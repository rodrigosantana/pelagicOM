########################################################################
## Description: pelagicOM - fishery generator pipeline (Part II
##              orchestrator)
##
## Author: Rodrigo Sant'Ana
## Created: 2026-11-22
## Version: 0.1.0
##
### Commentary:
##
## Port of run_fishery_pipeline() in
## Experimento_02/Simulacao_Pesca/run_simulation.R. Causal order:
##   true biomass -> fleets -> vessels -> trips -> sets -> location ->
##   strategy -> gear -> catchability -> expected catch -> true catch ->
##   companion species
##
### Code:
########################################################################

#' Simulate the longline fishery on top of the biomass truth
#'
#' Generates set-by-set pelagic longline operations (fleets, vessels with
#' careers and turnover, trips, sets, location by preferential sampling
#' and fidelity, latent fishing strategy, hooks and hooks between floats,
#' catchability components, Tweedie catches of the target species and
#' catches of companion species) with the COMPLETE truth of the fishing
#' process. Observed data sets are derived afterwards with
#' [generate_scenarios()].
#'
#' With `om_fishery_config("BET_ICCAT")` on the BET biomass truth, `$data`
#' is identical, bit for bit, to `TRUE_FISHERY_DATA_base.rds` of
#' Experimento 02. The caller's random number stream is left untouched.
#'
#' @param biomass An `om_biomass` object ([simulate_biomass()]), an
#'   `om_truth` object ([fishery_truth()]), a list with `dom`, `pop` and
#'   `biomass`, or the path to an `.rds` file with such a list (e.g. the
#'   Experimento 02 file `biomass_true_base.rds`).
#' @param cfg Fishery configuration ([om_fishery_config()]).
#' @param verbose Print progress messages.
#' @return An object of class `om_fishery`, a list with `cfg`, `data`
#'   (true fishery data, one row per set; observable columns first, then
#'   latent ones), `fleets`, `vessels`, `vessel_years`, `trips`,
#'   `vessel_effects`, `truth`, `biomass_source`, `observed_columns`,
#'   `latent_columns`.
#' @seealso [generate_scenarios()], [check_fishery_truth()],
#'   [make_fishery_figures()], [om_write_fishery()].
#' @examples
#' \donttest{
#' sim <- simulate_biomass(verbose = FALSE)
#' fcfg <- om_fishery_config("BET_ICCAT",
#'     fleets = list(A = list(n_vessels = 5), B = list(n_vessels = 5),
#'                   C = list(n_vessels = 5), D = list(n_vessels = 5),
#'                   E = list(n_vessels = 5)))
#' fish <- simulate_fishery(sim, fcfg, verbose = FALSE)
#' fish
#' }
#' @export
simulate_fishery <- function(biomass, cfg = om_fishery_config(),
                             verbose = TRUE) {
    cfg <- validate_fishery_config(cfg)
    om_msg(verbose, "== 1. Population truth (Part I) ==================")
    truth <- fishery_truth(biomass, verbose = verbose)
    check_fishery_vs_truth(cfg, truth)
    res <- with_om_rng(run_fishery_pipeline(cfg, truth, verbose))
    td <- res$td
    om_msg(verbose, "== 7. Structural checks ==========================")
    check_fishery_truth(td, truth, res$vessels, cfg, verbose = verbose)
    structure(list(cfg = cfg, data = td, fleets = res$fleets,
                   vessels = res$vessels, vessel_years = res$vessel_years,
                   trips = res$trips, vessel_effects = res$vessel_effects,
                   truth = truth, biomass_source = truth$source,
                   observed_columns = attr(td, "observed_columns"),
                   latent_columns = attr(td, "latent_columns")),
              class = c("om_fishery", "list"))
}

