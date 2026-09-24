# RW_Percolation — Paper Inventory & Series Strategy

**Closed by the September 2026 finite-size letter.** The series option and the question of two universality classes were settled by `paper_drafts/prl_letter.tex`: one effective critical character (ν_eff ≈ 1.6, no systematic κ trend for κ ≤ 0.8), not a paper series and not two classes. The optional rod-like follow-up (P5) is deferred until this letter has been submitted for review. Paths below that point at `sections/`, `main.tex`, or `docs/` now live under `archive/legacy_pre_fss/`. See `LEDGER.md`.

*Working map of every paper version and reusable result in the repo, with options for cherry-picking one flagship paper vs. splitting into a complementary series. Prepared to drive the "which papers do we write" decision.*

**Legend:** ✅ read in full this session · 🟨 mapped from structure/summary docs · ⬜ inferred from filename/scope (needs a read to confirm).

---

## Part A — The paper versions that already exist

| # | Version | Location | Core thesis | Status & health |
|---|---|---|---|---|
| **V1** | **New focused paper** ✅ | `paper_drafts/sections/*` + `main.tex` (+ my consolidated `full_draft.md`) | The viscoelastic gel-point is *not* fixed by density — it is set by growth dynamics and tunable via a single nucleation-density parameter κ. | **Strongest.** Complete, honest, internally consistent. Main text done; appendices rewritten; figures exist. Only gap: bibliography keys + per-κ table. |
| **V2** | **Old broad paper** 🟨 | `main_old_paper.tex` (62 KB), `docs/MAIN_PAPER_DRAFT.md`, appendices A–E | "Complete Characterization Framework for Material Design" — universality classes + tunable gel-point + **98.6% prediction accuracy** + hydrogel/scaffold/sensor design. | **Over-claims.** Nature Materials framing, fabricated-looking accuracy/exponents/case studies. Good *scaffolding and breadth*, but its headline claims aren't defensible. Mine it for parts, don't ship as-is. |
| **V3** | **Colleague report** ⬜ | `paper_drafts/colleague_report.tex` (+ README/summary) | Internal write-up for a collaborator. | Not read in full this session. Likely a condensed results summary — useful as a plain-language backbone or cover note. |
| **V4** | **Word skeleton / "for Dan"** ⬜ | `paper_drafts/paper_skeleton.docx`, `.html`; `forDan.docx` (most recent, ~large) | Word-workflow versions, possibly shared with a co-author ("Dan"). | Recent (2026). Not read. May contain co-author edits/comments worth reconciling before we finalise structure. |
| **V5** | **Methodology note** 🟨 | `simulation_methodology.md` / `.docx` | Standalone description of the simulation method. | Self-contained; a ready methods backbone / supplementary. |

**Bottom line on versions:** you effectively have *one publishable paper* (V1) and *one idea-bank* (V2) plus supporting write-ups. The real question isn't "which draft" — it's "how many distinct results deserve their own paper," which is Part B.

---

## Part B — The distinct result-assets (the actual building blocks)

These are the separable scientific findings scattered across `docs/`. Each is a candidate to be a paper, a lead result, or a section.

| Asset | Where | One-line claim | Maturity |
|---|---|---|---|
| **R1 — Gel-point = void percolation** | new paper §3.1, `docs/*ALPHA*`, `MICRORHEOLOGY_*` | Winter–Chambon α=0.5 gel-point coincides with void-phase percolation, pc′≈1−pc≈0.683. | ✅ Solid, quantitative. The foundational result. |
| **R2 — Templated growth = distinct gelation behaviour** | new paper §3.2, `UNIVERSALITY_CLASS_ANALYSIS.md`, `TEMPLATING_*` | Connectivity-constrained growth shifts pc′ by +0.20 and broadens the transition 3.4×, with persistent sub-diffusion above pc′. | ✅ Solid (phenomenological on "universality"). |
| **R3 — κ-mixing tunability** | new paper §3.3, `TUNABLE_GEL_POINT_POSITIONING.md` | A single nucleation-density parameter continuously tunes pc′ over ~0.31. | ✅ Solid; κ=1 endpoint extrapolated. |
| **R4 — Frequency-domain / 3D viscoelastic surfaces** | new paper §3.4, `README_3D_VISCOELASTIC_SURFACES.md`, `MICRORHEOLOGY_IMPLICATIONS.md`, viscoelastic_*.png | GSER → G′(ω), G″(ω), δ(ω,p) full spectra & surfaces; δ=45° signature at pc′. | 🟨 Rich figures exist; single-replica (flagged limitation). |
| **R5 — Critical-region detection methodology** | `CHANGEPOINT_SCALING_*` (5 docs), `PADDED_SIGMOID_*`, `CRITICAL_REGION_TAU_CR_*`, `MSD_*` | Robust methods for locating the gel-point/critical region from noisy MSD (changepoint detection, τ_cr scaling, padded sigmoid). | 🟨 Substantial standalone methods content. |
| **R6 — Correlation length / finite-size** | `CORRELATION_LENGTH_ANALYSIS.md`, `FINITE_SIZE_SCALING_SUPPLEMENTARY.md` | ξ(p) behaviour; finite-size offset of pc′. | ⬜ Partial; true FSS across L not yet done (known gap). |
| **R7 — Rod-like / anisotropic templating** | `ROD_LIKE_TEMPLATING.md`, `TEMPLATED_RANDOM_VARIANT.md`, 3d_templated_results.* | Anisotropic (rod) templates as another morphology axis. | ⬜ Exploratory variant; extent unknown. |
| **R8 — Biomedical / fibrin-clot connection** | bib: Evans2010 (Blood), Evans2010b, Curtis2013 (fibrin–thrombin *templating*) | Templated gelation maps onto real fibrin/blood-clot networks & gel-point diagnostics. | ⬜ Currently only a citation thread — but a strong applied hook (and ties to P. R. Williams). |
| **R9 — Prediction/design model** | V2 appendix A, `COMPLETE_CHARACTERIZATION_FRAMEWORK.md` | Map lattice/growth parameters → predicted gel-point & moduli for material design. | 🟨 The "98.6%" version is not defensible; a scaled-back predictive map from κ *could* be. |

