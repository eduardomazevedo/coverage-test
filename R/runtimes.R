rm(list = ls())

source("R/run_bootstrap.R")

# Softmax correction fully removed.

model_types <- c("lm", "probit", "cox")
n_obs_vals <- c(1e3, 1e4, 1e5, 1e6)
n_bootstraps <- 10

runtime_results <- list()

for (model_type in model_types) {
  for (n_obs in n_obs_vals) {
    cat(sprintf("Running: model = %s, n_obs = %.0f\n", model_type, n_obs))
    start_time <- Sys.time()
    run_bootstrap(
      model_type = model_type,
      heritability_source = "snph2",
      n_obs = n_obs,
      n_bootstraps = n_bootstraps
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
