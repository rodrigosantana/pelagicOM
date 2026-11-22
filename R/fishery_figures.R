########################################################################
## Description: pelagicOM - diagnostic figures of the fishery truth
##              (Part II, module 14)
##
## Author: Rodrigo Sant'Ana
## Created: 2026-11-22
## Version: 0.1.0
##
### Commentary:
##
## Port of Experimento_02/Simulacao_Pesca/R/14_figures.R. Multi-panel
## figures use 'patchwork'; maps need 'sf' and the cell geometry.
##
### Code:
########################################################################

agg_mean <- function(x, by, FUN = mean) {
    a <- stats::aggregate(x, by = by, FUN = FUN)
    names(a)[ncol(a)] <- "value"
    a
}

scale_mean1 <- function(x) x / mean(x, na.rm = TRUE)

#' Figures of the fishery truth
#'
#' `fishery_figures()` returns the twelve diagnostic figures of
#' Experimento 02 as a named list of `ggplot` / `patchwork` objects;
#' `make_fishery_figures()` saves them as PNG files. The `fig_*`
#' functions build one figure each.
#'
#' @param fishery An `om_fishery` object.
#' @return A plot (or a list of them).
#' @name fishery_figures
NULL

#' @rdname fishery_figures
#' @export
fig_effort_time <- function(fishery) {
    td <- fishery$data
    fs <- fleet_style(names(fishery$cfg$fleets))
    s <- stats::aggregate(cbind(sets = 1, hooks = td$Hooks),
                          by = list(Year = td$Year, Fleet = td$Fleet), sum)
    d <- rbind(data.frame(s[, 1:2], value = s$sets, panel = "Sets per year"),
               data.frame(s[, 1:2], value = s$hooks / 1e6,
                          panel = "Hooks per year (millions)"))
    ggplot2::ggplot(d, ggplot2::aes(Year, value, colour = Fleet,
                                    linetype = Fleet)) +
        ggplot2::geom_line(linewidth = 0.7) +
        ggplot2::scale_colour_manual(values = fs$pal) +
        ggplot2::scale_linetype_manual(values = fs$lty) +
        ggplot2::facet_wrap(~panel, scales = "free_y") +
        ggplot2::labs(x = NULL, y = NULL,
                      title = "Simulated fishing effort by fleet") +
        theme_pub()
}

#' @rdname fishery_figures
#' @param years_sel Years of the maps (default `cfg$output$map_years`).
#' @export
fig_effort_maps <- function(fishery, years_sel = NULL) {
    truth <- fishery$truth
    require_geometry(list(geometry = truth$geometry), "fig_effort_maps()")
    td <- fishery$data
    yrs <- years_sel %||% fishery$cfg$output$map_years
    g <- truth$geometry
    L <- do.call(rbind, lapply(yrs, function(y) {
        n <- table(factor(td$Cell_ID[td$Year == y], levels = g$Cell_ID))
        gg <- g; gg$Sets <- as.numeric(n); gg$Year <- y
        gg$Sets[gg$Sets == 0] <- NA
        gg
    }))
    L$panel <- factor(L$Year)
    ggplot2::ggplot(L) +
        ggplot2::geom_sf(ggplot2::aes(fill = Sets), colour = NA) +
        ggplot2::scale_fill_gradient(low = "grey85", high = "black",
                                     transform = "sqrt", na.value = "grey97",
                                     name = "Sets per cell") +
        ggplot2::geom_hline(yintercept = truth$regions$breaks,
                            linetype = "22", colour = GRAY_MID,
                            linewidth = 0.3) +
        ggplot2::facet_wrap(~panel, ncol = 2) +
        ggplot2::coord_sf(expand = FALSE) +
        ggplot2::labs(x = NULL, y = NULL,
                      title = "Spatial distribution of fishing sets",
                      subtitle = paste("All fleets combined; light grey:",
                                       "domain cells without sets")) +
        theme_pub(base = 10) +
        ggplot2::theme(legend.position = "right",
                       legend.title = ggplot2::element_text(size = 9),
                       panel.grid.major = ggplot2::element_blank())
}

