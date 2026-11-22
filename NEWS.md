# pelagicOM 0.1.2 (2026-11-22)

* Package website (pkgdown) at <https://rodrigosantana.github.io/pelagicOM/>,
  built and deployed to GitHub Pages by a GitHub Actions workflow. Eight
  articles cover the spatial domain, Part I (biomass), Part II (fishery), the
  observation process and scenarios, tuning, outputs and
  data dictionary, every parameter (generated from the preset) and the proof
  of reproduction of Experimento 02.
* `sf` is now imported in the NAMESPACE, so its methods are available as soon
  as pelagicOM is loaded. Before this, the bundled cell polygons (read with
  `readRDS()`) could be handled as plain data frames, and `fig_maps()` /
  `fig_base_habitat()` failed in a fresh session where no `sf` function had
  been called yet.
* `strategy_recovery_diagnostic()` silences the harmless "Quick-TRANSfer"
  warning of `kmeans()`; its results do not change.
* All examples (README, vignette, articles, help pages) are based on BET
  and keep the structure of Experimento 02: the BET-A area with its three
  regions (R01, R02, R03), the five fleets A-E and the eight scenarios; no
  example removes or adds fleets. The complete tuning example is an alternative BET operating model that changes
  only parameter values (productivity, northward redistribution, creep).
* The map of ICCAT stock areas (article "Spatial domain") now draws one panel
  per species, with each stock area labelled on the map. In the old
  facetted layout the east and west areas of a species (e.g. SKJ-E / SKJ-W)
  looked swapped.

# pelagicOM 0.1.1 (2026-11-22)

* `lwgeom` and `sf` are now required (Imports). Every cell area is geodesic
  on the WGS84 ellipsoid, computed by `lwgeom::st_geod_area()` through the
  new exported helper `geodesic_area_km2()`. This is exactly the computation
  of Experimento 02 (`sf::st_area()` with s2 off).
* `om_domain_from_gpkg()` uses `lwgeom` explicitly and, with the defaults,
  rebuilds the Experimento 02 domain from `ICCAT_gis.gpkg` with identical
  cells, lattice and polygons. New argument `selection`: `"intersects"`
  (Experimento 02) or `"point_on_surface"` (same cells as
  `om_domain_iccat()` for smaller stock areas); also available as
  `cfg$spatial$selection`.
* `om_domain_grid()` now uses geodesic (ellipsoidal) areas instead of the
  spherical formula, so open-ocean cells have the same area as in the
  ICCAT grid.
* The bundled ICCAT grid (`inst/extdata`) is now built from the GeoPackage
  by `om_domain_from_gpkg()` (`data-raw/build_iccat_grid.R`), with a
  check against the saved domain of Experimento 02. Its content is
  unchanged.
* Maps and domains attach the cell geometry by default (`geometry = TRUE`).

# pelagicOM 0.1.0 (2026-11-22)

* First version, built from the simulation components of Experimento 02
  (`Simulacao_Biomassa/` and `Simulacao_Pesca/`).
* `BET_ICCAT` preset: reproduces bit for bit the biomass truth, the fishery
  truth and the eight scenario data sets of Experimento 02
  (`inst/scripts/reproduce_experimento02.R`, `om_compare_reference()`).
* Bundled ICCAT 1x1 grid with 24 stock areas (`om_domain_iccat()`,
  `iccat_stocks()`); GeoPackage reader (`om_domain_from_gpkg()`) and
  synthetic grids (`om_domain_grid()`).
* Generalisations with neutral defaults: free latitudinal regions, envelope
  on absolute latitude (temperate species), user habitat layers
  (`habitat$custom_effect`), any number and names of fleets (`om_fleet()`),
  configurable drifting strategy, `om_config_update()`.
* Simulations no longer change the caller's random number stream.
