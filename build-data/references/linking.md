# Linking two tables

A merge is the only operation in a pipeline that can change the number of rows without anyone
noticing. Everything here exists to make that impossible.

## The join contract, written before the merge

Four statements, committed before a line of merge code:

```
LEFT   raj_05_10.parquet            key: gp_code + year        unique: verified, 148,332 rows
RIGHT  gp_xwalk_active.parquet      key: gp_code               unique: verified,  11,341 rows
CARD   m:1                          expected out: 148,332 rows (left preserved)
MATCH  expect ≥ 95%; misses expected in 3 districts delimited in 2011
```

`scripts/check_join.R` turns all four into an exit code. A join contract that is not executable
is a comment.

**The left table is chosen by the estimand.** Whatever unit the claim will be about must survive
the join with its row count intact. Convenience — "this is the table I already had open" — picks
the wrong one about half the time, and the symptom appears three scripts later as an
unexplainable N.

## Cardinality

| declared | means | what a violation looks like |
|---|---|---|
| `1:1` | key unique on both sides | duplicate rows on either side; the result is longer than both inputs |
| `m:1` | key unique on the **right** | the canonical lookup join; a duplicate on the right multiplies left rows |
| `1:m` | key unique on the **left** | expansion is intended; the result is longer than the left and that is fine |
| `m:m` | — | **never a plan.** It is an undiscovered key. Find it. |

`m:m` produces a cross-product within each key value. A key with 4 rows on each side yields 16.
The row count usually still looks plausible, which is why it survives. In dplyr, an unexpected
many-to-many now warns; do not suppress the warning, and do not pass `relationship = "many-to-
many"` to silence it unless you can state what the cross-product means.

Verify uniqueness on the side that claims it, and do it as an assertion, not a glance:

```r
stopifnot(!anyDuplicated(right[, key]))
n_before <- nrow(left)
out <- dplyr::left_join(left, right, by = key, relationship = "many-to-one", unmatched = "drop")
stopifnot(nrow(out) == n_before)
```

`relationship =` and `unmatched =` make dplyr enforce the contract rather than you remembering to
check it.

## Diagnostics, in the order they pay

1. **Row conservation.** `nrow(out) == nrow(left)` for a left join under a verified `m:1`. If it
   grew, the right side has duplicates. If it shrank, you wrote an inner join.
2. **Match rate overall.** The share of left rows with a non-missing key column from the right.
3. **Match rate by group** — arm, wave, district, source file. **This is the finding, not the
   nuisance.** 92% overall that is 97% in one arm and 84% in the other is differential attrition
   wearing a merge costume, and it biases every downstream estimate in a direction you can sign.
   Report it as a table, always, even when it is flat.
4. **Unmatched exemplars, both sides, printed.** Ten rows from each. They name the failure mode
   in one look:

   | exemplar pattern | cause |
   |---|---|
   | left `08` vs right `8` | leading zero stripped by a CSV read |
   | left `"Baksa "` vs right `"Baksa"` | trailing whitespace |
   | left `Kamrup` vs right `Kamrup Metropolitan` | a split district; the crosswalk is stale |
   | left 2011 vs right 2012 for the same event | a fiscal-year offset |
   | left present, right entirely absent for one state | a source file never loaded |
   | matches only for short names | a truncation at a field width upstream |

5. **Key overlap in both directions.** `setdiff(left_keys, right_keys)` and the reverse. The
   second one is the one people skip, and a large right-only set usually means the right table is
   at a different level than you thought.
6. **Re-run the dictionary battery on the joined table.** A join creates new missingness with a
   new meaning: a column that was complete on its own table is now missing wherever the join
   failed, and that missingness is correlated with whatever made the match fail.

## Fuzzy linkage

Exact joins fail on names. Do not fix that with a lower threshold; fix it with blocking, an
explicit scoring rule, and a measured error rate.

### The in-house R path

`fuzzy_match_within_block()` — Jaro-Winkler similarity computed inside an exact block (district,
usually), explicit tie resolution, and a `match_confidence` flag carried onto every matched row.
This is the default for district/block/village crosswalk work and it should stay so: blocking on
an administrative unit removes almost all of the false-positive surface, and the block is
verifiable independently.

Always normalise before scoring, in a named function, and record what it did:
`normalize_string()` for the permissive pass, `normalize_string_strict()` for the tight one.
Unicode NFKC, case, whitespace collapse, punctuation, and the transliteration variants specific
to the source ("Kamrup"/"Kamroop", "Bishwanath"/"Biswanath").

### The `preclink` path

Where volume or a precision requirement justifies it, `preclink` (Python, `pip install preclink`)
is the better instrument. Pipeline: `preprocess → block → score → filter → decide`.