#' @rdname fishery_figures
#' @export
fig_gear <- function(fishery) {
    need_pkg("patchwork", "fig_gear()")
    td <- fishery$data; cfg <- fishery$cfg
    fs <- fleet_style(names(cfg$fleets))
    ss <- strategy_style(cfg$strategies$levels)
    h <- agg_mean(td$Hooks, list(Year = td$Year, Fleet = td$Fleet),
                  stats::median)
    b <- agg_mean(td$HooksBetweenFloats,
                  list(Year = td$Year, Strategy = td$TrueFishingStrategy),
                  stats::median)
    p1 <- ggplot2::ggplot(h, ggplot2::aes(Year, value, colour = Fleet,
                                          linetype = Fleet)) +
        ggplot2::geom_line(linewidth = 0.7) +
        ggplot2::scale_colour_manual(values = fs$pal) +
        ggplot2::scale_linetype_manual(values = fs$lty) +
        ggplot2::labs(x = NULL, y = "Median hooks per set",
                      title = "Effort unit: hooks per set") + theme_pub()
    p2 <- ggplot2::ggplot(b, ggplot2::aes(Year, value, colour = Strategy,
                                          linetype = Strategy)) +
        ggplot2::geom_line(linewidth = 0.7) +
        ggplot2::scale_colour_manual(values = ss$pal) +
        ggplot2::scale_linetype_manual(values = ss$lty) +
        ggplot2::labs(x = NULL, y = "Median hooks between floats",
                      title = "Gear configuration: HBF by true strategy") +
        theme_pub()
    patchwork::wrap_plots(p1, p2, ncol = 2)
}

#' @rdname fishery_figures
#' @export
fig_strategy <- function(fishery) {
    td <- fishery$data
    ss <- strategy_style(fishery$cfg$strategies$levels)
    tab <- as.data.frame(prop.table(table(Year = td$Year, Fleet = td$Fleet,
                                          Strategy = td$TrueFishingStrategy),
                                    c(1, 2)), responseName = "share")
    tab <- tab[!is.nan(tab$share), ]
    tab$Year <- as.integer(as.character(tab$Year))
    ggplot2::ggplot(tab, ggplot2::aes(Year, share, colour = Strategy,
                                      linetype = Strategy)) +
        ggplot2::geom_line(linewidth = 0.7) +
        ggplot2::scale_colour_manual(values = ss$pal) +
        ggplot2::scale_linetype_manual(values = ss$lty) +
        ggplot2::facet_wrap(~Fleet, ncol = length(fishery$cfg$fleets)) +
        ggplot2::scale_y_continuous(limits = c(0, 1)) +
        ggplot2::labs(x = NULL, y = "Share of sets",
                      title = "True fishing strategy composition by fleet") +
        theme_pub()
}

#' @rdname fishery_figures
#' @export
fig_catchability_time <- function(fishery) {
    need_pkg("patchwork", "fig_catchability_time()")
    td <- fishery$data
    fs <- fleet_style(names(fishery$cfg$fleets))
    a <- agg_mean(td$log_q, list(Year = td$Year, Fleet = td$Fleet))
    comp <- stats::aggregate(cbind(HBF = td$q_hbf, Creep = td$q_creep,
                                   Strategy = td$q_strategy,
                                   Vessel = td$q_vessel),
                             by = list(Year = td$Year), mean)
    cl <- stats::reshape(comp, direction = "long", varying = names(comp)[-1],
                         v.names = "value", timevar = "component",
                         times = names(comp)[-1], idvar = "Year")
    p1 <- ggplot2::ggplot(a, ggplot2::aes(Year, value, colour = Fleet,
                                          linetype = Fleet)) +
        ggplot2::geom_line(linewidth = 0.7) +
        ggplot2::scale_colour_manual(values = fs$pal) +
        ggplot2::scale_linetype_manual(values = fs$lty) +
        ggplot2::labs(x = NULL, y = "mean log q",
                      title = "True catchability over time, by fleet") +
        theme_pub()
    p2 <- ggplot2::ggplot(cl, ggplot2::aes(Year, value, linetype = component,
                                           colour = component)) +
        ggplot2::geom_line(linewidth = 0.7) +
        ggplot2::scale_colour_manual(values = c("black", "grey30", "grey50",
                                                "grey70")) +
        ggplot2::labs(x = NULL, y = "mean component of log q",
                      title = "Components of log q (all fleets)") +
        theme_pub()
    patchwork::wrap_plots(p1, p2, ncol = 2)
}

