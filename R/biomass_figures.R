########################################################################
## Description: pelagicOM - diagnostic figures of the biomass truth
##
## Author: Rodrigo Sant'Ana
## Created: 2026-11-22
## Version: 0.1.0
##
### Commentary:
##
## Port of Experimento_02/Simulacao_Biomassa/R/07_figures.R:
##   fig01_total_biomass      B_total(y), K, Bmsy and removal rate
##   fig02_region_biomass     biomass by region
##   fig03_region_share       regional share
##   fig04_maps               density maps in selected years (needs sf)
##   fig05_centre_gravity     latitudinal centre of gravity
##   fig06_hovmoller          density by latitude band x year
##   fig07_base_habitat       static habitat map (needs sf)
##   fig08_envelope_profiles  latitudinal envelope in selected years
##
### Code:
########################################################################

#' Figures of the biomass truth
#'
#' `biomass_figures()` returns the eight diagnostic figures of
#' Experimento 02 as a named list of `ggplot` objects;
#' `make_biomass_figures()` saves them as PNG files named
#' `figNN_<name>_<label>.png`. The individual `fig_*` functions build one
#' figure each. Maps (`fig_maps()`, `fig_base_habitat()`) need the cell
#' geometry (package `sf` and a domain built with `geometry = TRUE`).
#'
#' @param sim An `om_biomass` object.
#' @return A `ggplot` (or a list of them).
#' @name biomass_figures
NULL

#' @rdname biomass_figures
#' @export
fig_total_biomass <- function(sim) {
    need_pkg("ggplot2", "fig_total_biomass()")
    pop <- sim$pop; ref <- attr(pop, "ref")
    d <- rbind(
        data.frame(Year = pop$Year, value = pop$B_total / 1e3,
                   panel = "Total biomass (thousand t)"),
        data.frame(Year = pop$Year, value = pop$u,
                   panel = "Removal rate u(y)"))
    d$panel <- factor(d$panel, levels = unique(d$panel))
    hl <- data.frame(
        panel = factor(rep("Total biomass (thousand t)", 2),
                       levels = levels(d$panel)),
        y = c(ref$K, ref$Bmsy) / 1e3, lab = c("K", "Bmsy"))
    mdl <- sim$cfg$population$model
    sub <- if (is.function(mdl)) "User-defined surplus production" else
        sprintf("Pella-Tomlinson (shape = %.1f), K = %s t, r = %.2f",
                ref$shape, format(ref$K, big.mark = ",", scientific = FALSE),
                ref$r)
    ggplot2::ggplot(d, ggplot2::aes(Year, value)) +
        ggplot2::geom_hline(data = hl, ggplot2::aes(yintercept = y),
                            linetype = "22", colour = GRAY_MID,
                            linewidth = 0.4) +
        ggplot2::geom_text(data = hl, ggplot2::aes(x = min(pop$Year),
                                                   y = y, label = lab),
                           vjust = -0.4, hjust = 0, size = 3,
                           colour = GRAY_MID) +
        ggplot2::geom_line(colour = GRAY_INK, linewidth = 0.8) +
        ggplot2::facet_wrap(~panel, scales = "free_y", ncol = 1) +
        ggplot2::expand_limits(y = 0) +
        ggplot2::labs(x = NULL, y = NULL,
                      title = "True total biomass trajectory",
                      subtitle = paste0(sub, "; AR(1) process error")) +
        theme_pub()
}

#' @rdname biomass_figures
#' @param reg Output of [regional_summary()].
#' @export
fig_region_biomass <- function(sim, reg = regional_summary(sim)) {
    rs <- region_style(domain_regions(sim$dom, sim$cfg))
    ggplot2::ggplot(reg, ggplot2::aes(Year, Biomass / 1e3, colour = Region,
                                      linetype = Region)) +
        ggplot2::geom_line(linewidth = 0.8) +
        ggplot2::scale_colour_manual(values = rs$pal, labels = rs$lab) +
        ggplot2::scale_linetype_manual(values = rs$lty, labels = rs$lab) +
        ggplot2::expand_limits(y = 0) +
        ggplot2::labs(x = NULL, y = "Biomass (thousand t)",
                      title = "True biomass by latitudinal region") +
        theme_pub()
}

