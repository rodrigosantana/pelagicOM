# pelagicOM: spatio-temporal operating model for pelagic stocks and longline fisheries

`pelagicOM` packages the simulation components of Experimento 02
(workshop tRFMO CPUE, 2026) so that they can be rerun, tuned and reused
for other species and distributions.

## Workflow


    bcfg <- om_biomass_config("BET_ICCAT")     # Part I parameters
    fcfg <- om_fishery_config("BET_ICCAT")     # Part II parameters
    sim  <- simulate_biomass(bcfg)             # B(y, s), cells x years
    fish <- simulate_fishery(sim, fcfg)        # set-by-set fishery truth
    scen <- generate_scenarios(fish)           # observed data sets
    om_write_biomass(sim, "out/Simulacao_Biomassa")
    om_write_fishery(fish, scen, "out/Simulacao_Pesca")

or simply `om_run("BET_ICCAT", dir = "out")`.

## Tuning

Every parameter lives in the two configuration lists; change them with
[`om_config_update()`](https://rodrigosantana.github.io/pelagicOM/reference/om_config_update.md)
(or the `...` of
[`om_biomass_config()`](https://rodrigosantana.github.io/pelagicOM/reference/om_biomass_config.md)
/
[`om_fishery_config()`](https://rodrigosantana.github.io/pelagicOM/reference/om_fishery_config.md)).
The spatial domain can be any ICCAT stock area
([`om_domain_iccat()`](https://rodrigosantana.github.io/pelagicOM/reference/om_domain_iccat.md),
[`iccat_stocks()`](https://rodrigosantana.github.io/pelagicOM/reference/iccat_stocks.md)),
an ICCAT-like GeoPackage
([`om_domain_from_gpkg()`](https://rodrigosantana.github.io/pelagicOM/reference/om_domain_from_gpkg.md))
or a synthetic grid
([`om_domain_grid()`](https://rodrigosantana.github.io/pelagicOM/reference/om_domain_grid.md));
regions are free latitudinal bands
([`classify_regions()`](https://rodrigosantana.github.io/pelagicOM/reference/classify_regions.md)).

## Reproducibility

Each stochastic component has its own seed; simulations never change the
caller's random stream.
[`om_compare_reference()`](https://rodrigosantana.github.io/pelagicOM/reference/om_compare_reference.md)
checks a run against the reference files of Experimento 02.

## See also

Useful links:

- <https://rodrigosantana.github.io/pelagicOM/>

- <https://github.com/rodrigosantana/pelagicOM>

- Report bugs at <https://github.com/rodrigosantana/pelagicOM/issues>

## Author

**Maintainer**: Rodrigo Sant'Ana <rsantana@univali.br>

Authors:

- Rodrigo Sant'Ana <rsantana@univali.br>
