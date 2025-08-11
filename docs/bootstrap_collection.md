# Bootstrap Collection Script

## Overview

The `collect_bootstraps.R` script collects and combines bootstrap results from multiple computational chunks into consolidated results for each unique specification.

## What it does

The script:

1. **Reads job specifications** from `assets/list_of_jobs.yaml`
2. **Groups jobs by specification** (model_type, n_obs, softmax_correction)
3. **Combines results** from multiple chunks for each specification:
   - **Stacks** `beta_df` and `se_df` (adds rows from all chunks)
   - **Averages** `psi_estimates` and `alpha_estimates` (for cox models)
   - **Sums** `n_obs` across all chunks
   - **Sums** `n_bootstraps` across all chunks
4. **Saves results** in two formats:
   - Individual specification files: `data/bootstrap_combined_{spec_key}.rds`
   - All specifications combined: `data/bootstrap_all_combined.rds`

## Usage

```bash
Rscript R/collect_bootstraps.R
```

## Output Structure

Each combined specification file contains:

```r
list(
  model_type = "cox",                    # Model type
  heritability_source = "snph2",         # Heritability source
  softmax_correction = "clt",           # Softmax correction method
  n_obs = 600000,                       # Total observations (summed)
  n_bootstraps = 1002,                  # Total bootstraps (summed)
  true_beta = c(...),                   # True beta values
  betas_df = data.frame(...),           # All beta estimates (stacked)
  se_df = data.frame(...),              # All SE estimates (stacked)
  psi_estimates = matrix(...),          # Averaged psi estimates (cox only)
  alpha_estimates = matrix(...)         # Averaged alpha estimates (cox only)
)
```

## Key Features

- **Automatic grouping**: Jobs are automatically grouped by specification
- **Sequential numbering**: Bootstrap IDs are renumbered to be sequential (1, 2, 3, ...)
- **Missing file handling**: Gracefully handles missing bootstrap files
- **Progress reporting**: Shows progress and file locations during processing
- **Summary output**: Provides summary of all combined results

## Example Output

```
Loading job specifications...
Found 19 unique specifications

Processing specification 1 of 19 : cox_1000000_clt
Collecting results for spec: cox_1000000_clt
  Warning: File not found for job 232
  ...
  Saved to: data/bootstrap_combined_cox_1000000_clt.rds

...

All combined results saved to: data/bootstrap_all_combined.rds

Summary of combined results:
  cox_1000000_clt: 0 bootstraps, 0 observations
  cox_1000000_softmax-fast: 0 bootstraps, 0 observations
  cox_100000_clt: 1002 bootstraps, 600000 observations
  ...
```

## Notes

- Specifications with 0 bootstraps/observations indicate that the corresponding jobs haven't been run yet
- The script assumes all jobs use `heritability_source = "snph2"`
- Files are saved in RDS format for efficient storage and loading
- The script can be run multiple times to update results as new bootstrap chunks become available
