########################################################################
## Description: pelagicOM - spatial domain (ICCAT 1x1 grid and stock
##              areas, GeoPackage reader, synthetic grids, regions)
##
## Author: Rodrigo Sant'Ana
## Created: 2026-11-22
## Version: 0.1.0
##
### Commentary:
##
## A domain is a list of class "om_domain" with the same components as
## the object built in Experimento_02/Simulacao_Biomassa/R/
## 01_spatial_domain.R:
##   cells    : data.frame (1 row per cell) Cell_ID, Longitude, Latitude,
##              Nominal_lon0, Nominal_lat0, Row, Col, Area_km2, Area_frac,
##              Region;
##   geometry : sf with Cell_ID + polygons (maps only; may be NULL);
##   lattice  : origin and size of the regular integer lattice used by
##              the Gaussian fields;
##   stock    : sf of the stock area (NULL for the bundled grid);
##   meta     : provenance;
##   regions  : list(breaks, labels) used to classify cells.
##
## Three constructors:
##   om_domain_iccat()     bundled ICCAT 1x1 grid (no GIS file needed);
##   om_domain_from_gpkg() reads an ICCAT-like GeoPackage (the original
##                         build_spatial_domain());
##   om_domain_grid()      synthetic rectangular 1x1 grid.
##
## Every cell area is geodesic, on the WGS84 ellipsoid, computed by
## lwgeom::st_geod_area() (geodesic_area_km2()). This is exactly what
## sf::st_area() did in Experimento 02 with spherical geometry (s2)
## switched off, so the areas of the bundled grid, of grids read from a
## GeoPackage and of synthetic grids are all computed the same way.
##
### Code:
########################################################################

########################################################################
######@> Regions...

#' Latitudinal regions
#'
#' Classifies latitudes into bands. With `breaks = c(-20, 20)` and
#' `labels = c("R01", "R02", "R03")` this is the rule of Experimento 02:
#' R01 when lat > 20, R03 when lat < -20 and R02 otherwise (both limits
#' inclusive). In general, the southernmost and northernmost bands are
#' open and every interior band is closed at its southern limit (the
#' northernmost interior band is closed at both limits).
#'
#' @param lat Numeric vector of latitudes.
#' @param breaks Ascending latitude limits (may be empty: one region).
#' @param labels Region labels ordered from north to south;
#'   `length(breaks) + 1` elements.
#' @return Factor with levels `labels`.
#' @examples
#' classify_regions(c(-35, -20, 0, 20, 35))
#' classify_regions(c(-35, 0, 35), breaks = 0, labels = c("North", "South"))
#' @export
classify_regions <- function(lat, breaks = c(-20, 20),
                             labels = c("R01", "R02", "R03")) {
    if (length(labels) != length(breaks) + 1L)
        stop("classify_regions(): 'labels' needs length(breaks) + 1 elements")
    if (!length(breaks)) {
        reg <- rep(labels[1], length(lat))
        reg[is.na(lat)] <- NA
        return(factor(reg, levels = labels))
    }
    k <- findInterval(lat, breaks, rightmost.closed = TRUE)
    factor(rev(labels)[k + 1L], levels = labels)
}

region_spec <- function(cfg_spatial) {
    list(breaks = as.numeric(cfg_spatial$region_breaks),
         labels = as.character(cfg_spatial$region_labels))
}

######@> Applies the regions to the cells; regions without cells are
######@> dropped (with a message) so that summaries never divide by an
######@> empty area...
assign_regions <- function(cells, regions, verbose = TRUE) {
    reg <- classify_regions(cells$Latitude, regions$breaks, regions$labels)
    empty <- setdiff(levels(reg), unique(as.character(reg)))
    if (length(empty)) {
        om_msg(verbose, "  regions without cells in this domain (dropped): ",
               paste(empty, collapse = ", "))
        reg <- droplevels(reg)
    }
    cells$Region <- reg
    cells
}

########################################################################
######@> Lattice...

lattice_from_cells <- function(lon0, lat0) {
    list(lon0_min = min(lon0), lat0_min = min(lat0),
         n_col = diff(range(lon0)) + 1L,
         n_row = diff(range(lat0)) + 1L)
}

