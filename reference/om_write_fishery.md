# Write the fishery outputs

Saves the fishery truth, the scenario data sets, the diagnostic tables
and the figures with the files and names of Experimento 02
(`outputs/truth/`, `outputs/datasets/`, `outputs/diagnostics/`,
`outputs/figures/` inside `dir`).

## Usage

``` r
om_write_fishery(
  fishery,
  scenarios = NULL,
  dir,
  label = fishery$cfg$general$label,
  csv = fishery$cfg$output$save_csv,
  diagnostics = TRUE,
  figures = fishery$cfg$output$save_figures,
  verbose = TRUE
)
```

## Arguments

- fishery:

  An `om_fishery` object.

- scenarios:

  An `om_scenarios` object (or `NULL`).

- dir:

  Folder playing the role of `Simulacao_Pesca/`.

- label:

  Label of the files (default `cfg$general$label`).

- csv:

  Also write `.csv.gz` copies of the large tables.

- diagnostics, figures:

  Write diagnostic tables / figures.

- verbose:

  Print progress.

## Value

Invisible character vector of written files.
