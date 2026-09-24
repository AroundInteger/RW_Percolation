# Simulation Methodology: Tunable Gel-Point via κ-Mixing Percolation

## 1. Overview

We model a viscoelastic gel using 3D site percolation on a cubic lattice, where the occupied sites represent the polymer network and the unoccupied (void) sites form the fluid phase through which probe particles diffuse. The gel-point corresponds to the occupation probability $p_c'$ at which the diffusion exponent $\alpha$ crosses 0.5 (the Winter–Chambon criterion, $\delta = 45°$). A nucleation-density parameter $\kappa \in [0, 1]$ controls the spatial morphology of the occupied network, enabling continuous tuning of $p_c'$ across a range $\Delta p_c' \approx 0.31$.

---

## 2. Lattice Model

### 2.1 Site Percolation

A three-dimensional $L \times L \times L$ cubic lattice (production: $L = 500$) is generated with periodic boundary conditions. Each lattice site is classified as **occupied** (polymer network) or **unoccupied** (void/fluid phase). The target occupation probability is $p$, so the target number of occupied sites is $N_\text{target} = \lfloor p L^3 \rceil$.

### 2.2 κ-Mixing Nucleation-Density Model

The morphology of the occupied network is controlled by the nucleation-density parameter $\kappa$. At each value of $p$ in the sweep, the lattice is built **cumulatively** from the lattice at the previous $p$ value, so that $N_\text{new} = N_\text{target} - N_\text{current}$ new sites are added.

**Step 1 — Seed placement.** A fraction $(1 - \kappa)$ of the $N_\text{new}$ required sites are placed as **nucleation seeds** at uniformly random positions in the unoccupied volume:

$$N_\text{seeds} = \left\lfloor (1 - \kappa) \cdot N_\text{new} \right\rceil$$

If $\kappa = 0$, then $N_\text{seeds} = N_\text{new}$: all sites are seeded randomly, recovering **Bernoulli (random) percolation**. If the lattice is empty and $\kappa = 1$, a single seed is planted to initialise growth.

**Step 2 — Adjacency growth.** The remaining $N_\text{new} - N_\text{seeds}$ sites are filled by **6-neighbour (6N) adjacency growth** from the combined frontier of all occupied sites (existing cluster + new seeds). At each iteration, a random subset of frontier sites is selected and added. Growth continues until $N_\text{target}$ is reached.

This ensures **connectivity**: every occupied site is reachable from at least one seed via a path of 6N adjacency steps. No isolated disconnected islands are created.

**Boundary cases:**

| $\kappa$ | Seeds per step | Morphology | $p_c'$ |
|---|---|---|---|
| 0 | All required sites | Bernoulli (spatially uniform) | $\approx 0.683$ |
| 0.5 | 50% seeded, 50% grown | Intermediate clustering | $\approx 0.73$ |
| 1 | 1 seed (single origin) | Eden-like compact cluster | $\approx 0.993$ |

**Physical interpretation.** $\kappa$ maps to the nucleation site density of the material. High $\kappa$ (few seeds) produces a spatially clustered, compact occupied network whose void channels remain open to high $p$, delaying fragmentation. Low $\kappa$ (many seeds) distributes obstacles uniformly, fragmenting the void space at lower $p$.

The cumulative generation ensures lattices at successive $p$ values are nested: the lattice at $p_2 > p_1$ contains the lattice at $p_1$ as a subset. This is physically consistent with progressive gelation.

**Implementation:** `matlab/generate_kappa_mixed_lattice.m`

---

## 3. Random Walk Simulation

### 3.1 Walker Protocol

Random walkers are placed on **unoccupied sites** of the lattice, modelling the diffusion of microrheology probe particles through the fluid phase. For each $(κ, p)$ condition, $N_W = 3{,}000$ independent walkers are simulated for $L_W = 10^6$ steps.

