########################################################################
## Description: pelagicOM - observation process (truth -> observed data)
##              and scenario data sets (Part II, modules 11-12)
##
## Author: Rodrigo Sant'Ana
## Created: 2026-11-22
## Version: 0.1.0
##
### Commentary:
##
## Ports of Experimento_02/Simulacao_Pesca/R/11_observation_process.R and
## 12_generate_scenarios.R (file writing moved to om_write_fishery()).
##
## Observation mechanisms (one parameter per period, 0 = off): strategy
## misclassification, position error (re-anchored in the domain), 5x5
## coordinate resolution, missing HBF / strategy / vessel, multiplicative
## error and rounding of hooks and catches, record loss.
##
### Code:
########################################################################

######@> Re-anchors coordinates in the nearest domain cell: nominal
######@> 1-degree cell first, nearest domain cell otherwise...
snap_to_domain <- function(lon, lat, truth) {
    lt <- truth$lattice
    col <- pmin(pmax(floor(lon) - lt$lon0_min + 1L, 1L), lt$n_col)
    row <- pmin(pmax(floor(lat) - lt$lat0_min + 1L, 1L), lt$n_row)
    truth$nearest_lookup[cbind(row, col)]
}

######@> Parameters of the profile that apply to each year...
period_params <- function(profile, years) {
    yrs <- sort(unique(years))
    fields <- setdiff(names(profile[[1]]), "period")
    tab <- as.data.frame(matrix(NA_real_, length(yrs), length(fields),
                                dimnames = list(NULL, fields)))
    for (per in profile) {
        r <- yrs >= per$period[1] & yrs <= per$period[2]
        for (f in fields) tab[[f]][r] <- per[[f]]
    }
    if (anyNA(tab)) stop("period_params(): years without observation profile")
    tab$Year <- yrs
    tab
}

