########################################################################
## Description: pelagicOM - configuration of the longline fishery
##              (Part II): presets, validation
##
## Author: Rodrigo Sant'Ana
## Created: 2026-11-22
## Version: 0.1.0
##
### Commentary:
##
## Same structure as FISHERY_CONFIG in
## Experimento_02/Simulacao_Pesca/R/00_config.R (without paths). The
## package generalises what was fixed in the experiment: any number of
## fleets with any names, any set of latitudinal regions (checked against
## the biomass truth when the fishery is simulated), and the strategy
## whose odds drift in time (strategies$drift_level). Defaults reproduce
## Experimento 02.
##
## Fundamental distinction kept throughout:
##   EFFORT          = Hooks (hooks per set)
##   CATCHABILITY    = everything in log q (fleet, vessel, strategy, HBF,
##                     creep, space, residual)
##
### Code:
########################################################################

#' Fishery (Part II) configuration
#'
#' Returns the full list of parameters of the pelagic longline fishery
#' generator: fleets, vessels and their careers, trips, sets, effort
#' (hooks), gear (hooks between floats, HBF), latent fishing strategies,
#' spatial behaviour of the fleets (preferential sampling, fidelity,
#' expansion), the components of log catchability, the catch process
#' (Tweedie or delta-lognormal), companion species, observation profiles
#' and the scenario data sets. The `"BET_ICCAT"` preset is the
#' configuration of Experimento 02 (five fleets A-E, target BET,
#' companions YFT, ALB, SWO, BSH, eight scenarios).
#'
#' Every stochastic component has its own seed
#' (`reproducibility$seeds`), so that changing one process does not
#' reshuffle the draws of the others.
#'
#' @inheritParams om_biomass_config
#' @return A list of class `om_fishery_config`.
#' @seealso [om_biomass_config()], [simulate_fishery()],
#'   [generate_scenarios()].
#' @examples
#' fcfg <- om_fishery_config("BET_ICCAT")
#' names(fcfg$fleets)
#' ## halve the size of fleet A and switch off creep
#' fcfg2 <- om_fishery_config("BET_ICCAT",
#'                            fleets = list(A = list(n_vessels = 20)),
#'                            catchability = list(creep_enabled = FALSE))
#' fcfg2$fleets$A$n_vessels
#' @export
om_fishery_config <- function(preset = "BET_ICCAT", ...) {
    preset <- match.arg(preset, om_presets()$preset)
    cfg <- switch(preset, BET_ICCAT = fishery_config_bet_iccat())
    class(cfg) <- c("om_fishery_config", "list")
    upd <- list(...)
    if (length(upd)) cfg <- om_config_update(cfg, upd)
    cfg <- validate_fishery_config(cfg)
    cfg
}

