library(hapr)
library(tidyverse)

source("R/simulate_probit.R")

#' Bootstrap Simulations for Model Estimation
#' 
#' Performs bootstrap simulations by repeatedly simulating datasets and estimating
#' the model parameters. Collects beta estimates and standard errors from all
#' bootstrap iterations.
#' 
#' @param n_obs Number of observations to simulate in each bootstrap
#' @param n_bootstraps Number of bootstrap iterations to perform
#' @param parameters DGP parameters object containing beta, theta, var_v, var_epsilon, improvement_ratio
#' @param w_pool Covariates pool (e.g., from data/covariate_draws.rds)
#' 
#' @return Named list containing:
#'   - betas: Data frame with bootstrap beta estimates (rows = bootstraps, columns = parameter names)
#'   - standard_errors: Data frame with bootstrap standard errors (rows = bootstraps, columns = parameter names)
#' 
#' @examples
#' # parameters <- readRDS("assets/summary_object_brc_probit_snph2.rds")
#' # w_pool <- readRDS("data/simulated_covariates.rds")
#' # results <- bootstrap_simulations(1000, 10, parameters, w_pool)
bootstrap_simulations <- function(n_obs, n_bootstraps, parameters, w_pool) {
  
  # Extract true beta names for consistency checks
  true_beta <- parameters$beta
  true_beta_names <- names(true_beta)
  
  # Initialize storage for bootstrap results
  beta_estimates <- matrix(NA, nrow = n_bootstraps, ncol = length(true_beta_names))
  colnames(beta_estimates) <- true_beta_names
  se_estimates <- matrix(NA, nrow = n_bootstraps, ncol = length(true_beta_names))
  colnames(se_estimates) <- true_beta_names
  
  # Perform bootstrap simulations
  for (i in 1:n_bootstraps) {
    # Simulate dataset
    simulated_dataset <- simulate_probit(n_obs, parameters, w_pool)
    
    # Estimate model
    fit <- hapr::hapr(
      y = simulated_dataset$y,
      gc = simulated_dataset$gc,
      w = simulated_dataset$w,
      model_type = "probit",
      improvement_ratio = parameters$improvement_ratio
    )
    
    # Extract beta estimates and standard errors
    beta_hat <- fit$coefficients$beta
    se_hat <- fit$standard_errors
    
    # Consistency checks
    stopifnot(identical(names(beta_hat), true_beta_names))
    stopifnot(identical(names(se_hat), true_beta_names))
    
    # Store beta estimates and standard errors
    beta_estimates[i, ] <- beta_hat
    se_estimates[i, ] <- se_hat
  }
  
  # Convert to tidy data frames
  betas_df <- as.data.frame(beta_estimates)
  betas_df$bootstrap_id <- 1:n_bootstraps
  
  se_df <- as.data.frame(se_estimates)
  se_df$bootstrap_id <- 1:n_bootstraps
  
  # Return results
  list(
    betas = betas_df,
    standard_errors = se_df
  )
}

# Example usage (commented out):
# model_type <- "probit"
# n_observations <- 1000
# n_bootstraps <- 10
# w_cache <- readRDS("data/simulated_covariates.rds")
# params <- readRDS("assets/summary_object_brc_probit_snph2.rds")
# 
# bootstrap_results <- bootstrap_simulations(n_observations, n_bootstraps, params, w_cache)
# 
# # Access results
# print(head(bootstrap_results$betas))
# print(head(bootstrap_results$standard_errors))