#' @rdname fishery_figures
#' @export
fig_catchability_factors <- function(fishery) {
    need_pkg("patchwork", "fig_catchability_factors()")
    td <- fishery$data; cfg <- fishery$cfg
    td$HBF_bin <- as.character(cut(td$HooksBetweenFloats,
                                   cfg$gear$hbf_bin_breaks))
    f <- function(by, lab) {
        a <- agg_mean(td$log_q, list(level = td[[by]]))
        a$factor <- lab; a
    }
    d <- rbind(f("Fleet", "Fleet"), f("TrueFishingStrategy", "Strategy"),
               f("Region", "Region"), f("HBF_bin", "HBF (bins)"),
               f("Quarter", "Quarter"))
    d$factor <- factor(d$factor, levels = unique(d$factor))
    rg <- cfg$gear$hbf_range
    hb <- data.frame(HBF = rg[1]:rg[2])
    hb$value <- hbf_effect_fun(hb$HBF, cfg$catchability$hbf)
    p1 <- ggplot2::ggplot(d, ggplot2::aes(level, value)) +
        ggplot2::geom_col(fill = "grey35") +
        ggplot2::facet_wrap(~factor, scales = "free_x", nrow = 1) +
        ggplot2::labs(x = NULL, y = "mean log q",
                      title = "True catchability by factor") + theme_pub() +
        ggplot2::theme(axis.text.x = ggplot2::element_text(angle = 45,
                                                           hjust = 1))
    p2 <- ggplot2::ggplot(hb, ggplot2::aes(HBF, value)) +
        ggplot2::geom_line(linewidth = 0.9) +
        ggplot2::geom_vline(xintercept = cfg$catchability$hbf$ref,
                            linetype = "22", colour = GRAY_MID) +
        ggplot2::labs(x = "Hooks between floats", y = "f(HBF) in log q",
                      title = "Generating HBF effect (saturating)") +
        theme_pub()
    patchwork::wrap_plots(p1, p2, ncol = 1, heights = c(1, 0.8))
}

#' @rdname fishery_figures
#' @export
fig_vessel_effects <- function(fishery) {
    v <- unique(fishery$data[, c("Fleet", "VesselID", "q_vessel")])
    ggplot2::ggplot(v, ggplot2::aes(Fleet, q_vessel)) +
        ggplot2::geom_boxplot(outlier.shape = 1, fill = "grey90") +
        ggplot2::geom_jitter(width = 0.15, size = 0.7, colour = GRAY_MID) +
        ggplot2::labs(x = NULL, y = "vessel effect in log q",
                      title = "True vessel effects by fleet") + theme_pub()
}

#' @rdname fishery_figures
#' @export
fig_catch_distribution <- function(fishery) {
    need_pkg("patchwork", "fig_catch_distribution()")
    td <- fishery$data
    fs <- fleet_style(names(fishery$cfg$fleets))
    pos <- td[td$TrueCatch > 0, ]
    z <- agg_mean(td$TrueCatch == 0, list(Year = td$Year, Fleet = td$Fleet))
    p1 <- ggplot2::ggplot(pos, ggplot2::aes(TrueCatch)) +
        ggplot2::geom_histogram(bins = 40, fill = "grey40", colour = "white",
                                linewidth = 0.2) +
        ggplot2::scale_x_log10(breaks = c(0.001, 0.01, 0.1, 1, 10),
                               labels = c("0.001", "0.01", "0.1", "1",
                                          "10")) +
        ggplot2::facet_wrap(~Fleet, nrow = 1, scales = "free_y") +
        ggplot2::labs(x = "Catch per set (t, positive sets, log scale)",
                      y = "Sets", title = "Distribution of positive catches") +
        theme_pub()
    p2 <- ggplot2::ggplot(z, ggplot2::aes(Year, value, colour = Fleet,
                                          linetype = Fleet)) +
        ggplot2::geom_line(linewidth = 0.7) +
        ggplot2::scale_colour_manual(values = fs$pal) +
        ggplot2::scale_linetype_manual(values = fs$lty) +
        ggplot2::scale_y_continuous(limits = c(0, 1)) +
        ggplot2::labs(x = NULL, y = "Proportion of zero-catch sets",
                      title = "Zero catches over time") + theme_pub()
    patchwork::wrap_plots(p1, p2, ncol = 1)
}

