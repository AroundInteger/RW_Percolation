# Tunable gel-point positioning in three-dimensional percolation networks via nucleation density control

**[Author Names]**
*[Affiliations]*
*[Email addresses]*

---

## Abstract

The viscoelastic gel-point of a polymer network is commonly treated as a fixed property of chemistry and concentration. Here we demonstrate, through three-dimensional random walk simulations on site-percolation lattices, that the gel-point is instead controlled by the growth dynamics of the forming network and can be continuously programmed via a single nucleation-density parameter. Probe-particle diffusion is modelled by random walkers confined to the unoccupied (void) sublattice of an $L \times L \times L$ cubic lattice ($L = 500$); the gel-point $p_c'$ is identified by the Winter–Chambon criterion $\alpha = 0.5$, where $\langle r^2(t) \rangle \propto t^\alpha$. For random (Bernoulli) percolation networks we find $p_c' \approx 0.683 \approx 1 - p_c$, quantitatively identifying the rheological gel-point with the loss of spanning connectivity in the void phase. Replacing random growth with adjacency-templated cluster growth shifts the gel-point to $p_c' \approx 0.886$ ($\Delta p_c' = +0.20$) and qualitatively alters the transition: the critical region is 3.4-times broader and probe particles remain persistently sub-diffusive ($\alpha \approx 0.3$–$0.4$) well above $p_c'$, a signature absent in the random class. Interpolating between these limits via a nucleation-density parameter $\kappa \in [0,1]$ — which controls the fraction of newly occupied sites placed as independent nuclei versus grown from the cluster frontier — yields a monotonically tunable gel-point spanning $\Delta p_c' \approx 0.31$ ($p_c' \in [0.683, 0.993]$). Frequency-domain viscoelastic spectra $G'(\omega)$ and $G''(\omega)$ derived via the Generalised Stokes–Einstein Relation confirm the $\delta(\omega) = 45^{\circ}$ Winter–Chambon signature at $p_c'$ for both gelation classes. These results establish nucleation density as a structural design parameter for programming the gel-point in network-forming materials.

**Keywords:** percolation, viscoelasticity, gel-point, microrheology, Winter–Chambon criterion, nucleation density, random walk, GSER

---

## 1. Introduction

The gelation of polymer solutions and colloidal suspensions — the transition from a viscous fluid to a viscoelastic solid — is characterised by a well-defined gel-point $p_c'$ at which the loss tangent $\tan\delta = G''/G'$ becomes frequency-independent and equal to unity \citep{Chambon1987,Winter1987}. In the Winter–Chambon framework this corresponds to a phase angle $\delta = 45°$ and a power-law mean squared displacement (MSD) $\langle r^2(t) \rangle \propto t^{0.5}$, measurable by passive microrheology through the Generalised Stokes–Einstein Relation (GSER) \citep{Mason1995,Mason2000,Squires2010}. The gel-point is routinely used as the defining characteristic of a material system, and a considerable body of literature has established its dependence on polymer concentration, cross-link density, and temperature \citep{Rubinstein2003,Larson1999}.

What is rarely asked, however, is whether the gel-point is also a function of *how the network forms* — that is, of the spatial growth dynamics of the cluster itself. In colloidal gels, crystallising proteins, and biopolymer networks, cluster growth is not random; it is governed by nucleation and propagation rules that produce morphologies ranging from fractal aggregates to compact, space-filling domains \citep{Trappe2001,Gibaud2012,Ng2016}. Whether these different morphologies shift the gel-point, and whether that shift can be controlled by a single parameter, has not been systematically established.

In this paper we use three-dimensional random walk (RW) simulations on site-percolation lattices to address this question directly. The approach is motivated by passive microrheology: probe particles in a gelling medium diffuse through the *void* (fluid) phase of the network, not through the network itself \citep{deBruyn2013,Rich2011,Oppong2006}. We therefore place walkers on the unoccupied sublattice of an $L \times L \times L$ cubic lattice, sweeping the occupation probability $p$ from 0 to 1 and tracking the anomalous diffusion exponent $\alpha(p)$. The gel-point $p_c'$ is identified by $\alpha = 0.5$, which corresponds to $\delta = 45°$ via the GSER. This places the model firmly within the Winter–Chambon framework for critical gelation \citep{Winter1987,Chambon1987,Muthukumar1989}.

We present three interconnected results. First, for randomly generated percolation networks (Bernoulli site percolation), the gel-point coincides quantitatively with the loss of spanning connectivity in the void sublattice: $p_c' \approx 1 - p_c \approx 0.683$, where $p_c = 0.3116$ is the 3D site percolation threshold. This is not a coincidence — it is a direct consequence of the walkers probing the void-phase topology, and it provides a quantitative link between the rheological gel-point and a well-characterised geometric phase transition. Second, replacing random growth with adjacency-constrained templated growth — where new occupied sites must be adjacent to existing cluster members, mimicking nucleation-and-growth kinetics — shifts the gel-point by $\Delta p_c' = +0.20$ to $p_c' \approx 0.886$, and qualitatively changes the nature of the transition. Third, a single nucleation-density parameter $\kappa$ interpolates continuously between these two limits, providing monotonic control over $p_c'$ across a range $\Delta p_c' \approx 0.31$. We complement these structural results with GSER-derived frequency-domain spectra $G'(\omega)$ and $G''(\omega)$, confirming the $\delta(\omega) = 45°$ signature at $p_c'$ for both gelation classes.

Together these results demonstrate that the gel-point of a percolating network is not fixed by density alone — it is set by the growth dynamics of the network-forming phase, and is tunable via the nucleation density of the growing cluster.

---

## 2. Model and Methods

### 2.1 Lattice model

We consider a three-dimensional simple cubic lattice of side length $L = 500$ with periodic boundary conditions. Each site is classified as *occupied* (network phase) or *unoccupied* (void/fluid phase). The occupation probability $p$ sets the target number of occupied sites $N_\mathrm{target} = \lfloor p L^3 \rceil$. Lattices are generated cumulatively: at each successive value of $p$ in the sweep, $N_\mathrm{new} = N_\mathrm{target}(p) - N_\mathrm{target}(p_\mathrm{prev})$ sites are added to the existing lattice, so that higher-$p$ lattices contain all sites present at lower $p$ as a strict subset. This is physically consistent with progressive gelation and ensures continuity across the $p$-sweep.

#### 2.1.1 Random (Bernoulli) percolation

In the *random percolation* and *density-increment* variants, the $N_\mathrm{new}$ additional sites are selected uniformly at random from the remaining unoccupied volume, with no adjacency constraint. This recovers classical Bernoulli site percolation in the cumulative sense, and both variants give indistinguishable $\alpha(p)$ curves (Sec. 3.1).

#### 2.1.2 Adjacency-templated growth

In the *templated* variants, new sites must be placed adjacent to at least one already-occupied site, enforcing connectivity of the growing cluster. Two adjacency rules are studied: 6-neighbour (6N, face-sharing only) and 26-neighbour (26N, face- and corner-sharing). Growth proceeds by iteratively selecting sites from the frontier of the current cluster. As shown in Sec. 3.2, both 6N and 26N rules give indistinguishable gel-points, indicating that the precise adjacency rule is secondary to the connectivity constraint itself.

#### 2.1.3 $\kappa$-mixing nucleation-density model

To interpolate continuously between random and templated growth, we introduce the nucleation-density parameter $\kappa \in [0, 1]$. At each $p$-step, the $N_\mathrm{new}$ required sites are allocated as follows:

$$
N_\mathrm{seeds} = \left\lfloor (1-\kappa)\, N_\mathrm{new} \right\rceil
$$

seed sites are placed at uniformly random positions in the unoccupied volume; the remaining $N_\mathrm{new} - N_\mathrm{seeds}$ sites are filled by 6N adjacency growth from the combined frontier of all occupied sites (existing cluster plus new seeds). Connectivity is guaranteed by construction: every occupied site can be reached from at least one seed via a path of adjacency steps. If $\kappa = 0$, all sites are seeded randomly, recovering Bernoulli percolation. If $\kappa = 1$, a single seed is planted at $p = 0$ and all subsequent growth is adjacency-driven, producing a compact, connected cluster morphology reminiscent of Eden growth \citep{Eden1961}. We study 18 values of $\kappa$ spaced densely near $\kappa = 1$ (where the gel-point shifts most steeply): $\kappa \in \{0.00,\, 0.20,\, 0.40,\, 0.60,\, 0.70,\, 0.80,\, 0.85,\, 0.88,\, 0.91,\, 0.94,\, 0.97,\, 0.98,\, 0.99,\, 0.995,\, 0.996,\, 0.997,\, 0.998,\, 1.00\}$.

### 2.2 Random walk simulation

Random walkers are placed on *unoccupied* sites of the lattice, modelling the diffusion of microrheology probe particles through the fluid phase of the gelling medium. For each $(\kappa, p)$ condition, $N_W = 3000$ independent walkers are simulated for $L_W = 10^6$ steps ($N_W = 500$, $L_W = 2\times 10^5$ for the Clusters1 base-case study). At each step, a walker at position $(x, y, z)$ attempts a move to one of the six nearest neighbours chosen uniformly at random. If the target site is unoccupied the move is accepted; if it is occupied the walker waits at its current position for a dwell time

$$
\mathrm{WT} = \left\lceil \left|\mathcal{N}(\mu_\mathrm{WT},\, \sigma_\mathrm{WT})\right| \right\rceil \text{ steps},
$$

with $\mu_\mathrm{WT} = 20$, $\sigma_\mathrm{WT} = 5$. This wait-time mechanism models transient binding of the probe to the network and prevents artificial super-diffusion from immediate reflection. Periodic boundary conditions are applied via $x_n = \mathrm{mod}(x_n - 1,\, L) + 1$; the *unwrapped* (accumulated) coordinate $X(t)$ is recorded for MSD computation.

The ensemble-averaged MSD is

$$
\langle r^2(t) \rangle = \frac{1}{N_W} \sum_{i=1}^{N_W}
    \left[\Delta x_i(t)^2 + \Delta y_i(t)^2 + \Delta z_i(t)^2\right],
$$

accumulated online via a parallel-reduction loop to avoid storing $O(L_W N_W)$ trajectory arrays ($\sim$36 GB at production scale).

### 2.3 Gel-point extraction

The anomalous diffusion exponent $\alpha$ is extracted from a power-law fit to $\langle r^2(t)\rangle$ in log–log space over the intermediate time window $[L_W/100,\, L_W/10]$ (steps $10^4$–$10^5$ for $L_W = 10^6$), avoiding early-time transients and long-time saturation. A linear regression of $\log_{10} t$ on $\log_{10}\langle r^2 \rangle$ gives $\alpha$ as the slope. The gel-point $p_c'(\kappa)$ is identified as the value of $p$ at which $\alpha = 0.5$ (corresponding to a phase angle $\delta = 45°$ in the Winter–Chambon framework), located by linear interpolation between the bracketing $p$ values:

$$
p_c' = p_i + \frac{0.5 - \alpha(p_i)}{\alpha(p_{i+1}) - \alpha(p_i)}\,(p_{i+1} - p_i),
$$

where $\alpha(p_i) > 0.5 > \alpha(p_{i+1})$. For the $\kappa$-mixing study, $N_s = 3$ independent replicates per $(\kappa, p)$ condition are averaged before interpolation.

### 2.4 Frequency-domain viscoelastic spectra

MSD data at the gel-point are converted to complex shear moduli $G^*(\omega) = G'(\omega) + \mathrm{i}G''(\omega)$ via the GSER \citep{Mason1995}:

$$
G^*(\omega) \approx \frac{k_B T}{\pi a \langle r^2(1/\omega) \rangle \,\Gamma(1+\alpha(\omega))},
$$

where $a$ is the probe radius, $k_B T$ the thermal energy, and $\alpha(\omega)$ the local logarithmic slope of the MSD evaluated at lag time $1/\omega$. Physical parameters used: $T = 293\,\mathrm{K}$, $\eta = 1.2\times 10^{-3}\,\mathrm{Pa\,s}$, $a = 0.243\,\mu\mathrm{m}$.

### 2.5 Simulation parameters

Key parameters are summarised in Table 1. All simulations were performed in MATLAB R2025a with `parfor` parallelisation over $N_W$.

**Table 1. Simulation parameters.**

| Parameter | Symbol | Base-case (Clusters1) | $\kappa$-mixing study |
|---|---|---|---|
| Lattice side length | $L$ | 500 | 500 |
| Steps per walker | $L_W$ | $10^6$ | $10^6$ |
| Walkers per condition | $N_W$ | 3000 | 3000 |
| Independent replicates | $N_s$ | 1 | 3 |
| Wait-time mean / std | $\mu_\mathrm{WT}$, $\sigma_\mathrm{WT}$ | 20, 5 steps | 20, 5 steps |
| $p$-value grid | — | 54 values, $p \in [0, 0.99]$ | 38 values, $p \in [0, 0.995]$ |
| $\kappa$ values | — | — | 18 values, $\kappa \in [0, 1]$ |
| Total $(p,\kappa,s)$ conditions | — | 216 | 1890 |

---

## 3. Results

Figure 1 provides a two-dimensional schematic of the four growth mechanisms studied, illustrating the qualitative morphological differences and their consequences for void connectivity at identical occupation densities.

**Figure 1** (`figures/fig_schematic_growth.png`). **Growth mechanism morphologies and their gel-point hierarchy (2D schematic).** Each row depicts a different growth mechanism at three identical values of the occupation density $p$ (columns). Border colour indicates void-connectivity state: green = sol (spanning connected void $> 50\%$); orange $\approx p_c'$ (transitioning); red = gel (spanning void $< 12\%$, void fragmented into isolated pockets, shown pink). *Row 1: Bernoulli (random percolation).* Sites are placed uniformly at random; the network is already gelled ($p_c' \approx 0.41$ in this 2D illustration) at $p = 0.55$ and $p = 0.70$. *Row 2: 6N adjacency-templated.* Growth proceeds by 4-connected Eden expansion from 18 Poisson-disk distributed seeds; compact blocky blobs grow and merge, with the gel-point near $p = 0.55$ (orange border). *Row 3: 26N adjacency-templated.* As row 2 but with 8-connected growth, producing rounder blobs that merge marginally earlier than 6N. *Row 4: Eden ($\kappa = 1$), single seed.* A single central seed grows as a compact disc; at $p = 0.70$ where rows 1–3 are all gelled, the void still forms a connected frame around the cluster (green border, 54% spanning), demonstrating the markedly elevated gel-point ($p_c' \approx 0.99$ in 3D) of the single-seed limit. Note: 2D gel-points shown here are illustrative; quantitative gel-points reported in the text are from the full 3D ($L = 500$) simulations.

### 3.1 Gel-point in random percolation: $p_c' \approx 1 - p_c$

Figure 2 shows $\alpha(p)$ for the two random-growth variants (random percolation and density increment) over the full range $p \in [0, 1]$ (panel a) and the critical region (panel b). Both variants give indistinguishable curves: $\alpha \approx 1$ (Fickian diffusion, sol state) for $p \lesssim 0.60$, a sharp monotonic decline through the gel criterion $\alpha = 0.5$, and rapid arrest ($\alpha \to 0$) above $p_c'$.

Linear interpolation of $\alpha(p)$ through 0.5 gives:

$$
p_c'(\text{random percolation}) = 0.6832, \qquad
p_c'(\text{density increment}) = 0.6834.
$$

Both values agree to within $\Delta p = 0.0002$, confirming that the gel-point is insensitive to whether the lattice is generated independently at each $p$ or cumulatively, as long as the spatial distribution of occupied sites is random.

The gel-points bracket the complementary void-percolation threshold $1 - p_c = 1 - 0.3116 = 0.6884$ from below, with an offset of $0.0052$ in $p$. This offset is consistent with finite-size effects at $L = 500$ (the threshold shifts toward $1 - p_c$ as $L \to \infty$). The physical interpretation is direct: the walkers reside in the void sublattice, which undergoes its own site-percolation transition. The void sublattice loses spanning connectivity when the occupied fraction $p$ exceeds $1 - p_c$; at this point, walkers are confined to finite void clusters and their long-time diffusion becomes anomalous with $\alpha = 0.5$ at the transition. The Winter–Chambon gel criterion thus coincides with the void-phase percolation threshold, not with the occupied-cluster threshold $p_c$.

Above $p_c'$, $\alpha$ collapses sharply to near zero within $\Delta p \approx 0.03$, corresponding to complete walker arrest as the void phase fragments into disconnected pockets. This narrow transition width ($\sigma_\mathrm{sigmoid} = 0.015$ from a sigmoid fit) is characteristic of a sharp percolation-like transition.

**Figure 2** (`figures/fig1_bernoulli_class.png`). **Gel-point in random percolation networks.** Anomalous diffusion exponent $\alpha(p)$ for the two Bernoulli-class variants (random percolation, blue; density increment, green) over the full range (a) and the critical region (b). Both variants give indistinguishable gel-points at $p_c' = 0.683 \approx 1 - p_c$ (dashed blue vertical line), coinciding with the loss of spanning connectivity in the void sublattice. The dashed horizontal line marks the Winter–Chambon gel criterion $\alpha = 0.5$. Simulation parameters: $L = 500$, $N_W = 3000$, $L_W = 10^6$ steps.

### 3.2 Growth-rule sensitivity: adjacency-templated gelation

Figure 3 shows $\alpha(p)$ for all four variants. The two templated variants (6N and 26N adjacency) behave identically to each other but qualitatively differently from the random class in three respects.

**Shifted gel-point.** Linear interpolation gives:

$$
p_c'(\text{6N templated}) = 0.8856, \qquad
p_c'(\text{26N templated}) = 0.8861,
$$

a shift of $\Delta p_c' = +0.20$ relative to the random class. The interpolation bracket spans only $[0.880, 0.890]$ (width $0.010$ in $p$), and $\alpha$ at the bracketing points is $(0.516, 0.487)$ for 6N and $(0.508, 0.495)$ for 26N — the crossing of $\alpha = 0.5$ is clean and well-resolved in both cases.

**Broader transition.** A sigmoid fit to $\alpha(p)$ in the templated class (padded with $\alpha = 0$ at $p = 1$) gives a transition width $\sigma_\mathrm{sigmoid} = 0.052$, compared to 0.015 for the random class — a factor of 3.4 broader. The critical region extends over $\Delta p \approx 0.10$ rather than $\approx 0.03$.

**Persistent sub-diffusion above $p_c'$.** In the random class, $\alpha$ drops to near zero ($\alpha < 0.05$) within $\Delta p \approx 0.03$ above $p_c'$. In the templated class, $\alpha$ remains at $0.3$–$0.4$ even at $p = 0.95$ (Fig. 3b), $\Delta p = 0.064$ above $p_c'$. This persistent sub-diffusion is absent in the random class and constitutes a qualitative dynamical signature of the templated morphology: the compact, connected cluster geometry maintains open, tortuous void channels at high occupation density, allowing slow but non-arrested walker motion far above the gel-point.

Both the 6N and 26N adjacency rules give nearly identical results ($|\Delta p_c'| = 0.0005$), demonstrating that it is the *connectivity constraint itself* — not the precise number of neighbours used to enforce it — that drives the gel-point shift. We therefore refer to these jointly as the *templated class*.

It is important to distinguish the templated class from the single-seed Eden limit ($\kappa = 1$) introduced in Section 3.3. In the templated variants, growth proceeds from *many* independently seeded nuclei (each new $p$-step plants $N_\mathrm{seeds} \sim N_\mathrm{new}$ random seeds), producing a morphology of many compact blobs that coalesce as $p$ increases. This multi-seed topology yields $p_c' \approx 0.886$. By contrast, the $\kappa = 1$ Eden limit uses a *single* persistent seed and all subsequent growth is adjacency-driven, producing a single compact cluster that maintains open, connected void until $p \to 1$ (Fig. 1, bottom row). It is nucleation density — not the adjacency rule itself — that separates the templated class ($p_c' \approx 0.886$) from the Eden limit ($p_c' \approx 0.993$), with $\kappa$-mixing providing continuous interpolation between these endpoints.

**Figure 3** (`figures/fig2_two_classes.png`). **Two kinetically distinct gelation classes.** $\alpha(p)$ for all four growth variants over the full range (a) and the extended critical region $p \in [0.55, 1.0]$ (b). Bernoulli-class variants (circles: random percolation, blue; density increment, green) cross $\alpha = 0.5$ sharply at $p_c' = 0.683$ and arrest rapidly ($\alpha \to 0$ within $\Delta p \approx 0.03$). Templated-class variants (squares: 6N, orange; 26N, purple) cross at $p_c' = 0.886$ ($\Delta p_c' = +0.20$, indicated by the double-headed arrow in panel a) and show persistent sub-diffusion ($\alpha \approx 0.3$–$0.4$) well above $p_c'$ (annotated in panel b). Vertical dashed lines indicate $p_c'$ for each class.

### 3.3 Continuous tuning via $\kappa$-mixing

Figure 4 shows $\alpha(p, \kappa)$ for all 18 values of $\kappa$, averaged over $N_s = 3$ replicates. The $\alpha = 0.5$ crossing shifts monotonically to higher $p$ as $\kappa$ increases from 0 (Bernoulli, dark) to 1 (single-seed Eden-like, light). Figure 5 shows the extracted gel-point curve $p_c'(\kappa)$.

$p_c'(\kappa)$ is monotonically increasing across the full parameter range, spanning $p_c' \in [0.683, 0.993]$ and a tunable range:

$$
\Delta p_c' = p_c'(\kappa=1) - p_c'(\kappa=0) \approx 0.31.
$$

The value at $\kappa = 1.00$ is extrapolated: the measured $\alpha$ at $p = 0.99$ is $0.521 > 0.5$, indicating $p_c' > 0.99$; a linear extrapolation from the three highest $p$ values gives $p_c'(\kappa=1) \approx 0.993$. The divergence of $p_c'$ toward unity as $\kappa \to 1$ is physically consistent with the single-seed Eden morphology in the thermodynamic limit, where a single compact cluster can in principle fill the lattice without fragmenting the void until $p \to 1$.

Two regimes are visible in Fig. 5b, which plots $p_c'$ against seed fraction $(1-\kappa)$ on a logarithmic scale:

1. *Bernoulli-like regime* ($\kappa \lesssim 0.99$, seed fraction $\gtrsim 1\%$): $p_c'$ increases gradually from 0.683 to $\approx 0.91$ as $\kappa$ increases. The occupied network is seeded densely enough that the morphology remains qualitatively similar to random percolation, with many small clusters that merge as $p$ increases.

2. *Eden regime* ($\kappa \gtrsim 0.99$, seed fraction $\lesssim 1\%$): $p_c'$ rises steeply from $\approx 0.91$ toward unity. With only one or a handful of seeds, the cluster grows as a compact, connected body; the void space remains open to walker diffusion until very high $p$.

The transition between regimes occurs near a seed fraction of $\sim 1\%$ of new sites per $p$-step (dashed line, Fig. 5b), corresponding to $\kappa \approx 0.99$.

**Figure 4** (`figures/fig1_alpha_vs_p.png`). **Continuously tunable $\alpha(p)$ via $\kappa$-mixing.** Ensemble-averaged $\alpha(p)$ for all 18 values of $\kappa$, coloured from $\kappa = 0$ (dark purple, Bernoulli) to $\kappa = 1$ (yellow, single-seed Eden-like). Shaded bands indicate $\pm 1$ standard deviation over $N_s = 3$ replicates. The $\alpha = 0.5$ crossing (dashed horizontal) shifts monotonically rightward with increasing $\kappa$. Panels: (a) full range $p \in [0, 1]$; (b) critical region $p \in [0.60, 1.00]$. Dotted vertical lines mark the gel-point $p_c'(\kappa)$ for each curve. Simulation parameters: $L = 500$, $N_W = 3000$, $L_W = 10^6$, $N_s = 3$.

**Figure 5** (`figures/fig2_gel_point_tunable.png`). **Tunable gel-point $p_c'(\kappa)$.** (a) Gel-point $p_c'$ as a function of nucleation-density parameter $\kappa$. Filled circles are gel-points extracted by linear interpolation of $\alpha(p)$ through 0.5; blue shading indicates the interpolation bracket width ($p$-grid resolution uncertainty). The starred symbol at $\kappa = 1.0$ denotes a linear extrapolation ($p_c' \approx 0.993$). Dotted horizontal lines mark the Bernoulli-class ($p_c' \approx 0.683$, blue) and templated-class ($p_c' \approx 0.886$, red) limiting values from the base-case study; the double-headed arrow marks the total tunable range $\Delta p_c' \approx 0.31$. (b) $p_c'$ versus seed fraction $(1-\kappa)$ on a logarithmic scale, revealing two physical regimes separated at $\sim 1\%$ seed fraction (dashed vertical line): a Bernoulli-like regime ($\kappa \lesssim 0.99$) with gradual increase, and an Eden regime ($\kappa \gtrsim 0.99$) with steep increase toward unity. Upper axis shows corresponding $\kappa$ values.

### 3.4 Frequency-domain characterisation via the GSER

To connect the simulation results to experimentally measurable rheology, MSD curves at and near $p_c'$ are converted to $G'(\omega)$, $G''(\omega)$, and $\delta(\omega)$ via the GSER (Eq. in Sec. 2.4). Since the MSD follows a power law $\langle r^2(t)\rangle \propto t^\alpha$ throughout the anomalous window $[L_W/100, L_W/10]$, the GSER yields power-law moduli $G', G'' \propto \omega^\alpha$ with a frequency-independent phase angle $\delta(\omega) = 90\alpha$. Figure 6 shows $G'(\omega)$, $G''(\omega)$, and $\delta(\omega)$ for representative $p$ values straddling $p_c'$ in each class.

At the gel-point ($p \approx p_c'$), both gelation classes exhibit $\delta \approx 45°$ and $G'(\omega) \approx G''(\omega)$ across the accessible frequency range ($\omega \approx 0.4$–$4\,\mathrm{rad\,s^{-1}}$), confirming the Winter–Chambon criterion. For $p < p_c'$ (sol state), $\delta > 45°$ and $G'' > G'$ at all frequencies, consistent with viscous-dominated response. For $p > p_c'$ (gel state), $\delta < 45°$ and $G' > G''$, consistent with elastic-dominated response.

The two gelation classes are distinguished in the frequency domain by the rate at which $\delta$ departs from $45°$ above the gel-point. For the Bernoulli class at $p = 0.700$ ($\Delta p = 0.017$ above $p_c'$), $\delta$ falls to $31°$, indicating near-complete elastic arrest. For the templated class at $p = 0.950$ ($\Delta p = 0.064$ above $p_c'$), $\delta$ remains at $33°$ — comparable elastic character reached only at a far larger distance from the gel-point. This slower departure is a direct frequency-domain signature of the persistent sub-diffusion ($\alpha \approx 0.3$–$0.4$) observed in the time domain above $p_c'$ for the templated class, and reflects the more open, tortuous void-channel structure maintained by compact cluster morphology.

**Figure 6** (`figures/fig5_gser.png`). **Frequency-domain GSER characterisation of both gelation classes.** *Top row:* Elastic modulus $G'(\omega)$ (thick) and loss modulus $G''(\omega)$ (thin, same colour) derived via the GSER for representative occupation densities $p$ in the Bernoulli class (a) and the Templated (6N) class (b). In both classes the gel-point condition ($p \approx p_c'$, solid curve) yields $G' \approx G''$ (annotated) across the accessible frequency range ($\omega \approx 0.4$–$4\,\mathrm{rad\,s^{-1}}$), confirming the Winter–Chambon criterion. Since the MSD follows a power law $\langle r^2(t)\rangle \propto t^\alpha$ throughout the anomalous window, moduli satisfy $G', G'' \propto \omega^\alpha$ and the phase angle $\delta = 90\alpha$ is frequency-independent. *Bottom panel (c):* Phase angle $\delta = 90\alpha$ plotted against $\Delta p = p - p_c'$, the distance from each class's own gel-point, so both curves are aligned at $\Delta p = 0$ regardless of their absolute $p_c'$ values. The Bernoulli class (blue circles) transitions sharply: $\delta$ reaches $22.5°$ at $\Delta p = 0.016$. The Templated class (brown squares) transitions $\approx 4\times$ more gradually: $\delta$ reaches $22.5°$ only at $\Delta p = 0.065$. At $\Delta p = 0.064$ the Bernoulli class is nearly fully arrested ($\delta \approx 1°$) while the Templated class retains $\delta \approx 23°$ — persistent sub-diffusion arising from open, tortuous void channels maintained by compact cluster morphology. Physical parameters: $T = 293\,\mathrm{K}$, $\eta = 1.2\times10^{-3}\,\mathrm{Pa\,s}$, probe radius $a = 0.243\,\mu\mathrm{m}$, gel mesh size $l = 10\,\mathrm{nm}$.

---

## 4. Discussion

### 4.1 Physical basis of $p_c' \approx 1 - p_c$

The result $p_c' \approx 1 - p_c$ is not an approximation or a numerical coincidence — it is a direct consequence of placing walkers in the void phase. The void sublattice of a 3D simple cubic lattice undergoes its own site-percolation transition: it is connected (spanning) when $p < 1 - p_c \approx 0.6884$ and fragmented when $p > 1 - p_c$. At $p = 1 - p_c$ exactly, the void phase is at its critical point — the system sits at the boundary between a connected, system-spanning fluid and a collection of finite isolated pockets. A random walker at this point experiences the critical-point MSD scaling $\langle r^2(t) \rangle \propto t^{0.5}$, which is precisely the Winter–Chambon criterion $\alpha = 0.5$.

The small offset ($p_c' = 0.683$ vs $1 - p_c = 0.6884$) is attributable to finite-size effects. At $L = 500$, the void percolation transition is sharp but shifted below the thermodynamic threshold; the observed offset of $\sim 0.005$ in $p$ is consistent with finite-size scaling corrections of order $L^{-1/\nu}$ with $\nu \approx 0.88$ for 3D percolation \citep{Ballesteros1999}.

This identification has a concrete implication for microrheology: the rheological gel-point of a random network-forming material is not an independently tunable parameter — it is fixed at $p_c' = 1 - p_c$ by the geometry of the lattice and the constraint that walkers are in the void. Changing the gel-point therefore requires changing the network morphology.

### 4.2 Why templated growth shifts the gel-point

In the templated class, the occupied cluster grows as a connected, compact body. At any given density $p$, a compact connected cluster occupies a more localised region of space than the same number of randomly placed sites, leaving a correspondingly larger and more interconnected void region. The void sublattice therefore loses its percolation connectivity only at a higher occupied fraction $p$, shifting $p_c'$ from 0.683 to 0.886.

The persistent sub-diffusion above $p_c'$ ($\alpha \approx 0.3$–$0.4$ at $p = 0.95$) supports this interpretation: even well above the gel-point, walkers in the templated system are not fully arrested because the void channels, though disconnected on the largest scales, remain locally open and tortuous. This is qualitatively different from the random case, where the void fragments into small, isolated pockets above $p_c'$ and walkers become immediately localised.

The near-identity of the 6N and 26N gel-points ($|\Delta p_c'| = 0.0005$) demonstrates that the connectivity constraint is the key physical ingredient, not the details of how adjacency is defined. This robustness is encouraging for physical realisability: any growth mechanism that enforces cluster connectivity is expected to produce a similar shift.

### 4.3 $\kappa$ as a material design parameter

The nucleation-density parameter $\kappa$ has a direct physical interpretation: it controls the number of independent nucleation centres per unit increase in network density. In real polymer systems, analogous parameters include the concentration of cross-linking agents (which act as nucleation centres for gel formation), the temperature ramp rate (which controls nucleation density in thermoreversible gels), and the ionic strength (which tunes the Debye screening length and hence the range of attractive interactions governing cluster growth). Systems with high nucleation density (many small growing clusters, low $\kappa$) are predicted to gel at lower $p$, while systems that grow from a small number of nuclei (high $\kappa$) are predicted to gel at much higher $p$.

The steep rise in $p_c'(\kappa)$ near $\kappa \approx 0.99$ (the Eden regime, Fig. 5b) suggests that small changes in nucleation density at very low seed fractions can produce large shifts in the gel-point. This regime may be experimentally accessible in systems where gelation initiates from a small number of heterogeneous nucleation sites, such as mineral impurities or deliberately introduced seed particles.

### 4.4 Relation to Eden and diffusion-limited aggregation models

At $\kappa = 1$, the growth model is equivalent to Eden growth \citep{Eden1961}: a single seed expands by randomly adding adjacent frontier sites at each step. Eden clusters in 3D are compact, roughly spherical, and have a fractal dimension approaching 3 at long times \citep{Jullien1985}. The predicted $p_c' \to 1$ as $L \to \infty$ for $\kappa = 1$ is consistent with this: a single compact Eden cluster can in principle fill the lattice entirely before fragmenting the void, so the gel-point in the thermodynamic limit approaches $p = 1$. The finite-size extrapolation gives $p_c'(\kappa=1) \approx 0.993$ at $L = 500$, confirming that even at this scale the void channels persist to very high density.

### 4.5 Limitations and future work

Several limitations warrant acknowledgement. First, all results are for a single lattice size $L = 500$; finite-size scaling analysis over a range of $L$ would be needed to extract critical exponents and confirm whether the templated and Bernoulli classes belong to different universality classes in the strict statistical-mechanics sense. Our data are consistent with different universality classes (different transition widths and critical behaviours) but the evidence is currently phenomenological. Second, the GSER frequency-domain spectra (Sec. 3.4) are based on a single-replica analysis per condition; replication at the same level as the structural data would strengthen the modulus estimates. Third, the $\kappa = 1$ gel-point is extrapolated rather than directly measured, and would benefit from a dedicated simulation at $p \in [0.99, 1.00]$.

Future work will address finite-size scaling to characterise the critical exponents of both classes, extend the $\kappa$-mixing framework to 2D lattices and off-lattice systems, and explore connections between $\kappa$ and experimentally controllable nucleation parameters in physical gel-forming systems.

---

## 5. Conclusions

We have demonstrated through systematic three-dimensional random walk simulations that the viscoelastic gel-point of a percolating network is not a fixed property of occupation density — it is determined by the growth dynamics of the forming cluster, and can be continuously programmed via a single nucleation-density parameter.

Three main results are established. First, for random (Bernoulli) percolation networks, the Winter–Chambon gel criterion ($\alpha = 0.5$) is satisfied at $p_c' \approx 1 - p_c \approx 0.683$, quantitatively identifying the rheological gel-point with the loss of spanning connectivity in the void phase. This is the natural gel-point baseline for any network-forming material that grows without spatial correlation.

Second, replacing random growth with adjacency-constrained (templated) cluster growth shifts the gel-point by $\Delta p_c' = +0.20$ to $p_c' \approx 0.886$, and changes the character of the transition: the critical region is 3.4-times broader and probe particles remain persistently sub-diffusive above the gel-point — a morphological signature of the more open, connected void channels maintained by compact cluster growth.

Third, a nucleation-density parameter $\kappa$ provides continuous, monotonic interpolation between the Bernoulli and templated limits, spanning a total tunable range $\Delta p_c' \approx 0.31$ ($p_c' \in [0.683, 0.993]$). The $\kappa$ parameter maps directly onto the fraction of growing sites that originate as independent nuclei, providing a physically motivated handle that may be realised experimentally through nucleation site density, cross-linker concentration, or thermal ramp rate.

Frequency-domain viscoelastic spectra derived via the GSER confirm the $\delta(\omega) = 45°$ Winter–Chambon signature at $p_c'$ for both gelation classes, establishing a direct bridge from simulation to measurable microrheology.

Together these results provide a conceptual and quantitative framework for programming viscoelastic gel-points in network-forming materials through control of cluster growth dynamics rather than chemical composition alone.

---

## Acknowledgments

[To be completed.]

---

## References

*Citations appear inline as `\citep{...}` keys, resolving against `references_enhanced.bib` at compile time. The list below is reconstructed from the citation keys used in the text; entries marked **[verify]** should be checked against `references_enhanced.bib`, which I could not read while the machine link was offline.*

1. **[Winter1987]** Winter, H. H. & Chambon, F. Analysis of linear viscoelasticity of a crosslinking polymer at the gel point. *J. Rheol.* **30**, 367–382 (1986). **[verify year/key]**
2. **[Chambon1987]** Chambon, F. & Winter, H. H. Linear viscoelasticity at the gel point of a crosslinking PDMS with imbalanced stoichiometry. *J. Rheol.* **31**, 683–697 (1987).
3. **[Mason1995]** Mason, T. G. & Weitz, D. A. Optical measurements of frequency-dependent linear viscoelastic moduli of complex fluids. *Phys. Rev. Lett.* **74**, 1250–1253 (1995).
4. **[Mason2000]** Mason, T. G. Estimating the viscoelastic moduli of complex fluids using the generalized Stokes–Einstein equation. *Rheol. Acta* **39**, 371–378 (2000).
5. **[Squires2010]** Squires, T. M. & Mason, T. G. Fluid mechanics of microrheology. *Annu. Rev. Fluid Mech.* **42**, 413–438 (2010).
6. **[Rubinstein2003]** Rubinstein, M. & Colby, R. H. *Polymer Physics* (Oxford Univ. Press, 2003).
7. **[Larson1999]** Larson, R. G. *The Structure and Rheology of Complex Fluids* (Oxford Univ. Press, 1999).
8. **[Trappe2001]** Trappe, V., Prasad, V., Cipelletti, L., Segre, P. N. & Weitz, D. A. Jamming phase diagram for attractive particles. *Nature* **411**, 772–775 (2001).
9. **[Gibaud2012]** Gibaud, T. *et al.* Rheological and structural signatures of colloidal gels. *Soft Matter* (2012). **[verify]**
10. **[Ng2016]** Ng, T. S. K. *et al.* Microrheology of network-forming colloidal systems (2016). **[verify]**
11. **[deBruyn2013]** de Bruyn, J. R. *et al.* Microrheology of gelling systems. (2013). **[verify]**
12. **[Rich2011]** Rich, J. P., McKinley, G. H. & Doyle, P. S. Size dependence of microprobe dynamics during gelation of a discotic colloidal clay. *J. Rheol.* **55**, 273–299 (2011).
13. **[Oppong2006]** Oppong, F. K., Rubatat, L., Frisken, B. J., Bailey, A. E. & de Bruyn, J. R. Microrheology and structure of a yield-stress polymer gel. *Phys. Rev. E* **73**, 041405 (2006).
14. **[Muthukumar1989]** Muthukumar, M. Screening effect on viscoelasticity near the gel point. *Macromolecules* **22**, 4656–4658 (1989).
15. **[Eden1961]** Eden, M. A two-dimensional growth process. In *Proc. 4th Berkeley Symp. Math. Statist. Prob.* **4**, 223–239 (Univ. California Press, 1961).
16. **[Jullien1985]** Jullien, R. & Botet, R. Scaling properties of the surface of the Eden model in $d = 2, 3, 4$. *J. Phys. A: Math. Gen.* **18**, 2279–2287 (1985).
17. **[Ballesteros1999]** Ballesteros, H. G. *et al.* Scaling corrections: site percolation and Ising model in three dimensions. *J. Phys. A: Math. Gen.* **32**, 1–13 (1999).

---

# Appendices

## Appendix A. Mathematical Framework

### A.1 The Winter–Chambon criterion in the random-walk model

At the gel-point, the Winter–Chambon criterion requires that the loss tangent be frequency-independent and equal to unity, $\tan\delta = G''/G' = 1$, i.e. a phase angle $\delta = 45°$ \citep{Winter1987,Chambon1987}. For a probe undergoing power-law anomalous diffusion, $\langle r^2(t)\rangle \propto t^{\alpha}$, the GSER (Section A.4) maps this directly onto the diffusion exponent. Writing the moduli that follow from a power-law MSD (Section A.4),

$$
\delta(\omega) = \frac{\pi}{2}\,\alpha \quad\Longleftrightarrow\quad \delta(°) = 90\,\alpha ,
$$

so that the gel condition $\delta = 45°$ is exactly equivalent to $\alpha = 0.5$. This is the operational criterion used throughout: the gel-point $p_c'$ is the occupation probability at which the anomalous diffusion exponent of void-phase walkers passes through $1/2$.

### A.2 Sigmoid model of the transition and its width

The empirical dependence of the diffusion exponent on occupation probability is well described by a sigmoid,

$$
\alpha(p) = \alpha_{\min} + \frac{\alpha_{\max} - \alpha_{\min}}{1 + \exp\!\left(\dfrac{p - p_c'}{w}\right)},
$$

where $\alpha_{\min}$ and $\alpha_{\max}$ bound the exponent, $p_c'$ is the inflection (gel) point, and $w \equiv \sigma_\mathrm{sigmoid}$ sets the transition width. Fits are performed by non-linear least squares (Levenberg–Marquardt). The width parameter is the primary quantitative discriminator between the two gelation classes:

| Class | $\sigma_\mathrm{sigmoid}$ | Critical-region width $\Delta p$ |
|---|---|---|
| Bernoulli (random) | $\approx 0.015$ | $\approx 0.03$ |
| Templated (6N/26N) | $\approx 0.052$ | $\approx 0.10$ |

The templated transition is thus a factor of $\approx 3.4$ broader. For the templated class the sigmoid is fitted with a padding constraint $\alpha(p=1) = 0$, because probe motion must vanish in the fully occupied lattice; without this constraint the bare fit is poorly conditioned in the tail (this padding raises the fit $R^2$ substantially and does not move $p_c'$). We report only the transition width and gel-point from these fits; we deliberately do **not** extract critical exponents ($\beta, \gamma, \nu$) from single-size ($L = 500$) data, since a defensible estimate requires finite-size scaling across a range of $L$ (see Section 4.5 and Appendix B.3).

### A.3 Gel-point extraction by interpolation

Rather than relying on the sigmoid fit for the central value, the gel-point is located directly by linear interpolation of the measured $\alpha(p)$ through $0.5$:

$$
p_c' = p_i + \frac{0.5 - \alpha(p_i)}{\alpha(p_{i+1}) - \alpha(p_i)}\,(p_{i+1} - p_i),
\qquad \alpha(p_i) > 0.5 > \alpha(p_{i+1}).
$$

The uncertainty in $p_c'$ from this procedure is bounded by the $p$-grid spacing of the bracketing points (typically $\Delta p = 0.005$–$0.01$ in the critical region); this bracket width is shown as shading in Fig. 5a.

### A.4 The Generalised Stokes–Einstein Relation

MSD data are converted to a complex shear modulus using the GSER in the Mason form \citep{Mason1995,Mason2000}:

$$
G^*(\omega) \approx \frac{k_B T}{\pi a\, \langle r^2(1/\omega)\rangle\, \Gamma\!\left(1 + \alpha(\omega)\right)},
$$

where $a$ is the probe radius, $k_B T$ the thermal energy, $\Gamma$ the gamma function, and $\alpha(\omega) = \mathrm{d}\ln\langle r^2(t)\rangle / \mathrm{d}\ln t$ evaluated at lag $t = 1/\omega$ is the local logarithmic slope of the MSD. The storage and loss moduli follow as

$$
G'(\omega) = |G^*(\omega)|\cos\!\big(\delta(\omega)\big), \qquad
G''(\omega) = |G^*(\omega)|\sin\!\big(\delta(\omega)\big),
\qquad
\delta(\omega) = \frac{\pi}{2}\,\alpha(\omega).
$$

When the MSD is a pure power law, $\langle r^2(t)\rangle \propto t^{\alpha}$ with constant $\alpha$, the modulus magnitude scales as $|G^*(\omega)| \propto \omega^{\alpha}$ and the phase angle $\delta = 90\alpha$ is frequency-independent — recovering the exact Winter–Chambon signature at $\alpha = 0.5$ ($\delta = 45°$, $G' = G''$). Physical constants used for the dimensional spectra: $T = 293\,\mathrm{K}$, solvent viscosity $\eta = 1.2\times10^{-3}\,\mathrm{Pa\,s}$, probe radius $a = 0.243\,\mu\mathrm{m}$.

---

## Appendix B. Void-Phase Percolation and the Identity $p_c' \approx 1 - p_c$

### B.1 Complementary percolation of the void sublattice

Probe walkers occupy the *void* (unoccupied) sublattice. On a 3D simple cubic lattice, the void sublattice at occupied fraction $p$ is itself a site-percolation problem with occupation probability $1 - p$ for the void phase. The void phase spans the system when its occupation exceeds the site threshold, $1 - p > p_c$, i.e. when

$$
p < 1 - p_c, \qquad p_c = 0.3116 \;(\text{3D simple cubic}),
$$

and fragments into finite, disconnected pockets when $p > 1 - p_c$. The boundary $p = 1 - p_c \approx 0.6884$ is therefore the point at which system-spanning fluid transport is lost.

### B.2 Why the transition point gives $\alpha = 0.5$

Exactly at the void-phase percolation threshold, a walker explores an incipient percolation cluster whose long-time transport is anomalous. In the random (Bernoulli) class we observe $\langle r^2(t)\rangle \propto t^{0.5}$ at $p = p_c'$, which is precisely the Winter–Chambon gel criterion. The rheological gel-point is thus identified with a geometric phase transition of the void phase, and the numerical result $p_c'(\text{random}) = 0.6832$–$0.6834$ sits just below the thermodynamic value $1 - p_c = 0.6884$.

### B.3 The finite-size offset

The measured offset $\delta p = (1 - p_c) - p_c' \approx 0.0052$ at $L = 500$ is consistent with a finite-size shift of the percolation threshold. Percolation thresholds on finite lattices are displaced from their thermodynamic value by a correction that scales as

$$
p_c(L) - p_c(\infty) \sim A\, L^{-1/\nu},
$$

with $\nu \approx 0.88$ for 3D percolation \citep{Ballesteros1999}. A single lattice size cannot separate the amplitude $A$ from $\nu$, so we report the offset as consistent with finite-size scaling rather than as a measured exponent. A dedicated finite-size scaling study across several $L$ (e.g. $L = 100, 200, 300, 500, 750$) would allow $p_c'(\infty)$ and the correction exponent to be extracted, and is identified as future work (Section 4.5).

---

## Appendix C. Detailed $\kappa$-Mixing Results

### C.1 Gel-point as a function of nucleation density

The gel-point $p_c'(\kappa)$ increases monotonically with $\kappa$ across the full range. The anchor values established by the study are:

| Regime | $\kappa$ | $p_c'$ | Source |
|---|---|---|---|
| Bernoulli limit | $0.00$ | $0.683$ | direct interpolation (base case) |
| Bernoulli-like regime upper end | $\lesssim 0.99$ | $\to \approx 0.91$ | direct interpolation |
| Multi-seed templated (6N/26N) | — | $0.886$ | base-case study |
| Eden regime | $\gtrsim 0.99$ | $0.91 \to 1$ | direct interpolation |
| Single-seed Eden limit | $1.00$ | $\approx 0.993$ | **linear extrapolation** ($\alpha(p{=}0.99) = 0.521 > 0.5$) |

The total tunable range is $\Delta p_c' = p_c'(\kappa{=}1) - p_c'(\kappa{=}0) \approx 0.31$, i.e. $p_c' \in [0.683, 0.993]$.

> **Note.** The complete per-$\kappa$ gel-point values for all 18 studied $\kappa \in \{0.00, 0.20, 0.40, 0.60, 0.70, 0.80, 0.85, 0.88, 0.91, 0.94, 0.97, 0.98, 0.99, 0.995, 0.996, 0.997, 0.998, 1.00\}$ are stored in the tunable-gel-point results dataset (`tunable_gel_point_results.mat` / `paper_figures/`). This table should be expanded to one row per $\kappa$ (with interpolation-bracket uncertainties) directly from that file before submission; the anchor values above are the ones quoted in the main text.

### C.2 Two regimes

Plotting $p_c'$ against the seed fraction $(1-\kappa)$ on a logarithmic axis (Fig. 5b) reveals two regimes separated at a seed fraction of $\sim 1\%$ ($\kappa \approx 0.99$):

- **Bernoulli-like regime** ($\kappa \lesssim 0.99$): many independent nuclei per $p$-step; morphology resembles random percolation; $p_c'$ rises gradually from $0.683$ to $\approx 0.91$.
- **Eden regime** ($\kappa \gtrsim 0.99$): one or a few persistent nuclei; growth is compact and connected; $p_c'$ rises steeply toward unity.

### C.3 Replication

Each $(\kappa, p)$ condition in the mixing study was run with $N_s = 3$ independent replicates ($N_W = 3000$ walkers, $L_W = 10^6$ steps each) and averaged before interpolation. The $\pm 1$ standard-deviation bands on $\alpha(p,\kappa)$ are shown as shading in Fig. 4.

---

## Appendix D. Frequency-Domain Conversion Details

### D.1 Procedure

For each occupation density $p$ of interest, the ensemble MSD $\langle r^2(t)\rangle$ is (i) restricted to the anomalous window $[L_W/100, L_W/10]$; (ii) fitted locally to obtain $\alpha(\omega)$ as the logarithmic slope at $t = 1/\omega$; and (iii) inserted into the GSER (Appendix A.4) to yield $G^*(\omega)$, from which $G'$, $G''$ and $\delta$ follow. Because the MSD is close to a single power law over this window, the derived spectra are effectively power laws with frequency-independent $\delta = 90\alpha$.

### D.2 Accessible frequency range and parameters

The accessible angular-frequency range corresponding to the anomalous lag-time window is $\omega \approx 0.4$–$4\ \mathrm{rad\,s^{-1}}$. Physical parameters: $T = 293\,\mathrm{K}$, $\eta = 1.2\times10^{-3}\,\mathrm{Pa\,s}$, probe radius $a = 0.243\,\mu\mathrm{m}$, and (for dimensional MSD scaling) a gel mesh size $l = 10\,\mathrm{nm}$.

### D.3 Class discrimination in the frequency domain

The two classes are distinguished by how quickly $\delta$ departs from $45°$ above the gel-point. Aligning each class at its own $p_c'$ (i.e. plotting against $\Delta p = p - p_c'$):

| Class | $\Delta p$ at which $\delta = 22.5°$ | $\delta$ at $\Delta p = 0.064$ |
|---|---|---|
| Bernoulli | $\approx 0.016$ | $\approx 1°$ (arrested) |
| Templated (6N) | $\approx 0.065$ | $\approx 23°$ (still sub-diffusive) |

This $\approx 4\times$ slower elastic onset is the frequency-domain counterpart of the persistent time-domain sub-diffusion ($\alpha \approx 0.3$–$0.4$) of the templated class.

> **Caveat (see Section 4.5).** The GSER spectra are currently based on a single replica per condition; replicating them at the $N_s = 3$ level used for the structural data would tighten the modulus estimates.

---

## Appendix E. Computational Implementation

### E.1 Lattice generation

Lattices are generated cumulatively over the $p$-sweep so that the occupied set at higher $p$ is a strict superset of that at lower $p$, mirroring progressive gelation. At each $p$-step the number of new sites is $N_\mathrm{new} = \lfloor pL^3\rceil - \lfloor p_\mathrm{prev}L^3\rceil$. The three growth rules differ only in how these $N_\mathrm{new}$ sites are placed:

- **Random / density-increment:** sites drawn uniformly from the remaining void.
- **Templated (6N / 26N):** sites drawn from the adjacency frontier of the current occupied set.
- **$\kappa$-mixing:** $N_\mathrm{seeds} = \lfloor (1-\kappa)N_\mathrm{new}\rceil$ placed uniformly at random, the remainder grown by 6N adjacency from the combined frontier. Connectivity is guaranteed by construction.

### E.2 Random-walk engine and online MSD

Walkers are initialised on void sites and take nearest-neighbour steps with a Gaussian wait-time penalty on blocked moves ($\mu_\mathrm{WT} = 20$, $\sigma_\mathrm{WT} = 5$ steps). Both wrapped coordinates (for neighbour lookup under periodic boundaries, $x_n = \mathrm{mod}(x_n - 1, L) + 1$) and unwrapped coordinates (for MSD) are tracked. The ensemble MSD is accumulated **online** by parallel reduction across walkers, avoiding storage of the full $O(L_W N_W)$ trajectory array (which would be $\sim$36 GB at production scale, $N_W = 3000$, $L_W = 10^6$).

### E.3 Environment and scale

Simulations were implemented in MATLAB (R2025a) with `parfor` parallelisation over walkers. Production runs used $L = 500$, $N_W = 3000$, $L_W = 10^6$, with $N_s = 3$ replicates for the $\kappa$-mixing study (1890 total $(p, \kappa, s)$ conditions) and $N_s = 1$ for the base-case class comparison (216 conditions). Reproducibility is supported by fixed random seeds per condition and version-controlled analysis scripts.

### E.4 Analysis pipeline

Per-condition MSD curves are post-processed by: (i) power-law fitting on the intermediate window to obtain $\alpha(p)$; (ii) interpolation of $\alpha(p)$ through $0.5$ to locate $p_c'$ (Appendix A.3); (iii) sigmoid fitting for the transition width (Appendix A.2); and (iv) GSER conversion for the frequency-domain spectra (Appendix D). Figure-generation scripts consume the resulting summary tables (`*_results.csv`) and the tunable-gel-point dataset.

---

*End of draft.*
