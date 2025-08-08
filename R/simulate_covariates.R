# Creates simulated covariates w dataset with 100,000 observations
########################################################
rm(list = ls())

library(tidyverse)
library(SimMultiCorrData)

set.seed(123)

# Load inputs
inputs <- readRDS("assets/means_sd_cov_mat.BRC.std.rds")
means <- as.numeric(inputs$means[1, ])
names(means) <- colnames(inputs$means)
cov_mat <- inputs$cov_mat

# Parameters
n_simulated_dataset <- 1e5

# Define variable names by type
binary_vars <- c("Smoker_i0", "ExSmoker_i0", "phys_inact_i0", "array_bit",
                 "ever_brc_screening_i0", "ever_hrt_i0", "ever_ocp_i0",
                 "ever_live_birth_bit", "mother_BRC", "siblings_BRC", "T1D_bit")

pos_cont_vars <- c("age_last_obs", "age_assess_i0", "bmi_i0",
                   "drinksweekly_i0", "sbp_i0", "eduyears", "age_menarche", "age_first_birth")

count_vars <- c("num_live_births")

unrestricted_vars <- c(paste0("pc", 1:10), "townsend_index")

# Ensure variable lists are character vectors
binary_vars <- as.character(binary_vars)
pos_cont_vars <- as.character(pos_cont_vars)
count_vars <- as.character(count_vars)
unrestricted_vars <- as.character(unrestricted_vars)

# Marginal probabilities for binary variables from means
p_bin <- means[binary_vars]
# For binary, marginal is a list of length k_cat, each element is the probability of 0 (failure)
bin_marginals <- lapply(p_bin, function(p) c(1 - p))

# Combine all variable names in the correct order
all_vars <- c(binary_vars, pos_cont_vars, count_vars, unrestricted_vars)

# Subset covariance matrix to only these variables, in this order
cov_mat <- cov_mat[all_vars, all_vars]

# Convert covariance matrix to correlation matrix
target_corr <- cov2cor(cov_mat)

# Poisson means
lam <- means[count_vars]

# Prepare moments for continuous variables
pos_cont_means <- means[pos_cont_vars]
pos_cont_vars_vals <- diag(cov_mat[pos_cont_vars, pos_cont_vars])
pos_cont_skews <- numeric(length(pos_cont_vars))
pos_cont_skurts <- numeric(length(pos_cont_vars))
pos_cont_fifths <- numeric(length(pos_cont_vars))
pos_cont_sixths <- numeric(length(pos_cont_vars))
for (i in seq_along(pos_cont_vars)) {
  m <- pos_cont_means[i]
  v <- pos_cont_vars_vals[i]
  meanlog <- log(m^2 / sqrt(v + m^2))
  sdlog <- sqrt(log(1 + v / m^2))
  # lognormal moments
  pos_cont_skews[i] <- (exp(sdlog^2) + 2) * sqrt(exp(sdlog^2) - 1)
  pos_cont_skurts[i] <- exp(4 * sdlog^2) + 2 * exp(3 * sdlog^2) + 3 * exp(2 * sdlog^2) - 6
  pos_cont_fifths[i] <- 0 # set to 0 for Fleishman
  pos_cont_sixths[i] <- 0 # set to 0 for Fleishman
}

# Normal moments (unrestricted)
unrestricted_means <- means[unrestricted_vars]
unrestricted_vars_vals <- diag(cov_mat[unrestricted_vars, unrestricted_vars])
unrestricted_skews <- rep(0, length(unrestricted_vars))
unrestricted_skurts <- rep(0, length(unrestricted_vars))
unrestricted_fifths <- rep(0, length(unrestricted_vars))
unrestricted_sixths <- rep(0, length(unrestricted_vars))

