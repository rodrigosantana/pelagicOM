# Diagnostic tables of the fishery truth

Tables written by Experimento 02 in `outputs/diagnostics/`: fleet
structure, regional presence, hooks and HBF quantiles by decade,
strategy frequency, catch summaries, mean catchability by factor (the
truth a standardisation tries to recover), nominal CPUE vs true biomass
(global or by factor; for regions the reference is the regional biomass)
and its log-log slopes (beta \< 1 indicates hyperstability), species
composition and the recovery of the latent strategy from the catch
composition (k-means and PCA, a check that the generator leaves the
signature that a cluster / DPC approach looks for).

## Usage

``` r
fleet_structure_table(td, vessels, trips)

regional_presence_table(td)

effort_summary_table(td)

hbf_summary_table(td)

strategy_frequency_table(td)

catch_summary_table(td, by = "Fleet")

catchability_summary_table(td, hbf_breaks = c(3, 6, 9, 12, 15, 18, 26))

cpue_biomass_table(td, truth, by = NULL)

cpue_biomass_slopes(tab)

species_composition_table(td, cfg, by = "TrueFishingStrategy")

strategy_recovery_diagnostic(td, cfg)
```

## Arguments

- td:

  True fishery data (`$data` of an `om_fishery` object).

- vessels, trips:

  Vessel and trip tables of the `om_fishery` object.

- by:

  Grouping column.

- hbf_breaks:

  Breaks of the HBF classes.

- truth:

  Population truth
  ([`fishery_truth()`](https://rodrigosantana.github.io/pelagicOM/reference/fishery_truth.md)).

- tab:

  Output of `cpue_biomass_table()`.

- cfg:

  Fishery configuration.

## Value

A data frame (or a list for `strategy_recovery_diagnostic()`).