---

## Part C — Two ways to go

### Option 1 — One flagship paper (cherry-pick)
Ship **V1 as-is** (R1+R2+R3+R4) — "Tunable gel-point positioning via nucleation density control." It's the tightest, most novel, most complete story. Fastest route to submission. Everything else becomes supplementary or future work.

- **Pros:** ready now; one clean narrative; honest.
- **Cons:** leaves R5 (methods), R7 (rods), R8 (biomedical) unpublished; "spends" the headline result in one venue.
- **Best if:** you want a submission in weeks, not months.

### Option 2 — A complementary series
Split the assets so each paper has one clear contribution and they cite each other rather than compete. A natural 3-paper spine (+ optional 4th/5th):

| Paper | Title (working) | Lead assets | Angle / venue class | Readiness |
|---|---|---|---|---|
| **P1 — Foundational** | *The rheological gel-point as a void-percolation transition* | R1 (+R6 support) | Physics — soft matter / stat-mech (PRE, Soft Matter) | High — R1 is done; needs the pc′=1−pc argument foregrounded + light FSS. |
| **P2 — Flagship (the new paper)** | *Tunable gel-point positioning via nucleation density control* | R2 + R3 (cites P1) | Soft matter / materials (Soft Matter, Macromolecules) | **Highest — already drafted.** |
| **P3 — Methods** | *Locating the gel-point from probe MSD: changepoint & sigmoid methods* | R5 (+R4 spectra) | Methods / microrheology (Rheol. Acta, J. Rheol., PRE) | Medium — content exists across `docs/`, needs assembly. |
| **P4 — Applied (optional)** | *Templated gelation as a model for fibrin/colloidal networks* | R8 + R2 + R4 | Applied / biomedical (Soft Matter, biorheology) | Low now — needs framing + a real-system tie-in; high impact. |
| **P5 — Variant (optional)** | *Anisotropic (rod-like) templates and morphology control of gelation* | R7 | Short letter / follow-up | Low — depends how far the rod work went. |

- **Pros:** maximises publications from the work; each paper is defensible and focused; they reinforce each other.
- **Cons:** more total effort; P1 and P2 must be sequenced (P2 cites P1) so there's a dependency; risk of salami-slicing if the splits are too thin (P1/P2 must each stand alone — see below).
- **Best if:** this is a sustained programme (it clearly is, given the depth in `docs/`).

**Salami-slicing check:** P1 and P2 are only worth separating if P1 carries enough on its own — i.e. the void-percolation identification plus finite-size scaling across several L (R6), which is *currently the biggest genuine gap*. If FSS doesn't materialise, fold R1 into P2 as its opening result and run the series as P2 + P3 (+P4).

---

## Part D — What's missing, per path

- **For V1/P2 (either option):** fix the 10 missing/mismatched bibliography keys; expand the per-κ table from `tunable_gel_point_results.mat`. (Both already flagged in `full_draft.md`.)
- **For P1:** run finite-size scaling across L (100–750) to turn the "consistent with 1−pc" statement into a measured extrapolation + real exponent — this is what makes P1 a paper rather than a section.
- **For P3:** decide whether the changepoint/τ_cr/padded-sigmoid material is a *methods contribution* (novel estimator) or just *our procedure* (belongs in P2 supplementary). That hinges on how the changepoint scaling compares to standard gel-point estimators — worth me reading the 5 `CHANGEPOINT_SCALING_*` docs to judge.
- **For P4:** identify one real dataset or collaborator system (fibrin via the Evans/Curtis/Williams line looks tailor-made) to anchor the applied claims.
- **For R9/design model:** only revive a *scaled-back* κ→pc′ predictive map; the 98.6%-accuracy framing should be retired.

---

## Suggested next move

Two decisions unblock everything:

1. **One flagship (Option 1) or a series (Option 2)?**
2. If a series — **is finite-size scaling (R6) on the table?** That single question decides whether P1 is its own paper or the opening act of P2.

Tell me the direction and I'll (a) deep-read the specific docs behind whichever assets you pick — especially `main_old_paper.tex`, `colleague_report.tex`, `forDan.docx`, and the changepoint set — to firm up the 🟨/⬜ rows, and (b) turn the chosen split into per-paper outlines with figure lists and a claimed-results ledger.