# Simulate the data
sim_data <- rcorrvar(
  n = n_simulated_dataset,
  k_cat = length(binary_vars),
  k_cont = length(pos_cont_vars) + length(unrestricted_vars),
  k_pois = length(count_vars),
  marginal = bin_marginals,
  lam = lam,
  means = c(pos_cont_means, unrestricted_means),
  vars = c(pos_cont_vars_vals, unrestricted_vars_vals),
  skews = c(pos_cont_skews, unrestricted_skews),
  skurts = c(pos_cont_skurts, unrestricted_skurts),
  fifths = c(pos_cont_fifths, unrestricted_fifths),
  sixths = c(pos_cont_sixths, unrestricted_sixths),
  rho = target_corr,
  method = "Fleishman"
)

# Name the simulated dataset columns
cat("Simulated data structure:\n")
cat("Length of sim_data:", length(sim_data), "\n")
cat("Names of sim_data:", names(sim_data), "\n")

# Check which element contains the actual simulated data
if ("ordinal_variables" %in% names(sim_data)) {
  cat("Dimensions of ordinal_variables:", dim(sim_data$ordinal_variables), "\n")
  cat("Expected binary vars:", length(binary_vars), "\n")
}
if ("continuous_variables" %in% names(sim_data)) {
  cat("Dimensions of continuous_variables:", dim(sim_data$continuous_variables), "\n")
  cat("Expected continuous vars:", length(pos_cont_vars) + length(unrestricted_vars), "\n")
  cat("Expected pos_cont vars:", length(pos_cont_vars), "\n")
  cat("Expected unrestricted vars:", length(unrestricted_vars), "\n")
}
if ("Poisson_variables" %in% names(sim_data)) {
  cat("Dimensions of Poisson_variables:", dim(sim_data$Poisson_variables), "\n")
  cat("Expected count vars:", length(count_vars), "\n")
}

# Debug: print the variable lists to verify
cat("Binary vars:", paste(binary_vars, collapse=", "), "\n")
cat("Pos cont vars:", paste(pos_cont_vars, collapse=", "), "\n")
cat("Count vars:", paste(count_vars, collapse=", "), "\n")
cat("Unrestricted vars:", paste(unrestricted_vars, collapse=", "), "\n")

# Combine all simulated variables in the correct order
# IMPORTANT: rcorrvar returns data in order: ordinal -> continuous -> Poisson
# But we want: binary -> pos_cont -> count -> unrestricted
# So we need to reorder the continuous variables to match our desired order
continuous_data <- sim_data$continuous_variables
pos_cont_data <- continuous_data[, 1:length(pos_cont_vars), drop=FALSE]
unrestricted_data <- continuous_data[, (length(pos_cont_vars)+1):ncol(continuous_data), drop=FALSE]

simulated_data <- cbind(
  sim_data$ordinal_variables,      # binary variables
  pos_cont_data,                   # positive continuous variables  
  sim_data$Poisson_variables,      # count variables
  unrestricted_data                # unrestricted variables
)

cat("Combined simulated data dimensions:", dim(simulated_data), "\n")

simulated_df <- simulated_data |>
  as_tibble(.name_repair = "minimal") |>
  setNames(c(binary_vars, pos_cont_vars, count_vars, unrestricted_vars))

# Convert binary variables from numeric (1,2) to logical (FALSE, TRUE)
# Assume 1 = FALSE, 2 = TRUE
for (var in binary_vars) {
  simulated_df[[var]] <- simulated_df[[var]] == 2
}

# Make Richard's first birth date and ever_live_birth_bit consistent
simulated_df |>
  mutate(
    ever_live_birth_bit = (num_live_births > 0),
    age_first_birth = if_else(num_live_births == 0, 0, age_first_birth),
    age_last_obs = pmax(age_last_obs, age_assess_i0 + 1)
  )

cat("Final simulated_df dimensions:", dim(simulated_df), "\n")
glimpse(simulated_df)

# Compute sample mean and vcov
sample_mean <- colMeans(simulated_df |> as.data.frame())
sample_vcov <- cov(simulated_df |> as.data.frame())

# Save all as a named list
output <- list(
  simulated_df = simulated_df,
  sample_mean = sample_mean,
  sample_vcov = sample_vcov
)

# Save the simulated data
dir.create("data", showWarnings = FALSE)
saveRDS(output, "data/simulated_covariates.rds")
cat("Simulated data (with mean and vcov) saved to data/simulated_covariates.rds\n")