######@> Experimento 02 / BET (values of FISHERY_CONFIG, 2026-10-05
######@> revision: 8-15 sets per trip and companion species)...
fishery_config_bet_iccat <- function() {
    list(
        general = list(
            label = "base"
        ),
        reproducibility = list(
            seeds = list(
                vessels      = 20261101,
                trips        = 20261102,
                sets         = 20261103,
                spatial      = 20261104,
                strategy     = 20261105,
                gear         = 20261106,
                catchability = 20261107,
                catch        = 20261108,
                species      = 20261110,
                observation  = 20261109
            )
        ),
        temporal = list(
            year_start = 1950,
            year_end   = 2025,
            quarters   = 1:4,
            biomass_within_year = "constant"
        ),
        fleets = list(
            A = list(n_vessels = 45, year_start = 1950, year_end = 2025,
                     regions = c("R01", "R02"),
                     core_lon = -45, core_lat = 12, core_sd = 20,
                     quarter_weights = c(0.25, 0.30, 0.25, 0.20),
                     hooks_median = c("1950" = 1300, "1980" = 1900,
                                      "2025" = 2300),
                     hbf_mult = 1.0,
                     strategy_comp = c(S1 = 0.55, S2 = 0.30, S3 = 0.15),
                     q_effect = 0.00),
            B = list(n_vessels = 40, year_start = 1950, year_end = 2025,
                     regions = c("R01", "R02"),
                     core_lon = -25, core_lat = 8, core_sd = 20,
                     quarter_weights = c(0.20, 0.25, 0.30, 0.25),
                     hooks_median = c("1950" = 1200, "1980" = 1800,
                                      "2025" = 2000),
                     hbf_mult = 1.1,
                     strategy_comp = c(S1 = 0.60, S2 = 0.25, S3 = 0.15),
                     q_effect = 0.10),
            C = list(n_vessels = 35, year_start = 1958, year_end = 2025,
                     regions = c("R01", "R02"),
                     core_lon = -15, core_lat = 22, core_sd = 18,
                     quarter_weights = c(0.30, 0.25, 0.20, 0.25),
                     hooks_median = c("1950" = 1000, "1980" = 1500,
                                      "2025" = 1800),
                     hbf_mult = 0.8,
                     strategy_comp = c(S1 = 0.20, S2 = 0.35, S3 = 0.45),
                     q_effect = -0.35),
            D = list(n_vessels = 40, year_start = 1962, year_end = 2025,
                     regions = c("R02", "R03"),
                     core_lon = -30, core_lat = -8, core_sd = 20,
                     quarter_weights = c(0.25, 0.25, 0.25, 0.25),
                     hooks_median = c("1950" = 1300, "1980" = 1900,
                                      "2025" = 2200),
                     hbf_mult = 1.0,
                     strategy_comp = c(S1 = 0.50, S2 = 0.35, S3 = 0.15),
                     q_effect = -0.10),
            E = list(n_vessels = 30, year_start = 1968, year_end = 2025,
                     regions = c("R02", "R03"),
                     core_lon = 0, core_lat = -18, core_sd = 18,
                     quarter_weights = c(0.20, 0.30, 0.30, 0.20),
                     hooks_median = c("1950" = 900, "1980" = 1400,
                                      "2025" = 1700),
                     hbf_mult = 0.9,
                     strategy_comp = c(S1 = 0.15, S2 = 0.35, S3 = 0.50),
                     q_effect = -0.25)
        ),
        vessels = list(
            turnover_enabled = TRUE,
            career_mean = 18,
            career_sd   = 6,
            career_min  = 3
        ),
        trips = list(
            per_vessel_year = c(5, 10)
        ),
        sets = list(
            per_vessel_year = c(8, 15),
            per_trip        = c(8, 15),
            unit            = "per_trip"
        ),
        effort = list(
            hooks_range   = c(700, 2500),
            hooks_cv      = 0.15,
            trend_enabled = TRUE
        ),
        gear = list(
            hbf_range = c(4, 26),
            hbf_by_strategy = list(
                S1 = c("1950" = 6, "1975" = 8, "1985" = 13, "2025" = 16),
                S2 = c("1950" = 5, "1975" = 6, "1990" = 9,  "2025" = 10),
                S3 = c("1950" = 4, "2025" = 6)
            ),
            hbf_vessel_sd = 0.10,
            hbf_sd        = 0.18,
            trend_enabled = TRUE,
            ## HBF classes used only by diagnostics and figures
            hbf_bin_breaks = c(3, 6, 9, 12, 15, 18, 26)
        ),
        strategies = list(
            levels        = c("S1", "S2", "S3"),
            drift_enabled = TRUE,
            drift_level   = "S1",
            drift_S1_odds = c("1950" = 1.0, "2025" = 1.8),
            misclassification = 0
        ),
        spatial = list(
            preferential_sampling_strength = 1.0,
            fidelity                 = 0.5,
            core_preference_enabled  = TRUE,
            expansion_enabled        = TRUE,
            expansion_profile        = c("0" = 0.30, "25" = 0.70, "50" = 1.0),
            density_floor            = 1e-6
        ),
        catchability = list(
            q0              = 0.01,
            vessel_sd       = 0.30,
            strategy_effect = c(S1 = 0, S2 = -0.7, S3 = -1.6),
            hbf = list(effect = 1.2, rate = 0.15, ref = 8,
                       by_fleet = c(A = 1, B = 1, C = 1, D = 1, E = 1)),
            creep           = 0.01,
            creep_enabled   = TRUE,
            quarter_effect  = c(0, 0, 0, 0),
            region_effect   = c(R01 = 0, R02 = 0, R03 = 0),
            spatial         = list(enabled = TRUE, sd = 0.15, range = 4),
            residual_sd     = 0.10
        ),
        catch_process = list(
            distribution = "tweedie",
            power        = 1.4,
            dispersion   = 1.0,
            delta = list(logit_a = 1.0, logit_b = 1.0, sdlog = 0.8)
        ),
        species = list(
            enabled    = TRUE,
            target     = "BET",
            companions = c("YFT", "ALB", "SWO", "BSH"),
            params = list(
                YFT = list(ref = 0.35,
                           strategy_effect = c(S1 = 0.0, S2 = 0.8, S3 = -0.6),
                           hbf_effect = -0.4,
                           lat_center = 5, lat_sd = 15, use_abs_lat = FALSE,
                           trend = c("1950" = 1.0, "2025" = 0.6)),
                ALB = list(ref = 0.25,
                           strategy_effect = c(S1 = 0.2, S2 = 1.0, S3 = -1.5),
                           hbf_effect = 0.3,
                           lat_center = 25, lat_sd = 10, use_abs_lat = TRUE,
                           trend = c("1950" = 1.0, "2025" = 0.7)),
                SWO = list(ref = 0.45,
                           strategy_effect = c(S1 = -2.0, S2 = -1.0, S3 = 0.0),
                           hbf_effect = -0.9,
                           lat_center = 20, lat_sd = 20, use_abs_lat = TRUE,
                           trend = c("1950" = 1.0, "2025" = 0.8)),
                BSH = list(ref = 0.40,
                           strategy_effect = c(S1 = -1.8, S2 = -1.0, S3 = 0.0),
                           hbf_effect = -0.8,
                           lat_center = 25, lat_sd = 15, use_abs_lat = TRUE,
                           trend = c("1950" = 1.0, "2025" = 1.0))
            ),
            power       = 1.4,
            dispersion  = 1.0,
            residual_sd = 0.20,
            cluster_sample = 50000
        ),
        observation = list(
            complete = list(
                list(period = c(1950, 2025), position_sd = 0,
                     coord_resolution = 1, hbf_missing = 0, hooks_cv = 0,
                     hooks_round = 1, catch_cv = 0, catch_round = 0,
                     strategy_missing = 0, vessel_missing = 0,
                     record_loss = 0)
            ),
            temporal = list(
                list(period = c(1950, 1980), position_sd = 0.5,
                     coord_resolution = 5, hbf_missing = 0.60,
                     hooks_cv = 0.15, hooks_round = 100, catch_cv = 0.20,
                     catch_round = 0.1, strategy_missing = 0.40,
                     vessel_missing = 0.30, record_loss = 0.15),
                list(period = c(1981, 2025), position_sd = 0,
                     coord_resolution = 1, hbf_missing = 0, hooks_cv = 0,
                     hooks_round = 1, catch_cv = 0, catch_round = 0,
                     strategy_missing = 0, vessel_missing = 0,
                     record_loss = 0)
            )
        ),
        scenarios = list(
            list(name = "01_global_complete",
                 regions = c("R01", "R02", "R03"), drop = character(0),
                 observation = "complete",
                 objective = "Referencia: todas as regioes e variaveis"),
            list(name = "02_global_without_hbf",
                 regions = c("R01", "R02", "R03"),
                 drop = "HooksBetweenFloats", observation = "complete",
                 objective = "Efeito da ausencia de HBF (global)"),
            list(name = "03_R02_complete",
                 regions = "R02", drop = character(0),
                 observation = "complete",
                 objective = paste("Regiao central de maior abundancia e",
                                   "sobreposicao de frotas")),
            list(name = "04_global_temporal_uncertainty",
                 regions = c("R01", "R02", "R03"), drop = character(0),
                 observation = "temporal",
                 objective = "Qualidade dos dados inferior em 1950-1980 (global)"),
            list(name = "05_R02_temporal_uncertainty",
                 regions = "R02", drop = character(0),
                 observation = "temporal",
                 objective = "Qualidade dos dados inferior em 1950-1980 (R02)"),
            list(name = "06_R01_complete",
                 regions = "R01", drop = character(0),
                 observation = "complete",
                 objective = "Regional R01 completo"),
            list(name = "07_R03_complete",
                 regions = "R03", drop = character(0),
                 observation = "complete",
                 objective = "Regional R03 completo"),
            list(name = "08_R02_without_hbf",
                 regions = "R02", drop = "HooksBetweenFloats",
                 observation = "complete",
                 objective = "Ausencia de HBF em analise regional (R02)")
        ),
        output = list(
            save_csv     = TRUE,
            save_figures = TRUE,
            map_years    = c(1955, 1975, 2000, 2025),
            fig_width    = 9,
            fig_height   = 5.5,
            fig_dpi      = 200
        )
    )
}

