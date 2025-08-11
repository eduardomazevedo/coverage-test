#!/usr/bin/env Rscript

# Script to run coverage reports on all bootstrap files
# This script processes each bootstrap file in data/bootstraps_by_spec/
# and generates coverage reports in output/bootstrap_results/

# Load required libraries
library(readr)
library(ggplot2)

# Source the coverage report function
source("R/coverage_report.R")

# Function to parse filename and extract specification details
parse_filename <- function(filename) {
  # Remove .rds extension
  base_name <- gsub("\\.rds$", "", filename)
  
  # Split by underscores
  parts <- strsplit(base_name, "_")[[1]]
  
  # Extract model type
  model_type <- gsub("model=", "", parts[1])
  
  # Extract heritability source
  heritability_source <- gsub("h=", "", parts[2])
  
  # Extract softmax correction (if present)
  softmax_correction <- "clt"  # default
  if (length(parts) >= 4 && grepl("^s=", parts[3])) {
    softmax_correction <- gsub("s=", "", parts[3])
    sample_size <- gsub("n=", "", parts[4])
  } else {
    sample_size <- gsub("n=", "", parts[3])
  }
  
  return(list(
    model_type = model_type,
    heritability_source = heritability_source,
    softmax_correction = softmax_correction,
    sample_size = sample_size
  ))
}

# Function to create organized output directory structure
create_output_dirs <- function(spec_info) {
  base_dir <- "output/bootstrap_results"
  
  # Create main directory
  if (!dir.exists(base_dir)) {
    dir.create(base_dir, recursive = TRUE)
  }
  
  # Create model-specific directory
  model_dir <- file.path(base_dir, spec_info$model_type)
  if (!dir.exists(model_dir)) {
    dir.create(model_dir, recursive = TRUE)
  }
  
  # Create heritability-specific directory
  h_dir <- file.path(model_dir, paste0("h_", spec_info$heritability_source))
  if (!dir.exists(h_dir)) {
    dir.create(h_dir, recursive = TRUE)
  }
  
  # Create softmax-specific directory (for cox models)
  if (spec_info$model_type == "cox") {
    s_dir <- file.path(h_dir, paste0("s_", spec_info$softmax_correction))
    if (!dir.exists(s_dir)) {
      dir.create(s_dir, recursive = TRUE)
    }
    final_dir <- file.path(s_dir, paste0("n_", spec_info$sample_size))
  } else {
    final_dir <- file.path(h_dir, paste0("n_", spec_info$sample_size))
  }
  
  if (!dir.exists(final_dir)) {
    dir.create(final_dir, recursive = TRUE)
  }
  
  return(final_dir)
}

# Main function to process all bootstrap files
main <- function() {
  # Get list of all bootstrap files
  bootstrap_dir <- "data/bootstraps_by_spec"
  bootstrap_files <- list.files(bootstrap_dir, pattern = "\\.rds$", full.names = FALSE)
  
  cat("Found", length(bootstrap_files), "bootstrap files to process\n")
  
  # Process each file
  for (filename in bootstrap_files) {
    cat("\nProcessing:", filename, "\n")
    
    tryCatch({
      # Parse filename to get specification details
      spec_info <- parse_filename(filename)
      cat("  Model:", spec_info$model_type, 
          "| Heritability:", spec_info$heritability_source,
          "| Softmax:", spec_info$softmax_correction,
          "| Sample size:", spec_info$sample_size, "\n")
      
      # Load bootstrap results
      file_path <- file.path(bootstrap_dir, filename)
      bootstrap_results <- readRDS(file_path)
      
      # Create output directory
      output_dir <- create_output_dirs(spec_info)
      cat("  Output directory:", output_dir, "\n")
      
      # Run coverage report
      cat("  Running coverage report...\n")
      coverage_results <- coverage_report(
        bootstrap_results = bootstrap_results,
        output_folder = output_dir,
        confidence_level = 0.95
      )
      
      # Save coverage results as RDS for potential further analysis
      results_file <- file.path(output_dir, "coverage_results.rds")
      saveRDS(coverage_results, results_file)
      
      # Print summary
      cat("  Coverage report completed successfully\n")
      cat("  Summary statistics saved to:", file.path(output_dir, "summary_stats.csv"), "\n")
      cat("  Plots saved to:", output_dir, "\n")
      cat("  Full results saved to:", results_file, "\n")
      
    }, error = function(e) {
      cat("  ERROR processing", filename, ":", conditionMessage(e), "\n")
    })
  }
  
  cat("\nAll bootstrap files processed!\n")
  cat("Results saved in: output/bootstrap_results/\n")
}

# Run the main function if script is executed directly
if (!interactive()) {
  main()
}
