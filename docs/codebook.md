# means_sd_cov_mat.BRC.std.rds
This file is an RDS (R data serialization) object containing summary statistics and covariance matrices for a set of variables related to the disease type **BRC** (likely Breast Cancer). It is intended for use in statistical simulations or analyses.

## Structure
The RDS file contains a named list with the following elements:

- `disease`: Character string indicating the disease type (here, "BRC").
- `means`: A 1x36 data frame (tidytable/data.table/tibble) with the mean values for each variable.
- `sd`: A 1x36 data frame with the standard deviation for each variable.
- `binary_var`: A 1x36 data frame of logicals indicating which variables are binary (TRUE) or continuous (FALSE).
- `cov_mat`: A 35x35 covariance matrix for a subset of variables (see below for exact list).
- `cov_mat_pw_complete`: A 36x36 pairwise-complete covariance matrix for all variables (see below for exact list).

## Variable Counts
- **Binary covariates:** 12
- **Continuous covariates:** 24
- **Total variables:** 36

## Variables
There are 36 variables in total, including demographic, clinical, genetic, and lifestyle factors. They are divided into binary and continuous variables:

### Binary Variables (12)
- BRC_bit
- Smoker_i0
- ExSmoker_i0
- phys_inact_i0
- array_bit
- ever_brc_screening_i0
- ever_hrt_i0
- ever_ocp_i0
- ever_live_birth_bit
- mother_BRC
- siblings_BRC
- T1D_bit

### Continuous Variables (24)
- age_last_obs
- age_at_first_BRC
- pc1, pc2, ..., pc10 (principal components)
- age_assess_i0
- townsend_index
- eduyears
- bmi_i0
- drinksweekly_i0
- sbp_i0
- age_menarche
- num_live_births
- age_first_birth
- pgi_std_BRC_finngen
- pgi_std_BRC_zhang
- pgi_std_BRC_meta

## Covariance Matrices

### Variables in `cov_mat` (35x35)
All variables except `age_at_first_BRC`.

### Variables in `cov_mat_pw_complete` (36x36)
All variables.

---

# summary_object_brc_cox_snph2.rds
This file is an RDS object containing summary statistics from a Cox proportional hazards model fitted to **BRC** (Breast Cancer) data with SNP heritability analysis. It contains model parameters, confidence intervals, and heritability estimates.

## Structure
The RDS file contains a named list with the following elements:

- `model_type`: Character string indicating the model type ("cox").
- `beta`: Named numeric vector of 30 regression coefficients for covariates.
- `sd_beta`: Named numeric vector of standard errors for regression coefficients.
- `ci_beta`: Data frame with 4 columns (Estimate, Std.Error, Lower, Upper) containing confidence intervals.
- `gamma`: Named numeric vector of 30 genetic effect parameters.
- `theta`: Named numeric vector of 30 intercept and principal component parameters.
- `var_v`: Numeric value for genetic variance component (0.508).
- `var_epsilon`: Numeric value for environmental variance component (0.482).
- `improvement_ratio`: Numeric value for model improvement (1.93).
- `max_improvement_ratio`: Numeric value for maximum improvement (101).
- `r2_current`: Numeric value for current R² (0.0725).
- `r2_future`: Numeric value for future R² (0.14).
- `heritability_source`: Character string indicating heritability source ("r2_future").
- `r2_current_source`: Character string indicating R² source ("user_provided").
- `posterior`: List with 3 elements (a, b, c) containing posterior estimates.
- `base_hazard_conversion_ratio`: Named numeric value for baseline hazard conversion.

## Variables
The model includes 30 variables:

### Demographic and Clinical Variables
- age_first_birth, age_menarche, bmi_i0, drinksweekly_i0, eduyears
- ever_brc_screening_i0, ever_hrt_i0, ever_live_birth_bit, ever_ocp_i0
- ExSmoker_i0, mother_BRC, num_live_births, phys_inact_i0, sbp_i0
- siblings_BRC, Smoker_i0, T1D_bit, townsend_index

### Genetic Variables
- array_bit, gf, pc1, pc2, pc3, pc4, pc5, pc6, pc7, pc8, pc9, pc10

## Model Performance
- **Current R²:** 0.0725
- **Future R²:** 0.14
- **Heritability Source:** r2_future
- **Genetic Variance:** 0.508
- **Environmental Variance:** 0.482

---

# summary_object_brc_probit_snph2.rds
This file is an RDS object containing summary statistics from a Probit model fitted to **BRC** (Breast Cancer) data with SNP heritability analysis. It contains model parameters, confidence intervals, and heritability estimates.

## Structure
The RDS file contains a named list with the following elements:

- `model_type`: Character string indicating the model type ("probit").
- `beta`: Named numeric vector of 32 regression coefficients including intercept.
- `sd_beta`: Named numeric vector of standard errors for regression coefficients.
- `ci_beta`: Data frame with 4 columns (Estimate, Std.Error, Lower, Upper) containing confidence intervals.
- `gamma`: Named numeric vector of 32 genetic effect parameters including intercept.
- `theta`: Named numeric vector of 31 intercept and principal component parameters.
- `var_v`: Numeric value for genetic variance component (0.508).
- `var_epsilon`: Numeric value for environmental variance component (0.482).
- `improvement_ratio`: Numeric value for model improvement (1.93).
- `max_improvement_ratio`: Numeric value for maximum improvement (101).
- `r2_current`: Numeric value for current R² (0.0725).
- `r2_future`: Numeric value for future R² (0.14).
- `heritability_source`: Character string indicating heritability source ("r2_future").
- `r2_current_source`: Character string indicating R² source ("first_stage").
- `posterior`: List with 3 elements (a, b, c) containing posterior estimates.

## Variables
The model includes 32 variables (including intercept):

### Intercept and Demographic Variables
- (Intercept), age_first_birth, age_last_obs, age_menarche, bmi_i0, drinksweekly_i0, eduyears
- ever_brc_screening_i0, ever_hrt_i0, ever_live_birth_bit, ever_ocp_i0
- ExSmoker_i0, mother_BRC, num_live_births, phys_inact_i0, sbp_i0
- siblings_BRC, Smoker_i0, T1D_bit, townsend_index

### Genetic Variables
- array_bit, gf, pc1, pc2, pc3, pc4, pc5, pc6, pc7, pc8, pc9, pc10

## Model Performance
- **Current R²:** 0.0725
- **Future R²:** 0.14
- **Heritability Source:** r2_future
- **R² Current Source:** first_stage
- **Genetic Variance:** 0.508
- **Environmental Variance:** 0.482