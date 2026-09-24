# Figure set — full_draft_v2 (nucleation-density tunability + FSS)

All figures for the reframed manuscript, gathered here. "Role" = where it appears in
`../full_draft_v2.md`. Status: **final** = usable as-is; **regenerate** = needs a redraw.

| File | Role in v2 | Source | Status |
|------|-----------|--------|--------|
| `fig0_schematic_growth.png` | (optional) growth-morphology schematic | figures/fig_schematic_growth.png | **regenerate** — simplify to random → κ family → Eden; drop the 6N/26N "class" emphasis |
| `fig1_random_alpha_vs_p.png` | §3.1 — α(p) for the random (κ=0) network | figures/fig1_bernoulli_class.png | final (could add an FSS pc′(L) inset) |
| `fig2a_kappa_alpha_vs_p.png` | §3.2 — α(p,κ) across the nucleation-density family | figures/fig1_alpha_vs_p.png | final |
| `fig2b_gelpoint_vs_kappa.png` | §3.2 — pc′(κ) tunable gel-point curve (L=500) | figures/fig2_gel_point_tunable.png | final |
| `fig3_gser_spectra.png` | §3.4 — GSER G′,G″,δ spectra straddling pc′ | figures/fig5_gser.png | final (single-replicate caveat noted in text) |
| `fig4a_fss_pcL.png` | §3.3 / App. B — FSS pc′(L) vs L^(−1/ν) with fits | matlab/FSS_study/fss_pcL_fits.png | final |
| `fig4b_nu_vs_kappa.png` | §3.3 — ν(κ): collapse + width, κ=0.97 crossover, 0.88 ref | regenerated (see make_fig4b.py) | **final** |

`make_fig4b.py` regenerates `fig4b` from `matlab/FSS_study/fss_nu_summary.csv` (matplotlib).

## Suggested final figure order (5 figures)
1. Random α(p) + void-percolation identity  →  `fig1_random_alpha_vs_p.png`
2. κ tunability: α(p,κ) and pc′(κ)  →  `fig2a_…` + `fig2b_…` (two panels)
3. FSS: pc′(L) collapse + ν(κ)  →  `fig4a_…` + `fig4b_…` (two panels)
4. GSER spectra  →  `fig3_gser_spectra.png`
5. (optional) growth-morphology schematic  →  `fig0_…`

## Deliberately excluded (retired with the "two classes" framing)
- `fig2_two_classes.png` — the random-vs-templated two-class figure (superseded by the κ line)
- `fig5_restructured.png`, `fig6_delta_vs_deltap.png` — earlier GSER variants (kept in figures/ if needed)

## Still to regenerate
- `fig0`: 2D schematic; drop the 6N/26N rows, keep random / mid-κ / Eden.
- (optional) `fig4b` in MATLAB style, if strict visual consistency with fig4a is wanted;
  the current matplotlib version is publication-quality and self-contained.
