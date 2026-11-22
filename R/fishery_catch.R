########################################################################
## Description: pelagicOM - catchability, catch of the target species and
##              catches of the companion species (Part II, modules 09-10)
##
## Author: Rodrigo Sant'Ana
## Created: 2026-11-22
## Version: 0.1.0
##
### Commentary:
##
## Ports of Experimento_02/Simulacao_Pesca/R/09_simulate_catchability.R,
## 10_simulate_catch.R and 10_simulate_companion_species.R.
##
##   log q = log q0 + fleet + vessel + strategy + f(HBF) + creep
##           + quarter + region + spatial field + residual
##   E[C]  = q * Hooks * D(y, s)
##   C     ~ Tweedie(mu, p, phi)  (compound Poisson-Gamma)
##           or delta-lognormal
##
## Companion species j:
##   log mu_j = log(ref_j / 1000) + log(Hooks) + beta_j[strategy]
##              + h_j g(HBF) + E_j(lat) + log T_j(y) + eps
##
### Code:
########################################################################

########################################################################
######@> Catchability...

#' Effect of hooks between floats on log catchability
#'
#' Saturating effect \eqn{f(h) = a (1 - e^{-b (h - 4)})}, centred at
#' the reference HBF: \eqn{f(h) - f(h_{ref})}.
#'
#' @param hbf Hooks between floats.
#' @param hp List with `effect` (a), `rate` (b) and `ref`.
#' @return Effect on log q.
#' @examples
#' hbf_effect_fun(4:26, om_fishery_config()$catchability$hbf)
#' @export
hbf_effect_fun <- function(hbf, hp) {
    g <- function(h) hp$effect * (1 - exp(-hp$rate * (h - 4)))
    g(hbf) - g(hp$ref)
}

######@> Components of log q (seed 'catchability': vessel effects ->
######@> spatial field -> residual, in this order)...
simulate_catchability <- function(sets, truth, cfg) {
    om_set_seed(cfg$reproducibility$seeds$catchability)
    cq <- cfg$catchability
    y0 <- cfg$temporal$year_start

    vids <- sort(unique(sets$VesselID))
    b_v  <- stats::setNames(stats::rnorm(length(vids), 0, cq$vessel_sd),
                            vids)

    if (isTRUE(cq$spatial$enabled) && cq$spatial$sd > 0) {
        Zm <- gaussian_random_field(truth$lattice, cq$spatial$range,
                                    cq$spatial$sd)
        Zc <- Zm[cbind(truth$cells$Row, truth$cells$Col)]
    } else Zc <- rep(0, nrow(truth$cells))

    fq <- sapply(cfg$fleets, `[[`, "q_effect")
    sets$q_fleet    <- as.numeric(fq[sets$Fleet])
    sets$q_vessel   <- as.numeric(b_v[sets$VesselID])
    sets$q_strategy <- as.numeric(cq$strategy_effect[sets$TrueFishingStrategy])
    sets$q_hbf      <- as.numeric(cq$hbf$by_fleet[sets$Fleet]) *
                       hbf_effect_fun(sets$HooksBetweenFloats, cq$hbf)
    sets$q_creep    <- if (isTRUE(cq$creep_enabled))
                           cq$creep * (sets$Year - y0) else 0
    sets$q_quarter  <- cq$quarter_effect[sets$Quarter]
    sets$q_region   <- as.numeric(cq$region_effect[sets$Region])
    sets$q_spatial  <- Zc[sets$CellIndex]
    sets$q_resid    <- stats::rnorm(nrow(sets), 0, cq$residual_sd)
    sets$log_q <- log(cq$q0) + sets$q_fleet + sets$q_vessel +
                  sets$q_strategy + sets$q_hbf + sets$q_creep +
                  sets$q_quarter + sets$q_region + sets$q_spatial +
                  sets$q_resid
    sets$TrueCatchability <- exp(sets$log_q)
    attr(sets, "vessel_effects") <- data.frame(VesselID = vids,
                                               q_vessel = as.numeric(b_v),
                                               stringsAsFactors = FALSE)
    sets
}

########################################################################
######@> Catch of the target species...

######@> Compound Poisson-Gamma parameters of the Tweedie...
tweedie_cpg_params <- function(mu, p, phi) {
    list(lambda = mu^(2 - p) / (phi * (2 - p)),
         alpha  = (2 - p) / (p - 1),
         scale  = phi * (p - 1) * mu^(p - 1))
}

