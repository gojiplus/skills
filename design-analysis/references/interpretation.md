# Interpreting results without leaning on significance

"Significant" compresses an interval into a binary at a threshold nobody chose for this problem,
and the binary is the part that does not replicate. Everything below is about writing the interval
instead — which is harder, because it requires knowing what magnitude would matter.

## The rewrite patterns

| do not write | write |
|---|---|
| "the effect is significant (p < 0.01)" | "quotas raise the probability a woman wins by 6.2pp (95% CI 3.1 to 9.3), on a base rate of 11%" |
| "we find no significant effect" | "the estimate is 0.4pp (CI −1.0 to 1.8); we can rule out effects above 1.8pp, [comparator]" |
| "the effect is not robust" | "the point estimate ranges 4.1–6.8pp across the twelve specifications; every interval excludes zero, and the spread is driven by whether 2015 is included" |
| "marginally significant (p = 0.07)" | "2.9pp (CI −0.2 to 6.0). The data are consistent with anything from a small negative effect to a substantial positive one" |
| "the interaction is significant, so the effect is larger for X" | "the effect is 8.1pp for X (CI 4.0 to 12.2) and 3.2pp for Y (CI −0.5 to 6.9); the difference is 4.9pp (CI −0.7 to 10.5)" |
| "consistent with the theory" | "the theory predicts 3–8pp; the estimate is 6.2pp (CI 3.1 to 9.3), inside that range" |

Two habits carry most of the weight. **Always give the base rate or the outcome mean** — 6.2pp
means nothing until the reader knows whether the baseline is 11% or 71%. And **always report the
interval for the difference**, not two intervals and an eyeball; overlapping intervals do not
imply a non-significant difference and non-overlapping ones are not required for a significant
one.

## Nulls need a comparator

"We can rule out effects larger than 1.8pp" is a number with no referent until you say what 1.8pp
would have meant. The comparator has to be a real number from a primary source you looked up:

- the smallest effect reported in the literature you are speaking to;
- the effect of a comparable policy on the same outcome;
- the cost-effectiveness threshold the programme would need to clear;
- a benchmark from the same data — one standard deviation, the gap between two known groups, the
  effect of a demographic covariate in your own regression.

A comparator you half-remember is worse than none, because it survives into the abstract and
nobody re-checks it. If you cannot find one, say the interval is wide and stop; do not manufacture
a scale.

Where the claim genuinely is "no meaningful effect", say so with an **equivalence test** rather
than a failed null test: pre-specify an equivalence bound `δ`, and report whether the 90% interval
lies entirely inside `(−δ, δ)` (TOST). This is a positive claim with a stated bound, which is what
"no effect" was always trying to be.

## Convert every coefficient into something with units

This is the cheapest bug-finder in the whole workflow and it finds bugs no residual plot will.
Take the coefficient and turn it into an implied count, probability, share, rupee amount, or
number of people. Then check it against a bound:

- more treated units than exist;
- a turnout change larger than the number of registered non-voters;
- a probability outside [0, 1] at a plausible covariate value;
- an implied elasticity two orders of magnitude off the literature;
- a per-capita transfer larger than the programme's total budget.

Each of these has been a real, published error. The arithmetic takes a minute; the alternative is
that a reader does it for you after publication.

Also state the estimand's population when you convert. A within-district coefficient converted
into a national total is a different claim than the regression supports.

## The interval-first exhibit

The coefficient plot is the default figure for every headline result, and the regression table is
the appendix to it, not the other way around:

```r
p <- ggplot(tidy(m, conf.int = TRUE) |> filter(term %in% keep), aes(x = estimate, y = term)) +
    geom_vline(xintercept = 0, linetype = "dashed", colour = "gray50") +
    geom_errorbarh(aes(xmin = conf.low, xmax = conf.high), height = 0,
                   colour = COLORS_PUB["secondary"], linewidth = 0.6) +
    geom_point(size = 2.5, colour = COLORS_PUB["primary"]) +
    labs(x = "Effect on Pr(woman elected), percentage points", y = NULL) +
    theme_pub() + theme(axis.text.y = element_text(hjust = 0))
ggsave(here("figs", "main_coefplot.pdf"), p,
       width = FIG_WIDTH_FULL, height = 3.5, device = cairo_pdf)
```

Three things make it work: the zero line is drawn but not emphasised, the x-axis is in substantive
units with the units named, and one row per specification so the reader sees the spread rather
than being told about it. Where the ladder from `se_ladder.R` matters, plot the rungs as rows —
the reader can then see for themselves whether the conclusion depends on the variance estimator.

Regression tables keep their `$^{***}$p$<$0.01` legends because journals expect them. The prose,
the abstract, the figure, and the output contract do not.

## What "robust" is allowed to mean

Not "the sign survived one alternative specification." A robustness claim needs the family of
specifications defined in advance and the position of the published estimate inside it:

> Across the 24 combinations of {three control sets} × {two samples} × {two clustering levels} ×
> {two functional forms}, the estimate ranges 4.1–6.8pp with a median of 5.9pp. Twenty-two of 24
> intervals exclude zero; the two that do not are the specifications dropping 2015, which removes
> 40% of the treated units.

That is a specification curve in prose, and it is the honest version. Where the family is large
enough to plot, plot it: estimates sorted on top, the specification grid below, so the reader can
see which choice moves the result. What that exhibit is *for* is locating the published estimate
in the distribution — not demonstrating that a distribution exists.

The failure mode to avoid is the multiverse as decoration: running 500 specifications, reporting
that most are positive, and never saying which analytic choice the result actually hinges on.
Name the hinge.
