########################################################################
## Description: pelagicOM - complete runs and output files with the
##              folder structure of Experimento 02
##
## Author: Rodrigo Sant'Ana
## Created: 2026-11-22
## Version: 0.1.0
##
### Commentary:
##
## om_write_biomass() reproduces the outputs of
## Simulacao_Biomassa/run_simulation.R and om_write_fishery() those of
## Simulacao_Pesca/run_simulation.R, with the same file names:
##
##   <dir>/Simulacao_Biomassa/outputs/data/      biomass_true_<label>.rds ...
##   <dir>/Simulacao_Biomassa/outputs/figures/   fig01_total_biomass_<label>.png ...
##   <dir>/Simulacao_Pesca/outputs/truth/        TRUE_FISHERY_DATA_<label>.rds ...
##   <dir>/Simulacao_Pesca/outputs/datasets/     01_global_complete.rds ...
##   <dir>/Simulacao_Pesca/outputs/diagnostics/  catch_summary_fleet_<label>.csv ...
##   <dir>/Simulacao_Pesca/outputs/figures/      fig01_effort_time_<label>.png ...
##
### Code:
########################################################################

#' Write the biomass outputs
#'
#' Saves the biomass truth with the files and names of Experimento 02
#' (`outputs/data/` and `outputs/figures/` inside `dir`): the full object
#' (`biomass_true_<label>.rds`), the long table (`.csv.gz`), population,
#' regional summary, centre of gravity, envelope parameters, cells and
#' configuration, plus the eight figures.
#'
#' @param sim An `om_biomass` object.
#' @param dir Folder playing the role of `Simulacao_Biomassa/`.
#' @param label Label of the files (default `cfg$general$label`).
#' @param rds,csv,figures What to write (defaults from `cfg$output`).
#' @param verbose Print the file names.
#' @return Invisible character vector of written files.
#' @export
om_write_biomass <- function(sim, dir, label = sim$cfg$general$label,
                             rds = sim$cfg$output$save_rds,
                             csv = sim$cfg$output$save_csv,
                             figures = sim$cfg$output$save_figures,
                             verbose = TRUE) {
    d_data <- file.path(dir, "outputs", "data")
    d_fig  <- file.path(dir, "outputs", "figures")
    dir.create(d_data, showWarnings = FALSE, recursive = TRUE)
    out_file <- function(name, ext) file.path(d_data,
                                              sprintf("%s_%s.%s", name, label,
                                                      ext))
    files <- character(0)
    if (isTRUE(rds)) {
        saveRDS(sim, out_file("biomass_true", "rds"))
        files <- c(files, out_file("biomass_true", "rds"))
    }
    if (isTRUE(csv)) {
        tb <- sim$table %||% build_long_table(sim)
        con <- gzfile(out_file("biomass_true", "csv.gz"), "w")
        utils::write.csv(tb, con, row.names = FALSE)
        close(con)
        files <- c(files, out_file("biomass_true", "csv.gz"))
    }
    wcsv <- function(x, name) {
        f <- out_file(name, "csv")
        utils::write.csv(x, f, row.names = FALSE)
        files <<- c(files, f)
    }
    wcsv(sim$pop, "population")
    wcsv(regional_summary(sim), "regional_summary")
    wcsv(centre_of_gravity(sim), "centre_of_gravity")
    wcsv(sim$envelope_params, "envelope_params")
    wcsv(sim$dom$cells, "cells")
    saveRDS(sim$cfg, out_file("config", "rds"))
    files <- c(files, out_file("config", "rds"))
    if (isTRUE(figures) && requireNamespace("ggplot2", quietly = TRUE))
        files <- c(files, make_biomass_figures(sim, d_fig, label,
                                               verbose = verbose))
    om_msg(verbose, "  biomass outputs written to ", normalizePath(dir))
    invisible(files)
}

