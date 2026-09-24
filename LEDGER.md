# Manuscript ledger

The manuscript is the 23 September 2026 letter and its supplement:

- `paper_drafts/prl_letter.tex`
- `paper_drafts/supplemental.tex`
- `paper_drafts/prl_combined.tex` (the same text in one file, for review)
- `paper_drafts/figures_v2/`

Its claims are the ones later files must not contradict. The dynamical gel point is the void-percolation threshold, and it agrees with a direct geometric spanning measurement for κ ≲ 0.8. Nucleation density κ shifts pc′ from about 0.68 towards 1. Finite-size scaling (L = 50–750) gives ν_eff ≈ 1.6 with no systematic κ trend for κ ≤ 0.8: one effective critical character, not two universality classes. α is the log–log slope on the fixed window [L_W/100, L_W/10], not a changepoint time.

Nothing under `archive/legacy_pre_fss/` is a current result. Files were moved, not deleted. Production code and data stay in place: `matlab/` (including `FSS_study` and `RW3D_FSS_study.m`), `ensemble_simulations/`, and `lattices_L100_seq/`.

## Why the archived work is not a second paper

The long-form LaTeX still describes a single lattice size and says finite-size scaling would be needed. The 2025 complete-characterisation drafts claim two universality classes and a 98.6% prediction accuracy; the scaling study withdrew both. The changepoint notes locate the ballistic-to-diffusive crossover, not the gel point. Rod-like templating and the fibrin framing have no pc′ measurement on the current engine.

A short paper on anisotropic (rod-like) growth is deferred. It is not part of the letter, and it will not be started until this paper has been submitted for review. It would then need a new pc′ measurement on the current walker, with the geometric spanning check.

## Moves

### `archive/legacy_pre_fss/paper_longform/`

Pre-scaling long-form drafts, and the Overleaf copies of that draft. Useful as prose to mine, not as a manuscript.

- `paper_drafts/sections/`
- `paper_drafts/appendices/`
- `paper_drafts/main.tex`
- `paper_drafts/main_old_paper.tex`
- `paper_drafts/full_draft.md`
- `paper_drafts/full_draft_v2.md`
- `paper_drafts/full_draft_v2.html` (HTML of the same draft)
- `paper_drafts/overleaf_build/`
- `paper_drafts/overleaf_RW_Percolation/`
- `paper_drafts/overleaf_RW_Percolation.zip`
- `paper_drafts/colleague_report.tex`
- `paper_drafts/COLLEAGUE_REPORT_README.md`
- `paper_drafts/COLLEAGUE_REPORT_SUMMARY.md`
- `paper_drafts/compile_colleague_report.sh`

### `archive/legacy_pre_fss/claude_snapshot/`

The `Claude outputs/` folder: 19 September copies of the letter and supplement, plus earlier figure and script snapshots. The production script is `matlab/RW3D_FSS_study.m`. The production figures are `paper_drafts/figures_v2/`.

### `archive/legacy_pre_fss/docs_2025/`

The whole of `docs/`, including `docs/MR_5/`. This is the 2025 paper draft, the two-universality-class notes, the changepoint series (including `ALPHA_DETERMINATION_ANALYSIS.md` and `CHANGEPOINT_SCALING_MASTER_SUMMARY.md`), the early L ≤ 200 finite-size note, and the rod-like templating notes.

### `archive/legacy_pre_fss/root_analysis_2025/`

Root CSVs, PNGs, logs, and notes from the August 2025 analysis passes, the 8 September universality scripts that continue that pass, and the critical-region outputs. Several of those figures label occupations well below the gel point as critical. Do not import their numbers into the supplement.

- August 2025 root analysis files: `CONSOLIDATED_VERIFICATION_SUMMARY.md`, `MATLAB_DATA_LOADING_SOLUTION.md`, `PAPER_COMPARISON_SUMMARY.md`, `README_3D_VISCOELASTIC_SURFACES.md`, `README_CONSOLIDATED_PHYSICAL_VERIFICATION.md`, `README_DEFINITIVE_ANALYSIS.md`, `README_HYBRID_ANALYSIS.md`, `SETUP_HYBRID_ANALYZER.md`, `alpha_*.png`, `comprehensive_msd_analysis_*`, `corrected_alpha_analysis_*`, `corrected_analysis_p*.png`, `corrected_fine_resolution_output.log`, `critical_region_analysis.log`, `investigation_p0.6384.png`, `msd_analysis_p*.png`, `msd_dataset_sample_curves.png`, `physics_based_analysis_p0.6384.png`, `real_data_critical_region_analysis.log`, `robust_comprehensive_analysis.*`, `transition_analysis_detailed.png`, `viscoelastic_*.png`
- August 2025 output directories: `output_comparison/`, `output_new_dataset/`, `output_original_dataset/`, `output_physics_based/`, `critical_region_changepoint_results/`, `real_data_critical_region_results/`
- 8 September continuation of the same analysis: `analyze_comprehensive_results.py`, `comprehensive_alpha_results.csv`, `comprehensive_analysis_report.txt`, `comprehensive_analysis_results.png`, `corrected_universality_analysis.py`, `corrected_universality_analysis_final.py`

## Left in place on purpose

`paper_drafts/paper_breakdown_and_series_strategy.md` and `paper_drafts/comprehensive_paper_plan.md` stay, with a banner: the series option and the two-class question were closed by the September finite-size letter. Literature notes, the reference checklist, and `figures_v2/` stay with the letter. `matlab/`, `ensemble_simulations/`, and `lattices_L100_seq/` stay, because they are the engine and the data for this paper.

### `archive/legacy_pre_fss/other_projects/`

The other project trees, so the working root is the paper plus the MATLAB engine: `robust_simulation/`, `scripts/`, `tests/`, `test_output/`, `test_paper_analysis/`, `test_paper_simulations/`, `enhanced_output/`, `enhanced_output_fine/`, `paper_figures/`, `paper_simulations/`, `PROJECT_ANALYSIS.md`, and the loose June–July result files that were sitting at the repo root.

### `archive/legacy_pre_fss/paper_drafts_extras/`

Copies and leftovers removed from `paper_drafts/` so that folder is the letter: `.bak` files, the old `figures/` set, `paper_skeleton.docx`, unused bibliographies, and the old folder README. The bibliography the letter compiles against, `references_enhanced.bib`, stays in `paper_drafts/`. `simulation_methodology.md` and `forDan.docx` were moved into `paper_drafts/` with the manuscript.
