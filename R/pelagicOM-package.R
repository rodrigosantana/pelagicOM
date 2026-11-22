########################################################################
## Description: pelagicOM - package documentation
##
## Author: Rodrigo Sant'Ana
## Created: 2026-11-22
## Version: 0.1.0
########################################################################

#' pelagicOM: spatio-temporal operating model for pelagic stocks and
#' longline fisheries
#'
#' `pelagicOM` packages the simulation components of Experimento 02
#' (workshop tRFMO CPUE, 2026) so that they can be rerun, tuned and
#' reused for other species and distributions.
#'
#' @section Workflow:
#' \preformatted{
#' bcfg <- om_biomass_config("BET_ICCAT")     # Part I parameters
#' fcfg <- om_fishery_config("BET_ICCAT")     # Part II parameters
#' sim  <- simulate_biomass(bcfg)             # B(y, s), cells x years
#' fish <- simulate_fishery(sim, fcfg)        # set-by-set fishery truth
#' scen <- generate_scenarios(fish)           # observed data sets
#' om_write_biomass(sim, "out/Simulacao_Biomassa")
#' om_write_fishery(fish, scen, "out/Simulacao_Pesca")
#' }
#' or simply `om_run("BET_ICCAT", dir = "out")`.
#'
#' @section Tuning:
#' Every parameter lives in the two configuration lists; change them with
#' [om_config_update()] (or the `...` of [om_biomass_config()] /
#' [om_fishery_config()]). The spatial domain can be any ICCAT stock area
#' ([om_domain_iccat()], [iccat_stocks()]), an ICCAT-like GeoPackage
#' ([om_domain_from_gpkg()]) or a synthetic grid ([om_domain_grid()]);
#' regions are free latitudinal bands ([classify_regions()]).
#'
#' @section Reproducibility:
#' Each stochastic component has its own seed; simulations never change
#' the caller's random stream. [om_compare_reference()] checks a run
#' against the reference files of Experimento 02.
#'
#' @keywords internal
"_PACKAGE"
