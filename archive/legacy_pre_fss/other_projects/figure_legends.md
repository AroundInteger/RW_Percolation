# Figure Legends

---

## Figure 1 — Anomalous diffusion exponent α(p, κ)

**fig1_alpha_vs_p.png**

**Figure 1.** Ensemble-averaged anomalous diffusion exponent α as a function of occupation probability *p* for all 18 values of the nucleation-density parameter κ. Results are obtained from three-dimensional random walk simulations on κ-mixed percolation lattices (*L* = 500, *N*_W = 3,000 walkers, *L*_W = 10⁶ steps per walker, *N*_s = 3 independent replicates). Curves are coloured according to κ from κ = 0 (dark purple, Bernoulli percolation) to κ = 1 (yellow, single-seed Eden-like growth), as indicated by the shared colourbar. Shaded bands denote ±1 standard deviation across replicates. The dashed horizontal line at α = 0.5 marks the gel-point criterion corresponding to a phase angle δ = 45° in the Winter–Chambon framework; the intersection of each curve with this threshold defines the gel-point p_c′(κ) for that morphology.

**(a) Full range** (*p* ∈ [0, 1]): at low *p* all lattices exhibit normal diffusion (α ≈ 1, sol state). As *p* increases, α decreases monotonically through the gel-point and approaches zero in the arrested gel state.

**(b) Critical region** (*p* ∈ [0.60, 1.00]): the zoomed view resolves the α = 0.5 crossings for each κ value. Dotted vertical lines indicate the interpolated gel-points p_c′(κ). The rightward shift of the crossing with increasing κ — from p_c′ ≈ 0.683 (κ = 0, labelled) to p_c′ ≈ 0.993 (κ = 1, labelled) — demonstrates continuous, monotonic tuning of the gel-point across Δp_c′ ≈ 0.31.

---

## Figure 2 — Tunable gel-point p_c′(κ)

**fig2_gel_point_tunable.png**

**Figure 2.** Tunable gel-point p_c′ as a function of the nucleation-density parameter κ (panel a) and as a function of seed fraction (1 − κ) on a logarithmic scale (panel b). Filled circles show p_c′(κ) values obtained by linear interpolation of α through 0.5; vertical error bars span the interpolation bracket (the p-grid interval containing the crossing). Blue shading indicates the full bracket width as a measure of p-grid resolution uncertainty. The starred symbol at κ = 1.0 (panel a) and (1 − κ) → 0 (panel b) denotes a conservative linear extrapolation (p_c′ ≈ 0.993 ± 0.008); this value requires confirmation by simulation at p > 0.99.

**(a) p_c′ vs κ:** Dotted horizontal lines indicate the two physical endpoints: the Bernoulli (random) percolation limit p_c′ ≈ 0.683 (κ = 0, blue) and the single-seed Eden growth limit p_c′ ≈ 0.993 (κ = 1, red). The double-headed arrow marks the total tunable range Δp_c′ ≈ 0.31. The gel-point increases monotonically with κ across the full parameter range, confirming that nucleation density provides a physically well-defined and continuous handle on viscoelastic gel-point positioning.

**(b) p_c′ vs seed fraction (1 − κ), log scale:** Re-plotting against the nucleation site density (1 − κ) — the fraction of newly required sites that are placed as independent seeds at each increment of *p* — reveals two physical regimes separated at a seed fraction of approximately 1% (dashed vertical line). In the **Bernoulli-like regime** (seed fraction ≳ 1%, right side), the occupied network is seeded densely enough that spatial clustering is limited and p_c′ increases gradually with decreasing seed fraction (from p_c′ ≈ 0.683 to ≈ 0.88). In the **Eden regime** (seed fraction ≲ 1%, left side), the cluster originates from one or very few seeds and grows as a compact, connected body reminiscent of Eden or diffusion-limited aggregation models; the resulting void space remains open to anomalous diffusion until very high *p*, pushing p_c′ sharply toward unity. The upper x-axis shows the corresponding κ values for orientation.

---

## Simulation parameters (reference)

| Parameter | Symbol | Value |
|---|---|---|
| Lattice side length | *L* | 500 |
| Steps per walker | *L*_W | 10⁶ |
| Walkers per condition | *N*_W | 3,000 |
| Independent replicates | *N*_s | 3 |
| Wait-time mean / std | μ_WT, σ_WT | 20, 5 steps |
| κ values (18 total) | — | 0.00 – 1.00, log-dense near κ = 1 |
| p-value grid (35–38 points) | — | Dense near p_c′ ≈ 0.683 and 0.88–0.99 |
