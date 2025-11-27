source("R/run_bootstrap.R")

# Example: Run run_bootstrap with small dummy parameters
n_bootstraps <- 10
n_observations <- 1000
beta_g <- 0.42
beta_w <- c(w1 = 0.07, w2 = -0.05)
beta_constant <- 0.1
theta <- c(w1 = 1 / sqrt(3), w2 = 0.0)
var_v <- 1/3
var_epsilon <- 1/30
e_w <- c(w1 = 0, w2 = 0.2)
vcov_w <- matrix(c(1, 0.2, 0.2, 1), nrow = 2, dimnames = list(names(e_w), names(e_w)))

adjusted_theta <- adjust_theta(theta, var_v, var_epsilon, vcov_w)

print("adjusted_theta")
print(adjusted_theta)

# Example with model_type = "lm"
bootstrap_result_lm <- run_bootstrap(
  n_bootstraps = n_bootstraps,
  n_observations = n_observations,
  beta_g = beta_g,
  beta_w = beta_w,
  beta_constant = beta_constant,
  theta = adjusted_theta,
  var_v = var_v,
  var_epsilon = var_epsilon,
  e_w = e_w,
  vcov_w = vcov_w,
  model_type = "lm"
)
print("bootstrap_result_lm")
print(colMeans(bootstrap_result_lm$betas_df))

# Example with model_type = "probit"
bootstrap_result_probit <- run_bootstrap(
  n_bootstraps = n_bootstraps,
  n_observations = n_observations,
  beta_g = beta_g,
  beta_w = beta_w,
  beta_constant = beta_constant,
  theta = adjusted_theta,
  var_v = var_v,
  var_epsilon = var_epsilon,
  e_w = e_w,
  vcov_w = vcov_w,
  model_type = "probit"
)
print("bootstrap_result_probit")
print(colMeans(bootstrap_result_probit$betas_df))

# Example with model_type = "cox"
bootstrap_result_cox <- run_bootstrap(
  n_bootstraps = n_bootstraps,
  n_observations = n_observations,
  beta_g = beta_g,
  beta_w = beta_w,
  beta_constant = beta_constant,
  theta = adjusted_theta,
  var_v = var_v,
  var_epsilon = var_epsilon,
  e_w = e_w,
  vcov_w = vcov_w,
  model_type = "cox"
)
print("bootstrap_result_cox")
print(colMeans(bootstrap_result_cox$betas_df))
