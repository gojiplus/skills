---
name: metered-runs
description: Plan and run paid API batches with measured costs, small pilots, quality checks, and an authorized spending limit. Use for LLM inference, OCR, embeddings, or other metered jobs.
---

# Run a metered job within budget

A failed paid request can still incur charges. Measure the work and output quality
on a small pilot before committing the full batch.

## Establish cost and authorization

Count items, fixed prompt/schema overhead, per-item inputs, expected outputs,
reasoning tokens where applicable, retries, and duplicated work. Retrieve current
pricing and request limits for the exact provider, model, and API. Record what is
known locally and what the pilot must measure. Include concurrency and retries in
the spending bound; a stop checked only after a large submission is too late.

Before the first paid call, establish the authorized provider/account, purpose,
maximum total spend, and stop conditions. Existing authorization covering those
terms is sufficient. If a budget or billing choice is missing, state the proposed
pilot size, expected cost, and purpose and ask once. Do not switch billing accounts
or exceed the cap without authorization.

## Measure a small pilot

Choose a sample covering likely request sizes and difficult cases. About ten items
can expose a broken response contract; it does not establish production accuracy
or tail behavior. Use the pilot to measure:

- input, visible-output, and reasoning usage per item where reported;
- maximum and distribution of request sizes, not just their mean;
- missing, truncated, malformed, or invalid outputs;
- correctness on independently checked examples;
- actual cost per usable item, latency, and retry rate.

A capped request reveals only a lower bound on the output it needed. Check the
provider's recommended reserve and model-specific cap before raising a limit.
Reasoning allowance may share the visible-output limit. Do not extrapolate a
parameter that has not produced usable output on the chosen API.

## Expand behind measured gates

Set numeric thresholds before running each stage: acceptable return rate, output
validity, measured quality, truncation, cost, and maximum exposure from in-flight
requests. Scale stage sizes to uncertainty and the remaining authorized budget.
Inspect each stage before submitting more work. Continue without repeated approval
while within the authorized scope, cap, and gates.

Stop on a failed gate, unexpectedly high cost, unavailable usage accounting needed
to bound further spending, or a proposed scope/billing change. Keep completed
outputs and checkpoints so recovery does not pay for the same work again. Apply
retry limits before submission and count failed attempts against the budget.

## Verify the intended outcome

A change that restores nonempty output may reduce accuracy. Revalidate quality
when changing models, reasoning effort, prompts, parsers, or output limits. Reuse
cached outputs where they answer the question. Report observed charges and usable
outputs, distinguishing provider-reported usage from estimates or delayed billing.

Deliver the completed output, quality results, actual or explicitly estimated
spend, failures, and remaining work. For OCR repair validation use
`ocr-error-triage`; for extraction/retrieval architecture use `scrape-and-parse`.