########################################################################
######@> Geodesic areas (lwgeom)...

#' Geodesic area of polygons
#'
#' Area of polygons in geographic coordinates on the WGS84 ellipsoid,
#' computed by [lwgeom::st_geod_area()]. This is the computation behind the
#' cell areas of the ICCAT grid in Experimento 02 (`sf::st_area()` with
#' spherical geometry switched off delegates to `lwgeom`), and it is used by
#' every domain constructor of the package.
#'
#' @param x An `sf` or `sfc` object with polygons in longitude / latitude.
#' @return Numeric vector of areas in km2.
#' @examples
#' cell <- sf::st_sfc(sf::st_polygon(list(cbind(c(0, 1, 1, 0, 0),
#'                                              c(0, 0, 1, 1, 0)))),
#'                    crs = 4326)
#' geodesic_area_km2(cell)   # 1x1 degree cell at the equator
#' @export
geodesic_area_km2 <- function(x) {
    g <- sf::st_geometry(x)
    if (!isTRUE(sf::st_is_longlat(g)))
        stop("geodesic_area_km2(): geographic coordinates (lon/lat) expected")
    ###@> the compiled code of lwgeom calls require(sf); its startup message
    ###@> would report a temporary s2 setting of the caller...
    a <- suppressPackageStartupMessages(lwgeom::st_geod_area(g))
    as.numeric(a) / 1e6
}

######@> Nominal 1x1 cells from their south-west corners...
nominal_cell_polygons <- function(lon0, lat0, crs = sf::st_crs(4326)) {
    sf::st_sfc(lapply(seq_along(lon0), function(i)
        sf::st_polygon(list(cbind(
            c(lon0[i], lon0[i] + 1, lon0[i] + 1, lon0[i], lon0[i]),
            c(lat0[i], lat0[i], lat0[i] + 1, lat0[i] + 1, lat0[i]))))),
        crs = crs)
}

######@> Cells (polygons) that belong to a stock polygon. "intersects":
######@> any contact (rule of Experimento 02 for BET-A, the whole
######@> Convention area); "point_on_surface": a point on the cell surface
######@> lies inside the stock polygon (no cells that only share an edge
######@> with the stock boundary; rule of the bundled stock memberships).
######@> Planar tests (s2 off) on the regular lon/lat grid...
cells_in_stock <- function(cells, stock, selection = "intersects") {
    s2_old <- sf::sf_use_s2()
    on.exit(suppressMessages(sf::sf_use_s2(s2_old)), add = TRUE)
    suppressMessages(sf::sf_use_s2(FALSE))
    x <- switch(selection,
                intersects = cells,
                point_on_surface = suppressWarnings(
                    sf::st_point_on_surface(sf::st_geometry(cells))),
                stop("unknown selection rule '", selection, "'"))
    suppressMessages(sf::st_intersects(x, stock, sparse = FALSE))[, 1]
}

########################################################################
######@> Bundled ICCAT grid...

.om_cache <- new.env(parent = emptyenv())

iccat_grid_data <- function() {
    if (is.null(.om_cache$grid)) {
        f <- system.file("extdata", "iccat_grid.rds", package = "pelagicOM")
        if (!nzchar(f)) stop("bundled ICCAT grid not found (reinstall ",
                             "pelagicOM)")
        .om_cache$grid <- readRDS(f)
    }
    .om_cache$grid
}

#' ICCAT stock areas available in the bundled grid
#'
#' The package ships the 10051 cells of the official ICCAT 1x1 degree
#' grid (layer `grids_01x01` of the ICCAT GIS GeoPackage, cells clipped by
#' the coastline, geodesic area from `lwgeom`) together with the membership
#' of each cell in every stock area of the GeoPackage. The grid was built
#' with [om_domain_from_gpkg()] (script `data-raw/build_iccat_grid.R`) and
#' is identical to the domain of Experimento 02. A cell belongs to a stock
#' area when a point on its surface lies inside the stock polygon
#' (`selection = "point_on_surface"`); for BET-A (identical to the ICCAT
#' Convention area) membership is the intersection used in Experimento 02
#' (all cells).
#'
#' @return Data frame with `stock_code`, `layer`, `name` and `n_cells`.
#' @examples
#' iccat_stocks()
#' @export
iccat_stocks <- function() iccat_grid_data()$stocks

