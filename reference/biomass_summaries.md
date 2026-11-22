# Summaries of the biomass truth

`regional_summary()`: biomass, share, area and mean density (t/km2) by
year and region. `centre_of_gravity()`: biomass-weighted mean
latitude/longitude, mean absolute latitude, hemispheric centres and
northern share. `latitude_profile()`: mean density by 1-degree latitude
band and year (Hovmoller diagram).

## Usage

``` r
regional_summary(sim)

centre_of_gravity(sim)

latitude_profile(sim)
```

## Arguments

- sim:

  An `om_biomass` object.

## Value

A data frame.
