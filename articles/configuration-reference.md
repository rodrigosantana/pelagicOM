# Configuration reference: every parameter

This page lists every parameter of the two configurations, with its
value in the `BET_ICCAT` preset (Experimento 02) and its meaning. The
values are read from the package, so this page always matches the code.
Parameters are addressed as `section$name`. Change them with
[`om_config_update()`](https://rodrigosantana.github.io/pelagicOM/reference/om_config_update.md)
or with the `...` of the configuration functions:

``` r

cfg <- om_biomass_config("BET_ICCAT", population = list(r = 0.4))
```

## Biomass configuration (`om_biomass_config()`)

| parameter | BET_ICCAT value | meaning |
|:---|:---|:---|
| `general$label` | `"base"` | Label of the run, appended to the output file names. |
| `general$seed` | `20261005` | Single seed of Part I (process error, persistent field, yearly fields, in this order). |
| `temporal$year_start` | `1950` | First year. |
| `temporal$year_end` | `2025` | Last year. |
| `spatial$source` | `"iccat"` | `"iccat"`: bundled ICCAT 1x1 grid; `"gpkg"`: read `spatial$gpkg` with [`om_domain_from_gpkg()`](https://rodrigosantana.github.io/pelagicOM/reference/om_domain_from_gpkg.md). |
| `spatial$gpkg` | `NULL` | Path to the GeoPackage when `source = "gpkg"`. |
| `spatial$layer_grid` | `"grids_01x01"` | Grid layer of the GeoPackage. |
| `spatial$layer_stock` | `"bigeye_tuna_stock_areas"` | Stock-area layer of the GeoPackage. |
| `spatial$stock_code` | `"BET-A"` | Stock area (field CODE); see [`iccat_stocks()`](https://rodrigosantana.github.io/pelagicOM/reference/iccat_stocks.md). |
| `spatial$id_field` | `"CODE"` | Field with the permanent cell identifier. |
| `spatial$lon_field` | `"CENTER_LON"` | Field with the longitude of the representative point of the cell. |
| `spatial$lat_field` | `"CENTER_LAT"` | Field with the latitude of the representative point of the cell. |
| `spatial$selection` | `"intersects"` | Cells of the stock area (gpkg): `"intersects"` (Exp. 02) or `"point_on_surface"`. |
| `spatial$region_breaks` | `c(-20, 20)` | Ascending latitude limits of the regions. |
| `spatial$region_labels` | `c("R01", "R02", "R03")` | Region labels from north to south (one more than the breaks). |
| `population$model` | `"pella_tomlinson"` | Surplus production: `"pella_tomlinson"`, `"logistic"` or a function `f(B, K, r, shape)`. |
| `population$K` | `1e+06` | Carrying capacity (t). |
| `population$r` | `0.3` | Intrinsic growth rate (1/year). |
| `population$shape` | `1` | Pella-Tomlinson shape p (1 = Schaefer). |
| `population$B0_frac` | `0.95` | Initial biomass as a fraction of K. |
| `population$u_base` | `0.02` | Removal rate before the decline. |
| `population$decline$start` | `1965` | First year of the increase of the removal rate. |
| `population$decline$end` | `1995` | Year in which the removal rate reaches its peak. |
| `population$decline$u_peak` | `0.26` | Peak removal rate (plateau). |
| `population$recovery$start` | `2012` | First year of the decrease of the removal rate. |
| `population$recovery$end` | `2025` | Year in which the removal rate reaches `u_end`. |
| `population$recovery$u_end` | `0.12` | Final removal rate. |
| `population$u_smooth` | `5` | Window (years) of the moving average that smooths the phases. |
| `population$K_trend` | `0` | Trend in K (fraction per year; 0 = none). |
| `population$proc_sd` | `0.05` | SD of the AR(1) process error (log scale). |
| `population$proc_rho` | `0.4` | Autocorrelation of the process error. |
| `population$events` | [`list()`](https://rdrr.io/r/base/list.html) | Shocks: list of `list(year, log_shock)`. |
| `population$B_floor_frac` | `0.001` | Numerical floor: B \>= B_floor_frac \* K. |
| `habitat$envelope_type` | `"latitude"` | `"latitude"` (Gaussian on latitude, tropical) or `"abs_latitude"` (Gaussian on \|lat\|, temperate). |
| `habitat$lat_center` | `0` | Centre of the envelope (degrees; absolute latitude for `abs_latitude`). |
| `habitat$lat_sd_north` | `11` | SD of the envelope north of the centre (or in the northern hemisphere). |
| `habitat$lat_sd_south` | `11` | SD of the envelope south of the centre (or in the southern hemisphere). |
| `habitat$hotspots` | `list of 2 (table below)` | Gaussian elevations of the log-density: list of `list(lon, lat, sd_lon, sd_lat, amp)`. |
| `habitat$lon_gradient` | `0` | Log-linear gradient per degree of longitude (positive = denser to the east). |
| `habitat$field_sd` | `0.45` | SD of the persistent random field (log scale). |
| `habitat$field_range` | `4` | Range (kernel SD, degrees) of the persistent field. |
| `habitat$custom_effect` | `NULL` | Optional function of the cell table returning a log-scale layer added to the habitat. |
| `shift$enabled` | `TRUE` | Switch of the whole redistribution. |
| `shift$start` | `1950` | Year in which the ramp starts (f = 0). |
| `shift$end` | `2025` | Year in which the ramp saturates (f = 1). |
| `shift$ramp` | `"linear"` | `"linear"` or `"logistic"`. |
| `shift$ramp_steepness` | `8` | Steepness of the logistic ramp. |
| `shift$north_expansion` | `0.7` | Relative widening of the northern SD at the end of the ramp. |
| `shift$south_expansion` | `0.7` | Relative widening of the southern SD at the end of the ramp. |
| `shift$center_drift` | `0` | Drift of the centre (degrees at the end of the ramp; positive = north / poleward). |
| `shift$equatorial_contraction` | `0` | Reduction (log) of the density within the equatorial band at the end of the ramp. |
| `shift$eq_band` | `10` | Half-width (degrees) of the equatorial band. |
| `stochastic$enabled` | `TRUE` | Switch of the spatio-temporal noise. |
| `stochastic$sd` | `0.3` | Marginal SD of the noise (log scale). |
| `stochastic$range` | `3` | Spatial range (kernel SD, degrees) of the noise. |
| `stochastic$rho` | `0.6` | Temporal AR(1) autocorrelation of the noise. |
| `output$save_rds` | `TRUE` | Write `biomass_true_<label>.rds`. |
| `output$save_csv` | `TRUE` | Write the long table as `.csv.gz`. |
| `output$save_figures` | `TRUE` | Write the figures. |
| `output$map_years` | `c(1950, 1975, 2000, 2025)` | Years of the maps. |
| `output$fig_width` | `9` | Default figure width (inches). |
| `output$fig_height` | `5.5` | Default figure height (inches). |
| `output$fig_dpi` | `200` | Figure resolution. |

**Hotspots** (`habitat$hotspots`):

| lon | lat | sd_lon | sd_lat | amp |
|----:|----:|-------:|-------:|----:|
|  -5 |   0 |     10 |      5 | 0.9 |
| -32 |   4 |      9 |      5 | 0.6 |

## Fishery configuration (`om_fishery_config()`)

| parameter | BET_ICCAT value | meaning |
|:---|:---|:---|
| `general$label` | `"base"` | Label of the run, appended to the output file names. |
| `reproducibility$seeds$vessels` | `20261101` | Seed of the vessel careers. |
| `reproducibility$seeds$trips` | `20261102` | Seed of trips per vessel-year and quarters. |
| `reproducibility$seeds$sets` | `20261103` | Seed of sets per trip. |
| `reproducibility$seeds$spatial` | `20261104` | Seed of the spatial choice and fidelity. |
| `reproducibility$seeds$strategy` | `20261105` | Seed of the latent strategies. |
| `reproducibility$seeds$gear` | `20261106` | Seed of hooks and HBF (one stream). |
| `reproducibility$seeds$catchability` | `20261107` | Seed of vessel effects, spatial q field and residuals. |
| `reproducibility$seeds$catch` | `20261108` | Seed of the catch of the target species. |
| `reproducibility$seeds$species` | `20261110` | Seed of the companion species (+1: strategy-recovery diagnostic). |
| `reproducibility$seeds$observation` | `20261109` | Seed of the observation process (same for every profile). |
| `temporal$year_start` | `1950` | First year of the fishery (within the biomass years). |
| `temporal$year_end` | `2025` | Last year of the fishery. |
| `temporal$quarters` | `1:4` | Quarters (fixed: 1:4). |
| `temporal$biomass_within_year` | `"constant"` | Biomass within the year: `"constant"` (only option). |
| `vessels$turnover_enabled` | `TRUE` | Retiring vessels are replaced; FALSE keeps the same vessels all the time. |
| `vessels$career_mean` | `18` | Mean career (years). |
| `vessels$career_sd` | `6` | SD of the career (years). |
| `vessels$career_min` | `3` | Minimum career (years). |
| `trips$per_vessel_year` | `c(5, 10)` | Range of trips per vessel-year. |
| `sets$per_vessel_year` | `c(8, 15)` | Range of sets per vessel-year (`unit = "per_vessel_year"`). |
| `sets$per_trip` | `c(8, 15)` | Range of sets per trip (`unit = "per_trip"`, base). |
| `sets$unit` | `"per_trip"` | `"per_trip"` or `"per_vessel_year"`. |
| `effort$hooks_range` | `c(700, 2500)` | Truncation range of hooks per set. |
| `effort$hooks_cv` | `0.15` | CV of hooks per set around the fleet median. |
| `effort$trend_enabled` | `TRUE` | Time trend of the median hooks (FALSE: first anchor only). |
| `gear$hbf_range` | `c(4, 26)` | Range of hooks between floats. |
| `gear$hbf_by_strategy$S1` | `c("1950" = 6, "1975" = 8, "1985" = 13, "2025" = 16)` | Anchors (year = median HBF) of strategy S1. |
| `gear$hbf_by_strategy$S2` | `c("1950" = 5, "1975" = 6, "1990" = 9, "2025" = 10)` | Anchors (year = median HBF) of strategy S2. |
| `gear$hbf_by_strategy$S3` | `c("1950" = 4, "2025" = 6)` | Anchors (year = median HBF) of strategy S3. |
| `gear$hbf_vessel_sd` | `0.1` | SD (log) of the persistent HBF habit of each vessel. |
| `gear$hbf_sd` | `0.18` | SD (log) of the HBF noise per set. |
| `gear$trend_enabled` | `TRUE` | Time trend of the HBF medians (FALSE: first anchor only). |
| `gear$hbf_bin_breaks` | `c(3, 6, 9, 12, 15, 18, 26)` | HBF classes used by diagnostics and figures. |
| `strategies$levels` | `c("S1", "S2", "S3")` | Names of the fishing strategies. |
| `strategies$drift_enabled` | `TRUE` | Drift of the strategy composition in time. |
| `strategies$drift_level` | `"S1"` | Strategy whose odds drift. |
| `strategies$drift_S1_odds` | `c("1950" = 1, "2025" = 1.8)` | Anchors of the odds multiplier of `drift_level`. |
| `strategies$misclassification` | `0` | Probability that the observed strategy is wrong. |
| `spatial$preferential_sampling_strength` | `1` | theta in P(s) ~ D^theta g(s) (0 = no dependence on density). |
| `spatial$fidelity` | `0.5` | Probability of repeating the cell of the previous set of the vessel-year. |
| `spatial$core_preference_enabled` | `TRUE` | Gaussian preference around the fleet centre. |
| `spatial$expansion_enabled` | `TRUE` | Footprint grows from the centre with the years of activity. |
| `spatial$expansion_profile` | `c("0" = 0.3, "25" = 0.7, "50" = 1)` | Anchors (years since start = fraction of the accessible area). |
| `spatial$density_floor` | `1e-06` | Floor added to the density before the log. |
| `catchability$q0` | `0.01` | Reference catchability (km2 per hook). |
| `catchability$vessel_sd` | `0.3` | SD of the random vessel effect on log q. |
| `catchability$strategy_effect` | `c(S1 = 0, S2 = -0.7, S3 = -1.6)` | Effect of each strategy on log q. |
| `catchability$hbf$effect` | `1.2` | Asymptote a of f(HBF) = a (1 - exp(-b (HBF - 4))). |
| `catchability$hbf$rate` | `0.15` | Rate b of f(HBF). |
| `catchability$hbf$ref` | `8` | Reference HBF (f centred at it). |
| `catchability$hbf$by_fleet` | `c(A = 1, B = 1, C = 1, D = 1, E = 1)` | Multiplier of the HBF effect by fleet (missing fleets get 1). |
| `catchability$creep` | `0.01` | Effort creep per year on log q. |
| `catchability$creep_enabled` | `TRUE` | Switch of the creep. |
| `catchability$quarter_effect` | `c(0, 0, 0, 0)` | Effect of each quarter on log q. |
| `catchability$region_effect` | `c(R01 = 0, R02 = 0, R03 = 0)` | Effect of each region on log q. |
| `catchability$spatial$enabled` | `TRUE` | Persistent spatial field of log q. |
| `catchability$spatial$sd` | `0.15` | SD of the spatial field of log q. |
| `catchability$spatial$range` | `4` | Range (degrees) of the spatial field of log q. |
| `catchability$residual_sd` | `0.1` | SD of the residual of log q per set. |
| `catch_process$distribution` | `"tweedie"` | `"tweedie"` or `"delta_lognormal"`. |
| `catch_process$power` | `1.4` | Tweedie power p (1 \< p \< 2). |
| `catch_process$dispersion` | `1` | Tweedie dispersion phi (Var = phi mu^p). |
| `catch_process$delta$logit_a` | `1` | Delta-lognormal: intercept of logit P(catch \> 0) on log mu. |
| `catch_process$delta$logit_b` | `1` | Delta-lognormal: slope of logit P(catch \> 0) on log mu. |
| `catch_process$delta$sdlog` | `0.8` | Delta-lognormal: SD (log) of positive catches. |
| `species$enabled` | `TRUE` | Simulate companion species. |
| `species$target` | `"BET"` | Name of the target species (column `TrueCatch` / `Catch`). |
| `species$companions` | `c("YFT", "ALB", "SWO", "BSH")` | Names of the companion species. |
| `species$power` | `1.4` | Tweedie power of the companion catches. |
| `species$dispersion` | `1` | Tweedie dispersion of the companion catches. |
| `species$residual_sd` | `0.2` | SD (log) of the noise per set and species. |
| `species$cluster_sample` | `50000` | Sets sampled by the strategy-recovery diagnostic. |
| `output$save_csv` | `TRUE` | Write `.csv.gz` copies of the truth and of the data sets. |
| `output$save_figures` | `TRUE` | Write the figures. |
| `output$map_years` | `c(1955, 1975, 2000, 2025)` | Years of the effort maps. |
| `output$fig_width` | `9` | Default figure width (inches). |
| `output$fig_height` | `5.5` | Default figure height (inches). |
| `output$fig_dpi` | `200` | Figure resolution. |

### Fleets (`fleets$<name>`, see `om_fleet()`)

| field | meaning |
|----|----|
| `n_vessels` | vessel slots kept active |
| `year_start`, `year_end` | period of activity |
| `regions` | regions the fleet can fish |
| `core_lon`, `core_lat`, `core_sd` | centre and spread of the baseline spatial preference |
| `quarter_weights` | relative frequency of trips per quarter |
| `hooks_median` | anchors (year = median hooks per set) |
| `hbf_mult` | multiplier of HBF |
| `strategy_comp` | composition of strategies (sums to 1) |
| `q_effect` | fleet effect on log q |

| fleet | n_vessels | period | regions | core | quarter_weights | hooks_median | hbf_mult | strategy_comp | q_effect |
|:---|---:|:---|:---|:---|:---|:---|---:|:---|---:|
| A | 45 | 1950-2025 | R01+R02 | (-45, 12) sd 20 | 0.25/0.3/0.25/0.2 | 1950:1300 1980:1900 2025:2300 | 1.0 | S1 0.55, S2 0.30, S3 0.15 | 0.00 |
| B | 40 | 1950-2025 | R01+R02 | (-25, 8) sd 20 | 0.2/0.25/0.3/0.25 | 1950:1200 1980:1800 2025:2000 | 1.1 | S1 0.60, S2 0.25, S3 0.15 | 0.10 |
| C | 35 | 1958-2025 | R01+R02 | (-15, 22) sd 18 | 0.3/0.25/0.2/0.25 | 1950:1000 1980:1500 2025:1800 | 0.8 | S1 0.20, S2 0.35, S3 0.45 | -0.35 |
| D | 40 | 1962-2025 | R02+R03 | (-30, -8) sd 20 | 0.25/0.25/0.25/0.25 | 1950:1300 1980:1900 2025:2200 | 1.0 | S1 0.50, S2 0.35, S3 0.15 | -0.10 |
| E | 30 | 1968-2025 | R02+R03 | (0, -18) sd 18 | 0.2/0.3/0.3/0.2 | 1950:900 1980:1400 2025:1700 | 0.9 | S1 0.15, S2 0.35, S3 0.50 | -0.25 |

### Companion species (`species$params$<sp>`)

| field | meaning |
|----|----|
| `ref` | t per 1000 hooks at the reference |
| `strategy_effect` | log effect of each strategy |
| `hbf_effect` | multiplier of g(HBF), the HBF shape of the target |
| `lat_center`, `lat_sd`, `use_abs_lat` | latitudinal envelope of the species |
| `trend` | anchors of a multiplicative time trend |

| species | ref | strategy_effect | hbf_effect | lat_center | lat_sd | use_abs_lat | trend |
|:---|---:|:---|---:|---:|---:|:---|:---|
| YFT | 0.35 | S1 +0.0, S2 +0.8, S3 -0.6 | -0.4 | 5 | 15 | FALSE | 1950:1 2025:0.6 |
| ALB | 0.25 | S1 +0.2, S2 +1.0, S3 -1.5 | 0.3 | 25 | 10 | TRUE | 1950:1 2025:0.7 |
| SWO | 0.45 | S1 -2.0, S2 -1.0, S3 +0.0 | -0.9 | 20 | 20 | TRUE | 1950:1 2025:0.8 |
| BSH | 0.40 | S1 -1.8, S2 -1.0, S3 +0.0 | -0.8 | 25 | 15 | TRUE | 1950:1 2025:1 |

### Observation profiles (`observation$<profile>`)

Each profile is a list of periods. The meaning of every mechanism is in
[Observation and
scenarios](https://rodrigosantana.github.io/pelagicOM/articles/observation-scenarios.md).

| profile | period | position_sd | coord_resolution | hbf_missing | hooks_cv | hooks_round | catch_cv | catch_round | strategy_missing | vessel_missing | record_loss |
|:---|:---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| complete | 1950-2025 | 0.0 | 1 | 0.0 | 0.00 | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0.00 |
| temporal | 1950-1980 | 0.5 | 5 | 0.6 | 0.15 | 100 | 0.2 | 0.1 | 0.4 | 0.3 | 0.15 |
| temporal | 1981-2025 | 0.0 | 1 | 0.0 | 0.00 | 1 | 0.0 | 0.0 | 0.0 | 0.0 | 0.00 |

### Scenarios (`scenarios`)

| name | regions | drop | observation | objective |
|:---|:---|:---|:---|:---|
| 01_global_complete | R01+R02+R03 |  | complete | Referencia: todas as regioes e variaveis |
| 02_global_without_hbf | R01+R02+R03 | HooksBetweenFloats | complete | Efeito da ausencia de HBF (global) |
| 03_R02_complete | R02 |  | complete | Regiao central de maior abundancia e sobreposicao de frotas |
| 04_global_temporal_uncertainty | R01+R02+R03 |  | temporal | Qualidade dos dados inferior em 1950-1980 (global) |
| 05_R02_temporal_uncertainty | R02 |  | temporal | Qualidade dos dados inferior em 1950-1980 (R02) |
| 06_R01_complete | R01 |  | complete | Regional R01 completo |
| 07_R03_complete | R03 |  | complete | Regional R03 completo |
| 08_R02_without_hbf | R02 | HooksBetweenFloats | complete | Ausencia de HBF em analise regional (R02) |
