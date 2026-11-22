# Gaussian random field on the regular lattice

Smooths white noise with a separable Gaussian kernel, \\F = K_r Z
K_c^\top\\, and normalises cell by cell so that every lattice cell has
marginal standard deviation exactly `sd`. This is the spatial building
block of the persistent habitat field, of the spatio-temporal noise and
of the spatial catchability field.

## Usage

``` r
gaussian_random_field(lattice, range, sd)
```

## Arguments

- lattice:

  List with `n_row` and `n_col` (see
  [`om_domain_iccat()`](https://rodrigosantana.github.io/pelagicOM/reference/om_domain_iccat.md)).

- range:

  Standard deviation of the kernel, in lattice cells (degrees for a
  1-degree grid).

- sd:

  Marginal standard deviation (log scale).

## Value

Matrix `n_row x n_col`.
