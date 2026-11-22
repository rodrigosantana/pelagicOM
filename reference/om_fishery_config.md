# Fishery (Part II) configuration

Returns the full list of parameters of the pelagic longline fishery
generator: fleets, vessels and their careers, trips, sets, effort
(hooks), gear (hooks between floats, HBF), latent fishing strategies,
spatial behaviour of the fleets (preferential sampling, fidelity,
expansion), the components of log catchability, the catch process
(Tweedie or delta-lognormal), companion species, observation profiles
and the scenario data sets. The `"BET_ICCAT"` preset is the
configuration of Experimento 02 (five fleets A-E, target BET, companions
YFT, ALB, SWO, BSH, eight scenarios).

## Usage

``` r
om_fishery_config(preset = "BET_ICCAT", ...)

validate_fishery_config(cfg)
```

## Arguments

- preset:

  Name of a preset (see
  [`om_presets()`](https://rodrigosantana.github.io/pelagicOM/reference/om_presets.md)).

- ...:

  Optional named sections that override the preset, passed to
  [`om_config_update()`](https://rodrigosantana.github.io/pelagicOM/reference/om_config_update.md)
  (e.g. `population = list(r = 0.4)`).

- cfg:

  A fishery configuration.

## Value

A list of class `om_fishery_config`.

## Details

Every stochastic component has its own seed (`reproducibility$seeds`),
so that changing one process does not reshuffle the draws of the others.

## Functions

- `validate_fishery_config()`: Checks the internal coherence of a
  fishery configuration. Region names are checked later, against the
  biomass truth, by
  [`simulate_fishery()`](https://rodrigosantana.github.io/pelagicOM/reference/simulate_fishery.md).

## See also

[`om_biomass_config()`](https://rodrigosantana.github.io/pelagicOM/reference/om_biomass_config.md),
[`simulate_fishery()`](https://rodrigosantana.github.io/pelagicOM/reference/simulate_fishery.md),
[`generate_scenarios()`](https://rodrigosantana.github.io/pelagicOM/reference/generate_scenarios.md).

## Examples

``` r
fcfg <- om_fishery_config("BET_ICCAT")
names(fcfg$fleets)
#> [1] "A" "B" "C" "D" "E"
## halve the size of fleet A and switch off creep
fcfg2 <- om_fishery_config("BET_ICCAT",
                           fleets = list(A = list(n_vessels = 20)),
                           catchability = list(creep_enabled = FALSE))
fcfg2$fleets$A$n_vessels
#> [1] 20
```
