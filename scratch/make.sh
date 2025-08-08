#!/bin/bash

# Simulation pipeline script
# Runs all simulation scripts in order

echo "Starting simulation pipeline..."

echo "1. Running simulate_w.R..."
Rscript simulate_w.R
if [ $? -ne 0 ]; then
    echo "Error: simulate_w.R failed"
    exit 1
fi

echo "2. Running summary_stats_w.R..."
Rscript summary_stats_w.R
if [ $? -ne 0 ]; then
    echo "Error: summary_stats_w.R failed"
    exit 1
fi

echo "3. Running simulate_cox.R..."
Rscript simulate_cox.R
if [ $? -ne 0 ]; then
    echo "Error: simulate_cox.R failed"
    exit 1
fi

echo "4. Running simulate_probit.R..."
Rscript simulate_probit.R
if [ $? -ne 0 ]; then
    echo "Error: simulate_probit.R failed"
    exit 1
fi

echo "Simulation pipeline completed successfully!" 