#' Observation process
#'
#' Builds the OBSERVED data set from the true fishery data under one
#' observation profile of `cfg$observation`. Every profile starts from
#' the same seed (`seeds$observation`), so that profiles differ only by
#' their parameters.
#'
#' @param td True fishery data (`$data` of an `om_fishery` object).
#' @param profile Name of the observation profile (e.g. `"complete"`,
#'   `"temporal"`).
#' @param cfg Fishery configuration.
#' @param truth Population truth ([fishery_truth()]).
#' @return Data frame with the observable variables (Year, Quarter,
#'   Fleet, VesselID, TripID, SetID, Hooks, HooksBetweenFloats,
#'   FishingStrategy, Region, Longitude, Latitude, Cell_ID, Catch and
#'   Catch_<companion>), with attribute `"mechanisms"` (counts of each
#'   mechanism).
#' @export
apply_observation_process <- function(td, profile, cfg, truth) {
    prof <- cfg$observation[[profile]]
    if (is.null(prof)) stop("unknown observation profile: ", profile)
    with_om_rng({
    om_set_seed(cfg$reproducibility$seeds$observation)
    n <- nrow(td)
    pp <- period_params(prof, td$Year)
    getp <- function(name) pp[[name]][match(td$Year, pp$Year)]

    obs <- data.frame(
        Year = td$Year, Quarter = td$Quarter, Fleet = td$Fleet,
        VesselID = td$VesselID, TripID = td$TripID, SetID = td$SetID,
        Hooks = td$Hooks, HooksBetweenFloats = td$HooksBetweenFloats,
        FishingStrategy = td$TrueFishingStrategy,
        Region = td$Region, Longitude = td$Longitude,
        Latitude = td$Latitude, Cell_ID = td$Cell_ID,
        Catch = td$TrueCatch, stringsAsFactors = FALSE)
    sp_obs <- species_observed_columns(cfg)
    if (isTRUE(cfg$species$enabled))
        for (sp in cfg$species$companions)
            obs[[paste0("Catch_", sp)]] <- td[[paste0("TrueCatch_", sp)]]
    mech <- list(profile = profile, n_true = n,
                 strategy_misclassified = 0L, position_perturbed = 0L,
                 position_cell_changed = 0L, coord_5deg = 0L,
                 region_changed = 0L, hbf_missing = 0L,
                 strategy_missing = 0L, vessel_missing = 0L,
                 hooks_perturbed = 0L, catch_perturbed = 0L,
                 records_lost = 0L)

    ###@> Strategy misclassification (0 in the base)...
    mc <- cfg$strategies$misclassification
    if (mc > 0) {
        r <- stats::runif(n) < mc
        lv <- cfg$strategies$levels
        obs$FishingStrategy[r] <- sapply(obs$FishingStrategy[r], function(k)
            sample(setdiff(lv, k), 1))
        mech$strategy_misclassified <- sum(r)
    }

    ###@> Position: Gaussian error + re-anchoring in the domain...
    psd <- getp("position_sd")
    if (any(psd > 0)) {
        lon <- obs$Longitude + stats::rnorm(n, 0, psd)
        lat <- obs$Latitude  + stats::rnorm(n, 0, psd)
        r <- psd > 0
        idx <- snap_to_domain(lon[r], lat[r], truth)
        obs$Longitude[r] <- truth$cells$Longitude[idx]
        obs$Latitude[r]  <- truth$cells$Latitude[idx]
        obs$Cell_ID[r]   <- truth$cells$Cell_ID[idx]
        mech$position_perturbed <- sum(r)
        mech$position_cell_changed <- sum(obs$Cell_ID[r] != td$Cell_ID[r])
    }
    ###@> Resolution: centre of the 5-degree square; Cell_ID unknown...
    res <- getp("coord_resolution")
    r <- res == 5
    if (any(r)) {
        obs$Longitude[r] <- floor(obs$Longitude[r] / 5) * 5 + 2.5
        obs$Latitude[r]  <- floor(obs$Latitude[r] / 5) * 5 + 2.5
        obs$Cell_ID[r]   <- NA_character_
        mech$coord_5deg <- sum(r)
    }
    obs$Region <- region_from_latitude(obs$Latitude, truth)
    mech$region_changed <- sum(obs$Region != td$Region)

    ###@> Missing covariates...
    r <- stats::runif(n) < getp("hbf_missing")
    obs$HooksBetweenFloats[r] <- NA_integer_; mech$hbf_missing <- sum(r)
    r <- stats::runif(n) < getp("strategy_missing")
    obs$FishingStrategy[r] <- NA_character_; mech$strategy_missing <- sum(r)
    r <- stats::runif(n) < getp("vessel_missing")
    obs$VesselID[r] <- NA_character_; mech$vessel_missing <- sum(r)

    ###@> Effort and catch errors (multiplicative + rounding)...
    hcv <- getp("hooks_cv"); hr <- getp("hooks_round")
    e <- exp(stats::rnorm(n, 0, sqrt(log(1 + hcv^2))))
    obs$Hooks <- as.integer(pmax(1, round(obs$Hooks * e / hr) * hr))
    mech$hooks_perturbed <- sum(hcv > 0 | hr > 1)
    ccv <- getp("catch_cv"); cr <- getp("catch_round")
    perturb_catch <- function(x) {
        e <- exp(stats::rnorm(n, 0, sqrt(log(1 + ccv^2))))
        y <- x * e
        rr <- cr > 0
        y[rr] <- round(y[rr] / cr[rr]) * cr[rr]
        y[x == 0] <- 0
        y
    }
    obs$Catch <- perturb_catch(obs$Catch)
    for (v in sp_obs) obs[[v]] <- perturb_catch(obs[[v]])
    mech$catch_perturbed <- sum(ccv > 0 | cr > 0)

    ###@> Record loss...
    r <- stats::runif(n) < getp("record_loss")
    obs <- obs[!r, ]
    mech$records_lost <- sum(r)
    rownames(obs) <- NULL
    attr(obs, "mechanisms") <- mech
    obs
    })
}

