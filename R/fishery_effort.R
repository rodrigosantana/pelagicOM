########################################################################
## Description: pelagicOM - where and how the sets are made: spatial
##              allocation, fishing strategy and gear (Part II, modules
##              06-08)
##
## Author: Rodrigo Sant'Ana
## Created: 2026-11-22
## Version: 0.1.0
##
### Commentary:
##
## Ports of Experimento_02/Simulacao_Pesca/R/06_simulate_spatial_effort.R,
## 07_simulate_gear.R and 08_simulate_strategy.R.
##
## Spatial choice of a set (fleet f, year y):
##   P(s) ~ D(y, s)^theta * g_f(s),  s in the footprint of f in y
## followed by fidelity (probability of repeating the cell of the previous
## set of the same vessel-year).
##
### Code:
########################################################################

########################################################################
######@> Spatial allocation...

allocate_sets_spatially <- function(sets, truth, cfg, verbose = TRUE) {
    om_set_seed(cfg$reproducibility$seeds$spatial)
    sp <- cfg$spatial
    theta <- sp$preferential_sampling_strength
    n <- nrow(sets)
    cell_idx <- integer(n); sel_p <- numeric(n)
    fp_n <- integer(n); fp_frac <- numeric(n)

    for (nm in names(cfg$fleets)) {
        f   <- cfg$fleets[[nm]]
        acc <- fleet_accessible_cells(f, truth)
        if (!length(acc))
            stop("fleet '", nm, "' has no accessible cell in the domain")
        g   <- fleet_core_preference(f, truth, cfg, acc)
        rows_f <- which(sets$Fleet == nm)
        for (y in sort(unique(sets$Year[rows_f]))) {
            rows <- rows_f[sets$Year[rows_f] == y]
            frac <- expansion_fraction(f, y, cfg)
            n_fp <- max(1L, ceiling(frac * length(acc)))
            idx  <- acc[seq_len(n_fp)]
            D    <- truth$density[idx, match(y, truth$years)]
            ###@> Weight = density^theta x baseline preference; theta = 0
            ###@> reduces the choice to g_f (or uniform)...
            w <- exp(theta * log(D + sp$density_floor)) * g[seq_len(n_fp)]
            p <- w / sum(w)
            draw <- sample.int(n_fp, length(rows), replace = TRUE, prob = p)
            cell_idx[rows] <- idx[draw]
            sel_p[rows]    <- p[draw]
            fp_n[rows]     <- n_fp
            fp_frac[rows]  <- frac
        }
    }
    sets$CellIndex      <- cell_idx
    sets$SelectionProb  <- sel_p
    sets$FootprintCells <- fp_n
    sets$FootprintFrac  <- fp_frac
    sets$SpatialChoice  <- "preference"

    ###@> Fidelity: the first set of each vessel-year is always fresh, so
    ###@> the forward fill never crosses vessels or years...
    if (sp$fidelity > 0) {
        o <- order(sets$VesselID, sets$Year, sets$SetOrder)
        sets <- sets[o, ]
        keep <- stats::runif(nrow(sets)) < sp$fidelity & sets$SetOrder > 1
        sets$CellIndex     <- fill_forward(ifelse(keep, NA, sets$CellIndex))
        sets$SelectionProb <- fill_forward(ifelse(keep, NA,
                                                  sets$SelectionProb))
        sets$SpatialChoice[keep] <- "fidelity"
        rownames(sets) <- NULL
    }

    cl <- truth$cells
    sets$Cell_ID     <- cl$Cell_ID[sets$CellIndex]
    sets$Longitude   <- cl$Longitude[sets$CellIndex]
    sets$Latitude    <- cl$Latitude[sets$CellIndex]
    sets$Region      <- as.character(cl$Region[sets$CellIndex])
    sets$TrueDensity <- true_density_at(truth, sets$CellIndex, sets$Year)
    sets$TrueBiomass <- true_biomass_at(truth, sets$CellIndex, sets$Year)
    if (verbose)
        message("  distinct cells fished: ",
                length(unique(sets$CellIndex)), " | sets by fidelity: ",
                sprintf("%.1f%%", 100 * mean(sets$SpatialChoice ==
                                             "fidelity")))
    sets
}

