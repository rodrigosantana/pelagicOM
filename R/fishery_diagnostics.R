########################################################################
## Description: pelagicOM - structural checks and diagnostic tables of
##              the fishery truth (Part II, module 13)
##
## Author: Rodrigo Sant'Ana
## Created: 2026-11-22
## Version: 0.1.0
##
### Commentary:
##
## Port of Experimento_02/Simulacao_Pesca/R/13_diagnostics.R.
##
### Code:
########################################################################

#' Structural checks of the fishery truth and of observed data sets
#'
#' `check_fishery_truth()` stops if any structural property of the true
#' fishery data is violated (non-negative catches, ranges of hooks and
#' HBF, identifier hierarchy, cells and coordinates from the biomass
#' truth, regional access of each fleet, vessel active in the year of the
#' set, identity E[C] = q x Hooks x D). `check_observed_dataset()` checks
#' an observed data set.
#'
#' @param td True fishery data.
#' @param truth Population truth ([fishery_truth()]).
#' @param vessels Vessel table of the `om_fishery` object.
#' @param cfg Fishery configuration.
#' @param verbose Print a message when all checks pass.
#' @return Invisible `TRUE`.
#' @export
check_fishery_truth <- function(td, truth, vessels, cfg, verbose = TRUE) {
    tp <- cfg$temporal
    labs <- truth$regions$labels
    stopifnot(all(td$TrueCatch >= 0), all(is.finite(td$TrueCatch)),
              all(td$ExpectedCatch >= 0), all(td$Hooks > 0),
              all(td$HooksBetweenFloats > 0),
              all(td$Year >= tp$year_start), all(td$Year <= tp$year_end),
              all(td$Quarter %in% 1:4),
              all(td$Fleet %in% names(cfg$fleets)),
              all(td$Region %in% labs),
              all(td$TrueFishingStrategy %in% cfg$strategies$levels),
              all(td$Hooks >= cfg$effort$hooks_range[1]),
              all(td$Hooks <= cfg$effort$hooks_range[2]),
              all(td$HooksBetweenFloats >= cfg$gear$hbf_range[1]),
              all(td$HooksBetweenFloats <= cfg$gear$hbf_range[2]),
              !any(duplicated(td$SetID)),
              !anyNA(td[, c("SetID", "TripID", "VesselID", "Cell_ID",
                            "Longitude", "Latitude", "TrueCatchability")]))
    stopifnot(all(startsWith(td$SetID, td$TripID)),
              all(startsWith(td$TripID, td$VesselID)),
              all(startsWith(td$VesselID, paste0(td$Fleet, "_"))),
              !any(duplicated(paste(td$TripID, td$SetInTrip))))
    cl <- truth$cells
    m <- match(td$Cell_ID, cl$Cell_ID)
    stopifnot(!anyNA(m), all(td$Longitude == cl$Longitude[m]),
              all(td$Latitude == cl$Latitude[m]),
              all(td$Region == as.character(cl$Region[m])),
              all(abs(td$TrueBiomass -
                      truth$biomass[cbind(m, match(td$Year, truth$years))])
                  < 1e-9))
    for (nm in names(cfg$fleets))
        stopifnot(all(td$Region[td$Fleet == nm] %in%
                      cfg$fleets[[nm]]$regions))
    vi <- match(td$VesselID, vessels$VesselID)
    stopifnot(!anyNA(vi), all(td$Year >= vessels$Year_in[vi]),
              all(td$Year <= vessels$Year_out[vi]))
    for (v in species_truth_columns(cfg))
        stopifnot(all(is.finite(td[[v]])), all(td[[v]] >= 0))
    stopifnot(max(abs(td$ExpectedCatch - td$TrueCatchability * td$Hooks *
                      td$TrueDensity)) < 1e-9)
    om_msg(verbose, "  structural checks of the fishery truth: OK (",
           nrow(td), " sets)")
    invisible(TRUE)
}

#' @rdname check_fishery_truth
#' @param obs Observed data set.
#' @param name Name of the data set (messages).
#' @export
check_observed_dataset <- function(obs, cfg, name = "", truth = NULL) {
    labs <- if (is.null(truth)) unique(obs$Region) else truth$regions$labels
    ok <- all(obs$Catch >= 0) && all(obs$Hooks > 0) &&
        all(is.na(obs$HooksBetweenFloats) | obs$HooksBetweenFloats > 0) &&
        all(obs$Year >= cfg$temporal$year_start) &&
        all(obs$Year <= cfg$temporal$year_end) &&
        all(obs$Quarter %in% 1:4) &&
        all(obs$Fleet %in% names(cfg$fleets)) &&
        all(obs$Region %in% labs) &&
        !any(duplicated(obs$SetID)) &&
        all(is.na(obs$FishingStrategy) |
            obs$FishingStrategy %in% cfg$strategies$levels)
    if (!ok) stop("check_observed_dataset(): data set '", name,
                  "' failed the structural checks")
    invisible(TRUE)
}

