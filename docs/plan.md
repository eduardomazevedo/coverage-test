# Simulation Coverage Testing Project Plan

This project performs simulation-based coverage testing for our hapr package estimator https://github.com/eduardomazevedo/hapr. The goal is to flexibly run a wide range of simulation designs, evaluate coverage of confidence intervals, and generate organized outputs for reporting and analysis.

This is a plan file of what we will implement.

---

## 📁 Folder Structure

```
sim-coverage/
├── assets/                    # Static data derived from real datasets
│   ├── means_sd_cov_mat.BRC.std.rds    # Means and SD of all covariates
│   ├── summary_object_brc_cox_snph2.rds    # Reference estimates for Cox model (SNP h2)
│   ├── summary_object_brc_cox_twinh2.rds   # Reference estimates for Cox model (twin h2)
│   ├── summary_object_brc_probit_snph2.rds # Reference estimates for probit model (SNP h2)
│   └── summary_object_brc_probit_twinh2.rds # Reference estimates for probit model (twin h2)
│
├── data/
│   ├── covariate_draws.rds    # Large simulated sample of covariates W
│
├── R/                         # Core reusable R functions and scripts
│   ├── simulate_covariates.R
│   ├── simulate_dataset.R
│   ├── bootstrap_simulations.R
│   └── coverage_report.R
│
├── config/                    # Parameterized YAML files for each simulation
│   ├── sim_001.yaml
│   ├── sim_002.yaml
│   └── ...
│
├── experiments/               # Scripts that run specific simulation settings
│   ├── sim_001.R
│   ├── sim_002.R
│   └── ...
│
├── output/                    # Results from each simulation
│   ├── sim_001/
│   │   ├── betas.csv
│   │   ├── summary.yaml
│   │   └── plots/
│   │       ├── beta1_hist.pdf
│   │       └── ...
│   └── sim_002/
│
├── run_all.R                  # Master script to run all config files
├── README.md                  # Project overview and usage instructions
└── DESCRIPTION                # Optional: if creating a minimal R package
```

---

## 🔧 Functional Components and Requirements

### `assets/`
- **Purpose**: Hold reference data from real datasets.
- Files:
  - `covariate_stats.rds`: Contains empirical means, variances, correlations, etc.
  - `parameter_values.rds`: True DGP parameters used for simulation and coverage tests.

---

### `R/`: Core R Functions

#### `simulate_covariates.R` (script)
- This script is intended to be run **once** to generate a large pool of simulated covariates for all downstream simulations.
- Reads summary statistics (means, variances, covariances, etc.) from a reference file (e.g., `assets/covariate_stats.rds`).
- Simulates a large data frame of covariates `W` (e.g., using multivariate normal or appropriate distributions).
- Saves the resulting data frame to `data/covariate_draws.rds` for reuse in all simulation experiments.

#### `simulate_dataset.R`
- Function: `simulate_dataset(n, parameters, w_pool)`
- Inputs:
  - `n`: Number of observations to simulate.
  - `parameters`: DGP parameters.
  - `w_pool`: Covariates drawn (e.g. from `data/covariate_draws.rds`).
- Returns: A full simulated dataset including outcome variables.

#### `bootstrap_simulations.R`
- Function: `bootstrap_simulations(n_obs, n_bootstraps, parameters, w_pool)`
- Logic:
  - Repeatedly simulate datasets using `simulate_dataset()`.
  - Estimate model each time.
  - Collect beta estimates into a tidy data frame: `bootstrap_results$betas`
  - Also save the standard error vector from the **first** estimation.
- Returns: Named list:
  - `betas`: Data frame (rows = bootstraps, columns = parameter names)
  - `se_first`: Named numeric vector of SEs from first iteration

#### `coverage_report.R`
- Function: `coverage_report(bootstrap_results, parameters)`
- Computes:
  - Mean beta estimates.
  - Confidence interval coverage: % of times true value is inside 95% CI.
  - Histograms of beta distributions with vertical lines for true values and CI.
- Output:
  - A named list with summary stats and plots.
  - Plots saved to output folder (if specified).

---

## 🔁 Simulation Configuration and Execution

### `config/sim_XXX.yaml`
Each simulation has a corresponding YAML config file defining:
```yaml
id: sim_001
description: "Baseline simulation with N = 1000"
n_obs: 1000
n_bootstraps: 500
parameters_file: "assets/parameter_values.rds"
covariate_pool_file: "data/covariate_draws.rds"
output_dir: "output/sim_001"
save_plots: true
save_results: true
```

---

### `experiments/sim_XXX.R`
- Each script reads a YAML config and performs the simulation.
- General structure:
  ```r
  cfg <- yaml::read_yaml("config/sim_001.yaml")
  parameters <- readRDS(cfg$parameters_file)
  w_pool <- readRDS(cfg$covariate_pool_file)

  bootstrap_results <- bootstrap_simulations(cfg$n_obs, cfg$n_bootstraps, parameters, w_pool)
  report <- coverage_report(bootstrap_results, parameters)

  if (cfg$save_results) {
    write.csv(bootstrap_results$betas, file.path(cfg$output_dir, "betas.csv"), row.names = FALSE)
    yaml::write_yaml(report$summary_stats, file.path(cfg$output_dir, "summary.yaml"))
  }
  if (cfg$save_plots) {
    # Save ggplots using ggsave
  }
  ```

---

### `run_all.R`
- Automatically loops through all `config/*.yaml` files and runs each experiment.
- Optionally parallelized.

---

## ✅ Next Steps

1. [ ] Set up repository with above structure.
2. [ ] Implement core functions in `R/`.
3. [ ] Create `simulate_covariates.R` and generate `data/covariate_draws.rds`.
4. [ ] Write baseline simulation config: `config/sim_001.yaml`.
5. [ ] Write script: `experiments/sim_001.R`.
6. [ ] Run and inspect output.
7. [ ] Iterate by adding more simulations, parameters, or alternative estimators.

---

## 💡 Notes

- Add a `set.seed()` in each script for reproducibility.
- Use `fs::dir_create()` to ensure output folders are created.
- Consider `targets` or `drake` for orchestration in the future if scaling up.
- Use `ggplot2::theme_minimal()` and consistent color schemes for plots.

---
