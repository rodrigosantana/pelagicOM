# Tune a configuration

Recursively replaces elements of a biomass or fishery configuration.
Named lists are merged level by level, so only the elements given are
changed; any other value (vectors, unnamed lists such as `hotspots`,
`events`, `scenarios` or observation periods) replaces the original one
entirely. `NULL` removes an element (e.g. a fleet). New names are
accepted (e.g. a new fleet or companion species) and reported with a
message, which also catches typos.

## Usage

``` r
om_config_update(cfg, ..., quiet = FALSE)
```

## Arguments

- cfg:

  A configuration from
  [`om_biomass_config()`](https://rodrigosantana.github.io/pelagicOM/reference/om_biomass_config.md)
  or
  [`om_fishery_config()`](https://rodrigosantana.github.io/pelagicOM/reference/om_fishery_config.md).

- ...:

  Named sections with the new values, or a single named list.

- quiet:

  If `TRUE`, does not report new elements.

## Value

The updated configuration (not validated; the simulation functions
validate it).

## Examples

``` r
cfg <- om_biomass_config()
cfg <- om_config_update(cfg,
    population = list(r = 0.45, decline = list(u_peak = 0.30)),
    habitat = list(hotspots = list(
        list(lon = -20, lat = 0, sd_lon = 8, sd_lat = 4, amp = 1.2))))
cfg$population$decline
#> $start
#> [1] 1965
#> 
#> $end
#> [1] 1995
#> 
#> $u_peak
#> [1] 0.3
#> 
length(cfg$habitat$hotspots)
#> [1] 1
```