#' Tweedie random draws (compound Poisson-Gamma)
#'
#' Draws from a Tweedie distribution with mean `mu`, power `p`
#' (1 < p < 2) and dispersion `phi` (Var = phi mu^p) through its compound
#' Poisson-Gamma representation, without external dependencies.
#'
#' @param mu Vector of means.
#' @param p Power parameter.
#' @param phi Dispersion.
#' @return Numeric vector (with exact zeros).
#' @examples
#' set.seed(1)
#' x <- rtweedie_cpg(rep(0.5, 1e4), 1.4, 1)
#' c(mean = mean(x), prop_zero = mean(x == 0))
#' @export
rtweedie_cpg <- function(mu, p, phi) {
    pr <- tweedie_cpg_params(mu, p, phi)
    N  <- stats::rpois(length(mu), pr$lambda)
    y  <- numeric(length(mu))
    pos <- N > 0
    if (any(pos))
        y[pos] <- stats::rgamma(sum(pos), shape = N[pos] * pr$alpha,
                                scale = pr$scale[pos])
    y
}

######@> Analytical probability of a zero catch...
zero_prob <- function(mu, cfg) {
    cp <- cfg$catch_process
    if (cp$distribution == "tweedie")
        exp(-tweedie_cpg_params(mu, cp$power, cp$dispersion)$lambda)
    else 1 - stats::plogis(cp$delta$logit_a + cp$delta$logit_b * log(mu))
}

simulate_catch <- function(sets, cfg) {
    om_set_seed(cfg$reproducibility$seeds$catch)
    cp <- cfg$catch_process
    mu <- sets$TrueCatchability * sets$Hooks * sets$TrueDensity
    stopifnot(all(is.finite(mu)), all(mu >= 0))
    sets$ExpectedCatch <- mu
    sets$ZeroProb <- zero_prob(mu, cfg)
    if (cp$distribution == "tweedie") {
        sets$TrueCatch <- rtweedie_cpg(mu, cp$power, cp$dispersion)
    } else {
        p_pos <- 1 - sets$ZeroProb
        pos <- stats::runif(nrow(sets)) < p_pos
        sdl <- cp$delta$sdlog
        y <- numeric(nrow(sets))
        y[pos] <- stats::rlnorm(sum(pos),
                                log(mu[pos] / p_pos[pos]) - sdl^2 / 2, sdl)
        sets$TrueCatch <- y
    }
    sets
}

########################################################################
######@> Companion species...

species_lat_effect <- function(lat, p) {
    x <- if (isTRUE(p$use_abs_lat)) abs(lat) else lat
    -0.5 * ((x - p$lat_center) / p$lat_sd)^2
}

######@> Expected_<sp> and TrueCatch_<sp> per set (seed 'species',
######@> independent of the target catch)...
simulate_companion_catch <- function(sets, cfg) {
    spc <- cfg$species
    if (!isTRUE(spc$enabled)) return(sets)
    om_set_seed(cfg$reproducibility$seeds$species)
    n <- nrow(sets)
    g_hbf <- hbf_effect_fun(sets$HooksBetweenFloats,
                            list(effect = 1, rate = cfg$catchability$hbf$rate,
                                 ref = cfg$catchability$hbf$ref))
    for (sp in spc$companions) {
        p <- spc$params[[sp]]
        log_mu <- log(p$ref / 1000) + log(sets$Hooks) +
                  as.numeric(p$strategy_effect[sets$TrueFishingStrategy]) +
                  p$hbf_effect * g_hbf +
                  species_lat_effect(sets$Latitude, p) +
                  log(interp_anchors(sets$Year, p$trend)) +
                  stats::rnorm(n, 0, spc$residual_sd)
        mu <- exp(log_mu)
        sets[[paste0("Expected_", sp)]] <- mu
        sets[[paste0("TrueCatch_", sp)]] <- rtweedie_cpg(mu, spc$power,
                                                        spc$dispersion)
    }
    sets$TrueCatch_total <- sets$TrueCatch +
        rowSums(sets[, paste0("TrueCatch_", spc$companions), drop = FALSE])
    sets
}

species_truth_columns <- function(cfg) {
    spc <- cfg$species
    if (!isTRUE(spc$enabled)) return(character(0))
    c(paste0("Expected_", spc$companions),
      paste0("TrueCatch_", spc$companions), "TrueCatch_total")
}

species_observed_columns <- function(cfg) {
    spc <- cfg$species
    if (!isTRUE(spc$enabled)) return(character(0))
    paste0("Catch_", spc$companions)
}
