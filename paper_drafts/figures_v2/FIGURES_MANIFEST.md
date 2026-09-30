# Figure set — full_draft_v2 (nucleation-density tunability + FSS)

All figures for the reframed manuscript, gathered here. "Role" = where it appears in
`../full_draft_v2.md`. Status: **final** = usable as-is; **regenerate** = needs a redraw.

| File | Role in v2 | Source | Status |
|------|-----------|--------|--------|
| `fig0_schematic_growth.png` | (optional) growth-morphology schematic | figures/fig_schematic_growth.png | **regenerate** — simplify to random → κ family → Eden; drop the 6N/26N "class" emphasis |
| `fig1_random_alpha_vs_p.png` | §3.1 — α(p) for the random (κ=0) network; **letter default**: ±1σ shaded band over $N_s=3$ seeds + horizontal gel-point seed uncertainty | `make_fig1.py` ← `matlab/Clusters_kappa/L500/kappa_study_alpha_table.csv` | **regenerate** |
| `fig1_random_alpha_vs_p_errbars.png` | §3.1 — same data, explicit vertical error bars at each $p$ (comparison / supplement) | `make_fig1.py` (errbars mode) | **regenerate** |
| `fig2a_kappa_alpha_vs_p.png` | §3.2 — α(p,κ) across the nucleation-density family | figures/fig1_alpha_vs_p.png | final |
| `fig2b_gelpoint_vs_kappa.png` | §3.2 — pc′(κ) tunable gel-point curve (L=500) | figures/fig2_gel_point_tunable.png | final |
| `fig3_gser_spectra.png` | §3.4 — GSER G′,G″,δ spectra straddling pc′ | figures/fig5_gser.png | final (single-replicate caveat noted in text) |
| `fig4a_fss_pcL.png` | §3.3 / App. B — FSS pc′(L) vs L^(−1/ν) with per-κ ν | `make_fig4a.py` ← `fss_pcL_table.csv` + `fss_nu_summary.csv` | **regenerate** |
| `fig4b_nu_vs_kappa.png` | §3.3 — ν(κ): collapse + width, κ=0.97 crossover, 0.88 ref | `make_fig4b.py` ← `fss_nu_summary.csv` | **regenerate** |
| `fig_collapse_kappa035.png` | §3.3 / supplement — data collapse at κ = 0, 0.6, 0.8 | `make_fig_collapse.py` | **regenerate** |
| `fig_threshold_kappa0.png` | §3.1 / B1 — joint p′_MR(L), p′_geom(L), 1−p_c at κ=0 with ±1σ seed error bars | `make_fig_threshold_kappa0.py` ← `fss_alpha_table.csv` + `void_geom_fss_kappa0.csv` | **regenerate** |
| `fig_alpha_window_sensitivity.png` | supplement M4 — p′_c(∞) vs MSD fit window | `make_fig_alpha_window_sensitivity.py` | **regenerate** |
| `fig_dyn_vs_geom.png` | §3.2 — dynamical vs geometric pc′(κ) | `make_fig_dyn_vs_geom.py` | **regenerate** (re-seed void run) |

## Regeneration commands (from repo root, after CSVs exist)

```bash
python3 paper_drafts/figures_v2/make_fig1.py   # writes band + errbars PNGs
python3 paper_drafts/figures_v2/make_fig4a.py
python3 paper_drafts/figures_v2/make_fig4b.py
python3 paper_drafts/figures_v2/make_fig_collapse.py
python3 paper_drafts/figures_v2/make_fig_threshold_kappa0.py
python3 paper_drafts/figures_v2/make_fig_alpha_window_sensitivity.py
python3 paper_drafts/figures_v2/make_fig_dyn_vs_geom.py
```

MATLAB prerequisites: `RW3D_FSS_study` → `analyze_FSS` → `alpha_window_sensitivity` / `void_geom_FSS_kappa0` / `void_percolation_threshold`.

## Suggested final figure order (5 figures)
1. Random α(p) + void-percolation identity  →  `fig1_random_alpha_vs_p.png` + `fig_threshold_kappa0.png`
2. κ tunability: α(p,κ) and pc′(κ)  →  `fig2a_…` + `fig2b_…` (two panels)
3. FSS: pc′(L) collapse + ν(κ)  →  `fig4a_…` + `fig4b_…` + `fig_collapse_kappa035.png`
4. GSER spectra  →  `fig3_gser_spectra.png`
5. (optional) growth-morphology schematic  →  `fig0_…`

## Deliberately excluded (retired with the "two classes" framing)
- `fig2_two_classes.png` — the random-vs-templated two-class figure (superseded by the κ line)
- `fig5_restructured.png`, `fig6_delta_vs_deltap.png` — earlier GSER variants (kept in figures/ if needed)

## Still to regenerate
- `fig0`: 2D schematic; drop the 6N/26N rows, keep random / mid-κ / Eden.
- All Phase A figures above once `matlab/FSS_study/` production CSVs are restored.
