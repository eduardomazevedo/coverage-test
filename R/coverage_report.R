coverage_report <- function(bootstrap_results, output_folder = NULL, confidence_level = 0.95) {
  # Extract true beta values from bootstrap_results
  true_beta <- bootstrap_results$true_beta
  beta_names <- names(true_beta)

  # Extract beta and SE matrices
  betas_df <- bootstrap_results$betas_df
  se_df <- bootstrap_results$se_df

  stopifnot(nrow(betas_df) == nrow(se_df))
  n_bootstraps <- nrow(betas_df)

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

  # Calculate coverage
  summary_stats$coverage_percentage <- sapply(beta_names, function(name) {
    beta_hats <- betas_df[[name]]
    se_hats <- se_df[[name]]
    true_val <- true_beta[[name]]
    ci_lower <- beta_hats - t_multiplier * se_hats
    ci_upper <- beta_hats + t_multiplier * se_hats
    inside_ci <- sum(true_val >= ci_lower & true_val <= ci_upper, na.rm = TRUE)
    return(100 * inside_ci / n_bootstraps)
  })

  # Save summary statistics
  if (!is.null(output_folder)) {
    if (!dir.exists(output_folder)) dir.create(output_folder, recursive = TRUE)
    write_csv(summary_stats, file.path(output_folder, "summary_stats.csv"))
  }

  # Create plots
  plots <- list()
  for (param_name in beta_names) {
    beta_hats <- betas_df[[param_name]]
    true_val <- true_beta[[param_name]]
    mean_est <- mean(beta_hats, na.rm = TRUE)
    mean_se <- mean(se_df[[param_name]], na.rm = TRUE)
    coverage_rate <- summary_stats$coverage_percentage[summary_stats$parameter == param_name]
    ci_lower <- true_val - t_multiplier * mean_se
    ci_upper <- true_val + t_multiplier * mean_se

    p <- ggplot(data.frame(estimate = beta_hats), aes(x = estimate)) +
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
          "Red = True value, Green = Mean estimate, Orange = ±", confidence_level * 100, "% CI"
        )
      ) +
      theme_minimal() +
      theme(
        plot.title = element_text(size = 14, face = "bold"),
        plot.subtitle = element_text(size = 12),
        plot.caption = element_text(size = 10, color = "gray50")
      )

    plots[[param_name]] <- p

    if (!is.null(output_folder)) {
      ggsave(
        filename = file.path(output_folder, paste0(param_name, "_distribution.png")),
        plot = p,
        width = 8, height = 6, dpi = 300
      )
    }
  }

  return(list(
    summary_stats = summary_stats,
    plots = plots
  ))
}