######@> Fields added by the package, filled with neutral defaults so that
######@> configurations saved by Experimento_02 are accepted...
normalize_fishery_config <- function(cfg) {
    cfg$strategies$drift_level <- cfg$strategies$drift_level %||%
        cfg$strategies$levels[1]
    cfg$gear$hbf_bin_breaks <- cfg$gear$hbf_bin_breaks %||%
        c(3, 6, 9, 12, 15, 18, 26)
    ###@> Fleets without an HBF-effect multiplier get the neutral value 1...
    bf <- cfg$catchability$hbf$by_fleet
    miss <- setdiff(names(cfg$fleets), names(bf))
    if (length(miss))
        cfg$catchability$hbf$by_fleet <- c(bf, stats::setNames(
            rep(1, length(miss)), miss))
    if (!inherits(cfg, "om_fishery_config"))
        class(cfg) <- c("om_fishery_config", "list")
    cfg
}

#' Specification of a fleet
#'
#' Helper that returns the list describing one fleet, with the fields
#' used by [om_fishery_config()]. Defaults are those of fleet A of
#' Experimento 02. Assign the result to `cfg$fleets$<name>` (or pass it
#' through [om_config_update()]).
#'
#' @param n_vessels Number of vessel slots kept active (turnover replaces
#'   retiring vessels).
#' @param year_start,year_end Period of activity.
#' @param regions Regions the fleet can fish in (labels of the domain).
#' @param core_lon,core_lat,core_sd Centre (degrees) and spread of the
#'   baseline spatial preference; cells are also made available from the
#'   centre outwards as the fleet expands.
#' @param quarter_weights Relative frequency of trips per quarter (4).
#' @param hooks_median Anchors (named by year) of the median hooks per set.
#' @param hbf_mult Multiplier of the hooks between floats of the fleet.
#' @param strategy_comp Composition of fishing strategies (sums to 1,
#'   names = strategy levels).
#' @param q_effect Fleet effect on log catchability.
#' @return A list.
#' @examples
#' fcfg <- om_fishery_config()
#' fcfg$fleets$F <- om_fleet(n_vessels = 15, year_start = 1990,
#'                           regions = "R02", core_lon = -10, core_lat = 0)
#' names(fcfg$fleets)
#' @export
om_fleet <- function(n_vessels = 45, year_start = 1950, year_end = 2025,
                     regions = c("R01", "R02"), core_lon = -45,
                     core_lat = 12, core_sd = 20,
                     quarter_weights = c(0.25, 0.30, 0.25, 0.20),
                     hooks_median = c("1950" = 1300, "1980" = 1900,
                                      "2025" = 2300),
                     hbf_mult = 1.0,
                     strategy_comp = c(S1 = 0.55, S2 = 0.30, S3 = 0.15),
                     q_effect = 0) {
    list(n_vessels = n_vessels, year_start = year_start, year_end = year_end,
         regions = regions, core_lon = core_lon, core_lat = core_lat,
         core_sd = core_sd, quarter_weights = quarter_weights,
         hooks_median = hooks_median, hbf_mult = hbf_mult,
         strategy_comp = strategy_comp, q_effect = q_effect)
}

