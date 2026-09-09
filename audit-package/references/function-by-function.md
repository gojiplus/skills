# Function-by-function audit contract

Inventory the public API before starting. Review each callable separately, and do
not infer correctness from package-wide test coverage or the existence of tests.
For each callable, answer:

1. **Idea and contract.** What problem, estimand, or transformation does it define?
   State what it does not measure when confusion is plausible.
2. **Research support.** Is the idea supported by relevant primary research or an
   authoritative specification? Distinguish established results, empirical
   recommendations, assumptions, and package-specific choices.
3. **Reference implementation.** Is there an authors' implementation, standards
   implementation, or mature library reference? Prefer primary sources and official
   API documentation. Credit the people whose method or code the package uses.
4. **Implementation correctness.** Compare formulas, limiting cases, defaults,
   tie/boundary behavior, weighting, missing-data behavior, and failure modes against
   the contract and reference. Explain intentional deviations.
5. **API quality and consistency.** Check names, argument order, keyword-only tuning
   options, return types, validation, state semantics, and consistency with sibling
   APIs. Build a package-wide vocabulary table: the same concept should use the same
   name, position, default, unit, and interpretation everywhere, while distinct
   concepts should not share a misleading name. Compare naming with mature ecosystem
   conventions. Do not retain deprecated or compatibility-only surface unless
   requested.
6. **Magic numbers.** Identify constants, thresholds, defaults, seeds, tolerances,
   iteration limits, and grids. Give their source or replace them with derived or
   exposed choices. Do not present machine-specific timings as general facts.
7. **Data roles.** State exactly which observations fit, tune, calibrate, select, and
   evaluate the method. Look for leakage and distinguish training, calibration,
   validation, and held-out evaluation data.
8. **Pre/post evidence.** Choose domain-appropriate metrics that can show improvement
   without hiding costs. For probabilistic calibration, use held-out proper scores and
   calibration plus resolution/discrimination diagnostics; never judge improvement
   from calibration error alone.
9. **Positive and negative validation.** Specify realistic scenarios, known-truth or
   hand-computed targets, expected numerical values or principled tolerances, positive
   controls, negative controls, malformed inputs, degeneracies, invariances, and a
   case that would expose the suspected defect. For every public argument with a
   defined domain, test below, at, and above each boundary; NaN and infinity where
   numeric; wrong shapes and types; unknown categories; and incompatible option
   combinations. Invalid values must fail clearly at the public boundary unless their
   behavior is intentional and documented. Do not accept silent clipping, coercion,
   ignored settings, fallback defaults, warnings followed by a different analysis, or
   NaN output as validation.

Build the discriminating tests before changing production code. A useful test must
fail against the old behavior for the claimed reason and pass after the fix. Include
realistic known-truth scenarios in addition to unit fixtures.

When a finding would change semantics, defaults, names, or the supported public API,
present the evidence, impact, and proposed contract to the user before editing unless
they have already authorized that specific change. Continue directly for routine
implementation work once the contract is settled.
