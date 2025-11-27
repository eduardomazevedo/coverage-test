rm(list = ls())

source("R/get_params.R")
source("R/run_bootstrap.R")

# Softmax correction fully removed.

model_types <- c("lm", "probit", "cox")
n_obs_vals <- c(1e3, 1e4, 1e5, 1e6)
n_bootstraps <- 10

runtime_results <- list()

for (model_type in model_types) {
  # Load parameters once per model type
  params <- get_params(model_type, "snph2")
  
  for (n_obs in n_obs_vals) {
    cat(sprintf("Running: model = %s, n_obs = %.0f\n", model_type, n_obs))
    start_time <- Sys.time()
    run_bootstrap(
      n_obs = n_obs,
      n_bootstraps = n_bootstraps,
      params = params
    )
    elapsed <- as.numeric(Sys.time() - start_time, units = "secs")
    runtime_results[[length(runtime_results) + 1]] <- list(
      model_type = model_type,
      n_obs = n_obs,
      runtime_per_bs = elapsed / n_bootstraps,
      total_runtime = elapsed
    )
  }
}

runtime_df <- do.call(rbind, lapply(runtime_results, as.data.frame))
write.csv(runtime_df, "data/runtimes.csv", row.names = FALSE)
cat("Runtime benchmarking complete. Results written to data/runtimes.csv\n")
