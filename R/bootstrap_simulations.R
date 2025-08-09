bootstrap_simulations <- function(n_obs, n_bootstraps, parameters, w_pool) {
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
      improvement_ratio = parameters$improvement_ratio
    )
    
    # Extract estimates
    beta_hat <- fit$coefficients$beta
    se_hat <- fit$standard_errors
    
    # Check names for consistency
    stopifnot(identical(names(beta_hat), true_beta_names))
    stopifnot(identical(names(se_hat), true_beta_names))
    
    # Store
    beta_estimates[i, ] <- beta_hat
    se_estimates[i, ] <- se_hat
  }
  
  # Convert to data frames
  betas_df <- as.data.frame(beta_estimates)
  betas_df$bootstrap_id <- 1:n_bootstraps
  
  se_df <- as.data.frame(se_estimates)
  se_df$bootstrap_id <- 1:n_bootstraps
  
  list(
    betas = betas_df,
    standard_errors = se_df
  )
}
