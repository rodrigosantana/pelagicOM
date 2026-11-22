test_that("bundled ICCAT grid gives the BET-A domain of Experimento 02", {
    dom <- om_domain_iccat("BET-A", geometry = FALSE, verbose = FALSE)
    expect_s3_class(dom, "om_domain")
    expect_equal(nrow(dom$cells), 10051)
    expect_equal(dom$lattice$n_row, 130)
    expect_equal(dom$lattice$n_col, 140)
    expect_equal(as.vector(table(dom$cells$Region)), c(4519, 2368, 3164))
    expect_identical(names(dom$cells),
                     c("Cell_ID", "Longitude", "Latitude", "Nominal_lon0",
                       "Nominal_lat0", "Row", "Col", "Area_km2", "Area_frac",
                       "Region"))
})

test_that("other ICCAT stock areas can be used as domains", {
    st <- iccat_stocks()
    expect_true(all(c("BET-A", "YFT-A", "ALB-N", "ALB-S", "SWO-N",
                      "BFT-E", "SKJ-W") %in% st$stock_code))
    alb <- om_domain_iccat("ALB-S", geometry = FALSE, verbose = FALSE)
    expect_equal(nrow(alb$cells), st$n_cells[st$stock_code == "ALB-S"])
    expect_true(max(alb$cells$Latitude) < 7)  # ALB-S: south of 5N (coastal centroids up to 6.2N)
    expect_true(all(alb$cells$Row >= 1 & alb$cells$Row <= alb$lattice$n_row))
    expect_error(om_domain_iccat("XXX", geometry = FALSE), "unknown")
    expect_message(om_domain_iccat("ALB-N", geometry = FALSE),
                   "regions without cells")
})

test_that("classify_regions follows the rule of Experimento 02", {
    r <- classify_regions(c(-35, -20, -19.5, 0, 20, 20.5, NA))
    expect_identical(as.character(r),
                     c("R03", "R02", "R02", "R02", "R02", "R01", NA))
    expect_identical(levels(r), c("R01", "R02", "R03"))
    r2 <- classify_regions(c(-10, 10), breaks = 0, labels = c("N", "S"))
    expect_identical(as.character(r2), c("S", "N"))
    r1 <- classify_regions(c(-10, 10), breaks = numeric(0), labels = "ALL")
    expect_identical(as.character(r1), c("ALL", "ALL"))
})

test_that("synthetic grid has geodesic areas equal to the ICCAT grid", {
    dom <- small_domain()
    expect_equal(nrow(dom$cells), 30 * 40)
    ## open-ocean ICCAT cells: Area_km2 / Area_frac = area of the nominal
    ## 1x1 cell, computed by lwgeom exactly as in the synthetic grid
    ic <- om_domain_iccat(geometry = FALSE, verbose = FALSE)$cells
    for (lat0 in c(-25, 0, 14)) {
        a_syn <- dom$cells$Area_km2[dom$cells$Nominal_lat0 == lat0][1]
        a_icc <- with(ic[ic$Nominal_lat0 == lat0 & ic$Area_frac == 1, ],
                      Area_km2[1])
        expect_equal(a_syn, a_icc, tolerance = 1e-10)
    }
    expect_equal(dom$meta$area_method,
                 "lwgeom::st_geod_area (WGS84 ellipsoid)")
    ex <- om_domain_grid(lon = c(-10, 0), lat = c(0, 10), geometry = FALSE,
                         exclude = function(lon, lat) lon > -2,
                         verbose = FALSE)
    expect_equal(nrow(ex$cells), 8 * 10)
})

test_that("geodesic_area_km2 uses lwgeom on the WGS84 ellipsoid", {
    cell <- sf::st_sfc(sf::st_polygon(list(cbind(c(0, 1, 1, 0, 0),
                                                 c(0, 0, 1, 1, 0)))),
                       crs = 4326)
    expect_equal(geodesic_area_km2(cell),
                 as.numeric(lwgeom::st_geod_area(cell)) / 1e6)
    expect_equal(geodesic_area_km2(cell), 12308.8, tolerance = 1e-4)
    expect_error(geodesic_area_km2(sf::st_transform(cell, 3857)),
                 "geographic")
})

## Reading the ICCAT GeoPackage (about 40 s). Runs only when
## PELAGICOM_EXP02 points to the Experimento_02 folder (which holds
## ICCAT/ICCAT_gis.gpkg and the saved domain of the experiment).
test_that("om_domain_from_gpkg + lwgeom rebuilds the Experimento 02 domain", {
    ref <- Sys.getenv("PELAGICOM_EXP02")
    gpkg <- file.path(ref, "ICCAT", "ICCAT_gis.gpkg")
    skip_if(!nzchar(ref) || !file.exists(gpkg),
            "PELAGICOM_EXP02 not set (ICCAT GeoPackage unavailable)")
    dom <- om_domain_from_gpkg(gpkg, verbose = FALSE)
    saved <- readRDS(file.path(ref, "Simulacao_Biomassa", "data",
                               "spatial_domain.rds"))
    expect_identical(dom$cells, saved$cells)
    expect_identical(dom$lattice, saved$lattice)
    expect_identical(sf::st_geometry(dom$geometry),
                     sf::st_geometry(saved$geometry))
    expect_identical(dom$cells,
                     om_domain_iccat(geometry = FALSE, verbose = FALSE)$cells)
    ## a smaller stock area: same cells as the bundled grid
    alb <- om_domain_from_gpkg(gpkg, layer_stock = "albacore_tuna_stock_areas",
                               stock_code = "ALB-S",
                               selection = "point_on_surface", verbose = FALSE)
    expect_identical(alb$cells, om_domain_iccat("ALB-S", geometry = FALSE,
                                                verbose = FALSE)$cells)
    expect_identical(alb$lattice, om_domain_iccat("ALB-S", geometry = FALSE,
                                                  verbose = FALSE)$lattice)
})
