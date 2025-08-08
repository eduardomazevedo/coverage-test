rm(list = ls())
source("R/simulate_cox.R")
library(hapr)
library(survival)

params <- readRDS("assets/summary_object_brc_cox_snph2.rds")
w_cache <- readRDS("data/simulated_covariates.rds")

simulated <- simulate_cox(
  n_observations = 1e4,
  params = params,
  w_cache = w_cache
)

# Build full Surv object once
surv_obj <- Surv(
  time = simulated$time,
  event = simulated$status
)

fit <- hapr::hapr(
  y = surv_obj,
  gc = simulated$gc,
  w = simulated$w,
  model_type = "cox",
  improvement_ratio = params$improvement_ratio
)

beta_hat <- fit$coefficients$beta
se_hat <- fit$standard_errors