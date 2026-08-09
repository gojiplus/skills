# The pre-analysis plan

A PAP is not a promise to be inflexible. It is a record of which decisions were made before the
data could influence them, so that a reader can tell your confirmatory results from your
exploratory ones. Deviating is fine. Deviating silently is the problem.

## When it is credible, and what to do when it is not

| situation | what makes the PAP credible |
|---|---|
| experiment, data not yet collected | registration timestamp precedes collection |
| prospective observational study | registration precedes the outcome period |
| restricted-access data | the access request and the plan precede the data release |
| **data already on your disk** | nothing. Registration cannot prove you had not looked |

For the last row — most secondary-data work — pre-registration is theatre unless you do something
structural. The options, in order of preference:

1. **Split the sample.** Draw a held-out confirmation sample *before* any exploration, seal it,
   develop the whole analysis on the exploratory half, then run the frozen plan once on the
   held-out half and report both. Costs power; buys an honest test. Say in the paper that you did
   it and give the seed.
2. **Hold out a period or a geography** rather than a random half, when that is the more natural
   out-of-sample test and you can argue the units are comparable.
3. **Register the plan anyway and be explicit about what you had already seen.** A PAP that says
   "I have examined the treatment variable's distribution and the outcome's time series but have
   run no regression of Y on D" is a weaker guarantee than a split sample and a much stronger one
   than silence.

Never claim more than the timing supports.

## The template

```markdown
# Pre-analysis plan: <project>

Committed <date>, tag `pap-v1`, commit <sha>.
Data state at freeze: <what has been examined, and what has not>.

## 1. Question and estimand
<the seven-part estimand: unit, population, treatment, outcome, contrast,
 aggregation and weighting, time window>

## 2. Identification
Assumption: <one sentence>
Would be violated if: <one sentence>
Observable implication I will check: <one sentence>
If it fails: <what the claim degrades to>

## 3. Hypotheses, with predicted sign AND magnitude
| # | hypothesis | outcome | predicted sign | predicted magnitude | basis for the prediction |
|---|-----------|---------|----------------|---------------------|--------------------------|
| H1 | ... | primary | + | 3-8pp on a base of 11% | Bhavnani 2009 reports X; our sample is Y |

## 4. Primary specification
<the exact regression, written out, with the control set fixed>
Sample: <inclusion and exclusion rules, with expected N>
Estimator: <function call, verbatim>
vcov: <explicit, with the design reason>
Clusters: <level>, expected <k> total and <k_treated> treated

## 5. What else should be true
### Placebo outcomes
### Placebo populations / periods
### Negative control exposure / negative control outcome
### Dose-response and heterogeneity the mechanism implies
### Falsification checks the design demands (balance / pre-trends / density)

## 6. Multiplicity
Primary outcome per family: <one each>
Index construction: <Anderson inverse-covariance, components listed>
Adjustment: <Romano-Wolf FWER | sharpened FDR q-values>, applied to <which family>
Subgroups, exhaustive list: <...>. Anything else is exploratory.

## 7. Design analysis
MDE at 80% power: <x>
At a plausible true effect of <d>: power <p>, Type S <s>, exaggeration <m>

## 8. Missing data and attrition
Policy: <complete case | indicator-and-impute | MI>, expected N under each
Attrition bounds if applicable: <Lee | Manski>

## 9. What would change my mind
<the result that would make me abandon the hypothesis, stated now>

## 10. Deviations
<empty at freeze; every later change appended with date, reason, and what the
 pre-specified version showed>
```

Section 9 is the one people skip and the one that does the most work. A hypothesis that no
possible result would disconfirm is not a hypothesis.

Section 10 is why the file is committed rather than registered and forgotten: the deviation log is
the artifact the paper's appendix reproduces.

## Predicting magnitudes

The hardest part, and the point. Sources for a prior, in order:

- the closest existing estimate, with its interval, from a primary source you have read;
- the same mechanism in a different setting, adjusted for the obvious differences;
- an accounting or budget constraint that bounds the effect from above;
- the effect of a known comparable covariate in your own data.

Write the range you would be surprised to fall outside, not the range you think is plausible.
Those differ, and the second is always wider than people admit.

If every number from 0 to 20pp would have counted as confirmation, the hypothesis is not testable
and the PAP should say so rather than pretend.

## The freeze

```bash
git add pap.md
git commit -m "PAP: freeze before any outcome model"
git tag -a pap-v1 -m "pre-analysis plan, frozen"
git push --tags
```

**The tag is a discipline device, not a timestamp.** Git tags are mutable, commit dates are
settable with `GIT_COMMITTER_DATE`, and a tag can be force-moved. It stops *you* from quietly
revising the plan, and it gives the deviation log something to diff against — that is worth
having, and it is all it is worth.

The credible timestamp is **third-party registration**: OSF Registries, the AEA RCT Registry, or
EGAP, each of which stamps immutably and supports versioned amendments. Register there and
reference this commit hash from the registration, not the other way round. If the work is not
registered anywhere, say in the paper that the plan is self-attested and that a reader should
weight it accordingly.

**After the freeze, `git log --diff-filter=A -- '*outcome*' '*main*'` should show every
outcome-model script created after the tag.** If one predates it, say so.

## Split-sample mechanics

```r
set.seed(1234567)
holdout <- sample(unique(df$gp_code), size = round(0.3 * n_distinct(df$gp_code)))
explore <- df |> filter(!gp_code %in% holdout)
saveRDS(holdout, here("data", "holdout_keys.rds"))     # committed, never opened
```

Split on the **clustering unit**, not on rows, or the two halves share clusters and the
confirmation is not independent. Commit the key list so the split is verifiable. Do not load the
confirmation half in any exploratory script — a `stopifnot(!any(df$gp_code %in% holdout))` at the
top of each one makes that a check rather than an intention.

Report both halves in the paper. The exploratory half is where the specification came from and it
should be presented as such; the confirmation half is the test.
