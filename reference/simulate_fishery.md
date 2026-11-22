# Simulate the longline fishery on top of the biomass truth

Generates set-by-set pelagic longline operations (fleets, vessels with
careers and turnover, trips, sets, location by preferential sampling and
fidelity, latent fishing strategy, hooks and hooks between floats,
catchability components, Tweedie catches of the target species and
catches of companion species) with the COMPLETE truth of the fishing
process. Observed data sets are derived afterwards with
[`generate_scenarios()`](https://rodrigosantana.github.io/pelagicOM/reference/generate_scenarios.md).

## Usage

``` r
simulate_fishery(biomass, cfg = om_fishery_config(), verbose = TRUE)
```

## Arguments

- biomass:

  An `om_biomass` object
  ([`simulate_biomass()`](https://rodrigosantana.github.io/pelagicOM/reference/simulate_biomass.md)),
  an `om_truth` object
  ([`fishery_truth()`](https://rodrigosantana.github.io/pelagicOM/reference/fishery_truth.md)),
  a list with `dom`, `pop` and `biomass`, or the path to an `.rds` file
  with such a list (e.g. the Experimento 02 file
  `biomass_true_base.rds`).

- cfg:

  Fishery configuration
  ([`om_fishery_config()`](https://rodrigosantana.github.io/pelagicOM/reference/om_fishery_config.md)).

- verbose:

  Print progress messages.

## Value

An object of class `om_fishery`, a list with `cfg`, `data` (true fishery
data, one row per set; observable columns first, then latent ones),
`fleets`, `vessels`, `vessel_years`, `trips`, `vessel_effects`, `truth`,
`biomass_source`, `observed_columns`, `latent_columns`.

## Details

With `om_fishery_config("BET_ICCAT")` on the BET biomass truth, `$data`
is identical, bit for bit, to `TRUE_FISHERY_DATA_base.rds` of
Experimento 02. The caller's random number stream is left untouched.

## See also

[`generate_scenarios()`](https://rodrigosantana.github.io/pelagicOM/reference/generate_scenarios.md),
[`check_fishery_truth()`](https://rodrigosantana.github.io/pelagicOM/reference/check_fishery_truth.md),
[`make_fishery_figures()`](https://rodrigosantana.github.io/pelagicOM/reference/fishery_figures.md),
[`om_write_fishery()`](https://rodrigosantana.github.io/pelagicOM/reference/om_write_fishery.md).

## Examples

``` r
# \donttest{
sim <- simulate_biomass(verbose = FALSE)
fcfg <- om_fishery_config("BET_ICCAT",
    fleets = list(A = list(n_vessels = 5), B = list(n_vessels = 5),
                  C = list(n_vessels = 5), D = list(n_vessels = 5),
                  E = list(n_vessels = 5)))
fish <- simulate_fishery(sim, fcfg, verbose = FALSE)
fish
#> <pelagicOM fishery truth> label 'base'
#>   147,990 sets | 12,851 trips | 100 vessels | 5 fleets | 1950-2025
#>   target catch: total 62,868 t | mean 0.425 t/set | zeros 51.2%
#>   sets by fleet x region:
#>    
#>       R01   R02   R03
#>   A  3808 29487     0
#>   B  1879 31079     0
#>   C  3627 25200     0
#>   D     0 25468  2313
#>   E     0 21077  4052
# }
```
