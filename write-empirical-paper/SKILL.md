---
name: write-empirical-paper
description: Coordinate revision of a quantitative empirical paper and repository. Use for analysis audits, prose, figures, tables, citations, compilation, rendered-page checks, and claim validation.
---

# Write an empirical paper

Coordinate existing specialist skills. Do not duplicate their full guidance here.

## Load the specialists

Load and apply these skills when available:

1. `audit-analysis` for data integrity, estimands, inference, robustness, and manuscript-to-code agreement.
2. `on-writing` for organization, paragraphs, sentences, voice, and editorial triage.
3. `visualize-evidence` for figures, tables, maps, uncertainty, captions, and rendered-page QA.

If the analysis has not yet been run and the research design is still open, load `design-analysis` before the others. If a named skill is unavailable, state that briefly and continue with the closest defensible workflow.

## Separate editorial from substantive work

Classify each proposed change before making it:

- **Mechanical:** spelling, broken references, caption mismatches, formatting, or code deduplication with invariant outputs. Fix and test directly.
- **Presentational:** prose organization, labels, visual encodings, table precision, or generated-number plumbing that preserves the estimand. Fix and render directly.
- **Substantive:** a changed universe, denominator, benchmark, sample exclusion, model, uncertainty method, interpretation, or claim strength. Assemble the evidence and consult the author one issue at a time unless the author already made the choice explicitly.

Never hide a substantive decision inside a writing or visualization pass.

## Build a paper ledger

Before rewriting, trace each headline claim to:

- its estimand and direction of comparison;
- population or analytic universe;
- unit of observation and denominator;
- source data and cleaning rule;
- producing script and generated artifact;
- uncertainty method and clustering unit;
- manuscript sentence, table, figure, and citation.

Record conflicts. Treat manuscript prose, tables, figures, README text, and supplements as consumers of computed results, not independent sources of truth.

## Work from upstream to downstream

1. Orient to the repository and read its local instructions.
2. Run the existing tests and compile the current paper to establish a baseline.
3. Audit raw-to-analysis transformations before changing results.
4. Fix cleaning, joins, exclusions, estimands, and summary calculations at the earliest shared stage after data collection.
5. Preserve legitimate long-form data. Define duplicates by the physical or logical entity and annotator, not by repeated identifiers alone.
6. Put shared definitions and styles in shared modules. Remove parallel implementations that can drift.
7. Generate tables, figures, manuscript macros, and repeated prose numbers from the corrected source.
8. Re-run the full pipeline, then compile and visually inspect the paper.

Prefer a standard build target over a one-off repair script.

## Keep the numerical language stable

- Use the same name for the same construct everywhere.
- State whether a quantity describes people, person-sightings, images, trips, roads, cells, annotator overlaps, or clusters.
- Use percent for a level and percentage points for a difference between percentages.
- Use proportion only for values on a 0-to-1 scale.
- State ratios with direction and base, such as women per 1,000 men.
- Do not compare an adult analytic sample with an all-age benchmark without naming and resolving the mismatch.
- Do not call top-coded or repeated sightings an exact count of unique people.

Automate headline values where the document system permits it. Leave explanatory prose human-readable rather than turning whole sentences into macros.

## Revise the argument

Use `on-writing` from the largest unit to the smallest. For each empirical result paragraph, prefer this order:

1. State the result in plain language.
2. Give the estimate and uncertainty that establish it.
3. Interpret its substantive meaning.
4. State the real scope condition or limitation.

Keep mechanisms separate from findings. Mark a mechanism as a hypothesis when the design does not identify it. Replace gestural transitions such as “two caveats attach to this” or “private transport does not close it” with the exact relation the next sentence establishes.

## Design the exhibits

Use `visualize-evidence`. Give all non-map exhibits one visual grammar. Treat maps separately because their encoding serves geography rather than ordinary group comparison. Keep diagnostic maps and plots out of the manuscript unless they answer a stated paper question.

## Validate citations

- Prefer the official dataset, documentation, paper, or software record.
- Verify title, author or institution, year, version, URL or DOI, and access path against the source.
- Ensure every citation key resolves in the compiled bibliography and every bibliography entry is cited when required by the project's style.
- Cite the exact source used to construct a benchmark, including table, geography, age bands, and any assumption.

## Finish the paper, not only the source

Before reporting completion:

1. Run formatting, linting, tests, and the complete analysis target.
2. Compile without unresolved citations, references, missing assets, or overfull content.
3. Render every PDF page and inspect it at delivery size.
4. Check every headline number against generated output.
5. Check that captions match marks, intervals, samples, and notes.
6. List unresolved substantive decisions separately from completed fixes.

Deliver the compiled artifact, the tests run, the main upstream changes, and the next substantive question. Do not bury the question in a long audit dump.
