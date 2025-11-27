#!/usr/bin/env Rscript

# Load libraries
# Load libraries
suppressPackageStartupMessages({
  library(yaml)
  library(optparse)
  library(tidyverse)
})

# Parse command line argument
option_list <- list(
  make_option(c("-j", "--job_number"), type = "integer", help = "Job number (1-indexed)")
)
opt_parser <- OptionParser(option_list = option_list)
opt <- parse_args(opt_parser)

if (is.null(opt$job_number)) {
  stop("Please provide a job number using --job_number")
}

# Load job list
job_list <- yaml::read_yaml("assets/list_of_jobs.yaml")$jobs

# Validate job number
if (opt$job_number < 1 || opt$job_number > length(job_list)) {
  stop(paste("Invalid job number. Must be between 1 and", length(job_list)))
}

# Extract job parameters
job <- job_list[[opt$job_number]]

model_type <- job$model_type
heritability_source <- job$heritability_source
n_obs <- job$n_obs
n_bootstraps <- job$n_bootstraps
chunk_id <- job$chunk_id
total_chunks <- job$total_chunks

# Display job info
cat("Running job", opt$job_number, ":\n")
cat("  model_type:", model_type, "\n")
cat("  heritability_source:", heritability_source, "\n")
cat("  n_obs:", n_obs, "\n")
cat("  n_bootstraps:", n_bootstraps, "\n")
cat("  chunk_id:", chunk_id, "\n")
cat("  total_chunks:", total_chunks, "\n")

# Print time
start_time <- Sys.time()
cat("  start_time:", format(start_time, "%Y-%m-%d %H:%M:%S"), "\n")

# Load required functions
source("R/get_params.R")
source("R/run_bootstrap.R")

# Load parameters
params <- get_params(model_type, heritability_source)

# Run the job
set.seed(opt$job_number)
bootstrap_results <- run_bootstrap(
  n_obs = n_obs,
  n_bootstraps = n_bootstraps,
  params = params
)

# Add heritability_source to results
bootstrap_results$heritability_source <- heritability_source

# Create output path
dir.create("data/bootstrap_chunks", recursive = TRUE, showWarnings = FALSE)
outfile <- sprintf("data/bootstrap_chunks/bootstrap_%03d.rds", opt$job_number)
saveRDS(bootstrap_results, outfile)

cat("Saved results to", outfile, "\n")
end_time <- Sys.time()
cat("  end_time:", format(end_time, "%Y-%m-%d %H:%M:%S"), "\n")
duration <- end_time - start_time
cat("  duration:", sprintf("%.1f seconds", as.numeric(duration, units = "secs")), "\n")
