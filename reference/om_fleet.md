# Specification of a fleet

Helper that returns the list describing one fleet, with the fields used
by
[`om_fishery_config()`](https://rodrigosantana.github.io/pelagicOM/reference/om_fishery_config.md).
Defaults are those of fleet A of Experimento 02. Assign the result to
`cfg$fleets$<name>` (or pass it through
[`om_config_update()`](https://rodrigosantana.github.io/pelagicOM/reference/om_config_update.md)).

## Usage

``` r
om_fleet(
  n_vessels = 45,
  year_start = 1950,
  year_end = 2025,
  regions = c("R01", "R02"),
  core_lon = -45,
  core_lat = 12,
  core_sd = 20,
  quarter_weights = c(0.25, 0.3, 0.25, 0.2),
  hooks_median = c(`1950` = 1300, `1980` = 1900, `2025` = 2300),
  hbf_mult = 1,
  strategy_comp = c(S1 = 0.55, S2 = 0.3, S3 = 0.15),
  q_effect = 0
)
```

## Arguments

- n_vessels:

  Number of vessel slots kept active (turnover replaces retiring
  vessels).

- year_start, year_end:

  Period of activity.

- regions:

  Regions the fleet can fish in (labels of the domain).

- core_lon, core_lat, core_sd:

  Centre (degrees) and spread of the baseline spatial preference; cells
  are also made available from the centre outwards as the fleet expands.

- quarter_weights:

  Relative frequency of trips per quarter (4).

- hooks_median:

  Anchors (named by year) of the median hooks per set.

- hbf_mult:

  Multiplier of the hooks between floats of the fleet.

- strategy_comp:

  Composition of fishing strategies (sums to 1, names = strategy
  levels).

- q_effect:

  Fleet effect on log catchability.

## Value

A list.

## Examples

``` r
fcfg <- om_fishery_config()
fcfg$fleets$F <- om_fleet(n_vessels = 15, year_start = 1990,
                          regions = "R02", core_lon = -10, core_lat = 0)
names(fcfg$fleets)
#> [1] "A" "B" "C" "D" "E" "F"
```
