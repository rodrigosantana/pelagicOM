# Spatial domain from an ICCAT-like GeoPackage

Reads a grid layer and a stock-area layer, keeps the grid cells that
belong to the stock area, repairs invalid geometries, computes the
geodesic area of each cell on the WGS84 ellipsoid with `lwgeom`
([`geodesic_area_km2()`](https://rodrigosantana.github.io/pelagicOM/reference/geodesic_area_km2.md)),
derives the integer lattice indices used by the random fields and
classifies cells into latitudinal regions. This is the function used to
build the domain of Experimento 02 from `ICCAT_gis.gpkg` (the file is
never written): with the defaults it returns exactly the cells, lattice
and polygons of that domain.

## Usage

``` r
om_domain_from_gpkg(
  path,
  layer_grid = "grids_01x01",
  layer_stock = "bigeye_tuna_stock_areas",
  stock_code = "BET-A",
  id_field = "CODE",
  lon_field = "CENTER_LON",
  lat_field = "CENTER_LAT",
  region_breaks = c(-20, 20),
  region_labels = c("R01", "R02", "R03"),
  selection = c("intersects", "point_on_surface"),
  verbose = TRUE
)
```

## Arguments

- path:

  Path to the GeoPackage.

- layer_grid, layer_stock:

  Layer names of the 1x1 grid and of the stock areas.

- stock_code:

  Value of the `CODE` field that identifies the stock.

- id_field, lon_field, lat_field:

  Fields of the grid layer with the permanent cell identifier and its
  representative point.

- region_breaks, region_labels:

  Latitudinal regions (see
  [`classify_regions()`](https://rodrigosantana.github.io/pelagicOM/reference/classify_regions.md)).

- selection:

  Rule that assigns cells to the stock area: `"intersects"` (any
  contact; rule of Experimento 02, adequate when the stock area is the
  whole Convention area, as BET-A) or `"point_on_surface"` (a point on
  the cell surface lies inside the stock polygon; avoids the cells that
  only touch the boundary of a smaller stock area, and gives the same
  cells as
  [`om_domain_iccat()`](https://rodrigosantana.github.io/pelagicOM/reference/om_domain_iccat.md)).

- verbose:

  Print progress messages.

## Value

An object of class `om_domain` (with geometry and stock polygon).
