########################################################################
## Description: pelagicOM - simulation of the biomass operating truth
##              B(y, s) (Part I orchestrator)
##
## Author: Rodrigo Sant'Ana
## Created: 2026-11-22
## Version: 0.1.0
##
### Commentary:
##
## Port of Experimento_02/Simulacao_Biomassa/R/05_simulate_biomass.R
##
##   B(y, s) = B_total(y) * p(y, s)
##   p(y, s) = D(y, s) A_s / sum_s' D(y, s') A_s'
##   D(y, s) = exp( static(s) + E(y, s) + eps(y, s) )
##
## Fixed order of the random draws (same seed => same result):
##   1. process error of B_total;  2. persistent field Z(s);
##   3. fields xi_y, year by year.
##
### Code:
########################################################################

######@> Log-density -> weights p(y, s) (columns sum to 1). The column
######@> maximum is subtracted before exponentiating to avoid overflow...
spatial_weights <- function(logD, area) {
    W <- exp(sweep(logD, 2, apply(logD, 2, max), "-")) * area
    sweep(W, 2, colSums(W), "/")
}

#' Simulate the spatio-temporal biomass operating truth
#'
#' Generates a completely known biomass trajectory for every year and
#' cell of the spatial domain: total biomass from a surplus-production
#' model, distributed in space by a static habitat (latitudinal envelope,
#' hotspots, gradient, persistent random field), a redistribution of the
#' envelope in time (e.g. poleward expansion) and spatio-temporal noise.
#' No fishing process is simulated here (see [simulate_fishery()]).
#'
#' With `om_biomass_config("BET_ICCAT")` the result is identical, bit for
#' bit, to `Simulacao_Biomassa/outputs/data/biomass_true_base.rds` of
#' Experimento 02.
#'
#' The caller's random number stream is left untouched: the simulation
#' seeds its own stream with `cfg$general$seed` and restores the previous
#' state on exit.
#'
#' @param cfg Biomass configuration ([om_biomass_config()]).
#' @param domain Optional spatial domain ([om_domain_iccat()],
#'   [om_domain_grid()], [om_domain_from_gpkg()]). By default it is built
#'   from `cfg$spatial`. Its regions take precedence over the ones in
#'   `cfg$spatial`.
#' @param long_table If `TRUE`, also builds the long table Year x Cell
#'   (`$table`), the main product of Experimento 02.
#' @param verbose Print progress messages.
#' @return An object of class `om_biomass`, a list with `cfg`, `dom`
#'   (domain), `pop` (B_total and related series; attribute `"ref"` with
#'   reference points), `base` (static components), `envelope`, `noise`,
#'   `logD`, `weights` (p), `biomass` (B, cells x years, t),
#'   `envelope_params` and `table`.
#' @seealso [check_simulation()], [regional_summary()],
#'   [make_biomass_figures()], [om_write_biomass()].
#' @examples
#' \donttest{
#' sim <- simulate_biomass(om_biomass_config(), verbose = FALSE)
#' sim
#' head(sim$pop)
#' }
#' @export
simulate_biomass <- function(cfg = om_biomass_config(), domain = NULL,
                             long_table = TRUE, verbose = TRUE) {
    cfg <- validate_biomass_config(cfg)
    years <- cfg$temporal$year_start:cfg$temporal$year_end

    om_msg(verbose, "== 1. Spatial domain =============================")
    dom <- if (is.null(domain)) om_domain(cfg, verbose = verbose) else domain
    if (!inherits(dom, "om_domain")) class(dom) <- c("om_domain", class(dom))
    dom$regions <- domain_regions(dom, cfg)
    check_spatial_domain(dom)
    cfg$spatial$region_breaks <- dom$regions$breaks
    cfg$spatial$region_labels <- dom$regions$labels

    out <- with_om_rng({
        ###@> Single seed for the whole run...
        om_set_seed(cfg$general$seed)

        om_msg(verbose, "== 2. Total biomass ==============================")
        pop <- simulate_total_biomass(cfg)
        if (verbose) print(summarize_phases(pop), digits = 3,
                           row.names = FALSE)

        om_msg(verbose, "== 3. Static spatial structure ===================")
        base <- build_base_habitat(dom, cfg)

        om_msg(verbose, "== 4. Redistribution and spatio-temporal noise ===")
        E   <- build_envelope_matrix(dom, years, cfg)
        eps <- build_spatiotemporal_noise(dom, years, cfg)
        list(pop = pop, base = base, E = E, eps = eps)
    })

    om_msg(verbose, "== 5. Composition B(y, s) ========================")
    logD <- out$base$static + out$E + out$eps       # static recycles by column
    P    <- spatial_weights(logD, dom$cells$Area_km2)
    B    <- sweep(P, 2, out$pop$B_total, "*")
    dimnames(B) <- dimnames(P) <- dimnames(logD) <-
        list(dom$cells$Cell_ID, years)

    sim <- list(cfg = cfg, dom = dom, pop = out$pop, base = out$base,
                envelope = out$E, noise = out$eps, logD = logD,
                weights = P, biomass = B,
                envelope_params = envelope_parameters(years, cfg))
    class(sim) <- c("om_biomass", "list")
    if (isTRUE(long_table)) {
        sim$table <- build_long_table(sim)
        om_msg(verbose, "  long table: ", nrow(sim$table), " rows (",
               length(years), " years x ", nrow(dom$cells), " cells)")
    }
    sim
}

