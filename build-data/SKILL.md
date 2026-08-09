---
name: build-data
description: Use when turning raw or unfamiliar data into an analysis-ready file — columns with no codebook, values you cannot interpret, sentinel codes like -999 or 88, a recode to define, or a merge to plan between tables whose key is not obvious. Replaces "load it and start joining" with three artifacts you can defend: a data dictionary that states each column's universe, a recode ledger, and a join contract with a declared key and a verified row count.
---

# Building an analysis-ready dataset

## Overview

Most of what later gets called an econometric problem is a data problem that was never written
down. A column meant something specific to whoever collected it, nobody recovered what, and by
the time it reaches a regression the meaning has been replaced by a plausible guess. Nothing
downstream can repair that. **Without a data dictionary, nothing matters** — not the
identification strategy, not the standard errors, not the robustness table.

This skill produces three artifacts and stops. `design-analysis` owns everything after the
analysis-ready file — estimand, identification, inference, repo, paper. `audit-analysis` owns
verifying an analysis that already exists, and its `audit_data.py` is the mechanical sweep this
skill defers to rather than duplicating.

## Usage

`/build-data [path] [stage] [consult|auto]` — stage defaults to `auto` (resume at the first stage
whose artifact is missing); mode defaults to **`consult`**.

**`auto`** runs the three stages end to end and reports once. Use it only when the user asks for
it in so many words — "do it autonomously", "don't stop and ask", "just build the file".

**Dictionary → Recode → Link.** Each stage ends in a committed file, not a conclusion.

## Work with the user, not for them

The failure mode of running this alone is not getting a step wrong. It is making forty judgement
calls silently and handing back a clean file. Each of those calls is a fork the analysis could
have taken, and the person who knows which fork is right is the one who knows the data's
provenance, the institutional detail, and what the paper is for. That is not you.

### Show the decisive slice, write the rest to a file

The opposite failure is a wall of output. Twenty tables and five pages of text in a terminal is not
collaboration; it is the same silence with more scrolling, because nobody reads it.

**Full output goes to a file. Inline goes the slice that decides something.** `profile_columns.R`
prints two hundred lines — redirect it, then show the user the six rows that matter:

```
literacy   183 rows at -999 (12.5%), and the rate is 13.1% / 11.3% across arms
turnout    94 rows at 999 (6.4%)
full profile: profile_rolls.txt   draft dictionary: data-dictionary.md
```

Three lines and two paths beats three pages. The rule of thumb: **one screen per checkpoint**, the
numbers that would change the decision, and a path to everything else. If a table needs more than
about fifteen rows to make its point, the point is a summary statistic and you should compute it.

### Stop and ask at these five points

Each is a question the data cannot answer:

| checkpoint | what you show | what you ask |
|---|---|---|
| a sentinel candidate | the value counts, the spike, its share by group | is `999` missing, not-applicable, or a real top-code? They imply three different denominators |
| a column whose universe is a guess | the coverage pattern and what you inferred | who is eligible to have a value here, and where is that documented? |
| a consequential recode | the old × new crosstab, and the estimate under each option if cheap | these two codings differ by N rows; which matches the construct? |
| the left table and the key | the candidate keys and their uniqueness | the estimand decides this — what is the claim about? |
| a match rate that differs by group | the by-group table and unmatched exemplars | is 84% in this arm acceptable, or does the sample change? |

Ask the way a colleague would: the numbers, the options and what each implies downstream, **your
recommendation and your reason**, then the question. Use `AskUserQuestion` so the options are
selectable. Never ask "shall I proceed?" — that is a request for permission, not for judgement,
and it spends the user's turn on nothing.

Batch them. Four checkpoints reached in one stage is one question with four parts, not four
interruptions.

**Do not ask about what the data or this skill already settles.** Not permission to print value
counts, verify a key, or write the dictionary. Not which file format. Those are decided — make the
call, say you made it, move on. A skill that asks about everything is as useless as one that asks
about nothing, and more annoying.

In `auto` mode, and whenever the user is not reachable, **write the assumption into the dictionary
as an open question** instead of burying it. That list is the record of every fork taken without
an answer, and it is the first thing the next reader should see.