#' @rdname biomass_figures
#' @export
fig_region_share <- function(sim, reg = regional_summary(sim)) {
    rg <- domain_regions(sim$dom, sim$cfg)
    rs <- region_style(rg)
    lv <- levels(reg$Region)
    sub <- if (length(lv) >= 3)
        sprintf("Poleward redistribution transfers share from %s to %s and %s",
                lv[ceiling(length(lv) / 2)], lv[1], lv[length(lv)]) else NULL
    ggplot2::ggplot(reg, ggplot2::aes(Year, Share, colour = Region,
                                      linetype = Region)) +
        ggplot2::geom_line(linewidth = 0.8) +
        ggplot2::scale_colour_manual(values = rs$pal, labels = rs$lab) +
        ggplot2::scale_linetype_manual(values = rs$lty, labels = rs$lab) +
        ggplot2::scale_y_continuous(labels = function(x)
                                        sprintf("%.0f%%", 100 * x),
                                    limits = c(0, 1)) +
        ggplot2::labs(x = NULL, y = "Share of total biomass",
                      title = "Regional share of the stock", subtitle = sub) +
        theme_pub()
}

require_geometry <- function(dom, what) {
    if (is.null(dom$geometry))
        stop(what, " needs the cell geometry: build the domain with ",
             "geometry = TRUE", call. = FALSE)
    invisible(TRUE)
}

#' @rdname biomass_figures
#' @param years_sel Years shown in the maps (default
#'   `cfg$output$map_years`).
#' @export
fig_maps <- function(sim, years_sel = NULL) {
    require_geometry(sim$dom, "fig_maps()")
    cfg <- sim$cfg
    if (is.null(years_sel)) years_sel <- cfg$output$map_years
    idx <- match(years_sel, sim$pop$Year)
    stopifnot(!anyNA(idx))
    geom <- sim$dom$geometry
    L <- do.call(rbind, lapply(seq_along(idx), function(k) {
        g <- geom
        g$Density <- sim$biomass[, idx[k]] / sim$dom$cells$Area_km2
        g$panel <- sprintf("%d  (B/K = %.2f)", years_sel[k],
                           sim$pop$Depletion[idx[k]])
        g
    }))
    L$panel <- factor(L$panel, levels = unique(L$panel))
    br <- domain_regions(sim$dom, cfg)$breaks
    ggplot2::ggplot(L) +
        ggplot2::geom_sf(ggplot2::aes(fill = Density), colour = NA) +
        ggplot2::scale_fill_gradient(low = "grey97", high = "black",
                                     transform = "sqrt",
                                     name = "Density (t/km\u00b2)") +
        ggplot2::geom_hline(yintercept = br, linetype = "22",
                            colour = GRAY_MID, linewidth = 0.3) +
        ggplot2::facet_wrap(~panel, ncol = 2) +
        ggplot2::coord_sf(expand = FALSE) +
        ggplot2::labs(x = NULL, y = NULL,
                      title = "True biomass density in selected years",
                      subtitle = if (length(br))
                          paste("Dashed lines:", collapse_and(fmt_lat(br)),
                                "region boundaries")) +
        theme_pub(base = 10) +
        ggplot2::theme(legend.position = "right",
                       legend.title = ggplot2::element_text(size = 9),
                       panel.grid.major = ggplot2::element_blank())
}

