# Spatial domain on the ICCAT 1x1 grid

Builds the spatial domain of an ICCAT stock area from the grid bundled
with the package (no GIS file needed). For `stock_code = "BET-A"` the
result is identical to the domain of Experimento 02.

## Usage

``` r
om_domain_iccat(
  stock_code = "BET-A",
  region_breaks = c(-20, 20),
  region_labels = c("R01", "R02", "R03"),
  geometry = TRUE,
  verbose = TRUE
)
```

## Arguments

- stock_code:

  Stock area code (see
  [`iccat_stocks()`](https://rodrigosantana.github.io/pelagicOM/reference/iccat_stocks.md)).

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
dom <- om_domain_iccat("BET-A", geometry = FALSE)
#>   domain BET-A: 10051 cells | lattice 130 x 140
dom
#> <pelagicOM spatial domain> BET-A (iccat)
#>   10051 cells | lattice 130 x 140 | lon -97.4 to 41.3 | lat -59.5 to 69.9
#>   regions: R01 = 4519, R02 = 2368, R03 = 3164 
#>   total area: 88,756,675 km2 | geometry: no 
dom_alb <- om_domain_iccat("ALB-N", region_breaks = 30,
                           region_labels = c("North", "South"),
                           geometry = FALSE)
#>   domain ALB-N: 5070 cells | lattice 65 x 129
table(dom_alb$cells$Region)
#> 
#> North South 
#>  3250  1820 
```
