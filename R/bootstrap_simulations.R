bootstrap_simulations <- function(n_obs, n_bootstraps, parameters, w_pool, softmax_correction = "clt") {
  # Extract model type
  model_type <- parameters$model_type
  
  # Validate model type
  stopifnot(model_type %in% c("probit", "cox"))
  
  # Extract true beta names for consistency checks
  true_beta <- parameters$beta
  true_beta_names <- names(true_beta)
  
  # Initialize storage for bootstrap results
  beta_estimates <- matrix(NA, nrow = n_bootstraps, ncol = length(true_beta_names))
  colnames(beta_estimates) <- true_beta_names
  se_estimates <- matrix(NA, nrow = n_bootstraps, ncol = length(true_beta_names))
  colnames(se_estimates) <- true_beta_names
  psi_estimates <- matrix(NA, nrow = n_bootstraps, ncol = 1)
  colnames(psi_estimates) <- "psi_hat"
  alpha_estimates <- matrix(NA, nrow = n_bootstraps, ncol = 1)
  colnames(alpha_estimates) <- "alpha_hat"
  
  for (i in 1:n_bootstraps) {
    # Simulate dataset based on model type
    if (model_type == "probit") {
      simulated_dataset <- simulate_probit(n_obs, parameters, w_pool)
      y_input <- simulated_dataset$y
    } else if (model_type == "cox") {
      simulated_dataset <- simulate_cox(n_obs, parameters, w_pool)
      y_input <- survival::Surv(simulated_dataset$time, simulated_dataset$status)
    }
    
    # Fit model
    fit <- hapr::hapr(
      y = y_input,
      gc = simulated_dataset$gc,
      w = simulated_dataset$w,
      model_type = model_type,
      improvement_ratio = parameters$improvement_ratio,
      softmax_correction = softmax_correction
    )
    
    # Extract estimates
    beta_hat <- fit$coefficients$beta
    se_hat <- fit$standard_errors

    if (model_type == "cox") {
      psi_hat <- fit$stats$psi_hat
      alpha_hat <- fit$stats$alpha_hat
    }
    
    # Check names for consistency
    stopifnot(identical(names(beta_hat), true_beta_names))
    stopifnot(identical(names(se_hat), true_beta_names))
    
    # Store
    beta_estimates[i, ] <- beta_hat
    se_estimates[i, ] <- se_hat
    if (model_type == "cox") {
      psi_estimates[i, ] <- psi_hat
      alpha_estimates[i, ] <- alpha_hat
    }
  }
  
  # Convert to data frames
  betas_df <- as.data.frame(beta_estimates)
  betas_df$bootstrap_id <- 1:n_bootstraps
  
  se_df <- as.data.frame(se_estimates)
  se_df$bootstrap_id <- 1:n_bootstraps
  
  list(
    betas = betas_df,
    standard_errors = se_df,
    psi_hat = mean(psi_estimates),
    alpha_hat = mean(alpha_estimates)
  )
}
