---
name: build-data
description: Prepare an analysis-ready dataset with documented columns, recodes, missing values, and verified joins. Use for unfamiliar data or unreliable data handoffs.
---

# Build an analysis-ready dataset

Produce an analysis-ready file, a data dictionary, a recode ledger, and a join
contract. Use `design-analysis` for open research-design decisions and
`audit-analysis` to verify an analysis that already exists.

## Inspect before transforming

Read source documentation and inspect actual records. Show a small decisive sample
from each key table, its shape, intended row unit, column types, missingness,
common values, and relevant extremes. Write large profiles to a file and show the
slice that needs a decision. For scans, images, or other unstructured sources,
inspect representative artifacts rather than relying on file listings.

Ask about unresolved meanings that affect the analysis: sentinel values, eligible
populations, consequential recodes, the left table, or differential nonmatches.
Show the evidence and recommendation with the question. Carry prior decisions and
authorization forward; do not stop merely to approve profiling or writing files.
When autonomous work is requested, record defensible assumptions and unresolved
questions explicitly. Do not guess an unknowable construct just to finish a file.

## Document the columns

Read [dictionary.md](references/dictionary.md) for profiling and sentinel checks.
For an R workflow, [profile_columns.R](scripts/profile_columns.R) can write a draft
with `--out`; otherwise use the project's existing tools for equivalent checks.
The profile finds candidates, not meanings or verdicts.

For each column record source, type, unit, universe, value set/range, missing codes,
coverage, transformations, and provenance. Distinguish structural absence,
not-asked, refusal, and observed zero. Recover definitions from the source's
codebook, sibling instruments, printed control totals, or a justified benchmark;
label inferred meanings. Inspect extreme-value spikes and group-specific patterns.

State what one row represents and verify the corresponding key. Investigate
repeated rows before deduplicating; legitimate long-form data can repeat an ID.
For panels, establish within-unit coverage and treatment variation before proposing
an estimator. Protect any agreed blinding and record what outcomes were inspected.

Use `audit-analysis`'s data sweep when available for differential missingness,
skew, and denominator checks rather than duplicating its implementation.

## Recode with a ledger

Read [recode.md](references/recode.md) for conditional traps. Put shared recodes in
named functions using the project's language and organization. Print the old-by-new
counts for categorical recodes. Record reference categories, level order,
standardization population, transformations, exclusions, and resulting sample sizes.

Replacing missing with zero requires evidence that zero represents the construct;
check missingness by arm, wave, and other relevant groups. State the missing-data
policy and sample consequences. The direction of a resulting bias depends on the
design and missingness mechanism; do not infer it from a fill rate alone.

## Join under an explicit contract

Before writing the join, record:

1. The left-hand universe and intended output row unit.
2. Keys on both sides and their observed uniqueness.
3. Expected cardinality, row count, and match rate.
4. How unmatched, ambiguous, and repeated records will be handled.

Read [linking.md](references/linking.md). The R helper
[check_join.R](scripts/check_join.R) can enforce the contract. Investigate unexpected
many-to-many expansion; a deliberate many-to-many relation requires an explicit
output unit and expected multiplicity rather than silent row multiplication.

Check row conservation and report matches by relevant group, not just overall.
Show unmatched examples from both sides. For fuzzy linkage, retain candidates,
scores, decisions, and ambiguous cases for review. Estimate precision and recall
on an independently labeled evaluation sample that can detect both false matches
and missed true matches. A high match rate is not evidence of accurate linkage.
Re-profile the joined data because joining changes its coverage and missingness.

## Treat generated measurements as instruments

For model scores, LLM labels, scales, or probabilistic links, read
[measurement.md](references/measurement.md). Document the construct, measurement
procedure, model/prompt/parser versions, and reliability/validity evidence.
Evaluate relevant groups and account for downstream measurement uncertainty.
Record training, calibration, evaluation, and analysis samples and enforce the
separation or cross-fitting required by the chosen method. A model update changes
the instrument and needs validation.

## Store and hand off

Read [storage.md](references/storage.md). Prefer Parquet for typed analytical
handoffs and JSONL for cached raw responses. Use explicit schemas when consuming or
exporting CSV, especially for IDs, missing values, dates, and large integers. Verify
important values survive a round trip. Preserve raw inputs and record producing
scripts and source versions. Follow the existing repository layout.

Deliver the file path, row count and row definition, completed dictionary, recode
ledger, join results, meaningful checks run, and unresolved source questions.
Report the decisions and evidence that support the handoff, rather than calling
the data clean without qualification. Background sources: [sources.md](references/sources.md).
