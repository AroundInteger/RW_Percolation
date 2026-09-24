# Comprehensive Paper — Plan & Finite-Size Scaling Design

**Closed by the September 2026 finite-size letter.** The series option and the question of two universality classes were settled by `paper_drafts/prl_letter.tex`: ν_eff ≈ 1.6 with no systematic κ trend for κ ≤ 0.8. This note is the design that study followed, not an open decision. See `LEDGER.md`.

*Decision (agreed): a single comprehensive paper, not a series. The methods (R5) and fibrin/applied (R8) threads are parked as optional future companions. This plan covers the finite-size scaling (FSS) study — including κ-series coverage — the paper structure, figures, framing contingency, work roadmap, and compute budget.*

---

## 1. The scientific question FSS must answer

FSS is not just box-ticking here; it decides the paper's central framing. Three nested questions, in order of importance:

1. **Is the gel-point a true critical point in the thermodynamic limit?** Extrapolate pc′(L) → pc′(∞) and confirm it lands on 1−p_c (=0.6884) for the random class. *(Upgrades R1 from "consistent with" to "measured.")*
2. **Are the random and templated classes genuinely different universality classes?** Compare the correlation-length exponent ν between them. Random should recover 3D percolation ν≈0.88; templated either matches (→ same class) or differs (→ distinct class). *(Decides the R2 framing.)*
3. **Along the κ tuning line, is ν constant or does it vary with κ?** This is the completeness question you raised. Two possible stories:
   - **(A) Fixed class, tunable non-universal threshold:** ν(κ) ≈ const; κ only shifts pc′ and rescales amplitudes. Clean, conservative, very defensible.
   - **(B) κ-dependent exponents:** ν varies along the line — a line of *continuously varying universality*. Striking, publishable at a higher tier, but a strong claim that needs tight error bars.

   We cannot assert either without intermediate-κ FSS. Whichever way it falls, the paper is stronger for having tested it, and it closes the obvious referee question.

---

## 2. FSS study design

### 2.1 Conditions (the κ coverage answer)

Do **full FSS on 5 growth conditions**, not all 18 κ and not just 2:

| Condition | κ | Role in the paper |
|---|---|---|
| Random (Bernoulli) | 0.00 | Class-A endpoint; must recover ν≈0.88, pc′(∞)→1−p_c |
| κ-mid | ~0.80 | Intermediate — tests ν(κ) flatness (Bernoulli-like regime) |
| κ near regime boundary | ~0.97 | Intermediate — the most likely place ν would change, if it does |
| Templated 6N (multi-seed) | — | The headline +0.20 shift result; its own ν |
| Eden limit (single seed) | 1.00 | Class-B endpoint (see caveat 2.4) |

Rationale: endpoints establish the two classes; the two intermediate κ points (0.80, 0.97) bracket the regime boundary and are exactly where a κ-dependent exponent would show up first. Drop **26N** from FSS — it was already shown indistinguishable from 6N, so it doesn't need its own scaling study (state this explicitly).

### 2.2 Lattice sizes

Six sizes spanning a ~15× range for a stable power-law fit:

$$
L \in \{50,\ 100,\ 200,\ 300,\ 500,\ 750\}
$$

(Confirm L=750 is tractable — lattice storage bit-packed is only ~50 MB, so memory is fine; the cost is walker-steps, §5.) A geometric-ish spread gives clean leverage on L^{−1/ν}.

### 2.3 Observables and three independent ν estimates

For each (condition, L): run a fine p-sweep through the critical region and extract, per size:

