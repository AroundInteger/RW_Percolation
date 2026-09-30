# Finite-Size Scaling (FSS) study — run guide

Two scripts, dropped in `matlab/` alongside the existing model functions they reuse
(`generate_kappa_mixed_lattice.m`, `generate_templated_growth_3d_logical.m`, `RW3D_P_SP.m`):

- **`RW3D_FSS_study.m`** — runs the simulations.
- **`analyze_FSS.m`** — extracts pc′(L), fits ν three ways, assembles ν(κ).

## What it does

FSS on **6 conditions** — the κ line at κ = {0.00, 0.60, 0.80, 0.97, 1.00} plus the
multi-seed **6N-templated** class — across **6 sizes** L = {50, 100, 200, 300, 500, 750}.
Steps per walker scale as **L_W ∝ L²** (reference 10⁶ at L = 500), so the fit window
`[L_W/100, L_W/10]` tracks the finite-size crossover time. Walkers are run only in each
condition's **critical-region p-window** (fine grid, Δp = 0.005); the lattice is still built
cumulatively over a coarse pre-grid below the window so the growth history matches the
production dataset.

Everything else — the void-phase RW engine, wait-time (20 ± 5), online-MSD `parfor`
reduction, and the log-log α fit — is byte-for-byte the same as `RW3D_kappa_mixing_study.m`,
so FSS numbers are directly comparable to your existing results.

## Run it

```matlab
% smoke test first (minutes): L = {50,100}, NW = 300, 1 seed
MODE = 'quick'; RW3D_FSS_study

% then the real campaign (headless, days — use nohup):
% nohup /Applications/MATLAB_R2025a.app/bin/matlab -nodisplay \
%     -r "RW3D_FSS_study; exit" > fss_study.log 2>&1 &

analyze_FSS      % after the run completes (resumable — re-run any time)

% Phase A follow-ups (re-read saved MSD .mat; no new walkers unless noted):
alpha_window_sensitivity   % M4 — p_c'(inf) vs fit-window choice
void_geom_FSS_kappa0       % B1 — geometric p_c'(L) at kappa=0 across FSS sizes
void_percolation_threshold % geometric p_c'(kappa) at L=500 (uses rng(100*seed))
```

Resumable: existing per-`(condition,L,p,seed)` `.mat` files are skipped, so a killed run
picks up where it left off.

## Outputs (`matlab/FSS_study/`)

- `fss_alpha_table.csv/.mat` — α(p,L) for every condition/size/seed
- `fss_pcL_table.csv` — pc′(L) and logistic width w(L) per (condition, L)
- `fss_nu_summary.csv` — pc′(∞), ν_shift(+CI), ν_width(+CI), ν_collapse(+CI), collapse_sse; fixed-ν (0.88 / 1.50) pc′(∞) & R²
- `fss_nu_R2_curve.csv` — full R²(ν) grid for p′_c(L) shift fits (rows at ν = 0.88, 1.50 flagged)
- `fss_pcL_fits.png` — pc′(L) vs L^(−1/ν) with fits
- `fss_nu_of_kappa.png` — ν(κ): shift, width & collapse estimators with jackknife bars
- `alpha_window_pcL.csv`, `alpha_window_summary.csv` — M4 window sensitivity (from `alpha_window_sensitivity`)
- `void_geom_fss_kappa0.csv` — per-seed geometric pc′_geom(L) at κ = 0 (long: L, seed, pc_geom_z)
- `void_geom_fss_kappa0_summary.csv` — mean ± std of pc′_geom(L) per L (from `void_geom_FSS_kappa0`)

## Reading the result

- **Sanity check:** random (κ=0) pc′(∞) should sit near **1 − p_c ≈ 0.688**. Compare R²_p88 vs R²_150 in `fss_nu_summary.csv` (and the full curve in `fss_nu_R2_curve.csv`) to see which fixed ν the shift data prefer.
- **Two classes?** Compare κ=0 vs templated-6N ν across all three estimators.
- **The κ question:** ν(κ) **flat** → one universality class, κ tunes a *non-universal* threshold (conservative story). ν(κ) **sloped** → κ-dependent exponents (bold story) — only claim this if the three estimators agree tightly.
- **κ=1 (Eden):** pc′→1, single cluster — not a conventional critical point. Reported as a **bound**, not a class exponent.

## Caveats / knobs

- **Memory at L=750:** the L³ logical lattice is ~420 MB and is broadcast to each `parfor`
  worker. On a machine with limited RAM, reduce the pool size (`parpool('local', N)`) for the
  L=750 pass, or run L=750 separately.
- **Window edges:** if a pc′(L) lands on a window edge (check `p_lo`/`p_hi` in
  `fss_pcL_table.csv`), widen that condition's `win` in `RW3D_FSS_study.m` and re-run — only
  the affected condition recomputes.
- **Small L + high κ:** near κ=1 the critical p is ~0.99, so small lattices have few free
  sites; the driver caps walkers to the available free sites (and warns), and skips a point
  entirely if the free fraction drops below 2%. Expect κ=1 to be usable mainly at larger L.
- **Runtime:** dominated by the L=750 pass (L_W = 2.25×10⁶). Budget it like the existing
  production κ run, up to ~2–3× longer overall; run headless.
