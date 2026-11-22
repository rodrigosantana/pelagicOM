# Synthetic rectangular domain

Builds a regular 1x1 degree domain covering a longitude x latitude box,
optionally without some cells (e.g. land). Cell areas are geodesic on
the WGS84 ellipsoid
([`geodesic_area_km2()`](https://rodrigosantana.github.io/pelagicOM/reference/geodesic_area_km2.md)),
computed as for the ICCAT grid, so an open-ocean cell has the same area
in both domains. Useful for tests, teaching and for oceans other than
the Atlantic when no GIS grid is at hand.

## Usage

``` r
om_domain_grid(
  lon = c(-60, 10),
  lat = c(-40, 40),
  exclude = NULL,
  region_breaks = c(-20, 20),
  region_labels = c("R01", "R02", "R03"),
  geometry = TRUE,
  verbose = TRUE
)
```

## Arguments

- lon, lat:

  Ranges (degrees) of the box; the limits are rounded outwards to whole
  degrees.

- exclude:

  Optional function `f(lon, lat)` of the cell centres returning `TRUE`
  for cells to drop.

- region_breaks, region_labels:

  Latitudinal regions (see
  [`classify_regions()`](https://rodrigosantana.github.io/pelagicOM/reference/classify_regions.md)).

- geometry:

  Attach the cell polygons (`sf`), used by the maps.

- verbose:

  Print progress messages.

## Value

An object of class `om_domain`.

## Examples

``` r
dom <- om_domain_grid(lon = c(-40, 0), lat = c(-30, 30), geometry = FALSE)
#>   synthetic domain: 2400 cells | lattice 60 x 40
dom
#> <pelagicOM spatial domain> GRID (grid)
#>   2400 cells | lattice 60 x 40 | lon -39.5 to -0.5 | lat -29.5 to 29.5
#>   regions: R01 = 400, R02 = 1600, R03 = 400 
#>   total area: 28,242,379 km2 | geometry: no 
```
