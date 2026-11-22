# Scenario data sets

Applies each observation profile once and derives the scenario data sets
of `cfg$scenarios` (regional filter, removed variables, observation
profile), with a metadata table describing each one. With the
`"BET_ICCAT"` preset these are the eight data sets of Experimento 02
(identical to `Simulacao_Pesca/outputs/datasets/*.rds`).

## Usage

``` r
generate_scenarios(fishery, verbose = TRUE)
```

## Arguments

- fishery:

  An `om_fishery` object
  ([`simulate_fishery()`](https://rodrigosantana.github.io/pelagicOM/reference/simulate_fishery.md)).

- verbose:

  Print one line per scenario.

## Value

A list of class `om_scenarios` with `datasets` (named list of data
frames), `metadata` (data frame) and `observed` (the full observed data
set of each profile).