#' @rdname biomass_figures
#' @param cg Output of [centre_of_gravity()].
#' @export
fig_centre_gravity <- function(sim, cg = centre_of_gravity(sim)) {
    d <- rbind(
        data.frame(Year = cg$Year, value = cg$Lat_cg,
                   series = "Whole stock",
                   panel = "Biomass-weighted mean latitude"),
        data.frame(Year = cg$Year, value = cg$Abs_lat_cg,
                   series = "Whole stock", panel = "Mean absolute latitude"),
        data.frame(Year = cg$Year, value = cg$Lat_cg_north,
                   series = "Northern hemisphere",
                   panel = "Hemispheric centres"),
        data.frame(Year = cg$Year, value = cg$Lat_cg_south,
                   series = "Southern hemisphere",
                   panel = "Hemispheric centres"))
    d <- d[is.finite(d$value), ]
    d$panel <- factor(d$panel, levels = unique(d$panel))
    d$series <- factor(d$series,
                       levels = c("Whole stock", "Northern hemisphere",
                                  "Southern hemisphere"))
    ggplot2::ggplot(d, ggplot2::aes(Year, value, colour = series,
                                    linetype = series)) +
        ggplot2::geom_line(linewidth = 0.8) +
        ggplot2::scale_colour_manual(values = c("black", "grey45", "grey45"),
                                     drop = FALSE) +
        ggplot2::scale_linetype_manual(values = c("solid", "solid", "22"),
                                       drop = FALSE) +
        ggplot2::facet_wrap(~panel, scales = "free_y", ncol = 3) +
        ggplot2::labs(x = NULL, y = "Latitude (\u00b0)",
                      title = "Centre of distribution over time") +
        theme_pub()
}

#' @rdname biomass_figures
#' @param prof Output of [latitude_profile()].
#' @export
fig_hovmoller <- function(sim, prof = latitude_profile(sim)) {
    br <- domain_regions(sim$dom, sim$cfg)$breaks
    ggplot2::ggplot(prof, ggplot2::aes(Year, Lat_band, fill = Density)) +
        ggplot2::geom_raster() +
        ggplot2::scale_fill_gradient(low = "grey97", high = "black",
                                     transform = "sqrt",
                                     name = "Mean density (t/km\u00b2)") +
        ggplot2::geom_hline(yintercept = br, linetype = "22",
                            colour = "white", linewidth = 0.4) +
        ggplot2::scale_x_continuous(expand = c(0, 0)) +
        ggplot2::scale_y_continuous(expand = c(0, 0)) +
        ggplot2::labs(x = NULL, y = "Latitude (\u00b0)",
                      title = "Latitudinal profile of mean density by year",
                      subtitle = paste("Mean over all cells of each 1\u00b0",
                                       "latitude band; dashed lines:",
                                       "region boundaries")) +
        theme_pub() +
        ggplot2::theme(legend.position = "right",
                       legend.title = ggplot2::element_text(size = 9),
                       panel.grid.major = ggplot2::element_blank())
}

#' @rdname biomass_figures
#' @export
fig_base_habitat <- function(sim) {
    require_geometry(sim$dom, "fig_base_habitat()")
    g <- sim$dom$geometry
    comp <- list(
        "Static component only (hotspots + persistent field)" =
            sim$base$static,
        "Static x latitudinal envelope (first year)" =
            sim$base$static + sim$envelope[, 1])
    L <- do.call(rbind, lapply(names(comp), function(nm) {
        gg <- g; v <- exp(comp[[nm]] - max(comp[[nm]]))
        gg$Relative <- v; gg$panel <- nm; gg
    }))
    L$panel <- factor(L$panel, levels = names(comp))
    ggplot2::ggplot(L) +
        ggplot2::geom_sf(ggplot2::aes(fill = Relative), colour = NA) +
        ggplot2::scale_fill_gradient(low = "grey97", high = "black",
                                     name = "Relative density") +
        ggplot2::facet_wrap(~panel, ncol = 2) +
        ggplot2::coord_sf(expand = FALSE) +
        ggplot2::labs(x = NULL, y = NULL,
                      title = "Mean spatial structure of the habitat") +
        theme_pub(base = 10) +
        ggplot2::theme(legend.position = "right",
                       legend.title = ggplot2::element_text(size = 9),
                       panel.grid.major = ggplot2::element_blank())
}

