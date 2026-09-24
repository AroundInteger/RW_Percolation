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
% 1) SMOKE TEST first (a few minutes): L = {40,70,110}, NW = 200, 1 seed,
%    coarse grid, all 6 conditions. Then run analyze_FSS on it — this checks
%    the FULL pipeline including the nu fit (which needs >= 3 sizes).
MODE = 'quick'; RW3D_FSS_study
analyze_FSS
%    Expected: it runs clean, writes fss_alpha_table.csv, fss_pcL_table.csv,
%    fss_nu_summary.csv and the two PNGs, and prints a nu per condition.
%    The NUMBERS are noise here (tiny L, short LW) — you're checking it WORKS,
%    not the physics. Delete matlab/FSS_study/ before the production run.

% 2) THE REAL CAMPAIGN (headless, hours-to-days — use nohup):
% nohup /Applications/MATLAB_R2025a.app/bin/matlab -nodisplay \
%     -r "RW3D_FSS_study; exit" > fss_study.log 2>&1 &

analyze_FSS      % after the production run completes (resumable — re-run any time)
```

Resumable: existing per-`(condition,L,p,seed)` `.mat` files are skipped, so a killed run
picks up where it left off.

## Outputs (`matlab/FSS_study/`)

- `fss_alpha_table.csv/.mat` — α(p,L) for every condition/size/seed
- `fss_pcL_table.csv` — pc′(L) and logistic width w(L) per (condition, L)
- `fss_nu_summary.csv` — pc′(∞), ν_shift, ν_width, ν_collapse per condition
- `fss_pcL_fits.png` — pc′(L) vs L^(−1/ν) with fits
- `fss_nu_of_kappa.png` — ν(κ) with error bars (flat = one class; sloped = κ-dependent exponents)

## Reading the result

- **Sanity check:** random (κ=0) ν_shift should land near **0.88** (3D percolation). If it doesn't, something's off before you trust anything else.
- **Two classes?** Compare κ=0 vs templated-6N ν across all three estimators.
- **The κ question:** ν(κ) **flat** → one universality class, κ tunes a *non-universal* threshold (conservative story). ν(κ) **sloped** → κ-dependent exponents (bold story) — only claim this if the three estimators agree tightly.
- **κ=1 (Eden):** pc′→1, single cluster — not a conventional critical point. Reported as a **bound**, not a class exponent.

## Caveats / knobs

- **Memory at L=750:** the L³ logical lattice is ~420 MB and is broadcast to each `parfor`
  worker. On a 64 GB M3 Max this is a non-issue (~6 GB across a full ~12–14-worker pool);
  run at full pool size. Only on a low-RAM machine would you reduce the pool
  (`parpool('local', N)`) for the L=750 pass.
- **Window edges:** if a pc′(L) lands on a window edge (check `p_lo`/`p_hi` in
  `fss_pcL_table.csv`), widen that condition's `win` in `RW3D_FSS_study.m` and re-run — only
  the affected condition recomputes.
- **Small L + high κ:** near κ=1 the critical p is ~0.99, so small lattices have few free
  sites; the driver caps walkers to the available free sites (and warns), and skips a point
  entirely if the free fraction drops below 2%. Expect κ=1 to be usable mainly at larger L.
- **Runtime:** dominated by the L=750 pass (L_W = 2.25×10⁶). Budget it like the existing
  production κ run, up to ~2–3× longer overall; run headless.
