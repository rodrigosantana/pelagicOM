# Latitudinal envelope (log scale)

Latitudinal envelope (log scale)

## Usage

``` r
latitudinal_envelope(lat, center, sd_north, sd_south, type = "latitude")
```

## Arguments

- lat:

  Latitudes.

- center:

  Centre of the envelope (signed latitude for `type = "latitude"`,
  absolute latitude for `type = "abs_latitude"`).

- sd_north, sd_south:

  Standard deviations north / south of the centre (`"latitude"`) or in
  the northern / southern hemisphere (`"abs_latitude"`).

- type:

  `"latitude"` or `"abs_latitude"`.

## Value

Log-scale envelope (0 at the centre).

## Examples

``` r
## BET envelope in 1950 (sd 11) and in 2025 (sd 11 x 1.7, poleward
## expansion of Experimento 02)
lat <- seq(-60, 60, 10)
round(exp(latitudinal_envelope(lat, 0, 11, 11)), 3)
#>  [1] 0.000 0.000 0.001 0.024 0.191 0.662 1.000 0.662 0.191 0.024 0.001 0.000
#> [13] 0.000
round(exp(latitudinal_envelope(lat, 0, 18.7, 18.7)), 3)
#>  [1] 0.006 0.028 0.101 0.276 0.564 0.867 1.000 0.867 0.564 0.276 0.101 0.028
#> [13] 0.006
```
