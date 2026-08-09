# The Twelve Review Moves

Each move: what to check, how, and a worked example from the review of Beaman, Duflo, Pande & Topalova (2012, *Science*) — "female leadership raises girls' aspirations and educational attainment," identified off randomized reservation of gram panchayat (GP) pradhan seats in Birbhum district, West Bengal ("Science: 20 GPs in a Single District," gojiberries.io).

## 1. Decompose indices

**Check:** Which components of any summary index moved, and whether the component that maps most literally onto the headline claim is among them. A normalized index weights items by the SD of their baseline gaps, so a few large-gap items can carry the average while the claim-relevant item sits at zero.

**How:** Rebuild the component table from the paper's own tables. Put the headline coefficient next to each component coefficient.

**Example:** The aspirations index moved +0.166 SD (SE 0.057), but its components split: housewife-rejection +0.075, high-education job +0.099, marry-after-18 +0.085 — and *wishes to graduate secondary school* +0.001 (SE 0.045). The paper's Discussion attributes the educational-attainment result principally to aspirations; the one aspiration that predicts attainment is the one that did not move. "Wish to be pradhan," the most literal role-model item, came in at −0.008.

## 2. Ceiling/floor effects and baseline gaps

**Check:** "Closed X% of the gap" depends on what the gap was and where each group started. Items where the comparison group is at the ceiling dominate a normalized gap index mechanically; items where the baseline gap is ~zero cannot contribute.

**How:** Pull baseline means by group for every component.

**Example:** Boys' baselines were 99.8% (housewife item) and 98.0% (marry-after-18) — the two ceiling-gap items that dominate the index. Two other items were statistical ties at baseline (want-to-be-pradhan: 48% girls vs 50% boys; high-education job: 16.6% vs 15.7%).

## 3. Dose-response: step or curve?

**Check:** If the design has graded exposure, does the effect scale with dose, or jump only in one cell? Two null cells being indistinguishable *from each other* does not establish that dose matters; it establishes that the lower dose does nothing.

**How:** Line up the coefficients by exposure level. A causal-exposure story predicts a curve; flat-at-zero-then-jump is a step localized to one cell — which is also what a confound specific to that cell would produce.

**Example:** After one full cycle (up to nine years of a female pradhan), the index moved −0.005 (SE 0.052); after two cycles, +0.166. The paper read Table S6 (1998-only vs 2003-only once-reserved villages indistinguishable, p = 0.28–0.84) as dose-response evidence. The trajectory on the index is (0, −0.005, +0.166): a step, not a curve.

## 4. Mechanism validation

**Check:** Is the asserted causal channel empirically live? Exposure stories require measured exposure: do subjects perceive the treatment, and are effects gated on that perception?

**How:** Look for awareness/exposure measures in the paper, its supplement, and companion papers on the same data.

**Example:** The companion QJE 2009 paper, same villages and survey wave: 33% of women could name the current pradhan (67% of men); reservation *lowers* name recognition by 10–14 points; attitudinal effects are "concentrated among those who know the Pradhan's name"; and for women the attitudinal effect of reservation is absent — women are described as too unaware of local politics for exposure to operate. The 2012 paper's channel is the one its own companion documented as gated and null for women.

## 5. Implementation fidelity

**Check:** Did the treatment happen on the ground as theorized? For "exposure to X" treatments: is X actually present, visible, and functioning?

**How:** Search for audits, later replications, and administrative evidence — including work published after the paper.

**Example:** A 2026 phone audit of Rajasthan's 2020 female-reserved sarpanch seats: of 377 answered calls, 9% reached the elected woman; 85% were intercepted by male relatives; 86% of those refused to transfer the call. A 2026 survey across 1,927 GPs in three states: 43% of female sarpanches report final authority over governance decisions, vs 89% of males. The role model is often not the person citizens can observe transacting or deciding.

## 6. ITT → TOT arithmetic

**Check:** Divide the intent-to-treat effect by the plausible share actually exposed. Is the implied treatment-on-treated effect credible against known benchmarks for that class of intervention?