decade_of <- function(y) paste0(floor(y / 10) * 10, "s")

#' Diagnostic tables of the fishery truth
#'
#' Tables written by Experimento 02 in `outputs/diagnostics/`:
#' fleet structure, regional presence, hooks and HBF quantiles by decade,
#' strategy frequency, catch summaries, mean catchability by factor
#' (the truth a standardisation tries to recover), nominal CPUE vs true
#' biomass (global or by factor; for regions the reference is the
#' regional biomass) and its log-log slopes (beta < 1 indicates
#' hyperstability), species composition and the recovery of the latent
#' strategy from the catch composition (k-means and PCA, a check that the
#' generator leaves the signature that a cluster / DPC approach looks
#' for).
#'
#' @param td True fishery data (`$data` of an `om_fishery` object).
#' @return A data frame (or a list for `strategy_recovery_diagnostic()`).
#' @name fishery_diagnostics
NULL

#' @rdname fishery_diagnostics
#' @param vessels,trips Vessel and trip tables of the `om_fishery` object.
#' @export
fleet_structure_table <- function(td, vessels, trips) {
    do.call(rbind, lapply(sort(unique(td$Fleet)), function(f) {
        data.frame(Fleet = f,
                   n_vessels_total = sum(vessels$Fleet == f),
                   n_vessels_mean_year = round(mean(table(
                       td$Year[td$Fleet == f],
                       td$VesselID[td$Fleet == f]) > 0) *
                       length(unique(td$VesselID[td$Fleet == f])), 1),
                   first_year = min(td$Year[td$Fleet == f]),
                   last_year = max(td$Year[td$Fleet == f]),
                   n_trips = sum(trips$Fleet == f),
                   n_sets = sum(td$Fleet == f),
                   sets_per_vessel_year = round(sum(td$Fleet == f) /
                       length(unique(paste(td$VesselID,
                                           td$Year)[td$Fleet == f])), 2),
                   sets_per_trip = round(sum(td$Fleet == f) /
                       sum(trips$Fleet == f), 2),
                   stringsAsFactors = FALSE)
    }))
}

#' @rdname fishery_diagnostics
#' @export
regional_presence_table <- function(td) {
    tab <- as.data.frame(table(Fleet = td$Fleet, Region = td$Region),
                         responseName = "n_sets")
    tab[tab$n_sets > 0, ]
}

quantile_summary <- function(x, name) {
    q <- stats::quantile(x, c(0.05, 0.25, 0.5, 0.75, 0.95), na.rm = TRUE)
    out <- data.frame(mean = mean(x, na.rm = TRUE),
                      sd = stats::sd(x, na.rm = TRUE),
                      q05 = q[1], q25 = q[2], q50 = q[3], q75 = q[4],
                      q95 = q[5], min = min(x, na.rm = TRUE),
                      max = max(x, na.rm = TRUE), n = sum(!is.na(x)))
    names(out) <- paste0(name, "_", names(out))
    out
}

#' @rdname fishery_diagnostics
#' @export
effort_summary_table <- function(td) {
    g <- split(seq_len(nrow(td)), list(td$Fleet, decade_of(td$Year)),
               drop = TRUE)
    do.call(rbind, lapply(names(g), function(k) {
        i <- g[[k]]
        cbind(data.frame(Fleet = td$Fleet[i[1]],
                         decade = decade_of(td$Year[i[1]]),
                         stringsAsFactors = FALSE),
              quantile_summary(td$Hooks[i], "hooks"))
    }))
}

#' @rdname fishery_diagnostics
#' @export
hbf_summary_table <- function(td) {
    g <- split(seq_len(nrow(td)),
               list(td$Fleet, td$TrueFishingStrategy, decade_of(td$Year)),
               drop = TRUE)
    do.call(rbind, lapply(names(g), function(k) {
        i <- g[[k]]
        cbind(data.frame(Fleet = td$Fleet[i[1]],
                         Strategy = td$TrueFishingStrategy[i[1]],
                         decade = decade_of(td$Year[i[1]]),
                         stringsAsFactors = FALSE),
              quantile_summary(td$HooksBetweenFloats[i], "hbf"))
    }))
}