#' Spatial domain on the ICCAT 1x1 grid
#'
#' Builds the spatial domain of an ICCAT stock area from the grid bundled
#' with the package (no GIS file needed). For `stock_code = "BET-A"` the
#' result is identical to the domain of Experimento 02.
#'
#' @param stock_code Stock area code (see [iccat_stocks()]).
#' @param region_breaks,region_labels Latitudinal regions (see
#'   [classify_regions()]).
#' @param geometry Attach the cell polygons (`sf`), used by the maps.
#' @param verbose Print progress messages.
#' @return An object of class `om_domain`.
#' @examples
#' dom <- om_domain_iccat("BET-A", geometry = FALSE)
#' dom
#' ## the three regions of Experimento 02
#' table(dom$cells$Region)
#' @export
om_domain_iccat <- function(stock_code = "BET-A", region_breaks = c(-20, 20),
                            region_labels = c("R01", "R02", "R03"),
                            geometry = TRUE,
                            verbose = TRUE) {
    g <- iccat_grid_data()
    if (!stock_code %in% names(g$membership))
        stop("unknown ICCAT stock code '", stock_code, "'. Available: ",
             paste(names(g$membership), collapse = ", "))
    idx <- g$membership[[stock_code]]
    full <- g$cells[idx, ]
    lattice <- lattice_from_cells(full$Nominal_lon0, full$Nominal_lat0)
    cells <- data.frame(
        Cell_ID      = full$Cell_ID,
        Longitude    = full$Longitude,
        Latitude     = full$Latitude,
        Nominal_lon0 = full$Nominal_lon0,
        Nominal_lat0 = full$Nominal_lat0,
        Row          = as.integer(full$Nominal_lat0 - lattice$lat0_min + 1L),
        Col          = as.integer(full$Nominal_lon0 - lattice$lon0_min + 1L),
        Area_km2     = full$Area_km2,
        Area_frac    = full$Area_frac,
        stringsAsFactors = FALSE
    )
    regions <- list(breaks = as.numeric(region_breaks),
                    labels = as.character(region_labels))
    cells <- assign_regions(cells, regions, verbose)
    bbox <- c(xmin = min(full$xmin), ymin = min(full$ymin),
              xmax = max(full$xmax), ymax = max(full$ymax))
    geom <- NULL
    if (isTRUE(geometry)) {
        gg <- iccat_geometry()
        geom <- gg[match(cells$Cell_ID, gg$Cell_ID), ]
        rownames(geom) <- NULL
    }
    meta <- c(g$meta[c("source", "layer_grid", "crs", "epsg")],
              list(layer_stock = g$stocks$layer[g$stocks$stock_code ==
                                                    stock_code],
                   stock_code = stock_code, bbox = bbox,
                   n_cells = nrow(cells),
                   n_invalid_fixed = g$meta$n_invalid_fixed,
                   built_on = g$meta$built_on, constructor = "iccat"))
    dom <- structure(list(cells = cells, geometry = geom, lattice = lattice,
                          stock = NULL, meta = meta, regions = regions),
                     class = "om_domain")
    om_msg(verbose, "  domain ", stock_code, ": ", nrow(cells),
           " cells | lattice ", lattice$n_row, " x ", lattice$n_col)
    check_spatial_domain(dom)
    dom
}

#' Cell polygons of the bundled ICCAT grid
#'
#' Polygons of the 10051 cells (clipped by the coastline and slightly
#' simplified to keep the package small) used for maps.
#'
#' @return An `sf` object with `Cell_ID` and the geometry.
#' @export
iccat_geometry <- function() {
    if (is.null(.om_cache$geometry)) {
        f <- system.file("extdata", "iccat_geometry.rds", package = "pelagicOM")
        if (!nzchar(f)) stop("bundled ICCAT geometry not found")
        .om_cache$geometry <- readRDS(f)
    }
    .om_cache$geometry
}