######@> Chains the modules in causal order; each module seeds its own
######@> stream. Returns the complete fishery truth (td) and the
######@> auxiliary tables...
run_fishery_pipeline <- function(cfg, truth, verbose = TRUE) {
    msg <- function(...) om_msg(verbose, ...)
    msg("== 2. Fleets and vessels =========================")
    fleets <- build_fleet_table(cfg)
    vs <- simulate_vessels(cfg)
    msg("  ", nrow(vs$vessels), " vessels (", nrow(vs$vessel_years),
        " vessel-years)")
    msg("== 3. Trips and sets =============================")
    trips <- simulate_trips(vs$vessel_years, cfg)
    sets  <- simulate_sets(trips, cfg)
    msg("  ", nrow(trips), " trips | ", nrow(sets), " sets | ",
        "vessel-years with n_sets raised to n_trips: ",
        attr(sets, "n_adjusted"))
    msg("== 4. Location of the sets =======================")
    sets <- allocate_sets_spatially(sets, truth, cfg, verbose = verbose)
    msg("== 5. Strategy and gear ==========================")
    sets <- simulate_strategy(sets, cfg)
    sets <- simulate_hooks(sets, cfg)
    sets <- simulate_hbf(sets, cfg)
    msg("== 6. Catchability and catch =====================")
    sets <- simulate_catchability(sets, truth, cfg)
    veff <- attr(sets, "vessel_effects")
    sets <- simulate_catch(sets, cfg)
    sets <- simulate_companion_catch(sets, cfg)
    msg(sprintf(paste0("  mean catch %.3f t | median %.3f | ",
                       "zeros %.1f%% | total %.0f t"),
                mean(sets$TrueCatch), stats::median(sets$TrueCatch),
                100 * mean(sets$TrueCatch == 0), sum(sets$TrueCatch)))
    ###@> Final order and columns: observables first, latent next...
    o <- order(sets$Fleet, sets$VesselID, sets$Year, sets$TripIndex,
               sets$SetInTrip)
    sets <- sets[o, ]; rownames(sets) <- NULL
    obs_cols <- c("Year", "Quarter", "Fleet", "VesselID", "TripID", "SetID",
                  "Hooks", "HooksBetweenFloats", "Region", "Longitude",
                  "Latitude", "Cell_ID")
    lat_cols <- c("TrueFishingStrategy", "TrueDensity", "TrueBiomass",
                  "TrueCatchability", "log_q", "q_fleet", "q_vessel",
                  "q_strategy", "q_hbf", "q_creep", "q_quarter", "q_region",
                  "q_spatial", "q_resid", "ExpectedCatch", "ZeroProb",
                  "TrueCatch", "SelectionProb", "SpatialChoice",
                  "FootprintCells", "FootprintFrac", "HBF_vessel_habit",
                  "CellIndex", "TripIndex", "SetInTrip", "SetOrder",
                  species_truth_columns(cfg))
    td <- sets[, c(obs_cols, lat_cols)]
    attr(td, "observed_columns") <- obs_cols
    attr(td, "latent_columns") <- lat_cols
    list(td = td, fleets = fleets, vessels = vs$vessels,
         vessel_years = vs$vessel_years, trips = trips,
         vessel_effects = veff)
}

#' @export
print.om_fishery <- function(x, ...) {
    td <- x$data
    cat("<pelagicOM fishery truth> label '", x$cfg$general$label, "'\n",
        sep = "")
    cat(sprintf("  %s sets | %s trips | %d vessels | %d fleets | %d-%d\n",
                format(nrow(td), big.mark = ","),
                format(nrow(x$trips), big.mark = ","), nrow(x$vessels),
                nrow(x$fleets), min(td$Year), max(td$Year)))
    cat(sprintf("  target catch: total %s t | mean %.3f t/set | zeros %.1f%%\n",
                format(round(sum(td$TrueCatch)), big.mark = ","),
                mean(td$TrueCatch), 100 * mean(td$TrueCatch == 0)))
    tab <- table(td$Fleet, td$Region)
    cat("  sets by fleet x region:\n")
    print(tab)
    invisible(x)
}
