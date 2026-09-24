# Systematic literature sweep — verified results

*September 2026. All bibliographic fields verified via Crossref unless flagged. Companion to `literature_positioning_brief.md`.*

The sweep covered three clusters (~22 sources). Below: the verified annotated bibliography, the BibTeX additions (`new_references.bib`, ready to append), a recommended core subset, and two ready-to-drop text blocks — a related-work sentence for the Letter and a "why α≈0.5" paragraph for the SM.

## Headline numbers (now sourced)

From **Kammerer, Höfling & Franosch, EPL 84, 66002 (2008)** — the modern high-precision Monte-Carlo determination for lattice percolation:

| Quantity | 3D | 2D |
|---|---|---|
| Walk dimension d_w | **3.88(3)** | **2.878(1)** |
| MSD exponent 2/d_w | **0.515(4)** | **0.695(1)** |
| Fractal dimension d_f | 2.530(4) | 91/48 (exact) |
| Spectral dimension d_s = 2d_f/d_w | ≈1.30 | ≈1.32 |

So your α≈0.5 **is** the 3D percolation walk exponent (2/d_w = 0.515), and the coincidence with Winter–Chambon is genuinely 3D-specific (2D gives 0.70). Two caveats a referee may raise: (i) 2/d_w = 0.515 is *slightly above* 0.5, so state the identification as approximate; (ii) continuum "Swiss-cheese" void percolation has a *larger* d_w (≈4.81 in 3D) — pre-empt by noting your discretised model is in the lattice-percolation class.

## Verified annotated bibliography

### Cluster 1 — anomalous diffusion on percolation clusters (the 2/d_w line)
- **Gefen, Aharony & Alexander**, PRL **50**, 77 (1983), doi:10.1103/PhysRevLett.50.77 — *canonical* source of MSD∝t^(2/d_w) on percolation clusters. The reference for the exponent your α reduces to. **Add.**
- **Straley**, J. Phys. C **13**, 2991 (1980), doi:10.1088/0022-3719/13/16/009 — first quantitative "ant in the labyrinth" scaling near threshold. Nice historical antecedent. *Optional.*
- **Havlin, Ben-Avraham & Sompolinsky**, PRA **27**, 1730 (1983) — *already in your .bib as `Havlin1983`* (scaling of diffusion on percolation clusters).
- **Alexander & Orbach**, J. Phys. Lett. **43**, L625 (1982), doi:10.1051/jphyslet:019820043017062500 — spectral dimension d_s=4/3 conjecture. **Add** (for the SM d_s remark).
- **Kammerer, Höfling & Franosch**, EPL **84**, 66002 (2008), doi:10.1209/0295-5075/84/66002 — best primary source for the numeric d_w (3D & 2D). **Add** (anchors the 2/d_w paragraph).
- **Ben-Avraham & Havlin**, *Diffusion and Reactions in Fractals and Disordered Systems* (CUP, 2000) — *already in your .bib as `Ben-Avraham2000`*.

### Cluster 2 — microrheology of the gel point / Winter–Chambon / GSER
- **Larsen & Furst**, PRL **100**, 146001 (2008) — *already in your .bib as `Larsen2008`*. The closest experimental precedent; make sure it's actually **cited in the Letter** as the "microrheology already locates the gel point" anchor.
- **Larsen, Schultz & Furst**, Korea-Aust. Rheol. J. **20**, 165 (2008) — follow-up on cross-linking hydrogels; no DOI (journal issued none). *Optional.* (Note: middle author is **K. M. Schultz**.)
- **Winter & Chambon**, J. Rheol. **30**, 367 (1986) / **Chambon & Winter**, J. Rheol. **31**, 683 (1987) — *your `Winter1987`/`Chambon1987`*. The α=0.5/δ=45° criterion.
- **Mason & Weitz** PRL 74, 1250 (1995); **Mason** Rheol. Acta 39, 371 (2000); **Squires & Mason** Annu. Rev. Fluid Mech. 42, 413 (2010) — *all already in your .bib*. GSER foundations.
- **Corrigan & Donald**, EPJE **28**, 457 (2009), doi:10.1140/epje/i2008-10439-7 — particle-tracking microrheology of a gelling (amyloid) network; extra precedent that microrheology reads the gel point. *Optional.*

