# Random walks on percolation lattices: the viscoelastic gel point

Probe particles are modelled as random walkers on the unoccupied (void) sites of a three-dimensional site-percolation lattice. The gel point is the occupation at which the anomalous-diffusion exponent reaches the Winter–Chambon value α = 0.5.

## Manuscript

The current paper is the letter and its supplement:

- `paper_drafts/prl_letter.tex`
- `paper_drafts/supplemental.tex`
- `paper_drafts/prl_combined.tex` (the same text in one file)
- `paper_drafts/figures_v2/`

`LEDGER.md` records what was archived and why. Superseded drafts live under `archive/legacy_pre_fss/` and are not current results.

## Results in the letter

1. **The gel point is void percolation.** For random growth the dynamical gel point agrees with the geometric void-spanning threshold, pc′ ≃ 1 − pc ≈ 0.68. The two stay together for nucleation densities κ ≲ 0.8.
2. **Nucleation density shifts the gel point.** A single parameter κ, the fraction of new sites grown from the cluster frontier rather than placed as independent nuclei, moves pc′ from about 0.68 towards 1. κ = 0 is Bernoulli percolation; κ = 1 is single-seed Eden growth.
3. **One effective critical character.** Finite-size scaling from L = 50 to 750 gives ν_eff ≈ 1.6 with no systematic trend in κ for κ ≤ 0.8. That exponent is not the static 3D percolation value ν = 0.88, and the κ family is not a set of distinct universality classes. At κ ≳ 0.97 the transition is an Eden crossover, and passive microrheology mildly over-reads the structural gel point.
4. **How α is measured.** α is the log–log slope of the mean squared displacement on the fixed window [L_W/100, L_W/10]. It is not a changepoint time.

Adjacency-constrained 6-neighbour and 26-neighbour growth sit inside this κ family. They are a robustness check, not a separate gelation class.

## Layout

Work in `paper_drafts/`. That folder is the manuscript: the letter, the supplement, `figures_v2/`, and the methods note.

```
RW_Percolation/
├── paper_drafts/            # The paper. This is the folder to use.
├── matlab/                  # Production scripts, including the finite-size study
├── ensemble_simulations/    # Ensemble random-walk output
├── lattices_L100_seq/       # Lattice realisations
├── archive/legacy_pre_fss/  # Everything else: old drafts, old projects, analysis dumps
├── LEDGER.md
└── README.md
```

## Status

The letter is the manuscript in preparation. Earlier notes that report two universality classes, a 98.6% prediction accuracy, or a changepoint scaling of τ_cr are archived and should not be cited as results.

A short paper on rod-like growth is deferred until this letter has been submitted for review. It is not part of the current manuscript.
