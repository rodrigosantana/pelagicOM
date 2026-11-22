# Compare a run with reference outputs

Compares the objects of a run (biomass matrix, population series, long
table, cells, fishery truth and scenario data sets) with the files of a
reference folder laid out as Experimento 02 (or as written by
[`om_run()`](https://rodrigosantana.github.io/pelagicOM/reference/om_run.md)
with `dir`). `identical` means bit-for-bit equality
([`base::identical()`](https://rdrr.io/r/base/identical.html));
`max_abs_diff` is the largest absolute difference over numeric columns.

## Usage

``` r
om_compare_reference(run, ref_dir, label = "base")
```

## Arguments

- run:

  An `om_run` object, or a list with `biomass`, `fishery` and
  `scenarios` (any of them may be `NULL`).

- ref_dir:

  Reference folder containing `Simulacao_Biomassa/` and
  `Simulacao_Pesca/` (e.g. the `Experimento_02` folder).

- label:

  Label of the reference files.

## Value

A data frame with one row per compared component (`component`,
`identical`, `max_abs_diff`, `n_rows`, `file`).

## Examples

``` r
if (FALSE) { # \dontrun{
run <- om_run("BET_ICCAT", verbose = FALSE)
om_compare_reference(run, "R-Work/Experimento_02")
} # }
```