## 1. Dictionary: a column is not understood until you can state its universe

The universe is *who is eligible to have a value*. It is not the same as the set of rows that
have one. A column is understood when you can say "every X in period Y has a value here, and
these are the reasons one would be missing" — and check it.

Run `scripts/profile_columns.R` first, **with `--out`** — the draft dictionary is the artifact
this stage exists to produce, and the console output is only how you fill it in:

```
Rscript scripts/profile_columns.R data/raj/rolls.parquet \
  --key gp_code year --unit gp_code --time year --treat quota --group wave \
  --out data-dictionary.md > logs/profile_rolls.txt
```

It reports candidates, never verdicts. The hand part — filling in every `TODO` for unit, universe,
missing-code meaning, and provenance — is the work.

`--treat` with `--unit` and `--time` answers the structural question that decides the whole
design: **does the treatment vary within unit over time?** If it does not, there is no
difference-in-differences and no unit fixed effect whatever the row count says, and the script
names the coarsest grouping the treatment is constant within — that is the assignment level, and
the number of treated groups is the sample size that matters. Two independent test runs of this
skill found that fact by hand before the script did it; it is cheap and it changes everything
downstream, so run it early.

For every column, print:

- **value counts including NA as a printed category.** `table()` drops `NA` by default and
  `count()` does not; the default is the bug. Top and bottom values verbatim, not summarised.
- distinct count, range, and the quantiles — but see the sentinel section before you trust the
  min or the max.
- **coverage**: the first and last period, and the geographies, where the column is non-missing.
  A variable that quietly starts in 2011 manufactures a trend in any panel that spans 2011.

### Sentinels: the min and the max are lying to you

A reserved code is a missing value wearing a number's clothes. It survives `is.na()`, it
survives a type check, it enters a mean. The tell is a **spike at a round or extreme value**, or
a category share that is implausibly stable across strata.

| pattern | usual meaning |
|---|---|
| `-999`, `-99`, `-9`, `-1` | missing, or "not applicable" — and those differ |
| `999`, `9999`, `99999` | missing, or a top-code at the field width |
| `77`, `88`, `98`, `99` | survey don't-know / refused / not-ascertained — three *different* refusals |
| `0` in a positive-support column | often "not measured", sometimes "measured, none found" |
| `""`, `" "`, `"NA"`, `"N/A"`, `"."`, `"NULL"`, `"None"`, `"-"` | missing, from different export paths |
| `1900-01-01`, `1970-01-01`, `9999-12-31` | epoch or sentinel dates from a failed parse |
| the exact max of the type (`32767`, `2147483647`) | overflow or a top-code |
| a value at exactly the field width (`age == 999` on a 3-char field) | truncation, not a person |

Two rules that catch what the table misses. **Check the last digit.** A histogram of a numeric
field's final digit exposes systematic misreads and heaping where every individual value looks
fine. **Check by category.** A code that appears in one wave, one enumerator, or one arm and not
others is a collection artifact, and downstream it will read as a finding rather than as
missing data.

### The unit-of-observation test

Find the **minimal column set that is unique**. Not a key you were told about — one you verified.

If no column set is unique, you do not know what a row is. Stop. Every join and every regression
below this point is undefined, and the duplicate rows will silently reweight whatever you
estimate. The usual causes are a panel stored long without its time index, an export that
repeated a header, a many-to-many join someone already ran, or a genuine hierarchy you have not
named yet.

### Structural versus item missing

Not-asked, refused, and not-applicable are three different facts and one `NA`. A childless
respondent's "number of daughters" is structurally absent; a refusal is item nonresponse; a
question added in wave 3 is absent by design. They want three different downstream treatments,
and collapsing them is how a filter question turns into an effect.

Record which one each missing code is. Where the data cannot distinguish them, say so in the
dictionary — that sentence is the finding.

### Where the dictionary comes from when there is no codebook

In order of value: the source's own documentation; a sibling year or sibling state's codebook
for the same instrument; **printed control totals inside the document itself** — summary pages,
header counts, closing totals, which are self-validating and routinely missed; external
benchmarks (census totals, official aggregates) that the column should reconcile against.