#' Long table of the biomass truth
#'
#' Table Year x Cell_ID with Year, Cell_ID, Longitude, Latitude, Region,
#' Area_km2, B_total (t), Spatial_weight (p, sums to 1 per year),
#' Biomass (t), Density (t/km2), Relative_biomass (biomass / temporal mean
#' of the cell) and Depletion (B_total / K). Rows are ordered by year and,
#' within year, by the order of the cells in the domain.
#'
#' @param sim An `om_biomass` object.
#' @return A data frame.
#' @export
build_long_table <- function(sim) {
    cl <- sim$dom$cells; pop <- sim$pop
    ny <- nrow(pop); n <- nrow(cl)
    cell_mean <- rowMeans(sim$biomass)
    data.frame(
        Year            = rep(pop$Year, each = n),
        Cell_ID         = rep(cl$Cell_ID, times = ny),
        Longitude       = rep(cl$Longitude, times = ny),
        Latitude        = rep(cl$Latitude, times = ny),
        Region          = rep(cl$Region, times = ny),
        Area_km2        = rep(cl$Area_km2, times = ny),
        B_total         = rep(pop$B_total, each = n),
        Spatial_weight  = as.vector(sim$weights),
        Biomass         = as.vector(sim$biomass),
        Density         = as.vector(sim$biomass) / rep(cl$Area_km2,
                                                       times = ny),
        Relative_biomass = as.vector(sim$biomass) / rep(cell_mean,
                                                        times = ny),
        Depletion       = rep(pop$Depletion, each = n),
        stringsAsFactors = FALSE
    )
}

#' @export
print.om_biomass <- function(x, ...) {
    pop <- x$pop; ref <- attr(pop, "ref")
    n <- nrow(pop)
    cat("<pelagicOM biomass truth> label '", x$cfg$general$label, "' | seed ",
        x$cfg$general$seed, "\n", sep = "")
    cat(sprintf("  %d cells x %d years (%d-%d) | stock area %s\n",
                nrow(x$dom$cells), n, pop$Year[1], pop$Year[n],
                x$dom$meta$stock_code %||% "?"))
    cat(sprintf("  B_total: %s t (%d) -> %s t (%d) | B/K %.2f -> %.2f | Bmsy %s t\n",
                format(round(pop$B_total[1]), big.mark = ","), pop$Year[1],
                format(round(pop$B_total[n]), big.mark = ","), pop$Year[n],
                pop$Depletion[1], pop$Depletion[n],
                format(round(ref$Bmsy), big.mark = ",")))
    reg <- regional_summary(x)
    s0 <- reg[reg$Year == pop$Year[1], ]; s1 <- reg[reg$Year == pop$Year[n], ]
    cat("  regional share:", paste(sprintf("%s %.2f -> %.2f", s0$Region,
                                           s0$Share, s1$Share),
                                   collapse = " | "), "\n")
    invisible(x)
}
