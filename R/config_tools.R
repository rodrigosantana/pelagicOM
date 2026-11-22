########################################################################
## Description: pelagicOM - presets and tools to tune configurations
##
## Author: Rodrigo Sant'Ana
## Created: 2026-11-22
## Version: 0.1.0
##
### Code:
########################################################################

#' Available presets
#'
#' Lists the named configurations shipped with the package. Each preset
#' provides a biomass configuration ([om_biomass_config()]) and a fishery
#' configuration ([om_fishery_config()]).
#'
#' @return A data frame with columns `preset`, `species`, `area`,
#'   `description`.
#' @examples
#' om_presets()
#' @export
om_presets <- function() {
    data.frame(
        preset = "BET_ICCAT",
        species = "Bigeye tuna (Thunnus obesus)",
        area = "ICCAT BET-A stock area, 1x1 degree grid",
        description = paste(
            "Operating model of Experimento 02 (workshop tRFMO CPUE, 2026):",
            "Pella-Tomlinson biomass 1950-2025 with poleward redistribution,",
            "five longline fleets, target BET + YFT/ALB/SWO/BSH, eight",
            "observation scenarios. Reproduces the experiment exactly."),
        stringsAsFactors = FALSE)
}

#' Tune a configuration
#'
#' Recursively replaces elements of a biomass or fishery configuration.
#' Named lists are merged level by level, so only the elements given are
#' changed; any other value (vectors, unnamed lists such as `hotspots`,
#' `events`, `scenarios` or observation periods) replaces the original
#' one entirely. `NULL` removes an element (e.g. a fleet). New names are
#' accepted (e.g. a new fleet or companion species) and reported with a
#' message, which also catches typos.
#'
#' @param cfg A configuration from [om_biomass_config()] or
#'   [om_fishery_config()].
#' @param ... Named sections with the new values, or a single named list.
#' @param quiet If `TRUE`, does not report new elements.
#' @return The updated configuration (not validated; the simulation
#'   functions validate it).
#' @examples
#' cfg <- om_biomass_config()
#' cfg <- om_config_update(cfg,
#'     population = list(r = 0.45, decline = list(u_peak = 0.30)),
#'     habitat = list(hotspots = list(
#'         list(lon = -20, lat = 0, sd_lon = 8, sd_lat = 4, amp = 1.2))))
#' cfg$population$decline
#' length(cfg$habitat$hotspots)
#' @export
om_config_update <- function(cfg, ..., quiet = FALSE) {
    upd <- list(...)
    if (length(upd) == 1L && is.null(names(upd)) && is.list(upd[[1]]))
        upd <- upd[[1]]
    if (length(upd) && (is.null(names(upd)) || any(!nzchar(names(upd)))))
        stop("om_config_update(): all updates must be named")
    added <- character(0)
    merge <- function(x, val, path) {
        ###@> by position: the same section may be given more than once
        ###@> (later entries win)...
        for (i in seq_along(val)) {
            nm <- names(val)[i]
            v <- val[[i]]
            p <- if (nzchar(path)) paste0(path, "$", nm) else nm
            if (!nm %in% names(x) && !is.null(v)) added <<- c(added, p)
            is_named <- function(z) is.list(z) && length(z) &&
                !is.null(names(z)) && all(nzchar(names(z)))
            if (is.null(v)) {
                x[[nm]] <- NULL
            } else if (is_named(v) && is_named(x[[nm]])) {
                x[[nm]] <- merge(x[[nm]], v, p)
            } else {
                x[[nm]] <- v
            }
        }
        x
    }
    out <- merge(cfg, upd, "")
    if (length(added) && !quiet)
        message("om_config_update(): new element(s) added: ",
                paste(added, collapse = ", "))
    out
}

#' @export
print.om_biomass_config <- function(x, ...) {
    cat("<pelagicOM biomass configuration> label '", x$general$label,
        "' | seed ", x$general$seed, " | ", x$temporal$year_start, "-",
        x$temporal$year_end, " | stock area ", x$spatial$stock_code, "\n",
        sep = "")
    cat("sections:", paste(names(x), collapse = ", "), "\n")
    pp <- x$population
    cat(sprintf("population: %s, K = %g, r = %g, shape = %g, B0/K = %g\n",
                if (is.function(pp$model)) "custom" else pp$model, pp$K,
                pp$r, pp$shape, pp$B0_frac))
    cat(sprintf(paste0("habitat: %s envelope, centre %g, sd N/S %g/%g, ",
                       "%d hotspot(s); shift %s; noise %s\n"),
                x$habitat$envelope_type, x$habitat$lat_center,
                x$habitat$lat_sd_north, x$habitat$lat_sd_south,
                length(x$habitat$hotspots),
                if (isTRUE(x$shift$enabled)) "on" else "off",
                if (isTRUE(x$stochastic$enabled)) "on" else "off"))
    invisible(x)
}

#' @export
print.om_fishery_config <- function(x, ...) {
    cat("<pelagicOM fishery configuration> label '", x$general$label,
        "' | ", x$temporal$year_start, "-", x$temporal$year_end, "\n",
        sep = "")
    cat("sections:", paste(names(x), collapse = ", "), "\n")
    nv <- vapply(x$fleets, function(f) f$n_vessels, numeric(1))
    cat("fleets:", paste(sprintf("%s (%d vessels, %s)", names(x$fleets), nv,
                                 vapply(x$fleets, function(f)
                                     paste(f$regions, collapse = "+"), "")),
                         collapse = "; "), "\n")
    cat("strategies:", paste(x$strategies$levels, collapse = ", "),
        "| catch:", x$catch_process$distribution, "\n")
    if (isTRUE(x$species$enabled))
        cat("species: target", x$species$target, "+",
            paste(x$species$companions, collapse = ", "), "\n")
    cat("scenarios:", length(x$scenarios), "\n")
    invisible(x)
}
