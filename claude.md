# UKB-RAP Helpers

Helper scripts for extracting and analysing UK Biobank phenotype data on the DNAnexus Research Analysis Platform.

## UKB-RAP platform

Cloud environment (DNAnexus/AWS eu-west-2) where ~500k-participant UKB data is analysed in place (no download). Projects are tied to approved access applications; only named collaborators can access. Data is dispensed in Parquet format on project creation. Compute environments (RStudio, JupyterLab, Stata) are ephemeral -- session state is lost on termination. Persistent storage is via `dx upload` to the project. Data mount: `/mnt/project/`. Field naming: `p<FIELD>_i<INSTANCE>_a<ARRAY>`. Participants identified by pseudonymised 7-digit EID.

**Data access methods**: `dx extract_dataset` (CLI, scripted extraction), Table Exporter app (Cohort Browser view to CSV/TSV), Spark SQL in JupyterLab (large extractions, linked records like GP/HES/death). For linked records, use named tables (`gp_clinical`, `hesin`, `death`) not versioned variants. Always specify entity when extracting non-participant fields.

## Repository structure

```
code/
  *.sh    Field/category extraction via dx CLI
  *.R     Data filtering, QC, phenotype analysis (tidyverse)
  *.txt   UKB metadata: field definitions, cross-reference tables
```

No formal package structure. Scripts run interactively in RAP RStudio (`~/ukb-rap-helpers/`).

## Conventions

- Shell scripts use `dx` CLI + `.txt` reference files for field/category metadata.
- R scripts assume tidyverse, read data from `/mnt/project/`.
- Fields referenced by RAP column names (e.g. `p20510`, `p22006`).
- Standard UKB genetic QC: genotyped cohort (p22020), White British (p22006), sex concordance (p31 vs p22001), no genetic outliers (p22027).

## Development guidelines

- Scripts: simple, single-purpose, parameterised field/category IDs.
- Batch large extractions (see `get_category_batched.sh`).
- R: tidyverse style, tibbles.
- Never commit data or credentials (`.gitignore` excludes `data/`, `.Renviron`, `.sh_history`).

## Dependencies

- **Bash**: `dx` CLI (RAP-provided), `cut`, `awk`, `grep`, `paste`, `split`.
- **R**: `tidyverse`, `fs`.