########################################################################
######@> GeoPackage reader (Experimento 02 build_spatial_domain)...

#' Inspect a GeoPackage
#'
#' Lists the layers of a GeoPackage and, for the requested layers,
#' reports CRS, extent, fields, number of features and geometric
#' validity. Read only.
#'
#' @param path Path to the `.gpkg`.
#' @param layers Layer names to describe in detail.
#' @param verbose Print the report.
#' @return Invisible list with the information.
#' @export
inspect_geopackage <- function(path, layers = NULL, verbose = TRUE) {
    stopifnot(file.exists(path))
    lyr <- sf::st_layers(path)
    out <- list(layers = data.frame(name = lyr$name,
                                    geomtype = sapply(lyr$geomtype, `[`, 1),
                                    features = lyr$features,
                                    fields = lyr$fields,
                                    stringsAsFactors = FALSE))
    if (verbose) {
        message("GeoPackage: ", path)
        message("  ", nrow(out$layers), " layers")
    }
    for (ln in layers %||% character(0)) {
        if (!ln %in% lyr$name)
            stop("inspect_geopackage(): layer '", ln, "' does not exist")
        x <- sf::st_read(path, layer = ln, quiet = TRUE)
        info <- list(
            n        = nrow(x),
            geomtype = as.character(unique(sf::st_geometry_type(x))),
            crs      = sf::st_crs(x)$input,
            epsg     = sf::st_crs(x)$epsg,
            bbox     = sf::st_bbox(x),
            fields   = setdiff(names(x), attr(x, "sf_column")),
            n_invalid = sum(!sf::st_is_valid(x)),
            n_empty  = sum(sf::st_is_empty(x))
        )
        out[[ln]] <- info
        if (verbose) {
            message("  layer '", ln, "': ", info$n, " features, ",
                    paste(info$geomtype, collapse = "/"), ", CRS ",
                    info$crs, " (EPSG:", info$epsg, ")")
            message("    fields: ", paste(info$fields, collapse = ", "))
            message("    invalid geometries: ", info$n_invalid,
                    " | empty: ", info$n_empty)
        }
    }
    invisible(out)
}

