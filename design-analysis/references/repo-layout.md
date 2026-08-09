# Repository layout

Codified from three of the author's repositories, treating the most recent as canonical and the
earlier two as drafts of the same idea. Nothing here is invented; the additions are marked.

## Top level

```
scripts/          numbered pipeline, plus 00_config.R and 00_utils.R
data/             partitioned by source; source/ is immutable
figs/             .pdf only, produced by ggsave(device = cairo_pdf)
tabs/             .tex fragments, produced by the table writers
lit/              papers, notes, and the .bib these feed
ms/               main.tex, compile.sh, .latexmkrc, the .bst and .cls
logs/             pipeline_<timestamp>.log, retained in-repo as evidence of runs
README.md
<name>.Rproj
.Rprofile         -> source("renv/activate.R")
renv.lock         pinned to an exact R version, Posit PPM
```

Flat, lowercase, no `src/`, no `analysis/`, no `output/tables`. `figs/` and `tabs/` are separate
top-level directories, not children of an `output/`, because they have different consumers: `ms/`
`\input`s one and `\includegraphics`es the other.

`data/`:

```
data/
  <source>/
    source/                    immutable raw; the pipeline reads, never writes
    <source>_<unit>_<geo>_<yearspan>[_variant].parquet
  crosswalks/
    active/                    the live mapping the pipeline reads
    audit/                     ties, rejects, diagnostics, reviewed pairs
```

Partition by **source or geography first**, not by raw/processed at the top. Within a source,
`source/` is the immutable layer and everything beside it is derived. The `active/` versus
`audit/` split on crosswalks is the newest idea in the corpus and the one `build-data`'s linking
stage depends on: the live mapping is small and reviewable, and everything that explains how it
was produced lives next to it without being read by the pipeline.

Derived tables are Parquet via `arrow`; hand-maintained crosswalks are CSV because a human edits
them. See `build-data`'s storage reference for why.

## Scripts

`NN[a-z]_<scope>_<verb>.R` — number is the pipeline stage, letter the sub-step or the state.

```
00_config.R                    constants, label dictionaries, theme, note strings
00_utils.R                     table writers, string normalisers, match helpers
01a_raj_standardize_source.R   01b_raj_create_district_xwalk.R
01g_audit_crosswalk_provenance.R          <- audit scripts are a first-class kind
02a_raj_recode.R               02b_up_recode.R
03a_raj_shrug_match.R          03d_audit_shrug_coverage.R
04a_descriptive_tables.R  04d_balance.R  04f_power_analysis.R
05a_short_term_main.R     05d_short_term_placebo.R
06a_long_term_main.R
09_weaver_replication.R
99_run_all.R
scripts/archive/               dead code moves here, it is not deleted
```

Every script opens the same way:

```r
# 05a_short_term_main.R
# Short-term effects for all two-way panels.
# Tests: does a quota in YEAR1 raise women's election in YEAR2?
# Output: tabs/short_term_combined.tex, figs/short_term_coefplot.pdf

library(here); library(dplyr); library(fixest); library(ggplot2)
source(here("scripts/00_config.R"))
source(here("scripts/00_utils.R"))
```

The **Output** line in the header is load-bearing: it is what makes every file in `tabs/` and
`figs/` traceable to the line that wrote it, and it is what the README's script list is generated
from. Section banners are 77-character `# ====` rules. Progress goes through `message()`, never
`print()` or `cat()`, and every artifact is followed by `message("Created: <path>")`.

`here::here()` for every path. No `setwd()`, ever.

## The driver

`99_run_all.R` — explicit list, named phases, timestamped log, per-script timing, warning capture,
fail-fast. Not a regex glob over the scripts directory: phase order legitimately differs from
filename order when a dependency requires it, and a glob has nowhere to record why.

```r
# 99_run_all.R
# Run the full analysis pipeline. Execute from the project root:
#   Rscript scripts/99_run_all.R
library(here)

dir.create(here("logs"), showWarnings = FALSE)
log_file <- here("logs", paste0("pipeline_", format(Sys.time(), "%Y%m%d_%H%M%S"), ".log"))

log_msg <- function(msg, level = "INFO") {
    line <- sprintf("[%s] %s: %s", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), level, msg)
    message(line); cat(line, "\n", file = log_file, append = TRUE)
}

run_script <- function(script_name) {
    start <- Sys.time(); had_warning <- FALSE
    log_msg(paste("START", script_name))
    tryCatch({
        withCallingHandlers(
            source(here("scripts", script_name)),
            warning = function(w) {
                had_warning <<- TRUE
                log_msg(paste("WARNING in", script_name, ":", conditionMessage(w)), "WARN")
                invokeRestart("muffleWarning")
            })
        log_msg(sprintf("DONE  %s (%.1fs)%s", script_name,
                        difftime(Sys.time(), start, units = "secs"),
                        if (had_warning) " [with warnings]" else ""))
    }, error = function(e) {
        log_msg(paste("ERROR in", script_name, ":", conditionMessage(e)), "ERROR")
        stop(sprintf("Pipeline halted at %s: %s", script_name, conditionMessage(e)))
    })
}

message("\n### PHASE 1: DATA EXTRACTION ###")
run_script("01d_up_extract_lgd.R")
message("\n### PHASE 2: PANELS AND CROSSWALKS ###")
# 01e-01g run here, after 02a/02b: the UP crosswalks depend on refreshed panels
run_script("02a_raj_recode.R")
run_script("01e_up_create_district_xwalk.R")
# ... ending with a Successes / Warnings / Errors tally
```

