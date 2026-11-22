test_that("fishery truth on a small configuration passes all checks", {
    sim <- simulate_biomass(small_biomass_cfg(), small_domain(),
                            long_table = FALSE, verbose = FALSE)
    fcfg <- small_fishery_cfg()
    fish <- simulate_fishery(sim, fcfg, verbose = FALSE)
    expect_s3_class(fish, "om_fishery")
    td <- fish$data
    expect_true(nrow(td) > 1000)
    expect_setequal(unique(td$Fleet), c("N", "S"))
    expect_true(all(td$Region[td$Fleet == "S"] %in% c("R02", "R03")))
    expect_equal(td$ExpectedCatch,
                 td$TrueCatchability * td$Hooks * td$TrueDensity)
    expect_true(all(c("TrueCatch_YFT", "TrueCatch_total") %in% names(td)))
    ## same configuration => identical data; caller RNG preserved
    set.seed(3); a <- runif(1); set.seed(3)
    fish2 <- simulate_fishery(sim, fcfg, verbose = FALSE)
    expect_identical(a, runif(1))
    expect_identical(fish$data, fish2$data)

    scen <- generate_scenarios(fish, verbose = FALSE)
    expect_s3_class(scen, "om_scenarios")
    expect_length(scen$datasets, 8)
    expect_false("HooksBetweenFloats" %in% names(scen$datasets[[2]]))
    d4 <- scen$datasets[["04_global_temporal_uncertainty"]]
    early <- d4$Year <= 1995
    expect_gt(mean(is.na(d4$HooksBetweenFloats[early])), 0.4)
    expect_equal(mean(is.na(d4$HooksBetweenFloats[!early])), 0)
    expect_true(all(is.na(d4$Cell_ID[early])))
    expect_identical(scen$datasets[[1]]$Catch, td$TrueCatch)

    tab <- cpue_biomass_table(td, fish$truth)
    expect_equal(nrow(tab), 16)
    expect_s3_class(catchability_summary_table(td), "data.frame")
    rec <- strategy_recovery_diagnostic(td, fcfg)
    expect_true(rec$summary$cluster_accuracy_best_match > 1 / 3)
})

test_that("alternative catch and observation options run", {
    sim <- simulate_biomass(small_biomass_cfg(), small_domain(),
                            long_table = FALSE, verbose = FALSE)
    fcfg <- small_fishery_cfg()
    fcfg$catch_process$distribution <- "delta_lognormal"
    fcfg$strategies$misclassification <- 0.1
    fcfg$species$enabled <- FALSE
    fcfg$sets$unit <- "per_vessel_year"
    fish <- simulate_fishery(sim, fcfg, verbose = FALSE)
    expect_false("TrueCatch_YFT" %in% names(fish$data))
    obs <- apply_observation_process(fish$data, "complete", fcfg, fish$truth)
    m <- attr(obs, "mechanisms")
    expect_gt(m$strategy_misclassified, 0)
    expect_lt(mean(obs$FishingStrategy == fish$data$TrueFishingStrategy), 1)
})

test_that("fishery runs on a domain with custom regions and fleets", {
    dom <- om_domain_grid(lon = c(-40, -10), lat = c(-25, 15),
                          region_breaks = 0, region_labels = c("N", "S"),
                          geometry = FALSE, verbose = FALSE)
    sim <- simulate_biomass(small_biomass_cfg(), dom, long_table = FALSE,
                            verbose = FALSE)
    fcfg <- small_fishery_cfg()
    fcfg$fleets$N$regions <- "N"
    fcfg$fleets$S$regions <- c("N", "S")
    fcfg$catchability$region_effect <- c(N = 0, S = -0.2)
    fcfg$scenarios <- list(
        list(name = "all", regions = c("N", "S"), drop = character(0),
             observation = "complete", objective = "all"),
        list(name = "south", regions = "S", drop = "HooksBetweenFloats",
             observation = "temporal", objective = "south"))
    fish <- simulate_fishery(sim, fcfg, verbose = FALSE)
    expect_true(all(fish$data$Region[fish$data$Fleet == "N"] == "N"))
    scen <- generate_scenarios(fish, verbose = FALSE)
    expect_identical(names(scen$datasets), c("all", "south"))
    expect_true(all(scen$datasets$south$Region == "S"))
})
