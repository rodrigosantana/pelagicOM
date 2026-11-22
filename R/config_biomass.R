########################################################################
## Description: pelagicOM - configuration of the biomass operating truth
##              (Part I): presets, validation
##
## Author: Rodrigo Sant'Ana
## Created: 2026-11-22
## Version: 0.1.0
##
### Commentary:
##
## The structure is the one of SIM_CONFIG in
## Experimento_02/Simulacao_Biomassa/R/00_config.R. Differences:
##   - no file paths (outputs are written by om_write_biomass());
##   - spatial$region_breaks / region_labels generalise the two fixed
##     latitude limits (region_lat_south / region_lat_north);
##   - spatial$source selects the bundled ICCAT grid or a GeoPackage;
##   - habitat$envelope_type and habitat$custom_effect allow other
##     latitudinal shapes (e.g. temperate species) and user-defined
##     static habitat layers. Their defaults reproduce Experimento 02.
##
### Code:
########################################################################

#' Biomass (Part I) configuration
#'
#' Returns the full list of parameters that controls the spatio-temporal
#' biomass operating truth. The `"BET_ICCAT"` preset is the configuration
#' used in Experimento 02 (bigeye tuna, ICCAT BET-A stock area, 1950-2025,
#' seed 20261005) and reproduces its results exactly.
#'
#' The list has the sections
#' \describe{
#'   \item{general}{`label`, `seed`.}
#'   \item{temporal}{`year_start`, `year_end`.}
#'   \item{spatial}{source of the spatial domain (`source = "iccat"` for
#'     the 1x1 ICCAT grid bundled with the package, `"gpkg"` to read a
#'     GeoPackage, read by [om_domain_from_gpkg()] with geodesic areas
#'     from `lwgeom`), the stock area (`stock_code`, `selection`), and the
#'     latitudinal
#'     regions (`region_breaks`, ascending; `region_labels`, ordered from
#'     north to south, one more than the breaks).}
#'   \item{population}{Pella-Tomlinson surplus production with an
#'     exogenous removal rate u(y) drawn by phases (`u_base`, `decline`,
#'     `recovery`), AR(1) process error, optional shocks (`events`) and a
#'     trend in carrying capacity (`K_trend`). `model` may also be a
#'     function `f(B, K, r, shape)` returning the surplus production.}
#'   \item{habitat}{static log-density: latitudinal envelope
#'     (`envelope_type = "latitude"`: Gaussian on signed latitude, the
#'     tropical core of Experimento 02; `"abs_latitude"`: Gaussian on
#'     absolute latitude, i.e. one band per hemisphere, for temperate
#'     species), Gaussian `hotspots`, longitudinal gradient, persistent
#'     random field (`field_sd`, `field_range`) and an optional
#'     `custom_effect = function(cells)` returning a log-scale vector.}
#'   \item{shift}{poleward redistribution: expansion of the envelope
#'     standard deviations, drift of its centre and equatorial
#'     contraction along a ramp between `start` and `end`.}
#'   \item{stochastic}{spatio-temporal AR(1) noise on Gaussian fields.}
#'   \item{output}{what [om_write_biomass()] saves and figure settings.}
#' }
#'
#' @param preset Name of a preset (see [om_presets()]).
#' @param ... Optional named sections that override the preset, passed to
#'   [om_config_update()] (e.g. `population = list(r = 0.4)`).
#' @return A list of class `om_biomass_config`.
#' @seealso [om_fishery_config()], [om_config_update()],
#'   [simulate_biomass()].
#' @examples
#' cfg <- om_biomass_config("BET_ICCAT")
#' cfg$population$r
#' cfg2 <- om_biomass_config("BET_ICCAT", population = list(r = 0.45),
#'                           shift = list(enabled = FALSE))
#' cfg2$population$r
#' @export
om_biomass_config <- function(preset = "BET_ICCAT", ...) {
    preset <- match.arg(preset, om_presets()$preset)
    cfg <- switch(preset, BET_ICCAT = biomass_config_bet_iccat())
    class(cfg) <- c("om_biomass_config", "list")
    upd <- list(...)
    if (length(upd)) cfg <- om_config_update(cfg, upd)
    cfg <- validate_biomass_config(cfg)
    cfg
}