#' Spatial domain from an ICCAT-like GeoPackage
#'
#' Reads a grid layer and a stock-area layer, keeps the grid cells that
#' belong to the stock area, repairs invalid geometries, computes the
#' geodesic area of each cell on the WGS84 ellipsoid with `lwgeom`
#' ([geodesic_area_km2()]), derives the integer lattice indices used by the
#' random fields and classifies cells into latitudinal regions. This is the
#' function used to build the domain of Experimento 02 from
#' `ICCAT_gis.gpkg` (the file is never written): with the defaults it
#' returns exactly the cells, lattice and polygons of that domain.
#'
#' @param path Path to the GeoPackage.
#' @param layer_grid,layer_stock Layer names of the 1x1 grid and of the
#'   stock areas.
#' @param stock_code Value of the `CODE` field that identifies the stock.
#' @param id_field,lon_field,lat_field Fields of the grid layer with the
#'   permanent cell identifier and its representative point.
#' @param selection Rule that assigns cells to the stock area:
#'   `"intersects"` (any contact; rule of Experimento 02, adequate when the
#'   stock area is the whole Convention area, as BET-A) or
#'   `"point_on_surface"` (a point on the cell surface lies inside the stock
#'   polygon; avoids the cells that only touch the boundary of a smaller
#'   stock area, and gives the same cells as [om_domain_iccat()]).
#' @inheritParams om_domain_iccat
#' @return An object of class `om_domain` (with geometry and stock
#'   polygon).
#' @export
om_domain_from_gpkg <- function(path, layer_grid = "grids_01x01",
                                layer_stock = "bigeye_tuna_stock_areas",
                                stock_code = "BET-A", id_field = "CODE",
                                lon_field = "CENTER_LON",
                                lat_field = "CENTER_LAT",
                                region_breaks = c(-20, 20),
                                region_labels = c("R01", "R02", "R03"),
                                selection = c("intersects",
                                              "point_on_surface"),
                                verbose = TRUE) {
    selection <- match.arg(selection)
    stopifnot(file.exists(path))

    ###@> Planar geometry: faster topological tests, sufficient on a
    ###@> regular lon/lat grid...
    s2_old <- sf::sf_use_s2()
    on.exit(suppressMessages(sf::sf_use_s2(s2_old)), add = TRUE)
    suppressMessages(sf::sf_use_s2(FALSE))

    om_msg(verbose, "  reading layers '", layer_grid, "' and '",
           layer_stock, "'")
    grid  <- sf::st_read(path, layer = layer_grid,  quiet = TRUE)
    stock <- sf::st_read(path, layer = layer_stock, quiet = TRUE)

    for (v in c(id_field, lon_field, lat_field))
        if (!v %in% names(grid))
            stop("om_domain_from_gpkg(): field '", v,
                 "' not found in layer ", layer_grid)
    if (!"CODE" %in% names(stock))
        stop("om_domain_from_gpkg(): field CODE not found in layer ",
             layer_stock)
    stock <- stock[stock$CODE == stock_code, ]
    if (nrow(stock) != 1)
        stop("om_domain_from_gpkg(): expected 1 feature with CODE = '",
             stock_code, "', found ", nrow(stock))
    if (sf::st_crs(grid) != sf::st_crs(stock))
        stop("om_domain_from_gpkg(): grid and stock have different CRS")
    if (is.na(sf::st_crs(grid)$epsg) || sf::st_crs(grid)$epsg != 4326)
        warning("grid CRS is not EPSG:4326; check the file")
    if (any(duplicated(grid[[id_field]])))
        stop("om_domain_from_gpkg(): identifier '", id_field,
             "' is not unique")

    n_inv <- sum(!sf::st_is_valid(grid))
    if (n_inv > 0) {
        om_msg(verbose, "  repairing ", n_inv, " invalid grid geometries")
        grid <- sf::st_make_valid(grid)
    }
    if (!all(sf::st_is_valid(stock))) stock <- sf::st_make_valid(stock)

    om_msg(verbose, "  selecting cells of ", stock_code, " (", selection, ")")
    inter <- cells_in_stock(grid, stock, selection)
    if (!any(inter))
        stop("om_domain_from_gpkg(): no cell belongs to the stock area")
    grid <- grid[inter, ]

    ###@> Geodesic area (km2) on the WGS84 ellipsoid (lwgeom): coastal
    ###@> cells and high-latitude cells are smaller, and biomass must be
    ###@> density x area...
    area_km2 <- geodesic_area_km2(grid)

    bb <- do.call(rbind, lapply(sf::st_geometry(grid),
                                function(g) as.numeric(sf::st_bbox(g))))
    lon0 <- floor(bb[, 1] + 1e-9)
    lat0 <- floor(bb[, 2] + 1e-9)
    if (any(duplicated(cbind(lon0, lat0))))
        stop("om_domain_from_gpkg(): duplicated nominal cells")
    lattice <- lattice_from_cells(lon0, lat0)

    area_nom <- geodesic_area_km2(nominal_cell_polygons(lon0, lat0,
                                                        sf::st_crs(grid)))

    cells <- data.frame(
        Cell_ID      = as.character(grid[[id_field]]),
        Longitude    = as.numeric(grid[[lon_field]]),
        Latitude     = as.numeric(grid[[lat_field]]),
        Nominal_lon0 = lon0,
        Nominal_lat0 = lat0,
        Row          = as.integer(lat0 - lattice$lat0_min + 1L),
        Col          = as.integer(lon0 - lattice$lon0_min + 1L),
        Area_km2     = area_km2,
        Area_frac    = area_km2 / area_nom,
        stringsAsFactors = FALSE
    )
    regions <- list(breaks = as.numeric(region_breaks),
                    labels = as.character(region_labels))
    cells <- assign_regions(cells, regions, verbose)

    geometry <- grid[, id_field]
    names(geometry)[names(geometry) == id_field] <- "Cell_ID"
    geometry$Cell_ID <- as.character(geometry$Cell_ID)

    meta <- list(
        source      = path,
        layer_grid  = layer_grid,
        layer_stock = layer_stock,
        stock_code  = stock_code,
        crs         = sf::st_crs(grid)$input,
        epsg        = sf::st_crs(grid)$epsg,
        bbox        = sf::st_bbox(grid),
        n_cells     = nrow(cells),
        n_invalid_fixed = n_inv,
        selection   = selection,
        area_method = "lwgeom::st_geod_area (WGS84 ellipsoid)",
        built_on    = format(Sys.time(), "%Y-%m-%d %H:%M:%S"),
        constructor = "gpkg"
    )
    om_msg(verbose, "  domain: ", nrow(cells), " cells | lattice ",
           lattice$n_row, " x ", lattice$n_col)
    dom <- structure(list(cells = cells, geometry = geometry,
                          lattice = lattice, stock = stock, meta = meta,
                          regions = regions),
                     class = "om_domain")
    check_spatial_domain(dom)
    dom
}

