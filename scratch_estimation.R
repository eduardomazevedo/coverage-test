rm(list = ls())
library(tidyverse)
library(hapr)
library(survival)

# Load data
simulated_dataset <- readRDS("output/simulated_dataset_brc_cox_snph2.rds")
input_summary <- readRDS("input/summary_object_brc_cox_snph2.rds")

# Build full Surv object once
surv_obj <- Surv(
  time = simulated_dataset$time,
  event = simulated_dataset$status
)

# Parameters
n_reps <- 20 # number of bootstraps
sample_size <- 100000 # sample size of each bootstrap
n_obs <- nrow(simulated_dataset$w) # number of obs in the original simulated dataset

# Store beta estimates
beta_list <- numeric(n_reps)

# Loop with random indices
set.seed(123)
for (i in seq_len(n_reps)) {
  idx <- sample(n_obs, sample_size, replace = TRUE)

  fit <- hapr(
    y = surv_obj[idx],
    gc = simulated_dataset$gc[idx, ],
    w = simulated_dataset$w[idx, ],
    model_type = "cox",
    improvement_ratio = input_summary$improvement_ratio
  )

  beta_list[i] <- fit$coefficients$beta["gf"]
}

# Plot histogram
tibble(beta = beta_list) |>
  ggplot(aes(x = beta)) +
  geom_histogram(bins = 30, fill = "skyblue", color = "black") +
  theme_minimal() +
  labs(title = "Distribution of beta['gf'] estimates",
       x = "beta['gf']", y = "Count")

# Print sample mean
mean_beta <- mean(beta_list)
print(paste("Mean of beta['gf'] estimates:", mean_beta))
