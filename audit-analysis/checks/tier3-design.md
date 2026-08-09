# Tier 3: Design and Interpretation

Where the arithmetic is right and the meaning is still wrong. Citations in
[sources.md](../references/sources.md).

---

## Gelman

### The significance filter exaggerates — report Type S and Type M

**Check:** If a design is noisy, the estimates that clear a significance
threshold are, conditional on clearing it, badly exaggerated — and can have the
wrong sign. The question is not "is it significant" but "given this much noise,
what would a significant estimate look like even if the true effect were small".

**How:** Take the design's standard error and a plausible true effect size from
outside the data. Compute the **exaggeration factor** (expected |estimate| given
significance, over the true effect) and the **Type S rate** (probability the
significant estimate has the wrong sign). `retrodesign` in R does this. Report
these instead of, or beside, the p-value. A study powered at 0.06 to detect its
own published effect is not weak evidence for that effect; it is no evidence.

### The garden of forking paths

**Check:** Whether the analysis was chosen after seeing the data. This does not
require p-hacking or bad faith: if a different dataset would have led to a
different reasonable analysis, the reported p-value is not the p-value of the
procedure that generated it.

**How:** Ask what would have been reported had the sign flipped, had the
subgroup been null, had the outcome been the other one. Look for the
specification's degrees of freedom — outcome coding, exclusions, covariate sets,
subgroup definitions, thresholds. Pre-registration resolves it; absent that, the
honest move is to report the garden — the whole set of defensible
specifications — rather than one path through it.

### "The difference between significant and not significant is not itself statistically significant"

**Check:** Any claim that an effect is present in one group and absent in
another, or changed between waves. Comparing two significance verdicts is not a
test of their difference.

**How:** Test the interaction or the difference directly, with its own standard
error.

### Fake-data simulation

**Check:** Does the fitting procedure recover parameters you planted? This is the
strongest single check in the skill and the most under-used.

**How:** Simulate data from the assumed model with known parameters, run the
*actual pipeline* end to end, and check it returns the truth within its stated
uncertainty. This catches errors that no amount of staring at real output will,
because with real data you never know the answer.

It would have caught two real bugs in the motivating case directly: invalid
inclusion probabilities (simulate the sampling design, estimate a known
population mean, watch it come back biased) and a solver that stopped short of
the optimum (simulate, compare against the exact solution).

### The secret weapon

**Check:** Whether the paper reports one number where it could report the same
estimate across subsets, waves, or specifications.

**How:** Plot the estimate with its interval across every natural split. A
pattern that is real is usually visible as a pattern; one that is an artifact
usually appears in exactly one cell.

### Multilevel structure over multiple comparisons

**Check:** Where many related estimates are reported (many groups, many
outcomes), whether they are treated as independent tests requiring correction or
as draws from a common distribution.

**How:** Partial pooling shrinks noisy subgroup estimates toward the group mean
and typically dominates both "report all unadjusted" and "Bonferroni everything".
Where pooling is not feasible, at least declare the family — and check the
declared family matches the reported statistic (Tier 2E).

---

## Green

The Green Lab SOP is a concrete standard-operating-procedure document and worth
reading directly. The checks it implies for an audit:

### Verify the treatment happened and the outcomes were gathered

**Check:** Before any estimate, is there evidence the intervention was actually
delivered and the outcome actually measured? Receipts, spot checks, manipulation
checks, geotagged photos.

**How:** Look for the verification in the paper. Its absence is a finding. An
"exposure to X" claim needs measured exposure, not assumed exposure.

### Attrition, and especially differential attrition

**Check:** Who left, and did they leave at different rates by arm or group? This
is the same disease as Tier 1 check 2, in its experimental form.

**How:** Report attrition by arm and test the difference. If attrition is
independent of potential outcomes you lose power; if it is differential you lose
identification. Where it is differential, bound the estimate (Manski/Lee) rather
than assuming it away.

### Cluster at the unit of randomisation

**Check:** Standard errors clustered at the level treatment was assigned, not
higher, not lower. And the count that drives inference is the **number of
clusters**, not the number of respondents.

**How:** Count clusters per treatment cell. Below roughly 40, prefer randomisation
inference or a wild cluster bootstrap to asymptotic standard errors.

### Covariates chosen for prediction, not for balance

**Check:** Were covariates selected because they predict the outcome (good) or
because they looked imbalanced after randomisation (bad — that is a forking
path)? Covariates must be pre-randomisation measurements.

**How:** Check they are pre-treatment. Check the selection rule was stated in
advance. Green's lab caps covariate count by sample size (no more than M/20 with
interactions) — an explicit rule beats a judgement call.

### Report adjusted and unadjusted; disclose deviations

**Check:** Both estimates present, the pre-specified one labelled as such, and
every departure from the plan named.

### Permutation as the default

**Check:** Randomisation inference is the natural test when you know the
assignment mechanism, not a fallback for small samples. It also removes the
asymptotic-approximation question entirely.

---

## Partial identification

**Check:** Where the data cannot pin the quantity down, are bounds reported, or
is a point estimate reported as though identification were complete?

**How:** Construct the bounds under the weakest defensible assumptions (Manski),
report them, and **keep them separate from sampling uncertainty**. A single
interval that mixes "what the data cannot tell us" with "how much the sample
might vary" communicates neither. Format: `point [ID bounds] (sampling CI)`.

---

## Robustness, framed usefully

**Check:** Does the robustness section establish where the published estimate
sits in the family of defensible specifications, or does it only assert survival?

**How:** Run the family — alternative denominators, weighting schemes, sample
restrictions, functional forms — and report all of them. The strong finding is
not "the result survives" but "the published specification is the *conservative*
member, and a reader who preferred any alternative would conclude something
larger". That is a claim a reader can check and cannot dismiss.

In the motivating case the headline coefficient was 2.809 published, 3.010 after
dropping the least precise units, and 3.080 visit-weighted — six specifications,
the published one smallest. Stating that is worth more than six sentences saying
each alternative was also significant.

**And gate it.** A robustness claim in prose goes stale. A robustness script
that *fails the build* when the published estimate stops being the smallest of
the family cannot.
