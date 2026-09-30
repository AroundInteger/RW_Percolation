# Production figures for the PRL letter

This directory holds **publication PNGs** and the **Python drivers** that draw them from simulation tables. The manuscript sources are `paper_drafts/prl_letter.tex`, `paper_drafts/supplemental.tex`, and `paper_drafts/prl_combined.tex`. A compact file index with draft-section mapping is in [`FIGURES_MANIFEST.md`](FIGURES_MANIFEST.md).

Shared styling lives in `rw_figstyle.py`. **κ = 0** α(p) panels share logic in **`kappa_alpha_common.py`** (CSV load, per-seed grids, gel-point crossing, band vs error-bar drawing, FSS annotation helper).

## What belongs here

- **Committed:** PNG outputs and `make_*.py` scripts.
- **Not committed:** all `*.csv` inputs (repo-wide `*.csv` is gitignored). Regenerate figures on a machine that has run the MATLAB pipeline or restored production tables locally.

## Input data paths (gitignored)

| Figure script | Primary CSV inputs (from repo root) |
|---------------|-------------------------------------|
| `make_fig1.py` | `matlab/Clusters_kappa/L500/kappa_study_alpha_table.csv` |
| `make_fig2.py`, `make_fig_dyn_vs_geom.py`, `make_fig3.py` | same κ-study table (L = 500 family) |
| `make_fig4a.py`, `make_fig4b.py`, `make_fig_collapse.py` | `matlab/FSS_study/fss_nu_summary.csv`, `fss_pcL_table.csv`, `fss_alpha_table.csv` |
| `make_fig_threshold_kappa0.py` | `matlab/FSS_study/fss_alpha_table.csv`, `fss_pcL_table.csv`, `void_geom_fss_kappa0.csv` (or `void_geom_fss_kappa0_summary.csv`) |
| `make_fig_alpha_window_sensitivity.py` | `matlab/FSS_study/alpha_window_summary.csv` |

MATLAB campaign and analysis: see [`matlab/FSS_README.md`](../../matlab/FSS_README.md). Typical order: `RW3D_FSS_study` → `analyze_FSS`, then Phase A follow-ups `alpha_window_sensitivity`, `void_geom_FSS_kappa0`, and (for κ tunability at L = 500) `void_percolation_threshold`. The L = 500 κ-mixing α table comes from the production κ study (`RW3D_kappa_mixing_study.m` / `matlab/Clusters_kappa/L500/`).

## Regeneration (from repo root)

Requires Python 3 with `numpy` and `matplotlib`. CSVs must exist at the paths above.

```bash
python3 paper_drafts/figures_v2/make_fig1.py
python3 paper_drafts/figures_v2/make_fig_threshold_kappa0.py
python3 paper_drafts/figures_v2/make_fig_collapse.py
python3 paper_drafts/figures_v2/make_fig4a.py
python3 paper_drafts/figures_v2/make_fig4b.py
python3 paper_drafts/figures_v2/make_fig_alpha_window_sensitivity.py
python3 paper_drafts/figures_v2/make_fig_dyn_vs_geom.py
python3 paper_drafts/figures_v2/make_fig2.py
```

`make_fig1.py` writes **two** PNGs in one run (see below). Other scripts write a single file each, named in the script header.

## Fig 1: band (letter default) vs error bars

`make_fig1.py` produces:

| Output | Use |
|--------|-----|
| `fig1_random_alpha_vs_p.png` | **Letter default:** κ = 0 α(p) with ±1σ **shaded band** over N_s = 3 lattice seeds at each p, plus **horizontal** error bar on p′_c at α = 0.5 (seed-to-seed gel-point spread). |
| `fig1_random_alpha_vs_p_errbars.png` | Same data with **vertical** ±1σ error bars at each p (subsampled on the full-range panel for clarity). For comparison or supplement. |

Both variants use `kappa_alpha_common.draw_kappa_curve_band` vs `draw_kappa_curve_errbars`, and annotate FSS p′_c(∞) from `fss_nu_summary.csv` (`condition = k0p00`) when that file is present. Bernoulli reference 1 − p_c = 0.6884 is marked as a dotted vertical line.

**Gel-point seed statistics at κ = 0 (L = 500, α = 0.5 crossing per seed):** mean p′_c = **0.682514 ± 0.001382** (N_s = 3 seeds). This is the horizontal uncertainty shown on the band figure, not the vertical α band at fixed p.

## Threshold panel: per-seed error bars

`fig_threshold_kappa0.png` (`make_fig_threshold_kappa0.py`) plots dynamical p′_MR(L) and geometric p′_geom(L) at κ = 0 versus system size, with **±1σ error bars over seeds** at each L, alongside the Bernoulli reference 1 − p_c. Dynamical thresholds are recomputed from per-seed α(p, L) in `fss_alpha_table.csv` when a seed column is present; geometric points come from `void_geom_fss_kappa0.csv` (long format) or its summary file.

## Phase A (`cursor/phase-a-science-fixes`)

This branch batch aligns **Phase A** science fixes with regenerated PNGs:

- Shared κ = 0 α(p) drawing and gel-point uncertainty via `kappa_alpha_common.py`.
- Fig 1 band + errbars variants; threshold panel with explicit seed error bars.
- Tracked updates to `fig1_random_alpha_vs_p.png`, `fig1_random_alpha_vs_p_errbars.png`, `fig_threshold_kappa0.png`, and `fig_collapse_kappa035.png` where CSV-backed regeneration was run locally.

Manuscript `.tex` edits and full FSS CSV restoration may land in separate commits; **do not** commit gitignored CSVs when pushing figure-only updates.

## Current claims (figure context)

See root [`LEDGER.md`](../../LEDGER.md) and [`paper_drafts/PAPER_WRITING_RULES.md`](../PAPER_WRITING_RULES.md). In brief: dynamical gel point matches void spanning for κ ≲ 0.8; at κ = 0, p′_c(∞) ≈ 0.681; α is the log–log MSD slope on [L_W/100, L_W/10], not a changepoint time.
