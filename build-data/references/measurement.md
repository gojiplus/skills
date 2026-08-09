# Measurement: from construct to column

A column is a claim that some number stands for something in the world. Most of the effort in
empirical social science goes into estimation, and most of the damage comes from the step before
it — where a construct became a variable and nobody wrote down the correspondence, tested it, or
propagated its error.

## Write the construct before the column

Three lines, in the dictionary, for every constructed variable:

```
CONSTRUCT   what you claim to be measuring, in words, without naming a variable
MEASURE     the operation that produces the number
GAP         what the measure captures that the construct does not, and vice versa
```

The GAP line is the one that does work. "Political participation" measured as turnout omits
everything between elections and includes compelled voting; "state capacity" measured as tax/GDP
is partly a measure of what is taxable. Write the gap, then decide whether the claim you want to
make survives it.

## Reliability

Reliability is consistency: would the same unit get the same value again? It bounds validity — an
unreliable measure cannot be valid — but it is not validity. A thermometer reading 5 degrees too
high every time is perfectly reliable.

### Internal consistency across items

**Cronbach's α**, with its limits stated rather than ignored:

```r
psych::alpha(df[, items])        # $total$raw_alpha, $total$std.alpha, plus alpha-if-dropped
```

- α is a **lower bound** on reliability, and only equals it under tau-equivalence (all items load
  equally). That assumption is almost never true and almost never checked.
- α rises mechanically with the **number of items**. A twenty-item scale with α = 0.85 can be
  less coherent than a four-item scale with α = 0.75.
- α says nothing about dimensionality. A two-factor scale can have high α.
- The conventional 0.70 cut-off has no theoretical basis and is not a pass mark.

**McDonald's ω is the better default**, because it does not assume tau-equivalence:

```r
psych::omega(df[, items], nfactors = 1)   # omega_h (hierarchical) and omega_t (total)
```

Report ω with α, the item-total correlations, and a factor analysis showing the scale is
one-dimensional if you intend to treat it as one. If it is not one-dimensional, the sum score is
not a measure of one thing and the coefficient on it is not a coefficient on one thing.

### Agreement between coders

For hand-coded or LLM-coded categorical variables, percent agreement is not enough — it is
inflated by the base rate. Use a chance-corrected statistic:

| statistic | when | R |
|---|---|---|
| Cohen's κ | two coders, nominal | `psych::cohen.kappa()` |
| Fleiss' κ | three or more coders, nominal | `irr::kappam.fleiss()` |
| Krippendorff's α | any number of coders, any level, tolerates missing | `irr::kripp.alpha()` |
| ICC | continuous ratings | `psych::ICC()` |

Krippendorff's α is the general default. Report it per category as well as overall: an α of 0.80
driven by a common category while the rare, substantively interesting one sits at 0.35 is the
usual pattern, and the rare category is often the one the paper is about.

### Test-retest and split-half

Where the same unit is measured twice — two waves, two enumerators, two crops of the same
document — the correlation between the two readings bounds error from above and is worth more
than any internal-consistency statistic. This is also the cheapest thing to build into a data
collection and the most commonly omitted.

## Validity

| kind | question | how you show it |
|---|---|---|
| face / content | does it look like the construct, and cover it? | expert review; a coverage table of construct facets against items |
| convergent | does it correlate with measures of the same thing? | correlation with an accepted measure, with a number |
| discriminant | does it fail to correlate with different things? | correlation with a construct it should *not* track |
| criterion / predictive | does it predict what the construct should predict? | out-of-sample prediction of a known outcome |
| known-groups | does it separate groups known to differ? | difference between groups where the answer is not in doubt |

Convergent evidence alone is weak: almost everything in social data correlates with almost
everything. **Discriminant validity is the part that discriminates**, and it is the part usually
skipped. Report at least one correlation you expected to be near zero and that was.

Known-groups is the cheapest strong test and connects directly to `design-analysis`: it is the
same logic as a placebo, run on the measure instead of the effect.

## What measurement error does to your estimate

