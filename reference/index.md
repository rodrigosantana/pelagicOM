# Package index

## Complete runs

Run the whole operating model and write or check its outputs.

- [`om_run()`](https://rodrigosantana.github.io/pelagicOM/reference/om_run.md)
  : Run the complete operating model
- [`om_write_biomass()`](https://rodrigosantana.github.io/pelagicOM/reference/om_write_biomass.md)
  : Write the biomass outputs
- [`om_write_fishery()`](https://rodrigosantana.github.io/pelagicOM/reference/om_write_fishery.md)
  : Write the fishery outputs
- [`om_compare_reference()`](https://rodrigosantana.github.io/pelagicOM/reference/om_compare_reference.md)
  : Compare a run with reference outputs

## Configuration

Presets and tools to tune every parameter.

- [`om_presets()`](https://rodrigosantana.github.io/pelagicOM/reference/om_presets.md)
  : Available presets
- [`om_biomass_config()`](https://rodrigosantana.github.io/pelagicOM/reference/om_biomass_config.md)
  [`validate_biomass_config()`](https://rodrigosantana.github.io/pelagicOM/reference/om_biomass_config.md)
  : Biomass (Part I) configuration
- [`om_fishery_config()`](https://rodrigosantana.github.io/pelagicOM/reference/om_fishery_config.md)
  [`validate_fishery_config()`](https://rodrigosantana.github.io/pelagicOM/reference/om_fishery_config.md)
  : Fishery (Part II) configuration
- [`om_config_update()`](https://rodrigosantana.github.io/pelagicOM/reference/om_config_update.md)
  : Tune a configuration
- [`om_fleet()`](https://rodrigosantana.github.io/pelagicOM/reference/om_fleet.md)
  : Specification of a fleet

## Spatial domain

ICCAT grid and stock areas, GeoPackages, synthetic grids, regions.

- [`om_domain()`](https://rodrigosantana.github.io/pelagicOM/reference/om_domain.md)
  : Spatial domain from a biomass configuration
- [`om_domain_iccat()`](https://rodrigosantana.github.io/pelagicOM/reference/om_domain_iccat.md)
  : Spatial domain on the ICCAT 1x1 grid
- [`om_domain_from_gpkg()`](https://rodrigosantana.github.io/pelagicOM/reference/om_domain_from_gpkg.md)
  : Spatial domain from an ICCAT-like GeoPackage
- [`om_domain_grid()`](https://rodrigosantana.github.io/pelagicOM/reference/om_domain_grid.md)
  : Synthetic rectangular domain
- [`iccat_stocks()`](https://rodrigosantana.github.io/pelagicOM/reference/iccat_stocks.md)
  : ICCAT stock areas available in the bundled grid
- [`iccat_geometry()`](https://rodrigosantana.github.io/pelagicOM/reference/iccat_geometry.md)
  : Cell polygons of the bundled ICCAT grid
- [`inspect_geopackage()`](https://rodrigosantana.github.io/pelagicOM/reference/inspect_geopackage.md)
  : Inspect a GeoPackage
- [`classify_regions()`](https://rodrigosantana.github.io/pelagicOM/reference/classify_regions.md)
  : Latitudinal regions
- [`geodesic_area_km2()`](https://rodrigosantana.github.io/pelagicOM/reference/geodesic_area_km2.md)
  : Geodesic area of polygons

## Biomass operating truth (Part I)

- [`simulate_biomass()`](https://rodrigosantana.github.io/pelagicOM/reference/simulate_biomass.md)
  : Simulate the spatio-temporal biomass operating truth
- [`build_long_table()`](https://rodrigosantana.github.io/pelagicOM/reference/build_long_table.md)
  : Long table of the biomass truth
- [`reference_points()`](https://rodrigosantana.github.io/pelagicOM/reference/reference_points.md)
  : Reference points of the production model
- [`latitudinal_envelope()`](https://rodrigosantana.github.io/pelagicOM/reference/latitudinal_envelope.md)
  : Latitudinal envelope (log scale)
- [`gaussian_random_field()`](https://rodrigosantana.github.io/pelagicOM/reference/gaussian_random_field.md)
  : Gaussian random field on the regular lattice
- [`check_simulation()`](https://rodrigosantana.github.io/pelagicOM/reference/check_simulation.md)
  [`check_reproducibility()`](https://rodrigosantana.github.io/pelagicOM/reference/check_simulation.md)
  : Automatic checks of the biomass truth
- [`regional_summary()`](https://rodrigosantana.github.io/pelagicOM/reference/biomass_summaries.md)
  [`centre_of_gravity()`](https://rodrigosantana.github.io/pelagicOM/reference/biomass_summaries.md)
  [`latitude_profile()`](https://rodrigosantana.github.io/pelagicOM/reference/biomass_summaries.md)
  : Summaries of the biomass truth

## Fishery (Part II)

- [`simulate_fishery()`](https://rodrigosantana.github.io/pelagicOM/reference/simulate_fishery.md)
  : Simulate the longline fishery on top of the biomass truth
- [`fishery_truth()`](https://rodrigosantana.github.io/pelagicOM/reference/fishery_truth.md)
  : Population truth for the fishery generator
- [`hbf_effect_fun()`](https://rodrigosantana.github.io/pelagicOM/reference/hbf_effect_fun.md)
  : Effect of hooks between floats on log catchability
- [`rtweedie_cpg()`](https://rodrigosantana.github.io/pelagicOM/reference/rtweedie_cpg.md)
  : Tweedie random draws (compound Poisson-Gamma)
- [`active_vessels_by_year()`](https://rodrigosantana.github.io/pelagicOM/reference/active_vessels_by_year.md)
  : Active vessels by fleet and year
- [`check_fishery_truth()`](https://rodrigosantana.github.io/pelagicOM/reference/check_fishery_truth.md)
  [`check_observed_dataset()`](https://rodrigosantana.github.io/pelagicOM/reference/check_fishery_truth.md)
  : Structural checks of the fishery truth and of observed data sets

## Observation and scenarios

- [`apply_observation_process()`](https://rodrigosantana.github.io/pelagicOM/reference/apply_observation_process.md)
  : Observation process
- [`generate_scenarios()`](https://rodrigosantana.github.io/pelagicOM/reference/generate_scenarios.md)
  : Scenario data sets

## Diagnostics

- [`fleet_structure_table()`](https://rodrigosantana.github.io/pelagicOM/reference/fishery_diagnostics.md)
  [`regional_presence_table()`](https://rodrigosantana.github.io/pelagicOM/reference/fishery_diagnostics.md)
  [`effort_summary_table()`](https://rodrigosantana.github.io/pelagicOM/reference/fishery_diagnostics.md)
  [`hbf_summary_table()`](https://rodrigosantana.github.io/pelagicOM/reference/fishery_diagnostics.md)
  [`strategy_frequency_table()`](https://rodrigosantana.github.io/pelagicOM/reference/fishery_diagnostics.md)
  [`catch_summary_table()`](https://rodrigosantana.github.io/pelagicOM/reference/fishery_diagnostics.md)
  [`catchability_summary_table()`](https://rodrigosantana.github.io/pelagicOM/reference/fishery_diagnostics.md)
  [`cpue_biomass_table()`](https://rodrigosantana.github.io/pelagicOM/reference/fishery_diagnostics.md)
  [`cpue_biomass_slopes()`](https://rodrigosantana.github.io/pelagicOM/reference/fishery_diagnostics.md)
  [`species_composition_table()`](https://rodrigosantana.github.io/pelagicOM/reference/fishery_diagnostics.md)
  [`strategy_recovery_diagnostic()`](https://rodrigosantana.github.io/pelagicOM/reference/fishery_diagnostics.md)
  : Diagnostic tables of the fishery truth

## Figures

- [`fig_total_biomass()`](https://rodrigosantana.github.io/pelagicOM/reference/biomass_figures.md)
  [`fig_region_biomass()`](https://rodrigosantana.github.io/pelagicOM/reference/biomass_figures.md)
  [`fig_region_share()`](https://rodrigosantana.github.io/pelagicOM/reference/biomass_figures.md)
  [`fig_maps()`](https://rodrigosantana.github.io/pelagicOM/reference/biomass_figures.md)
  [`fig_centre_gravity()`](https://rodrigosantana.github.io/pelagicOM/reference/biomass_figures.md)
  [`fig_hovmoller()`](https://rodrigosantana.github.io/pelagicOM/reference/biomass_figures.md)
  [`fig_base_habitat()`](https://rodrigosantana.github.io/pelagicOM/reference/biomass_figures.md)
  [`fig_envelope_profiles()`](https://rodrigosantana.github.io/pelagicOM/reference/biomass_figures.md)
  [`biomass_figures()`](https://rodrigosantana.github.io/pelagicOM/reference/biomass_figures.md)
  [`make_biomass_figures()`](https://rodrigosantana.github.io/pelagicOM/reference/biomass_figures.md)
  : Figures of the biomass truth
- [`fig_effort_time()`](https://rodrigosantana.github.io/pelagicOM/reference/fishery_figures.md)
  [`fig_effort_maps()`](https://rodrigosantana.github.io/pelagicOM/reference/fishery_figures.md)
  [`fig_gear()`](https://rodrigosantana.github.io/pelagicOM/reference/fishery_figures.md)
  [`fig_strategy()`](https://rodrigosantana.github.io/pelagicOM/reference/fishery_figures.md)
  [`fig_catchability_time()`](https://rodrigosantana.github.io/pelagicOM/reference/fishery_figures.md)
  [`fig_catchability_factors()`](https://rodrigosantana.github.io/pelagicOM/reference/fishery_figures.md)
  [`fig_vessel_effects()`](https://rodrigosantana.github.io/pelagicOM/reference/fishery_figures.md)
  [`fig_catch_distribution()`](https://rodrigosantana.github.io/pelagicOM/reference/fishery_figures.md)
  [`fig_cpue_vs_biomass()`](https://rodrigosantana.github.io/pelagicOM/reference/fishery_figures.md)
  [`fig_cpue_fleet_strategy()`](https://rodrigosantana.github.io/pelagicOM/reference/fishery_figures.md)
  [`fig_observation_quality()`](https://rodrigosantana.github.io/pelagicOM/reference/fishery_figures.md)
  [`fig_species_composition()`](https://rodrigosantana.github.io/pelagicOM/reference/fishery_figures.md)
  [`fishery_figures()`](https://rodrigosantana.github.io/pelagicOM/reference/fishery_figures.md)
  [`make_fishery_figures()`](https://rodrigosantana.github.io/pelagicOM/reference/fishery_figures.md)
  : Figures of the fishery truth
- [`theme_pub()`](https://rodrigosantana.github.io/pelagicOM/reference/theme_pub.md)
  : Publication theme of pelagicOM figures
