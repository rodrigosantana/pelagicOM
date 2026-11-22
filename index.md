# pelagicOM

**Spatio-temporal operating model for pelagic stocks and longline
fisheries.**

Documentation: <https://rodrigosantana.github.io/pelagicOM/>

`pelagicOM` packages the simulation components of *Experimento 02*
(workshop tRFMO CPUE, 2026) as an R package. You can rerun it, tune it
for other species and distributions, and reuse it to test CPUE
standardisation methods against a completely known truth.

| Part | What is simulated | Main function |
|----|----|----|
| I. Biomass | \\B\_{total}(y)\\ (Pella-Tomlinson + removal rate + AR(1) error), distributed on the ICCAT 1x1 grid: latitudinal envelope, hotspots, persistent random field, poleward redistribution, spatio-temporal noise | [`simulate_biomass()`](https://rodrigosantana.github.io/pelagicOM/reference/simulate_biomass.md) |
| II\. Fishery | set-by-set longline operations: fleets, vessels (careers, turnover), trips, sets, preferential sampling and fidelity, latent strategies, hooks and HBF, log q components (incl. creep), Tweedie catches, companion species | [`simulate_fishery()`](https://rodrigosantana.github.io/pelagicOM/reference/simulate_fishery.md) |
| Observation | observation profiles (position error, 5x5 resolution, missing HBF / strategy / vessel, catch and effort errors, record loss) and scenario data sets | [`generate_scenarios()`](https://rodrigosantana.github.io/pelagicOM/reference/generate_scenarios.md) |

The **`BET_ICCAT`** preset is the bigeye tuna operating model of
Experimento 02. It reproduces the experiment **bit for bit**: biomass,
long table, fishery truth (1,137,186 sets) and the eight scenario data
sets.

## Installation

``` r

# from GitHub
remotes::install_github("rodrigosantana/pelagicOM")
# or from a local copy of the source (folder pelagicOM/)
install.packages("pelagicOM", repos = NULL, type = "source")
```

`pelagicOM` imports `sf` and `lwgeom`. Every cell area is geodesic, on
the WGS84 ellipsoid, computed by
[`lwgeom::st_geod_area()`](https://r-spatial.github.io/lwgeom/reference/geod.html)
([`geodesic_area_km2()`](https://rodrigosantana.github.io/pelagicOM/reference/geodesic_area_km2.md)),
exactly as in Experimento 02. This holds for the bundled ICCAT grid, for
GeoPackages read by
[`om_domain_from_gpkg()`](https://rodrigosantana.github.io/pelagicOM/reference/om_domain_from_gpkg.md)
and for synthetic grids. Figures need `ggplot2` and `patchwork`
(Suggests).

## Quick start

``` r

library(pelagicOM)

sim  <- simulate_biomass(om_biomass_config("BET_ICCAT"))   # Part I  (~1 s)
fish <- simulate_fishery(sim, om_fishery_config("BET_ICCAT"))  # Part II (~15 s)
scen <- generate_scenarios(fish)                           # 8 data sets

# or everything at once, written with the folder structure of Experimento 02
run <- om_run("BET_ICCAT", dir = "Experimento_pelagicOM")
```

## Tuning

``` r

# any parameter: named lists are merged, everything else is replaced
bcfg <- om_biomass_config("BET_ICCAT",
                          population = list(r = 0.45),
                          shift = list(center_drift = 3))

# any ICCAT stock area (24 areas bundled), any latitudinal regions,
# or read a GeoPackage directly (geodesic areas by lwgeom)
iccat_stocks()
dom <- om_domain_iccat("ALB-N", region_breaks = c(25, 40),
                       region_labels = c("NORTH", "CENTRAL", "SOUTH"))
dom2 <- om_domain_from_gpkg("Experimento_02/ICCAT/ICCAT_gis.gpkg",
                            layer_stock = "albacore_tuna_stock_areas",
                            stock_code = "ALB-N",
                            selection = "point_on_surface")

# temperate species: envelope on |latitude|; user-defined habitat layers
bcfg$habitat$envelope_type <- "abs_latitude"
bcfg$habitat$custom_effect <- function(cells) 0.01 * cells$Longitude

# any fleets
fcfg <- om_fishery_config("BET_ICCAT")
fcfg$fleets$F <- om_fleet(n_vessels = 20, year_start = 1990,
                          regions = "R02", core_lon = -10, core_lat = 0)
```

The [articles](https://rodrigosantana.github.io/pelagicOM/articles/)
cover every component of the model and the tuning options, including a
complete example with a temperate tuna in the ALB-N area, the
configuration reference and the data dictionary.

## Proof of reproduction

``` sh
Rscript pelagicOM/inst/scripts/reproduce_experimento02.R Experimento_02
```

The script compares the outputs with the Experimento 02 files using
[`identical()`](https://rdrr.io/r/base/identical.html): 19 of 19
components are identical, and the caller’s random stream is preserved.
The same proof also runs as a unit test:

``` sh
PELAGICOM_EXP02=$PWD/Experimento_02 Rscript -e 'devtools::test("pelagicOM")'
```

In addition, every CSV written by `om_run(dir = ...)` has the same text
as the CSV of the experiment. This covers 5 biomass tables, 4 fishery
tables and 17 diagnostic tables.

## Package structure

    pelagicOM/
    ├── R/
    │   ├── config_biomass.R, config_fishery.R, config_tools.R   presets, validation, om_config_update(), om_fleet()
    │   ├── domain.R                                             ICCAT grid, GeoPackage, synthetic grid, regions
    │   ├── biomass_population.R, biomass_habitat.R              Part I modules (02-04 of Simulacao_Biomassa)
    │   ├── biomass_simulate.R, biomass_diagnostics.R, biomass_figures.R
    │   ├── fishery_truth.R, fishery_structure.R, fishery_effort.R, fishery_catch.R   Part II modules (01-10)
    │   ├── fishery_observation.R, fishery_simulate.R            observation, scenarios, pipeline (11-12)
    │   ├── fishery_diagnostics.R, fishery_figures.R             (13-14)
    │   ├── io.R                                                 om_run(), om_write_biomass(), om_write_fishery()
    │   └── reference.R                                          om_compare_reference()
    ├── inst/extdata/      iccat_grid.rds (cells + 24 stock areas), iccat_geometry.rds (polygons for maps)
    ├── inst/scripts/      reproduce_experimento02.R
    ├── data-raw/          build_iccat_grid.R (ICCAT_gis.gpkg -> om_domain_from_gpkg() + lwgeom -> inst/extdata,
    │                      checked against the saved domain of Experimento 02)
    ├── tests/testthat/    unit tests + full reproduction test (PELAGICOM_EXP02)
    └── vignettes/         pelagicOM.Rmd

## License

GPL-3 (see `LICENSE`).

## Resumo em português

O `pelagicOM` empacota as componentes de simulação do Experimento 02:
biomassa espaço-temporal (Parte I), dados pesqueiros de espinhel lance a
lance (Parte II), processo de observação e cenários. O preset
`BET_ICCAT` reproduz exatamente os resultados do experimento para o BET,
e o script `inst/scripts/reproduce_experimento02.R` faz essa prova.

As áreas das células são geodésicas (elipsoide WGS84) e calculadas pelo
`lwgeom`
([`geodesic_area_km2()`](https://rodrigosantana.github.io/pelagicOM/reference/geodesic_area_km2.md)),
como no experimento. A grade ICCAT embutida é gerada do GeoPackage pelo
próprio pacote
([`om_domain_from_gpkg()`](https://rodrigosantana.github.io/pelagicOM/reference/om_domain_from_gpkg.md))
e conferida contra o domínio salvo do Experimento 02.

Todos os parâmetros podem ser ajustados com
[`om_config_update()`](https://rodrigosantana.github.io/pelagicOM/reference/om_config_update.md).
A área pode ser qualquer estoque da ICCAT
([`om_domain_iccat()`](https://rodrigosantana.github.io/pelagicOM/reference/om_domain_iccat.md)),
as regiões podem ser faixas de latitude livres, o envelope pode ser
tropical (`"latitude"`) ou temperado (`"abs_latitude"`), e frotas,
espécies-alvo e acompanhantes também são configuráveis. A metodologia
completa está em `Experimento_02/Simulacao_Biomassa/METODOLOGIA.md` e
`Experimento_02/Simulacao_Pesca/RELATORIO_METODOLOGICO.md`.