```python
result = (
    Pipeline()
    .preprocess(normalize_unicode=True, lowercase=True)
    .block(on="district", crosswalk={"Kamrup Metropolitan": "Kamrup M"})
    .score([
        StringComparison("gp_name", algorithm="jaro_winkler", weight=2.0),
        StringComparison("block_name", algorithm="jaro_winkler", weight=1.0),
        ExactComparison("year", weight=1.0),
    ])
    .filter(min_score=0.90, margin=0.10)
    .decide(method="hungarian")
    .build()
    .link(df_left, df_right)
)
```

Why it is worth the language switch when it is:

- it retains `candidate_pairs → filtered_pairs → matches`, so the funnel is auditable at every
  stage and you can compute a reduction ratio rather than guessing at one;
- `decide(method="hungarian")` gives **provably optimal 1:1 assignment**, not greedy first-come;
- `MarginFilter` drops a left record entirely when its best and second-best scores are within
  `margin` — the precision-first behaviour you want when a false match is more costly than a
  missed one;
- `MultiPassOrchestrator` with `strict_then_relaxed(0.95, 0.85, 0.70)` removes matched rows
  between passes and re-blocks, so the easy matches never compete with the hard ones;
- `TFIDFStringComparison` weights rare names above common ones, which is the closest thing here
  to Fellegi–Sunter's `m`/`u` weights.

Two gotchas that will silently degrade every score:

- `PairwiseScorer` applies a comparison only if **both** `{col}_left` and `{col}_right` exist in
  the pair frame. Pandas only suffixes *colliding* column names, so a field present on one side
  only is skipped — while still counting its weight in the denominator, deflating every score.
  Check that each comparison column exists on both sides before scoring.
- `FieldBlocker` drops rows with `NA` in any blocking key. Those rows never become candidates and
  never appear as unmatched-because-scored-low; they simply vanish. Count them separately.

`preclink` does **not** implement Fellegi–Sunter, EM-estimated `m`/`u` weights, phonetic
encoders, or ML classifiers. If you need those, that is `fastLink` (R) or `splink` (Python), and
`splink` is materially faster and more accurate at million-row scale with disjunctive blocking.

Adopt `preclink`'s naming — `left_index`/`right_index`, `*_left`/`*_right`, `score` — even for
exact joins, so the audit trail reads the same whatever produced it.

## Linkage error is measurement error, and it is almost never random

A match rate is not an accuracy. Hand-label about 100 candidate pairs — stratified across the
score distribution, not just the top — and report **precision and recall**:

```python
def compute_metrics(predicted, ground_truth):
    tp = len(predicted & ground_truth)
    precision = tp / len(predicted) if predicted else 0.0
    recall    = tp / len(ground_truth) if ground_truth else 0.0
    f1 = 2 * precision * recall / (precision + recall) if (precision + recall) else 0.0
    return precision, recall, f1
```

Both sets are `set[tuple[str, str]]` of business-key pairs. `preclink` ships no `evaluate()`;
this pattern from its `examples/` is the one to copy.

Then say which direction the bias runs:

- **False matches** attach one unit's outcome to another's treatment. Under a null this
  attenuates toward zero; under a real effect it attenuates too, so a false-match-heavy linkage
  understates. It also fabricates correlation whenever the matching variables are themselves
  correlated with the outcome.
- **Missed matches** select on whatever made the record hard to match — long or transliterated
  names, rural addresses, recent migrants, women who changed surname. None of those is ignorable,
  and all of them correlate with the outcomes political-economy papers care about.

Report both rates by group, for the same reason the exact-join match rate is reported by group.

Ambiguous pairs go to **clerical review**, not to a threshold. `result.inspect()` returns
`ambiguous_pairs`, `unmatched_left`, and `unmatched_right`; those three frames are the review
queue. Reviewed decisions land in `data/crosswalks/audit/` with the reviewer and the date; the
live mapping in `data/crosswalks/active/` is the only thing the pipeline reads.

## Deduplication before linkage

Duplicates on either side break cardinality before the join has a chance. Deduplicate first, and
be conservative about it: `preclink`'s `ClusterDeduplicator` uses union-find connected components,
keeps the most complete record in each cluster, and — this is the good part — **drops the entire
cluster as `dropped_as_indistinguishable`** when the top two are within `margin`. Dropping an
ambiguous pair is safer than picking one, and the count of drops is a number you report rather
than a decision you hide.

Whatever tool you use, the dedup report belongs in the join contract: original count, kept count,
dropped as duplicate, dropped as indistinguishable, largest cluster size. A largest cluster of 40
means the blocking key is wrong.
