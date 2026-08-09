# Tier 1: The Five Checks That Catch Most Real Bugs

Ordered by how many number-changing findings each produced in the audits behind
this skill. Run all five even under time pressure. Each is **Check / How /
Example**, and every example is a real finding with the number it moved.

---

## 1. Denominator and unit match

**Check:** For every ratio in the analysis: what is the numerator's unit, what
is the denominator's unit, and does every quantity it is compared against share
both? A rate is only comparable to another rate built the same way.

This is the highest-yield check in the skill. It produced three independent
bugs in one pipeline, and each looked correct in isolation — the error only
exists in the comparison.

**How:**

- List every rate/share/ratio column and write down its numerator unit and
  denominator unit explicitly. Not "per visit" — *whose* visits, counted over
  what set.
- For each regression, check that the outcome and every constructed regressor
  share a denominator. Mixed units inside one model is the classic form.
- Verify the denominator by reconstruction: `numerator / rate` should return the
  denominator actually used. If it does not equal the denominator you expected,
  you have found the bug without reading any code.
- Ask whether the estimand is a **mean of ratios** (average person) or a **ratio
  of means** (average unit of exposure). These are different quantities, not
  robustness variants of each other. Whichever is reported, the paper must say
  which and why.

**Example A — mixed denominators inside one regression.** A model regressed
tracking-per-**visit** on flagged-domains-per-**domain**. The coefficient was
−3.069 (SE 0.817, p < .001) and was reported as a finding. With the denominator
matched — flagged domains per *visit* — it became −10.905 (SE 7.344, **p =
.138**). The association was an artifact of the mismatch, and none of the four
measures was significant under both denominators.

**Example B — a counterfactual compared to the wrong baseline.** A residual
"exposure after blocking" measure counted unblocked cookie-setting *domains*,
while the published baseline counted *cookies*. Dividing one by the other
overstated blocking efficacy by 14 points: **84.3% removed became 70.2%**, and
the age ratio moved 1.79 → 1.98. The source file even carried a comment saying
the two were not comparable and built a matched column for the purpose — every
consumer then ignored it. A comment is not a guard.

**Example C — one denominator differing from every other.** An organisation-share
measure divided by the *unfiltered* visit frame, which included 60,547 visits
with no domain attached; every other rate in the paper divided by the filtered
count. 963 of 1,134 units affected; the mean moved 0.5503 → 0.5573 and four
regression coefficients moved with it. Reconstruction found it in one line:
`numerator / share − expected_denominator` summed to exactly 60,547.

**Fix pattern:** route every baseline through one function
(`base_col(measure)`), so the pairing is defined once rather than at each call.

---

## 2. Missing coded as zero

**Check:** Every place a missing value becomes a number. Is zero the structural
truth ("measured, and there were none") or is it "not measured"? These are
different facts and collapsing them is the second most productive bug class.

**The decisive sub-check is differential missingness.** Missingness at a
constant rate attenuates. Missingness whose *rate changes* across waves, arms,
or groups **manufactures** trends and gaps that are not there. Always compute
the fill rate by group and by period, never just overall.

**How:**

- Grep for `fillna`, `coalesce`, `replace(NA`, `ifelse(is.na(`, `mvencode`,
  `.fillna(False)`, and every silent equivalent.
- Grep for comparisons that swallow missingness. `NaN > 0` is `False` in pandas
  and R alike, so a bare `x > 0` on a column with NAs is a hidden fill. This
  form is far more dangerous than an explicit `fillna` because there is nothing
  to grep for except the comparison itself.
- Tabulate the missing rate by every grouping variable used in the analysis and
  by every time period. Report the *change* in the rate, not just the level.
- For each fill, state the direction of the induced bias in one sentence. If you
  cannot, you do not yet understand the fill.
- Distinguish three states in the data itself, not in your head: measured-and-zero,
  measured-and-positive, not-measured. Carry a `*_queried` / `*_observed` flag.

**Example A — the fill that manufactured a trend.** A crawl's cookie extract was
rank-capped while its request extract was not, so most domains were never asked
about cookies; the code filled those with 0. Coverage was 58% in one wave and
66% in the next, and that *growing gap alone* produced an apparent decline.
Over half the reported drift was artifact.

**Example B — the same bug resurrected downstream.** After the fill above was
fixed to leave unqueried domains as `NaN`, a downstream notebook tested
`NaN > 0`, which is `False`, and restored the artifact exactly. Coverage ran
45.2% → 36.3% across the two waves, and the decline came back: the published
change was **−8.7pp against a true −3.1pp** on domains queried in both. Fixing a
fill at its source does nothing if a consumer re-implements it.

