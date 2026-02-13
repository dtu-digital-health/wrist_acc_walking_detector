# Wrist Accelerometer Walking Detector

Reproducible MATLAB pipeline for detection of walking bouts and extraction of gait-related metrics from wrist-worn accelerometer recordings.

If you use this software, please cite the publication (see also `CITATION.cff`).

## Quick start (minimal example)

### Requirements

- MATLAB `R2024b`

### Run demo

From the repository root:

```
matlab
addpath(genpath(fullfile(pwd, "src")));
run(fullfile("src","matlab","demo_run.m"));
```

## Repo Structure

```
.
├── src/matlab/          # Core source code
├── notebooks/           # Analysis & validation scripts
├── data/                # Input/output structure (placeholders only)
├── CHANGES.md           # Version history
├── CONTRIBUTING.md
├── CODE_OF_CONDUCT.md
└── LICENSE.md

```

**Maintainers**

This repository is maintained by Digital Health, DTU to support reproducible research and student projects.

*Please create [an issue](../../issues) to share references or ideas related to the development of this project.
