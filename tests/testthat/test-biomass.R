test_that("biomass truth satisfies its identities", {
    sim <- simulate_biomass(small_biomass_cfg(), small_domain(),
                            verbose = FALSE)
    expect_s3_class(sim, "om_biomass")
    expect_equal(dim(sim$biomass), c(1200, 16))
    expect_equal(unname(colSums(sim$weights)), rep(1, 16))
    expect_equal(unname(colSums(sim$biomass)), sim$pop$B_total)
    expect_equal(nrow(sim$table), 1200 * 16)
    res <- check_simulation(sim, verbose = FALSE)
    expect_true(res$structural_ok)
})

test_that("same seed, same result; caller RNG untouched", {
    cfg <- small_biomass_cfg(); dom <- small_domain()
    set.seed(42); a <- runif(3)
    set.seed(42)
    s1 <- simulate_biomass(cfg, dom, long_table = FALSE, verbose = FALSE)
    b <- runif(3)
    expect_identical(a, b)
    s2 <- simulate_biomass(cfg, dom, long_table = FALSE, verbose = FALSE)
    expect_identical(s1$biomass, s2$biomass)
    s3 <- simulate_biomass(om_config_update(cfg, general = list(seed = 9)),
                           dom, long_table = FALSE, verbose = FALSE)
    expect_false(identical(s1$biomass, s3$biomass))
})

test_that("BET_ICCAT biomass is reproduced (Experimento 02 checksums)", {
    sim <- simulate_biomass(om_biomass_config("BET_ICCAT"),
                            om_domain_iccat(geometry = FALSE, verbose = FALSE),
                            long_table = FALSE, verbose = FALSE)
    ## values of Simulacao_Biomassa/outputs/data/population_base.csv
    expect_equal(sim$pop$B_total[1], 950000)
    expect_equal(sim$pop$B_total[76], 318100.566272, tolerance = 1e-12)
    expect_equal(sum(sim$biomass), 41448680.9683, tolerance = 1e-12)
})

test_that("tuning options change the distribution as expected", {
    dom <- small_domain()
    ## temperate species: envelope on absolute latitude
    cfg <- small_biomass_cfg(habitat = list(envelope_type = "abs_latitude",
                                            lat_center = 15, lat_sd_north = 5,
                                            lat_sd_south = 5, hotspots = list(),
                                            field_sd = 0),
                             stochastic = list(enabled = FALSE),
                             shift = list(enabled = FALSE))
    sim <- simulate_biomass(cfg, dom, long_table = FALSE, verbose = FALSE)
    cg <- centre_of_gravity(sim)
    expect_gt(cg$Abs_lat_cg[1], 10)
    ## custom static layer (e.g. a covariate): a strong eastward preference
    cfg2 <- small_biomass_cfg(habitat = list(
        custom_effect = function(cells) 0.2 * (cells$Longitude + 25)))
    sim2 <- simulate_biomass(cfg2, dom, long_table = FALSE, verbose = FALSE)
    expect_gt(centre_of_gravity(sim2)$Lon_cg[1], -25)
    expect_length(sim2$base$custom, nrow(dom$cells))
    ## logistic production model and a user-defined one
    cfg3 <- small_biomass_cfg(population = list(model = "logistic"))
    expect_s3_class(simulate_biomass(cfg3, dom, long_table = FALSE,
                                     verbose = FALSE), "om_biomass")
    gompertz <- function(B, K, r, shape) r * B * log(K / B)
    cfg4 <- small_biomass_cfg(population = list(model = gompertz))
    s4 <- simulate_biomass(cfg4, dom, long_table = FALSE, verbose = FALSE)
    expect_true(all(is.finite(s4$pop$B_total)))
    ## a shock event lowers the biomass in its year
    cfg5 <- small_biomass_cfg(population = list(events = list(
        list(year = 1995, log_shock = -0.5))))
    s5 <- simulate_biomass(cfg5, dom, long_table = FALSE, verbose = FALSE)
    s0 <- simulate_biomass(small_biomass_cfg(), dom, long_table = FALSE,
                           verbose = FALSE)
    expect_lt(s5$pop$B_total[6], s0$pop$B_total[6])
    expect_equal(s5$pop$B_total[5], s0$pop$B_total[5])
})

test_that("domains with other regions work end to end", {
    dom <- om_domain_grid(lon = c(-40, -10), lat = c(-25, 15),
                          region_breaks = 0, region_labels = c("N", "S"),
                          geometry = FALSE, verbose = FALSE)
    sim <- simulate_biomass(small_biomass_cfg(), dom, long_table = TRUE,
                            verbose = FALSE)
    expect_identical(levels(sim$dom$cells$Region), c("N", "S"))
    expect_equal(sim$cfg$spatial$region_labels, c("N", "S"))
    expect_true(check_simulation(sim, verbose = FALSE)$structural_ok)
    expect_setequal(regional_summary(sim)$Region, c("N", "S"))
})
