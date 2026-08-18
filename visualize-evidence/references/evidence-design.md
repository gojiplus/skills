# Evidence-design foundations

Load this reference when chart choice is ambiguous, model output or uncertainty is central, several panels must work together, a map is proposed, or a project needs one visual system. It translates five bodies of work into decisions. Do not imitate an author's surface style mechanically.

## Working synthesis

Use the authors together in this order:

1. **Healy and Gelman — define the task.** State the comparison, audience, estimand, universe, and uncertainty. Decide whether the exhibit is exploratory, diagnostic, or communicative.
2. **Wickham — construct the display.** Make data, transformations, marks, mappings, scales, coordinates, facets, and theme explicit. Keep statistical computation separate from cosmetic styling.
3. **Jackman and Gelman — carry the distribution through.** Plot quantities readers can interpret, propagate uncertainty through predictions or contrasts, and inspect computation and model fit before publishing summaries.
4. **Tufte and Healy — edit the evidence.** Preserve truthful scales and necessary scaffolding, remove decoration that competes with evidence, label directly, and keep related evidence within one eyespan.
5. **All five — iterate.** Render at delivery size, ask what comparison the eye now makes, and revise. A grammatically valid or attractive plot can still answer the wrong question.

Do not turn these ideas into slogans. In particular, "maximize data-ink" does not mean erase axes or uncertainty; "use graphs" does not mean replace a small lookup table; and "show the posterior" does not excuse a poorly identified or poorly fitting model.

## Typography, color, and house style

Treat typography and color as semantic infrastructure. Establish one project theme, but tune its sizes and weights to the delivery medium rather than copying values from a book or website.

### A defensible default

- Use a white or very light neutral background with black or near-black essential text. Reserve gray for secondary notes, grids, and context; do not make axis labels, denominators, or uncertainty annotations faint.
- Use one highly legible family across titles, labels, captions, and tables. A neutral sans serif works well for compact empirical exhibits. Use a condensed face only when labels are crowded and the face remains readable at final size.
- Prefer a regular face for most text and semibold or bold for a short title or facet header. Avoid using light font weights for small text and avoid italics for long labels.
- Left-align titles and subtitles with the plotting panel. Use sentence case. Keep captions visually subordinate but fully readable.
- Start around 10--12 points for print figures only as a working value; render the composed page and raise it when the final artifact is hard to read. Slides and dashboards require substantially larger type.
- Use black or near-black for the main estimate and a lighter, still visible stroke for intervals. Use a single accent for the comparison named in the title; render other observations in neutral gray.
- Keep panel grids thin and light, but retain the grid lines needed to recover values. Remove grids from maps when coordinates are not part of the question.
- Use sequential, diverging, and qualitative palettes only for the corresponding data types. Do not use a diverging palette unless the midpoint has substantive meaning.
- Ensure color is redundant with position, label, line type, or facet when a distinction must survive grayscale or color-vision deficiency.
- For web delivery, require at least 4.5:1 contrast for ordinary text, 3:1 for large text, and 3:1 for meaningful graphical objects against adjacent colors. Check the actual foreground/background pairs and avoid hairlines whose antialiasing makes nominal contrast illusory.
- Embed or subset the selected fonts in PDF/SVG outputs, or use a reliable fallback stack. Re-open the exported artifact and check substitution, kerning, clipping, and symbol coverage.

### Healy-informed theme

Healy's current `myriad` theme is a useful worked example, not a universal prescription. It uses Myriad Pro SemiCondensed for general plot text, a semibold variant for titles, and Myriad Pro Condensed for dense in-plot labels. Its code uses black text on white, `gray10` axes and ticks, `gray90` 0.1-width grids, blank panel borders, a top horizontal legend, a left-aligned bold title at 1.4 times the base size, a subtitle at 1.25 times, and a caption at 0.9 times. The map variant removes axes, ticks, borders, and grids because those marks do not describe the mapped coordinate task.

Do not make Myriad Pro a project dependency unless the font is licensed, installed in every build environment, and embedded correctly. Healy's package explicitly does not distribute the Adobe font and falls back to Helvetica Neue. Preserve the relationships—legible semi-condensed text, clear hierarchy, neutral ink, light scaffolding—with a portable project font when necessary.

### Jackman-informed model and diagnostic style

Jackman does not publish a general theme or branded palette. His canonical simulation examples instead provide a functional statistical style:

