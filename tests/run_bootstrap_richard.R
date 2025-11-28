source("R/run_bootstrap.R")
source("R/get_richard_params.R")

# Options
model_type <- "cox"
snp_source <- "twinh2"
n_bootstraps <- 100
n_observations <- 10000

# Get Richard's parameters
params <- get_richard_params(model_type = model_type, snp_source = snp_source)
beta_g <- params$beta_g
beta_w <- params$beta_w
theta <- params$theta
var_v <- params$var_v
var_epsilon <- params$var_epsilon
e_w <- params$e_w
vcov_w <- params$vcov_w

beta_intercept <- params$beta_intercept
cox_censoring_time <- 10
cox_median_event_probability <- 0.9

adjusted_theta <- adjust_theta(theta, var_v, var_epsilon, vcov_w)

print("original theta")
print(theta)
print("adjusted_theta")
print(adjusted_theta)

# Run BS
bootstrap_result <- run_bootstrap(
  n_bootstraps = n_bootstraps,
  n_observations = n_observations,
  beta_g = beta_g,
  beta_w = beta_w,
  theta = adjusted_theta,
  var_v = var_v,
  var_epsilon = var_epsilon,
  e_w = e_w,
  vcov_w = vcov_w,
  model_type = model_type,
  beta_intercept = beta_intercept,
  cox_censoring_time = cox_censoring_time,
  cox_median_event_probability = cox_median_event_probability
)
# print("bootstrap_result")
# print(colMeans(bootstrap_result$betas_df))

# Coverage tests using coverage_table function
print("=== Coverage Table ===")
coverage_table <- coverage_table(
  bootstrap_result$betas_df,
  bootstrap_result$se_df,
  true_beta_g = beta_g,
  true_beta_w = beta_w
)
glimpse(coverage_table)