Cite the source per column. Where a meaning is inferred rather than documented, write
`inferred` in the provenance field. An inferred universe that is wrong is recoverable; one that
is undocumented is not.

### The artifact

`data-dictionary.md`, committed, one row per column:

`name | source_file | type | unit | universe | value set or range | missing codes | n_missing |
structural vs item | transformations | provenance`

Read [dictionary.md](references/dictionary.md) for the full battery and the sentinel catalogue.

Then hand off: run `audit_data.py` from `audit-analysis` for differential missingness, skew,
and denominator reconstruction. This skill does not re-implement those.

## 2. Recode: every derived variable is a claim, so make it a function

An inline recode is a claim made once, in a place nobody will look at again. Recodes belong in
named functions in `00_utils.R`, called from the analysis scripts. If two quantities were
confused once, route both through one function so they cannot be confused again.

**The mandatory check is the old × new crosstab with counts, printed.** Every categorical
recode, every time. It takes one line and it catches collapsed levels, dropped cases, and
inverted logic in a single look. A recode without its crosstab is untested code.

- **`replace_na(x, 0)` is banned** without a stated argument that the zero is *measured* rather
  than *unmeasured* — and a check that the fill rate does not differ by arm, wave, or group.
  Be precise about which harm you are risking, because the shorthand version of this rule is
  wrong: *dropping* rows that are missing at random costs precision, not bias; *filling* them with
  a constant pulls the coefficient toward the value you filled with; and when the missingness rate
  differs across arms or waves, the bias runs in whatever direction the selection runs — it can
  create an effect, hide one, or leave it alone. Which of those happens is an argument you make,
  not a default you assume.
- Declare what is otherwise implicit: reference category and factor level order (R will pick
  alphabetically and you will not notice), top-coding, winsorising and at which percentile,
  `log(x + 1)` versus log of a strictly positive subset, index construction and its weights,
  standardisation and by *which* sample's standard deviation.
- Choose a missing-data policy once and write it down — complete case, indicator-and-impute
  (and its bias), or multiple imputation — with the N each implies. Silently different N across
  the columns of one table is the most common version of this error.
- Name so a stale variable cannot enter a model. `raw_` → `clean_` → `an_`, with the `_std` /
  `_strict` suffixes already in use for standardised and tight-match variants.

Read [recode.md](references/recode.md) for the trap list.

## 3. Link: declare the left table, the key, and the cardinality before writing the merge

A merge is the only operation in a pipeline that can change the number of rows without anyone
noticing. Write the contract first.

**The left table is chosen by the estimand, not by convenience.** Whatever unit the claim will
be about is what must survive with its row count intact. If the estimand is not fixed yet, that
is a `design-analysis` question, and the join waits for it.

Before writing the merge, state four things:

1. the candidate key on each side, and evidence each is unique on the side it should be;
2. the expected cardinality — `1:1`, `1:m`, or `m:1`. **`m:m` is never a plan**; it is an
   undiscovered key, and the row count will multiply;
3. the expected row count of the result;
4. the expected match rate, and what you will do about the misses.

`scripts/check_join.R` makes all four a non-zero exit code rather than a hope.

### Match rate by group is the finding, not the nuisance

A 92% match rate that is 97% in one arm and 84% in the other is differential attrition wearing
a merge costume, and it biases everything downstream in a direction you can sign. This is the
most-skipped join check and the one that most often changes a result.

Always print the unmatched exemplars from both sides. They name the failure mode in one look —
stripped ID padding, a renamed district, a year offset, a trailing space, a state that spells
its own name two ways.

### Fuzzy linkage

`fuzzy_match_within_block()` (Jaro-Winkler inside a block, explicit tie resolution, a
`match_confidence` flag) is the in-house R tool and stays the default for the usual
district/block/village crosswalk work.

