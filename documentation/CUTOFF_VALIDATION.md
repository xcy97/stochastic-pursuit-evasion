# Cutoff continuation validation

These independent ensembles assess the remaining-time proxy in the hybrid
estimate. They do not replace the historical Figure 6 ensembles. All runs use
mu=3, a=2.4, h=1e-4, R=.1, S=1, ve=1 and initial distance 1. The full-model
internal state starts at zero. The cutoff is 1000 and final horizon is 100000.

| Model | N | D | Trials | Uncaptured at 1000 |
|---|---:|---:|---:|---:|
| Full A | 1 | .004642 | 2000 | 253 |
| Full A | 1 | 31.6228 | 8000 | 309 |
| Full A | 3 | 31.6228 | 30000 | 307 |
| Simplified C control | 1 | .004642 | 2000 | 74 |

All trajectories are captured by the final horizon. The full-model hybrid
means are 5.13%, 9.14% and 8.11% below the complete means in the same ensembles.
These are observed biases at selected conditions, not a universal error bound.
Complete observation of these samples does not by itself prove convergence of
the population mean. The comparison uses the main-scan time resolution, not an
exact continuous-time benchmark.

Recompute saved results with Python and NumPy from the repository root:

    python analysis/cutoff_validation.py

This writes tables/cutoff_validation_results.csv and .json and checks them
against the archived expected statistics. Bootstrap intervals use 10000 draws
and seed 2026102901. They describe pointwise sampling uncertainty. The hybrid
and complete estimates are compared within the same ensemble.

For a new simulation, compile the independent Fortran program in a compiler
console (Intel Fortran Classic 2021.6 was used), then run from the repository:

    ifort /O3 /QxHost /exe:cutoff_validation.exe fortran/cutoff_validation.f90
    cutoff_validation.exe configs/cutoff_low_A.nml

The other three configurations reproduce the other conditions. Use a fresh
output prefix; the program refuses to overwrite results. Model 0 is full A;
model 1 uses aligned constant speed a/mu from the initial time. The state-file
column speed records norm(V); in model C it is an unused internal-state norm,
while the physical speed is a/mu.

At the cutoff, the actual positions and internal states of surviving paths
are saved and retained for continuation. Future noise uses an independent
seed domain, preserving the conditional process law. The main seed is
20261028 and formal trial IDs start at 100001. Runtime pilots are excluded.
Exact random streams require the recorded compiler/runtime and architecture.
The data files merge the originally generated batches in trial-ID order.

Probability notation and manuscript wording changes do not alter these
simulation results. The hybrid estimate includes elapsed time for every
uncaptured path plus an approximate remaining time; no path is discarded.
