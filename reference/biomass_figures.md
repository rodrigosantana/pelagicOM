# Figures of the biomass truth

`biomass_figures()` returns the eight diagnostic figures of Experimento
02 as a named list of `ggplot` objects; `make_biomass_figures()` saves
them as PNG files named `figNN_<name>_<label>.png`. The individual
`fig_*` functions build one figure each. Maps (`fig_maps()`,
`fig_base_habitat()`) need the cell geometry (package `sf` and a domain
built with `geometry = TRUE`).

## Usage

``` r
fig_total_biomass(sim)

fig_region_biomass(sim, reg = regional_summary(sim))

fig_region_share(sim, reg = regional_summary(sim))

fig_maps(sim, years_sel = NULL)

fig_centre_gravity(sim, cg = centre_of_gravity(sim))

fig_hovmoller(sim, prof = latitude_profile(sim))

fig_base_habitat(sim)

fig_envelope_profiles(sim, years_sel = NULL)

biomass_figures(sim, maps = !is.null(sim$dom$geometry))

make_biomass_figures(
  sim,
  dir,
  label = sim$cfg$general$label,
  maps = !is.null(sim$dom$geometry),
  verbose = TRUE
)
```

## Arguments

- sim:

  An `om_biomass` object.

- reg:

  Output of
  [`regional_summary()`](https://rodrigosantana.github.io/pelagicOM/reference/biomass_summaries.md).

- years_sel:

  Years shown in the maps (default `cfg$output$map_years`).

- cg:

  Output of
  [`centre_of_gravity()`](https://rodrigosantana.github.io/pelagicOM/reference/biomass_summaries.md).

- prof:

  Output of
  [`latitude_profile()`](https://rodrigosantana.github.io/pelagicOM/reference/biomass_summaries.md).

- maps:

  Include the maps (needs geometry).

- dir:

  Folder where the PNG files are written.

- label:

  Label appended to the file names.

- verbose:

  Print the file names.

## Value

A `ggplot` (or a list of them).

`make_biomass_figures()`: invisible vector of file paths.
