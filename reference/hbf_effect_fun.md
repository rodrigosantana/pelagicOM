# Effect of hooks between floats on log catchability

Saturating effect \\f(h) = a (1 - e^{-b (h - 4)})\\, centred at the
reference HBF: \\f(h) - f(h\_{ref})\\.

## Usage

``` r
hbf_effect_fun(hbf, hp)
```

## Arguments

- hbf:

  Hooks between floats.

- hp:

  List with `effect` (a), `rate` (b) and `ref`.

## Value

Effect on log q.

## Examples

``` r
hbf_effect_fun(4:26, om_fishery_config()$catchability$hbf)
#>  [1] -0.5414260 -0.3742756 -0.2304079 -0.1065798  0.0000000  0.0917341
#>  [7]  0.1706904  0.2386487  0.2971409  0.3474857  0.3908178  0.4281141
#> [13]  0.4602153  0.4878451  0.5116262  0.5320949  0.5497124  0.5648760
#> [19]  0.5779273  0.5891608  0.5988295  0.6071514  0.6143142
```
