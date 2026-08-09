# Recoding

Every derived variable is a claim about what the raw values meant. The claim is usually right and
occasionally catastrophic, and the difference is visible only if the claim was written down and
checked. This file holds the trap list and the checks that catch each one.

## The two rules

**A recode is a named function, not an inline mutation.** It lives in `00_utils.R` and is called
from the analysis scripts. The reason is not tidiness: if two quantities were ever confused, the
only durable fix is to route both through one definition so they cannot be confused again.
Patching the call site fixes today's table and leaves tomorrow's.

**Every categorical recode prints its old × new crosstab, with counts.** One line, every time.

```r
recode_relation <- function(x) {
    dplyr::case_when(
        x %in% c("F", "FTHR", "FATHER")   ~ "father",
        x %in% c("H", "HUSB", "HUSBAND")  ~ "husband",
        x %in% c("M", "MTHR", "MOTHER")   ~ "mother",
        x %in% c("O", "OTHER")            ~ "other",
        TRUE                              ~ NA_character_
    )
}

# the check, printed, not asserted away
janitor::tabyl(df, relation_raw, relation) |> print(n = Inf)
```

The crosstab catches, in one look: levels that collapsed when they should not have, cases that
fell to `NA` through the `TRUE ~` arm, inverted logic, and a level in the data that no arm
matched. `case_when`'s silent `NA` default is the single most common way a recode loses rows.

Count before and after and assert:

```r
stopifnot(sum(is.na(df$relation)) == sum(is.na(df$relation_raw)))
```

If that fails, the difference is exactly the set of unmatched raw levels — print them.

## The trap list

| trap | what it does | check |
|---|---|---|
| `replace_na(x, 0)` | turns "not measured" into "measured, zero" | fill rate by arm/wave; if it differs, this manufactures the effect |
| `case_when` with no `TRUE ~` arm | unmatched values silently become `NA` | crosstab; count `NA` before and after |
| `factor()` on a character column | levels ordered alphabetically, so the reference category is whichever label sorts first | `levels()` printed; set it explicitly |
| `as.numeric(factor)` | returns the level *index*, not the label | never do this; use `as.numeric(as.character(f))` or, better, don't store numbers as factors |
| `ifelse` on a `Date` | strips the class and returns a numeric | `dplyr::if_else`, which is type-strict |
| `log(x + 1)` | changes the estimand and is not scale-free; the "+1" is arbitrary in a variable measured in rupees | state it, or use asinh, or model the count |
| standardising with the pooled SD | the coefficient now depends on the sample composition | say which sample's SD, and use the control group's if the comparison is to a treatment effect |
| winsorising without saying so | moves the mean and shrinks the SE | state the percentile; report the count moved |
| top-coding inherited from the source | already applied before you got the data | it is a dictionary fact, not a recode; record it |
| collapsing categories to get cell sizes | changes what the coefficient means | do it once, in the function, and name the collapsed level for what it now contains |
| `na.rm = TRUE` in a summary | silently changes the denominator between columns of one table | report N per column, not one N for the table |
| recoding after subsetting | the level set differs between subsets, so the reference category differs | recode before any filter, on the full frame |
| an index built from variables with different N | each component's missingness enters the index | decide the index's own universe first |

## Missing-data policy, chosen once

Pick one, write it in the dictionary, and apply it everywhere:

- **Complete case.** Honest and usually fine. State the N it costs and check whether the dropped
  rows differ from the kept ones on the observables — if they do, say so; that is selection, and
  it belongs in the limitations, not in a footnote about sample size.
- **Indicator-and-impute.** Fill with a constant and add a missingness dummy. Popular, and biased
  under anything but MCAR for the covariate — the dummy absorbs the level difference but not the
  slope. Acceptable for nuisance covariates, not for the treatment or the outcome.
- **Multiple imputation.** Correct under MAR, and it requires the imputation model to include the
  outcome and the treatment or it biases toward the null. Report the number of imputations and
  pool properly.

What is never acceptable: a different policy per column, chosen by whichever kept the most rows.

## Naming

`raw_` → `clean_` → `an_`, so a stale variable cannot enter a model by resembling the current one.

- `raw_age` — as it arrived, sentinels intact, nothing touched.
- `clean_age` — sentinels converted to `NA`, types fixed, still on the source's own scale.
- `an_age` — the analysis version: top-coded, binned, or standardised as the plan specifies.

Keep `raw_` in the file. Deleting it means the next person cannot check the recode, and it is the
only thing that makes the crosstab reproducible.

Existing suffixes worth keeping: `_std` for standardised names or values, `_strict` for the
tighter-match variant of a panel, `_block` for the aggregate level. Each defined in the
dictionary — a suffix whose meaning lives only in the author's head is a filename comment.

## The recode ledger

Every derived variable, in one committed file:

```markdown
| variable | from | definition | universe | check | why |
|----------|------|------------|----------|-------|-----|
| `an_female_winner` | `raw_winner_sex` | 1 if "F", 0 if "M", NA otherwise (n=214 blank) | contested seats only | crosstab in `02a_raj_recode.R:44` | outcome |
| `clean_age` | `raw_age` | 999 → NA (n=4,412); 0 → NA (n=88, all in AC 47) | all electors | last-digit histogram flat after fix | 999 is a width sentinel |
```

The `why` column is what makes this a ledger rather than a changelog. A recode with no reason is
a recode nobody can evaluate.
