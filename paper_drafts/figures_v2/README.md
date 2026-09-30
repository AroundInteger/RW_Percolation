# Manuscript figures (`figures_v2/`)

Publication PNGs and Python redraw scripts for the PRL letter and supplement. The LaTeX sources include these files directly:

- `paper_drafts/prl_letter.tex`
- `paper_drafts/supplemental.tex`
- `paper_drafts/prl_combined.tex`

Shared styling lives in `rw_figstyle.py`. A quick inventory of filenames and manuscript roles is in `FIGURES_MANIFEST.md`.

## Phase A (science fixes branch)

Branch `cursor/phase-a-science-fixes` carries the Phase A figure refresh: per-seed uncertainty on the random-network α(p) panel, a dual fig1 export (band vs error bars), seed error bars on the κ = 0 threshold reconciliation plot, and collapse/threshold PNGs regenerated from local production CSVs. **Committed PNGs reflect runs on the author machine**; the gitignored CSV and `.mat` inputs are not in the repo. Clone the branch for Overleaf or review without rerunning MATLAB.

## Data dependencies (local, gitignored)

Root `.gitignore` excludes `*.csv` and most `*.png`; only `paper_drafts/figures_v2/*.png` is whitelisted so figures travel with the manuscript.

| Path | Produced by | Used for |
|------|-------------|----------|
| `matlab/Clusters_kappa/L500/kappa_study_alpha_table.csv` | κ mixing study at L = 500 | `make_fig1.py`, `make_fig2.py`, `make_fig3.py`, `make_fig_dyn_vs_geom.py` |
| `matlab/FSS_study/fss_alpha_table.csv` | `analyze_FSS.m` after `RW3D_FSS_study.m` | Threshold MR curve, collapse, per-seed pc′(L) |
| `matlab/FSS_study/fss_pcL_table.csv` | `analyze_FSS.m` | `make_fig4a.py`, threshold fallback |
| `matlab/FSS_study/fss_nu_summary.csv` | `analyze_FSS.m` | `make_fig4a.py`, `make_fig4b.py`, `make_fig_collapse.py`, fig1 FSS annotation |
| `matlab/FSS_study/void_geom_fss_kappa0.csv` | `void_geom_FSS_kappa0.m` | `make_fig_threshold_kappa0.py` (preferred: long format with seed column) |
| `matlab/FSS_study/void_geom_fss_kappa0_summary.csv` | `void_geom_FSS_kappa0.m` | threshold plot fallback |
| `matlab/FSS_study/alpha_window_summary.csv` | `alpha_window_sensitivity.m` | `make_fig_alpha_window_sensitivity.py` |
| `matlab/void_pc_geom.csv` | `void_percolation_threshold.m` | `make_fig_dyn_vs_geom.py` |

MATLAB run order and FSS outputs are documented in `matlab/FSS_README.md`. Production FSS: `RW3D_FSS_study` → `analyze_FSS`; Phase A follow-ups: `alpha_window_sensitivity`, `void_geom_FSS_kappa0`, `void_percolation_threshold`.

## Regenerating figures

From the repository root, with CSVs in place and a Python 3 environment that has `numpy` and `matplotlib`:

```bash
# Phase A core (order independent among these)
python3 paper_drafts/figures_v2/make_fig1.py
python3 paper_drafts/figures_v2/make_fig_threshold_kappa0.py
python3 paper_drafts/figures_v2/make_fig_collapse.py

# Remaining v2 scripts (depend on the same FSS / κ tables)
python3 paper_drafts/figures_v2/make_fig2.py
python3 paper_drafts/figures_v2/make_fig4a.py
python3 paper_drafts/figures_v2/make_fig4b.py
python3 paper_drafts/figures_v2/make_fig_alpha_window_sensitivity.py
python3 paper_drafts/figures_v2/make_fig_dyn_vs_geom.py
python3 paper_drafts/figures_v2/make_fig3.py   # needs GSER .mat under matlab/Clusters1/
```

There is no single `make all` target; run the scripts above as inputs become available.

## Shared module: `kappa_alpha_common.py`

`kappa_alpha_common.py` loads `kappa_study_alpha_table.csv`, builds the α(p) grid per κ, and implements drawing helpers used by:

- **`make_fig1.py`** — κ = 0 only, with seed-resolved gel-point markers
- **`make_fig2.py`** — full κ family (`draw_kappa_curve` uses mean ± 1σ bands and mean-curve gel markers on fig2a)

Key behaviours for fig1:

- **α curves:** mean over seeds at each p, with ±1σ across seeds (`N_s = 3` lattices).
- **Gel point at α = 0.5:** per-seed crossing `p′_c`, then a marker at the seed mean with **horizontal** error bar = sample standard deviation across seeds (`draw_gel_point_seed_uncertainty`).
- **FSS annotation:** `fss_pc_inf_kappa0()` reads `p_c'(\infty)` for condition `k0p00` from `fss_nu_summary.csv`.

### Fig1 dual outputs

`make_fig1.py` writes two PNGs from the same data:

| File | Mode | Letter use |
|------|------|------------|
| `fig1_random_alpha_vs_p.png` | `band` — shaded ±1σ band, no vertical error bars at every p | **Default in the letter** |
| `fig1_random_alpha_vs_p_errbars.png` | `errbars` — explicit vertical error bars (subsampled on the full-range panel) | Comparison / supplement |

Both panels show Bernoulli `1 − p_c = 0.6884`, L = 500 gel-point annotation, and FSS `p_c'(\infty)` when the nu summary CSV is present.

**Last production gel-point spread (κ = 0, α = 0.5 crossings, three seeds):**  
p′_c = 0.680932, 0.683119, 0.683490 → **mean 0.682514 ± 0.001382** (sample σ across seeds).

## Threshold figure (`fig_threshold_kappa0.png`)

`make_fig_threshold_kappa0.py` plots joint finite-size thresholds at κ = 0:

- **Dynamical** p′_MR(L): α = 0.5 crossing per seed from `fss_alpha_table.csv`, then mean ± 1σ over seeds at each L (matches `analyze_FSS.m` interpolation logic).
- **Geometric** p′_geom(L): void spanning from `void_geom_fss_kappa0.m` outputs (`void_geom_fss_kappa0.csv` or summary CSV).
- Horizontal reference: Bernoulli void threshold `1 − p_c = 0.6884`.

Error bars are **seed-to-seed** (N = 3), labelled on the figure. Requires FSS α table plus geometric FSS run; see `matlab/void_geom_FSS_kappa0.m`.

## Collapse and other regenerated PNGs

- `fig_collapse_kappa035.png` — `make_fig_collapse.py` (κ ∈ {0, 0.6, 0.8}, uses `fss_nu_summary.csv` + `fss_alpha_table.csv`).
- Other tracked PNGs in this folder may be copied from legacy `figures/` or produced by the corresponding `make_fig*.py` script; see `FIGURES_MANIFEST.md` for status.

## What not to commit

Do not add gitignored simulation products (`*.csv`, `matlab/FSS_study/*.mat`, ensemble lattices, etc.) unless project policy changes. Only commit redrawn PNGs under this directory and the scripts/README here.
