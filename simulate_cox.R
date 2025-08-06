# Simulates a dataset in the cox model
# Writes two files, one for snph2 and one for twinh2
# Each dataset is a named list with time, status, gc, and w
# Censoring time is uniform between 20 and 80 years
########################################################
rm(list = ls())

library(tidyverse)

set.seed(123)

# Options
n_observations <- 1e5
target_average_hazard <- 0.002

# Define summary objects to process
summary_objects <- c(
    "input/summary_object_brc_cox_snph2.rds",
    "input/summary_object_brc_cox_twinh2.rds"
)

# Function to simulate Cox data for a given summary object
simulate_cox_data <- function(summary_object_path, n_obs = n_observations, target_hazard = target_average_hazard) {
    
    # Extract model type from filename for output naming
    model_type <- str_extract(basename(summary_object_path), "(snph2|twinh2)")
    output_path <- paste0("output/simulated_dataset_brc_cox_", model_type, ".rds")
    
    cat("Processing:", basename(summary_object_path), "\n")
    
    # Load inputs
    inputs <- readRDS(summary_object_path)
    w <- readRDS("output/simulated_w.rds") |>
        select(-age_assess_i0, -age_last_obs)
    
    # Select rows
    if (n_obs <= nrow(w)) {
        w <- w[1:n_obs, ]
    } else {
        extra_needed <- n_obs - nrow(w)
        extra_rows <- w[sample(1:nrow(w), extra_needed, replace = TRUE), ]
        w <- rbind(w, extra_rows)
    }
    
    # Validation
    stopifnot(setequal(names(inputs$beta), c(colnames(w), "gf")))
    stopifnot(setequal(names(inputs$gamma), c(colnames(w), "gc")))
    stopifnot(setequal(names(inputs$theta), c("(Intercept)", colnames(w))))
    
    # Simulate gf = theta * w + Gaussian noise
    w_with_intercept <- cbind("(Intercept)" = 1, w)
    # Ensure columns match the order of theta parameters
    w_aligned <- w_with_intercept[, names(inputs$theta)]
    gf <- as.matrix(w_aligned) %*% inputs$theta + rnorm(nrow(w), 0, sqrt(inputs$var_v))
    
    # Simulate gc = gf + gaussian noise
    gc <- gf + rnorm(nrow(w), 0, sqrt(inputs$var_epsilon))
    
    # Calculate relative risk (hazard ratio)
    design_matrix <- cbind("(Intercept)" = 1, w, "gf" = gf)
    design_aligned <- design_matrix[, names(inputs$beta)]
    linear_predictor <- as.matrix(design_aligned) %*% inputs$beta
    relative_risk <- exp(linear_predictor)
    
    # Calculate base rate to match target average hazard
    base_rate <- target_hazard / mean(relative_risk)
    
    # Simulate censoring time uniform between 20 and 80 years
    censoring_time <- runif(nrow(w), 20, 80)
    
    # Simulate survival time
    survival_time <- rexp(nrow(w), base_rate * relative_risk)
    
    # Combine survival time and censoring time
    time <- pmin(survival_time, censoring_time)
    status <- (survival_time <= censoring_time)
    
    # Create simulated dataset
    simulated_dataset <- list(
        time = time,
        status = status,
        gc = gc,
        w = w
    )
    
    # Save results
    saveRDS(simulated_dataset, output_path)
    cat("Saved to:", output_path, "\n")
    
    # Return summary statistics
    return(list(
        model_type = model_type,
        n_observations = nrow(w),
        mean_relative_risk = mean(relative_risk),
        mean_hazard = mean(base_rate * relative_risk),
        event_probability = mean(status),
        mean_survival_time = mean(time)
    ))
}

# Process all summary objects
results <- list()
for (summary_path in summary_objects) {
    if (file.exists(summary_path)) {
        result <- simulate_cox_data(summary_path)
        results[[basename(summary_path)]] <- result
    } else {
        cat("Warning: File not found:", summary_path, "\n")
    }
}

# Print summary of results
cat("\n=== Simulation Summary ===\n")
for (i in seq_along(results)) {
    result <- results[[i]]
    cat("\nModel:", result$model_type, "\n")
    cat("  Observations:", result$n_observations, "\n")
    cat("  Mean relative risk:", round(result$mean_relative_risk, 4), "\n")
    cat("  Mean hazard:", round(result$mean_hazard, 6), "\n")
    cat("  Event probability:", round(result$event_probability, 3), "\n")
    cat("  Mean survival time:", round(result$mean_survival_time, 2), "years\n")
}