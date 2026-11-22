## Small, fast configurations used by the tests: a synthetic 1x1 domain
## (30 x 40 cells), 16 years and two fleets with a few vessels.

small_domain <- function() {
    om_domain_grid(lon = c(-40, -10), lat = c(-25, 15), geometry = FALSE,
                   verbose = FALSE)
}

small_biomass_cfg <- function(...) {
    om_biomass_config("BET_ICCAT",
        general = list(label = "test", seed = 123),
        temporal = list(year_start = 1990, year_end = 2005),
        population = list(decline = list(start = 1992, end = 1998),
                          recovery = list(start = 2000, end = 2005)),
        shift = list(start = 1990, end = 2005),
        output = list(map_years = c(1990, 2005)), ...)
}

small_fishery_cfg <- function() {
    cfg <- om_fishery_config("BET_ICCAT")
    cfg$temporal$year_start <- 1990
    cfg$temporal$year_end <- 2005
    cfg$fleets <- list(
        N = om_fleet(n_vessels = 4, year_start = 1990, year_end = 2005,
                     regions = c("R01", "R02"), core_lon = -25, core_lat = 5),
        S = om_fleet(n_vessels = 3, year_start = 1995, year_end = 2005,
                     regions = c("R02", "R03"), core_lon = -20,
                     core_lat = -15, strategy_comp = c(S1 = 0.2, S2 = 0.3,
                                                       S3 = 0.5)))
    cfg$catchability$hbf$by_fleet <- NULL
    cfg$observation$temporal[[1]]$period <- c(1950, 1995)
    cfg$observation$temporal[[2]]$period <- c(1996, 2025)
    cfg$output$map_years <- c(1990, 2005)
    cfg$species$cluster_sample <- 500
    validate_fishery_config(cfg)
}
