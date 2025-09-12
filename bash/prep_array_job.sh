#!/bin/bash
#$ -N prepare_array
#$ -q short.q
#$ -l m_mem_free=12G
#$ -o job_output/$JOB_NAME-$JOB_ID-$TASK_ID.log
#$ -cwd

# Print job info
echo "Running preparation script"
echo "Hostname: $(hostname)"
echo "Start time: $(date)"

# Run R script with the task ID as job_number
Rscript R/simulate_covariates.R
Rscript R/summary_stats_w.R
Rscript R/runtimes.R
Rscript R/yaml_job_list_generator.R

echo "End time: $(date)"
