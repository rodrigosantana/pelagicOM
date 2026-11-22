# ICCAT stock areas available in the bundled grid

The package ships the 10051 cells of the official ICCAT 1x1 degree grid
(layer `grids_01x01` of the ICCAT GIS GeoPackage, cells clipped by the
coastline, geodesic area from `lwgeom`) together with the membership of
each cell in every stock area of the GeoPackage. The grid was built with
[`om_domain_from_gpkg()`](https://rodrigosantana.github.io/pelagicOM/reference/om_domain_from_gpkg.md)
(script `data-raw/build_iccat_grid.R`) and is identical to the domain of
Experimento 02. A cell belongs to a stock area when a point on its
surface lies inside the stock polygon
(`selection = "point_on_surface"`); for BET-A (identical to the ICCAT
Convention area) membership is the intersection used in Experimento 02
(all cells).

## Usage

``` r
iccat_stocks()
```

## Value

Data frame with `stock_code`, `layer`, `name` and `n_cells`.

## Examples

``` r
iccat_stocks()
#>    stock_code                             layer
#> 1       ALB-M         albacore_tuna_stock_areas
#> 2       ALB-N         albacore_tuna_stock_areas
#> 3       ALB-S         albacore_tuna_stock_areas
#> 4       BFT-E atlantic_bluefin_tuna_stock_areas
#> 5       BFT-W atlantic_bluefin_tuna_stock_areas
#> 6       SAI-E     atlantic_sailfish_stock_areas
#> 7       SAI-W     atlantic_sailfish_stock_areas
#> 8       WHM-A atlantic_white_marlin_stock_areas
#> 9       BET-A           bigeye_tuna_stock_areas
#> 10      BUM-A           blue_marlin_stock_areas
#> 11      SPF-E    longbill_spearfish_stock_areas
#> 12      SPF-W    longbill_spearfish_stock_areas
#> 13      SKJ-E         skipjack_tuna_stock_areas
#> 14      SKJ-W         skipjack_tuna_stock_areas
#> 15      SWO-M             swordfish_stock_areas
#> 16      SWO-N             swordfish_stock_areas
#> 17      SWO-S             swordfish_stock_areas
#> 18      YFT-A        yellowfin_tuna_stock_areas
#> 19      AT-NE         other_species_stock_areas
#> 20      AT-NW         other_species_stock_areas
#> 21      AT-SE         other_species_stock_areas
#> 22      AT-SW         other_species_stock_areas
#> 23         MD         other_species_stock_areas
#> 24      ICCAT                 entire_iccat_area
#>                                      name n_cells        selection
#> 1          Albacore tuna stock area ALB-M     431 point_on_surface
#> 2          Albacore tuna stock area ALB-N    5070 point_on_surface
#> 3          Albacore tuna stock area ALB-S    4550 point_on_surface
#> 4  Atlantic bluefin tuna stock area BFT-E    5853 point_on_surface
#> 5  Atlantic bluefin tuna stock area BFT-W    4198 point_on_surface
#> 6      Atlantic sailfish stock area SAI-E    5308 point_on_surface
#> 7      Atlantic sailfish stock area SAI-W    4743 point_on_surface
#> 8  Atlantic white marlin stock area WHM-A   10051 point_on_surface
#> 9            Bigeye tuna stock area BET-A   10051       intersects
#> 10  Atlantic blue marlin stock area BUM-A   10051 point_on_surface
#> 11    Longbill spearfish stock area SPF-E    5308 point_on_surface
#> 12    Longbill spearfish stock area SPF-W    4743 point_on_surface
#> 13         Skipjack tuna stock area SKJ-E    5098 point_on_surface
#> 14         Skipjack tuna stock area SKJ-W    4952 point_on_surface
#> 15             Swordfish stock area SWO-M     431 point_on_surface
#> 16             Swordfish stock area SWO-N    5070 point_on_surface
#> 17             Swordfish stock area SWO-S    4550 point_on_surface
#> 18        Yellowfin tuna stock area YFT-A   10051 point_on_surface
#> 19                                  AT-NE    2454 point_on_surface
#> 20                                  AT-NW    2616 point_on_surface
#> 21                                  AT-SE    2423 point_on_surface
#> 22                                  AT-SW    2127 point_on_surface
#> 23                                     MD     431 point_on_surface
#> 24                  ICCAT convention area   10051 point_on_surface
```
