########################################################################
## Description: pelagicOM - diagnostics, automatic checks and summaries
##              of the biomass operating truth
##
## Author: Rodrigo Sant'Ana
## Created: 2026-11-22
## Version: 0.1.0
##
### Commentary:
##
## Port of Experimento_02/Simulacao_Biomassa/R/06_diagnostics.R.
## Structural checks stop; expected-pattern checks warn. The expected
## patterns of Experimento 02 (central region densest at the start,
## poleward gain of share) are evaluated only when they apply: they refer
## to the central region (the middle label) and to the first/last labels.
##
### Code:
########################################################################

#' Summaries of the biomass truth
#'
#' `regional_summary()`: biomass, share, area and mean density (t/km2) by
#' year and region. `centre_of_gravity()`: biomass-weighted mean
#' latitude/longitude, mean absolute latitude, hemispheric centres and
#' northern share. `latitude_profile()`: mean density by 1-degree
#' latitude band and year (Hovmoller diagram).
#'
#' @param sim An `om_biomass` object.
#' @return A data frame.
#' @name biomass_summaries
NULL

#' @rdname biomass_summaries
#' @export
regional_summary <- function(sim) {
    cl <- sim$dom$cells; B <- sim$biomass; years <- sim$pop$Year
    out <- lapply(levels(cl$Region), function(r) {
        i <- cl$Region == r
        b <- colSums(B[i, , drop = FALSE])
        data.frame(Year = years, Region = r, N_cells = sum(i),
                   Area_km2 = sum(cl$Area_km2[i]),
                   Biomass = b, Share = b / sim$pop$B_total,
                   Mean_density = b / sum(cl$Area_km2[i]),
                   stringsAsFactors = FALSE)
    })
    out <- do.call(rbind, out)
    out$Region <- factor(out$Region, levels = levels(cl$Region))
    out[order(out$Year, out$Region), ]
}

#' @rdname biomass_summaries
#' @export
centre_of_gravity <- function(sim) {
    cl <- sim$dom$cells; B <- sim$biomass
    wmean <- function(x, w) sum(x * w) / sum(w)
    N <- cl$Latitude > 0; S <- cl$Latitude < 0
    data.frame(
        Year          = sim$pop$Year,
        Lat_cg        = apply(B, 2, function(b) wmean(cl$Latitude, b)),
        Lon_cg        = apply(B, 2, function(b) wmean(cl$Longitude, b)),
        Abs_lat_cg    = apply(B, 2, function(b) wmean(abs(cl$Latitude), b)),
        Lat_cg_north  = apply(B, 2, function(b) wmean(cl$Latitude[N], b[N])),
        Lat_cg_south  = apply(B, 2, function(b) wmean(cl$Latitude[S], b[S])),
        Share_north   = apply(B, 2, function(b) sum(b[N]) / sum(b)),
        stringsAsFactors = FALSE
    )
}

#' @rdname biomass_summaries
#' @export
latitude_profile <- function(sim) {
    cl <- sim$dom$cells; B <- sim$biomass; years <- sim$pop$Year
    lat_band <- cl$Nominal_lat0 + 0.5
    bands <- sort(unique(lat_band))
    area_b <- tapply(cl$Area_km2, lat_band, sum)[as.character(bands)]
    M <- sapply(seq_along(years), function(t)
        tapply(B[, t], lat_band, sum)[as.character(bands)] / area_b)
    data.frame(Year = rep(years, each = length(bands)),
               Lat_band = rep(bands, times = length(years)),
               Density = as.vector(M))
}