#' @rdname fishery_figures
#' @param tab_global,tab_region Outputs of [cpue_biomass_table()]
#'   (global and by region).
#' @export
fig_cpue_vs_biomass <- function(fishery,
                                tab_global = cpue_biomass_table(fishery$data,
                                                                fishery$truth),
                                tab_region = cpue_biomass_table(fishery$data,
                                                                fishery$truth,
                                                                "Region")) {
    need_pkg("patchwork", "fig_cpue_vs_biomass()")
    g <- tab_global
    d1 <- rbind(data.frame(Year = g$Year, value = scale_mean1(g$RawCPUE),
                           series = "Nominal CPUE (t/1000 hooks)"),
                data.frame(Year = g$Year, value = scale_mean1(g$ExpectedCPUE),
                           series = "Expected CPUE (no catch noise)"),
                data.frame(Year = g$Year, value = scale_mean1(g$B_total),
                           series = "True total biomass"))
    p1 <- ggplot2::ggplot(d1, ggplot2::aes(Year, value, colour = series,
                                           linetype = series)) +
        ggplot2::geom_line(linewidth = 0.8) +
        ggplot2::scale_colour_manual(values = c("grey30", "grey60", "black")) +
        ggplot2::scale_linetype_manual(values = c("solid", "22", "solid")) +
        ggplot2::labs(x = NULL, y = "Relative to series mean",
                      title = "Global nominal CPUE vs true biomass") +
        theme_pub()
    p2 <- ggplot2::ggplot(g, ggplot2::aes(B_total / 1e3, RawCPUE)) +
        ggplot2::geom_path(colour = GRAY_LIGHT) +
        ggplot2::geom_point(ggplot2::aes(shape = Year >= 1990), size = 1.8) +
        ggplot2::scale_shape_manual(values = c(1, 16),
                                    labels = c("before 1990", "1990 onwards")) +
        ggplot2::scale_x_log10() + ggplot2::scale_y_log10() +
        ggplot2::labs(x = "True total biomass (thousand t, log)",
                      y = "Nominal CPUE (t / 1000 hooks, log)",
                      title = "Log-log relationship") + theme_pub()
    r <- tab_region
    d3 <- rbind(data.frame(Year = r$Year, Region = r$level,
                           value = NA, series = "Nominal CPUE"),
                data.frame(Year = r$Year, Region = r$level,
                           value = NA, series = "True regional biomass"))
    for (lv in unique(r$level)) {
        i <- r$level == lv
        d3$value[d3$Region == lv & d3$series == "Nominal CPUE"] <-
            scale_mean1(r$RawCPUE[i])
        d3$value[d3$Region == lv & d3$series == "True regional biomass"] <-
            scale_mean1(r$TrueBiomassRef[i])
    }
    p3 <- ggplot2::ggplot(d3, ggplot2::aes(Year, value, linetype = series,
                                           colour = series)) +
        ggplot2::geom_line(linewidth = 0.7) +
        ggplot2::scale_colour_manual(values = c("grey40", "black")) +
        ggplot2::scale_linetype_manual(values = c("solid", "22")) +
        ggplot2::facet_wrap(~Region, nrow = 1) +
        ggplot2::labs(x = NULL, y = "Relative to series mean",
                      title = paste("Regional nominal CPUE vs regional",
                                    "true biomass")) +
        theme_pub()
    patchwork::wrap_plots(patchwork::wrap_plots(p1, p2, ncol = 2,
                                                widths = c(1.4, 1)),
                          p3, ncol = 1)
}

