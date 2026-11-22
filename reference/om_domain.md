# Spatial domain from a biomass configuration

Builds the domain described by `cfg$spatial`: the bundled ICCAT grid
(`source = "iccat"`) or a GeoPackage (`source = "gpkg"`, path in
`cfg$spatial$gpkg`).

## Usage

``` r
om_domain(cfg, geometry = TRUE, verbose = TRUE)
```

## Arguments

- cfg:

  Biomass configuration
  ([`om_biomass_config()`](https://rodrigosantana.github.io/pelagicOM/reference/om_biomass_config.md)).

- geometry:

  Attach the cell polygons (`sf`), used by the maps.

- verbose:

  Print progress messages.

## Value

An object of class `om_domain`.
