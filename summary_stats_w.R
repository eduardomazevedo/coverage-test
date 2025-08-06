rm(list = ls())

library(tidyverse)

# Create output directory
dir.create("summary_stats/w", showWarnings = FALSE, recursive = TRUE)

# Load the simulated data
simulated_df <- readRDS("output/simulated_w.rds")

# Load the original inputs for comparison
inputs <- readRDS("input/means_sd_cov_mat.BRC.std.rds")
means <- as.numeric(inputs$means[1, ])
names(means) <- colnames(inputs$means)
cov_mat <- inputs$cov_mat

# Define variable names by type (same as in simulate_w.R)
binary_vars <- c("Smoker_i0", "ExSmoker_i0", "phys_inact_i0", "array_bit",
                 "ever_brc_screening_i0", "ever_hrt_i0", "ever_ocp_i0",
                 "ever_live_birth_bit", "mother_BRC", "siblings_BRC", "T1D_bit")

pos_cont_vars <- c("age_last_obs", "age_assess_i0", "bmi_i0",
                   "drinksweekly_i0", "sbp_i0", "eduyears", "age_menarche", "age_first_birth")

count_vars <- c("num_live_births")

unrestricted_vars <- c(paste0("pc", 1:10), "townsend_index")

all_vars <- c(binary_vars, pos_cont_vars, count_vars, unrestricted_vars)

# 1. Summary table
summary_stats <- data.frame(
  variable = names(simulated_df),
  mean = sapply(simulated_df, function(x) {
    if (is.logical(x)) {
      mean(as.numeric(x), na.rm = TRUE)
    } else {
      mean(x, na.rm = TRUE)
    }
  }),
  sd = sapply(simulated_df, function(x) {
    if (is.logical(x)) {
      sd(as.numeric(x), na.rm = TRUE)
    } else {
      sd(x, na.rm = TRUE)
    }
  }),
  min = sapply(simulated_df, function(x) {
    if (is.logical(x)) {
      min(as.numeric(x), na.rm = TRUE)
    } else {
      min(x, na.rm = TRUE)
    }
  }),
  max = sapply(simulated_df, function(x) {
    if (is.logical(x)) {
      max(as.numeric(x), na.rm = TRUE)
    } else {
      max(x, na.rm = TRUE)
    }
  }),
  median = sapply(simulated_df, function(x) {
    if (is.logical(x)) {
      median(as.numeric(x), na.rm = TRUE)
    } else {
      median(x, na.rm = TRUE)
    }
  })
)

write.csv(summary_stats, "summary_stats/w/summary_table.csv", row.names = FALSE)
cat("Summary table saved to summary_stats/w/summary_table.csv\n")

# 2. Target and simulated correlation matrices
# Subset covariance matrix to match our variables
cov_mat_subset <- cov_mat[all_vars, all_vars]
target_corr <- cov2cor(cov_mat_subset)

# Calculate simulated correlation matrix
simulated_corr <- cor(simulated_df)

write.csv(target_corr, "summary_stats/w/target_correlation_matrix.csv")
write.csv(simulated_corr, "summary_stats/w/simulated_correlation_matrix.csv")
cat("Correlation matrices saved to summary_stats/w/\n")

# 3. Target and simulated means
target_means <- means[all_vars]
simulated_means <- colMeans(simulated_df)

means_comparison <- data.frame(
  variable = names(target_means),
  target_mean = target_means,
  simulated_mean = simulated_means,
  difference = simulated_means - target_means,
  percent_diff = ((simulated_means - target_means) / target_means) * 100
)

write.csv(means_comparison, "summary_stats/w/means_comparison.csv", row.names = FALSE)
cat("Means comparison saved to summary_stats/w/means_comparison.csv\n")

# 4. Create histograms for all variables
# Set up the plotting device for 16:9 aspect ratio
pdf("summary_stats/w/variable_histograms.pdf", width = 16, height = 9)

# Calculate number of rows and columns for subplot layout
n_vars <- length(all_vars)
n_cols <- 6  # 6 columns
n_rows <- ceiling(n_vars / n_cols)

# Set up the layout
par(mfrow = c(n_rows, n_cols), mar = c(2, 2, 2, 1))

# Create histograms for each variable
for (var in all_vars) {
  if (var %in% binary_vars) {
    # For binary variables, create bar plot with frequencies
    counts <- table(simulated_df[[var]])
    freqs <- counts / sum(counts)
    barplot(freqs, main = var, xlab = "", ylab = "Frequency", 
            col = "lightblue", border = "black")
  } else if (var %in% count_vars) {
    # For count variables, create histogram with frequencies
    hist(simulated_df[[var]], main = var, xlab = "", ylab = "Frequency", 
         col = "lightgreen", border = "black", breaks = "Sturges", freq = FALSE)
  } else {
    # For continuous variables, create histogram with frequencies
    hist(simulated_df[[var]], main = var, xlab = "", ylab = "Frequency", 
         col = "lightcoral", border = "black", breaks = "Sturges", freq = FALSE)
  }
}

dev.off()
cat("Histograms saved to summary_stats/w/variable_histograms.pdf\n")

# 5. Additional summary statistics by variable type
cat("\n=== SUMMARY BY VARIABLE TYPE ===\n")

# Binary variables summary
cat("\nBinary Variables:\n")
binary_summary <- data.frame(
  variable = binary_vars,
  mean = sapply(simulated_df[binary_vars], function(x) mean(as.numeric(x), na.rm = TRUE)),
  prop_1 = sapply(simulated_df[binary_vars], function(x) mean(x, na.rm = TRUE))
)
print(binary_summary)

# Continuous variables summary
cat("\nContinuous Variables:\n")
cont_vars <- c(pos_cont_vars, unrestricted_vars)
cont_summary <- data.frame(
  variable = cont_vars,
  mean = sapply(simulated_df[cont_vars], mean, na.rm = TRUE),
  sd = sapply(simulated_df[cont_vars], sd, na.rm = TRUE)
)
print(cont_summary)

# Count variables summary
cat("\nCount Variables:\n")
count_summary <- data.frame(
  variable = count_vars,
  mean = sapply(simulated_df[count_vars], function(x) mean(x, na.rm = TRUE)),
  var = sapply(simulated_df[count_vars], function(x) var(x, na.rm = TRUE)),
  min = sapply(simulated_df[count_vars], function(x) min(x, na.rm = TRUE)),
  max = sapply(simulated_df[count_vars], function(x) max(x, na.rm = TRUE))
)
print(count_summary)

cat("\nAll summary files saved to summary_stats/w/ directory\n") 