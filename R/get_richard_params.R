#
#' Load Richard parameter inputs for bootstrap simulations.
#'
#' Fetches Richard's parameter summary objects and covariate distributions from
#' `assets/` and returns the subset required by downstream bootstrap routines.
#'
#' @param model_type Character scalar, one of `"cox"`, `"probit"`, or `"lm"`, that
#'   determines which summary object to read and how to derive `lp_mean`.
#' @param snp_source Character scalar, either `"snph2"` or `"twinh2"`, selecting
#'   the SNP heritability source embedded in the summary object filename.
#'
#' @return A named list containing `beta_g`, `beta_w`, `lp_mean`, `theta`,
#'   `var_v`, `var_epsilon`, `e_w`, and `vcov_w`. For cox model lp_mean is
#'   median linear predictor that we set to 1 / 20 years.
#'
#' @examples
#' params <- get_richard_params(model_type = "cox", snp_source = "snph2")
#' str(params)
#'
get_richard_params <- function(model_type, snp_source) {
  # Validate inputs
  if (!model_type %in% c("cox", "probit", "lm")) {
    stop("model_type must be either 'cox', 'probit', or 'lm'")
  }
  
  if (!snp_source %in% c("snph2", "twinh2")) {
    stop("snp_source must be either 'snph2' or 'twinh2'")
  }
  
  # Read params
  type <- if (model_type %in% c("lm", "probit")) "probit" else model_type
  filename <- paste0("summary_object_brc_", type, "_", snp_source, ".rds")
  filepath <- file.path("assets", filename)
  richard_params <- readRDS(filepath)

  covariate_names <- setdiff(names(richard_params$theta), "(Intercept)")

  # Read Richard's covariate distribution
  richard_covariate_distribution <- readRDS(file.path("assets", "means_sd_cov_mat.BRC.std.rds"))
  e_w <- richard_covariate_distribution$means[covariate_names] |> as.numeric()
  names(e_w) <- covariate_names
  vcov_w <- richard_covariate_distribution$cov_mat[covariate_names, covariate_names] |> as.matrix()
  colnames(vcov_w) <- covariate_names
  rownames(vcov_w) <- covariate_names

  var_v <- richard_params$var_v
  var_epsilon <- richard_params$var_epsilon

  theta <- richard_params$theta[covariate_names]
  beta_w <- richard_params$beta[covariate_names]
  beta_g <- richard_params$beta['gf']

  # Get beta_constant the average value of the linear predictor
  has_intercept <- "(Intercept)" %in% names(richard_params$beta)
  if (has_intercept) {
    beta_intercept <- richard_params$beta['(Intercept)']
  } else {
    beta_intercept <- 0
  }

  return(list(
    beta_g = beta_g,
    beta_w = beta_w,
    beta_intercept = beta_intercept,
    theta = theta,
    var_v = var_v,
    var_epsilon = var_epsilon,
    e_w = e_w,
    vcov_w = vcov_w))
}