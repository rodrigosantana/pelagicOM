# Observation process

Builds the OBSERVED data set from the true fishery data under one
observation profile of `cfg$observation`. Every profile starts from the
same seed (`seeds$observation`), so that profiles differ only by their
parameters.

## Usage

``` r
apply_observation_process(td, profile, cfg, truth)
```

## Arguments

- td:

  True fishery data (`$data` of an `om_fishery` object).

- profile:

  Name of the observation profile (e.g. `"complete"`, `"temporal"`).

- cfg:

  Fishery configuration.

- truth:

  Population truth
  ([`fishery_truth()`](https://rodrigosantana.github.io/pelagicOM/reference/fishery_truth.md)).

## Value

Data frame with the observable variables (Year, Quarter, Fleet,
VesselID, TripID, SetID, Hooks, HooksBetweenFloats, FishingStrategy,
Region, Longitude, Latitude, Cell_ID, Catch and Catch\_), with attribute
`"mechanisms"` (counts of each mechanism).
