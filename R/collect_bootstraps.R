# collect_bootstraps.R
library(purrr)
library(dplyr)
library(fs)
library(readr)

# Directories
input_dir <- "data/bootstrap_chunks"
output_dir <- "data/bootstraps_by_spec"
dir_create(output_dir)

# Helper: safely read RDS
safe_read_rds <- safely(readRDS)

# List and read all RDS files
rds_files <- dir_ls(input_dir, regexp = "\\.rds$")
results <- map(rds_files, safe_read_rds)

# Filter out failures
valid_results <- keep(results, ~ !is.null(.x$result))

# Extract spec + object
parsed <- map(valid_results, function(x) {
  obj <- x$result
  tibble(
    file = attr(x, "names"),  # capture filename
    model_type = obj$model_type,
    heritability_source = obj$heritability_source,
    n_obs = obj$n_obs,
    n_bootstraps = obj$n_bootstraps,
    object = list(obj)
  )
}) |> bind_rows()

# Group by full spec (without softmax)
grouped <- parsed |> group_split(model_type, heritability_source, n_obs)

# Process each group
walk(grouped, function(group_df) {
  first_obj <- group_df$object[[1]]
  
  spec_id <- paste0(
    "model=", group_df$model_type[1],
    "_h=", group_df$heritability_source[1],
    "_n=", group_df$n_obs[1]
  )
  
  # Check true_beta consistency
  true_betas <- map(group_df$object, ~ .x$true_beta)
  if (!all(map_lgl(true_betas, ~ identical(.x, true_betas[[1]])))) {
    warning("Inconsistent true_beta across chunks for spec: ", spec_id, " — skipping")
    return()
  }

  # Stack outputs
  betas_df <- map_dfr(group_df$object, ~ .x$betas_df, .id = "chunk")
  se_df <- map_dfr(group_df$object, ~ .x$se_df, .id = "chunk")

  # Save combined object
  final_obj <- list(
    model_type = group_df$model_type[1],
    heritability_source = group_df$heritability_source[1],
    n_obs = group_df$n_obs[1],
    n_bootstraps = nrow(betas_df),
    true_beta = true_betas[[1]],
    betas_df = betas_df,
    se_df = se_df
  )

  write_rds(final_obj, file = path(output_dir, paste0(spec_id, ".rds")))
})
