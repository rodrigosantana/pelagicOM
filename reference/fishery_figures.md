# Figures of the fishery truth

`fishery_figures()` returns the twelve diagnostic figures of Experimento
02 as a named list of `ggplot` / `patchwork` objects;
`make_fishery_figures()` saves them as PNG files. The `fig_*` functions
build one figure each.

## Usage

``` r
fig_effort_time(fishery)

fig_effort_maps(fishery, years_sel = NULL)

fig_gear(fishery)

fig_strategy(fishery)

fig_catchability_time(fishery)

fig_catchability_factors(fishery)

fig_vessel_effects(fishery)

fig_catch_distribution(fishery)

fig_cpue_vs_biomass(
  fishery,
  tab_global = cpue_biomass_table(fishery$data, fishery$truth),
  tab_region = cpue_biomass_table(fishery$data, fishery$truth, "Region")
)

fig_cpue_fleet_strategy(
  fishery,
  tab_fleet = cpue_biomass_table(fishery$data, fishery$truth, "Fleet"),
  tab_strategy = cpue_biomass_table(fishery$data, fishery$truth, "TrueFishingStrategy")
)

fig_observation_quality(fishery, scenarios, profile = "temporal")

fig_species_composition(fishery)

fishery_figures(
  fishery,
  scenarios = NULL,
  maps = !is.null(fishery$truth$geometry)
)

make_fishery_figures(
  fishery,
  scenarios = NULL,
  dir,
  label = fishery$cfg$general$label,
  maps = !is.null(fishery$truth$geometry),
  verbose = TRUE
)
```

## Arguments

- fishery:

  An `om_fishery` object.

- years_sel:

  Years of the maps (default `cfg$output$map_years`).

- tab_global, tab_region:

  Outputs of
  [`cpue_biomass_table()`](https://rodrigosantana.github.io/pelagicOM/reference/fishery_diagnostics.md)
  (global and by region).

- tab_fleet, tab_strategy:

  Outputs of
  [`cpue_biomass_table()`](https://rodrigosantana.github.io/pelagicOM/reference/fishery_diagnostics.md)
  by fleet and by true strategy.

- scenarios:

  An `om_scenarios` object
  ([`generate_scenarios()`](https://rodrigosantana.github.io/pelagicOM/reference/generate_scenarios.md)).

- profile:

  Observation profile shown.

- maps:

  Include the effort maps (needs geometry).

- dir:

  Folder where the PNG files are written.

- label:

  Label appended to the file names.

- verbose:

  Print the file names.

## Value

A plot (or a list of them).

`make_fishery_figures()`: invisible vector of file paths.
