########################################################################
## Description: pelagicOM - dynamics of total biomass B_total(y)
##              (Pella-Tomlinson with exogenous removal rate)
##
## Author: Rodrigo Sant'Ana
## Created: 2026-11-22
## Version: 0.1.0
##
### Commentary:
##
## Port of Experimento_02/Simulacao_Biomassa/R/02_population_dynamics.R
##
##   SP(y)    = (r / p) * B(y) * (1 - (B(y) / K(y))^p)
##   B(y + 1) = max( [B(y) + SP(y) - u(y) * B(y)] * exp(eps(y + 1)),
##                   B_floor )
##   eps(y)   = rho * eps(y - 1) + N(0, sd), bias corrected (E[exp] = 1)
##   K(y)     = K * (1 + K_trend)^(y - y0)
##
## cfg$population$model accepts "pella_tomlinson", "logistic" or a
## function f(B, K, r, shape) returning the surplus production.
##
### Code:
########################################################################

######@> Removal rate u(y) by phases (stable -> decline -> plateau ->
######@> recovery -> stable): anchors interpolated linearly and smoothed...
removal_rate_trajectory <- function(years, pp) {
    anchors <- c(
        stats::setNames(pp$u_base,            years[1]),
        stats::setNames(pp$u_base,            pp$decline$start),
        stats::setNames(pp$decline$u_peak,    pp$decline$end),
        stats::setNames(pp$decline$u_peak,    pp$recovery$start),
        stats::setNames(pp$recovery$u_end,    pp$recovery$end),
        stats::setNames(pp$recovery$u_end,    years[length(years)])
    )
    ax <- as.numeric(names(anchors)); av <- as.numeric(anchors)
    keep <- !duplicated(ax)
    u <- stats::approx(ax[keep], av[keep], xout = years, rule = 2)$y
    u <- moving_average(u, k = pp$u_smooth)
    pmin(pmax(u, 0), 0.95)
}

######@> Surplus production function f(B, K, r, shape)...
surplus_production_fun <- function(pp) {
    m <- pp$model
    if (is.function(m)) return(m)
    switch(m,
           pella_tomlinson = function(B, K, r, shape)
               (r / shape) * B * (1 - (B / K)^shape),
           logistic = function(B, K, r, shape) r * B * (1 - B / K),
           stop("surplus_production_fun(): unknown model '", m, "'"))
}

#' Reference points of the production model
#'
#' Exact Bmsy and MSY for the Pella-Tomlinson and logistic models;
#' numerical search for a user-supplied production function.
#'
#' @param pp The `population` section of a biomass configuration.
#' @return List with `K`, `r`, `shape`, `Bmsy`, `MSY`, `umsy`.
#' @examples
#' reference_points(om_biomass_config()$population)
#' @export
reference_points <- function(pp) {
    f <- surplus_production_fun(pp)
    if (is.character(pp$model)) {
        p <- if (pp$model == "logistic") 1 else pp$shape
        Bmsy <- pp$K * (1 / (p + 1))^(1 / p)
    } else {
        Bmsy <- stats::optimize(function(B) -f(B, pp$K, pp$r, pp$shape),
                                c(1e-6 * pp$K, pp$K))$minimum
    }
    MSY <- f(Bmsy, pp$K, pp$r, pp$shape)
    list(K = pp$K, r = pp$r, shape = pp$shape, Bmsy = Bmsy, MSY = MSY,
         umsy = MSY / Bmsy)
}

######@> B_total(y) for all years. Assumes the RNG has already been
######@> seeded by simulate_biomass() (this is the FIRST random draw)...
simulate_total_biomass <- function(cfg) {
    pp    <- cfg$population
    years <- cfg$temporal$year_start:cfg$temporal$year_end
    n     <- length(years)
    f_sp  <- surplus_production_fun(pp)

    u    <- removal_rate_trajectory(years, pp)
    Ky   <- pp$K * (1 + pp$K_trend)^(years - years[1])
    eps  <- ar1_noise(n, sd = pp$proc_sd, rho = pp$proc_rho)

    shock <- rep(0, n)
    for (ev in pp$events) {
        idx <- match(ev$year, years)
        if (is.na(idx))
            stop("simulate_total_biomass(): event outside the period (",
                 ev$year, ")")
        shock[idx] <- shock[idx] + ev$log_shock
    }

    B <- SP <- R <- numeric(n)
    B[1] <- pp$K * pp$B0_frac * exp(shock[1])
    floor_B <- pp$B_floor_frac * pp$K
    for (t in seq_len(n)) {
        SP[t] <- f_sp(B[t], Ky[t], pp$r, pp$shape)
        R[t]  <- u[t] * B[t]
        if (t < n)
            B[t + 1] <- max((B[t] + SP[t] - R[t]) *
                            exp(eps[t + 1] + shock[t + 1]), floor_B)
    }

    ref <- reference_points(pp)
    pop <- data.frame(
        Year       = years,
        B_total    = B,
        K_year     = Ky,
        u          = u,
        Surplus    = SP,
        Removal    = R,
        Proc_error = eps + shock,
        Depletion  = B / Ky,
        B_Bmsy     = B / ref$Bmsy,
        stringsAsFactors = FALSE
    )
    attr(pop, "ref") <- ref
    pop
}

######@> Summary by quarters of the series (quick diagnostic)...
summarize_phases <- function(pop) {
    y <- pop$Year; n <- length(y)
    q <- split(seq_len(n), cut(seq_len(n), 4, labels = paste0("Q", 1:4)))
    data.frame(
        phase   = names(q),
        period  = sapply(q, function(i) sprintf("%d-%d", y[min(i)],
                                                y[max(i)])),
        B_mean  = sapply(q, function(i) mean(pop$B_total[i])),
        dep_ini = sapply(q, function(i) pop$Depletion[min(i)]),
        dep_end = sapply(q, function(i) pop$Depletion[max(i)]),
        u_mean  = sapply(q, function(i) mean(pop$u[i])),
        row.names = NULL
    )
}
