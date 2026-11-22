# Automatic checks of the biomass truth

Structural checks (stop on failure): identities \\\sum_s p = 1\\ and
\\\sum_s B = B\_{total}\\, no NA / Inf / negatives, unique Year x Cell,
temporal and spatial limits, coherent regions. Pattern checks (warning):
with three or more regions, the central region has the highest mean
density in the first year, and an active poleward redistribution
increases the share of the outer regions and decreases the central one.

## Usage

``` r
check_simulation(sim, tol = 1e-08, verbose = TRUE)

check_reproducibility(cfg = om_biomass_config(), domain = NULL)
```

## Arguments

- sim:

  An `om_biomass` object.

- tol:

  Relative tolerance of the identities.

- verbose:

  Print a summary.

- cfg:

  Biomass configuration.

- domain:

  Optional domain (see
  [`simulate_biomass()`](https://rodrigosantana.github.io/pelagicOM/reference/simulate_biomass.md)).

## Value

Invisible list with the results.

## Functions

- `check_reproducibility()`: Runs the simulation twice with the same
  configuration and compares the results bit by bit.
