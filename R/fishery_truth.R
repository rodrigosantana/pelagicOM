########################################################################
## Description: pelagicOM - population truth as seen by the fishery
##              generator (Part II, module 01)
##
## Author: Rodrigo Sant'Ana
## Created: 2026-11-22
## Version: 0.1.0
##
### Commentary:
##
## Port of Experimento_02/Simulacao_Pesca/R/01_read_biomass.R. The
## truth can come from an om_biomass object, from any list with the
## components dom, pop and biomass (e.g. readRDS() of the Experimento 02
## file biomass_true_base.rds) or from the path to such a file.
##
### Code:
########################################################################

#' Population truth for the fishery generator
#'
#' Validates the biomass truth and derives what the fishery needs:
#' biomass and density (t/km2) matrices (cells x years), cells, regions,
#' lattice and a lookup table of the nearest domain cell for every
#' lattice cell (used by the position error of the observation process so
#' that observed positions never fall outside the domain).
#'
#' Density, not biomass, enters the expected catch: the gear samples a
#' local volume, not the whole cell (coastal cells clipped by land hold
#' less biomass but not fewer fish per km2).
#'
#' @param x An `om_biomass` object ([simulate_biomass()]), a list with
#'   `dom`, `pop` and `biomass`, or the path to an `.rds` file holding one.
#' @param verbose Print a summary.
#' @return An object of class `om_truth`.
#' @export
fishery_truth <- function(x, verbose = TRUE) {
    if (inherits(x, "om_truth")) return(x)
    file <- NA_character_
    if (is.character(x)) {
        if (!file.exists(x))
            stop("fishery_truth(): file not found: ", x)
        file <- x
        x <- readRDS(x)
    }
    need <- c("dom", "pop", "biomass")
    if (!all(need %in% names(x)))
        stop("fishery_truth(): object without components ",
             paste(setdiff(need, names(x)), collapse = ", "))
    cells <- x$dom$cells
    need_c <- c("Cell_ID", "Longitude", "Latitude", "Row", "Col",
                "Area_km2", "Region")
    if (!all(need_c %in% names(cells)))
        stop("fishery_truth(): cell table without fields ",
             paste(setdiff(need_c, names(cells)), collapse = ", "))
    B <- x$biomass
    years <- as.integer(colnames(B))
    stopifnot(nrow(B) == nrow(cells),
              identical(rownames(B), cells$Cell_ID),
              !anyNA(years), all(diff(years) == 1))
    D <- sweep(B, 1, cells$Area_km2, "/")
    truth <- list(
        cells    = cells,
        years    = years,
        biomass  = B,
        density  = D,
        pop      = x$pop,
        geometry = x$dom$geometry,
        lattice  = x$dom$lattice,
        regions  = domain_regions(x$dom, x$cfg),
        source   = list(file = file, label = x$cfg$general$label,
                        seed = x$cfg$general$seed,
                        shift_enabled = x$cfg$shift$enabled)
    )
    truth$nearest_lookup <- build_nearest_domain_lookup(truth)
    class(truth) <- c("om_truth", "list")
    if (verbose) {
        message("  population truth: ", nrow(cells), " cells x ",
                length(years), " years (", min(years), "-", max(years), ")")
        message("  B_total ", format(round(x$pop$B_total[1])), " t (",
                years[1], ") -> ",
                format(round(x$pop$B_total[length(years)])), " t (",
                years[length(years)], ") | Part I label: '",
                truth$source$label, "'")
    }
    truth
}

######@> True density / biomass of (cell index, year) pairs...
true_density_at <- function(truth, cell_idx, year) {
    truth$density[cbind(cell_idx, match(year, truth$years))]
}

true_biomass_at <- function(truth, cell_idx, year) {
    truth$biomass[cbind(cell_idx, match(year, truth$years))]
}

######@> For every lattice cell (including land), the index of the
######@> nearest domain cell (Euclidean distance in degrees between
######@> nominal centres), computed in blocks...
build_nearest_domain_lookup <- function(truth, chunk = 400L) {
    lt <- truth$lattice; cl <- truth$cells
    nr <- lt$n_row; nc <- lt$n_col
    look <- matrix(NA_integer_, nr, nc)
    look[cbind(cl$Row, cl$Col)] <- seq_len(nrow(cl))
    todo <- which(is.na(look))
    if (!length(todo)) return(look)
    rows <- ((todo - 1L) %% nr) + 1L; cols <- ((todo - 1L) %/% nr) + 1L
    lon_c <- lt$lon0_min + cols - 1L + 0.5
    lat_c <- lt$lat0_min + rows - 1L + 0.5
    cx <- cl$Nominal_lon0 + 0.5; cy <- cl$Nominal_lat0 + 0.5
    for (i in seq(1L, length(todo), by = chunk)) {
        j <- i:min(i + chunk - 1L, length(todo))
        d2 <- outer(lon_c[j], cx, "-")^2 + outer(lat_c[j], cy, "-")^2
        look[todo[j]] <- max.col(-d2, ties.method = "first")
    }
    look
}

######@> Region from latitude with the limits of the biomass truth...
region_from_latitude <- function(lat, truth) {
    rg <- truth$regions
    as.character(classify_regions(lat, rg$breaks, rg$labels))
}
