# Biomass (Part I) configuration

Returns the full list of parameters that controls the spatio-temporal
biomass operating truth. The `"BET_ICCAT"` preset is the configuration
used in Experimento 02 (bigeye tuna, ICCAT BET-A stock area, 1950-2025,
seed 20261005) and reproduces its results exactly.

## Usage

``` r
om_biomass_config(preset = "BET_ICCAT", ...)

validate_biomass_config(cfg)
```

## Arguments

- preset:

  Name of a preset (see
  [`om_presets()`](https://rodrigosantana.github.io/pelagicOM/reference/om_presets.md)).

- ...:

  Optional named sections that override the preset, passed to
  [`om_config_update()`](https://rodrigosantana.github.io/pelagicOM/reference/om_config_update.md)
  (e.g. `population = list(r = 0.4)`).

- cfg:

  A biomass configuration.

## Value

A list of class `om_biomass_config`.

## Details

The list has the sections

- general:

  `label`, `seed`.

- temporal:

  `year_start`, `year_end`.

- spatial:

  source of the spatial domain (`source = "iccat"` for the 1x1 ICCAT
  grid bundled with the package, `"gpkg"` to read a GeoPackage, read by
  [`om_domain_from_gpkg()`](https://rodrigosantana.github.io/pelagicOM/reference/om_domain_from_gpkg.md)
  with geodesic areas from `lwgeom`), the stock area (`stock_code`,
  `selection`), and the latitudinal regions (`region_breaks`, ascending;
  `region_labels`, ordered from north to south, one more than the
  breaks).

- population:

  Pella-Tomlinson surplus production with an exogenous removal rate u(y)
  drawn by phases (`u_base`, `decline`, `recovery`), AR(1) process
  error, optional shocks (`events`) and a trend in carrying capacity
  (`K_trend`). `model` may also be a function `f(B, K, r, shape)`
  returning the surplus production.

- habitat:

  static log-density: latitudinal envelope
  (`envelope_type = "latitude"`: Gaussian on signed latitude, the
  tropical core of Experimento 02; `"abs_latitude"`: Gaussian on
  absolute latitude, i.e. one band per hemisphere, for temperate
  species), Gaussian `hotspots`, longitudinal gradient, persistent
  random field (`field_sd`, `field_range`) and an optional
  `custom_effect = function(cells)` returning a log-scale vector.

- shift:

  poleward redistribution: expansion of the envelope standard
  deviations, drift of its centre and equatorial contraction along a
  ramp between `start` and `end`.

- stochastic:

  spatio-temporal AR(1) noise on Gaussian fields.

- output:

  what
  [`om_write_biomass()`](https://rodrigosantana.github.io/pelagicOM/reference/om_write_biomass.md)
  saves and figure settings.

## Functions

- `validate_biomass_config()`: Checks the internal coherence of a
  biomass configuration (stops with an explicit message).

## See also

[`om_fishery_config()`](https://rodrigosantana.github.io/pelagicOM/reference/om_fishery_config.md),
[`om_config_update()`](https://rodrigosantana.github.io/pelagicOM/reference/om_config_update.md),
[`simulate_biomass()`](https://rodrigosantana.github.io/pelagicOM/reference/simulate_biomass.md).

## Examples

``` r
cfg <- om_biomass_config("BET_ICCAT")
cfg$population$r
#> [1] 0.3
cfg2 <- om_biomass_config("BET_ICCAT", population = list(r = 0.45),
                          shift = list(enabled = FALSE))
cfg2$population$r
#> [1] 0.45
```
