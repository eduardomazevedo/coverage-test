# Example usage:
model_type <- "probit"
n_observations <- 10000
n_bootstraps <- 1000  # Increased for better coverage analysis
w_cache <- readRDS("data/simulated_covariates.rds")
params <- readRDS("assets/summary_object_brc_probit_snph2.rds")

# Source required functions
source("R/bootstrap_simulations.R")

# Run bootstrap simulations
bootstrap_results <- bootstrap_simulations(n_observations, n_bootstraps, params, w_cache)

# Generate coverage report
source("R/coverage_report.R")
report <- coverage_report(bootstrap_results, params, "output/plots")

# Access results
print("Bootstrap Results Structure:")
print(str(bootstrap_results$betas))
print(str(bootstrap_results$standard_errors))

print("\nCoverage Report Summary:")
print(report$summary_stats)