The folk rule "measurement error attenuates" is true only in one specific case, and the cases it
excludes are the ones that hurt.

| where the error is | structure | consequence |
|---|---|---|
| continuous regressor of interest | classical (mean zero, independent of truth and of the outcome error) | attenuation toward zero, by the reliability ratio |
| continuous regressor, several regressors | classical in one | bias in **all** coefficients, in either direction |
| outcome | classical | precision loss, no bias |
| outcome | correlated with treatment | bias in either direction |
| **binary treatment** | misclassification | **not** simple attenuation; with differential misclassification the sign can flip |
| control variable | any | incomplete control; residual confounding survives adjustment |

The binary case is worth dwelling on. Misclassification in a binary regressor is necessarily
non-classical — the error is negatively correlated with the true value, because a unit coded 1 can
only be wrong downward. Under *non-differential* misclassification the bias is toward the null;
under **differential** misclassification, where the error rate differs by outcome or by arm, the
estimate can be biased in either direction and can exceed the truth. This is the case that
LLM-coded treatment variables fall into.

The fix, when you have a validation subsample, is not to apologise in a footnote. It is to
propagate — see `design-analysis`'s inference reference and the DSL section below.

## Machine- and LLM-coded variables

An LLM used to label documents is a **measurement instrument**, and the model version, the prompt,
the temperature, and the parsing code are all part of it. Pin all four, record them in the
dictionary's provenance field, and treat a model upgrade as a change of instrument that requires
re-validation — not as a free improvement.

### Test it behaviourally, not just on accuracy

Held-out accuracy on a convenience sample overstates performance, and it will not tell you *how*
the instrument fails. Ribeiro et al.'s CheckList framework transfers directly to social-science
coding. Three test types, each cheap to write:

- **Minimum functionality (MFT)** — small, unambiguous cases the instrument must get right.
  Hand-write twenty documents whose label nobody would dispute. If it misses these, nothing else
  matters.
- **Invariance (INV)** — perturbations that must *not* change the label: swap a name for another
  of the same category, change a date, reorder clauses, switch dialect or transliteration. A
  label that moves when the speaker's name changes from one caste-marked surname to another is
  measuring the name.
- **Directional expectation (DIR)** — perturbations that must move the label a known way:
  intensify the sentiment, add the exact phrase the codebook says triggers the category. Failure
  here means the instrument is not tracking the construct even when it is accurate on average.

Write these as a test file, run them on every prompt or model change, and report the results next
to the accuracy number. INV tests over the demographic attributes in your data are also your
differential-error check: run them by group, because an instrument with 90% accuracy overall and
78% on one group produces a finding about that group out of thin air.

### Do not put raw LLM labels into a regression

This is the important one. Even at 80–90% surrogate accuracy, using LLM labels directly as a
variable in a downstream analysis produces **substantial bias and invalid confidence intervals**
(Egami, Hinck, Stewart and Wei, NeurIPS 2023). Accuracy that sounds high is not high enough,
because the errors are not random with respect to the covariates you care about.

The correct procedure:

1. Label everything with the LLM (cheap, biased).
2. Draw a **random** subsample with a known, controlled sampling probability and hand-label it
   (expensive, gold).
3. Estimate with **design-based supervised learning** (`dsl` in R, `naokiegami.com/dsl/`), which
   combines the two doubly-robustly and gives valid standard errors even when the surrogate is
   arbitrarily biased. Prediction-powered inference (Angelopoulos et al.) is the closely related
   alternative from the statistics side.

The design requirement is that the gold-standard subsample is sampled with a probability you
control, not chosen by convenience or by which documents were confusing. Getting that wrong
forfeits the guarantee.

### The validation subsample

Even without DSL, hand-label a random subsample and report it. Rules of thumb: enough to estimate
the error rate with a usable interval — 100 gives roughly ±10pp on a 50% rate and ±6pp on a 10%
rate — and stratified so each substantively important category has enough cases to have its own
error rate reported. Never report a single overall accuracy for a measure whose error rate you
have not checked by group.
