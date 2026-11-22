# Reference points of the production model

Exact Bmsy and MSY for the Pella-Tomlinson and logistic models;
numerical search for a user-supplied production function.

## Usage

``` r
reference_points(pp)
```

## Arguments

- pp:

  The `population` section of a biomass configuration.

## Value

List with `K`, `r`, `shape`, `Bmsy`, `MSY`, `umsy`.

## Examples

``` r
reference_points(om_biomass_config()$population)
#> $K
#> [1] 1e+06
#> 
#> $r
#> [1] 0.3
#> 
#> $shape
#> [1] 1
#> 
#> $Bmsy
#> [1] 5e+05
#> 
#> $MSY
#> [1] 75000
#> 
#> $umsy
#> [1] 0.15
#> 
```
