# Simulates a dataset in the probit model
# Writes two files, one for snph2 and one for twinh2
# Each dataset is a named list with y, gc, and w
########################################################
rm(list = ls())

library(tidyverse)
library(SimMultiCorrData)

set.seed(123)

# Options
n_observations <- 1e5

# Function to simulate dataset for a given summary object
simulate_probit_dataset <- function(summary_object_path, output_path, n_obs = n_observations) {
  cat("Processing:", summary_object_path, "\n")
  
  # Load inputs
  inputs <- readRDS(summary_object_path)
  w <- readRDS("output/simulated_w.rds") |>
      select(-age_assess_i0)
  
  # Select rows
  if (n_obs <= nrow(w)) {
    w <- w[1:n_obs, ]
  } else {
    extra_needed <- n_obs - nrow(w)
    extra_rows <- w[sample(1:nrow(w), extra_needed, replace = TRUE), ]
    w <- rbind(w, extra_rows)
  }
  
  # Validation
  stopifnot(setequal(names(inputs$beta), c("(Intercept)", colnames(w), "gf")))
  stopifnot(setequal(names(inputs$gamma), c("(Intercept)", colnames(w), "gc")))
  stopifnot(setequal(names(inputs$theta), c("(Intercept)", colnames(w))))
  
  # Simulate gf = theta * w + Gaussian noise
  w_with_intercept <- cbind("(Intercept)" = 1, w)
  # Ensure columns match the order of theta parameters
  w_aligned <- w_with_intercept[, names(inputs$theta)]
  gf <- as.matrix(w_aligned) %*% inputs$theta + rnorm(nrow(w), 0, sqrt(inputs$var_v))
  
  # Simulate gc = gf + gaussian noise
  gc <- gf + rnorm(nrow(w), 0, sqrt(inputs$var_epsilon))
  
  # Simulate disease status y
  # Create design matrix with gf and w, ensuring proper alignment
  design_matrix <- cbind("(Intercept)" = 1, w, "gf" = gf)
  design_aligned <- design_matrix[, names(inputs$beta)]
  latent_y <- as.matrix(design_aligned) %*% inputs$beta + rnorm(nrow(w), 0, 1)
  y <- latent_y > 0
  
  # Save simulated dataset
  simulated_dataset <- list(
    y = y,
    gc = gc,
    w = w
  )
  
  saveRDS(simulated_dataset, output_path)
  cat("Saved to:", output_path, "\n")
}

# Process both summary objects
summary_files <- c(
  "input/summary_object_brc_probit_snph2.rds",
  "input/summary_object_brc_probit_twinh2.rds"
)

output_files <- c(
  "output/simulated_dataset_probit_snph2.rds",
  "output/simulated_dataset_probit_twinh2.rds"
)

# Apply simulation to both files
for (i in seq_along(summary_files)) {
  simulate_probit_dataset(summary_files[i], output_files[i])
}

cat("All simulations completed successfully!\n")