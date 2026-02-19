# Wrist Accelerometer Walking Detector

Reproducible MATLAB pipeline for detection of walking bouts and extraction of gait-related metrics from wrist-worn accelerometer recordings.

If you use this software, please cite the publication (see also `CITATION.cff`).

## Quick start (minimal example)

### Requirements

- MATLAB `R2024b`

## Running the code

The main entry point for a minimal end-to-end run is:

- `src/matlab/demo_run.m`

This demo is designed for **long free-living recordings** and will:

1. Save **one CSV per input file** with detected walking bouts + walking metrics in:
   - `data/actigraphy/walking_bouts/`
2. Save an aggregated **feature CSV across all files** to the location you specify via `path_feat`.

### 1) Prepare your data

Place your actigraphy files (default: `.cwa`) in a folder on your machine, e.g.:

- Windows: `C:\path\to\my_actigraphy\`
- macOS/Linux: `/path/to/my_actigraphy/`

The demo looks for files using:

```matlab
data_subjects = dir(filepath(path_to_actigraphy, ['*.' extension_actigraphy]));
```

So path_to_actigraphy must point to the folder containing your actigraphy files.

### 2) Prepare your data

Open `src/matlab/demo_run.m`

and set the two required paths:

- `path_to_actigraphy` — folder containing input actigraphy files
- `path_feat` — output location for the aggregated feature CSV

### 3) Run the demo

From the repository root in MATLAB:
```
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

## Third-party software

This repository redistributes external tools under their respective licenses:

- `src/matlab/export_fig/` — BSD-style license (Woodford & Altman)
- `src/matlab/icp/` — BSD-style license (Per Bergström)

See the LICENSE files inside those folders for details.