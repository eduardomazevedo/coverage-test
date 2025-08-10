# Initialize runtime_results as an empty list
runtime_results <- list()

# Loop over configurations
for (model_type in model_types) {
  for (n_obs in n_obs_vals) {
    if (model_type == "cox") {
      for (softmax_correction in softmax_options) {

        # Skip softmax-slow with 1e6 for cox
        if (n_obs == 1e6 && softmax_correction == "softmax-slow") {
          cat(sprintf("Skipping: model = %s, n_obs = %.0f, softmax = %s (too slow)\n",
                      model_type, n_obs, softmax_correction))
          next
        }

        cat(sprintf("Running: model = %s, n_obs = %.0f, softmax = %s\n",
                    model_type, n_obs, softmax_correction))
        start_time <- Sys.time()
        run_bootstrap(
          model_type = model_type,
          heritability_source = "snph2",
          softmax_correction = softmax_correction,
          n_obs = n_obs,
          n_bootstraps = n_bootstraps
        )
        elapsed <- as.numeric(Sys.time() - start_time, units = "secs")
        runtime_results[[length(runtime_results) + 1]] <- list(
          model_type = model_type,
          n_obs = n_obs,
          softmax_correction = softmax_correction,
          runtime_seconds = elapsed
        )
      }
    } else {
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
        softmax_correction = NA,
        runtime_seconds = elapsed
      )
    }
  }
}

# Convert results to a data frame
runtime_df <- do.call(rbind, lapply(runtime_results, as.data.frame))

# Save to CSV
write.csv(runtime_df, "data/runtimes.csv", row.names = FALSE)
