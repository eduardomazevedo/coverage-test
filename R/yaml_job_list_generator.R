#!/usr/bin/env Rscript

# =============================================================================
# YAML Job List Generator for Bootstrap Simulations
# =============================================================================
#
# This script generates a list of jobs for bootstrap simulations
# based on runtime data and predefined simulation parameters. It creates a YAML
# file that can be used by array job systems to distribute computational work.
#
# Usage: Rscript R/yaml_job_list_generator.R
# Output: assets/list_of_jobs.yaml
#
# =============================================================================

# Load libraries
suppressPackageStartupMessages({
  library(yaml)
  library(tidyverse)
})

# Load runtime data
runtimes <- read_csv("data/runtimes.csv", show_col_types = FALSE)

# Helper to compute divisors of 1000
divisors <- function(n) {
  which(n %% 1:n == 0)
}

# Precompute chunk sizes based on runtime estimates
chunk_size_table <-
  runtimes |>
  mutate(
    max_chunk_size = floor((30 * 60) / runtime_seconds),
    chunk_size = map_int(max_chunk_size, \(mcs) {
      valid_divisors <- Filter(\(x) x <= mcs, divisors(1000))
      if (length(valid_divisors) == 0) 1 else max(valid_divisors)
    })
  ) |>
  select(model_type, softmax_correction, n_obs, chunk_size)

# Define simulation parameters
simulation_params <- list(
  lm = list(
    n_obs = c(1000, 10000, 100000, 1000000),
    n_bootstraps = 1000,
    softmax_correction = NA,
    heritability_source = c("snph2", "twinh2")
  ),
  probit = list(
    n_obs = c(1000, 10000, 100000, 1000000),
    n_bootstraps = 1000,
    softmax_correction = NA,
    heritability_source = c("snph2", "twinh2")
  ),
  cox = list(
    n_obs = c(1000, 10000, 100000, 1000000),
    n_bootstraps = 1000,
    softmax_correction = c("clt", "softmax-fast", "softmax-slow"),
    heritability_source = c("snph2", "twinh2")
  )
)

# Function to create job chunks using chunk_size_table
create_job_chunks <- function(model_type, n_obs, n_bootstraps, softmax_correction, heritability_source) {
  match <- chunk_size_table |>
    filter(
      model_type == !!model_type,
      n_obs == !!n_obs,
      # BUG FIX: previously compared softmax_correction to itself, always true.
      (is.na(softmax_correction) & is.na(!!softmax_correction)) |
      (softmax_correction == !!softmax_correction)
    )

  if (nrow(match) == 0) {
    warning("Skipping: no chunk size found for ", model_type,
            ", n_obs = ", n_obs,
            ", softmax_correction = ", softmax_correction)
    return(list())
  }

  chunk_size <- match$chunk_size[1]

  # BUG FIX: Previously used precomputed total_chunks = 1000 / chunk_size
  # without enforcing that total sum of n_bootstraps equals 1000.
  total_chunks <- floor(n_bootstraps / chunk_size)
  remainder <- n_bootstraps %% chunk_size

  chunk_sizes <- rep(chunk_size, total_chunks)
  if (remainder > 0) {
    chunk_sizes <- c(chunk_sizes, remainder)
    total_chunks <- total_chunks + 1
  }

  chunks <- map2(seq_along(chunk_sizes), chunk_sizes, function(i, this_chunk_size) {
    list(
      model_type = model_type,
      n_obs = n_obs,
      n_bootstraps = this_chunk_size,
      softmax_correction = if (is.na(softmax_correction)) NULL else softmax_correction,
      heritability_source = heritability_source,
      chunk_id = i,
      total_chunks = total_chunks
    )
  })

  return(chunks)
}

# Generate all jobs
cat("Generating job list...\n")
all_jobs <- list()

for (model_type in names(simulation_params)) {
  params <- simulation_params[[model_type]]

  for (n_obs in params$n_obs) {
    if (is.na(params$softmax_correction[1])) {
      # lm, probit
      for (hs in params$heritability_source) {
        jobs <- create_job_chunks(
          model_type = model_type,
          n_obs = n_obs,
          n_bootstraps = params$n_bootstraps,
          softmax_correction = params$softmax_correction,
          heritability_source = hs
        )
        all_jobs <- c(all_jobs, jobs)
      }
    } else {
      # cox
      for (softmax_correction in params$softmax_correction) {
        for (hs in params$heritability_source) {
          if (n_obs == 1e6 && softmax_correction == "softmax-slow") {
            cat("Skipping spec: ", model_type, ", n_obs = ", n_obs,
                ", softmax_correction = ", softmax_correction, "\n")
            next
          }

          jobs <- create_job_chunks(
            model_type = model_type,
            n_obs = n_obs,
            n_bootstraps = params$n_bootstraps,
            softmax_correction = softmax_correction,
            heritability_source = hs
          )
          all_jobs <- c(all_jobs, jobs)
        }
      }
    }
  }
}

# Create YAML structure
yaml_data <- list(jobs = all_jobs)

# Write YAML file
output_file <- "assets/list_of_jobs.yaml"
cat("Writing YAML file to", output_file, "...\n")
write_yaml(yaml_data, output_file)

# Print summary
cat("\nJob generation complete!\n")
cat("Total jobs:", length(all_jobs), "\n")
cat("Models:", paste(unique(sapply(all_jobs, \(x) x$model_type)), collapse = ", "), "\n")
cat("Sample sizes:", paste(unique(sapply(all_jobs, \(x) x$n_obs)), collapse = ", "), "\n")

# Show chunking summary
chunk_summary <- bind_rows(all_jobs) %>%
  group_by(model_type, n_obs, softmax_correction, heritability_source) %>%
  summarise(
    total_chunks = max(chunk_id),
    total_bootstraps = sum(n_bootstraps),
    .groups = "drop"
  )

cat("\nChunking summary:\n")
print(chunk_summary)

# ✅ SANITY CHECK: Warn if any spec doesn't sum to exactly 1000 bootstraps
check_failed <- chunk_summary |>
  filter(total_bootstraps != 1000)

if (nrow(check_failed) > 0) {
  cat("\n❌ WARNING: The following specs have total_bootstraps != 1000:\n")
  print(check_failed)
  stop("Invalid job configuration: total_bootstraps should sum to exactly 1000 per spec.")
} else {
  cat("\n✅ All specs correctly configured to run exactly 1000 bootstraps.\n")
}

cat("\nYAML file written successfully to", output_file, "\n")
cat("This file can now be used by array job systems to distribute bootstrap simulations.\n")
