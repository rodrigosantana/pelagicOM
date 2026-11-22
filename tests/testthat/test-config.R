test_that("BET_ICCAT presets hold the Experimento 02 values", {
    b <- om_biomass_config("BET_ICCAT")
    expect_s3_class(b, "om_biomass_config")
    expect_equal(b$general$seed, 20261005)
    expect_equal(b$population$K, 1e6)
    expect_equal(b$population$r, 0.30)
    expect_equal(b$spatial$region_breaks, c(-20, 20))
    expect_equal(b$spatial$region_labels, c("R01", "R02", "R03"))
    f <- om_fishery_config("BET_ICCAT")
    expect_identical(names(f$fleets), c("A", "B", "C", "D", "E"))
    expect_equal(sum(sapply(f$fleets, `[[`, "n_vessels")), 190)
    expect_length(f$scenarios, 8)
    expect_equal(f$reproducibility$seeds$catch, 20261108)
    expect_true("BET_ICCAT" %in% om_presets()$preset)
})

test_that("om_config_update merges named lists and replaces the rest", {
    b <- om_biomass_config()
    u <- om_config_update(b, population = list(r = 0.5,
                                               decline = list(u_peak = 0.3)))
    expect_equal(u$population$r, 0.5)
    expect_equal(u$population$decline$u_peak, 0.3)
    expect_equal(u$population$decline$start, 1965)
    expect_equal(u$population$K, b$population$K)
    hs <- list(list(lon = 0, lat = 0, sd_lon = 5, sd_lat = 5, amp = 1))
    u2 <- om_config_update(b, habitat = list(hotspots = hs))
    expect_identical(u2$habitat$hotspots, hs)
    expect_s3_class(u2, "om_biomass_config")
    expect_message(om_config_update(b, population = list(rr = 1)), "rr")
    ## the same section given twice: both are applied, later entries win
    u3 <- om_config_update(b, population = list(r = 0.4),
                           population = list(K = 2e6, r = 0.6))
    expect_equal(c(u3$population$r, u3$population$K), c(0.6, 2e6))
    f <- om_config_update(om_fishery_config(), fleets = list(E = NULL))
    expect_identical(names(f$fleets), c("A", "B", "C", "D"))
    f2 <- om_fishery_config(fleets = list(A = list(n_vessels = 10)))
    expect_equal(f2$fleets$A$n_vessels, 10)
    expect_equal(f2$fleets$A$core_lon, -45)
})

test_that("validation catches incoherent configurations", {
    b <- om_biomass_config()
    b$spatial$region_labels <- c("N", "S")
    expect_error(validate_biomass_config(b), "region_labels")
    b <- om_biomass_config()
    b$habitat$envelope_type <- "other"
    expect_error(validate_biomass_config(b))
    f <- om_fishery_config()
    f$fleets$A$strategy_comp <- c(S1 = 0.5, S2 = 0.5, S3 = 0.5)
    expect_error(validate_fishery_config(f))
    f <- om_fishery_config()
    f$fleets$A$regions <- "R09"
    sim <- simulate_biomass(small_biomass_cfg(), small_domain(),
                            long_table = FALSE, verbose = FALSE)
    expect_error(simulate_fishery(sim, f, verbose = FALSE), "R09")
})

test_that("configurations saved by Experimento 02 are accepted", {
    b <- unclass(om_biomass_config())
    b$spatial$region_breaks <- b$spatial$region_labels <- NULL
    b$spatial$region_lat_north <- 20; b$spatial$region_lat_south <- -20
    b$habitat$envelope_type <- NULL
    v <- validate_biomass_config(b)
    expect_equal(v$spatial$region_breaks, c(-20, 20))
    expect_equal(v$habitat$envelope_type, "latitude")
})

test_that("om_fleet builds a valid fleet and missing HBF multipliers are filled", {
    f <- om_fishery_config()
    f$fleets$F <- om_fleet(n_vessels = 3, regions = "R02")
    v <- validate_fishery_config(f)
    expect_equal(unname(v$catchability$hbf$by_fleet["F"]), 1)
})
