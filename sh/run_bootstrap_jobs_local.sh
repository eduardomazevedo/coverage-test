#!/bin/bash
#
# Run all bootstrap jobs locally in sequence
#

cd "$(dirname "$0")/.."

TOTAL_JOBS=54

for JOB_ID in $(seq 1 $TOTAL_JOBS); do
    echo "Job $JOB_ID / $TOTAL_JOBS"
    Rscript R/run_job.R "$JOB_ID"
done

echo "All jobs completed!"
