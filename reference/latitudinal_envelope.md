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
lat <- seq(-60, 60, 10)
round(exp(latitudinal_envelope(lat, 0, 11, 11)), 3)
#>  [1] 0.000 0.000 0.001 0.024 0.191 0.662 1.000 0.662 0.191 0.024 0.001 0.000
#> [13] 0.000
round(exp(latitudinal_envelope(lat, 30, 8, 10, "abs_latitude")), 3)
#>  [1] 0.011 0.135 0.607 1.000 0.607 0.135 0.001 0.044 0.458 1.000 0.458 0.044
#> [13] 0.001
```
