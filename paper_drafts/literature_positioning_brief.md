# Literature positioning — nucleation-density gel-point paper

*Preliminary sweep, September 2026. For co-author circulation. Citations marked **[verify]** need the exact volume/page confirmed before they go in the .bib.*

## Verdict

Yes — worth it, and arguably essential before the co-authors weigh in. For a PRL the first referee reflex will be *"what is new here versus the large literature on diffusion in percolation and on microrheology of gelation?"* The sweep turns up two things the manuscript should get ahead of: one **technical** (the α ≈ 0.5 ↔ percolation coincidence is a known walk-dimension result, and it is specific to 3D), one **positioning** (tuning a percolation threshold by nucleation + growth is an existing model class). Neither sinks the paper; both are answerable, and owning them makes the paper stronger.

## The landscape — five clusters of prior work

**1. Anomalous diffusion on / in percolation clusters.** The foundational body. A random walker on a percolation cluster has MSD ∝ t^(2/d_w) with d_w the *walk dimension*; at threshold this is the canonical anomalous-diffusion result. This is exactly where your α(p) curve and its value at the threshold live. Key entry point: Gefen, Aharony & Alexander, *Anomalous Diffusion on Percolating Clusters*, PRL **50**, 77 (1983); reviews by Havlin & Ben-Avraham (*Diffusion in disordered media*).

**2. Microrheology of the gel point (experiment).** Larsen & Furst, *Microrheology of the Liquid–Solid Transition during Gelation*, PRL **100**, 146001 (2008), and the follow-up *Hydrogel microrheology near the liquid–solid transition* (Larsen, Schultz, Furst). They locate the gel point by particle-tracking microrheology and a critical relaxation exponent / time–cure superposition. This is the closest *microrheology-finds-the-gel-point* precedent and will be cited at you.

**3. The Winter–Chambon critical gel.** Winter & Chambon (1986/87); Muthukumar (1989). The α = 0.5 / δ = 45° criterion itself — already in your bibliography.

**4. Void / continuum percolation and the 1−p_c threshold.** The complementary (void-phase) percolation threshold and tracer diffusion through void/pore space. Supports your p_c′ = 1 − p_c identity; there is an established void-percolation-threshold literature to anchor it.

**5. Tunable percolation by correlated / cluster growth.** This is where your κ mechanism sits. Closest: *First-order transition in a percolation model with nucleation and preferential growth*, PRE **95**, 010101(R) (2017) — a nucleation density plus a size-dependent growth amplitude drives percolation from continuous to first-order/compact. Also *Percolation in an interactive cluster-growth model*, PRA **38**, 4198 (1988); a two-parameter "constant and correlated growth" percolation FSS study (Physica A, 2017); and the explosive-percolation literature.

## The closest precedents — what a referee will hold up

| Precedent | What it did | Your differentiator |
|---|---|---|
| **Larsen & Furst, PRL 100, 146001 (2008)** | Microrheology already *locates* the gel point in real gels via the critical relaxation exponent | You do it in a lattice simulation, tie the point to the **void-percolation identity** p_c′ = 1−p_c, and make it **continuously tunable** by κ — not just measuring n |
| **PRE 95, 010101(R) (2017)** — nucleation + preferential growth | A nucleation density + growth rule already **tunes** percolation and drives continuous → first-order | Your κ→1 Eden bound is essentially their compact/first-order limit. Your novelty is the **rheological read-out and gel-point framing**, not the tunability per se |
| **Gefen–Aharony–Alexander, PRL 50, 77 (1983)** | α at threshold *is* 2/d_w — the anomalous-diffusion exponent on the incipient cluster | See the technical point below — this is the one to own directly |

## The technical point you must own

At the void-percolation threshold p = 1 − p_c, the probe is diffusing on the incipient void cluster, so its MSD exponent is the **known** 2/d_w, not a free rheological quantity.

- In **3D**, d_w ≈ 3.8 (Alexander–Orbach spectral dimension d_s ≈ 4/3, fractal dimension d_f ≈ 2.52 → d_w = 2 d_f / d_s ≈ 3.8), giving **2/d_w ≈ 0.53 ≈ 0.5**.
- In **2D**, d_w ≈ 2.87 → **2/d_w ≈ 0.70 ≠ 0.5**.

