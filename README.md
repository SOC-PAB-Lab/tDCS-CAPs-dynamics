# tDCS-CAPs-dynamics

Code for the paper:

**Bilateral M1 tDCS modulates dynamic large-scale brain states associated with sensorimotor control** <br>
Salameh H\*, Muffel T\*, Serhan Y, Samara M, Nenning K-H, Hertz U, Villringer A, Sehm B#, Ovadia-Caro S# <br>
(\*equal contribution, #equal correspondence)

---

## Overview

Analysis code for a concurrent tDCS-fMRI study (N=20, double-blind sham-controlled crossover) examining how unilateral and bilateral M1 tDCS modulate whole-brain dynamics and sensorimotor behavior. The code covers:
- **Preprocessing** of fMRI data
- **CAP analysis** to identify recurring large-scale brain states from resting-state fMRI
- **Statistical analysis** of tDCS effects on behavior (robotic kinematic tasks) and CAP dynamics
- **Brain–behavior associations** between bilateral-sensitive CAP metrics and sensorimotor performance

---

## Repository structure

```
tDCS-CAPs-dynamics/
├── preprocessing/
├── caps_analysis/
├── stats_and_R_figures/
├── data/
├── results/
├── .env.example
└── tDCS-CAPs-dynamics.Rproj
```

---

### `preprocessing/`

Scripts for fMRI data preprocessing and denoising, applied before CAP analysis.

| File | Description |
|------|-------------|
| `run_fmriprep_23.sh` | Runs fMRIPrep 23.2.2 via Docker on BIDS data. |
| `load_confound_simple.py` | Applies nuisance regression (motion, WM, CSF) and bandpass filtering to fMRIPrep outputs using Nilearn; saves denoised NIfTIs. |

---

### `caps_analysis/`

Jupyter notebooks implementing the full CAP pipeline in Python, intended to be run in order.

| Notebook | Description |
|----------|-------------|
| `01_time_series_extraction.ipynb` | Parcellates denoised fMRI data, z-scores and concatenates time series across all subjects/sessions, saves `CAP_TS` and `DATA_LABELS`. |
| `02_clustering_evaluation.ipynb` | Runs k-means (k=2–15, 100 permutations) and computes silhouette, Davies-Bouldin, inertia, and ARI stability to determine optimal k. |
| `03_plot_eval_metrics.ipynb` | Plots clustering evaluation metrics from notebook 02 to guide the selection of k=7. |
| `04_clustering_analysis.ipynb` | Runs k-means (k=2–10), reorders CAPs using the Hungarian algorithm on cosine similarity, saves cluster labels, centroids, and NIfTI spatial maps. |
| `05_plot_caps_surf&vol.ipynb` | Plots the seven CAP spatial maps on cortical surface and subcortical axial slices. |
| `06_prepare_caps_radar_data.ipynb` | Computes per-network mean CAP activation across Yeo networks and subcortical regions; saves CSVs for radar plots. |
| `07_plot_caps_cosine_similarity.ipynb` | Plots pairwise cosine similarity matrix between all seven CAPs. |
| `08_calc_caps_dynamics.ipynb` | Computes occurrence rate, dwell time, and transition probability for each CAP per subject and session; saves CSVs for R analyses. |

Additional files:

| File | Description |
|------|-------------|
| `environment.yml` | Conda environment specification for the Python analysis. |
| `requirements.txt` | Pip-installable dependencies for the Python analysis. |

---

### `stats_and_R_figures/`

R scripts and R Markdown notebooks for statistical analyses and publication figures. All scripts read paths from the project `.env` file.

| File | Description |
|------|-------------|
| `01_plot_caps_radar_profiles.R` | Generates radar chart figures of CAP network activation profiles. |
| `02_statistical_analysis_behavioral_tasks.Rmd` | Permutation-based omnibus + Bonferroni post-hoc tests for tDCS effects on kinematic performance (APM, VGR, OH, BOB). |
| `03_statistical_analysis_caps_dynamics.Rmd` | Same permutation framework testing tDCS effects on CAP occurrence rate, dwell time, and transition probability. |
| `04_plot_caps_occ_dt.R` | Plots CAP occurrence rate and dwell time across sessions (paired lines for CAP4, box plots for all CAPs). |
| `05_plot_caps_tp.Rmd` | Plots transition probability heatmaps per session and Cohen's d heatmaps for pairwise session contrasts. |
| `06_statistical_analysis_caps_beh_sham_corr.Rmd` | Spearman correlations between CAP dynamics and behavior, both under sham, to test baseline brain–behavior associations. |
| `07_statistical_analysis_caps_beh_partial_corr.Rmd` | Partial Spearman correlations between CAP dynamics and behavior under bilateral tDCS, controlling for sham baseline. |
| `08_plot_sham_bilateral_correlations.Rmd` | Plots significant sham and bilateral brain–behavior correlations side by side. |

---

### `data/`

Data needed to reproduce the results, including anonymized behavioral data and intermediate outputs of the CAP pipeline.

| Path | Description |
|------|-------------|
| `data/Behavioral_data_anon/csv/` | Anonymized kinematic data per task (APM, VGR, OH, BOB), hand, and session. |
| `data/atlases/KH_atlas/` | Combined parcellation atlas (Schaefer-1000 + subcortical + cerebellar). |
| `data/coactivation_patterns_run-ON/CAP_TS_run-ON_zscored.npy` | Concatenated z-scored time series — input to k-means clustering. |
| `data/coactivation_patterns_run-ON/DATA_LABELS_run-ON.npy` | Subject/session/run label for each row of `CAP_TS`. |

---

### `results/`

Output figures organized by type.

| Path | Description |
|------|-------------|
| `results/photoshop_figures/` | Final publication figures (PNG + PSD). |
| `results/supplementary_figures/` | Supplementary figures (clustering evaluation metrics). |

---

## Environment setup

Copy `.env.example` to `.env` and fill in your local paths. Recreate the Python environment with:

```bash
conda env create -f caps_analysis/environment.yml
```

---

## Analysis pipeline order

1. **Preprocessing**: `preprocessing/run_fmriprep_23.sh` → `preprocessing/load_confound_simple.py`
2. **CAP time series**: `caps_analysis/01_time_series_extraction.ipynb`
3. **Cluster selection**: `caps_analysis/02_clustering_evaluation.ipynb` → `caps_analysis/03_plot_eval_metrics.ipynb`
4. **Clustering**: `caps_analysis/04_clustering_analysis.ipynb`
5. **CAP visualization**: `caps_analysis/05_plot_caps_surf&vol.ipynb`, `caps_analysis/06_prepare_caps_radar_data.ipynb`, `caps_analysis/07_plot_caps_cosine_similarity.ipynb`
6. **CAP dynamics**: `caps_analysis/08_calc_caps_dynamics.ipynb`
7. **Statistics & figures**: `stats_and_R_figures/` scripts (01–08)
