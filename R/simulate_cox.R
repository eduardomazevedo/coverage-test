library(tidyverse)

simulate_cox <- function(
  n_observations,
  params,
  w_cache,
  target_average_hazard = NULL,
  base_rate = NULL
) {
  # Validate hazard/base rate inputs: exactly one must be provided
  if (is.null(target_average_hazard) == is.null(base_rate)) {
    # warning("Using default base rate of 0.00554.")
    base_rate <- 0.00554
  }
  if (!is.null(target_average_hazard)) {
    if (!is.numeric(target_average_hazard) || length(target_average_hazard) != 1 || is.na(target_average_hazard) || target_average_hazard <= 0) {
      stop("target_average_hazard must be a single positive numeric value.")
    }
  }
  if (!is.null(base_rate)) {
    if (!is.numeric(base_rate) || length(base_rate) != 1 || is.na(base_rate) || base_rate <= 0) {
      stop("base_rate must be a single positive numeric value.")
    }
  }
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

  # Calculate relative risk (hazard ratio)
  design_matrix <- cbind("(Intercept)" = 1, "gf" = gf, w)
  design_matrix <- design_matrix[, names(params$beta)]
  stopifnot(identical(names(params$beta), names(design_matrix)))
  linear_predictor <- as.matrix(design_matrix) %*% params$beta + rnorm(nrow(w), 0, 1)
  relative_risk <- exp(linear_predictor)

  # Calculate mean relative risk and choose base_rate accordingly
  mean_relative_risk <- mean(relative_risk)
  if (is.null(base_rate)) {
    base_rate <- as.numeric(target_average_hazard / mean_relative_risk)
  }
  average_hazard <- as.numeric(base_rate * mean_relative_risk)

  # Simulate censoring time uniform between 20 and 80 years
  censoring_time <- runif(nrow(w), 20, 80)

  # Simulate survival time
  survival_time <- rexp(nrow(w), base_rate * relative_risk)

  # Combine survival time and censoring time
  time <- pmin(survival_time, censoring_time)
  status <- (survival_time <= censoring_time)

  # Return simulated dataset
  list(
    time = time,
    status = status,
    gc = gc,
    w = w,
    base_rate = base_rate,
    average_hazard = average_hazard,
    mean_relative_risk = mean_relative_risk
  )
}