#' @describeIn om_fishery_config Checks the internal coherence of a
#'   fishery configuration. Region names are checked later, against the
#'   biomass truth, by [simulate_fishery()].
#' @param cfg A fishery configuration.
#' @export
validate_fishery_config <- function(cfg) {
    cfg <- normalize_fishery_config(cfg)
    tp <- cfg$temporal
    stopifnot(tp$year_end > tp$year_start,
              identical(as.integer(tp$quarters), 1:4),
              tp$biomass_within_year == "constant")
    my <- cfg$output$map_years
    if (length(my) && any(my < tp$year_start | my > tp$year_end))
        stop("output$map_years (", paste(my, collapse = ", "),
             ") must lie within ", tp$year_start, "-", tp$year_end)
    fl <- names(cfg$fleets)
    if (!length(fl) || anyDuplicated(fl) || any(!nzchar(fl)))
        stop("fleets must be a non-empty list with unique names")
    for (nm in fl) {
        f <- cfg$fleets[[nm]]
        need <- c("n_vessels", "year_start", "year_end", "regions",
                  "core_lon", "core_lat", "core_sd", "quarter_weights",
                  "hooks_median", "hbf_mult", "strategy_comp", "q_effect")
        miss <- setdiff(need, names(f))
        if (length(miss))
            stop("fleet '", nm, "' is missing: ", paste(miss, collapse = ", "))
        stopifnot(f$n_vessels >= 1,
                  f$year_start >= tp$year_start, f$year_end <= tp$year_end,
                  f$year_start <= f$year_end,
                  length(f$regions) >= 1,
                  length(f$quarter_weights) == 4,
                  all(f$quarter_weights > 0),
                  abs(sum(f$strategy_comp) - 1) < 1e-8,
                  identical(names(f$strategy_comp), cfg$strategies$levels),
                  f$core_sd > 0, f$hbf_mult > 0,
                  !is.null(names(f$hooks_median)))
        if (!nm %in% names(cfg$catchability$hbf$by_fleet))
            stop("catchability$hbf$by_fleet has no entry for fleet '", nm, "'")
    }
    stopifnot(cfg$vessels$career_min >= 1, cfg$vessels$career_mean > 0)
    stopifnot(cfg$trips$per_vessel_year[1] >= 1,
              diff(cfg$trips$per_vessel_year) >= 0,
              cfg$sets$per_vessel_year[1] >= 1,
              cfg$sets$unit %in% c("per_vessel_year", "per_trip"))
    stopifnot(cfg$effort$hooks_range[1] > 0,
              diff(cfg$effort$hooks_range) > 0, cfg$effort$hooks_cv >= 0)
    stopifnot(cfg$gear$hbf_range[1] >= 1, diff(cfg$gear$hbf_range) > 0,
              identical(names(cfg$gear$hbf_by_strategy),
                        cfg$strategies$levels))
    st <- cfg$strategies
    stopifnot(st$drift_level %in% st$levels,
              st$misclassification >= 0, st$misclassification < 1)
    stopifnot(identical(names(cfg$catchability$strategy_effect),
                        cfg$strategies$levels),
              cfg$catchability$q0 > 0, cfg$catchability$vessel_sd >= 0,
              cfg$catchability$hbf$rate >= 0,
              length(cfg$catchability$quarter_effect) == 4,
              !is.null(names(cfg$catchability$region_effect)),
              cfg$catchability$residual_sd >= 0)
    sp <- cfg$spatial
    stopifnot(sp$preferential_sampling_strength >= 0,
              sp$fidelity >= 0, sp$fidelity < 1,
              all(sp$expansion_profile > 0), all(sp$expansion_profile <= 1))
    cp <- cfg$catch_process
    stopifnot(cp$distribution %in% c("tweedie", "delta_lognormal"),
              cp$power > 1, cp$power < 2, cp$dispersion > 0)
    for (prof in names(cfg$observation))
        for (per in cfg$observation[[prof]])
            stopifnot(length(per$period) == 2,
                      per$coord_resolution %in% c(1, 5),
                      per$hbf_missing >= 0, per$hbf_missing <= 1,
                      per$record_loss >= 0, per$record_loss < 1)
    spc <- cfg$species
    stopifnot(is.logical(spc$enabled))
    if (isTRUE(spc$enabled)) {
        stopifnot(!any(duplicated(spc$companions)),
                  !spc$target %in% spc$companions,
                  identical(sort(names(spc$params)), sort(spc$companions)),
                  spc$power > 1, spc$power < 2, spc$dispersion > 0,
                  spc$residual_sd >= 0, spc$cluster_sample >= 100)
        for (sp in spc$companions) {
            p <- spc$params[[sp]]
            stopifnot(p$ref > 0, p$lat_sd > 0,
                      identical(names(p$strategy_effect),
                                cfg$strategies$levels),
                      all(p$trend > 0))
        }
    }
    nms <- vapply(cfg$scenarios, `[[`, "", "name")
    stopifnot(!any(duplicated(nms)),
              all(vapply(cfg$scenarios, `[[`, "", "observation") %in%
                  names(cfg$observation)))
    invisible(cfg)
}

