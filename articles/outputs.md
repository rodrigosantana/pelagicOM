# Outputs, files and data dictionary

``` r

library(pelagicOM)
```

## Objects in memory

| function | returns | main components |
|----|----|----|
| [`simulate_biomass()`](https://rodrigosantana.github.io/pelagicOM/reference/simulate_biomass.md) | `om_biomass` | `cfg`, `dom`, `pop`, `base`, `envelope`, `noise`, `logD`, `weights`, `biomass`, `envelope_params`, `table` |
| [`simulate_fishery()`](https://rodrigosantana.github.io/pelagicOM/reference/simulate_fishery.md) | `om_fishery` | `cfg`, `data` (true sets), `fleets`, `vessels`, `vessel_years`, `trips`, `vessel_effects`, `truth`, `observed_columns`, `latent_columns` |
| [`generate_scenarios()`](https://rodrigosantana.github.io/pelagicOM/reference/generate_scenarios.md) | `om_scenarios` | `datasets` (named list), `metadata`, `observed` (one data set per profile) |
| [`om_run()`](https://rodrigosantana.github.io/pelagicOM/reference/om_run.md) | `om_run` | `biomass`, `fishery`, `scenarios`, `checks` |

## Files written

`om_run(dir = ...)` writes
[`om_write_biomass()`](https://rodrigosantana.github.io/pelagicOM/reference/om_write_biomass.md)
into `dir/Simulacao_Biomassa` and
[`om_write_fishery()`](https://rodrigosantana.github.io/pelagicOM/reference/om_write_fishery.md)
into `dir/Simulacao_Pesca`. File names and folders are those of
Experimento 02. The example below uses reduced fleets:

``` r

fcfg <- om_fishery_config("BET_ICCAT",
    fleets = list(A = list(n_vessels = 4), B = list(n_vessels = 4),
                  C = list(n_vessels = 3), D = list(n_vessels = 3),
                  E = list(n_vessels = 3)))
out <- file.path(tempdir(), "pelagicOM_example")
run <- om_run("BET_ICCAT", fishery_cfg = fcfg, dir = out, figures = FALSE,
              csv = FALSE, verbose = FALSE)
cat(sort(list.files(out, recursive = TRUE)), sep = "\n")
#> Simulacao_Biomassa/outputs/data/biomass_true_base.rds
#> Simulacao_Biomassa/outputs/data/cells_base.csv
#> Simulacao_Biomassa/outputs/data/centre_of_gravity_base.csv
#> Simulacao_Biomassa/outputs/data/config_base.rds
#> Simulacao_Biomassa/outputs/data/envelope_params_base.csv
#> Simulacao_Biomassa/outputs/data/population_base.csv
#> Simulacao_Biomassa/outputs/data/regional_summary_base.csv
#> Simulacao_Pesca/outputs/datasets/01_global_complete.rds
#> Simulacao_Pesca/outputs/datasets/02_global_without_hbf.rds
#> Simulacao_Pesca/outputs/datasets/03_R02_complete.rds
#> Simulacao_Pesca/outputs/datasets/04_global_temporal_uncertainty.rds
#> Simulacao_Pesca/outputs/datasets/05_R02_temporal_uncertainty.rds
#> Simulacao_Pesca/outputs/datasets/06_R01_complete.rds
#> Simulacao_Pesca/outputs/datasets/07_R03_complete.rds
#> Simulacao_Pesca/outputs/datasets/08_R02_without_hbf.rds
#> Simulacao_Pesca/outputs/datasets/scenarios_metadata.csv
#> Simulacao_Pesca/outputs/diagnostics/catch_summary_fleet_base.csv
#> Simulacao_Pesca/outputs/diagnostics/catch_summary_region_base.csv
#> Simulacao_Pesca/outputs/diagnostics/catch_summary_strategy_base.csv
#> Simulacao_Pesca/outputs/diagnostics/catchability_summary_base.csv
#> Simulacao_Pesca/outputs/diagnostics/cpue_biomass_slopes_base.csv
#> Simulacao_Pesca/outputs/diagnostics/cpue_vs_biomass_base.csv
#> Simulacao_Pesca/outputs/diagnostics/fleet_structure_base.csv
#> Simulacao_Pesca/outputs/diagnostics/hbf_summary_base.csv
#> Simulacao_Pesca/outputs/diagnostics/hooks_summary_base.csv
#> Simulacao_Pesca/outputs/diagnostics/observation_mechanisms_base.csv
#> Simulacao_Pesca/outputs/diagnostics/regional_presence_base.csv
#> Simulacao_Pesca/outputs/diagnostics/species_cluster_confusion_base.csv
#> Simulacao_Pesca/outputs/diagnostics/species_cluster_recovery_base.csv
#> Simulacao_Pesca/outputs/diagnostics/species_composition_fleet_base.csv
#> Simulacao_Pesca/outputs/diagnostics/species_composition_strategy_base.csv
#> Simulacao_Pesca/outputs/diagnostics/strategy_frequency_base.csv
#> Simulacao_Pesca/outputs/diagnostics/vessels_by_year_base.csv
#> Simulacao_Pesca/outputs/truth/config_base.rds
#> Simulacao_Pesca/outputs/truth/fleets_base.csv
#> Simulacao_Pesca/outputs/truth/trips_base.csv
#> Simulacao_Pesca/outputs/truth/TRUE_FISHERY_DATA_base.rds
#> Simulacao_Pesca/outputs/truth/vessel_effects_base.csv
#> Simulacao_Pesca/outputs/truth/vessels_base.csv
```

With `figures = TRUE` (the default), `outputs/figures/` receives 8 PNG
files for the biomass and 12 for the fishery. With `csv = TRUE`,
compressed `.csv.gz` copies of the large tables are also written. The
`.rds` files are read back with
[`readRDS()`](https://rdrr.io/r/base/readRDS.html).
`biomass_true_<label>.rds` can be passed directly to
[`simulate_fishery()`](https://rodrigosantana.github.io/pelagicOM/reference/simulate_fishery.md).

``` r

sim  <- readRDS(file.path(out, "Simulacao_Biomassa/outputs/data/biomass_true_base.rds"))
fish <- simulate_fishery(file.path(out, "Simulacao_Biomassa/outputs/data/biomass_true_base.rds"))
```

## Biomass: population series (`pop`, `population_<label>.csv`)

| column       | unit | meaning                       |
|--------------|------|-------------------------------|
| `Year`       |      | year                          |
| `B_total`    | t    | total biomass                 |
| `K_year`     | t    | carrying capacity of the year |
| `u`          | 1/yr | removal rate                  |
| `Surplus`    | t    | surplus production            |
| `Removal`    | t    | removal u × B                 |
| `Proc_error` | log  | process error (+ shocks)      |
| `Depletion`  |      | B_total / K                   |
| `B_Bmsy`     |      | B_total / Bmsy                |

``` r

head(run$biomass$pop, 3)
#>   Year  B_total K_year    u   Surplus  Removal   Proc_error Depletion   B_Bmsy
#> 1 1950 950000.0  1e+06 0.02 14250.000 19000.00 -0.004677681 0.9500000 1.900000
#> 2 1951 943623.4  1e+06 0.02 15959.493 18872.47 -0.001722335 0.9436234 1.887247
#> 3 1952 978115.8  1e+06 0.02  6421.595 19562.32  0.038992708 0.9781158 1.956232
```

## Biomass: long table (`table`, `biomass_true_<label>.csv.gz`)

| column | unit | meaning |
|----|----|----|
| `Year`, `Cell_ID` |  | year and permanent cell identifier (ICCAT `CODE`) |
| `Longitude`, `Latitude` | degrees | representative point of the cell |
| `Region` |  | latitudinal region |
| `Area_km2` | km² | geodesic sea area of the cell |
| `B_total` | t | total biomass of the year |
| `Spatial_weight` |  | p(y, s), sums to 1 in each year |
| `Biomass` | t | B(y, s) = B_total × p |
| `Density` | t/km² | Biomass / Area_km2 |
| `Relative_biomass` |  | Biomass / temporal mean of the cell |
| `Depletion` |  | B_total / K |

``` r

head(run$biomass$table, 3)
#>   Year Cell_ID Longitude Latitude Region Area_km2 B_total Spatial_weight
#> 1 1950 5100000       0.5      0.5    R02 12308.78  950000    0.001268668
#> 2 1950 5100001       1.5      0.5    R02 12308.78  950000    0.001301248
#> 3 1950 5100002       2.5      0.5    R02 12308.78  950000    0.001338848
#>    Biomass    Density Relative_biomass Depletion
#> 1 1205.234 0.09791664         2.114591      0.95
#> 2 1236.186 0.10043121         1.983669      0.95
#> 3 1271.906 0.10333324         1.916429      0.95
```

## Fishery truth (`data`, `TRUE_FISHERY_DATA_<label>.rds`)

One row per set. The observable columns come first:

| column | meaning |
|----|----|
| `Year`, `Quarter` | time of the set |
| `Fleet`, `VesselID`, `TripID`, `SetID` | identifiers (`SetID` within `TripID` within `VesselID`) |
| `Hooks` | effort: hooks per set |
| `HooksBetweenFloats` | gear configuration (HBF) |
| `Region`, `Longitude`, `Latitude`, `Cell_ID` | position (cell of the domain) |

The latent columns follow, i.e. the truth that a standardisation tries
to recover:

| column | meaning |
|----|----|
| `TrueFishingStrategy` | latent strategy (S1 deep … S3 shallow) |
| `TrueDensity`, `TrueBiomass` | density (t/km²) and biomass (t) of the cell in the year |
| `TrueCatchability`, `log_q` | catchability (km² per hook) and its log |
| `q_fleet`, `q_vessel`, `q_strategy`, `q_hbf`, `q_creep`, `q_quarter`, `q_region`, `q_spatial`, `q_resid` | components of log q |
| `ExpectedCatch` | q × Hooks × TrueDensity (t) |
| `ZeroProb` | probability of a zero catch |
| `TrueCatch` | catch of the target species (t) |
| `SelectionProb`, `SpatialChoice` | probability of the chosen cell; `"preference"` or `"fidelity"` |
| `FootprintCells`, `FootprintFrac` | size of the footprint of the fleet in the year |
| `HBF_vessel_habit` | multiplicative HBF habit of the vessel |
| `CellIndex`, `TripIndex`, `SetInTrip`, `SetOrder` | indices |
| `Expected_<sp>`, `TrueCatch_<sp>`, `TrueCatch_total` | companion species and total catch |

``` r

str(run$fishery$data[, 1:12])
#> 'data.frame':    102023 obs. of  12 variables:
#>  $ Year              : int  1950 1950 1950 1950 1950 1950 1950 1950 1950 1950 ...
#>  $ Quarter           : int  1 1 1 1 1 1 1 1 1 2 ...
#>  $ Fleet             : chr  "A" "A" "A" "A" ...
#>  $ VesselID          : chr  "A_001" "A_001" "A_001" "A_001" ...
#>  $ TripID            : chr  "A_001_1950_T01" "A_001_1950_T01" "A_001_1950_T01" "A_001_1950_T01" ...
#>  $ SetID             : chr  "A_001_1950_T01_S01" "A_001_1950_T01_S02" "A_001_1950_T01_S03" "A_001_1950_T01_S04" ...
#>  $ Hooks             : int  1131 1205 1051 1391 1050 1028 1683 1149 1367 1596 ...
#>  $ HooksBetweenFloats: int  5 6 5 7 6 5 7 7 6 8 ...
#>  $ Region            : chr  "R02" "R02" "R02" "R02" ...
#>  $ Longitude         : num  -55.5 -55.5 -54.5 -52.4 -37.5 ...
#>  $ Latitude          : num  15.5 15.5 7.5 5.55 14.5 ...
#>  $ Cell_ID           : chr  "5415055" "5415055" "5407054" "5405052" ...
```

## Observed data sets (`outputs/datasets/<scenario>.rds`)

| column | meaning |
|----|----|
| `Year`, `Quarter`, `Fleet`, `VesselID`, `TripID`, `SetID` | as in the truth (`VesselID` may be NA) |
| `Hooks` | observed hooks (error / rounding by profile) |
| `HooksBetweenFloats` | observed HBF (may be NA or removed) |
| `FishingStrategy` | observed strategy (may be NA or misclassified) |
| `Region`, `Longitude`, `Latitude`, `Cell_ID` | observed position (`Cell_ID` NA at 5x5 resolution) |
| `Catch`, `Catch_<sp>` | observed catches (t) |

`scenarios_metadata.csv` describes each data set: its objective,
regions, period, number of sets, available and removed variables,
uncertainty, the true processes and the differences from the complete
reference.

## Diagnostic tables (`outputs/diagnostics/`)

| file | function |
|----|----|
| `fleet_structure_<label>.csv` | [`fleet_structure_table()`](https://rodrigosantana.github.io/pelagicOM/reference/fishery_diagnostics.md) |
| `vessels_by_year_<label>.csv` | [`active_vessels_by_year()`](https://rodrigosantana.github.io/pelagicOM/reference/active_vessels_by_year.md) |
| `regional_presence_<label>.csv` | [`regional_presence_table()`](https://rodrigosantana.github.io/pelagicOM/reference/fishery_diagnostics.md) |
| `hooks_summary_<label>.csv` | [`effort_summary_table()`](https://rodrigosantana.github.io/pelagicOM/reference/fishery_diagnostics.md) |
| `hbf_summary_<label>.csv` | [`hbf_summary_table()`](https://rodrigosantana.github.io/pelagicOM/reference/fishery_diagnostics.md) |
| `strategy_frequency_<label>.csv` | [`strategy_frequency_table()`](https://rodrigosantana.github.io/pelagicOM/reference/fishery_diagnostics.md) |
| `catch_summary_{fleet,region,strategy}_<label>.csv` | [`catch_summary_table()`](https://rodrigosantana.github.io/pelagicOM/reference/fishery_diagnostics.md) |
| `catchability_summary_<label>.csv` | [`catchability_summary_table()`](https://rodrigosantana.github.io/pelagicOM/reference/fishery_diagnostics.md) |
| `cpue_vs_biomass_<label>.csv` | [`cpue_biomass_table()`](https://rodrigosantana.github.io/pelagicOM/reference/fishery_diagnostics.md) |
| `cpue_biomass_slopes_<label>.csv` | [`cpue_biomass_slopes()`](https://rodrigosantana.github.io/pelagicOM/reference/fishery_diagnostics.md) |
| `observation_mechanisms_<label>.csv` | `attr(obs, "mechanisms")` |
| `species_composition_{strategy,fleet}_<label>.csv` | [`species_composition_table()`](https://rodrigosantana.github.io/pelagicOM/reference/fishery_diagnostics.md) |
| `species_cluster_{confusion,recovery}_<label>.csv` | [`strategy_recovery_diagnostic()`](https://rodrigosantana.github.io/pelagicOM/reference/fishery_diagnostics.md) |