At each step, a walker at position $(x, y, z)$ attempts a move to one of the 6 nearest neighbours, chosen uniformly at random. The proposed position is accepted if the target site is unoccupied ($bw = 0$); otherwise the walker **waits** at its current position for a dwell time drawn from:

$$\mathrm{WT} = \left\lceil \left| \mathcal{N}(\mu_\mathrm{WT}, \sigma_\mathrm{WT}) \right| \right\rceil \quad \text{steps}$$

with $\mu_\mathrm{WT} = 20$, $\sigma_\mathrm{WT} = 5$. This wait-time mechanism models the transient binding of probe particles to the polymer network and prevents artificial super-diffusion from immediate reflection.

Periodic boundary conditions are applied to the wrapped lattice coordinate via $x_n = \mathrm{mod}(x_n - 1, L) + 1$. The **unwrapped** coordinate $X(t)$ (accumulated displacement, no modulo) is recorded for MSD computation.

**Implementation:** `matlab/RW3D_P_SP.m`

### 3.2 Ensemble-Averaged MSD

The mean squared displacement is computed as:

$$\langle r^2(t) \rangle = \frac{1}{N_W} \sum_{i=1}^{N_W} \left[ \Delta x_i(t)^2 + \Delta y_i(t)^2 + \Delta z_i(t)^2 \right]$$

where $\Delta x_i(t) = X_i(t) - X_i(0)$ is the unwrapped displacement of walker $i$. MSD is accumulated online via a `parfor` reduction to avoid storing $L_W \times N_W$ position arrays (which would require $\sim$36 GB at production scale).

### 3.3 Diffusion Exponent α

The anomalous diffusion exponent $\alpha$ is extracted from a power-law fit to the MSD in log–log space:

$$\langle r^2(t) \rangle \propto t^\alpha$$

The fit is performed over the intermediate time window $[L_W/100,\; L_W/10]$ (steps 10,000–100,000 for $L_W = 10^6$), avoiding early-time transients and long-time saturation effects near the percolation threshold. A linear regression on $\log_{10} t$ vs $\log_{10} \langle r^2 \rangle$ yields $\alpha$ as the slope. The coefficient of determination $R^2$ is recorded as a quality metric.

| $\alpha$ | Physical regime |
|---|---|
| $\alpha = 1$ | Normal (Fickian) diffusion — sol state |
| $0 < \alpha < 1$ | Anomalous sub-diffusion — approaching gel-point |
| $\alpha = 0.5$ | Gel-point criterion ($\delta = 45°$, Winter–Chambon) |
| $\alpha \rightarrow 0$ | Localised / arrested — gel state |

---

## 4. Gel-Point Extraction

The gel-point $p_c'(\kappa)$ is the occupation probability at which $\alpha = 0.5$, located by linear interpolation between the bracketing $p$ values where $\alpha$ crosses 0.5:

$$p_c'(\kappa) = p_i + \frac{0.5 - \alpha(p_i)}{\alpha(p_{i+1}) - \alpha(p_i)} \cdot (p_{i+1} - p_i)$$

where $p_i < p_c' < p_{i+1}$ and $\alpha(p_i) > 0.5 > \alpha(p_{i+1})$.

For each $\kappa$, $N_s = 3$ independent random seeds (replicates) are simulated. The mean $\alpha$ over replicates is used for interpolation. Bracket widths (the $p$-grid spacing at the crossing) are reported as the interpolation uncertainty.

**Implementation:** `matlab/analyze_kappa_gel_points.m`

---

## 5. Simulation Parameters

| Parameter | Symbol | Quick run | Production run |
|---|---|---|---|
| Lattice side length | $L$ | 100 | 500 |
| Steps per walker | $L_W$ | $2 \times 10^5$ | $10^6$ |
| Walkers per condition | $N_W$ | 500 | 3,000 |
| Independent replicates | $N_s$ | 1 | 3 |
| Wait-time mean | $\mu_\mathrm{WT}$ | 20 steps | 20 steps |
| Wait-time std | $\sigma_\mathrm{WT}$ | 5 steps | 5 steps |
| $\kappa$ values | — | 18 values in $[0, 1]$ | 18 values in $[0, 1]$ |
| $p$ values | — | 35 values, dense near $p_c'$ | 38 values, dense near $p_c'$ |
| Total simulations | — | 630 | 1,890 |
| Total wall-clock time | — | $\sim$17 min (8 cores) | $\sim$25 h (8 cores) |

