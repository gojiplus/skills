# Sources

Names are routing devices, not appeals to authority. Every entry below earned its place by
supplying a check, a number, a bound, or a named failure mode — not by being well known.

## Data structure and the unit of observation

**Wickham, "Tidy Data" (JSS 2014).** Supplies the operational definition this skill uses for
"what is a row": one observation per row, one variable per column, one type of observational
unit per table. The value here is diagnostic, not aesthetic — a table that resists tidying
usually contains two units silently stacked, which is exactly the condition that makes a key
non-unique.

**Gentzkow and Shapiro, *Code and Data for the Social Sciences: A Practitioner's Guide* (2014).**
Source of the raw/derived separation, the "directories are portable" rule, and the discipline of
never editing a file by hand that a script could produce. `https://web.stanford.edu/~gentzkow/research/CodeAndData.pdf`

## Missing data and reserved codes

**Little and Rubin, *Statistical Analysis with Missing Data* (3rd ed., 2019).** The MCAR / MAR /
MNAR taxonomy, and the reason indicator-and-impute is biased under anything but MCAR for the
covariate. Cited here for the policy choice in `recode.md`, not for the imputation machinery.

**The DDI Codebook standard** (`https://ddialliance.org/`). What a dictionary entry is supposed
to contain when someone did it properly: universe, question text, value labels, and — the field
most often absent from home-made dictionaries — the *reason* for each missing code. The universe
field is lifted straight from DDI.

Survey codebooks are the empirical source of the `77/88/98/99` catalogue. The NHANES, GSS, DHS,
and NFHS codebooks each use the pattern with slightly different meanings, which is itself the
lesson: a code's meaning is instrument-specific and cannot be inferred from its value.

**Lipsitch, Tchetgen Tchetgen, and Cohen, "Negative Controls" (*Epidemiology* 2010).** Cited here
only for the stratum-stability heuristic: a quantity that does not move across strata where the
world does is measuring the instrument, not the world. `design-analysis` uses the paper properly.

## Record linkage

**Fellegi and Sunter, "A Theory for Record Linkage" (*JASA* 1969).** The `m`/`u` weight framework
every probabilistic linker implements. Worth reading to understand what `preclink`'s TF-IDF
rarity weighting is approximating and what it is not.

**Enamorado, Fifield, and Imai, "Using a Probabilistic Model to Assist Merging of Large-Scale
Administrative Records" (*APSR* 2019); the `fastLink` R package.** Fellegi-Sunter with EM-estimated
weights and principled handling of missing fields. The reference implementation when the in-house
Jaro-Winkler-in-a-block approach is not enough and the work must stay in R.

**`splink` (UK Ministry of Justice).** Same statistical model, SQL backends, disjunctive (OR)
blocking, and roughly 50× faster than `fastLink` at million-by-million scale in the Florida
Cancer Data System's published comparison. The reason the skill names it rather than treating
`preclink` as the ceiling.

**`preclink`** (`https://finite-sample.github.io/preclink`). Precision-first, weighted-additive
scoring, Hungarian assignment for provably optimal 1:1, and an auditable
`candidate_pairs → filtered_pairs → matches` funnel. Its `examples/benchmark_febrl.py` supplies
the `compute_metrics` pattern this skill uses for precision/recall.

**Bailey, Cole, Henderson, and Massey, "How Well Do Automated Linking Methods Perform?"
(*JEL* 2020).** The empirical basis for treating linkage error as non-random measurement error:
across methods, false-match and missed-match rates differ systematically by name commonness and
by literacy, and the resulting bias has a sign you can reason about rather than a variance you
can ignore.

## Data validation as executable checks

**`pointblank`** (R and Python) and **`pandera`** (Python). The idea worth taking is not the
package but the shape: a validation is a declared expectation with a threshold and an exit code,
stored next to the data, re-run on every build. `check_join.R` is that idea with a scope of one.

Great Expectations is the heavier alternative and is overkill for a research pipeline; noted so
the choice is deliberate rather than uninformed.

## In-repo precedent

The conventions this skill codifies rather than invents come from three of the author's own
repositories: the per-dataset `readme.md` + `data_dictionary.md` pattern in `daughters`; the
`<source>_<unit>_<geo>_<yearspan>[_variant].parquet` naming and `arrow` default in `quota`; and
the `source/` versus `processed/` split plus `crosswalks/active/` versus `crosswalks/audit/`
separation in `quota_raj`, which is the newest and best idea in the corpus and the one the
linking stage depends on.
