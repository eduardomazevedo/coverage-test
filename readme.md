This repo performs coverage tests for the HAPR package.
- Input parameters are saved in assets/*.rds based on estimates from Richard.
- R/simulare_covariates.R has to be run first to create a large dataset of simulated covariates.
- Bootstrap jobs are listed in `list_of_jobs.yaml` and can be run with `Rscript R/run_job_from_yaml.R --job_number=N`. The bash script `bash/bootstrap_array.sh` submits all as a job in an SGE cluster.
- After running desired bootstrap jobs, run `R/collect_bootstraps.R` and `R/run_coverage_reports.R` to build nice summary of the results.

Our renv includes all needed packages but not HAPR so that user can install preferred HAPR version to be tested.