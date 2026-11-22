########################################################################
## Description: pelagicOM - comparison of a run with reference outputs
##              (proof of reproduction of Experimento 02)
##
## Author: Rodrigo Sant'Ana
## Created: 2026-11-22
## Version: 0.1.0
##
### Code:
########################################################################

max_abs_diff <- function(a, b) {
    if (is.data.frame(a) && is.data.frame(b)) {
        if (!identical(dim(a), dim(b)) || !identical(names(a), names(b)))
            return(NA_real_)
        num <- names(a)[vapply(a, is.numeric, logical(1))]
        if (!length(num)) return(0)
        return(max(vapply(num, function(v)
            max(abs(a[[v]] - b[[v]]), 0, na.rm = TRUE), numeric(1))))
    }
    if (is.numeric(a) && is.numeric(b) && length(a) == length(b))
        return(max(abs(a - b), 0, na.rm = TRUE))
    NA_real_
}

#' Compare a run with reference outputs
#'
#' Compares the objects of a run (biomass matrix, population series, long
#' table, cells, fishery truth and scenario data sets) with the files of a
#' reference folder laid out as Experimento 02 (or as written by
#' [om_run()] with `dir`). `identical` means bit-for-bit equality
#' ([base::identical()]); `max_abs_diff` is the largest absolute
#' difference over numeric columns.
#'
#' @param run An `om_run` object, or a list with `biomass`, `fishery`
#'   and `scenarios` (any of them may be `NULL`).
#' @param ref_dir Reference folder containing `Simulacao_Biomassa/` and
#'   `Simulacao_Pesca/` (e.g. the `Experimento_02` folder).
#' @param label Label of the reference files.
#' @return A data frame with one row per compared component (`component`,
#'   `identical`, `max_abs_diff`, `n_rows`, `file`).
#' @examples
#' \dontrun{
#' run <- om_run("BET_ICCAT", verbose = FALSE)
#' om_compare_reference(run, "R-Work/Experimento_02")
#' }
#' @export
om_compare_reference <- function(run, ref_dir, label = "base") {
    rows <- list()
    add <- function(component, a, b, file) {
        rows[[length(rows) + 1L]] <<- data.frame(
            component = component, identical = identical(a, b),
            max_abs_diff = max_abs_diff(a, b),
            n_rows = if (is.null(dim(a))) length(a) else nrow(a),
            file = file, stringsAsFactors = FALSE)
    }
    if (!is.null(run$biomass)) {
        f <- file.path(ref_dir, "Simulacao_Biomassa", "outputs", "data",
                       sprintf("biomass_true_%s.rds", label))
        if (file.exists(f)) {
            ref <- readRDS(f)
            sim <- run$biomass
            add("biomass B(y,s)", sim$biomass, ref$biomass, f)
            add("spatial weights p(y,s)", sim$weights, ref$weights, f)
            add("population B_total(y)", sim$pop, ref$pop, f)
            add("domain cells", sim$dom$cells, ref$dom$cells, f)
            if (!is.null(sim$table) && !is.null(ref$table))
                add("long table Year x Cell", sim$table, ref$table, f)
        } else warning("reference file not found: ", f)
    }
    if (!is.null(run$fishery)) {
        f <- file.path(ref_dir, "Simulacao_Pesca", "outputs", "truth",
                       sprintf("TRUE_FISHERY_DATA_%s.rds", label))
        if (file.exists(f)) {
            ref <- readRDS(f)
            add("fishery truth (sets)", run$fishery$data, ref$data, f)
            add("vessels", run$fishery$vessels, ref$vessels, f)
            add("trips", run$fishery$trips, ref$trips, f)
            add("vessel effects", run$fishery$vessel_effects,
                ref$vessel_effects, f)
        } else warning("reference file not found: ", f)
    }
    if (!is.null(run$scenarios)) {
        for (nm in names(run$scenarios$datasets)) {
            f <- file.path(ref_dir, "Simulacao_Pesca", "outputs", "datasets",
                           paste0(nm, ".rds"))
            if (file.exists(f))
                add(paste("scenario", nm), run$scenarios$datasets[[nm]],
                    readRDS(f), f)
            else warning("reference file not found: ", f)
        }
    }
    out <- do.call(rbind, rows)
    rownames(out) <- NULL
    out
}
