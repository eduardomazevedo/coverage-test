#!/bin/bash
#$ -N bootstrap_array
#$ -q short.q
#$ -l m_mem_free=12G
#$ -t 1-124
#$ -cwd
#$ -o logs/
#$ -e logs/

# Create logs directory if it doesn't exist
mkdir -p logs

# Print job info
echo "Running task ID: $SGE_TASK_ID"
echo "Hostname: $(hostname)"
echo "Start time: $(date)"

# Run R script with the task ID as job_number
Rscript R/run_job_from_yaml.R --job_number=$SGE_TASK_ID

echo "End time: $(date)"