#' @rdname fishery_figures
#' @param tab_fleet,tab_strategy Outputs of [cpue_biomass_table()] by
#'   fleet and by true strategy.
#' @export
fig_cpue_fleet_strategy <- function(fishery,
                                    tab_fleet = cpue_biomass_table(
                                        fishery$data, fishery$truth, "Fleet"),
                                    tab_strategy = cpue_biomass_table(
                                        fishery$data, fishery$truth,
                                        "TrueFishingStrategy")) {
    need_pkg("patchwork", "fig_cpue_fleet_strategy()")
    pop <- fishery$truth$pop; cfg <- fishery$cfg
    fs <- fleet_style(names(cfg$fleets))
    ss <- strategy_style(cfg$strategies$levels)
    mk <- function(tab, lab, pal, lty) {
        tab$value <- stats::ave(tab$RawCPUE, tab$level, FUN = scale_mean1)
        b <- data.frame(Year = pop$Year, value = scale_mean1(pop$B_total))
        ggplot2::ggplot(tab, ggplot2::aes(Year, value, colour = level,
                                          linetype = level)) +
            ggplot2::geom_line(data = b, ggplot2::aes(Year, value),
                               inherit.aes = FALSE, colour = "grey75",
                               linewidth = 2) +
            ggplot2::geom_line(linewidth = 0.7) +
            ggplot2::scale_colour_manual(values = pal) +
            ggplot2::scale_linetype_manual(values = lty) +
            ggplot2::labs(x = NULL, y = "Relative to series mean",
                          title = paste("Nominal CPUE by", lab),
                          subtitle = "Thick grey line: true total biomass") +
            theme_pub()
    }
    patchwork::wrap_plots(mk(tab_fleet, "fleet", fs$pal, fs$lty),
                          mk(tab_strategy, "true strategy", ss$pal, ss$lty),
                          ncol = 2)
}

#' @rdname fishery_figures
#' @param scenarios An `om_scenarios` object ([generate_scenarios()]).
#' @param profile Observation profile shown.
#' @export
fig_observation_quality <- function(fishery, scenarios, profile = "temporal") {
    o <- scenarios$observed[[profile]]
    if (is.null(o)) stop("profile '", profile, "' not in the scenarios")
    td <- fishery$data
    m <- stats::aggregate(cbind(HBF_missing = is.na(o$HooksBetweenFloats),
                                Strategy_missing = is.na(o$FishingStrategy),
                                Vessel_missing = is.na(o$VesselID),
                                Cell_unknown = is.na(o$Cell_ID)),
                          by = list(Year = o$Year), mean)
    n_true <- table(td$Year); n_obs <- table(o$Year)
    m$Records_lost <- 1 - as.numeric(n_obs[as.character(m$Year)]) /
                      as.numeric(n_true[as.character(m$Year)])
    L <- stats::reshape(m, direction = "long", varying = names(m)[-1],
                        v.names = "value", timevar = "mechanism",
                        times = names(m)[-1], idvar = "Year")
    ggplot2::ggplot(L, ggplot2::aes(Year, value)) +
        ggplot2::geom_line(linewidth = 0.7) +
        ggplot2::facet_wrap(~mechanism, nrow = 1) +
        ggplot2::scale_y_continuous(limits = c(0, 1)) +
        ggplot2::labs(x = NULL, y = "Proportion of sets",
                      title = sprintf(paste("Observation profile '%s':",
                                            "information loss by year"),
                                      profile)) +
        theme_pub()
}