#' Write the fishery outputs
#'
#' Saves the fishery truth, the scenario data sets, the diagnostic tables
#' and the figures with the files and names of Experimento 02
#' (`outputs/truth/`, `outputs/datasets/`, `outputs/diagnostics/`,
#' `outputs/figures/` inside `dir`).
#'
#' @param fishery An `om_fishery` object.
#' @param scenarios An `om_scenarios` object (or `NULL`).
#' @param dir Folder playing the role of `Simulacao_Pesca/`.
#' @param label Label of the files (default `cfg$general$label`).
#' @param csv Also write `.csv.gz` copies of the large tables.
#' @param diagnostics,figures Write diagnostic tables / figures.
#' @param verbose Print progress.
#' @return Invisible character vector of written files.
#' @export
om_write_fishery <- function(fishery, scenarios = NULL, dir,
                             label = fishery$cfg$general$label,
                             csv = fishery$cfg$output$save_csv,
                             diagnostics = TRUE,
                             figures = fishery$cfg$output$save_figures,
                             verbose = TRUE) {
    cfg <- fishery$cfg; td <- fishery$data; truth <- fishery$truth
    d_truth <- file.path(dir, "outputs", "truth")
    d_ds    <- file.path(dir, "outputs", "datasets")
    d_diag  <- file.path(dir, "outputs", "diagnostics")
    d_fig   <- file.path(dir, "outputs", "figures")
    for (d in c(d_truth, d_ds, d_diag))
        dir.create(d, showWarnings = FALSE, recursive = TRUE)
    files <- character(0)

    ###@> Fishery truth...
    ot <- function(name, ext) file.path(d_truth, sprintf("%s_%s.%s", name,
                                                          label, ext))
    saveRDS(list(cfg = cfg, data = td, fleets = fishery$fleets,
                 vessels = fishery$vessels, trips = fishery$trips,
                 vessel_effects = fishery$vessel_effects,
                 biomass_source = fishery$biomass_source,
                 observed_columns = fishery$observed_columns,
                 latent_columns = fishery$latent_columns),
            ot("TRUE_FISHERY_DATA", "rds"))
    files <- c(files, ot("TRUE_FISHERY_DATA", "rds"))
    if (isTRUE(csv)) {
        write_csv_gz(td, ot("TRUE_FISHERY_DATA", "csv.gz"))
        files <- c(files, ot("TRUE_FISHERY_DATA", "csv.gz"))
    }
    for (nm in c("fleets", "vessels", "trips", "vessel_effects")) {
        utils::write.csv(fishery[[nm]], ot(nm, "csv"), row.names = FALSE)
        files <- c(files, ot(nm, "csv"))
    }
    saveRDS(cfg, ot("config", "rds"))
    files <- c(files, ot("config", "rds"))
    om_msg(verbose, "  truth: ", ot("TRUE_FISHERY_DATA", "rds"))

    ###@> Scenario data sets...
    if (!is.null(scenarios)) {
        meta <- scenarios$metadata
        for (nm in names(scenarios$datasets)) {
            f <- file.path(d_ds, paste0(nm, ".rds"))
            saveRDS(scenarios$datasets[[nm]], f)
            files <- c(files, f)
            meta$file_rds[meta$name == nm] <- normalizePath(f)
            if (isTRUE(csv)) {
                write_csv_gz(scenarios$datasets[[nm]],
                             file.path(d_ds, paste0(nm, ".csv.gz")))
                files <- c(files, file.path(d_ds, paste0(nm, ".csv.gz")))
            }
        }
        f <- file.path(d_ds, "scenarios_metadata.csv")
        utils::write.csv(meta, f, row.names = FALSE)
        files <- c(files, f)
        om_msg(verbose, "  ", length(scenarios$datasets),
               " scenario data sets in ", d_ds)
    }

    ###@> Diagnostic tables...
    if (isTRUE(diagnostics)) {
        wd <- function(x, name) {
            f <- file.path(d_diag, sprintf("%s_%s.csv", name, label))
            utils::write.csv(x, f, row.names = FALSE)
            files <<- c(files, f)
        }
        wd(fleet_structure_table(td, fishery$vessels, fishery$trips),
           "fleet_structure")
        wd(active_vessels_by_year(fishery$vessel_years), "vessels_by_year")
        wd(regional_presence_table(td), "regional_presence")
        wd(effort_summary_table(td), "hooks_summary")
        wd(hbf_summary_table(td), "hbf_summary")
        wd(strategy_frequency_table(td), "strategy_frequency")
        wd(catch_summary_table(td, "Fleet"), "catch_summary_fleet")
        wd(catch_summary_table(td, "Region"), "catch_summary_region")
        wd(catch_summary_table(td, "TrueFishingStrategy"),
           "catch_summary_strategy")
        wd(catchability_summary_table(td, cfg$gear$hbf_bin_breaks),
           "catchability_summary")
        tg <- cpue_biomass_table(td, truth)
        tr <- cpue_biomass_table(td, truth, "Region")
        tf <- cpue_biomass_table(td, truth, "Fleet")
        ts <- cpue_biomass_table(td, truth, "TrueFishingStrategy")
        wd(rbind(tg, tr, tf, ts), "cpue_vs_biomass")
        wd(rbind(cpue_biomass_slopes(tg), cpue_biomass_slopes(tr),
                 cpue_biomass_slopes(tf), cpue_biomass_slopes(ts)),
           "cpue_biomass_slopes")
        if (!is.null(scenarios))
            wd(do.call(rbind, lapply(scenarios$observed, function(o)
                as.data.frame(attr(o, "mechanisms")))),
               "observation_mechanisms")
        if (isTRUE(cfg$species$enabled)) {
            wd(species_composition_table(td, cfg, "TrueFishingStrategy"),
               "species_composition_strategy")
            wd(species_composition_table(td, cfg, "Fleet"),
               "species_composition_fleet")
            rec <- strategy_recovery_diagnostic(td, cfg)
            wd(rec$confusion, "species_cluster_confusion")
            wd(rec$summary, "species_cluster_recovery")
        }
        om_msg(verbose, "  diagnostics in ", d_diag)
    }

    if (isTRUE(figures) && requireNamespace("ggplot2", quietly = TRUE) &&
        requireNamespace("patchwork", quietly = TRUE))
        files <- c(files, make_fishery_figures(fishery, scenarios, d_fig,
                                               label, verbose = verbose))
    invisible(files)
}