########################################################################
######@> Fishing strategy...

######@> Strategy probabilities of the fleet in each year (with the drift
######@> of the odds of strategies$drift_level, S1 in Experimento 02)...
strategy_probs <- function(fleet_cfg, year, cfg) {
    st <- cfg$strategies
    p <- matrix(fleet_cfg$strategy_comp, nrow = length(year),
                ncol = length(st$levels), byrow = TRUE,
                dimnames = list(NULL, st$levels))
    if (isTRUE(st$drift_enabled)) {
        m <- interp_anchors(year, st$drift_S1_odds)
        lv <- st$drift_level %||% st$levels[1]
        p[, lv] <- p[, lv] * m
    }
    p / rowSums(p)
}

simulate_strategy <- function(sets, cfg) {
    om_set_seed(cfg$reproducibility$seeds$strategy)
    lv <- cfg$strategies$levels
    out <- character(nrow(sets))
    u <- stats::runif(nrow(sets))
    for (nm in names(cfg$fleets)) {
        r <- which(sets$Fleet == nm)
        if (!length(r)) next
        p <- strategy_probs(cfg$fleets[[nm]], sets$Year[r], cfg)
        cum <- t(apply(p, 1, cumsum))
        k <- 1L + rowSums(u[r] > cum[, -ncol(cum), drop = FALSE])
        out[r] <- lv[k]
    }
    sets$TrueFishingStrategy <- out
    sets
}

########################################################################
######@> Gear...

hooks_median_fleet <- function(fleet_cfg, year, cfg) {
    anc <- fleet_cfg$hooks_median
    if (!isTRUE(cfg$effort$trend_enabled)) anc <- anc[1]
    interp_anchors(year, anc)
}

######@> Hooks (effort) per set. Seed 'gear' (simulate_hbf continues the
######@> same stream)...
simulate_hooks <- function(sets, cfg) {
    om_set_seed(cfg$reproducibility$seeds$gear)
    med <- numeric(nrow(sets))
    for (nm in names(cfg$fleets)) {
        r <- sets$Fleet == nm
        med[r] <- hooks_median_fleet(cfg$fleets[[nm]], sets$Year[r], cfg)
    }
    rg <- cfg$effort$hooks_range
    sets$Hooks <- as.integer(round(rlnorm_trunc(nrow(sets), med,
                                                cfg$effort$hooks_cv,
                                                rg[1], rg[2])))
    sets
}

hbf_median_strategy <- function(strategy, year, cfg) {
    out <- numeric(length(year))
    for (k in cfg$strategies$levels) {
        r <- strategy == k
        if (!any(r)) next
        anc <- cfg$gear$hbf_by_strategy[[k]]
        if (!isTRUE(cfg$gear$trend_enabled)) anc <- anc[1]
        out[r] <- interp_anchors(year[r], anc)
    }
    out
}

######@> Hooks between floats per set: strategy median x fleet multiplier
######@> x vessel habit x lognormal noise. Continues the 'gear' stream...
simulate_hbf <- function(sets, cfg) {
    gp <- cfg$gear
    med <- hbf_median_strategy(sets$TrueFishingStrategy, sets$Year, cfg)
    fmult <- sapply(cfg$fleets, `[[`, "hbf_mult")[sets$Fleet]
    vids <- sort(unique(sets$VesselID))
    habit <- stats::setNames(exp(stats::rnorm(length(vids), 0,
                                              gp$hbf_vessel_sd)), vids)
    sets$HBF_vessel_habit <- as.numeric(habit[sets$VesselID])
    x <- med * fmult * sets$HBF_vessel_habit *
         exp(stats::rnorm(nrow(sets), 0, gp$hbf_sd))
    sets$HooksBetweenFloats <- as.integer(pmin(pmax(round(x),
                                                    gp$hbf_range[1]),
                                               gp$hbf_range[2]))
    sets
}
