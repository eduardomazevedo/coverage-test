source("R/simulate_model.R")

# Example: Run simulate_lm with n=10 and small dummy parameters
n_observations <- 10
beta_g <- 0.5
beta_w <- c(w1 = 0.3, w2 = -0.2)
beta_constant <- 1
theta <- c(w1 = 0.4, w2 = 0.5)
var_v <- 0.1
var_epsilon <- 0.2
e_w <- c(w1 = 0, w2 = 0)
vcov_w <- matrix(c(1, 0.2, 0.2, 1), nrow = 2, dimnames = list(names(e_w), names(e_w)))

theta <- adjust_theta(theta, var_v, var_epsilon, vcov_w)

# Example with model_type = "lm"
simdat_lm <- simulate_model(
  n_observations = n_observations, 
  beta_g = beta_g, 
  beta_w = beta_w, 
  beta_constant = beta_constant, 
  theta = theta, 
  var_v = var_v, 
  var_epsilon = var_epsilon, 
  e_w = e_w, 
  vcov_w = vcov_w,
  model_type = "lm"
)
print("simdat_lm")
print(simdat_lm)

# Example with model_type = "probit"
simdat_probit <- simulate_model(
  n_observations = n_observations, 
  beta_g = beta_g, 
  beta_w = beta_w, 
  beta_constant = beta_constant, 
  theta = theta, 
  var_v = var_v, 
  var_epsilon = var_epsilon, 
  e_w = e_w, 
  vcov_w = vcov_w,
  model_type = "probit"
)
print("simdat_probit")
print(simdat_probit)

# Example with model_type = "cox"
simdat_cox <- simulate_model(
  n_observations = n_observations, 
  beta_g = beta_g, 
  beta_w = beta_w, 
  beta_constant = -4, 
  theta = theta, 
  var_v = var_v, 
  var_epsilon = var_epsilon, 
  e_w = e_w, 
  vcov_w = vcov_w,
  model_type = "cox"
)
print("simdat_cox")
print(simdat_cox)