#' Automatic checks of the biomass truth
#'
#' Structural checks (stop on failure): identities
#' \eqn{\sum_s p = 1} and \eqn{\sum_s B = B_{total}}, no NA / Inf /
#' negatives, unique Year x Cell, temporal and spatial limits, coherent
#' regions. Pattern checks (warning): with three or more regions, the
#' central region has the highest mean density in the first year, and an
#' active poleward redistribution increases the share of the outer
#' regions and decreases the central one.
#'
#' @param sim An `om_biomass` object.
#' @param tol Relative tolerance of the identities.
#' @param verbose Print a summary.
#' @return Invisible list with the results.
#' @export
check_simulation <- function(sim, tol = 1e-8, verbose = TRUE) {
    cfg <- sim$cfg; cl <- sim$dom$cells; pop <- sim$pop
    P <- sim$weights; B <- sim$biomass; tb <- sim$table
    years <- cfg$temporal$year_start:cfg$temporal$year_end
    rg <- domain_regions(sim$dom, cfg)
    res <- list()

    ###@> (a) Structural ------------------------------------------------
    stopifnot(identical(pop$Year, years))
    stopifnot(all(is.finite(pop$B_total)), all(pop$B_total > 0))
    stopifnot(all(is.finite(P)), all(P >= 0))
    stopifnot(all(is.finite(B)), all(B >= 0))
    res$max_abs_dev_weights <- max(abs(colSums(P) - 1))
    stopifnot(res$max_abs_dev_weights < tol)
    res$max_rel_dev_biomass <- max(abs(colSums(B) - pop$B_total) /
                                   pop$B_total)
    stopifnot(res$max_rel_dev_biomass < tol)
    stopifnot(!any(duplicated(cl$Cell_ID)))
    if (!is.null(tb)) {
        stopifnot(!anyDuplicated(tb[, c("Year", "Cell_ID")]))
        stopifnot(nrow(tb) == length(years) * nrow(cl))
        stopifnot(!anyNA(tb))
        stopifnot(all(tb$Year >= cfg$temporal$year_start),
                  all(tb$Year <= cfg$temporal$year_end))
        bb <- sim$dom$meta$bbox
        if (!is.null(bb))
            stopifnot(all(tb$Longitude >= bb["xmin"]),
                      all(tb$Longitude <= bb["xmax"]),
                      all(tb$Latitude >= bb["ymin"]),
                      all(tb$Latitude <= bb["ymax"]))
        stopifnot(identical(as.character(tb$Region),
                            as.character(classify_regions(tb$Latitude,
                                                          rg$breaks,
                                                          rg$labels))))
        s_tab <- tapply(tb$Biomass, tb$Year, sum)
        stopifnot(max(abs(s_tab - pop$B_total) / pop$B_total) < tol)
    }
    res$structural_ok <- TRUE

    ###@> (b) Expected patterns ------------------------------------------
    reg <- regional_summary(sim)
    first <- reg[reg$Year == years[1], ]
    d <- stats::setNames(first$Mean_density, as.character(first$Region))
    res$density_first_year <- d
    lv <- levels(cl$Region)
    k <- min(10, floor(length(years) / 2))
    share <- stats::reshape(reg[, c("Year", "Region", "Share")], idvar = "Year",
                     timevar = "Region", direction = "wide")
    names(share) <- sub("Share\\.", "", names(share))
    trend_test <- function(x) {
        list(first = mean(utils::head(x, k)), last = mean(utils::tail(x, k)),
             rho = suppressWarnings(stats::cor(x, years, method = "spearman")))
    }
    res$trends <- lapply(stats::setNames(lv, lv),
                         function(r) trend_test(share[[r]]))
    sh <- cfg$shift
    active <- isTRUE(sh$enabled) &&
        (sh$north_expansion > 0 || sh$south_expansion > 0 ||
         sh$center_drift != 0 || sh$equatorial_contraction > 0)
    res$shift_active <- active
    if (length(lv) >= 3) {
        mid <- lv[ceiling(length(lv) / 2)]
        north <- lv[1]; south <- lv[length(lv)]
        res$central_densest_initially <- all(d[mid] > d[setdiff(lv, mid)])
        if (!res$central_densest_initially)
            warning("Expected pattern NOT observed: ", mid, " does not have ",
                    "the highest mean density in the first year")
        if (active) {
            tr <- res$trends
            if (sh$north_expansion > 0 && !(tr[[north]]$last > tr[[north]]$first))
                warning("Expected pattern NOT observed: share of ", north,
                        " did not increase although north_expansion > 0")
            if (sh$south_expansion > 0 && !(tr[[south]]$last > tr[[south]]$first))
                warning("Expected pattern NOT observed: share of ", south,
                        " did not increase although south_expansion > 0")
            if (!(tr[[mid]]$last < tr[[mid]]$first))
                warning("Expected pattern NOT observed: share of ", mid,
                        " did not decrease with an active redistribution")
        }
    }

    if (verbose) {
        message("  identities: max|sum p - 1| = ",
                format(res$max_abs_dev_weights, digits = 3),
                " | max rel |sum B - B_total| = ",
                format(res$max_rel_dev_biomass, digits = 3))
        message("  mean density in the first year (t/km2): ",
                paste(sprintf("%s=%.4f", names(d), d), collapse = "  "))
        message("  share (mean of the first vs last ", k, " years): ",
                paste(sprintf("%s %.3f -> %.3f", lv,
                              sapply(res$trends, `[[`, "first"),
                              sapply(res$trends, `[[`, "last")),
                      collapse = " | "))
        message("  redistribution active: ", active)
    }
    invisible(res)
}

#' @describeIn check_simulation Runs the simulation twice with the same
#'   configuration and compares the results bit by bit.
#' @param cfg Biomass configuration.
#' @param domain Optional domain (see [simulate_biomass()]).
#' @export
check_reproducibility <- function(cfg = om_biomass_config(), domain = NULL) {
    a <- simulate_biomass(cfg, domain, long_table = FALSE, verbose = FALSE)
    b <- simulate_biomass(cfg, domain, long_table = FALSE, verbose = FALSE)
    ok <- identical(a$biomass, b$biomass) && identical(a$pop, b$pop)
    if (!ok) stop("check_reproducibility(): the same seed produced ",
                  "different results")
    message("  reproducibility: OK (two identical runs)")
    invisible(ok)
}
