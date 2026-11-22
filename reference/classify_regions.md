# Latitudinal regions

Classifies latitudes into bands. With `breaks = c(-20, 20)` and
`labels = c("R01", "R02", "R03")` this is the rule of Experimento 02:
R01 when lat \> 20, R03 when lat \< -20 and R02 otherwise (both limits
inclusive). In general, the southernmost and northernmost bands are open
and every interior band is closed at its southern limit (the
northernmost interior band is closed at both limits).

## Usage

``` r
classify_regions(lat, breaks = c(-20, 20), labels = c("R01", "R02", "R03"))
```

## Arguments

- lat:

  Numeric vector of latitudes.

- breaks:

  Ascending latitude limits (may be empty: one region).

- labels:

  Region labels ordered from NORTH to SOUTH; `length(breaks) + 1`
  elements.

## Value

Factor with levels `labels`.

## Examples

``` r
classify_regions(c(-35, -20, 0, 20, 35))
#> [1] R03 R02 R02 R02 R01
#> Levels: R01 R02 R03
classify_regions(c(-35, 0, 35), breaks = 0, labels = c("North", "South"))
#> [1] South South North
#> Levels: North South
```
