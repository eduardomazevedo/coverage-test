library(tidyverse)
simulate_model <- function(n_observations, beta_g, beta_w, beta_constant, theta, var_v, var_epsilon, e_w, vcov_w, model_type) {
  # Validation
  # model_type: "probit", "cox", "lm"
  stopifnot(model_type %in% c("probit", "cox", "lm"))

  # beta_w and theta: same length and same names
  stopifnot(
    length(beta_w) == length(theta),
    identical(names(beta_w), names(theta))
  )

  # e_w and vcov_w: length matches ncol and names match column names
  stopifnot(
    length(e_w) == ncol(vcov_w),
    identical(names(e_w), colnames(vcov_w))
  )

  # e_w and theta: same length and same names
  stopifnot(
    length(e_w) == length(theta),
    identical(names(e_w), names(theta))
  )

  # var_v + var_epsilon <= 1
  stopifnot(var_v + var_epsilon <= 1)

  # Simulate dataset
  # w ~ gaussian(e_w, vcov_w)
  w <- MASS::mvrnorm(n_observations, e_w, vcov_w)

  # gf = theta * w + Gaussian noise
  gf <- (w - e_w) %*% theta + rnorm(nrow(w), 0, sqrt(var_v))
  
  # gc = gf + gaussian noise
  gc <- gf + rnorm(nrow(w), 0, sqrt(var_epsilon))
  
  # y lm
  if (model_type == "lm") {
  y <- (w - e_w) %*% beta_w + gf * beta_g + beta_constant + rnorm(nrow(w), 0, 1)
  }

  # y probit
  if (model_type == "probit") {
    y <- (w - e_w) %*% beta_w + gf * beta_g + beta_constant + rnorm(nrow(w), 0, 1)
    y <- y > 0
  }

  # y cox
  if (model_type == "cox") {
    # For 'cox', y is linear predictor, so event times t ~ exp with rate = exp(y)
    linear_predictor <- (w - e_w) %*% beta_w + gf * beta_g + beta_constant
    t_event <- rexp(n = nrow(w), rate = exp(linear_predictor))

    # t censoring ~ uniform between 20 and 80
    t_censoring <- runif(n = nrow(w), min = 20, max = 80)

    # t = min(t_event, t_censoring)
    t <- pmin(t_event, t_censoring)

    # status = 1 if t_event <= t_censoring, 0 otherwise
    status <- (t_event <= t_censoring)

    # y = survival::Surv(t, status)
    y <- survival::Surv(t, status)
  }

  # Create column names
  if (is.null(colnames(w))) {
    colnames(w) <- paste0("V", seq_len(ncol(w)))
  }

  # Return simulated dataset
  list(
    y = y,
    gc = gc,
    w = w |> as_tibble(.name_repair = "minimal")
  )
}