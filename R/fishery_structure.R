########################################################################
## Description: pelagicOM - fleets, vessels, trips and sets (Part II,
##              modules 02-05)
##
## Author: Rodrigo Sant'Ana
## Created: 2026-11-22
## Version: 0.1.0
##
### Commentary:
##
## Ports of Experimento_02/Simulacao_Pesca/R/02_simulate_fleets.R,
## 03_simulate_vessels.R, 04_simulate_trips.R and 05_simulate_sets.R.
## Each stochastic module seeds its own stream
## (cfg$reproducibility$seeds).
##
### Code:
########################################################################

########################################################################
######@> Fleets...

######@> Descriptive table of the fleets (1 row per fleet)...
build_fleet_table <- function(cfg) {
    do.call(rbind, lapply(names(cfg$fleets), function(nm) {
        f <- cfg$fleets[[nm]]
        data.frame(Fleet = nm, n_vessels = f$n_vessels,
                   year_start = f$year_start, year_end = f$year_end,
                   regions = paste(f$regions, collapse = "+"),
                   core_lon = f$core_lon, core_lat = f$core_lat,
                   core_sd = f$core_sd, q_effect = f$q_effect,
                   hbf_mult = f$hbf_mult,
                   stringsAsFactors = FALSE)
    }))
}

######@> Cells (row indices) accessible to a fleet by region, ordered by
######@> distance to the fleet centre (Euclidean, degrees)...
fleet_accessible_cells <- function(fleet_cfg, truth) {
    cl <- truth$cells
    idx <- which(cl$Region %in% fleet_cfg$regions)
    d <- sqrt((cl$Longitude[idx] - fleet_cfg$core_lon)^2 +
              (cl$Latitude[idx] - fleet_cfg$core_lat)^2)
    idx[order(d)]
}

######@> Fraction of the accessible area available in 'year' (expansion)...
expansion_fraction <- function(fleet_cfg, year, cfg) {
    if (!isTRUE(cfg$spatial$expansion_enabled)) return(rep(1, length(year)))
    since <- pmax(year - fleet_cfg$year_start, 0)
    interp_anchors(since, cfg$spatial$expansion_profile)
}

######@> Footprint in a year: the first ceiling(frac * n) accessible
######@> cells (closest to the centre)...
fleet_footprint <- function(fleet_cfg, truth, cfg, year,
                            accessible = NULL) {
    if (is.null(accessible)) accessible <- fleet_accessible_cells(fleet_cfg,
                                                                  truth)
    frac <- expansion_fraction(fleet_cfg, year, cfg)
    n <- max(1L, ceiling(frac * length(accessible)))
    accessible[seq_len(n)]
}

######@> Baseline spatial preference g_f(s): Gaussian around the fleet
######@> centre (max = 1); switched off => 1 everywhere...
fleet_core_preference <- function(fleet_cfg, truth, cfg, idx) {
    if (!isTRUE(cfg$spatial$core_preference_enabled))
        return(rep(1, length(idx)))
    cl <- truth$cells
    d2 <- (cl$Longitude[idx] - fleet_cfg$core_lon)^2 +
          (cl$Latitude[idx] - fleet_cfg$core_lat)^2
    exp(-0.5 * d2 / fleet_cfg$core_sd^2)
}

fleet_years <- function(fleet_cfg) fleet_cfg$year_start:fleet_cfg$year_end

########################################################################
######@> Vessels...

######@> Vessels and vessel-years. Within each fleet, 'n_vessels' slots
######@> are kept filled: when a vessel retires, a new one enters the
######@> next year (turnover). First cohort: uniform remaining career, so
######@> that exits are staggered...
simulate_vessels <- function(cfg) {
    om_set_seed(cfg$reproducibility$seeds$vessels)
    vp <- cfg$vessels
    out <- list()
    for (nm in names(cfg$fleets)) {
        f <- cfg$fleets[[nm]]
        yrs <- fleet_years(f)
        counter <- 0L
        rows <- list()
        for (slot in seq_len(f$n_vessels)) {
            year <- f$year_start
            first <- TRUE
            while (year <= f$year_end) {
                counter <- counter + 1L
                if (!isTRUE(vp$turnover_enabled)) {
                    career <- length(yrs)
                } else if (first) {
                    career <- rint(1, vp$career_min,
                                   max(vp$career_min,
                                       round(2 * vp$career_mean)))
                } else {
                    career <- max(vp$career_min,
                                  round(stats::rnorm(1, vp$career_mean,
                                                     vp$career_sd)))
                }
                y_out <- min(year + career - 1L, f$year_end)
                rows[[length(rows) + 1L]] <- data.frame(
                    VesselID = sprintf("%s_%03d", nm, counter),
                    Fleet = nm, Year_in = year, Year_out = y_out,
                    Career = y_out - year + 1L, Slot = slot,
                    stringsAsFactors = FALSE)
                year <- y_out + 1L
                first <- FALSE
            }
        }
        out[[nm]] <- do.call(rbind, rows)
    }
    vessels <- do.call(rbind, out)
    rownames(vessels) <- NULL
    vessel_years <- do.call(rbind, lapply(seq_len(nrow(vessels)), function(i)
        data.frame(VesselID = vessels$VesselID[i], Fleet = vessels$Fleet[i],
                   Year = vessels$Year_in[i]:vessels$Year_out[i],
                   stringsAsFactors = FALSE)))
    list(vessels = vessels, vessel_years = vessel_years)
}