#' @rdname fishery_figures
#' @export
fig_species_composition <- function(fishery) {
    td <- fishery$data; cfg <- fishery$cfg
    a <- species_composition_table(td, cfg, "TrueFishingStrategy")
    b <- species_composition_table(td, cfg, "Fleet")
    names(a)[1] <- "level"; names(b)[1] <- "level"
    a$panel <- "By true strategy"; b$panel <- "By fleet"
    d <- rbind(a, b)
    d$species <- factor(d$species, levels = c(cfg$species$target,
                                              cfg$species$companions))
    d$panel <- factor(d$panel, levels = c("By true strategy", "By fleet"))
    grays <- grDevices::gray.colors(nlevels(d$species), start = 0.05,
                                    end = 0.85)
    ggplot2::ggplot(d, ggplot2::aes(level, share_of_total, fill = species)) +
        ggplot2::geom_col(colour = "white", linewidth = 0.3) +
        ggplot2::scale_fill_manual(values = grays) +
        ggplot2::facet_wrap(~panel, scales = "free_x") +
        ggplot2::labs(x = NULL, y = "Share of total catch (t)",
                      title = "Species composition of the catch",
                      subtitle = paste("Target species first; composition",
                                       "is the signature of the latent",
                                       "strategy")) +
        theme_pub()
}

#' @rdname fishery_figures
#' @param maps Include the effort maps (needs geometry).
#' @export
fishery_figures <- function(fishery, scenarios = NULL,
                            maps = !is.null(fishery$truth$geometry)) {
    need_pkg("ggplot2", "fishery_figures()")
    td <- fishery$data; truth <- fishery$truth; cfg <- fishery$cfg
    tg <- cpue_biomass_table(td, truth)
    tr <- cpue_biomass_table(td, truth, "Region")
    tf <- cpue_biomass_table(td, truth, "Fleet")
    ts <- cpue_biomass_table(td, truth, "TrueFishingStrategy")
    out <- list(
        fig01_effort_time = fig_effort_time(fishery),
        fig02_effort_maps = if (maps) fig_effort_maps(fishery),
        fig03_gear = fig_gear(fishery),
        fig04_strategy = fig_strategy(fishery),
        fig05_catchability_time = fig_catchability_time(fishery),
        fig06_catchability_factors = fig_catchability_factors(fishery),
        fig07_vessel_effects = fig_vessel_effects(fishery),
        fig08_catch_distribution = fig_catch_distribution(fishery),
        fig09_cpue_vs_biomass = fig_cpue_vs_biomass(fishery, tg, tr),
        fig10_cpue_fleet_strategy = fig_cpue_fleet_strategy(fishery, tf, ts))
    if (isTRUE(cfg$species$enabled))
        out$fig12_species_composition <- fig_species_composition(fishery)
    if (!is.null(scenarios$observed$temporal))
        out$fig11_observation_quality <- fig_observation_quality(fishery,
                                                                 scenarios)
    out[!vapply(out, is.null, logical(1))]
}

#' @rdname fishery_figures
#' @param dir Folder where the PNG files are written.
#' @param label Label appended to the file names.
#' @param verbose Print the file names.
#' @return `make_fishery_figures()`: invisible vector of file paths.
#' @export
make_fishery_figures <- function(fishery, scenarios = NULL, dir,
                                 label = fishery$cfg$general$label,
                                 maps = !is.null(fishery$truth$geometry),
                                 verbose = TRUE) {
    dir.create(dir, showWarnings = FALSE, recursive = TRUE)
    figs <- fishery_figures(fishery, scenarios, maps = maps)
    size <- list(fig01_effort_time = c(11, 4.5), fig02_effort_maps = c(10, 9),
                 fig03_gear = c(11, 4.5), fig04_strategy = c(12, 3.8),
                 fig05_catchability_time = c(11, 4.5),
                 fig06_catchability_factors = c(11, 8),
                 fig07_vessel_effects = c(7, 4.5),
                 fig08_catch_distribution = c(11, 7.5),
                 fig09_cpue_vs_biomass = c(11, 9),
                 fig10_cpue_fleet_strategy = c(12, 4.8),
                 fig11_observation_quality = c(12, 3.5),
                 fig12_species_composition = c(10, 4.5))
    oc <- fishery$cfg$output
    out <- vapply(names(figs), function(nm) {
        wh <- size[[nm]]
        save_fig(figs[[nm]], file.path(dir, sprintf("%s_%s.png", nm, label)),
                 oc, width = wh[1], height = wh[2], verbose = verbose)
    }, character(1))
    invisible(unname(out))
}
