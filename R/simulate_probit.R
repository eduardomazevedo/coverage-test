library(tidyverse)

simulate_probit <- function(n_observations, params, w_cache) { 
  covariate_names <- setdiff(names(params$theta), "(Intercept)")
  
  # Load w
  w <- w_cache$simulated_df |>
    slice_sample(n = n_observations, replace = TRUE) |>
    select(all_of(covariate_names))
  w[] <- lapply(w, function(col) as.numeric(col))
  
  # Simulate gf = theta * w + Gaussian noise
  w_with_intercept <- cbind("(Intercept)" = 1, w)
  stopifnot(identical(names(params$theta), c("(Intercept)", colnames(w))))
  gf <- as.matrix(w_with_intercept) %*% params$theta + rnorm(nrow(w), 0, sqrt(params$var_v))
  
  # Simulate gc = gf + gaussian noise
  gc <- gf + rnorm(nrow(w), 0, sqrt(params$var_epsilon))
  
  # Simulate disease status y
  design_matrix <- cbind("(Intercept)" = 1, "gf" = gf, w)
  design_matrix <- design_matrix[, names(params$beta)]
  stopifnot(identical(names(params$beta), names(design_matrix)))
  latent_y <- as.matrix(design_matrix) %*% params$beta + rnorm(nrow(w), 0, 1)
  y <- latent_y > 0
  
  # Return simulated dataset
  list(
    y = y,
    gc = gc,
    w = w
  )
}