- Pair related diagnostic and inferential views in aligned columns, such as trace plots on the left and posterior histograms on the right.
- Use black traces and outlines, medium-gray histogram bars, thin dotted reference densities or thresholds, and black ticks for selected posterior quantiles.
- Keep axes compact and directly named with the parameter or transformed quantity. Use repeated panel structure instead of decorative color.
- Put detailed decoding information in the caption: retained iterations, reference distribution, smoother, and quantiles.
- Use joint two-parameter traces and likelihood contours when marginal plots would hide correlation or slow exploration of the parameter space.

Treat this as evidence of a grayscale-first diagnostic grammar, not as proof that Jackman recommends Helvetica, a specific gray, or colorlessness for all exhibits. His plotted labels were produced in Helvetica by the software of the period, while the surrounding document used other typefaces. Modernize the pattern with a project font and accessible colors when color distinguishes chains, groups, or computational warnings.

Sources: Kieran Healy, [`myriad` themes and font notes](https://kjhealy.github.io/myriad/) and [theme source](https://github.com/kjhealy/myriad/blob/main/R/myriad.r); Simon Jackman, [Bayesian Modeling in the Social Sciences, especially Figures 9--12](https://web.stanford.edu/class/polisci203/icpsr99.pdf); W3C, [WCAG 2.2 text contrast](https://www.w3.org/WAI/WCAG22/Understanding/contrast-minimum) and [non-text contrast](https://www.w3.org/WAI/WCAG22/understanding/non-text-contrast.html).

## Hadley Wickham: make the construction explicit

### Principles

- Treat a statistical graphic as a composition of data, aesthetic mappings, geometric marks, statistical transformations, scales, coordinates, facets, and theme. This makes design choices inspectable and reusable rather than a sequence of pixel edits.
- Distinguish **mapping** a variable to an aesthetic from **setting** a constant appearance. A legend should exist only for a data mapping.
- Treat a statistical transformation as part of the claim. State whether a line is raw, binned, smoothed, modeled, normalized, or aggregated; do not let a convenient `stat` silently change the estimand.
- Use layers when different evidence belongs in the same coordinate system: raw observations, a summary, uncertainty, and a reference value. Each layer may use different data, but it must serve the same comparison.
- Use facets to ask whether a pattern repeats across conditions. Fixed scales support between-panel comparison; free scales support within-panel detail. If scales differ, signal that choice clearly.
- Iterate in the grammar: change the encoding or transformation before polishing the theme.

### Tools and idioms

- In R, use `ggplot2`: `aes()` for mappings; `geom_*()` for marks; `stat_*()` for computed summaries; `scale_*()` for data-to-visual mappings and guides; `coord_*()` for coordinate systems; `facet_wrap()` or `facet_grid()` for small multiples; and `theme()` only for non-data appearance.
- Use small or hollow points, alpha, jitter, 2-D bins, hex bins, or explicit summaries when overplotting hides multiplicity. Each solves a different density problem; inspect the result instead of choosing mechanically.
- Keep the summary data inspectable when a publication number matters. Precompute estimates and intervals rather than hiding consequential calculations inside a plotting call.

### Representative examples

- Build a scatterplot as raw points plus a fitted line and interval, making the model layer visually subordinate to the observations.
- Split the same relationship into fixed-scale facets to test whether it persists across groups.
- Replace an unreadable large scatterplot with hex bins when the question is local observation density, not individual identity.

### Checks

- Can every aesthetic be traced to either a named variable or a deliberate constant?
- Does the selected `stat` compute the quantity named in the caption?
- Are scales comparable across the facets where the prose compares panels?

Primary sources: Hadley Wickham, [A Layered Grammar of Graphics](https://vita.had.co.nz/papers/layered-grammar.pdf); Hadley Wickham, Danielle Navarro, and Thomas Lin Pedersen, [ggplot2: Elegant Graphics for Data Analysis, third edition](https://ggplot2-book.org/); Hadley Wickham, Mine Çetinkaya-Rundel, and Garrett Grolemund, [R for Data Science, second edition: exploratory data analysis](https://r4ds.hadley.nz/EDA).

## Kieran Healy: join perception, substance, and workflow

### Principles

- Diagnose bad graphics in three separate dimensions: aesthetic, substantive, and perceptual. Restyling cannot repair the wrong denominator, and correct data can still be encoded in a way people cannot compare reliably.
- Design for a viewer and a task. An exploratory plot for the analyst may be dense and diagnostic; a publication plot should make one comparison recoverable without reconstructing the analysis.
- Prefer position on a common scale for ordered quantitative comparisons. Length is generally weaker, while area, angle, volume, and unstructured color intensity invite larger decoding errors.
- Match color to data type: sequential for low-to-high, diverging around a meaningful midpoint, and qualitative for unordered groups. Use perceptually ordered palettes and verify grayscale and color-vision accessibility.
- Look at raw data, missingness, marginal distributions, and group structure throughout modeling. Visualization is part of discovery and diagnosis, not merely presentation.
- For model results, show either coefficients with uncertainty or predictions/contrasts on a substantively interpretable scale. The hard part is computing the right quantity, not drawing it.
- Refine appearance last and centralize it in a theme. Reproducible project paths and scripted exports are part of the visual workflow.

### Tools and idioms

- Use `ggplot2` for construction, `broom`-style tidy model summaries when supported, `scales` for honest unit labels, and collision-aware direct labeling when labels are necessary.
- Use `geom_pointrange()` or its equivalent for compact coefficient displays; plot predictions and uncertainty ribbons when interactions or nonlinear links make coefficients hard to interpret.
- Use project-relative, scripted vector or high-resolution exports. Check the saved artifact, not just the interactive preview.
- Use Healy's `socviz` and `myriad` packages as inspectable examples of a shared plot theme, map theme, and font setup, not as required dependencies. Reproduce the design relationships in the project's native plotting system.

### Representative examples

- Separate aesthetic, substantive, and perceptual failures in a "junk" chart before redesigning it.
- Turn a coefficient table into an ordered horizontal point-and-interval plot.
- Compare a U.S. choropleth with population density and a nonspatial ranked display to reveal when geography mostly reproduces settlement patterns.

### Checks

- Is the apparent visual ordering the ordering in the data?
- Is the palette appropriate to ordered, diverging, or categorical data?
- Does the finished graphic retain the raw-data or model context needed to judge the claim?

Primary sources: Kieran Healy, [Data Visualization: A Practical Introduction](https://socviz.co/); Kieran Healy and James Moody, [Data Visualization in Sociology](https://kieranhealy.org/files/papers/data-visualization.pdf); Kieran Healy, [America's Ur-Choropleths](https://kieranhealy.org/blog/archives/2015/06/12/americas-ur-choropleths/).

## Simon Jackman: visualize simulated inference, not just coefficients

Jackman's contribution here is principally inferential rather than a general-purpose design grammar. Apply it when results come from simulation, latent-variable models, hierarchical models, or transformed model quantities.

### Principles

- Treat posterior simulation as a way to estimate distributions of any scientifically relevant function of parameters: predicted values, contrasts, residuals, goodness-of-fit quantities, ranks, or thresholds. Do not stop at raw coefficients merely because software prints them first.
- Transform every retained draw and summarize afterward. This propagates dependence and nonlinearity; transforming a point estimate and attaching a symmetric standard error generally does not.
- Show the distribution when skew, multimodality, bounds, or tail risk matters. A point and one interval are a lossy summary, not the posterior itself.
- Inspect simulation before interpreting it. Trace, rank, autocorrelation, joint-parameter, and convergence views answer computational questions; posterior or predictive views answer substantive ones. Keep those roles distinct.
- Compare prior, likelihood, and posterior when sensitivity or identification matters. If plausible priors materially change the result, make that visible.
- Label Bayesian intervals as credible or posterior intervals and state their probability mass and construction. Do not call them confidence intervals.

### Tools and idioms

- Work from retained draws, not rounded summary tables. Use interval/density plots for marginal summaries, joint plots for dependent quantities, and trace/rank plots for computation.
- Modern R implementations include `posterior` for draws and diagnostics and `bayesplot` for interval, density, MCMC diagnostic, prior-predictive, and posterior-predictive displays. Equivalent diagnostics in another ecosystem are acceptable when they expose the same quantities.
- Use nested intervals, such as 50% plus 90% or 95%, or densities when shape matters. State whether intervals are central quantile intervals or another defined construction.
- Default diagnostic plots to neutral ink and aligned panels. Introduce color only when it carries a named role, such as distinguishing chains or flagging divergent transitions; never use hue merely to make each parameter different.

### Representative examples

- Plot prior, likelihood, and posterior for a binomial proportion to expose prior sensitivity.
- Pair trace plots with posterior histograms for a voter-turnout probit or time-series model; use a joint trace when correlated parameters mix slowly.
- Simulate a predicted probability or counterfactual contrast for every posterior draw, then plot its posterior distribution on the outcome scale.

### Checks

- Was the plotted substantive quantity computed for every draw?
- Do diagnostics support treating the draws as a representation of the target distribution?
- Could a marginal interval conceal dependence, multimodality, or a consequential tail?

Primary sources: Simon Jackman, [Estimation and Inference Are Missing Data Problems: Unifying Social Science Statistics via Bayesian Simulation](https://doi.org/10.1093/oxfordjournals.pan.a029818); Simon Jackman, [Bayesian Analysis for the Social Sciences](https://bcs.wiley.com/he-bcs/Books?action=index&bcsId=5422&itemId=0470011548); Simon Jackman, [Bayesian Modeling in the Social Sciences course notes and graphical examples](https://web.stanford.edu/class/polisci203/icpsr99.pdf). Modern implementation references: [bayesplot](https://mc-stan.org/bayesplot/) and [posterior](https://mc-stan.org/posterior/).

## Andrew Gelman: organize comparisons and expose model implications

### Principles

- Begin with the comparisons a reader should make. Use spatial adjacency, alignment, ordering, common scales, and relevant baselines to put those comparisons next to one another.
- Use tables for exact lookup and graphs for patterns or many comparisons. A graph is not automatically superior; choose based on the reader's task.
- Order categories substantively or by a relevant value, not alphabetically or by arbitrary identifiers. Put verbal labels on the axis and use direct labels where practical.
- Prefer several simple, aligned plots over one overloaded plot. Small multiples can show raw data, estimates, uncertainty, and alternative specifications without turning each distinction into a legend code.
- Foregrounded comparisons need uncertainty. Do not invite readers to compare slopes, subgroups, or time trends while withholding the uncertainty of the comparison itself.
- Treat graphs as model checks. Compare observed data with data simulated under the model, targeting distributions or test quantities relevant to the scientific question.
- Be skeptical of maps of point estimates. Unequal sample sizes, area, and partial pooling can create or suppress apparent hot spots. Show support and uncertainty and pair the map with a nonspatial display.
- For unfamiliar or abstract models, climb a ladder of abstraction: begin with concrete special cases, then embed them stepwise in the more general display.

### Tools and idioms

- Use ordered dot plots, coefficient plots, calibration plots, residual displays, small multiples, and observed-versus-replicated predictive checks.
- In Bayesian work, use `bayesplot` or equivalent tools for prior predictive checks, posterior predictive overlays, interval plots, and visual MCMC diagnostics. Choose a check tied to a possible model failure rather than cycling through defaults.
- For maps, show sample size or standard error, use multiple imputations or uncertainty views when appropriate, and include a ranked interval plot for accurate comparison.

### Representative examples

- Convert a dense regression table into horizontal, directly labeled estimate-and-interval panels ordered by the comparison of interest.
- Place observed data beside replicated datasets or overlay an observed statistic on its predictive distribution.
- Contrast a choropleth of county point estimates with support-aware or multiply imputed maps to reveal sample-size artifacts.
- Explain a complex trajectory by first plotting one case, then several cases, then the full general model.

### Checks

- What exact comparison does adjacency or ordering invite?
- Does the displayed uncertainty apply to that comparison rather than only to separate point estimates?
- Could sample size, geographic area, or the model's pooling structure explain the visible pattern?

Primary sources: Andrew Gelman, Cristian Pasarica, and Rahul Dodhia, [Let's Practice What We Preach: Turning Tables into Graphs](https://sites.stat.columbia.edu/gelman/research/published/dodhia.pdf); Jonah Gabry, Daniel Simpson, Aki Vehtari, Michael Betancourt, and Andrew Gelman, [Visualization in Bayesian Workflow](https://arxiv.org/abs/1709.01449); Andrew Gelman and Philip N. Price, [All Maps of Parameter Estimates Are Misleading](https://sites.stat.columbia.edu/gelman/research/published/allmaps.pdf); Andrew Gelman, [The Ladder of Abstraction in Statistical Graphics](https://arxiv.org/abs/2501.06920).

## Edward Tufte: increase evidential resolution and graphical integrity

### Principles

- Make changes in the graphic proportional to changes in the data. Avoid truncated or nonlinear encodings that manufacture an effect, unexplained area encodings, 3-D decoration, and any visual dimension not backed by a data dimension.
- Use the data-ink ratio as an editing question: does this mark carry data, organize a necessary comparison, or explain the evidence? Remove it only when the answer is no. Necessary axes, uncertainty, labels, and grouping cues are not junk.
- Favor high-resolution displays: many relevant observations, variables, or time points within one eyespan. Data density is useful only when the display remains legible and comparisons remain valid.
- Use small multiples with a stable grammar and scale so variation in the display comes from variation in the evidence.
- Layer and separate complex information. Use position, whitespace, line weight, and restrained color to establish hierarchy without heavy boxes, repeated legends, or background ornament.
- Integrate words, numbers, and graphics. Put labels and short explanations next to the evidence they describe; do not force a reader to shuttle between a plot and a remote key.
- Use the smallest effective visual difference. Accents should mark substantive distinctions, not decorate every category.
- Use sparklines or compact sequences when local history belongs beside a number or row, retaining common scale and nearby quantitative context.
- Document provenance and analytic choices sufficiently to let a reader assess credibility and selection. Evidence design includes the data-generating and analysis process, not just marks on a page.

### Tools and idioms

Tufte's tools are design operations rather than a software stack: direct labeling, de-gridding, small multiples, micro/macro layouts, thin rules, restrained accent color, sparklines, adjacent annotations, and source notes. Implement them in the project's existing plotting system; do not install a "Tufte theme" and assume the work is done.

### Representative examples

- Use Minard's Napoleon campaign graphic to study how geography, direction, army size, temperature, and time can coexist in one evidence-rich narrative—not as a template for adding variables indiscriminately.
- Put aligned sparklines beside current values in a monitoring table so recent readings retain historical context.
- Replace heavy table grids with alignment, whitespace, and fine rules while preserving scan paths and exact values.

### Checks

- Does every prominent visual difference correspond to a substantive data difference?
- Can words, numbers, and marks be read together without legend lookup or page turning?
- Did simplification remove scaffolding or uncertainty needed for truthful interpretation?

Primary sources: Edward R. Tufte, [The Visual Display of Quantitative Information](https://www.edwardtufte.com/book/the-visual-display-of-quantitative-information/); Edward R. Tufte, [Envisioning Information](https://www.edwardtufte.com/book/envisioning-information/); Edward R. Tufte, [Beautiful Evidence](https://www.edwardtufte.com/book/beautiful-evidence/); Edward R. Tufte, [Sparkline Theory and Practice](https://www.edwardtufte.com/notebook/sparkline-theory-and-practice-edward-tufte/); Edward R. Tufte, [Making Better Inferences from Statistical Graphics](https://www.edwardtufte.com/notebook/making-better-inferences-from-statistical-graphics-edward-tufte/).

## Reusable exhibit patterns

### Estimates across groups

Use an ordered horizontal dot-and-interval plot. Put the estimand and unit on the axis, use a meaningful zero or parity line, identify unsupported cells, and state the interval method. Add a second nested interval only if it improves distributional reading.

### Two measurements per unit

Use a slopegraph or dumbbell when within-unit change is the estimand. Sort by baseline, endpoint, or change according to the question. Label endpoints directly and avoid connecting lines if they falsely imply continuous trajectories.

### Raw data plus model

Show observations with a fitted relation and uncertainty. Use transparency, bins, or small multiples when points overlap. If the model is nonlinear or includes interactions, prefer predicted outcomes or contrasts over isolated coefficients.

### Bayesian result

First inspect trace/rank and model diagnostics. Then plot a posterior distribution or nested intervals for a substantively interpretable quantity. For model checking, compare observed data with replicated data using a feature chosen because the model could plausibly miss it.

### Map

Spatial data do not automatically require a map. Use one when location, coverage, or spatial pattern is the question. Before mapping an outcome, ask:

1. Would an ordered dot-and-interval plot answer the comparison more accurately?
2. Does geographic area, population density, route density, sample size, or uneven coverage dominate the visible pattern?
3. Is the geographic unit substantively defensible?
4. Are sparse, missing, suppressed, and uncertain cells visible?
5. Does the caption distinguish sampled units, traversed routes, observation points, and boundaries?

For coverage maps, use a quiet base, one restrained accent, direct place labels, and an explicit count of observations without valid coordinates. For outcome maps, define a support rule, show missing or suppressed cells, use a perceptually ordered scale, and accompany the map with a nonspatial comparison. Do not narrate local clusters that sparse coverage or arbitrary bins could produce.

### Dense table or monitoring display

Use a table when exact retrieval matters. Align decimals, group related columns, de-emphasize rules, and add compact within-row sequences only when they supply context that the point value lacks. Maintain a common scale across sparklines meant for comparison.