**Example C — one row describing two populations.** The same `NaN > 0` pattern
made an agreement table compute prevalence over all 6,902 domains (with
never-asked counted as absent) while the Spearman correlation on the same row
silently dropped those pairs and ran on 2,490. Restricted to one population, the
row read 74.2% agreement rather than 49.1%.

**Fix pattern:** never let the analysis see a fill it cannot distinguish from a
measurement. Keep the flag column; restrict, do not fill; and report the
restricted `n` beside the statistic.

---

## 3. Silent row loss

**Check:** Does every operation conserve the units it should? Rows disappear
without error in more ways than they appear.

**How:**

- Assert row counts before and after every merge, filter, groupby, and reshape.
- **`groupby` on a filtered frame drops entire units.** If you group a subset and
  then assign back onto that index, every unit absent from the subset vanishes
  rather than taking a zero.
- Every merge declares its cardinality (`validate=` in pandas, an explicit
  `assert` in R/Stata) and its expected row count.
- Check whether the loss is *differential*. Losing units at random costs power;
  losing them at a rate that differs by wave or arm is bias, and it is the same
  disease as check 2.
- Confirm the join key is unique on the side that must be unique, and that the
  key *transform* is injective — string normalisation, case folding, `.`→`_`
  substitutions, and truncation all create collisions.

**Example — the differential deletion.** A measures table was built by grouping
*third-party* requests. A page whose requests were all first-party had no rows
in that frame, so it never got a group and vanished — not as unmeasured, but as
a measured page whose every count was genuinely zero. 288 of 13,711 pages in one
wave, 472 of 12,748 in the next: 2.1% against 3.7%. Those were exactly the
"lost all trackers" cases, so dropping them made the later wave look more tracked
than it was. A headline stability claim moved from **−0.1pp to −0.8pp**.

**Fix pattern:** reindex onto the full unit list and fill the genuine zeros
explicitly, then assert the count. Verify the fix is *purely additive* — every
pre-existing row numerically identical, including its NA pattern.

---

## 4. Provenance

**Check:** Every number in the running prose traced to the artifact that
produces it. This is mechanical, unglamorous, and it found more errors than any
other single check.

**How:**

- Extract every numeric token from the write-up's prose. Count them.
- For each, locate the table, figure, or script output it comes from, and
  compare. `scripts/audit_provenance.py` does the extraction and matching.
- Flag two classes: **orphans** (a number in prose that appears in no artifact —
  it was computed by hand and cannot be regenerated) and **mismatches** (a
  number in both, disagreeing).
- Check artifact timestamps against the data they derive from. A table older
  than its input is stale by construction.
- Diff the emitted artifacts against the committed ones after a clean rerun.

**Example — a paragraph quoting the previous version of its own table.** A
commit corrected a table and regenerated it; the paragraph citing it was never
touched. The prose values were byte-identical to the *pre-fix* table:
2.28 / 4.57 / 7.42 where the current table said 2.86 / 7.31 / 9.08. Nothing in
the build failed, because prose is not compiled against its sources.

**This is why the habit in SKILL.md exists:** after fixing any artifact, grep
the prose for every number it feeds. Eight of nineteen errors in the motivating
case were of exactly this form, and all eight were introduced by earlier
*correct* fixes.

---

## 5. Internal consistency

**Check:** The same quantity stated in two places must agree. Papers contradict
themselves more often than they contradict their data.

**How:**

- Extract every quantity stated more than once — abstract vs body, results vs
  limitations, prose vs its own table, figure caption vs figure.
- Check that named statistics match their labels: a mean called a median, a
  marginal called a joint, a count called a share.
- Check that qualitative claims match the tests they cite. "X and Y are not
  distinguishable" against the actual p-values in the referenced table.

**Example A — the section that contradicted its own paper.** A limitations
section said "race **and age** are not [statistically indistinguishable from the
benchmark]". The table it cited reported age χ²(4) = 3.1, **p = .55**, and the
methods section three pages earlier said the opposite. The limitations text was
stranded by an earlier fix to the age brackets. The same sentence overstated the
mean absolute deviation as 1.5 where the table said 1.2.

**Example B — joint read off a marginal.** "Over 65% met all three at least ten
times." The three marginals were 76.0%, 65.9% and 81.0%; the 65% was the
smallest marginal, which is an *upper bound* on the joint, not the joint. The
actual joint was **59.1%**.

**Example C — one quantity, three values.** The same interval appeared as
"6.2 and 8.4", "[6.20, 8.27]", and "6.2 and 8.3" in one paper. The 8.4 paired
one column's lower bound with a different column's upper bound — an interval
that existed in no column at all.