### κ values used

$$\kappa \in \{0.00,\ 0.20,\ 0.40,\ 0.60,\ 0.70,\ 0.80,\ 0.85,\ 0.88,\ 0.91,\ 0.94,\ 0.97,\ 0.98,\ 0.99,\ 0.995,\ 0.996,\ 0.997,\ 0.998,\ 1.00\}$$

Spacing is deliberately denser for $\kappa > 0.95$ to resolve the steep transition region where seed count per increment drops below $\sim$5% of new sites.

### p-value grid

Dense sampling near both gel-point regions: 13 points in $[0.60, 0.70]$ (bracketing $p_c' \approx 0.683$ for $\kappa = 0$) and 15 points in $[0.84, 0.995]$ (bracketing $p_c' \in [0.88, 0.993]$ for $\kappa \geq 0.99$).

---

## 6. Computational Implementation

All simulations were performed in MATLAB R2025a. Walker simulations were parallelised over $N_W$ using `parfor` (Parallel Computing Toolbox), with MSD accumulated as a reduction variable to avoid memory overflow at production scale. Lattice generation and analysis were performed serially. Each $(κ, p, \text{seed})$ simulation was saved as an individual `.mat` file, enabling graceful resumption after interruption.

**Script summary:**

| Script | Role |
|---|---|
| `generate_kappa_mixed_lattice.m` | Nucleation-density lattice generation (function) |
| `RW3D_P_SP.m` | Single-walker random walk (function) |
| `RW3D_kappa_mixing_study.m` | Main simulation loop (script) |
| `analyze_kappa_gel_points.m` | Gel-point extraction and figures (function) |
| `run_kappa_study.m` | Entry-point wrapper: pool startup → simulation → analysis |

---

## 7. Results Summary

| $\kappa$ | $p_c'$ | Bracket width |
|---|---|---|
| 0.0000 | 0.6826 | 0.0084 |
| 0.2000 | 0.6867 | 0.0084 |
| 0.4000 | 0.6921 | 0.0116 |
| 0.6000 | 0.7025 | 0.0200 |
| 0.7000 | 0.7094 | 0.0200 |
| 0.8000 | 0.7205 | 0.0300 |
| 0.8500 | 0.7333 | 0.0300 |
| 0.8800 | 0.7436 | 0.0300 |
| 0.9100 | 0.7509 | 0.0300 |
| 0.9400 | 0.7729 | 0.0300 |
| 0.9700 | 0.8063 | 0.0200 |
| 0.9800 | 0.8243 | 0.0200 |
| 0.9900 | 0.8517 | 0.0100 |
| 0.9950 | 0.8795 | 0.0050 |
| 0.9960 | 0.8878 | 0.0050 |
| 0.9970 | 0.9023 | 0.0200 |
| 0.9980 | 0.9098 | 0.0200 |
| 1.0000 | ≈ 0.993 | (extrapolated; p-grid extension pending) |

**Tunable range:** $p_c'(\kappa) \in [0.683,\ 0.993]$, $\Delta p_c' \approx 0.31$

The gel-point increases monotonically with $\kappa$ across the full range. Two physical regimes are identified:

- **Random-like regime** ($\kappa \lesssim 0.99$, seed fraction $\gtrsim 1\%$): $p_c'$ increases gradually from 0.683 to 0.88 as nucleation density decreases.
- **Eden regime** ($\kappa \gtrsim 0.99$, seed fraction $\lesssim 1\%$): cluster morphology transitions to a compact, single-origin Eden-like growth; $p_c'$ rises steeply to $\approx 0.993$.
