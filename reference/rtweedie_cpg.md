# Tweedie random draws (compound Poisson-Gamma)

Draws from a Tweedie distribution with mean `mu`, power `p` (1 \< p \<
2) and dispersion `phi` (Var = phi mu^p) through its compound
Poisson-Gamma representation, without external dependencies.

## Usage

``` r
rtweedie_cpg(mu, p, phi)
```

## Arguments

- mu:

  Vector of means.

- p:

  Power parameter.

- phi:

  Dispersion.

## Value

Numeric vector (with exact zeros).

## Examples

``` r
set.seed(1)
x <- rtweedie_cpg(rep(0.5, 1e4), 1.4, 1)
c(mean = mean(x), prop_zero = mean(x == 0))
#>      mean prop_zero 
#> 0.5067768 0.3319000 
```
