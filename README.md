# Stochastic pursuit evasion

Code and data for **Stochastic pursuit-evasion with variable-speed chasers and an actively avoiding evader**, by Chaoyang Xiang, Meng Su and Wei Xu.

This repository contains the full stochastic model, the single-chaser analytical mean capture time (MCT) calculation, time-step and model-approximation checks, and the saved data and MATLAB programs for the manuscript figures and numerical tables.

## Start here

Download the complete repository using **Code > Download ZIP** and extract it. Keep all subfolders together.

There are two workflows:

* **Reproduce results from the supplied data.** Run the MATLAB entries to plot figures, or run the Python analysis to recalculate statistics. This does not start a new simulation.
* **Generate new simulation samples.** Compile one of the Fortran programs and choose the required parameters and sample size. Full production runs can be expensive, especially at low noise.

For a quick visual check, open `matlab/run_revision_figures.m` in MATLAB and click **Run**. It displays Figures 3, 4, 6 and the two panels of Figure A.1. Open `matlab/reproduce_tables.m` for Tables 1, 2 and A.1-A.3. No Python installation is required to display these saved-data results.

Individual entries `matlab/fig1a.m` through `matlab/fig9e.m` produce the other panels. These entries save their images in `matlab/output/`. The five revision-figure entries display their figures without automatic export. `matlab/export_revision_tables.m` optionally exports CSV and LaTeX tables to a chosen directory.

The full figure-to-code mapping and parameter sets are in [FIGURE_MAP.csv](documentation/FIGURE_MAP.csv). Numerical definitions and input fields are described in [METHODS_AND_DATA.md](documentation/METHODS_AND_DATA.md).

## Software

Tested environment:

* Windows x64; Intel Fortran Classic 2021.6.0, optimized compilation.
* MATLAB R2021b with Statistics and Machine Learning Toolbox for `prctile`, and Signal Processing Toolbox for the tested speed-curve smoothing. The scripts also use `exportgraphics`, `readtable` and `readmatrix`. Speed plots include a `smoothdata` fallback when `sgolayfilt` is absent; use the tested Signal Processing Toolbox implementation to match the smoothing exactly.
* Python 3.12.14, NumPy 2.3.5 and pandas 3.0.1. Exact tested package versions are in `requirements-tested.txt`; broader dependency ranges are in `requirements.txt`.

The original validation drivers use Windows `cmd` to create timestamped result folders. Their command-line operation has been tested on Windows. The main model uses standard Fortran features; other platforms have not been tested here.

## Recalculate the numerical results

From the extracted repository root:

```text
python -m pip install -r requirements-tested.txt
python analysis/reproduce.py
```

The analysis checks the retained input hashes, trial identifiers, capture indicators, time steps and paired sample relationships. It recalculates 10000-resample confidence intervals, model comparisons, the analytical reference values, all 65 elapsed-time-corrected Figure 6 values, and five LaTeX table bodies. It compares the recalculated results with the supplied figure data before updating derived files.

Outputs are written to `tables/` and `generated_tables/`, and the corresponding derived inputs in `matlab/revision_data/` are refreshed. Raw files in `inputs/` are not changed. A successful run ends with `PASS: statistics, quadrature, 65 hybrid values and five table bodies reconstructed.`

To evaluate the single-chaser analytical expression in Eq. (25) separately:

```text
python analysis/analytical_mct.py --mu 3 --a 2.4 --D .002154 .004642 31.6228
```

The output includes quadrature orders 128 and 160 and their relative change. This expression applies to the aligned, quasi-steady process (model C); its accuracy for the full model A is assessed separately in the manuscript. The constants R=0.1, S=1, ve=1 and initial distance 1 are explicit in the function and must also be changed if another setting is required.

## Compile and test the simulation programs

Compile the three programs **separately** in an Intel Fortran command prompt, with the repository root as working directory:

```text
ifort /O2 /stand:f08 /exe:main_model.exe fortran/main_model.f90
ifort /O2 /exe:stepcheck.exe fortran/stepcheck.f90
ifort /O2 /exe:three_models.exe fortran/three_models.f90
```

With Visual Studio, create a separate Intel Fortran Console project for each complete source file. Use Release/x64. Set the working directory to the extracted repository root and provide the arguments shown below. Do not put three main programs in one project.

Short installation checks:

```text
main_model.exe configs/smoke.nml
stepcheck.exe --trials=2 --case=1 --tmax=.001 --bootstrap=100 --output=results
three_models.exe --trials=2 --case=1 --tmax=.001 --bootstrap=100 --curves=0 --output=results
```

These are two-path tests with a short horizon, so capture need not occur. They are not scientific estimates. The main-model output prefix must be new on each run; files are opened with `status='new'` to prevent overwriting previous results. Change `output_prefix` in the namelist before repeating it.

## Full model

