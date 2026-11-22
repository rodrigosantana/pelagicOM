# Simulate the spatio-temporal biomass operating truth

Generates a completely known biomass trajectory for every year and cell
of the spatial domain: total biomass from a surplus-production model,
distributed in space by a static habitat (latitudinal envelope,
hotspots, gradient, persistent random field), a redistribution of the
envelope in time (e.g. poleward expansion) and spatio-temporal noise. No
fishing process is simulated here (see
[`simulate_fishery()`](https://rodrigosantana.github.io/pelagicOM/reference/simulate_fishery.md)).

## Usage

``` r
simulate_biomass(
  cfg = om_biomass_config(),
  domain = NULL,
  long_table = TRUE,
  verbose = TRUE
)
```

## Arguments

- cfg:

  Biomass configuration
  ([`om_biomass_config()`](https://rodrigosantana.github.io/pelagicOM/reference/om_biomass_config.md)).

- domain:

  Optional spatial domain
  ([`om_domain_iccat()`](https://rodrigosantana.github.io/pelagicOM/reference/om_domain_iccat.md),
  [`om_domain_grid()`](https://rodrigosantana.github.io/pelagicOM/reference/om_domain_grid.md),
  [`om_domain_from_gpkg()`](https://rodrigosantana.github.io/pelagicOM/reference/om_domain_from_gpkg.md)).
  By default it is built from `cfg$spatial`. Its regions take precedence
  over the ones in `cfg$spatial`.

- long_table:

  If `TRUE`, also builds the long table Year x Cell (`$table`), the main
  product of Experimento 02.

- verbose:

  Print progress messages.

## Value

An object of class `om_biomass`, a list with `cfg`, `dom` (domain),
`pop` (B_total and related series; attribute `"ref"` with reference
points), `base` (static components), `envelope`, `noise`, `logD`,
`weights` (p), `biomass` (B, cells x years, t), `envelope_params` and
`table`.

## Details

With `om_biomass_config("BET_ICCAT")` the result is identical, bit for
bit, to `Simulacao_Biomassa/outputs/data/biomass_true_base.rds` of
Experimento 02.

The caller's random number stream is left untouched: the simulation
seeds its own stream with `cfg$general$seed` and restores the previous
state on exit.

## See also

[`check_simulation()`](https://rodrigosantana.github.io/pelagicOM/reference/check_simulation.md),
[`regional_summary()`](https://rodrigosantana.github.io/pelagicOM/reference/biomass_summaries.md),
[`make_biomass_figures()`](https://rodrigosantana.github.io/pelagicOM/reference/biomass_figures.md),
[`om_write_biomass()`](https://rodrigosantana.github.io/pelagicOM/reference/om_write_biomass.md).

## Examples

``` r
# \donttest{
sim <- simulate_biomass(om_biomass_config(), verbose = FALSE)
sim
#> <pelagicOM biomass truth> label 'base' | seed 20261005
#>   10051 cells x 76 years (1950-2025) | stock area BET-A
#>   B_total: 950,000 t (1950) -> 318,101 t (2025) | B/K 0.95 -> 0.32 | Bmsy 5e+05 t
#>   regional share: R01 0.04 -> 0.14 | R02 0.93 -> 0.74 | R03 0.03 -> 0.13 
head(sim$pop)
#>   Year  B_total K_year    u   Surplus  Removal   Proc_error Depletion   B_Bmsy
#> 1 1950 950000.0  1e+06 0.02 14250.000 19000.00 -0.004677681 0.9500000 1.900000
#> 2 1951 943623.4  1e+06 0.02 15959.493 18872.47 -0.001722335 0.9436234 1.887247
#> 3 1952 978115.8  1e+06 0.02  6421.595 19562.32  0.038992708 0.9781158 1.956232
#> 4 1953 974045.8  1e+06 0.02  7584.180 19480.92  0.009356064 0.9740458 1.948092
#> 5 1954 910712.7  1e+06 0.02 24394.532 18214.25 -0.054941928 0.9107127 1.821425
#> 6 1955 918052.9  1e+06 0.02 22569.538 18361.06  0.001264269 0.9180529 1.836106
# }
```
