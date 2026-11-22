# Proof of reproduction of Experimento 02

`pelagicOM` packages the simulation of Experimento 02 (workshop tRFMO
CPUE, 2026). The original scripts are `Simulacao_Biomassa/` (Part I) and
`Simulacao_Pesca/` (Part II). The `BET_ICCAT` preset must reproduce them
**bit for bit**. This page explains how that is checked and records the
result.

## Why the results are identical

- Every module is a line-by-line port of the original code. The random
  draws happen in the same order and use the same seeds: one seed for
  Part I and one per process in Part II.
- The RNG kinds are set explicitly (Mersenne-Twister, Inversion,
  Rejection). A user-level
  [`RNGkind()`](https://rdrr.io/r/base/Random.html) therefore cannot
  change the results, and the caller’s random stream is restored at the
  end.
- The spatial domain is the same. The bundled ICCAT grid is built from
  `ICCAT_gis.gpkg` by
  [`om_domain_from_gpkg()`](https://rodrigosantana.github.io/pelagicOM/reference/om_domain_from_gpkg.md),
  with geodesic areas from `lwgeom`, and the build stops unless cells,
  lattice and polygons are identical to the saved domain of the
  experiment (`data-raw/build_iccat_grid.R`).
- The generalisations of the package (free regions, envelope on absolute
  latitude, user habitat layers, any fleets) all have neutral defaults.

## How to run the proof

The reference files of Experimento 02 are not distributed with the
package. With the experiment folder at hand:

``` sh
Rscript -e 'source(system.file("scripts", "reproduce_experimento02.R",
                               package = "pelagicOM"))' \
        --args R-Work/Experimento_02
# or
PELAGICOM_EXP02=R-Work/Experimento_02 \
    Rscript $(Rscript -e 'cat(system.file("scripts", "reproduce_experimento02.R", package = "pelagicOM"))')
```

or, in R:

``` r

library(pelagicOM)
run <- om_run("BET_ICCAT")                       # ~15 s
om_compare_reference(run, "R-Work/Experimento_02")
```

The same comparison runs as a unit test when the environment variable
`PELAGICOM_EXP02` points to the experiment folder:

``` sh
PELAGICOM_EXP02=$PWD/Experimento_02 Rscript -e 'devtools::test("pelagicOM")'
```

## Result (pelagicOM 0.1.2, 2026-11-22)

All comparisons use
[`identical()`](https://rdrr.io/r/base/identical.html), i.e. bit-for-bit
equality:

| component | rows | identical | max. abs. difference |
|----|---:|:--:|---:|
| biomass B(y, s) | 10,051 × 76 | TRUE | 0 |
| spatial weights p(y, s) | 10,051 × 76 | TRUE | 0 |
| population B_total(y) | 76 | TRUE | 0 |
| domain cells | 10,051 | TRUE | 0 |
| long table Year x Cell | 763,876 | TRUE | 0 |
| fishery truth (sets) | 1,137,186 | TRUE | 0 |
| vessels | 826 | TRUE | 0 |
| trips | 98,782 | TRUE | 0 |
| vessel effects | 826 | TRUE | 0 |
| scenario 01_global_complete | 1,137,186 | TRUE | 0 |
| scenario 02_global_without_hbf | 1,137,186 | TRUE | 0 |
| scenario 03_R02_complete | 1,021,802 | TRUE | 0 |
| scenario 04_global_temporal_uncertainty | 1,077,246 | TRUE | 0 |
| scenario 05_R02_temporal_uncertainty | 965,163 | TRUE | 0 |
| scenario 06_R01_complete | 72,988 | TRUE | 0 |
| scenario 07_R03_complete | 42,396 | TRUE | 0 |
| scenario 08_R02_without_hbf | 1,021,802 | TRUE | 0 |
| fishery truth from the stored biomass file | 1,137,186 | TRUE | 0 |
| caller RNG stream preserved | 1 | TRUE | 0 |

Two further checks were made:

- Every CSV written by `om_run(dir = ...)` has the same text as the CSV
  of the experiment. This covers 5 biomass tables (population, regional
  summary, centre of gravity, envelope parameters, cells), 4 fishery
  tables (fleets, vessels, trips, vessel effects) and the 17 diagnostic
  tables.
- A simulation that reads the GeoPackage directly
  (`spatial = list(source = "gpkg", gpkg = ...)`) gives the same biomass
  and long table.

Environment of the check: R 4.5.2, sf 1.1.2, lwgeom 0.2.17, GEOS 3.12.1,
GDAL 3.8.4, PROJ 9.4.0, R’s reference BLAS. Biomass and fishery depend
on R’s random number generator and on floating-point arithmetic. An
optimised BLAS (used in the matrix products of the random fields) may
change the last digits. The geometry checks depend on the GEOS / PROJ
versions.