########################################################################
######@> Synthetic grid...

#' Synthetic rectangular domain
#'
#' Builds a regular 1x1 degree domain covering a longitude x latitude
#' box, optionally without some cells (e.g. land). Cell areas are geodesic
#' on the WGS84 ellipsoid ([geodesic_area_km2()]), computed as for the ICCAT
#' grid, so an open-ocean cell has the same area in both domains. Useful
#' for tests, teaching and for oceans other than the Atlantic when no GIS
#' grid is at hand.
#'
#' @param lon,lat Ranges (degrees) of the box; the limits are rounded
#'   outwards to whole degrees.
#' @param exclude Optional function `f(lon, lat)` of the cell centres
#'   returning `TRUE` for cells to drop.
#' @inheritParams om_domain_iccat
#' @return An object of class `om_domain`.
#' @examples
#' dom <- om_domain_grid(lon = c(-40, 0), lat = c(-30, 30), geometry = FALSE)
#' dom
#' @export
om_domain_grid <- function(lon = c(-60, 10), lat = c(-40, 40),
                           exclude = NULL, region_breaks = c(-20, 20),
                           region_labels = c("R01", "R02", "R03"),
                           geometry = TRUE,
                           verbose = TRUE) {
    lo <- floor(min(lon)):(ceiling(max(lon)) - 1)
    la <- floor(min(lat)):(ceiling(max(lat)) - 1)
    g <- expand.grid(lon0 = lo, lat0 = la)
    g$lon <- g$lon0 + 0.5; g$lat <- g$lat0 + 0.5
    if (is.function(exclude)) g <- g[!exclude(g$lon, g$lat), ]
    if (!nrow(g)) stop("om_domain_grid(): no cells left")
    polys <- nominal_cell_polygons(g$lon0, g$lat0)
    area <- geodesic_area_km2(polys)
    lattice <- lattice_from_cells(as.numeric(g$lon0), as.numeric(g$lat0))
    cells <- data.frame(
        Cell_ID      = sprintf("G%+04d%+03d", g$lon0, g$lat0),
        Longitude    = g$lon, Latitude = g$lat,
        Nominal_lon0 = as.numeric(g$lon0), Nominal_lat0 = as.numeric(g$lat0),
        Row = as.integer(g$lat0 - lattice$lat0_min + 1L),
        Col = as.integer(g$lon0 - lattice$lon0_min + 1L),
        Area_km2 = area, Area_frac = 1, stringsAsFactors = FALSE)
    rownames(cells) <- NULL
    regions <- list(breaks = as.numeric(region_breaks),
                    labels = as.character(region_labels))
    cells <- assign_regions(cells, regions, verbose)
    geom <- if (isTRUE(geometry))
        sf::st_sf(Cell_ID = cells$Cell_ID, geom = polys) else NULL
    meta <- list(source = "synthetic", stock_code = "GRID",
                 area_method = "lwgeom::st_geod_area (WGS84 ellipsoid)",
                 bbox = c(xmin = min(lo), ymin = min(la),
                          xmax = max(lo) + 1, ymax = max(la) + 1),
                 n_cells = nrow(cells),
                 built_on = format(Sys.time(), "%Y-%m-%d %H:%M:%S"),
                 constructor = "grid")
    dom <- structure(list(cells = cells, geometry = geom, lattice = lattice,
                          stock = NULL, meta = meta, regions = regions),
                     class = "om_domain")
    om_msg(verbose, "  synthetic domain: ", nrow(cells), " cells | lattice ",
           lattice$n_row, " x ", lattice$n_col)
    check_spatial_domain(dom)
    dom
}

