# Run the complete operating model

Simulates the biomass truth, the fishery and the scenario data sets in
one call and, if `dir` is given, writes every output with the folder
structure of Experimento 02 (`dir/Simulacao_Biomassa/outputs/...` and
`dir/Simulacao_Pesca/outputs/...`).

## Usage

``` r
om_run(
  preset = "BET_ICCAT",
  biomass_cfg = om_biomass_config(preset),
  fishery_cfg = om_fishery_config(preset),
  domain = NULL,
  scenarios = TRUE,
  dir = NULL,
  figures = TRUE,
  csv = TRUE,
  verbose = TRUE
)
```

## Arguments

- preset:

  Preset used for the default configurations.

- biomass_cfg, fishery_cfg:

  Configurations (default: the preset).

- domain:

  Optional spatial domain (see
  [`simulate_biomass()`](https://rodrigosantana.github.io/pelagicOM/reference/simulate_biomass.md)).

- scenarios:

  Generate the scenario data sets.

- dir:

  Output folder (`NULL`: nothing is written).

- figures, csv:

  Write figures / csv copies when `dir` is given.

- verbose:

  Print progress.

## Value

A list of class `om_run` with `biomass`, `fishery` and `scenarios`.

## Examples

``` r
if (FALSE) { # \dontrun{
run <- om_run("BET_ICCAT", dir = "Experimento_pelagicOM")
run$scenarios
} # }
```