#' @rdname fishery_diagnostics
#' @export
strategy_frequency_table <- function(td) {
    tab <- as.data.frame(prop.table(table(Fleet = td$Fleet,
                                          decade = decade_of(td$Year),
                                          Strategy = td$TrueFishingStrategy),
                                    c(1, 2)), responseName = "share")
    tab <- tab[!is.nan(tab$share), ]
    cnt <- as.data.frame(table(Fleet = td$Fleet, decade = decade_of(td$Year),
                               Strategy = td$TrueFishingStrategy))
    tab$n_sets <- cnt$Freq[match(paste(tab$Fleet, tab$decade, tab$Strategy),
                                 paste(cnt$Fleet, cnt$decade, cnt$Strategy))]
    tab[tab$n_sets > 0, ]
}

#' @rdname fishery_diagnostics
#' @param by Grouping column.
#' @export
catch_summary_table <- function(td, by = "Fleet") {
    g <- split(seq_len(nrow(td)), td[[by]])
    do.call(rbind, lapply(names(g), function(k) {
        i <- g[[k]]
        x <- td$TrueCatch[i]
        cbind(stats::setNames(data.frame(k, stringsAsFactors = FALSE), by),
              data.frame(n_sets = length(i), mean = mean(x),
                         median = stats::median(x), variance = stats::var(x),
                         prop_zero = mean(x == 0),
                         mean_expected = mean(td$ExpectedCatch[i]),
                         mean_zero_prob = mean(td$ZeroProb[i])),
              quantile_summary(x, "catch")[, c("catch_q05", "catch_q25",
                                               "catch_q75", "catch_q95",
                                               "catch_max")])
    }))
}

#' @rdname fishery_diagnostics
#' @param hbf_breaks Breaks of the HBF classes.
#' @export
catchability_summary_table <- function(td,
                                       hbf_breaks = c(3, 6, 9, 12, 15, 18, 26)) {
    f <- function(by, lab) {
        g <- split(seq_len(nrow(td)), td[[by]])
        do.call(rbind, lapply(names(g), function(k) {
            i <- g[[k]]
            data.frame(factor = lab, level = k, n_sets = length(i),
                       mean_log_q = mean(td$log_q[i]),
                       mean_q = mean(td$TrueCatchability[i]),
                       mean_q_fleet = mean(td$q_fleet[i]),
                       mean_q_vessel = mean(td$q_vessel[i]),
                       mean_q_strategy = mean(td$q_strategy[i]),
                       mean_q_hbf = mean(td$q_hbf[i]),
                       mean_q_creep = mean(td$q_creep[i]),
                       mean_q_spatial = mean(td$q_spatial[i]),
                       stringsAsFactors = FALSE)
        }))
    }
    td$HBF_bin <- cut(td$HooksBetweenFloats, hbf_breaks)
    rbind(f("Year", "Year"), f("Fleet", "Fleet"),
          f("TrueFishingStrategy", "FishingStrategy"), f("Region", "Region"),
          f("HBF_bin", "HooksBetweenFloats"), f("Quarter", "Quarter"))
}

#' @rdname fishery_diagnostics
#' @param truth Population truth ([fishery_truth()]).
#' @export
cpue_biomass_table <- function(td, truth, by = NULL) {
    pop <- truth$pop
    key <- if (is.null(by)) rep("ALL", nrow(td)) else td[[by]]
    g <- split(seq_len(nrow(td)), list(td$Year, key), drop = TRUE)
    out <- do.call(rbind, lapply(names(g), function(k) {
        i <- g[[k]]
        y <- td$Year[i[1]]; lv <- key[i[1]]
        B_ref <- if (identical(by, "Region")) {
            sum(truth$biomass[truth$cells$Region == lv, match(y, truth$years)])
        } else pop$B_total[match(y, pop$Year)]
        data.frame(Year = y, level = lv, n_sets = length(i),
                   Hooks = sum(td$Hooks[i]), Catch = sum(td$TrueCatch[i]),
                   RawCPUE = 1000 * sum(td$TrueCatch[i]) / sum(td$Hooks[i]),
                   ExpectedCPUE = 1000 * sum(td$ExpectedCatch[i]) /
                                  sum(td$Hooks[i]),
                   MeanTrueDensity = stats::weighted.mean(td$TrueDensity[i],
                                                          td$Hooks[i]),
                   MeanCatchability = stats::weighted.mean(
                       td$TrueCatchability[i], td$Hooks[i]),
                   PropZero = mean(td$TrueCatch[i] == 0),
                   TrueBiomassRef = B_ref,
                   B_total = pop$B_total[match(y, pop$Year)],
                   stringsAsFactors = FALSE)
    }))
    out$factor <- if (is.null(by)) "Global" else by
    out[order(out$level, out$Year), ]
}

