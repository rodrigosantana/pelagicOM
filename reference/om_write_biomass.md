# Write the biomass outputs

Saves the biomass truth with the files and names of Experimento 02
(`outputs/data/` and `outputs/figures/` inside `dir`): the full object
(`biomass_true_<label>.rds`), the long table (`.csv.gz`), population,
regional summary, centre of gravity, envelope parameters, cells and
configuration, plus the eight figures.

## Usage

``` r
om_write_biomass(
  sim,
  dir,
  label = sim$cfg$general$label,
  rds = sim$cfg$output$save_rds,
  csv = sim$cfg$output$save_csv,
  figures = sim$cfg$output$save_figures,
  verbose = TRUE
)
```

## Arguments

- sim:

  An `om_biomass` object.

- dir:

  Folder playing the role of `Simulacao_Biomassa/`.

- label:

  Label of the files (default `cfg$general$label`).

- rds, csv, figures:

  What to write (defaults from `cfg$output`).

- verbose:

  Print the file names.

## Value

Invisible character vector of written files.