#' @rdname biomass_figures
#' @export
fig_envelope_profiles <- function(sim, years_sel = NULL) {
    cfg <- sim$cfg
    if (is.null(years_sel)) years_sel <- cfg$output$map_years
    ep <- sim$envelope_params
    type <- cfg$habitat$envelope_type %||% "latitude"
    ###@> Whole tens of degrees around the domain (-60 to 70 for ICCAT)...
    lat <- seq(floor(min(sim$dom$cells$Latitude) / 10) * 10,
               ceiling(max(sim$dom$cells$Latitude) / 10) * 10, by = 0.5)
    d <- do.call(rbind, lapply(years_sel, function(y) {
        i <- match(y, ep$Year)
        e <- latitudinal_envelope(lat, ep$center[i], ep$sd_north[i],
                                  ep$sd_south[i], type)
        if (ep$eq_contr[i] != 0)
            e[abs(lat) < cfg$shift$eq_band] <- e[abs(lat) < cfg$shift$eq_band] -
                ep$eq_contr[i]
        data.frame(Latitude = lat, value = exp(e), Year = factor(y))
    }))
    grays <- grDevices::gray.colors(length(years_sel), start = 0,
                                    end = 0.7)
    ltys <- rep(c("solid", "22", "42", "12"), length.out = length(years_sel))
    ggplot2::ggplot(d, ggplot2::aes(Latitude, value, colour = Year,
                                    linetype = Year)) +
        ggplot2::geom_vline(xintercept = domain_regions(sim$dom, cfg)$breaks,
                            linetype = "22", colour = GRAY_LIGHT) +
        ggplot2::geom_line(linewidth = 0.8) +
        ggplot2::scale_colour_manual(values = grays) +
        ggplot2::scale_linetype_manual(values = ltys) +
        ggplot2::labs(x = "Latitude (\u00b0)", y = "Relative envelope",
                      title = "Latitudinal envelope in selected years",
                      subtitle = sprintf(paste0("North expansion = %.2f, ",
                                                "south expansion = %.2f, ",
                                                "centre drift = %.1f\u00b0"),
                                         cfg$shift$north_expansion,
                                         cfg$shift$south_expansion,
                                         cfg$shift$center_drift)) +
        theme_pub()
}

#' @rdname biomass_figures
#' @param maps Include the maps (needs geometry).
#' @export
biomass_figures <- function(sim, maps = !is.null(sim$dom$geometry)) {
    need_pkg("ggplot2", "biomass_figures()")
    reg <- regional_summary(sim)
    out <- list(
        fig01_total_biomass = fig_total_biomass(sim),
        fig02_region_biomass = fig_region_biomass(sim, reg),
        fig03_region_share = fig_region_share(sim, reg),
        fig04_maps = if (maps) fig_maps(sim),
        fig05_centre_gravity = fig_centre_gravity(sim),
        fig06_hovmoller = fig_hovmoller(sim),
        fig07_base_habitat = if (maps) fig_base_habitat(sim),
        fig08_envelope_profiles = fig_envelope_profiles(sim))
    out[!vapply(out, is.null, logical(1))]
}

#' @rdname biomass_figures
#' @param dir Folder where the PNG files are written.
#' @param label Label appended to the file names.
#' @param verbose Print the file names.
#' @return `make_biomass_figures()`: invisible vector of file paths.
#' @export
make_biomass_figures <- function(sim, dir, label = sim$cfg$general$label,
                                 maps = !is.null(sim$dom$geometry),
                                 verbose = TRUE) {
    dir.create(dir, showWarnings = FALSE, recursive = TRUE)
    figs <- biomass_figures(sim, maps = maps)
    size <- list(fig01_total_biomass = c(NA, 6), fig04_maps = c(10, 9),
                 fig05_centre_gravity = c(11, 4.5),
                 fig07_base_habitat = c(11, 5.5))
    oc <- sim$cfg$output
    out <- vapply(names(figs), function(nm) {
        wh <- size[[nm]] %||% c(NA, NA)
        save_fig(figs[[nm]], file.path(dir, sprintf("%s_%s.png", nm, label)),
                 oc, width = if (is.na(wh[1])) NULL else wh[1],
                 height = if (is.na(wh[2])) NULL else wh[2],
                 verbose = verbose)
    }, character(1))
    invisible(unname(out))
}
