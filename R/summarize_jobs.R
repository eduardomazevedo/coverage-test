#
# Summarize bootstrap job results
#
# Reads all completed job results, extracts the "gf" row from each coverage table,
# adds job specification parameters, and saves to a summary CSV file.

library(yaml)

# Read YAML file
yaml_file <- "data/list_of_jobs.yaml"
if (!file.exists(yaml_file)) {
  stop(sprintf("YAML file not found: %s", yaml_file))
}

yaml_data <- read_yaml(yaml_file)
jobs <- yaml_data$jobs

# Initialize list to store results
summary_rows <- list()

# Process each job
for (job in jobs) {
  job_id <- as.integer(job$job_id)
  results_file <- file.path("data", "job_results", sprintf("%d.rds", job_id))
  
  # Skip if results file doesn't exist
  if (!file.exists(results_file)) {
    cat(sprintf("Skipping job %d: results file not found\n", job_id))
    next
  }
  
  # Read results
  results <- readRDS(results_file)
  
  # Extract "gf" row from coverage table
  coverage_table <- results$coverage_table
  gf_row <- coverage_table[coverage_table$variable == "gf", ]
  
  if (nrow(gf_row) == 0) {
    cat(sprintf("Warning: No 'gf' row found in job %d\n", job_id))
    next
  }
  
  # Add all job specification parameters as columns
  # Convert job spec to a data frame row (handles missing parameters gracefully)
  job_spec_df <- data.frame(
    job_id = job_id,
    parameter_source = job$parameter_source,
    model = job$model,
    sample_size = as.numeric(job$sample_size),
    bootstrap_iterations = as.integer(job$bootstrap_iterations),
    stringsAsFactors = FALSE
  )
  
  # Add Cox-specific parameter if it exists
  if ("cox_median_event_probability" %in% names(job)) {
    job_spec_df$cox_median_event_probability <- as.numeric(job$cox_median_event_probability)
  } else {
    job_spec_df$cox_median_event_probability <- NA
  }
  
  # Combine coverage table row with job spec columns
  combined_row <- cbind(job_spec_df, gf_row, row.names = NULL)
  
  summary_rows[[length(summary_rows) + 1]] <- combined_row
}

# Combine all rows into a single data frame
if (length(summary_rows) == 0) {
  stop("No completed jobs found to summarize")
}

summary_df <- do.call(rbind, summary_rows)

# Ensure output directory exists
if (!dir.exists("output")) {
  dir.create("output", recursive = TRUE)
}

# Save to CSV
output_file <- "output/coverage_summary.csv"
write.csv(summary_df, output_file, row.names = FALSE)

cat(sprintf("\nSummary saved to: %s\n", output_file))
cat(sprintf("Total jobs summarized: %d\n", nrow(summary_df)))
cat(sprintf("Jobs with results: %d / %d\n", nrow(summary_df), length(jobs)))
