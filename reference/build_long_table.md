# Long table of the biomass truth

Table Year x Cell_ID with Year, Cell_ID, Longitude, Latitude, Region,
Area_km2, B_total (t), Spatial_weight (p, sums to 1 per year), Biomass
(t), Density (t/km2), Relative_biomass (biomass / temporal mean of the
cell) and Depletion (B_total / K). Rows are ordered by year and, within
year, by the order of the cells in the domain.

## Usage

``` r
build_long_table(sim)
```

## Arguments

- sim:

  An `om_biomass` object.

## Value

A data frame.