#' @rdname fishery_diagnostics
#' @param tab Output of `cpue_biomass_table()`.
#' @export
cpue_biomass_slopes <- function(tab) {
    do.call(rbind, lapply(split(tab, tab$level), function(d) {
        ok <- d$RawCPUE > 0 & d$TrueBiomassRef > 0
        fit <- stats::lm(log(RawCPUE) ~ log(TrueBiomassRef), data = d[ok, ])
        fit_e <- stats::lm(log(ExpectedCPUE) ~ log(TrueBiomassRef),
                           data = d[ok, ])
        data.frame(factor = d$factor[1], level = d$level[1],
                   n_years = sum(ok),
                   beta_raw = unname(stats::coef(fit)[2]),
                   beta_expected = unname(stats::coef(fit_e)[2]),
                   r_log = stats::cor(log(d$RawCPUE[ok]),
                                      log(d$TrueBiomassRef[ok])),
                   stringsAsFactors = FALSE)
    }))
}

species_catch_matrix <- function(td, cfg) {
    spc <- cfg$species
    m <- cbind(td$TrueCatch,
               as.matrix(td[, paste0("TrueCatch_", spc$companions),
                            drop = FALSE]))
    colnames(m) <- c(spc$target, spc$companions)
    m
}

#' @rdname fishery_diagnostics
#' @param cfg Fishery configuration.
#' @export
species_composition_table <- function(td, cfg, by = "TrueFishingStrategy") {
    m <- species_catch_matrix(td, cfg)
    g <- split(seq_len(nrow(td)), td[[by]])
    do.call(rbind, lapply(names(g), function(k) {
        i <- g[[k]]
        tot <- colSums(m[i, , drop = FALSE])
        out <- data.frame(level = k, n_sets = length(i),
                          species = colnames(m),
                          mean_catch = colMeans(m[i, , drop = FALSE]),
                          share_of_total = tot / sum(tot),
                          prop_positive = colMeans(m[i, , drop = FALSE] > 0),
                          stringsAsFactors = FALSE)
        names(out)[1] <- by
        out
    }))
}

#' @rdname fishery_diagnostics
#' @export
strategy_recovery_diagnostic <- function(td, cfg) {
    spc <- cfg$species
    with_om_rng({
        om_set_seed(cfg$reproducibility$seeds$species + 1L)
        m <- species_catch_matrix(td, cfg)
        ok <- which(rowSums(m) > 0)
        i <- if (length(ok) > spc$cluster_sample)
                 sort(sample(ok, spc$cluster_sample)) else ok
        comp <- (m[i, ] / rowSums(m[i, ]))^(1 / 4)
        truth_k <- td$TrueFishingStrategy[i]
        k <- length(cfg$strategies$levels)
        km <- stats::kmeans(comp, centers = k, nstart = 10, iter.max = 50)
    })
    conf <- table(cluster = km$cluster, strategy = truth_k)
    perms <- function(v) if (length(v) <= 1) list(v) else
        do.call(c, lapply(seq_along(v), function(j)
            lapply(perms(v[-j]), function(p) c(v[j], p))))
    acc <- max(sapply(perms(seq_len(k)), function(p)
        sum(conf[cbind(seq_len(k), p)]) / sum(conf)))
    pc <- stats::prcomp(comp, scale. = TRUE)
    r2 <- sapply(1:2, function(j)
        summary(stats::lm(pc$x[, j] ~ factor(truth_k)))$r.squared)
    list(confusion = as.data.frame(conf),
         summary = data.frame(n_sets = length(i), k = k,
                              cluster_accuracy_best_match = acc,
                              pc1_var_explained =
                                  summary(pc)$importance[2, 1],
                              pc2_var_explained =
                                  summary(pc)$importance[2, 2],
                              r2_pc1_vs_strategy = r2[1],
                              r2_pc2_vs_strategy = r2[2]))
}
