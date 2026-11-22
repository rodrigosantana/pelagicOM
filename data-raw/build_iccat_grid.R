########################################################################
## Description: pelagicOM - builds the bundled ICCAT grid
##              (inst/extdata/iccat_grid.rds and iccat_geometry.rds)
##
## Author: Rodrigo Sant'Ana
## Created: 2026-11-22
## Version: 0.1.1
##
## Database info: Experimento_02/ICCAT/ICCAT_gis.gpkg (read only)
##
### Commentary:
##
## 1. builds the BET-A domain from the GeoPackage with
##    om_domain_from_gpkg() (planar topology, geodesic areas on the WGS84
##    ellipsoid by lwgeom) and stops unless its cells, lattice and polygons
##    are identical to the domain saved by Experimento 02
##    (Simulacao_Biomassa/data/spatial_domain.rds);
## 2. stores the cell table (+ per-cell bounding box) of the full grid;
## 3. computes the membership of every cell in every ICCAT stock area of
##    the GeoPackage with the package rule "point_on_surface" (BET-A keeps
##    the "intersects" rule of Experimento 02: all cells);
## 4. stores slightly simplified cell polygons for maps.
##
## Requires sf and lwgeom (Imports of pelagicOM).
## Usage (from R-Work/):  Rscript pelagicOM/data-raw/build_iccat_grid.R
##
### Code:
########################################################################

suppressPackageStartupMessages({
    library(sf)
    pkgload::load_all("pelagicOM", quiet = TRUE)
})
gpkg <- "Experimento_02/ICCAT/ICCAT_gis.gpkg"
ref_domain <- "Experimento_02/Simulacao_Biomassa/data/spatial_domain.rds"
out_dir <- "pelagicOM/inst/extdata"
stopifnot(file.exists(gpkg), file.exists(ref_domain))
message("lwgeom ", packageVersion("lwgeom"), " | ",
        paste(names(lwgeom::lwgeom_extSoftVersion()),
              lwgeom::lwgeom_extSoftVersion(), collapse = ", "))

########################################################################
######@> 1. BET-A domain from the GeoPackage, checked against Exp. 02...

dom <- om_domain_from_gpkg(gpkg, layer_grid = "grids_01x01",
                           layer_stock = "bigeye_tuna_stock_areas",
                           stock_code = "BET-A", selection = "intersects")
ref <- readRDS(ref_domain)
stopifnot(identical(dom$cells, ref$cells),
          identical(dom$lattice, ref$lattice),
          identical(sf::st_geometry(dom$geometry),
                    sf::st_geometry(ref$geometry)),
          identical(dom$meta$n_invalid_fixed, ref$meta$n_invalid_fixed))
message("om_domain_from_gpkg() + lwgeom reproduce the Experimento 02 ",
        "domain: cells, lattice and polygons identical")

########################################################################
######@> 2. Cell table...

suppressMessages(sf_use_s2(FALSE))
bb <- do.call(rbind, lapply(st_geometry(dom$geometry),
                            function(g) as.numeric(st_bbox(g))))
cells <- dom$cells[, c("Cell_ID", "Longitude", "Latitude", "Nominal_lon0",
                       "Nominal_lat0", "Area_km2", "Area_frac")]
cells$xmin <- bb[, 1]; cells$ymin <- bb[, 2]
cells$xmax <- bb[, 3]; cells$ymax <- bb[, 4]

########################################################################
######@> 3. Stock membership...

layers <- st_layers(gpkg)$name
stock_layers <- c(grep("_stock_areas$", layers, value = TRUE),
                  "entire_iccat_area")
membership <- list(); stocks <- list()
for (ln in stock_layers) {
    x <- st_read(gpkg, layer = ln, quiet = TRUE)
    if (!"CODE" %in% names(x)) {
        message("  layer ", ln, " has no CODE field: skipped")
        next
    }
    if (!all(st_is_valid(x))) x <- st_make_valid(x)
    nm <- if ("NAME_EN" %in% names(x)) as.character(x$NAME_EN) else
        as.character(x$CODE)
    for (k in seq_len(nrow(x))) {
        code <- as.character(x$CODE[k])
        if (code %in% names(membership)) code <- paste0(code, "_", ln)
        rule <- if (code == "BET-A") "intersects" else "point_on_surface"
        idx <- which(pelagicOM:::cells_in_stock(dom$geometry, x[k, ], rule))
        if (!length(idx)) next
        membership[[code]] <- as.integer(idx)
        stocks[[code]] <- data.frame(stock_code = code, layer = ln,
                                     name = nm[k], n_cells = length(idx),
                                     selection = rule,
                                     stringsAsFactors = FALSE)
        message(sprintf("  %-8s %-38s %-17s %5d cells", code, ln, rule,
                        length(idx)))
    }
}
stocks <- do.call(rbind, stocks); rownames(stocks) <- NULL
stopifnot(length(membership[["BET-A"]]) == nrow(cells))

grid <- list(
    cells = cells, stocks = stocks, membership = membership,
    meta = list(source = "ICCAT GIS GeoPackage (ICCAT_gis.gpkg)",
                layer_grid = "grids_01x01", crs = dom$meta$crs,
                epsg = dom$meta$epsg,
                n_invalid_fixed = dom$meta$n_invalid_fixed,
                area_method = dom$meta$area_method,
                lwgeom = as.character(packageVersion("lwgeom")),
                built_on = format(Sys.time(), "%Y-%m-%d %H:%M:%S"),
                rule = paste("cell in stock if a point on its surface lies",
                             "inside the stock polygon; BET-A = all cells",
                             "(intersection, Experimento 02)")))
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)
saveRDS(grid, file.path(out_dir, "iccat_grid.rds"), compress = "xz")

########################################################################
######@> 4. Simplified geometry for maps...

geom <- dom$geometry
geom_s <- suppressWarnings(st_simplify(geom, preserveTopology = TRUE,
                                       dTolerance = 0.01))
empty <- st_is_empty(geom_s)
if (any(empty)) st_geometry(geom_s)[empty] <- st_geometry(geom)[empty]
geom_s <- st_make_valid(geom_s)
stopifnot(identical(geom_s$Cell_ID, cells$Cell_ID), !any(st_is_empty(geom_s)))
saveRDS(geom_s, file.path(out_dir, "iccat_geometry.rds"), compress = "xz")

print(file.size(file.path(out_dir, c("iccat_grid.rds",
                                     "iccat_geometry.rds"))) / 2^20)
message("done")