#' Active vessels by fleet and year
#'
#' @param vessel_years The `vessel_years` table of an `om_fishery`
#'   object.
#' @return Data frame Fleet x Year with `n_vessels`.
#' @export
active_vessels_by_year <- function(vessel_years) {
    as.data.frame(table(Fleet = vessel_years$Fleet,
                        Year = vessel_years$Year),
                  responseName = "n_vessels")
}

########################################################################
######@> Trips...

######@> Trips per vessel-year, quarter by fleet weights, chronological
######@> TripIndex / TripID within vessel-year...
simulate_trips <- function(vessel_years, cfg) {
    om_set_seed(cfg$reproducibility$seeds$trips)
    lim <- cfg$trips$per_vessel_year
    n_vy <- nrow(vessel_years)
    n_trips <- rint(n_vy, lim[1], lim[2])
    trips <- vessel_years[rep(seq_len(n_vy), n_trips), ]
    rownames(trips) <- NULL
    qw <- sapply(cfg$fleets, `[[`, "quarter_weights")   # 4 x n_fleets
    u <- stats::runif(nrow(trips))
    cum <- apply(qw, 2, function(w) cumsum(w) / sum(w))
    fcol <- match(trips$Fleet, colnames(cum))
    trips$Quarter <- 1L + (u > cum[1, fcol]) + (u > cum[2, fcol]) +
                     (u > cum[3, fcol])
    o <- order(trips$Fleet, trips$VesselID, trips$Year, trips$Quarter)
    trips <- trips[o, ]
    key <- paste(trips$VesselID, trips$Year)
    trips$TripIndex <- stats::ave(seq_along(key), key, FUN = seq_along)
    trips$TripID <- sprintf("%s_%d_T%02d", trips$VesselID, trips$Year,
                            trips$TripIndex)
    rownames(trips) <- NULL
    trips[, c("TripID", "VesselID", "Fleet", "Year", "Quarter", "TripIndex")]
}

########################################################################
######@> Sets...

######@> Sets per trip (base, 8-15) or per vessel-year (literal original
######@> specification, at least one set per trip)...
simulate_sets <- function(trips, cfg) {
    om_set_seed(cfg$reproducibility$seeds$sets)
    sp <- cfg$sets
    key <- paste(trips$VesselID, trips$Year)
    if (sp$unit == "per_trip") {
        n_per_trip <- rint(nrow(trips), sp$per_trip[1], sp$per_trip[2])
        n_adjusted <- 0L
    } else {
        vy <- unique(key)
        n_trips_vy <- table(key)[vy]
        n_sets_vy <- rint(length(vy), sp$per_vessel_year[1],
                          sp$per_vessel_year[2])
        n_adjusted <- sum(n_sets_vy < n_trips_vy)
        n_sets_vy <- pmax(n_sets_vy, as.integer(n_trips_vy))
        n_per_trip <- rep(1L, nrow(trips))
        extra <- n_sets_vy - as.integer(n_trips_vy)
        trip_rows_by_vy <- split(seq_len(nrow(trips)), key)
        for (j in which(extra > 0)) {
            rows <- trip_rows_by_vy[[vy[j]]]
            add <- rows[sample.int(length(rows), extra[j], replace = TRUE)]
            tab <- table(add)
            n_per_trip[as.integer(names(tab))] <-
                n_per_trip[as.integer(names(tab))] + as.integer(tab)
        }
    }
    sets <- trips[rep(seq_len(nrow(trips)), n_per_trip), ]
    rownames(sets) <- NULL
    sets$SetInTrip <- stats::ave(seq_len(nrow(sets)), sets$TripID,
                                 FUN = seq_along)
    sets$SetID <- sprintf("%s_S%02d", sets$TripID, sets$SetInTrip)
    o <- order(sets$Fleet, sets$VesselID, sets$Year, sets$TripIndex,
               sets$SetInTrip)
    sets <- sets[o, ]
    sets$SetOrder <- stats::ave(seq_len(nrow(sets)),
                                paste(sets$VesselID, sets$Year),
                                FUN = seq_along)
    rownames(sets) <- NULL
    out <- sets[, c("SetID", "TripID", "VesselID", "Fleet", "Year",
                    "Quarter", "TripIndex", "SetInTrip", "SetOrder")]
    attr(out, "n_adjusted") <- n_adjusted
    out
}