########################################################################
######@> Dispatcher and checks...

#' Spatial domain from a biomass configuration
#'
#' Builds the domain described by `cfg$spatial`: the bundled ICCAT grid
#' (`source = "iccat"`) or a GeoPackage (`source = "gpkg"`, path in
#' `cfg$spatial$gpkg`).
#'
#' @param cfg Biomass configuration ([om_biomass_config()]).
#' @inheritParams om_domain_iccat
#' @return An object of class `om_domain`.
#' @export
om_domain <- function(cfg, geometry = TRUE,
                      verbose = TRUE) {
    cfg <- normalize_biomass_config(cfg)
    sp <- cfg$spatial
    switch(sp$source,
           iccat = om_domain_iccat(sp$stock_code, sp$region_breaks,
                                   sp$region_labels, geometry = geometry,
                                   verbose = verbose),
           gpkg = {
               if (is.null(sp$gpkg) || !file.exists(sp$gpkg))
                   stop("cfg$spatial$gpkg must point to an existing ",
                        "GeoPackage when source = 'gpkg'")
               om_domain_from_gpkg(sp$gpkg, sp$layer_grid, sp$layer_stock,
                                   sp$stock_code, sp$id_field, sp$lon_field,
                                   sp$lat_field, sp$region_breaks,
                                   sp$region_labels,
                                   selection = sp$selection %||% "intersects",
                                   verbose = verbose)
           },
           stop("unknown spatial$source '", sp$source, "'"))
}

######@> Structural checks of a domain (stop on failure)...
check_spatial_domain <- function(dom) {
    cl <- dom$cells
    stopifnot(!any(duplicated(cl$Cell_ID)),
              !any(is.na(cl$Longitude)), !any(is.na(cl$Latitude)),
              all(cl$Area_km2 > 0), all(is.finite(cl$Area_km2)),
              all(cl$Row >= 1), all(cl$Row <= dom$lattice$n_row),
              all(cl$Col >= 1), all(cl$Col <= dom$lattice$n_col),
              !any(duplicated(cl[, c("Row", "Col")])))
    if (!is.null(dom$geometry))
        stopifnot(nrow(dom$geometry) == nrow(cl),
                  identical(dom$geometry$Cell_ID, cl$Cell_ID))
    rg <- dom$regions
    if (!is.null(rg))
        stopifnot(identical(as.character(cl$Region),
                            as.character(classify_regions(cl$Latitude,
                                                          rg$breaks,
                                                          rg$labels))))
    invisible(TRUE)
}

######@> Domains saved by Experimento_02 have no 'regions' element...
domain_regions <- function(dom, cfg = NULL) {
    if (!is.null(dom$regions)) return(dom$regions)
    if (!is.null(cfg)) return(region_spec(normalize_biomass_config(cfg)$spatial))
    list(breaks = c(-20, 20), labels = levels(dom$cells$Region))
}

#' @export
print.om_domain <- function(x, ...) {
    cl <- x$cells
    cat("<pelagicOM spatial domain> ", x$meta$stock_code %||% "", " (",
        x$meta$constructor %||% "?", ")\n", sep = "")
    cat(sprintf("  %d cells | lattice %d x %d | lon %.1f to %.1f | lat %.1f to %.1f\n",
                nrow(cl), as.integer(x$lattice$n_row),
                as.integer(x$lattice$n_col), min(cl$Longitude),
                max(cl$Longitude), min(cl$Latitude), max(cl$Latitude)))
    tab <- table(cl$Region)
    cat("  regions:", paste(sprintf("%s = %d", names(tab), tab),
                            collapse = ", "), "\n")
    cat("  total area:", format(round(sum(cl$Area_km2)), big.mark = ","),
        "km2 | geometry:", if (is.null(x$geometry)) "no" else "yes", "\n")
    invisible(x)
}