**No Makefile.** None of the three repositories has one, and none needs one: the dependency graph
is linear enough that an ordered list with phases is clearer than a rule set, and `make`'s
timestamp semantics fight the "recompute everything" rule below.

**No intermediate data files.** The driver recomputes. The exception is data that is expensive or
impossible to re-collect — scrapes, API pulls, manual coding, paid extracts — cached once under
`data/<source>/source/` with a provenance stamp and never regenerated. A cached file that exists
because a join was slow is a file nobody can trace, and it will drift from the code that made it.

## `00_config.R`

Constants, the figure theme, the palette, the figure dimensions, the label dictionaries fed to the
table writers, and the reusable note strings.

```r
theme_pub <- function(base_size = 11, base_family = "") {
    ggplot2::theme_bw(base_size = base_size, base_family = base_family) +
    ggplot2::theme(
        panel.grid.major = ggplot2::element_blank(),
        panel.grid.minor = ggplot2::element_blank(),
        panel.border     = ggplot2::element_rect(color = "gray30", fill = NA, linewidth = 0.5),
        axis.ticks       = ggplot2::element_line(color = "gray30", linewidth = 0.3),
        axis.text        = ggplot2::element_text(color = "gray20"),
        axis.title       = ggplot2::element_text(color = "gray10", face = "plain"),
        legend.background = ggplot2::element_blank(),
        legend.key       = ggplot2::element_blank(),
        legend.title     = ggplot2::element_text(face = "plain", size = ggplot2::rel(0.9)),
        strip.background = ggplot2::element_blank(),
        strip.text       = ggplot2::element_text(face = "bold", hjust = 0),
        plot.margin      = ggplot2::margin(10, 10, 10, 10),
        plot.title       = ggplot2::element_text(face = "bold", hjust = 0, size = ggplot2::rel(1.1)),
        plot.subtitle    = ggplot2::element_text(color = "gray40", hjust = 0))
}

COLORS_PUB <- c(primary = "#2C3E50", secondary = "#7F8C8D", accent = "#C0392B",
                highlight = "#27AE60", light = "#BDC3C7")

FIG_WIDTH_FULL <- 6.5; FIG_WIDTH_HALF <- 3.25; FIG_HEIGHT <- 4.5

NOTES_SIGNIF <- "$^{***}$p$<$0.01; $^{**}$p$<$0.05; $^{*}$p$<$0.1."
```

Every figure: `ggsave(here("figs", "x.pdf"), p, width = FIG_WIDTH_FULL, height = 3.5,
device = cairo_pdf)`. Always PDF, always explicit dimensions from the constants, always the
`message("Created: ...")` receipt.

## `00_utils.R` — the table writers

Never call `stargazer` or `etable` raw at a call site. Route every table through one of two
project-local writers, because that is what keeps 2 digits, booktabs, `\scriptsize`,
`fitstat = ~ r2 + n`, and the notes block identical across forty tables.

- **`aer_etable(models, file, dict, notes, title, label, headers, cmidrules, colsep, ...)`** wraps
  `fixest::etable` in AER style, post-processes the LaTeX (collapses duplicate FE rows into a row
  of check marks, rewrites " fixed effects" to " FE", strips the float wrapper), and appends the
  notes as `\parbox{\linewidth}{\scriptsize \emph{Notes: } ...}`.
- **`custom_stargazer(models, notes, digits, out, title, label, ...)`** is the `lm` path: converts
  `\hline` to booktabs rules, rewrites `\textasteriskcentered` into `$^{***}$`, escapes stray
  underscores, and suppresses stars on the constant.

**The one addition to existing practice:** the standard-error clause in the notes block is
generated from the fitted object rather than typed. `se_ladder.R` exports `se_note()` for this.
The reason is in `inference.md`; the short version is that 126 of 128 estimation calls in one repo
took a package default, and every note describing them was written from memory and was wrong.

## The manuscript