Where volume or a precision requirement justifies it, `preclink` is the better instrument
(Python, `pip install preclink`). Its pipeline is `preprocess → block → score → filter →
decide`, and it retains `candidate_pairs → filtered_pairs → matches` so the funnel is auditable
at every stage. `decide(method = "hungarian")` gives provably optimal 1:1 assignment;
`MarginFilter` or the `strict_then_relaxed` multi-pass gives precision-first behaviour. Two
gotchas worth knowing before you trust a score: `PairwiseScorer` silently skips a comparison
whose column lacks a `_left`/`_right` suffix while still counting its weight in the
denominator, deflating every score; and `FieldBlocker` drops rows with `NA` in the blocking key.

Adopt its naming — `left_index`/`right_index`, `*_left`/`*_right`, `score` — even for exact
joins, so the audit trail reads the same whatever produced it.

### Linkage error is measurement error, and it is almost never random

Hand-label about 100 candidate pairs and report **precision and recall**, not a match rate.
`preclink` has no `evaluate()`; the `compute_metrics` pattern in its `examples/` is the one to
copy. Then state which direction the resulting bias runs: false matches attenuate toward the
population mean, missed matches select on whatever made the record hard to match — which is
usually rurality, name length, or transliteration, none of them ignorable.

Send ambiguous pairs to clerical review rather than letting a threshold decide silently. Keep
the live mapping in `data/crosswalks/active/` and the diagnostics, ties, and reviewed rejects in
`data/crosswalks/audit/`.

**After the join, re-run stage 1 on the result.** A join creates new missingness with a new
meaning, and the joined table has a different universe than either input.

Read [linking.md](references/linking.md) for the full diagnostic set.

## A column that is a model output is not a measured column

Hand-coded scales, LLM labels, predicted probabilities, machine-learned scores, and probabilistic
links are all **measurements produced by an instrument**, and the instrument has a version. Three
obligations before such a column enters an analysis:

1. **Write the construct, the measure, and the gap between them** in the dictionary — what you
   claim to be measuring, the operation that produces the number, and what each captures that the
   other does not.
2. **Report reliability and validity, not accuracy alone.** For multi-item scales: McDonald's ω
   rather than Cronbach's α on its own, because α assumes tau-equivalence and rises mechanically
   with item count. For coded categories: Krippendorff's α, reported per category — an overall
   0.80 carried by a common category while the rare one sits at 0.35 is the usual shape, and the
   rare category is usually what the paper is about. For validity, include at least one
   **discriminant** check: a correlation you expected to be near zero and that was.
3. **Record the instrument in the provenance field** — model version, prompt, temperature, seed,
   parser. A model upgrade is a change of instrument and requires re-validation, not a free
   improvement.

**Where a variable is produced by a model, record the split contract too**: which rows trained the
model, which rows calibrate it, which rows are analysed — and an assertion that the three are
disjoint and were drawn after the model was frozen. Overlap between the training rows and the
analysis rows is a silent way to manufacture a finding, and it does not show up in any diagnostic
downstream.

Do not put raw LLM labels straight into a regression. At 80–90% accuracy they still produce
substantial bias and invalid intervals, because the errors are not random with respect to the
covariates. Read [measurement.md](references/measurement.md) for the reliability and validity
battery, the CheckList-style behavioural tests, and the gold-standard-subsample procedure that
makes downstream inference valid.

## Store it in a format that carries its own types

A CSV is a text file with a convention attached by whoever reads it next. It does not carry
types, so every reader re-guesses them, and the guesses differ. That is not a style preference;
it is a class of silent bug that stage 1 then has to find again on every re-read.

What CSV loses, every time:

- **leading zeros** on any ID — a `08` district code becomes `8`, and the join fails on exactly
  the rows that had them;
- **integer precision** above 2^53 when a reader infers double — long Aadhaar-style or account
  identifiers come back subtly wrong, not obviously wrong;
- **`NA` versus `"NA"` versus `""`** — three different facts, one indistinguishable field;
- **dates**, parsed by the reader's locale, so day-first and month-first files disagree only on
  the rows where the day exceeds 12;
- **encoding**, which is not declared anywhere in the file;
- **row integrity**, when an embedded delimiter or an unbalanced quote shifts every subsequent
  column on that row and nothing errors.

