# Population truth for the fishery generator

Validates the biomass truth and derives what the fishery needs: biomass
and density (t/km2) matrices (cells x years), cells, regions, lattice
and a lookup table of the nearest domain cell for every lattice cell
(used by the position error of the observation process so that observed
positions never fall outside the domain).

## Usage

``` r
fishery_truth(x, verbose = TRUE)
```

## Arguments

- x:

  An `om_biomass` object
  ([`simulate_biomass()`](https://rodrigosantana.github.io/pelagicOM/reference/simulate_biomass.md)),
  a list with `dom`, `pop` and `biomass`, or the path to an `.rds` file
  holding one.

- verbose:

  Print a summary.

## Value

An object of class `om_truth`.

## Details

Density, not biomass, enters the expected catch: the gear samples a
local volume, not the whole cell (coastal cells clipped by land hold
less biomass but not fewer fish per km2).
