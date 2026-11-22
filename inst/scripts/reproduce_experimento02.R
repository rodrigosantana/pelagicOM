########################################################################
## Description: pelagicOM - proof that the package reproduces the BET
##              operating model of Experimento 02
##
## Author: Rodrigo Sant'Ana
## Created: 2026-11-22
## Version: 0.1.0
##
### Commentary:
##
## Runs the "BET_ICCAT" preset (biomass -> fishery -> scenarios) and
## compares, bit for bit, every product with the reference files of
## Experimento 02:
##   Simulacao_Biomassa/outputs/data/biomass_true_base.rds
##   Simulacao_Pesca/outputs/truth/TRUE_FISHERY_DATA_base.rds
##   Simulacao_Pesca/outputs/datasets/0X_*.rds  (8 scenarios)
## It also runs the fishery directly on the stored biomass file (Part II
## alone). Nothing is written in the experiment folder.
##
## Usage:
##   Rscript reproduce_experimento02.R <Experimento_02 folder> [report.csv]
##   (or set PELAGICOM_EXP02=<Experimento_02 folder>)
##   (PELAGICOM_DEV=<package source> uses pkgload::load_all instead of
##    library(pelagicOM))
##
### Code:
########################################################################

args <- setdiff(commandArgs(trailingOnly = TRUE), "--args")
exp_dir <- if (length(args) >= 1) args[1] else
    Sys.getenv("PELAGICOM_EXP02", "Experimento_02")
report  <- if (length(args) >= 2) args[2] else NULL
stopifnot(dir.exists(exp_dir))

dev <- Sys.getenv("PELAGICOM_DEV")
if (nzchar(dev)) pkgload::load_all(dev, quiet = TRUE) else
    suppressPackageStartupMessages(library(pelagicOM))

t0 <- Sys.time()
run <- om_run("BET_ICCAT", verbose = FALSE)
t_run <- as.numeric(difftime(Sys.time(), t0, units = "secs"))

cmp <- om_compare_reference(run, exp_dir, label = "base")

###@> Part II alone, on the biomass file saved by Experimento 02...
f_bio <- file.path(exp_dir, "Simulacao_Biomassa", "outputs", "data",
                   "biomass_true_base.rds")
fish2 <- simulate_fishery(f_bio, om_fishery_config("BET_ICCAT"),
                          verbose = FALSE)
ref_td <- readRDS(file.path(exp_dir, "Simulacao_Pesca", "outputs", "truth",
                            "TRUE_FISHERY_DATA_base.rds"))$data
cmp <- rbind(cmp, data.frame(
    component = "fishery truth from the stored biomass file",
    identical = identical(fish2$data, ref_td),
    max_abs_diff = pelagicOM:::max_abs_diff(fish2$data, ref_td),
    n_rows = nrow(fish2$data), file = f_bio, stringsAsFactors = FALSE))

###@> The caller's random stream must be untouched...
set.seed(1); a <- runif(1)
set.seed(1); invisible(simulate_biomass(verbose = FALSE, long_table = FALSE))
b <- runif(1)
cmp <- rbind(cmp, data.frame(component = "caller RNG stream preserved",
                             identical = identical(a, b), max_abs_diff = 0,
                             n_rows = 1, file = "", stringsAsFactors = FALSE))

cmp$file <- basename(cmp$file)
print(cmp, row.names = FALSE)
cat(sprintf("\nrun time (biomass + fishery + 8 scenarios): %.1f s\n", t_run))
if (!is.null(report)) utils::write.csv(cmp, report, row.names = FALSE)
if (!all(cmp$identical)) {
    stop("pelagicOM does NOT reproduce Experimento 02 for: ",
         paste(cmp$component[!cmp$identical], collapse = "; "))
}
cat("pelagicOM reproduces Experimento 02 exactly (", nrow(cmp),
    " comparisons).\n", sep = "")
