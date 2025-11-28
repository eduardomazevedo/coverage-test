#
# Generate YAML file with bootstrap job specifications
#
# This script creates a comprehensive list of bootstrap jobs to run,
# varying parameters, models, sample sizes, and Cox-specific settings.

library(yaml)

# Define all the parameter combinations
parameter_sources <- c("simple", "richard_snph2", "richard_twinh2")
models <- c("lm", "probit", "cox")
sample_sizes <- c(1e3, 1e4, 1e5)
cox_median_event_probabilities <- c(0.1, 0.2, 0.5, 0.9)
bootstrap_iterations <- 1000

# Initialize list to store all job specifications
jobs <- list()

job_id <- 1

# Iterate over all combinations
for (param_source in parameter_sources) {
  for (model in models) {
    for (sample_size in sample_sizes) {
      if (model == "cox") {
        # For Cox model, iterate over cox_median_event_probability values
        for (cox_median_event_prob in cox_median_event_probabilities) {
          job <- list(
            job_id = job_id,
            parameter_source = param_source,
            model = model,
            sample_size = as.numeric(sample_size),
            bootstrap_iterations = bootstrap_iterations,
            cox_median_event_probability = cox_median_event_prob
          )
          jobs[[length(jobs) + 1]] <- job
          job_id <- job_id + 1
        }
      } else {
        # For lm and probit models, no cox_median_event_probability needed
        job <- list(
          job_id = job_id,
          parameter_source = param_source,
          model = model,
          sample_size = as.numeric(sample_size),
          bootstrap_iterations = bootstrap_iterations
        )
        jobs[[length(jobs) + 1]] <- job
        job_id <- job_id + 1
      }
    }
  }
}

# Create the final YAML structure
yaml_data <- list(
  metadata = list(
    total_jobs = length(jobs),
    created = as.character(Sys.time()),
    description = "Bootstrap analysis job specifications for systematic coverage testing"
  ),
  jobs = jobs
)

# Ensure data directory exists
if (!dir.exists("data")) {
  dir.create("data", recursive = TRUE)
}

# Write YAML file
output_file <- "data/list_of_jobs.yaml"
write_yaml(yaml_data, output_file)

cat(sprintf("Generated %d job specifications in %s\n", length(jobs), output_file))
cat(sprintf("Total combinations:\n"))
cat(sprintf("  - Parameter sources: %d\n", length(parameter_sources)))
cat(sprintf("  - Models: %d\n", length(models)))
cat(sprintf("  - Sample sizes: %d\n", length(sample_sizes)))
cat(sprintf("  - Cox event probabilities: %d\n", length(cox_median_event_probabilities)))
cat(sprintf("\nBreakdown:\n"))
cat(sprintf("  - LM jobs: %d\n", length(parameter_sources) * length(sample_sizes)))
cat(sprintf("  - Probit jobs: %d\n", length(parameter_sources) * length(sample_sizes)))
cat(sprintf("  - Cox jobs: %d\n", length(parameter_sources) * length(sample_sizes) * length(cox_median_event_probabilities)))
cat(sprintf("  - Total: %d\n", length(jobs)))
