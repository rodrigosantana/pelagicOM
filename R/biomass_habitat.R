########################################################################
## Description: pelagicOM - static spatial structure of the habitat and
##              its spatio-temporal change (redistribution and noise)
##
## Author: Rodrigo Sant'Ana
## Created: 2026-11-22
## Version: 0.1.0
##
### Commentary:
##
## Ports of Experimento_02/Simulacao_Biomassa/R/03_spatial_distribution.R
## and 04_spatiotemporal_process.R. Expected log-density of cell s:
##
##   log D(y, s) = E(y, lat_s) + H(s) + G(lon_s) + Z(s) [+ C(s)] + eps(y, s)
##
##   E   latitudinal envelope, changing in time (redistribution)
##   H   Gaussian hotspots;  G  longitudinal gradient
##   Z   persistent Gaussian random field (kernel smoothing)
##   C   optional user layer, habitat$custom_effect(cells) (package)
##   eps spatio-temporal AR(1) noise on Gaussian fields
##
## Envelope types:
##   "latitude"     (Experimento 02) Gaussian on signed latitude with
##                  different sd north / south of the centre;
##   "abs_latitude" (package) Gaussian on |lat| with centre = preferred
##                  absolute latitude and sd per hemisphere, i.e. two
##                  symmetric bands (temperate species). center_drift > 0
##                  then moves both bands poleward.
##
### Code:
########################################################################

########################################################################
######@> Deterministic components...

#' Latitudinal envelope (log scale)
#'
#' @param lat Latitudes.
#' @param center Centre of the envelope (signed latitude for
#'   `type = "latitude"`, absolute latitude for `type = "abs_latitude"`).
#' @param sd_north,sd_south Standard deviations north / south of the
#'   centre (`"latitude"`) or in the northern / southern hemisphere
#'   (`"abs_latitude"`).
#' @param type `"latitude"` or `"abs_latitude"`.
#' @return Log-scale envelope (0 at the centre).
#' @examples
#' lat <- seq(-60, 60, 10)
#' round(exp(latitudinal_envelope(lat, 0, 11, 11)), 3)
#' round(exp(latitudinal_envelope(lat, 30, 8, 10, "abs_latitude")), 3)
#' @export
latitudinal_envelope <- function(lat, center, sd_north, sd_south,
                                 type = "latitude") {
    if (identical(type, "abs_latitude")) {
        sdv <- ifelse(lat >= 0, sd_north, sd_south)
        return(-0.5 * ((abs(lat) - center) / sdv)^2)
    }
    sdv <- ifelse(lat >= center, sd_north, sd_south)
    -0.5 * ((lat - center) / sdv)^2
}

######@> Sum of Gaussian hotspots (log scale)...
hotspot_effect <- function(lon, lat, hotspots) {
    h <- numeric(length(lon))
    for (hs in hotspots)
        h <- h + hs$amp * exp(-0.5 * ((lon - hs$lon) / hs$sd_lon)^2 -
                              0.5 * ((lat - hs$lat) / hs$sd_lat)^2)
    h
}

######@> Static components (one value per cell). The persistent field is
######@> the SECOND random draw of the run (after the process error of
######@> B_total), which fixes the order of the draws...
build_base_habitat <- function(dom, cfg) {
    hb <- cfg$habitat
    cl <- dom$cells
    env0 <- latitudinal_envelope(cl$Latitude, hb$lat_center,
                                 hb$lat_sd_north, hb$lat_sd_south,
                                 hb$envelope_type %||% "latitude")
    hs   <- hotspot_effect(cl$Longitude, cl$Latitude, hb$hotspots)
    lg   <- hb$lon_gradient * (cl$Longitude - mean(cl$Longitude))
    Zm   <- gaussian_random_field(dom$lattice, hb$field_range, hb$field_sd)
    Z    <- field_at_cells(Zm, cl)
    static <- hs + lg + Z
    custom <- NULL
    if (is.function(hb$custom_effect)) {
        custom <- as.numeric(hb$custom_effect(cl))
        if (length(custom) != nrow(cl) || any(!is.finite(custom)))
            stop("habitat$custom_effect must return one finite value per cell")
        static <- static + custom
    }
    out <- list(envelope0 = env0, hotspots = hs, lon_grad = lg, field = Z,
                static = static, field_matrix = Zm)
    if (!is.null(custom)) out$custom <- custom
    out
}

########################################################################
######@> Redistribution...

######@> Ramp f(y) in [0, 1] between shift$start and shift$end...
shift_ramp <- function(years, sh) {
    if (!isTRUE(sh$enabled)) return(rep(0, length(years)))
    x <- (years - sh$start) / (sh$end - sh$start)
    x <- pmin(pmax(x, 0), 1)
    if (sh$ramp == "logistic") {
        k <- sh$ramp_steepness
        x <- (stats::plogis(k * (x - 0.5)) - stats::plogis(-k / 2)) /
             (stats::plogis(k / 2) - stats::plogis(-k / 2))
    }
    x
}

######@> Envelope parameters year by year...
envelope_parameters <- function(years, cfg) {
    hb <- cfg$habitat; sh <- cfg$shift
    f  <- shift_ramp(years, sh)
    data.frame(
        Year      = years,
        ramp      = f,
        center    = hb$lat_center + sh$center_drift * f,
        sd_north  = hb$lat_sd_north * (1 + sh$north_expansion * f),
        sd_south  = hb$lat_sd_south * (1 + sh$south_expansion * f),
        eq_contr  = sh$equatorial_contraction * f
    )
}

######@> E(y, s): n_cells x n_years (log scale)...
build_envelope_matrix <- function(dom, years, cfg) {
    cl <- dom$cells
    ep <- envelope_parameters(years, cfg)
    eqb <- cfg$shift$eq_band
    type <- cfg$habitat$envelope_type %||% "latitude"
    E <- matrix(0, nrow(cl), length(years))
    in_band <- abs(cl$Latitude) < eqb
    for (t in seq_along(years)) {
        E[, t] <- latitudinal_envelope(cl$Latitude, ep$center[t],
                                       ep$sd_north[t], ep$sd_south[t], type)
        if (ep$eq_contr[t] != 0)
            E[in_band, t] <- E[in_band, t] - ep$eq_contr[t]
    }
    dimnames(E) <- list(cl$Cell_ID, years)
    E
}

########################################################################
######@> Spatio-temporal noise...

######@> eps(y, s) = rho eps(y - 1, s) + sqrt(1 - rho^2) xi_y(s); fields
######@> drawn in the order of the years (THIRD block of draws)...
build_spatiotemporal_noise <- function(dom, years, cfg) {
    st <- cfg$stochastic
    n  <- nrow(dom$cells); ny <- length(years)
    eps <- matrix(0, n, ny, dimnames = list(dom$cells$Cell_ID, years))
    if (!isTRUE(st$enabled) || st$sd <= 0) return(eps)
    prev <- NULL
    for (t in seq_len(ny)) {
        xi <- field_at_cells(gaussian_random_field(dom$lattice, st$range,
                                                   st$sd), dom$cells)
        eps[, t] <- if (t == 1) xi else st$rho * prev +
                                       sqrt(1 - st$rho^2) * xi
        prev <- eps[, t]
    }
    eps
}
