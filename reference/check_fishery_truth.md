# Structural checks of the fishery truth and of observed data sets

`check_fishery_truth()` stops if any structural property of the true
fishery data is violated (non-negative catches, ranges of hooks and HBF,
identifier hierarchy, cells and coordinates from the biomass truth,
regional access of each fleet, vessel active in the year of the set,
identity E[C](https://rdrr.io/r/stats/zC.html) = q x Hooks x D).
`check_observed_dataset()` checks an observed data set.

## Usage

``` r
check_fishery_truth(td, truth, vessels, cfg, verbose = TRUE)

check_observed_dataset(obs, cfg, name = "", truth = NULL)
```

## Arguments

- td:

  True fishery data.

- truth:

  Population truth
  ([`fishery_truth()`](https://rodrigosantana.github.io/pelagicOM/reference/fishery_truth.md)).

- vessels:

  Vessel table of the `om_fishery` object.

- cfg:

  Fishery configuration.

- verbose:

  Print a message when all checks pass.

- obs:

  Observed data set.

- name:

  Name of the data set (messages).

## Value

Invisible `TRUE`.
