rm(list = ls())

source("R/run_bootstrap.R")

n_obs <- 1e5
n_bootstraps <- 1e0
model_type <- "cox"
heritability_source <- "snph2"
softmax_correction <- "softmax-slow"

bootstrap_results <- run_bootstrap(
  model_type = model_type,
  heritability_source = heritability_source,
  softmax_correction = softmax_correction,
  n_obs = n_obs,
  n_bootstraps = n_bootstraps
)

# report <- coverage_report(
#   bootstrap_results = bootstrap_results,
#   output_folder = "output/scratch"
# )
