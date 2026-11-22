# Available presets

Lists the named configurations shipped with the package. Each preset
provides a biomass configuration
([`om_biomass_config()`](https://rodrigosantana.github.io/pelagicOM/reference/om_biomass_config.md))
and a fishery configuration
([`om_fishery_config()`](https://rodrigosantana.github.io/pelagicOM/reference/om_fishery_config.md)).

## Usage

``` r
om_presets()
```

## Value

A data frame with columns `preset`, `species`, `area`, `description`.

## Examples

``` r
om_presets()
#>      preset                      species
#> 1 BET_ICCAT Bigeye tuna (Thunnus obesus)
#>                                      area
#> 1 ICCAT BET-A stock area, 1x1 degree grid
#>                                                                                                                                                                                                                                          description
#> 1 Operating model of Experimento 02 (workshop tRFMO CPUE, 2026): Pella-Tomlinson biomass 1950-2025 with poleward redistribution, five longline fleets, target BET + YFT/ALB/SWO/BSH, eight observation scenarios. Reproduces the experiment exactly.
```