`ms/main.tex`, `\documentclass[12pt]{article}`, XeLaTeX with `fontspec` and `libertinus-otf`,
`natbib` with a journal `.bst`. Built by:

```bash
# ms/compile.sh
#!/bin/bash
cd "$(dirname "$0")"
latexmk -xelatex -interaction=nonstopmode main.tex 2>&1 | grep -v "^$"
```

```
# ms/.latexmkrc
$pdf_mode = 5;
$xelatex = 'xelatex -interaction=nonstopmode %O %S';
```

Tables enter as fragments holding only the `tabular` and its notes; the float, caption, and label
live in the manuscript, so a regenerated table cannot silently change a caption:

```latex
\begin{table}[!htbp]
    \centering
    \caption{Short-run effects}
    \label{tab:short_term_main}
    \input{../tabs/short_term_combined.tex}
\end{table}

\includegraphics[width=\textwidth]{../figs/main_coefplot.pdf}
```

The SI is `\appendix` in the same file, after the bibliography, with `\counterwithin{table}
{section}`, section-prefixed numbering, and a `minitoc` appendix contents.

**Any number that appears in both prose and a table comes from a macro or an `\input`, never a
typed digit.** Write the headline numbers to `tabs/macros.tex` from the analysis script and
`\input` it in the preamble:

```r
writeLines(c(sprintf("\\newcommand{\\mainEst}{%.1f}", 100 * coef(m)["treat"]),
             sprintf("\\newcommand{\\mainCiLo}{%.1f}", 100 * ci[1]),
             sprintf("\\newcommand{\\mainCiHi}{%.1f}", 100 * ci[2]),
             sprintf("\\newcommand{\\nClusters}{%s}", format(k, big.mark = ","))),
           here("tabs", "macros.tex"))
```

Then `\mainEst pp (95\% CI \mainCiLo\ to \mainCiHi)` in the text. This single mechanism prevents
the most common error `audit-analysis` finds: a table regenerated while the sentence citing it was
not. **`ms/main.tex` must compile from clean as the last step of the driver.**

## README

Order matters, and the first four items are the addition to existing practice — currently the
abstract does this work implicitly and the reader has to extract it.

```markdown
# <Full paper title>

<Abstract paragraph, carrying the headline number.>

**Authors**: ...

## The question
<One or two sentences. What is being asked.>

## Why it matters
<Two sentences. What changes if the answer is one way rather than the other.>

## Research design
<Three sentences. The variation, the comparison, the assumption.>

## What we find
<Two sentences, as an interval in substantive units. Not "significant".>

## Quick Start
```bash
git clone <url> && cd <repo>
R -e "renv::restore()"
# obtain external data -- see Data Dependencies
Rscript scripts/99_run_all.R
cd ms && latexmk -xelatex main.tex
```

## Pipeline architecture
<Prose on the hard methodological problem, then the numbered chain.>

### Directory organization
```text
<annotated tree>
```

## Data Dependencies
### Included data
### External data (must be obtained separately)
#### 1. <source>
Source: <url>
Target: `data/<source>/source/`
Files: <manifest>

## Code Organization
```text
scripts/
├── 00_*.R   # config and utilities
├── 01_*.R   # extraction, standardisation, crosswalks
...
└── 99_run_all.R
```

## Notes on Analysis
### <each non-obvious analytic decision, with counts>
### What we do not report, and why
<the deliberately omitted analyses. This section is why readers trust the rest.>

## Outputs
**Tables**: `tabs/`  **Figures**: `figs/`  **Manuscript**: `ms/main.pdf`

## Requirements
- R 4.5+
- XeLaTeX
```

Declarative, no badges, no emoji, no marketing, everything hyperlinked. The **"what we do not
report, and why"** subsection is the distinctive move worth keeping: an analysis dropped for a
stated reason ("3 of 32 districts pass, 208 observations, a 7-coefficient interaction model cannot
be estimated reliably") is credibility; the same analysis dropped silently is the thing a referee
goes looking for.

Where the repo is a submitted replication package, append the Social Science Data Editors template
sections — data availability and provenance statements, dataset list, computational requirements,
list of tables and programs — rather than replacing the above with them. The reader-facing README
and the data-editor README have different audiences and both belong.

## Reproducibility

`.Rprofile` sourcing `renv/activate.R`; `renv.lock` pinned to an exact R version against Posit
PPM; `set.seed()` at the top of every script that samples or bootstraps, with the seed recorded;
`logs/pipeline_<ts>.log` committed as evidence of runs. `.gitignore` excludes latexmk aux files by
explicit name and the large external data by path.

Two GitHub Actions carry over and nothing else: a monthly retraction check over the bibliography,
and the weekly adjacent-repository recommender. There is deliberately no test or lint workflow —
the pipeline's gate is `99_run_all.R` running clean plus the `build-data` scripts' exit codes.
