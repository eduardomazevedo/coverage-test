rm(list = ls())

source("R/bootstrap_simulations.R")
source("R/coverage_report.R")
source("R/simulate_cox.R")
source("R/simulate_probit.R")

params <- readRDS("assets/summary_object_brc_cox_snph2.rds")
w_cache <- readRDS("data/simulated_covariates.rds")
n_obs <- 1e3
n_bootstraps <- 1e1

bootstrap_results <- bootstrap_simulations(
  n_obs = n_obs,
  n_bootstraps = n_bootstraps,
  parameters = params,
  w_pool = w_cache,
  softmax_correction = "softmax-slow")

report <- coverage_report(
  bootstrap_results = bootstrap_results,
  parameters = params,
  output_folder = "output/scratch"
)
