get_richard_params <- function(model_type, snp_source) {
  # Validate inputs
  if (!model_type %in% c("cox", "probit", "lm")) {
    stop("model_type must be either 'cox', 'probit', or 'lm'")
  }
  
  if (!snp_source %in% c("snph2", "twinh2")) {
    stop("snp_source must be either 'snph2' or 'twinh2'")
  }
  
  # Construct filename based on parameters
  if (model_type == "lm") {
    filename <- paste0("summary_object_brc_", "probit", "_", snp_source, ".rds")
  } else {
    filename <- paste0("summary_object_brc_", model_type, "_", snp_source, ".rds")
  }
  filepath <- file.path("assets", filename)
  
  # Check if file exists
  if (!file.exists(filepath)) {
    stop("Parameter file not found: ", filepath)
  }
  
  # Load and return the parameters
  params <- readRDS(filepath)  
  if (model_type == "lm") {
    params$model_type <- "lm"
  }
  return(params)
}