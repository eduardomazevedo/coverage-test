#
# Run a single bootstrap job from the YAML specification file
#
# This script takes a job number, reads the job specifications from the YAML file,
# runs the bootstrap analysis if the output doesn't exist, and saves results.

source("R/run_bootstrap.R")
source("R/get_richard_params.R")

library(yaml)

#' Get simple parameters (hardcoded from test script)
get_simple_params <- function() {
  list(
    beta_g = 0.42,
    beta_w = c(w1 = 0.07, w2 = -0.05),
    theta = c(w1 = 1 / sqrt(3), w2 = 0.0),
    var_v = 0.2,
    var_epsilon = 0.79,
    e_w = c(w1 = 0, w2 = 0.2),
    vcov_w = matrix(c(1, 0.2, 0.2, 1), nrow = 2, dimnames = list(c("w1", "w2"), c("w1", "w2"))),
    beta_intercept = 1,
    cox_censoring_time = 10
  )
}

#' Load parameters based on parameter source
load_parameters <- function(parameter_source, model_type) {
  if (parameter_source == "simple") {
    params <- get_simple_params()
  } else if (parameter_source == "richard_snph2") {
    params <- get_richard_params(model_type = model_type, snp_source = "snph2")
    params$cox_censoring_time <- 10  # Default value
  } else if (parameter_source == "richard_twinh2") {
    params <- get_richard_params(model_type = model_type, snp_source = "twinh2")
    params$cox_censoring_time <- 10  # Default value
  } else {
    stop(sprintf("Unknown parameter_source: %s", parameter_source))
  }
  return(params)
}

#' Run a single bootstrap job
#'
#' @param job_id Integer job ID (1-indexed)
#' @param yaml_file Path to YAML file with job specifications (default: "data/list_of_jobs.yaml")
#' @return Invisible NULL, saves results to RDS file
run_job <- function(job_id, yaml_file = "data/list_of_jobs.yaml") {
  # Read YAML file
  if (!file.exists(yaml_file)) {
    stop(sprintf("YAML file not found: %s", yaml_file))
  }
  
  yaml_data <- read_yaml(yaml_file)
  jobs <- yaml_data$jobs
  
  # Find the job with matching job_id
  job <- NULL
  for (j in jobs) {
    if (as.integer(j$job_id) == as.integer(job_id)) {
      job <- j
      break
    }
  }
  
  if (is.null(job)) {
    stop(sprintf("Job ID %d not found in YAML file", job_id))
  }
  
  # Check if output file already exists
  output_dir <- "data/job_results"
  if (!dir.exists(output_dir)) {
    dir.create(output_dir, recursive = TRUE)
  }
  
  output_file <- file.path(output_dir, sprintf("%d.rds", job_id))
  
  if (file.exists(output_file)) {
    cat(sprintf("Job %d: Output file already exists, skipping: %s\n", job_id, output_file))
    return(invisible(NULL))
  }
  
  cat(sprintf("Job %d: Running bootstrap analysis...\n", job_id))
  cat(sprintf("  Parameter source: %s\n", job$parameter_source))
  cat(sprintf("  Model: %s\n", job$model))
  cat(sprintf("  Sample size: %s\n", job$sample_size))
  cat(sprintf("  Bootstrap iterations: %s\n", job$bootstrap_iterations))
  
  # Load parameters
  params <- load_parameters(job$parameter_source, job$model)
  
  # Adjust theta
  adjusted_theta <- adjust_theta(
    params$theta,
    params$var_v,
    params$var_epsilon,
    params$vcov_w
  )
  
  # Prepare arguments for run_bootstrap
  bootstrap_args <- list(
    n_bootstraps = as.integer(job$bootstrap_iterations),
    n_observations = as.integer(job$sample_size),
    beta_g = params$beta_g,
    beta_w = params$beta_w,
    theta = adjusted_theta,
    var_v = params$var_v,
    var_epsilon = params$var_epsilon,
    e_w = params$e_w,
    vcov_w = params$vcov_w,
    model_type = job$model,
    beta_intercept = params$beta_intercept
  )
  
  # Add Cox-specific parameters if needed
  if (job$model == "cox") {
    bootstrap_args$cox_censoring_time <- params$cox_censoring_time
    bootstrap_args$cox_median_event_probability <- as.numeric(job$cox_median_event_probability)
    cat(sprintf("  Cox median event probability: %s\n", job$cox_median_event_probability))
  }
  
  # Run bootstrap
  bootstrap_result <- do.call(run_bootstrap, bootstrap_args)
  
  # Calculate coverage table
  coverage_table_result <- coverage_table(
    bootstrap_result$betas_df,
    bootstrap_result$se_df,
    true_beta_g = params$beta_g,
    true_beta_w = params$beta_w
  )
  
  # Prepare results list
  results <- list(
    bootstrap_result = bootstrap_result,
    coverage_table = coverage_table_result,
    job_spec = job
  )
  
  # Save to RDS
  saveRDS(results, output_file)
  cat(sprintf("Job %d: Results saved to %s\n", job_id, output_file))
  
  return(invisible(NULL))
}

# If run from command line, execute the job
if (!interactive()) {
  args <- commandArgs(trailingOnly = TRUE)
  if (length(args) < 1) {
    stop("Usage: Rscript R/run_job.R <job_id>")
  }
  
  job_id <- as.integer(args[1])
  if (is.na(job_id)) {
    stop("Job ID must be an integer")
  }
  
  run_job(job_id)
}
