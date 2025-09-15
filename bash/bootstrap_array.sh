#!/bin/bash
#$ -N bootstrap_array
#$ -q short.q
#$ -l m_mem_free=12G
#$ -t 1-276
#$ -j y
#$ -o job_output/$JOB_NAME-$JOB_ID-$TASK_ID.log
#$ -cwd

# Print job info
echo "Running task ID: $SGE_TASK_ID"
echo "Hostname: $(hostname)"
echo "Start time: $(date)"

# Run R script with the task ID as job_number
Rscript R/run_job_from_yaml.R --job_number=$SGE_TASK_ID

echo "End time: $(date)"
