rm(list = ls())

source("R/run_bootstrap.R")
source("R/coverage_report.R")

n_obs <- 1e5
n_bootstraps <- 1e0

start_time <- Sys.time()
bootstrap_results <- run_bootstrap(
  model_type = "cox",
  heritability_source = "snph2",
  softmax_correction = "softmax-slow",
  n_obs = n_obs,
  n_bootstraps = n_bootstraps
)
end_time <- Sys.time()
elapsed_time <- end_time - start_time
print(sprintf("Bootstrap simulations took %.2f seconds.", as.numeric(elapsed_time, units = "secs")))

# report <- coverage_report(
#   bootstrap_results = bootstrap_results,
#   output_folder = "output/scratch"
# )
