# Code and data provenance

The time-step and three-model Fortran sources are copies of the completed validation programs. Numerical statements, paired random inputs and seed domains are retained. Introductory comments and package paths were organized for standalone distribution.

`fortran/main_model.f90` is a parameterized namelist driver for the full model. It retains the original old-state Euler-Maruyama kernel, zero internal initial state and endpoint capture rule, and provides explicit censoring, parameter recording and the elapsed-time-corrected hybrid estimate. It can generate new samples. The supplied manuscript data were not replaced by outputs from this driver. A historical full-model source is retained in `historical_source/` for inspection of the original equations and scan; it is not the recommended run entry.

Raw validation data are preserved in `inputs/`; the input manifest verifies their package hashes. Paths in parameter records are omitted where they only identify the original local working folder. Numerical records are unchanged. Plot input filenames were organized by panel; the individual plotting scripts use relative paths, so the package does not depend on the authors' drive letters.

Some older scans retain aggregate means and capture fractions rather than individual trials. Saved inputs reproduce those aggregates and the corresponding plotted results. Historical random-number seeds are not available for every scan. New runs therefore reproduce the numerical experiment, but do not guarantee identical individual paths or identical aggregate values.

Code development and documentation were assisted by ChatGPT and OpenAI Codex. The numerical and execution checks included with this version are described in `TEST_REPORT.json`. Runtime libraries, compiler binaries and third-party software are not distributed in this repository.
