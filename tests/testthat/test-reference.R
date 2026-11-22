## Full reproduction of Experimento 02 (about 40 s). Runs only when the
## environment variable PELAGICOM_EXP02 points to the Experimento_02
## folder, e.g.  PELAGICOM_EXP02=/path/R-Work/Experimento_02
test_that("BET_ICCAT reproduces Experimento 02 bit for bit", {
    ref <- Sys.getenv("PELAGICOM_EXP02")
    skip_if(!nzchar(ref) || !dir.exists(ref),
            "PELAGICOM_EXP02 not set (reference outputs unavailable)")
    run <- om_run("BET_ICCAT", domain = om_domain_iccat(geometry = FALSE,
                                                        verbose = FALSE),
                  verbose = FALSE)
    cmp <- om_compare_reference(run, ref)
    expect_equal(nrow(cmp), 17)
    expect_true(all(cmp$identical), info = paste(
        cmp$component[!cmp$identical], collapse = "; "))
})