**How:** Take exposure shares from moves 4–5; compare the implied TOT to effects of direct, structured interventions.

**Example:** ITT of 0.166 SD ÷ 9% reached-the-woman ⇒ TOT ≈ 1.84 SD; even on the generous 33% name-recognition denominator, TOT ≈ 0.50 SD. The self-affirmation interventions the paper itself cites run ~0.3 SD.

## 7. Effect-size benchmarking

**Check:** Place each headline effect next to the best-documented interventions targeting the same outcome. Note magnitude *and* intensity — passive exposure beating a material transfer is a claim that needs defending.

**How:** Search for comparators in three classes: material transfers, conditional cash, structured persuasion.

**Example:** Reservation's attendance effect (9.8 pp) ≈ double the Bihar Cycle program (bicycle grant: +5.2 pp enrollment). Its stated marry-after-18 wish (+8.8 pp) ≈ Apni Beti Apna Dhan's effect on *actual* under-18 marriage (−9 pp, from an 18-year ~$400 conditional bond). Its aspirations index (0.166 SD) ≈ the Breakthrough curriculum's 0.18 SD from 27 facilitated 45-minute classroom sessions (AER 2022). Its grades-completed effect (0.59) ≈ PROGRESA's simulated 0.7 years from monthly cash.

## 8. Statistical fragility

**Check:** Count clusters at the level of assignment, in each treatment cell. Then: wild cluster bootstrap and randomization inference (few clusters), Bonferroni and Benjamini-Hochberg across the primary-outcome family (multiple testing), leave-one-cluster-out (influence).

**How:** With a replication package, run all four. Without one, apply corrections to the published p-values where possible and flag the rest.

**Example:** The headline cell held 20 twice-reserved GPs (377 adolescents). Replication: the best raw p (housewife, 0.036) became 0.051 under wild cluster bootstrap and 0.10 under randomization inference; Bonferroni pushed every outcome above 0.25; BH left the best three tied at 0.16. No outcome survived any correction at p < 0.05. Leave-one-GP-out: housewife failed p < 0.05 in 8 of 20 subsamples; marry-after-18 in 15 of 20.

## 9. Stated vs revealed preferences

**Check:** Are outcomes self-reports of attitudes/aspirations rather than behavior? Treatments that shift norms also shift what respondents think they should say. Aspirations are cheaper to move than behavior and do not automatically become it.

**Example:** All aspiration outcomes were one-shot post-treatment self-reports by adolescents and parents in villages where the salient norm (a woman in office) was itself the treatment. The behavioral comparison in move 7 (stated wish moving as much as an 18-year bond moved actual marriage) is the tell.

## 10. Companion-paper triangulation

**Check:** Same team, same data, other papers — do facts reported elsewhere contradict the mechanism or framing here?

**How:** Find every paper using the same survey/experiment (authors' CVs, citation trails) and read them for the awareness, exposure, and public-goods facts this paper needs.

**Example:** The QJE 2009 companion (move 4) supplied the awareness baselines and the effects-gated-on-recognition result. Earlier work by the same team showed female pradhans invest more in drinking water — a public-goods channel that can raise girls' schooling with no aspirational mechanism at all.

## 11. Selective emphasis

**Check:** Which coefficients does the text narrate, and which columns of the same table go unmentioned? Omissions cluster around the claim-relevant nulls.

**Example:** The Results section walks through three of the four index items; the unmentioned fourth is graduation aspiration (+0.001). "Wish to be pradhan" is also unmentioned. In the parents' table, the foregrounded number (in-law-chosen occupation, 76%→65%) sits one column from the unmentioned parental wish-to-graduate coefficient: 4.8 pp with SE 4.8, t ≈ 1.

## 12. Generalizability

**Check:** State the actual evidentiary base — clusters, sites, period — next to the breadth of the title claim. Ask what is unusual about the setting.

**Example:** The claim "female leadership raises aspirations and educational attainment" rests on 20 twice-reserved GPs in one district of one state, surveyed 2006–07 — a state with an atypically disciplined panchayat apparatus, under quota-installed (not organically elected) leaders.
