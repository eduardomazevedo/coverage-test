# Realistic simulations for HAPR probit and Cox
- This performs a realistic simulation of the Cox model and [TODO] checks that the estimates recover the correct parameters. The simulation is based on breast cancer data from the UK biobank.
- `input/` has numbers from Richard. There are statistics on the covariates that we use to simulate `w` and fitted parameters of the Cox model that we use to simulate polygenic scores and outcomes.
- `output` includes any datasets we produce.
- `summary_stats` includes figures and reports that we produce.

# Pipeline
- `simulate_w.R` creates a dataset of 100,000 simulated w covariates.
- `summary_stats_w.R` saves basic diagnostic summary stats about w.
- `simulate_probit.R` simulates dataset for probit model with w, gc, and binary disease outcome y.
- `simulate_cox.R` simulates dataset for probit model with w, gc, and status and event times assuming random censoring.
- TODO:
    - (Amrith) `test_probit.R`: write a script that estimates the probit model. Check that the estimates match the parameters Richard had. Load HAPR packages as submodule if needed to install HAPR. This is just a quick first version, we will produce a more polished version once we make sure this is roughly working and get spec from Jonathan.
    - (Amrith) `test_cox.R`: same thing for the Cox model.
    - (Jonathan): decide EXACTLY what output you want to produce here for the paper.