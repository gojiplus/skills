---
name: visualize-evidence
description: Design or audit empirical figures, tables, and maps. Use for comparisons, uncertainty, units, captions, visual consistency, generated exhibits, or rendered-page quality assurance.
---

# Visualize evidence

Make the comparison easy to see and hard to misread. Treat figures and tables as part of the analysis, not decoration.

## Start from the question

1. State the comparison the exhibit must answer in one sentence.
2. Record the estimand, population or analytic universe, denominator, unit, uncertainty method, and grouping level.
3. Inspect the code, data, current exhibit, caption, and surrounding prose together. Do not redesign from an image alone when the source is available.
4. Render the current paper or report before editing. Page context determines readable type, aspect ratio, and useful detail.

Stop and resolve a construct mismatch before styling. A polished plot of the wrong denominator is still wrong.

## Choose the smallest useful form

- Use a dot-and-interval plot for estimates across groups.
- Use a slopegraph or dumbbell for two values whose difference is the point.
- Use a line only when the horizontal axis is ordered and continuity is meaningful.
- Use a histogram, density, or ECDF for a distribution; show zero masses and top-coding rather than smoothing them away.
- Use small multiples when several groups need the same comparison.
- Use a table when exact values or several units matter more than shape.
- Use a map only when location, spatial coverage, or geographic pattern is the question.

Read `references/evidence-design.md` before choosing among plausible chart forms, presenting model uncertainty, creating multi-panel figures or maps, or redesigning a project's exhibits. It synthesizes Wickham, Healy, Jackman, Gelman, and Tufte into operational guidance, tools, examples, and source-backed checks.

Remove an exhibit that has no distinct question.

## Use one visual grammar

- Encode the same concept the same way across the project. Centralize fonts, sizes, colors, line widths, formats, and export settings in one style module.
- Put group identity in facet titles, row labels, or direct labels. Do not assign arbitrary shapes or colors to cities merely to make a legend.
- Use circles as the default point estimate. Use shape only when shape itself carries a stable, necessary distinction.
- Prefer direct labels to legends. Order rows by a meaningful value or a defensible substantive order.
- Give comparable panels common axes. Do not let independent scales manufacture apparent differences.
- Reserve an accent color for one substantive contrast or reference line. Make the exhibit legible in grayscale and under common color-vision deficiencies.
- Use reference lines only when they represent a real benchmark such as zero or parity. Label the benchmark.
- Put units in axis and column labels. Use sentence case throughout.

## Show uncertainty honestly

- Plot intervals when sampling, design, predictive, or posterior uncertainty matters. Name the level and interval type. Use 95% when convention or the inferential target calls for it; nested 50% and 90% or 95% intervals can better show posterior shape without pretending that one cutoff is special.
- State how the interval was calculated and the clustering or sampling unit in the caption or note.
- Keep wide intervals visible. Imprecision is a result, not a layout problem.
- Omit an interval when the design cannot support one, such as a cell with one cluster, and state why.
- Do not add intervals to a census, deterministic total, or purely descriptive full-universe quantity unless they represent a defined source of uncertainty.

## Make tables read like figures

- Give each table one job. Group rows into labeled blocks when necessary.
- Use booktabs-style rules and no vertical lines. Align numbers on decimals where the format permits.
- Use the same type size, caption style, precision, missing-value symbol, and note structure across tables.
- Report two or three significant digits unless the measurement supports more. Keep precision constant within a column or row.
- Label levels as percentages, differences as percentage points, proportions as proportions, and ratios with both direction and base, such as women per 1,000 men.
- Put denominators and analytic universes in headers or notes. Never make a reader infer whether a row describes people, images, trips, or clusters.
- Use `--` for an unavailable estimate only when the note explains why. Do not print `nan`.

## Write captions that stand alone

State, in this order: what is compared; the analytic universe; what points, lines, bars, or shading mean; the uncertainty method; exclusions or unsupported cells; and any benchmark. Keep interpretation in the prose unless one sentence is required to prevent a misreading.

Use the same construct name in the caption, axes, table, and manuscript. Avoid elegant variation in technical labels.

## Keep the pipeline upstream

- Separate statistical summaries from rendering so tables and figures share one computed source.
- Generate repeated manuscript numbers and exhibit labels from code. Do not hand-copy results into prose when macros or a standard document-generation mechanism can supply them.
- Make style changes in the shared theme before patching individual plots.
- Regenerate every dependent output after changing data cleaning, estimands, labels, or style.
- Keep diagnostic plots distinct from publication exhibits. Do not make every generated image part of the paper.

## Validate at delivery size

1. Run the repository's formatter, linter, tests, and full generation target.
2. Compile the paper or report from a clean-enough state to exercise all dependencies.
3. Render every page containing an exhibit at its actual delivery size.
4. Inspect labels, line breaks, panel order, clipping, whitespace, type size, caption accuracy, and agreement with the text.
5. Check common axes, units, interval support, and missing-value behavior programmatically where possible.
6. Recompile after the last edit and report both automated and visual checks.

Never declare a figure fixed from the standalone asset alone.