So α ≈ 0.5 landing on the Winter–Chambon criterion **exactly at the percolation threshold is, to a large extent, a 3D-specific numerical coincidence** between 2/d_w and 0.5 — it is *not* a dimension-independent identity, and it would fail in 2D. A referee who knows the percolation-diffusion literature will raise this; better to state it first.

**Two consequences, both usable:**

1. **Reframe it as physical grounding, not numerology.** Present p_c′ = 1 − p_c as the geometric identity (loss of void spanning), and α ≈ 0.5 as *the 3D value of 2/d_w*, which happens to coincide with the Winter–Chambon criterion in three dimensions. Stating the dimension dependence explicitly turns a likely criticism into a controlled, physically-motivated feature — and it is genuinely interesting that the gel criterion and the 3D walk dimension line up.

2. **It explains your ν_eff ≈ 1.6 ≠ 0.88.** The width over which α crosses 0.5 is set by the *dynamic* (walk-dimension) crossover of the diffusion, not the static correlation length ξ — consistent with your "dynamically-defined threshold" argument, and the reason ν_eff differs from the static ν = 0.88. A referee *will* ask "what is 1.6?"; connecting it to d_w / the anomalous-diffusion finite-size crossover (even qualitatively, with a citation) is a much stronger answer than leaving it as an unexplained effective number.

## Recommended citations to add

Essential:
- **Gefen, Aharony, Alexander**, PRL **50**, 77 (1983) — anomalous diffusion on percolation clusters (the d_w framing). **[verify page]**
- **Havlin & Ben-Avraham**, *Diffusion in disordered media*, Adv. Phys. (2002 reissue of 1987) — review; d_w, d_s values. **[verify]**
- **Larsen & Furst**, PRL **100**, 146001 (2008) — microrheology of the gelation transition (closest microrheology precedent).
- **Alexander & Orbach**, J. Phys. Lett. (1982) — spectral dimension d_s = 4/3 conjecture. **[verify]**

Position the κ mechanism:
- **PRE 95, 010101(R) (2017)** — nucleation + preferential-growth percolation, continuous→first-order.
- Interactive cluster-growth percolation, **PRA 38, 4198 (1988)**. **[verify]**
- Two-parameter (constant + correlated growth) percolation FSS, Physica A (2017). **[verify]**
- An explosive-percolation review, if you invoke the sharp κ→1 rise.
- A void/continuum-percolation-threshold reference to anchor p_c′ = 1 − p_c. **[verify choice]**

## Recommended framing adjustments

1. **Add one related-work sentence to the Letter** acknowledging that (a) microrheology already locates gel points (Larsen–Furst) and (b) growth rules already tune percolation (nucleation-growth models) — then state the specific new contribution: the void-percolation identity plus κ as a *single continuous morphological handle read out rheologically*. Pre-empting both precedents in one sentence is much safer than having a referee find them.
2. **Own the 2/d_w ≈ 0.5 point** explicitly (at minimum in the SM): geometric identity for p_c′, 3D value of 2/d_w for the α = 0.5 coincidence, with the 2D caveat.
3. **Give ν_eff ≈ 1.6 a home** — tie it to d_w / anomalous-diffusion crossover scaling, or at least cite that literature and call it an effective dynamic exponent rather than an unexplained number.

## What remains genuinely novel (your defensible claims)

- The explicit identification of the *passive-microrheology gel point* with the **void-percolation transition** p_c′ = 1 − p_c, demonstrated by direct probe simulation in the fluid phase.
- **κ as a single continuous nucleation-density handle** that moves the gel point across ≈ 0.68–0.91 while preserving the effective critical character — a rheologically-framed, continuously-tunable realisation of nucleation-growth percolation, with the Eden bound as the compact limit.
- **FSS evidence** that this dynamically-defined threshold sits in one effective class across κ, with a resolved Eden crossover.

None of the precedents combine these three. The paper is defensible — it just needs to *say* what it is not claiming to have invented.

## Suggested next step

This is a preliminary pass (about a dozen sources). If useful, I can do a **systematic sweep**: pull 15–20 abstracts, build an annotated bibliography, draft a ready-to-drop "related work" sentence/paragraph for the Letter and the SM, and generate verified BibTeX entries for everything above — so the co-authors receive positioning *and* the citations already in hand.