######@> Experimento 02 / BET-A (values of SIM_CONFIG, 2026-10-05)...
biomass_config_bet_iccat <- function() {
    list(
        general = list(
            label = "base",
            seed  = 20261005
        ),
        temporal = list(
            year_start = 1950,
            year_end   = 2025
        ),
        spatial = list(
            ## "iccat": 1x1 ICCAT grid bundled with the package;
            ## "gpkg": read 'gpkg' with the layers/fields below.
            source       = "iccat",
            gpkg         = NULL,
            layer_grid   = "grids_01x01",
            layer_stock  = "bigeye_tuna_stock_areas",
            stock_code   = "BET-A",
            id_field     = "CODE",
            lon_field    = "CENTER_LON",
            lat_field    = "CENTER_LAT",
            ## cells of the stock area when source = "gpkg":
            ## "intersects" (Experimento 02) or "point_on_surface"
            selection    = "intersects",
            ## Latitudinal regions: R01 lat > 20 ; R02 -20 <= lat <= 20 ;
            ## R03 lat < -20 (labels from north to south).
            region_breaks = c(-20, 20),
            region_labels = c("R01", "R02", "R03")
        ),
        population = list(
            model        = "pella_tomlinson",
            K            = 1e6,
            r            = 0.30,
            shape        = 1.0,
            B0_frac      = 0.95,
            u_base       = 0.02,
            decline      = list(start = 1965, end = 1995, u_peak = 0.26),
            recovery     = list(start = 2012, end = 2025, u_end  = 0.12),
            u_smooth     = 5,
            K_trend      = 0.0,
            proc_sd      = 0.05,
            proc_rho     = 0.40,
            events       = list(),
            B_floor_frac = 1e-3
        ),
        habitat = list(
            envelope_type = "latitude",
            lat_center   = 0,
            lat_sd_north = 11,
            lat_sd_south = 11,
            hotspots = list(
                list(lon = -5,  lat =  0, sd_lon = 10, sd_lat = 5, amp = 0.9),
                list(lon = -32, lat =  4, sd_lon = 9,  sd_lat = 5, amp = 0.6)
            ),
            lon_gradient = 0.0,
            field_sd     = 0.45,
            field_range  = 4,
            custom_effect = NULL
        ),
        shift = list(
            enabled          = TRUE,
            start            = 1950,
            end              = 2025,
            ramp             = "linear",
            ramp_steepness   = 8,
            north_expansion  = 0.70,
            south_expansion  = 0.70,
            center_drift     = 0.0,
            equatorial_contraction = 0.0,
            eq_band          = 10
        ),
        stochastic = list(
            enabled  = TRUE,
            sd       = 0.30,
            range    = 3,
            rho      = 0.60
        ),
        output = list(
            save_rds      = TRUE,
            save_csv      = TRUE,
            save_figures  = TRUE,
            map_years     = c(1950, 1975, 2000, 2025),
            fig_width     = 9,
            fig_height    = 5.5,
            fig_dpi       = 200
        )
    )
}

######@> Accepts configurations saved by Experimento_02 (region limits
######@> as region_lat_north / region_lat_south) and fills the fields
######@> added by the package with their neutral defaults...
normalize_biomass_config <- function(cfg) {
    sp <- cfg$spatial
    if (is.null(sp$region_breaks) && !is.null(sp$region_lat_north)) {
        sp$region_breaks <- c(sp$region_lat_south, sp$region_lat_north)
        sp$region_labels <- sp$region_labels %||% c("R01", "R02", "R03")
    }
    sp$source <- sp$source %||% "iccat"
    sp$selection <- sp$selection %||% "intersects"
    cfg$spatial <- sp
    cfg$habitat$envelope_type <- cfg$habitat$envelope_type %||% "latitude"
    if (!inherits(cfg, "om_biomass_config"))
        class(cfg) <- c("om_biomass_config", "list")
    cfg
}

#' @describeIn om_biomass_config Checks the internal coherence of a
#'   biomass configuration (stops with an explicit message).
#' @param cfg A biomass configuration.
#' @export
validate_biomass_config <- function(cfg) {
    stopifnot(is.list(cfg))
    cfg <- normalize_biomass_config(cfg)
    tp <- cfg$temporal
    stopifnot(is.numeric(tp$year_start), is.numeric(tp$year_end),
              tp$year_end > tp$year_start)
    sp <- cfg$spatial
    br <- sp$region_breaks
    if (length(br) && (any(!is.finite(br)) || any(diff(br) <= 0)))
        stop("spatial$region_breaks must be finite and strictly increasing")
    if (length(sp$region_labels) != length(br) + 1L)
        stop("spatial$region_labels must have length(region_breaks) + 1 ",
             "elements (ordered from north to south)")
    if (anyDuplicated(sp$region_labels))
        stop("spatial$region_labels must be unique")
    stopifnot(sp$source %in% c("iccat", "gpkg"),
              sp$selection %in% c("intersects", "point_on_surface"))
    pp <- cfg$population
    stopifnot(pp$K > 0, pp$r > 0, pp$shape > 0,
              pp$B0_frac > 0, pp$B0_frac <= 1.5,
              pp$u_base >= 0, pp$u_base < 1,
              pp$decline$u_peak >= 0, pp$decline$u_peak < 1,
              pp$recovery$u_end >= 0, pp$recovery$u_end < 1,
              pp$decline$start <= pp$decline$end,
              pp$decline$end <= pp$recovery$start,
              pp$recovery$start <= pp$recovery$end,
              pp$proc_sd >= 0, abs(pp$proc_rho) < 1)
    hb <- cfg$habitat
    stopifnot(hb$envelope_type %in% c("latitude", "abs_latitude"),
              hb$lat_sd_north > 0, hb$lat_sd_south > 0,
              hb$field_sd >= 0, hb$field_range > 0,
              is.null(hb$custom_effect) || is.function(hb$custom_effect))
    for (h in hb$hotspots)
        stopifnot(all(c("lon", "lat", "sd_lon", "sd_lat", "amp") %in%
                      names(h)), h$sd_lon > 0, h$sd_lat > 0)
    sh <- cfg$shift
    stopifnot(is.logical(sh$enabled), sh$end > sh$start,
              sh$ramp %in% c("linear", "logistic"),
              sh$north_expansion > -1, sh$south_expansion > -1,
              sh$eq_band > 0)
    st <- cfg$stochastic
    stopifnot(is.logical(st$enabled), st$sd >= 0, st$range > 0,
              abs(st$rho) < 1)
    stopifnot(all(cfg$output$map_years >= tp$year_start),
              all(cfg$output$map_years <= tp$year_end))
    invisible(cfg)
}
