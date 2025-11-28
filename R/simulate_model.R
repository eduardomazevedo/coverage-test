library(tidyverse)
#' Simulate dataset for hapr model.
#'
#' @param n_observations Number of observations to simulate.
#' @param beta_g Coefficient for genetic factor.
#' @param beta_w Coefficient vector for covariates.
#' @param theta Adjusted theta parameter vector.
#' @param var_v Variance component for v.
#' @param var_epsilon Variance component for epsilon.
#' @param e_w Expected value vector for w.
#' @param vcov_w Variance-covariance matrix for w.
#' @param model_type Model type ("lm", "probit", or "cox").
#' @param beta_intercept Intercept coefficient (default: 0).
#' @param cox_censoring_time Censoring time for Cox model (default: 10).
#' @param cox_median_event_probability Event probability for median person for Cox model (default: 0.5).
#' @return List with y (response), gc (genetic component), and w (covariates tibble).
simulate_model <- function(n_observations, beta_g, beta_w, theta, var_v, var_epsilon, e_w, vcov_w, model_type, beta_intercept = 0, cox_censoring_time = 10, cox_median_event_probability = 0.5) {
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

  # Calculate theta_intercept terms so that mean of gf is zero and mean of lp is lp_mean
  theta_intercept <- as.numeric(- theta %*% e_w)

  # Simulate dataset
  # w ~ gaussian(e_w, vcov_w)
  w <- MASS::mvrnorm(n_observations, e_w, vcov_w)

  # gf = theta * w + Gaussian noise
  gf <- w %*% theta + theta_intercept + rnorm(nrow(w), 0, sqrt(var_v))
  
  # gc = gf + gaussian noise
  gc <- gf + rnorm(nrow(w), 0, sqrt(var_epsilon))

  # Linear predictor
  lp <- w %*% beta_w + gf * beta_g + beta_intercept
  
  # y lm
  if (model_type == "lm") {
    y <- lp + rnorm(nrow(w), 0, 1)
  }

  # y probit
  if (model_type == "probit") {
    y <- (lp + rnorm(nrow(w), 0, 1)) > 0
  }

  # y cox
  if (model_type == "cox") {
    median_lp <- as.numeric(e_w %*% beta_w + beta_intercept)
    rate<- -1 / cox_censoring_time * log(1 - cox_median_event_probability)

    # For 'cox', y is linear predictor, so event times t ~ exp with rate = exp(y)
    t_event <- rexp(n = nrow(w), rate = exp(lp - median_lp) * rate)

    # t = min(t_event, t_censoring)
    t <- pmin(t_event, cox_censoring_time)

    # status = 1 if t_event <= t_censoring, 0 otherwise
    status <- (t_event <= cox_censoring_time)

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