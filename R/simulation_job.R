# Job script to run simulations across sample sizes and parameter sets

# Load required source files (follow sample syntax from `scratch.R`)
source("R/bootstrap_simulations.R")
source("R/coverage_report.R")
source("R/simulate_cox.R")
source("R/simulate_probit.R")

# Discover parameter files
assets_dir <- "assets"
param_files <- list.files(
  path = assets_dir,
  pattern = "^summary_object_.*\\.rds$",
  full.names = TRUE
)

if (length(param_files) == 0) {
  stop("No parameter files found in assets/. Expected files named like 'summary_object_*.rds'.")
}

# Load covariate cache
w_cache <- readRDS("data/simulated_covariates.rds")

# Configuration
n_bootstraps <- 1000L
sample_sizes <- c(1e3, 1e4, 1e5, 1e6)

# Ensure base output directory exists
base_output_dir <- "output"
if (!dir.exists(base_output_dir)) {
  dir.create(base_output_dir, recursive = TRUE)
}

# Iterate over sample sizes and parameter sets
for (n_obs in sample_sizes) {
  for (param_path in param_files) {
    params <- readRDS(param_path)
    param_basename <- tools::file_path_sans_ext(basename(param_path))

    message(sprintf("Starting parameter set: %s (n = %s)", param_basename, format(n_obs, scientific = FALSE, trim = TRUE)))

    if (identical(params$model_type, "cox")) {
      # For Cox, run all three softmax correction variants
      correction_variants <- c("clt", "softmax-slow", "softmax-fast")
      for (corr in correction_variants) {
        # Organized output directory: output/<param_basename>/n_<size>/softmax_<corr>/
        out_dir <- file.path(
          base_output_dir,
          param_basename,
          paste0("n_", format(n_obs, scientific = FALSE, trim = TRUE)),
          paste0("softmax_", corr)
        )

        if (dir.exists(out_dir)) {
          message(sprintf("  - Skipping: results directory already exists (%s)", out_dir))
          next
        }

        dir.create(out_dir, recursive = TRUE)

        message(sprintf("  - Running with %s bootstraps (softmax_correction = %s)", n_bootstraps, corr))

        bootstrap_results <- bootstrap_simulations(
          n_obs = n_obs,
          n_bootstraps = n_bootstraps,
          parameters = params,
          w_pool = w_cache,
          softmax_correction = corr
        )

        # Persist raw bootstrap results for reproducibility
        saveRDS(bootstrap_results, file.path(out_dir, "bootstrap_results.rds"))

        # Generate and save coverage report (plots + summary CSV)
        report <- coverage_report(
          bootstrap_results = bootstrap_results,
          parameters = params,
          output_folder = out_dir
        )

        # Optionally also save the summary stats as an RDS for easy re-load in R
        saveRDS(report$summary_stats, file.path(out_dir, "summary_stats.rds"))

        message(sprintf(
          "    Completed: %s (n = %s, softmax_correction = %s)",
          param_basename,
          format(n_obs, scientific = FALSE, trim = TRUE),
          corr
        ))
      }
    } else {
      # Non-Cox models: behavior unchanged
      out_dir <- file.path(base_output_dir, param_basename, paste0("n_", format(n_obs, scientific = FALSE, trim = TRUE)))
      if (dir.exists(out_dir)) {
        message(sprintf("  - Skipping: results directory already exists (%s)", out_dir))
        next
      }

      dir.create(out_dir, recursive = TRUE)

      message(sprintf("  - Running with %s bootstraps", n_bootstraps))

      bootstrap_results <- bootstrap_simulations(
        n_obs = n_obs,
        n_bootstraps = n_bootstraps,
        parameters = params,
        w_pool = w_cache
      )

      # Persist raw bootstrap results for reproducibility
      saveRDS(bootstrap_results, file.path(out_dir, "bootstrap_results.rds"))

      # Generate and save coverage report (plots + summary CSV)
      report <- coverage_report(
        bootstrap_results = bootstrap_results,
        parameters = params,
        output_folder = out_dir
      )

      # Optionally also save the summary stats as an RDS for easy re-load in R
      saveRDS(report$summary_stats, file.path(out_dir, "summary_stats.rds"))

      message(sprintf("    Completed: %s (n = %s)", param_basename, format(n_obs, scientific = FALSE, trim = TRUE)))
    }
  }
}

message("All simulation jobs completed.")
