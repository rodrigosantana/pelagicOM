# Inspect a GeoPackage

Lists the layers of a GeoPackage and, for the requested layers, reports
CRS, extent, fields, number of features and geometric validity. Read
only.

## Usage

``` r
inspect_geopackage(path, layers = NULL, verbose = TRUE)
```

## Arguments

- path:

  Path to the `.gpkg`.

- layers:

  Layer names to describe in detail.

- verbose:

  Print the report.

## Value

Invisible list with the information.
