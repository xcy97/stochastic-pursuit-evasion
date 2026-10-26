# Numerical methods and supplied data

## Model and analytical reference

The full model follows the equations in Section 2 of the manuscript. Every drift term is evaluated at the old state in an Euler-Maruyama step. Capture occurs at a grid endpoint when the minimum chaser-evader separation is at most R. Uncaptured paths are retained with a censoring flag at Tmax.

The analytical evaluator uses Gauss-Legendre quadrature for the outer integral over initial separation and Gauss-Laguerre quadrature for the unbounded inner integral, after substituting z=y+(D/v)u with v=a/mu. It uses `expm1` in the exponential difference and compares orders 128 and 160. This calculates Eq. (25) for the aligned, quasi-steady model.

For the Figure 6 aggregate input, the corrected hybrid estimate is `old_hybrid + (1-capture_rate)*Tmax`. This retains the original single-chaser tail proxy and adds the elapsed observation cutoff for each uncaptured path. The correction does not validate the proxy as the conditional remaining time at the actual multichaser state. The source scan permitted one extra 1e-4 step after the nominal cutoff; its maximal possible effect on these aggregate means is approximately 1.224e-5.

## Validation records

`inputs/step/trajectories.csv` has 12000 rows: four parameter conditions, 1000 paired trial identifiers per condition and three time steps. `inputs/models/trajectories.csv` has 18000 rows: six conditions, 1000 paired identifiers and three models. Primary fields are:

| Field | Meaning |
|---|---|
| `case_id`, `trial_id` | Parameter condition and within-condition paired trial identifier |
| `mu`, `a`, `D` | Model parameters |
| `h`, `Tmax` | Integration step and observation cutoff |
| `model` | A, B or C, for the model experiment |
| `observed_time` | Capture time when captured; otherwise the cutoff |
| `captured`, `censored` | Binary capture and right-censoring indicators |
| `em_updates` | Number of Euler-Maruyama steps |
| `master_seed` | Master seed used by the validation driver |

Other model fields store alignment and speed diagnostics. Parameter and compiler details are in the corresponding `run_info.txt`. The `summary.csv`, `paired_differences.csv` and timing/curve files are original driver outputs. The analysis uses individual trial records to reproduce the final statistics and compares them with the summaries.

`inputs/new_capture/trajectories.txt` contains 1000 rows for D=0.002154, mu=3, a=2.4, h=1e-4 and Tmax=1e6. Columns are trial identifier, time, capture indicator and censoring indicator. All 1000 paths were captured, with mean 73887.735296 to the manuscript precision. Applying a shorter cutoff to this same saved sample is a data diagnostic, not an additional simulation.

`inputs/legacy/figure_data.json` retains the main single-chaser aggregate values and their observation horizons. It is sufficient to reconstruct the reported main-scan statistics, but does not contain individual trajectories for every historical condition. At D=0.001 in Figure 3 no simulated mean is available because no path was captured within the stated cutoff.

## Bootstrap and reported differences

`analysis/analyze_results.py` uses 10000 percentile-bootstrap resamples. Trial indices are resampled together across coupled steps or models to preserve pairing. A parameter-dependent seed is derived from the documented base seed and SHA-256 key. Interval endpoints are the 2.5th and 97.5th percentiles, using NumPy's linear quantile convention.

The step comparison reports `100*(mean_h - mean_1e-6)/mean_1e-6`. The paired model effects AB, BC and AC are each divided by the full-model A mean. The model C analytical difference is `100*(mean_C - T_analytic)/T_analytic`. The code recalculates both the point estimates and their corresponding bootstrap intervals.

## Figure data and display choices

`matlab/revision_data/` contains the analytical curves, main-scan statistics and fine-grid/three-model estimates used by the revised figures and tables. `tables/` contains the corresponding calculation inputs and derived statistical outputs. Five LaTeX table bodies are in `generated_tables/`; captions and labels remain in the manuscript.

`matlab/data/` contains the saved speed/path records for Figures 1-2, the capture-time distributions for Figures 7 and 9, and the Figure 8 aggregate input. The histogram inputs are named by panel, for example `fig9a_capture_times.txt`. Figure 9(a) has 10000 captures with full-sample mean 1.72038458. Panel parameters are listed in `documentation/FIGURE_MAP.csv` and in each plotting script.

The speed plots retain their original display smoothing, with raw records provided. Histogram scripts calculate the mean from all valid capture times. Most display the central 0.2%-99.8% of the sample and normalize that displayed subset as a probability density. Thus the displayed histogram is not a plot of every tail observation; raw capture times remain available. These display choices do not change the full-sample mean.

The main simulation driver writes new raw trial records using the same capture/censoring definitions. Its optional state curves contain both the internal vector V and its norm; V itself is not the actual chaser velocity vector.
