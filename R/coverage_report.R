library(tidyverse)
library(ggplot2)

#' Coverage Report for Bootstrap Simulations
#' 
#' Computes coverage statistics using standard errors from each bootstrap iteration.
#' Calculates confidence intervals as beta_hat ± t_multiplier * standard_error_hat
#' and measures coverage as percentage of times true value falls within these CIs.
#' 
#' @param bootstrap_results List containing bootstrap results from bootstrap_simulations()
#' @param parameters DGP parameters object containing true beta values
#' @param output_folder Optional path to save plots (if NULL, plots are not saved)
#' @param confidence_level Confidence level for intervals (default: 0.95)
#' 
#' @return Named list containing:
#'   - summary_stats: Data frame with true_beta, mean_beta_hat, stdev_beta_hat, mean_standard_error, coverage_percentage
#'   - plots: List of ggplot objects for each parameter
#' 
#' @examples
#' # parameters <- readRDS("assets/summary_object_brc_probit_snph2.rds")
#' # bootstrap_results <- bootstrap_simulations(1000, 10, parameters, w_pool)
#' # report <- coverage_report(bootstrap_results, parameters, "output/plots")
coverage_report <- function(bootstrap_results, parameters, output_folder = NULL, confidence_level = 0.95) {
  
  # Extract true beta values
  true_beta <- parameters$beta
  beta_names <- names(true_beta)
  
  # Get bootstrap results
  betas_df <- bootstrap_results$betas
  se_df <- bootstrap_results$standard_errors
  n_bootstraps <- nrow(betas_df)
  
  # Calculate t-multiplier for confidence level
  # Using normal distribution approximation for large n
  t_multiplier <- qnorm(1 - (1 - confidence_level) / 2)
  
  # Calculate summary statistics
  summary_stats <- data.frame(
    parameter = beta_names,
    true_beta = true_beta,
    mean_beta_hat = sapply(beta_names, function(name) mean(betas_df[[name]], na.rm = TRUE)),
    stdev_beta_hat = sapply(beta_names, function(name) sd(betas_df[[name]], na.rm = TRUE)),
    mean_standard_error = sapply(beta_names, function(name) mean(se_df[[name]], na.rm = TRUE)),
    stringsAsFactors = FALSE
  )
  
  # Calculate coverage for each parameter
  summary_stats$coverage_percentage <- sapply(beta_names, function(name) {
    true_val <- true_beta[name]
    beta_hats <- betas_df[[name]]
    se_hats <- se_df[[name]]
    
    # Calculate confidence intervals for each bootstrap
    ci_lower <- beta_hats - t_multiplier * se_hats
    ci_upper <- beta_hats + t_multiplier * se_hats
    
    # Count how many times true value is inside CI
    inside_ci <- sum(true_val >= ci_lower & true_val <= ci_upper, na.rm = TRUE)
    coverage_rate <- inside_ci / n_bootstraps
    
    return(coverage_rate * 100)
  })
  
  # Create histograms for each parameter
  plots <- list()
  
  for (param_name in beta_names) {
    # Get data for this parameter
    param_data <- betas_df[[param_name]]
    true_val <- true_beta[param_name]
    mean_est <- summary_stats$mean_beta_hat[summary_stats$parameter == param_name]
    mean_se <- summary_stats$mean_standard_error[summary_stats$parameter == param_name]
    coverage_rate <- summary_stats$coverage_percentage[summary_stats$parameter == param_name]
    
    # Calculate CI bounds using mean standard error
    ci_lower <- true_val - t_multiplier * mean_se
    ci_upper <- true_val + t_multiplier * mean_se
    
    # Create histogram
    p <- ggplot(data.frame(estimate = param_data), aes(x = estimate)) +
      geom_histogram(bins = 30, fill = "steelblue", alpha = 0.7, color = "black") +
      geom_vline(xintercept = true_val, color = "red", linetype = "solid", linewidth = 1.2) +
      geom_vline(xintercept = mean_est, color = "green", linetype = "solid", linewidth = 1) +
      geom_vline(xintercept = ci_lower, color = "orange", linetype = "dashed", linewidth = 1) +
      geom_vline(xintercept = ci_upper, color = "orange", linetype = "dashed", linewidth = 1) +
      labs(
        title = paste("Distribution of", param_name, "Estimates"),
        subtitle = paste0(
          "Coverage: ", round(coverage_rate, 1), "%, ",
          "Mean SE: ", round(mean_se, 4)
        ),
        x = "Parameter Estimate",
        y = "Frequency",
        caption = paste0(
          "Red line = True value, ",
          "Green line = Mean estimate, ",
          "Orange lines = True value ± ", confidence_level * 100, "% CI"
        )
      ) +
      theme_minimal() +
      theme(
        plot.title = element_text(size = 14, face = "bold"),
        plot.subtitle = element_text(size = 12),
        plot.caption = element_text(size = 10, color = "gray50")
      )
    
    plots[[param_name]] <- p
    
    # Save plot if output folder is specified
    if (!is.null(output_folder)) {
      # Create output directory if it doesn't exist
      if (!dir.exists(output_folder)) {
        dir.create(output_folder, recursive = TRUE)
      }
      
      # Save plot
      ggsave(
        filename = file.path(output_folder, paste0(param_name, "_distribution.png")),
        plot = p,
        width = 8,
        height = 6,
        dpi = 300
      )
    }
  }
  
  # Print summary to console
  cat("=== Coverage Report ===\n")
  cat("Confidence level:", confidence_level * 100, "%\n")
  cat("Number of bootstraps:", n_bootstraps, "\n")
  cat("t-multiplier:", round(t_multiplier, 3), "\n\n")
  
  cat("Parameter-specific coverage:\n")
  for (i in 1:nrow(summary_stats)) {
    cat(sprintf("  %s: %.1f%%\n", 
                summary_stats$parameter[i], 
                summary_stats$coverage_percentage[i]))
  }
  
  # Return results
  list(
    summary_stats = summary_stats,
    plots = plots
  )
}

# Example usage (commented out):
# parameters <- readRDS("assets/summary_object_brc_probit_snph2.rds")
# w_pool <- readRDS("data/simulated_covariates.rds")
# bootstrap_results <- bootstrap_simulations(1000, 10, parameters, w_pool)
# report <- coverage_report(bootstrap_results, parameters, "output/plots")
# 
# # Access results
# print(report$summary_stats)
# 
# # Display a specific plot
# print(report$plots[["gf"]])
