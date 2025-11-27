source("R/simulate_model.R")

adjust_theta <- function(theta, var_v, var_epsilon, vcov_w) {
  var_theta_w <- as.vector(t(theta) %*% vcov_w %*% theta)
  target_var <- 1 - var_epsilon - var_v
  theta <- theta * sqrt(target_var / var_theta_w)
  return(theta)
}

run_bootstrap <- function(n_bootstraps, n_observations, beta_g, beta_w, beta_constant, theta, var_v, var_epsilon, e_w, vcov_w, model_type) {
  improvement_ratio <- 1 / (1 - var_epsilon)
  
  beta_estimates_list <- list()
  se_estimates_list <- list()
    
  for (i in 1:n_bootstraps) {
    # Simulate dataset based on model type
    simulated_dataset <- simulate_model(n_observations, beta_g, beta_w, beta_constant, adjusted_theta, var_v, var_epsilon, e_w, vcov_w, model_type)
    covariate_names <- colnames(simulated_dataset$w)
    
    # Fit model
    fit <- hapr::hapr(
      y = simulated_dataset$y,
      gc = simulated_dataset$gc,
      w = simulated_dataset$w,
      model_type = model_type,
      improvement_ratio = improvement_ratio
    )
    
    # Extract estimates
    beta_hat <- fit$coefficients$beta
    se_hat <- fit$standard_errors
    
    # Store as list elements (each is a named vector)
    beta_estimates_list[[i]] <- beta_hat
    se_estimates_list[[i]] <- se_hat
  }
  
  # Convert to data frames - each list element becomes a row
  betas_df <- do.call(rbind, lapply(beta_estimates_list, function(x) as.data.frame(t(x))))
  betas_df$bootstrap_id <- 1:n_bootstraps
  
  se_df <- do.call(rbind, lapply(se_estimates_list, function(x) as.data.frame(t(x))))
  se_df$bootstrap_id <- 1:n_bootstraps
  
  list(
    betas_df = betas_df,
    se_df = se_df
  )
}