1. **Threshold shift:** pc′(L) from the α=0.5 crossing, then fit
$$
p_c'(L) = p_c'(\infty) + a\,L^{-1/\nu}.
$$
2. **Transition-width scaling:** sigmoid width w(L) ~ L^{−1/ν} — an independent ν.
3. **Data collapse:** plot α(p,L) against the scaling variable
$$
x = \big(p - p_c'(\infty)\big)\,L^{1/\nu},
$$
and tune ν for best collapse. Agreement of all three is the robustness check.

Report ν with uncertainties for each condition; the class comparison (Q2) and the ν(κ) test (Q3) are then direct.

### 2.4 Two methodological cautions

- **L_W should scale with L.** The finite-size crossover time grows ~L²/D, so a fixed L_W=10⁶ that resolves the anomalous window at L=500 may be too short at L=750 and needlessly long at L=50. Scale L_W roughly ∝ L² (or verify the fit window [L_W/100, L_W/10] still sits in the power-law regime at each size). This is the main cost driver — see §5.
- **The Eden limit (κ=1) is not a standard critical point.** It's essentially a single connected cluster with pc′→1 as L→∞; conventional FSS collapse may not apply cleanly there. Treat κ=1 as a limiting *bound* (pc′→1) rather than forcing a ν out of it, and say so. The defensible ν comparison is Bernoulli vs templated-6N vs the intermediate κ points.

---

## 3. Paper structure (comprehensive, single paper)

Working title options (pick after FSS fixes the framing):
- Conservative: *Tunable gel-point positioning in three-dimensional percolation networks via nucleation-density control*
- If Q2/Q3 give distinct classes: *The rheological gel-point as a void-percolation transition: nucleation-density control and universality in three dimensions*

| Section | Content | Source |
|---|---|---|
| 1. Introduction | Gelation, Winter–Chambon, microrheology; the "is the gel-point fixed?" question; add universality + FSS motivation | ✅ drafted, light additions |
| 2. Model & Methods | Lattice model, RW engine, gel-point extraction, GSER, **+ FSS methodology (§2 here)** | ✅ drafted + new FSS subsection |
| 3.1 Results — gel-point = void percolation | R1 **+ FSS: pc′(∞)→1−p_c, ν_Bernoulli** | drafted + FSS |
| 3.2 Results — templated class | R2 **+ FSS: ν_templated, class comparison** | drafted + FSS |
| 3.3 Results — κ tuning | R3 **+ FSS along κ: ν(κ) flat or varying (the completeness result)** | drafted + **new** |
| 3.4 Results — frequency domain | R4 (GSER spectra, δ=45° signature) | ✅ drafted |
| 4. Discussion | Physical basis; universality interpretation (contingent); κ as design parameter; Eden limit; **shortened limitations** (FSS now done) | ✅ drafted, revise |
| 5. Conclusions | As drafted, add the universality verdict | ✅ drafted, revise |
| App A–F | Math framework; void-percolation; **FSS details + collapses (new)**; κ-table; GSER; computational implementation | rewritten + new App C |

### Figure plan
- **Fig 1** Growth-morphology schematic — ✅ exists
- **Fig 2** α(p) random class **+ FSS panel** (pc′(L) fit and/or collapse) — augment
- **Fig 3** α(p) two classes **+ ν comparison** — augment
- **Fig 4** α(p,κ) tuning — ✅ exists
- **Fig 5** pc′(κ) tunable curve — ✅ exists
- **Fig 6 (NEW)** FSS-along-κ: ν(κ) with error bars (flat line = story A; slope = story B), plus representative collapses — the completeness figure
- **Fig 7** GSER spectra — ✅ exists

Net new figure work: one dedicated FSS-along-κ figure (Fig 6) + FSS panels folded into Figs 2–3.

---

## 4. Framing contingency (decide after FSS, not before)

| FSS outcome | Headline framing | Title | Tier |
|---|---|---|---|
| ν_random ≈ ν_templated ≈ ν(κ) ≈ 0.88 | Single universality class; κ tunes a **non-universal** gel-point; morphology controls amplitudes/width | conservative title | Soft Matter / PRE |
| ν_templated ≠ ν_random, ν(κ) ~ const in each regime | **Two universality classes**, κ selects between them | universality title | strong Soft Matter / PRE, letter possible |
| ν varies continuously with κ | **Line of continuously varying exponents** | boldest title | highest tier — but hold to the strictest error bars |

**Do not pre-write the universality claim.** Draft the FSS-independent parts now; leave §3.1–3.3 verdict sentences and the title as slots to fill once ν is in hand.

---

## 5. Compute budget & risk

Order-of-magnitude, relative to work already done (existing κ-study was ~1890 conditions):

- Conditions: 5 growth settings × 6 L × ~10 p (critical region) × N_s=3 ≈ **900 (setting,L,p,s) runs**, each 3000 walkers.
- Cost is dominated by total walker-steps. If L_W scales ∝ L², the large-L runs dominate: L=750 is ~2.25× the steps of L=500 per walker. Expect total compute **comparable to, up to ~2–3× larger than**, the existing κ study — feasible on the current MATLAB `parfor` pipeline, but plan it as a batch/overnight campaign, not interactive.
- **Efficiency levers:** (i) only sweep the *critical region* per (setting, L), located from a quick coarse pass; (ii) 6N only, drop 26N; (iii) N_s=3 is enough given the online-MSD ensemble already averages 3000 walkers; (iv) cap L_W growth by checking the fit window rather than blindly scaling.
- **Risks:** L_W too short at large L (biases ν) — mitigate with the fit-window check; κ=1 not collapsing (expected — treat as bound); intermediate-κ pc′ near the regime knee being sensitive to grid resolution — use a finer p-grid at κ≈0.97.

---

## 6. Roadmap

**Phase 0 — lock scope (now).** Confirm the 5 FSS conditions, 6 L values, and the L_W-scaling rule. *(Open decisions in §7.)*

**Phase 1 — FSS compute.** Coarse p-pass per (condition, L) to bracket the critical region → fine sweeps → store α(p,L) tables. *(Runs on your machine; I can spec/adapt the MATLAB driver.)*

**Phase 2 — FSS analysis.** Extract pc′(L), w(L), collapses; fit ν three ways per condition; assemble ν(κ). Decide framing (§4).

**Phase 3 — paper assembly.** Slot FSS results into §3.1–3.3, build Fig 6, augment Figs 2–3, write App C (FSS), trim the limitations section, set title. Fix the bibliography gap and the per-κ table already flagged in `full_draft.md`.

**Phase 4 — polish & submit.** Framing pass, co-author review (the Word/`forDan` line), venue formatting.

---

## 7. Open decisions for you

1. **FSS conditions:** OK with the 5 (κ=0, 0.80, 0.97, templated-6N, κ=1)? Want a 3rd intermediate κ (e.g. 0.60) for a denser ν(κ) curve, at extra cost?
2. **Lattice sizes:** {50,100,200,300,500,750} — is L=750 within your machine's comfortable batch limit, or cap at 500 and add L=64 at the bottom for range?
3. **L_W policy:** scale ∝ L² (cleanest, costlier) or fix and verify window (cheaper)?
4. **Who runs the compute:** you kick off the MATLAB batch and I spec/adapt the driver, or do you want me to draft the full FSS driver script for you to run?