#' Scenario data sets
#'
#' Applies each observation profile once and derives the scenario data
#' sets of `cfg$scenarios` (regional filter, removed variables,
#' observation profile), with a metadata table describing each one. With
#' the `"BET_ICCAT"` preset these are the eight data sets of Experimento 02
#' (identical to `Simulacao_Pesca/outputs/datasets/*.rds`).
#'
#' @param fishery An `om_fishery` object ([simulate_fishery()]).
#' @param verbose Print one line per scenario.
#' @return A list of class `om_scenarios` with `datasets` (named list of
#'   data frames), `metadata` (data frame) and `observed` (the full
#'   observed data set of each profile).
#' @export
generate_scenarios <- function(fishery, verbose = TRUE) {
    stopifnot(inherits(fishery, "om_fishery"))
    td <- fishery$data; cfg <- fishery$cfg; truth <- fishery$truth
    profiles <- unique(vapply(cfg$scenarios, `[[`, "", "observation"))
    observed <- lapply(stats::setNames(profiles, profiles), function(p)
        apply_observation_process(td, p, cfg, truth))
    all_regions <- truth$regions$labels

    true_processes <- paste(
        c(sprintf("preferential_sampling=%.2f",
                  cfg$spatial$preferential_sampling_strength),
          sprintf("fidelity=%.2f", cfg$spatial$fidelity),
          sprintf("expansion=%s", cfg$spatial$expansion_enabled),
          sprintf("hbf_trend=%s", cfg$gear$trend_enabled),
          sprintf("hbf_effect=%.2f", cfg$catchability$hbf$effect),
          sprintf("creep=%.3f", if (cfg$catchability$creep_enabled)
                                    cfg$catchability$creep else 0),
          sprintf("strategy_drift=%s", cfg$strategies$drift_enabled),
          sprintf("vessel_sd=%.2f", cfg$catchability$vessel_sd),
          sprintf("catch=%s(p=%.2f,phi=%.2f)",
                  cfg$catch_process$distribution, cfg$catch_process$power,
                  cfg$catch_process$dispersion)),
        collapse = "; ")

    datasets <- list(); meta <- list()
    for (sc in cfg$scenarios) {
        obs <- observed[[sc$observation]]
        keep <- !is.na(obs$Region) & obs$Region %in% sc$regions
        d <- obs[keep, setdiff(names(obs), sc$drop)]
        rownames(d) <- NULL
        datasets[[sc$name]] <- d
        unc <- if (sc$observation == "complete") "nenhuma (dados exatos)"
               else paste0("qualidade ", sc$observation, ": ",
                           paste(sapply(cfg$observation[[sc$observation]],
                                        function(p)
                               sprintf(paste0("%d-%d[pos_sd=%.2f,res=%d,",
                                              "hbfNA=%.2f,hooks_cv=%.2f,",
                                              "catch_cv=%.2f,stratNA=%.2f,",
                                              "vesselNA=%.2f,loss=%.2f]"),
                                       p$period[1], p$period[2], p$position_sd,
                                       p$coord_resolution, p$hbf_missing,
                                       p$hooks_cv, p$catch_cv,
                                       p$strategy_missing, p$vessel_missing,
                                       p$record_loss)), collapse = " | "))
        diff_txt <- c(
            if (!setequal(sc$regions, all_regions))
                paste0("filtro regional: ", paste(sc$regions, collapse = "+")),
            if (length(sc$drop)) paste0("variaveis removidas: ",
                                        paste(sc$drop, collapse = ", ")),
            if (sc$observation != "complete")
                paste0("perfil de observacao: ", sc$observation))
        meta[[sc$name]] <- data.frame(
            name = sc$name, objective = sc$objective %||% "",
            regions = paste(sc$regions, collapse = "+"),
            period = if (nrow(d)) sprintf("%d-%d", min(d$Year), max(d$Year))
                     else NA_character_,
            n_sets = nrow(d),
            n_sets_true = nrow(td),
            variables_available = paste(names(d), collapse = ", "),
            variables_removed = if (length(sc$drop))
                                    paste(sc$drop, collapse = ", ") else "",
            uncertainty = unc,
            observation_profile = sc$observation,
            true_processes = true_processes,
            differences_from_complete = if (length(diff_txt))
                paste(diff_txt, collapse = "; ") else "nenhuma (referencia)",
            file_rds = paste0(sc$name, ".rds"), stringsAsFactors = FALSE)
        om_msg(verbose, sprintf("  %-32s %7d sets  %s", sc$name, nrow(d),
                                paste(sc$regions, collapse = "+")))
    }
    meta <- do.call(rbind, meta); rownames(meta) <- NULL
    for (nm in names(datasets))
        check_observed_dataset(datasets[[nm]], cfg, nm, truth)
    structure(list(datasets = datasets, metadata = meta, observed = observed),
              class = c("om_scenarios", "list"))
}

#' @export
print.om_scenarios <- function(x, ...) {
    cat("<pelagicOM scenario data sets>", length(x$datasets), "data sets\n")
    m <- x$metadata
    for (i in seq_len(nrow(m)))
        cat(sprintf("  %-32s %8d sets  %-12s %s\n", m$name[i], m$n_sets[i],
                    m$regions[i], m$observation_profile[i]))
    invisible(x)
}
