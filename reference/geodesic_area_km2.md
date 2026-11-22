# Geodesic area of polygons

Area of polygons in geographic coordinates on the WGS84 ellipsoid,
computed by
[`lwgeom::st_geod_area()`](https://r-spatial.github.io/lwgeom/reference/geod.html).
This is the computation behind the cell areas of the ICCAT grid in
Experimento 02
([`sf::st_area()`](https://r-spatial.github.io/sf/reference/geos_measures.html)
with spherical geometry switched off delegates to `lwgeom`), and it is
used by every domain constructor of the package.

## Usage

``` r
geodesic_area_km2(x)
```

## Arguments

- x:

  An `sf` or `sfc` object with polygons in longitude / latitude.

## Value

Numeric vector of areas in km2.

## Examples

``` r
cell <- sf::st_sfc(sf::st_polygon(list(cbind(c(0, 1, 1, 0, 0),
                                             c(0, 0, 1, 1, 0)))),
                   crs = 4326)
geodesic_area_km2(cell)   # 1x1 degree cell at the equator
#> [1] 12308.78
```