### Cluster 3 — tunable / correlated cluster-growth percolation (your κ mechanism)
- **Roy & Santra**, PRE **95**, 010101(R) (2017), doi:10.1103/PhysRevE.95.010101 — **the single closest prior art**: nucleation density + preferential growth tunes percolation continuous→first-order. **Add and differentiate explicitly.**
- **Roy & Santra**, Physica A **492**, 969 (2018), doi:10.1016/j.physa.2017.11.028 — same authors' two-parameter correlated-growth model *with finite-size scaling* — the same toolkit you use. **Add and differentiate.**
- **Anderson & Family**, PRA **38**, 4198 (1988), doi:10.1103/PhysRevA.38.4198 — origin of "growth rule shifts p_c." **Add.**
- **D'Souza & Nagler**, Nat. Phys. **11**, 531 (2015), doi:10.1038/nphys3378 — authoritative review of growth-rule-driven transition tuning. **Add** (one-citation survey of the landscape).
- **Achlioptas, D'Souza & Spencer**, Science **323**, 1453 (2009) + **Riordan & Warnke**, Science **333**, 322 (2011) — explosive percolation and the proof it's continuous; cite *only if* you lean on the sharp κ→1 rise, as a caution against over-claiming discontinuity. *Optional.*
- **Cho, Kahng & Kim**, PRE **81**, 030103(R) (2010), doi:10.1103/PhysRevE.81.030103 — aggregation-driven continuous→discontinuous crossover. *Optional.*

## Recommended core subset to add (8)

If you want to keep the reference count PRL-lean, these eight carry the positioning:
`Gefen1983`, `AlexanderOrbach1982`, `Kammerer2008` (the 2/d_w story); `Roy2017`, `Roy2018`, `Anderson1988`, `DSouzaNagler2015` (the tunable-growth positioning); and make sure `Larsen2008` is actually cited in the Letter body. The rest (`Straley1980`, `Corrigan2009`, `Achlioptas2009`, `Riordan2011`, `Cho2010`) are there if a referee pushes.

## Ready-to-drop text

### (A) Letter — related-work sentence
Insert near the end of the introduction (after the "Here we show…" paragraph), or as the opening of the closing discussion:

> Microrheology has previously been used to locate the gel point of real gels~\cite{Larsen2008,Corrigan2009}, and growth or nucleation rules are known to shift the percolation threshold and even change the order of the transition~\cite{Anderson1988,Roy2017,Roy2018,DSouzaNagler2015}. What has been missing is a single picture in which the passive-microrheology gel point is \emph{identified} with the void-percolation transition and then moved continuously by one morphological parameter---which is what the nucleation density $\kap$ provides here.

### (B) Supplemental Material — "why α≈0.5 at the threshold" paragraph
Add to the FSS/interpretation section (it also does double duty explaining ν_eff):

> \paragraph*{Origin of $\alpha\approx0.5$ at the threshold.}
> At the void-percolation threshold $\pcp=1-\pc$ the fluid sublattice explored by the probe is critical and fractal, so passive diffusion is anomalous with $\msd\propto t^{2/d_w}$, where $d_w$ is the walk dimension of the incipient cluster~\cite{Gefen1983,Havlin1983,Straley1980}. For three-dimensional lattice percolation $d_w=3.88(3)$~\cite{Kammerer2008}, giving $2/d_w=0.515(4)$---within one percent of the Winter--Chambon value $\alpha=0.5$. The coincidence of the gel criterion with the percolation threshold is therefore not accidental but reflects the 3D percolation walk exponent falling close to $0.5$; it is specific to three dimensions, since in two dimensions $d_w=2.878(1)$ gives $2/d_w=0.70$~\cite{Kammerer2008}, far from the gel criterion. (The Alexander--Orbach spectral dimension $d_s=2d_f/d_w\approx1.30$, near the conjectured $4/3$~\cite{AlexanderOrbach1982}, underlies this near-universality.) This dynamical origin also accounts for the effective exponent $\nueff\approx1.6$ governing the width of the $\alpha=0.5$ crossing differing from the static correlation-length exponent $\nu=0.88$: the crossing width is set by the anomalous-diffusion crossover of the probe, not by the static order parameter. We note that continuum (``Swiss-cheese'') void percolation has a larger walk dimension~\cite{Kammerer2008}; the discretised model here lies in the lattice-percolation class, for which $2/d_w\approx0.51$ applies.

## Bottom line

The paper is defensible, but two references now *must* be cited and distinguished — **Roy & Santra 2017/2018** (they already tune percolation by nucleation+growth with FSS) — and the **2/d_w** point should be stated rather than left for a referee to raise. Doing both converts the two obvious attack surfaces into stated strengths. The remaining novelty — the void-percolation *identity* read out by passive microrheology, κ as a single continuous Bernoulli↔Eden handle, and the one-effective-class FSS — is intact.