#' Run the complete operating model
#'
#' Simulates the biomass truth, the fishery and the scenario data sets in
#' one call and, if `dir` is given, writes every output with the folder
#' structure of Experimento 02 (`dir/Simulacao_Biomassa/outputs/...` and
#' `dir/Simulacao_Pesca/outputs/...`).
#'
#' @param preset Preset used for the default configurations.
#' @param biomass_cfg,fishery_cfg Configurations (default: the preset).
#' @param domain Optional spatial domain (see [simulate_biomass()]).
#' @param scenarios Generate the scenario data sets.
#' @param dir Output folder (`NULL`: nothing is written).
#' @param figures,csv Write figures / csv copies when `dir` is given.
#' @param verbose Print progress.
#' @return A list of class `om_run` with `biomass`, `fishery` and
#'   `scenarios`.
#' @examples
#' \dontrun{
#' run <- om_run("BET_ICCAT", dir = "Experimento_pelagicOM")
#' run$scenarios
#' }
#' @export
om_run <- function(preset = "BET_ICCAT",
                   biomass_cfg = om_biomass_config(preset),
                   fishery_cfg = om_fishery_config(preset),
                   domain = NULL, scenarios = TRUE, dir = NULL,
                   figures = TRUE, csv = TRUE, verbose = TRUE) {
    t0 <- Sys.time()
    om_msg(verbose, "#### Part I - biomass operating truth")
    sim <- simulate_biomass(biomass_cfg, domain, verbose = verbose)
    chk <- check_simulation(sim, verbose = verbose)
    om_msg(verbose, "#### Part II - fishery")
    fish <- simulate_fishery(sim, fishery_cfg, verbose = verbose)
    scen <- NULL
    if (isTRUE(scenarios)) {
        om_msg(verbose, "== 9. Scenarios ==================================")
        scen <- generate_scenarios(fish, verbose = verbose)
    }
    if (!is.null(dir)) {
        om_msg(verbose, "#### Writing outputs to ", dir)
        om_write_biomass(sim, file.path(dir, "Simulacao_Biomassa"),
                         csv = csv, figures = figures, verbose = verbose)
        om_write_fishery(fish, scen, file.path(dir, "Simulacao_Pesca"),
                         csv = csv, figures = figures, verbose = verbose)
    }
    om_msg(verbose, sprintf("#### Done in %.1f s", as.numeric(
        difftime(Sys.time(), t0, units = "secs"))))
    structure(list(biomass = sim, fishery = fish, scenarios = scen,
                   checks = chk), class = c("om_run", "list"))
}

#' @export
print.om_run <- function(x, ...) {
    print(x$biomass)
    print(x$fishery)
    if (!is.null(x$scenarios)) print(x$scenarios)
    invisible(x)
}
