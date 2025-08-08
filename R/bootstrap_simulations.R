rm(list = ls())

library(hapr)
library(tidyverse)

source("R/simulate_probit.R")

n_observations <- 1000
n_bootstraps <- 10
w_cache <- readRDS("data/simulated_covariates.rds")
params <- readRDS("assets/summary_object_brc_probit_snph2.rds")

true_beta <- params$beta
true_beta_names <- names(true_beta)

simulated_dataset <- simulate_probit(n_observations, params, w_cache)

fit <- hapr::hapr(
  y = simulated_dataset$y,
  gc = simulated_dataset$gc,
  w = simulated_dataset$w,
  model_type = "probit",
  improvement_ratio = params$improvement_ratio
)

beta_hat <- fit$coefficients$beta
se_hat <- fit$standard_errors
stopifnot(identical(names(beta_hat), names(se_hat)))
stopifnot(identical(names(beta_hat), true_beta_names))