| use | format | why |
|---|---|---|
| derived and analysis-ready tables | **Parquet** (`arrow::write_parquet`) | types and nullability travel with the file, columnar and compressed, no re-guessing on read |
| cached raw pulls: scrapes, APIs, per-document extraction | **JSONL** | one record per line, ragged and nested records survive, appendable and streamable, still greppable |
| hand-maintained crosswalks and manual coding | CSV, IDs stored as character, with a committed schema | a human has to edit it; that is the only good reason |
| a fitted model or an R-shaped object | `.rds` | R-only and version-coupled — never a data handoff format |
| anything arriving as `.xlsx` | convert once at the boundary | record the conversion script; never read Excel inside the pipeline |

Where a CSV is unavoidable, read it with an **explicit column specification** — never let the
reader infer. `readr::read_csv(col_types = cols(district_code = col_character(), ...))`. An
inferred schema is a schema that changes when the data changes.

### File naming and organisation

Names are a schema too. The house convention, already in use:

Top level is flat and fixed — `scripts/ data/ figs/ tabs/ lit/ ms/ logs/` — and `design-analysis`
owns the whole of it. This skill only writes under `data/`:

```
data/
  <source>/
    source/                       immutable raw, never written by the pipeline
    <source>_<unit>_<geo>_<yearspan>[_variant].parquet
  crosswalks/
    active/                       the live mapping the pipeline reads
    audit/                        ties, rejects, diagnostics, reviewed pairs
```

`mnrega_elex_raj_05_10.parquet`, `shrug_gp_raj_05_10_block.parquet`, `source_2015_std.parquet`.
Lowercase, snake_case, no spaces, no capitals, extension always present.

- **Do not put a date in an analysis file's name.** `final_data_2022_01_05.csv` is a version
  control system implemented by hand, and it guarantees that some script somewhere still reads
  the old one. Git holds versions; the filename holds meaning.
- **Do not put `final`, `new`, `v2`, `clean`, or `fixed` in a filename.** They all age into lies.
- Variant suffixes carry meaning and are worth keeping: `_std` for standardised names, `_strict`
  for the tighter-match panel, `_block` for the block-level aggregate. State each in the
  dictionary.
- Every derived file's producing script is named in the dictionary's `provenance` column, and
  every script's header comment names its output path. Those two together mean any file in
  `data/` can be traced to the line that wrote it.

Read [storage.md](references/storage.md) for the round-trip tests and the provenance stamp.

## Output contract

Start with what the analysis-ready file is and what one row of it is. Then provide:

1. The data dictionary, one row per column, with provenance and the columns still unresolved.
2. The recode ledger: every derived variable, its definition, and its old × new crosstab.
3. The join contract: left table, key, cardinality, expected and actual row count, match rate
   overall **and by group**, unmatched exemplars, and measured precision/recall where fuzzy.
4. The analysis-ready file: path, row count, and the sentence that defines a row.
5. Open questions a codebook, a source, or a phone call could still answer.

Do not report a clean dataset. Report the decisions that made it clean and what each cost.

## Sources

The literature each check came from, and what each supplied, is in
[sources.md](references/sources.md). Names there are routing devices, not appeals to authority.

## Red flags you are cutting corners

- You started joining before you could state what one row is.
- You called a column "age" and never printed its value counts, so you never saw the spike at 999.
- You read a min of `-999` as a range and not as a code.
- You treated `88` and `99` as the same refusal.
- You merged and checked that it ran, not that the row count survived.
- You reported a match rate without breaking it down by arm, wave, or region.
- You wrote a recode inline in the script that uses it.
- You recoded a categorical variable and did not print the old × new crosstab.
- You filled a missing value with zero because the column "should" be zero there.
- You accepted a fuzzy match rate without hand-labelling a single pair.
- You reported Cronbach's α as if it were the reliability rather than a lower bound on it.
- You reported one overall accuracy for an LLM-coded variable and never checked it by group.
- You put a model's output into a regression as if it had been measured.
- You trained a model on rows that are also in the analysis sample.
- You picked a left table because it was the one you loaded first.
- You wrote a derived table to CSV and let the next script re-guess its types.
- You read a CSV without a column specification and a district code lost its leading zero.
- You put a date in a filename because you were not sure the new version was right.
- You marked a column "understood" when what you had was a plausible guess about its universe.