######@> Checks that depend on the biomass truth (regions present in the
######@> spatial domain, fleet periods inside the biomass years)...
check_fishery_vs_truth <- function(cfg, truth) {
    labs <- truth$regions$labels
    for (nm in names(cfg$fleets)) {
        r <- setdiff(cfg$fleets[[nm]]$regions, labs)
        if (length(r))
            stop("fleet '", nm, "' uses regions absent from the biomass ",
                 "domain: ", paste(r, collapse = ", "), " (domain regions: ",
                 paste(labs, collapse = ", "), ")")
    }
    ## a region effect is needed only for regions with cells (e.g. R01 has
    ## no cells in a southern stock area)
    present <- intersect(labs, unique(as.character(truth$cells$Region)))
    miss <- setdiff(present, names(cfg$catchability$region_effect))
    if (length(miss))
        stop("catchability$region_effect has no entry for region(s): ",
             paste(miss, collapse = ", "))
    for (sc in cfg$scenarios) {
        r <- setdiff(sc$regions, labs)
        if (length(r))
            stop("scenario '", sc$name, "' uses unknown region(s): ",
                 paste(r, collapse = ", "))
    }
    tp <- cfg$temporal
    if (tp$year_start < min(truth$years) || tp$year_end > max(truth$years))
        stop("the biomass truth covers ", min(truth$years), "-",
             max(truth$years), " but the fishery asks for ", tp$year_start,
             "-", tp$year_end)
    invisible(TRUE)
}