`fortran/main_model.f90` implements the full two-dimensional model using old-state Euler-Maruyama updates. Chasers move along their instantaneous line of sight at speed norm(V); V is the internal speed-response vector. Capture is checked at time-step endpoints. No Brownian-bridge capture correction is applied.

Run a selected namelist, for example:

```text
main_model.exe configs/fig9a.nml
```

The `configs/` files are individual-condition examples, not automatic complete figure sweeps. Apart from `smoke.nml`, they use production sample sizes; inspect them before running. Parameters include:

| Namelist field | Meaning |
|---|---|
| `nch`, `ntrials` | Chaser count N and independent trial count |
| `d`, `mu`, `a` | Noise intensity D, internal relaxation rate and driving strength |
| `h`, `tmax` | Time step and observation cutoff |
| `radius`, `perception`, `ve` | Capture radius R, response length S and active-evasion scale |
| `r_initial` | Initial circle radius around the evader |
| `master_seed` | Master seed for the new simulation |
| `record_every` | Save state curves every this many steps; 0 disables curves |
| `tail_proxy` | Analytical remaining-time proxy; a negative value disables the hybrid estimate |
| `output_prefix` | Relative prefix of new result files |

The evader starts at the origin. N chasers are equally spaced on the initial circle and start with zero internal state. Each trial gets its own derived random seed.

The driver writes `_trials.csv`, `_summary.csv` and `_run_info.txt`. If enabled, `_curves.csv` records positions, internal states, speed and separation. The summary distinguishes the captured-only mean, complete-sample mean, restricted observation mean and hybrid estimate. A value of -1 in an unavailable mean or proxy field is a missing-value marker, not a negative capture time.

When a nonnegative `tail_proxy` is supplied, each uncaptured path contributes **Tmax + tail_proxy**. The proxy can be calculated with `analysis/analytical_mct.py` for the corresponding single-chaser parameters. It is a model approximation to the remaining time, not a state-conditioned exact expectation. `analysis/calculate_figure6.py` reproduces the manuscript's corrected Figure 6 directly from retained aggregate inputs.

## Time-step experiment

```text
stepcheck.exe --trials=1000 --bootstrap=2000 --tmax=100000 --output=results
```

Cases 1-4 are (mu,a,D) = (3,2.4,10), (3,2.4,31.6228), (3,2.4,0.215443), (30,29.97,31.6228). Each uses h=1e-4, 1e-5 and 1e-6, with shared Brownian increments. Coarse increments are sums of the fine increments while the corresponding levels are active. Use `--case=1` to select one condition; `--level=0` retains all three coupled levels. The default trial count is 1000 per condition.

## Three-model experiment

```text
three_models.exe --trials=1000 --bootstrap=2000 --tmax=100000 --output=results
```

There are six conditions: first (mu,a)=(3,2.4), then (30,29.97), each at D=0.021544, 0.215443 and 31.6228. The time step is 1e-6. Each trial couples three models through the same Cartesian Brownian increments:

* A: full internal-state model.
* B: aligned transient speed (a/mu)(1-exp(-mu*t)), starting from zero speed.
* C: aligned constant speed a/mu from t=0.

Each model uses its own positions and line-of-sight direction. The program creates a timestamped folder containing individual trial records, summaries, paired differences, timing and parameter/compiler information. `--curves=0` disables the first two example trajectories. The default is 1000 trials per condition.

## Verification and interpretation

Run `verify_reproduction` from the MATLAB `matlab/` folder to execute all 23 figure entries and check the five table sizes. It temporarily hides and closes its generated figure windows; original figure entries may save their usual images inside `matlab/output/`.

[TEST_REPORT.json](documentation/TEST_REPORT.json) records the tested environment and validation results. The checks include compilation and short runs of the three Fortran programs, an independent deterministic full-model calculation, saved-sample analysis, and all MATLAB figure entries. Full production simulations were not repeated during package verification.

The supplied samples reproduce the reported sample statistics. New Monte Carlo runs may produce different numbers: not all historical scans retained deterministic seeds, and Fortran random-number streams can vary with compiler/version. Three fine-grid A ensembles are shared between the time-step and model experiments; the analysis checks their identity rather than treating them as independent replications.

Confidence intervals quantify finite-sample uncertainty. They do not include time-discretization or model-approximation bias and are not simultaneous intervals for all comparisons. The Fortran summaries use 2000 bootstrap resamples; the final numerical tables use the documented Python 10000-resample calculation.

Further data-processing and provenance details are in [METHODS_AND_DATA.md](documentation/METHODS_AND_DATA.md) and [PROVENANCE.md](documentation/PROVENANCE.md).


## Additional cutoff continuation validation

The independent validation of the Figure 6 remaining-time proxy is documented in [documentation/CUTOFF_VALIDATION.md](documentation/CUTOFF_VALIDATION.md). Run `python analysis/cutoff_validation.py` to recompute the four archived ensembles. The hybrid estimates remain approximations; the validation reports their observed bias without replacing the original Figure 6 data.
