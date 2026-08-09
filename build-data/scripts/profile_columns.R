#!/usr/bin/env Rscript
# profile_columns.R
# Column profile and sentinel sweep over a table, and a draft data dictionary.
#
# Everything it reports is a *candidate*: "this column has a 3.1% spike at 999 and
# the spike is absent in wave 1" is a place to look, not a verdict. Deciding what a
# column's universe is remains the analyst's job -- the script only refuses to let
# you skip looking.
#
# Usage:
#     Rscript profile_columns.R DATA.parquet
#     Rscript profile_columns.R DATA.csv --key gp_code year
#     Rscript profile_columns.R DATA.parquet --key id --group wave --time year
#     Rscript profile_columns.R DATA.parquet --out data-dictionary.md
#
# Exit code is 1 if any HARD check fails (a declared --key that is not unique),
# so it can be dropped into a pipeline as a gate.

suppressWarnings(suppressMessages({
    ok_readr <- requireNamespace("readr", quietly = TRUE)
    ok_arrow <- requireNamespace("arrow", quietly = TRUE)
    ok_haven <- requireNamespace("haven", quietly = TRUE)
    ok_jsonl <- requireNamespace("jsonlite", quietly = TRUE)
}))

HARD_FAIL <- character(0)

# Numeric codes that are missing values wearing a number's clothes. See
# references/dictionary.md for what each usually means.
SENTINEL_NUM <- c(
    -9999, -999, -99, -9, -8, -7, -6, -5, -4, -3, -2, -1,
    77, 88, 96, 97, 98, 99,
    777, 888, 996, 997, 998, 999,
    9996, 9997, 9998, 9999, 99999, 999999,
    127, 255, 32767, 65535, 2147483647
)

# Strings that mean "missing" somewhere in some export path.
SENTINEL_CHR <- c(
    "", " ", "NA", "N/A", "n/a", "na", ".", "..", "-", "--", "NULL", "null",
    "None", "none", "nan", "NaN", "#N/A", "#NULL!", "?", "unknown", "Unknown",
    "UNKNOWN", "Not Available", "Not Reported", "Not Applicable", "Refused",
    "Don't know", "DK", "RF", "missing", "Missing"
)

SENTINEL_DATE <- as.Date(c(
    "1899-12-30", "1900-01-01", "1901-01-01", "1960-01-01", "1970-01-01",
    "0001-01-01", "2099-12-31", "9999-12-31"
))

# --------------------------------------------------------------------------- #
# arguments
# --------------------------------------------------------------------------- #

parse_args <- function(argv) {
    if (!length(argv) || argv[1] %in% c("-h", "--help")) {
        cat(readLines(sub("^--file=", "", grep("^--file=", commandArgs(FALSE),
                                               value = TRUE)))[2:22], sep = "\n")
        quit(status = 0)
    }
    out <- list(path = argv[1], key = character(0), group = character(0),
                time = NULL, out = NULL, top = 12L)
    i <- 2L
    cur <- NULL
    while (i <= length(argv)) {
        a <- argv[i]
        if (startsWith(a, "--")) {
            cur <- sub("^--", "", a)
            if (cur %in% c("time", "out", "top")) {
                i <- i + 1L
                out[[cur]] <- argv[i]
                cur <- NULL
            }
        } else if (!is.null(cur)) {
            out[[cur]] <- c(out[[cur]], a)
        }
        i <- i + 1L
    }
    out$top <- as.integer(out$top)
    out
}

load_table <- function(path) {
    ext <- tolower(tools::file_ext(path))
    if (ext %in% c("parquet", "pq")) {
        if (!ok_arrow) stop("reading parquet needs the arrow package: install.packages('arrow')")
        return(as.data.frame(arrow::read_parquet(path)))
    }
    if (ext == "feather" || ext == "arrow") {
        if (!ok_arrow) stop("reading feather needs the arrow package")
        return(as.data.frame(arrow::read_feather(path)))
    }
    if (ext == "dta") {
        if (!ok_haven) stop("reading .dta needs the haven package")
        return(as.data.frame(haven::read_dta(path)))
    }
    if (ext %in% c("jsonl", "ndjson")) {
        if (!ok_jsonl) stop("reading jsonl needs the jsonlite package")
        return(jsonlite::stream_in(file(path), verbose = FALSE))
    }
    if (ext == "rds") return(as.data.frame(readRDS(path)))
    # CSV and friends. Read everything as character and convert nothing: letting the
    # reader decide which strings mean missing destroys the exact distinction this
    # script exists to recover.
    if (!ok_readr) stop("reading delimited text needs the readr package")
    as.data.frame(readr::read_delim(
        path,
        delim = if (ext == "tsv") "\t" else ",",
        col_types = readr::cols(.default = readr::col_character()),
        na = character(), show_col_types = FALSE, progress = FALSE
    ))
}

fail <- function(msg) {
    HARD_FAIL <<- c(HARD_FAIL, msg)
    cat(sprintf("FAIL  %s\n", msg))
}

section <- function(title) {
    cat("\n", strrep("=", 76), "\n", title, "\n", strrep("=", 76), "\n", sep = "")
}

pct <- function(x) sprintf("%.2f%%", 100 * x)

# %g turns a 10-digit identifier into "9e+09", which hides exactly the values this
# script exists to show. Print integers in full and reals to 6 significant digits.
num <- function(x) {
    vapply(x, function(v) {
        if (is.na(v)) "NA"
        else if (v == floor(v) && abs(v) < 1e15) format(v, scientific = FALSE, trim = TRUE)
        else trimws(formatC(v, format = "g", digits = 6))
    }, character(1), USE.NAMES = FALSE)
}

# --------------------------------------------------------------------------- #
# 1. shape and the unit of observation
# --------------------------------------------------------------------------- #

shape_and_unit <- function(df, keys) {
    section("1. SHAPE AND UNIT OF OBSERVATION")
    cat(sprintf("rows %s   columns %d\n", format(nrow(df), big.mark = ","), ncol(df)))

    if (length(keys)) {
        missing_cols <- setdiff(keys, names(df))
        if (length(missing_cols)) {
            fail(sprintf("declared key column(s) not present: %s",
                         paste(missing_cols, collapse = ", ")))
            return(invisible(NULL))
        }
        k <- df[, keys, drop = FALSE]
        n_dup <- sum(duplicated(k))
        cat(sprintf("declared key [%s]: %s distinct, %s duplicate rows\n",
                    paste(keys, collapse = " + "),
                    format(nrow(unique(k)), big.mark = ","),
                    format(n_dup, big.mark = ",")))
        if (n_dup > 0) {
            fail(sprintf("declared key [%s] is not unique -- %s duplicate rows",
                         paste(keys, collapse = " + "), format(n_dup, big.mark = ",")))
            dupes <- df[duplicated(k) | duplicated(k, fromLast = TRUE), , drop = FALSE]
            print(utils::head(dupes[order(do.call(paste, dupes[keys])), keys, drop = FALSE], 8))
        }
        return(invisible(NULL))
    }

    # No key declared: search for the minimal unique column set. Singles, then pairs,
    # then triples, capped so this stays cheap on wide tables.
    cat("no --key given; searching for a minimal unique column set\n")
    cand <- names(df)[vapply(df, function(x) !is.list(x), logical(1))]
    cand <- cand[vapply(df[cand], function(x) length(unique(x)) > 1, logical(1))]
    if (!length(cand)) {
        cat("  every column is constant; there is no key here\n")
        return(invisible(NULL))
    }
    n <- nrow(df)
    singles <- cand[vapply(df[cand], function(x) !anyDuplicated(x), logical(1))]
    if (length(singles)) {
        cat(sprintf("  unique on its own: %s\n", paste(singles, collapse = ", ")))
        return(invisible(NULL))
    }
    # order candidates by distinctness so likely keys are tried first
    nd <- vapply(df[cand], function(x) length(unique(x)), numeric(1))
    cand <- names(sort(nd, decreasing = TRUE))
    cand <- utils::head(cand, 14L)
    for (size in 2:3) {
        combos <- utils::combn(cand, size, simplify = FALSE)
        for (cc in combos) {
            if (!anyDuplicated(df[, cc, drop = FALSE])) {
                cat(sprintf("  unique on [%s] -- %s rows, %s distinct\n",
                            paste(cc, collapse = " + "), format(n, big.mark = ","),
                            format(nrow(unique(df[, cc, drop = FALSE])), big.mark = ",")))
                cat("  Verify this is the intended unit before joining on it.\n")
                return(invisible(NULL))
            }
        }
    }
    cat("  NO unique column set found among the top 14 columns at sizes 1-3.\n")
    cat("  You do not know what a row is. Every join and every regression below\n")
    cat("  this point is undefined. Usual causes: a panel stored long without its\n")
    cat("  time index, a repeated header, or an m:m join someone already ran.\n")
}

# --------------------------------------------------------------------------- #
# 2. sentinel candidates
# --------------------------------------------------------------------------- #

sentinels <- function(df, groups) {
    section("2. SENTINEL CANDIDATES (a code is a missing value wearing a number)")
    hits <- 0L
    n <- nrow(df)

    for (col in names(df)) {
        x <- df[[col]]
        if (is.list(x)) next
        found <- character(0)

        if (is.numeric(x)) {
            xs <- x[!is.na(x)]
            if (!length(xs)) next
            for (s in intersect(SENTINEL_NUM, unique(xs))) {
                cnt <- sum(xs == s)
                found <- c(found, sprintf("%s x%s (%s)", s, format(cnt, big.mark = ","),
                                          pct(cnt / n)))
            }
            # Spike detection: a value holding a share far above the median share of
            # the top values, at a round or extreme position. Catches codes not in
            # the catalogue above.
            tb <- sort(table(xs), decreasing = TRUE)
            if (length(tb) > 3) {
                top_share <- as.numeric(tb[1]) / length(xs)
                med_share <- stats::median(as.numeric(tb)) / length(xs)
                v <- suppressWarnings(as.numeric(names(tb)[1]))
                is_round <- !is.na(v) && (abs(v) %in% c(1, 9, 99, 999, 9999, 99999) ||
                                          (abs(v) >= 100 && abs(v) %% 100 == 99))
                is_extreme <- !is.na(v) && (v == max(xs) || v == min(xs))
                if (top_share > 0.01 && top_share > 25 * med_share &&
                    (is_round || is_extreme) &&
                    !(v %in% SENTINEL_NUM)) {
                    found <- c(found, sprintf("spike at %s (%s of non-missing)",
                                              v, pct(top_share)))
                }
            }
        } else if (inherits(x, "Date")) {
            # intersect() drops the Date class and would print the integer day count
            for (s in SENTINEL_DATE[SENTINEL_DATE %in% unique(x[!is.na(x)])]) {
                cnt <- sum(x == s, na.rm = TRUE)
                found <- c(found, sprintf("%s x%s", format(as.Date(s, origin = "1970-01-01")),
                                          format(cnt, big.mark = ",")))
            }
        } else if (is.character(x) || is.factor(x)) {
            xs <- as.character(x)
            for (s in intersect(SENTINEL_CHR, unique(xs))) {
                cnt <- sum(xs == s, na.rm = TRUE)
                if (cnt > 0) {
                    found <- c(found, sprintf("%s x%s (%s)",
                                              if (s == "") '""' else if (s == " ") '" "' else s,
                                              format(cnt, big.mark = ","), pct(cnt / n)))
                }
            }
            # the column's own name leaking into its values
            if (any(tolower(xs) == tolower(col), na.rm = TRUE)) {
                found <- c(found, "the column's own name appears as a value (header leak)")
            }
        }

        if (length(found)) {
            hits <- hits + 1L
            cat(sprintf("  %-30s %s\n", col, paste(found, collapse = "; ")))
        }
    }

    if (!hits) {
        cat("none found from the catalogue. That is not proof of absence --\n")
        cat("check the last-digit and value-count sections below.\n")
    } else {
        cat("\nEach is a CANDIDATE. Confirm against the source before recoding, and\n")
        cat("check whether the code's share differs by wave, arm, or enumerator:\n")
        cat("a code present in one stratum only is a collection artifact.\n")
    }

    if (hits && length(groups)) sentinel_by_group(df, groups)
}

sentinel_by_group <- function(df, groups) {
    for (g in groups) {
        if (!g %in% names(df)) next
        cat(sprintf("\n  sentinel share by '%s':\n", g))
        lv <- unique(df[[g]])
        lv <- utils::head(lv[!is.na(lv)], 10)
        for (col in names(df)) {
            x <- df[[col]]
            if (!is.numeric(x)) next
            present <- intersect(SENTINEL_NUM, unique(x[!is.na(x)]))
            if (!length(present)) next
            shares <- vapply(lv, function(l) {
                idx <- !is.na(df[[g]]) & df[[g]] == l
                if (!sum(idx)) return(NA_real_)
                mean(x[idx] %in% present, na.rm = TRUE)
            }, numeric(1))
            if (all(is.na(shares))) next
            spread <- max(shares, na.rm = TRUE) - min(shares, na.rm = TRUE)
            if (spread > 0.02) {
                cat(sprintf("    %-26s spread %5.1fpp   %s\n", col, 100 * spread,
                            paste(sprintf("%s=%s", lv, vapply(shares, pct, character(1))),
                                  collapse = "  ")))
            }
        }
    }
}

# --------------------------------------------------------------------------- #
# 3. value counts, distinct, missing
# --------------------------------------------------------------------------- #

value_counts <- function(df, top) {
    section(sprintf("3. VALUE COUNTS (top %d, NA PRINTED AS A CATEGORY)", top))
    n <- nrow(df)
    for (col in names(df)) {
        x <- df[[col]]
        if (is.list(x)) { cat(sprintf("\n%s  [list column, skipped]\n", col)); next }
        n_na <- sum(is.na(x))
        nd <- length(unique(x[!is.na(x)]))
        cat(sprintf("\n%s  <%s>  distinct %s   NA %s (%s)\n", col,
                    paste(class(x), collapse = "/"), format(nd, big.mark = ","),
                    format(n_na, big.mark = ","), pct(n_na / n)))
        if (nd == 0) { cat("  (all missing)\n"); next }
        if (nd == 1) { cat(sprintf("  CONSTANT: %s\n", format(unique(x[!is.na(x)])[1]))); next }
        if (nd > 0.9 * n && nd > 50) {
            cat("  near-unique: an identifier or free text, not a category\n")
            cat(sprintf("  examples: %s\n",
                        paste(utils::head(as.character(x[!is.na(x)]), 3), collapse = " | ")))
            next
        }
        tb <- sort(table(as.character(x), useNA = "no"), decreasing = TRUE)
        show <- utils::head(tb, top)
        for (i in seq_along(show)) {
            lab <- names(show)[i]
            if (lab == "") lab <- '""'
            cat(sprintf("  %-40s %10s  %7s\n", substr(lab, 1, 40),
                        format(as.integer(show[i]), big.mark = ","),
                        pct(as.integer(show[i]) / n)))
        }
        if (n_na > 0) {
            cat(sprintf("  %-40s %10s  %7s\n", "<NA>", format(n_na, big.mark = ","),
                        pct(n_na / n)))
        }
        if (length(tb) > top) {
            cat(sprintf("  ... %s more distinct values\n",
                        format(length(tb) - top, big.mark = ",")))
        }
    }
}

# --------------------------------------------------------------------------- #
# 4. numeric ranges and last digits
# --------------------------------------------------------------------------- #

ranges_and_digits <- function(df) {
    section("4. NUMERIC RANGE, TAILS, AND LAST DIGIT")
    num <- names(df)[vapply(df, is.numeric, logical(1))]
    if (!length(num)) { cat("no numeric columns\n"); return(invisible(NULL)) }
    for (col in num) {
        x <- df[[col]][!is.na(df[[col]])]
        if (length(x) < 5) next
        q <- num(stats::quantile(x, c(0, .01, .25, .5, .75, .99, 1), names = FALSE))
        cat(sprintf("\n%s\n  min %-14s p1 %-14s p25 %-14s med %-14s p75 %-14s p99 %-14s max %s\n",
                    col, q[1], q[2], q[3], q[4], q[5], q[6], q[7]))
        cat(sprintf("  5 lowest : %s\n",
                    paste(num(utils::head(sort(unique(x)), 5)), collapse = ", ")))
        cat(sprintf("  5 highest: %s\n",
                    paste(num(utils::head(sort(unique(x), decreasing = TRUE), 5)), collapse = ", ")))
        # last-digit histogram: heaping at 0/5 is self-report; a spike elsewhere is
        # a systematic misread that per-row checks cannot see. Meaningless below ~10
        # distinct values, where the digit distribution just restates the categories.
        xi <- x[x == floor(x) & abs(x) < 1e15]
        if (length(xi) > 100 && length(unique(xi)) >= 10) {
            ld <- abs(xi) %% 10
            tb <- table(factor(ld, levels = 0:9))
            sh <- as.numeric(tb) / sum(tb)
            cat(sprintf("  last digit: %s\n",
                        paste(sprintf("%d=%.0f%%", 0:9, 100 * sh), collapse = " ")))
            if (max(sh) > 0.25) {
                cat(sprintf("    ^ digit %d holds %s. Heaping at 0/5 is rounding;\n",
                            which.max(sh) - 1L, pct(max(sh))))
                cat("      a spike elsewhere is a systematic misread.\n")
            }
        }
    }
}

# --------------------------------------------------------------------------- #
# 5. string hygiene
# --------------------------------------------------------------------------- #

string_hygiene <- function(df) {
    section("5. STRING HYGIENE (spurious categories)")
    chr <- names(df)[vapply(df, function(x) is.character(x) || is.factor(x), logical(1))]
    if (!length(chr)) { cat("no character columns\n"); return(invisible(NULL)) }
    hits <- 0L
    for (col in chr) {
        x <- as.character(df[[col]])
        x <- x[!is.na(x)]
        if (!length(x)) next
        raw <- length(unique(x))
        norm <- length(unique(tolower(trimws(gsub("\\s+", " ", x)))))
        if (raw > norm) {
            hits <- hits + 1L
            cat(sprintf("  %-30s %s distinct -> %s after trim/collapse/lower  (%s spurious)\n",
                        col, format(raw, big.mark = ","), format(norm, big.mark = ","),
                        format(raw - norm, big.mark = ",")))
        }
        nc <- nchar(x)
        tb <- sort(table(nc), decreasing = TRUE)
        if (length(tb) > 1 && as.numeric(tb[2]) / length(x) > 0.15) {
            cat(sprintf("  %-30s two modal lengths %s and %s -- two formats concatenated?\n",
                        col, names(tb)[1], names(tb)[2]))
            hits <- hits + 1L
        }
        if (any(grepl("^0", x)) && all(grepl("^[0-9]+$", x))) {
            cat(sprintf("  %-30s all-digit with leading zeros -- keep as character, never numeric\n", col))
            hits <- hits + 1L
        }
    }
    if (!hits) cat("none found\n")
}

# --------------------------------------------------------------------------- #
# 6. coverage over time and group
# --------------------------------------------------------------------------- #

coverage <- function(df, time, groups) {
    if (is.null(time) && !length(groups)) return(invisible(NULL))
    section("6. COVERAGE (a variable that starts mid-panel manufactures a trend)")
    if (!is.null(time) && time %in% names(df)) {
        tv <- sort(unique(df[[time]][!is.na(df[[time]])]))
        cat(sprintf("time column '%s': %s .. %s (%d periods)\n",
                    time, format(tv[1]), format(tv[length(tv)]), length(tv)))
        cat(sprintf("\n%-30s %-14s %-14s %s\n", "column", "first non-NA", "last non-NA", "periods covered"))
        for (col in setdiff(names(df), time)) {
            x <- df[[col]]
            if (is.list(x)) next
            ok <- !is.na(x)
            if (!any(ok)) { cat(sprintf("%-30s %s\n", col, "(all missing)")); next }
            tp <- sort(unique(df[[time]][ok]))
            flag <- if (length(tp) < length(tv)) "  <-- partial coverage" else ""
            cat(sprintf("%-30s %-14s %-14s %d/%d%s\n", col, format(tp[1]),
                        format(tp[length(tp)]), length(tp), length(tv), flag))
        }
    }
    for (g in groups) {
        if (!g %in% names(df)) next
        lv <- unique(df[[g]]); lv <- utils::head(lv[!is.na(lv)], 10)
        cat(sprintf("\nmissingness by '%s' (max-min > 2pp only):\n", g))
        any_hit <- FALSE
        for (col in setdiff(names(df), g)) {
            x <- df[[col]]
            if (is.list(x)) next
            r <- vapply(lv, function(l) {
                idx <- !is.na(df[[g]]) & df[[g]] == l
                if (!sum(idx)) NA_real_ else mean(is.na(x[idx]))
            }, numeric(1))
            if (all(is.na(r))) next
            spread <- max(r, na.rm = TRUE) - min(r, na.rm = TRUE)
            if (spread > 0.02) {
                any_hit <- TRUE
                cat(sprintf("  %-28s spread %5.1fpp   %s\n", col, 100 * spread,
                            paste(sprintf("%s=%s", lv, vapply(r, pct, character(1))),
                                  collapse = "  ")))
            }
        }
        if (!any_hit) cat("  none\n") else {
            cat("  ^ the missingness rate differs across groups. The bias this causes\n")
            cat("    runs in whatever direction the selection runs -- it can create a\n")
            cat("    gap, hide one, or do nothing. Work out which before proceeding;\n")
            cat("    do not assume it only attenuates.\n")
        }
    }
}

# --------------------------------------------------------------------------- #
# 7. the draft dictionary
# --------------------------------------------------------------------------- #

write_dictionary <- function(df, path, src) {
    n <- nrow(df)
    lines <- c(
        sprintf("# Data dictionary: `%s`", basename(src)),
        "",
        sprintf("Draft emitted by `profile_columns.R`. Rows: %s. Columns: %d.",
                format(n, big.mark = ","), ncol(df)),
        "",
        "**Every `TODO` below is a column whose universe nobody has stated yet.**",
        "A dictionary with TODOs is honest; a dictionary without them, written by a",
        "script, is a guess with a table around it.",
        "",
        "| name | type | unit | universe | values | missing codes | n_missing | miss kind | transformations | provenance |",
        "|------|------|------|----------|--------|---------------|-----------|-----------|-----------------|------------|"
    )
    for (col in names(df)) {
        x <- df[[col]]
        n_na <- sum(is.na(x))
        ty <- paste(class(x), collapse = "/")
        vals <- if (is.numeric(x) && sum(!is.na(x))) {
            paste(num(c(min(x, na.rm = TRUE), max(x, na.rm = TRUE))), collapse = " .. ")
        } else if (is.list(x)) {
            "(list)"
        } else {
            nd <- length(unique(x[!is.na(x)]))
            if (nd <= 8) paste(utils::head(sort(unique(as.character(x[!is.na(x)]))), 8),
                               collapse = ", ")
            else sprintf("%s distinct", format(nd, big.mark = ","))
        }
        cand <- character(0)
        if (inherits(x, "Date")) {
            cand <- format(as.Date(SENTINEL_DATE[SENTINEL_DATE %in% unique(x[!is.na(x)])],
                                   origin = "1970-01-01"))
        } else if (is.numeric(x)) {
            cand <- num(intersect(SENTINEL_NUM, unique(x[!is.na(x)])))
        } else if (is.character(x) || is.factor(x)) {
            cand <- intersect(SENTINEL_CHR, unique(as.character(x)))
            cand[cand == ""] <- '""'
        }
        lines <- c(lines, sprintf(
            "| `%s` | %s | TODO | TODO | %s | %s | %s (%s) | TODO | none | TODO |",
            col, ty, gsub("|", "\\|", vals, fixed = TRUE),
            if (length(cand)) paste(cand, collapse = ", ") else "none found",
            format(n_na, big.mark = ","), pct(n_na / n)))
    }
    lines <- c(lines, "",
        "## Open questions",
        "",
        "Columns whose universe is still a guess, and what would settle each.",
        "This list is the agenda for the next call with the data provider.",
        "",
        "- TODO")
    writeLines(lines, path)
    cat(sprintf("\nCreated: %s\n", path))
}

# --------------------------------------------------------------------------- #

main <- function() {
    a <- parse_args(commandArgs(trailingOnly = TRUE))
    df <- load_table(a$path)
    cat(sprintf("profile_columns.R  %s\n", a$path))

    shape_and_unit(df, a$key)
    sentinels(df, a$group)
    value_counts(df, a$top)
    ranges_and_digits(df)
    string_hygiene(df)
    coverage(df, a$time, a$group)
    if (!is.null(a$out)) write_dictionary(df, a$out, a$path)

    section("SUMMARY")
    if (length(HARD_FAIL)) {
        cat(sprintf("%d hard failure(s):\n", length(HARD_FAIL)))
        for (m in HARD_FAIL) cat(sprintf("  - %s\n", m))
        return(1L)
    }
    cat("no hard failures. The soft findings above still need judgement --\n")
    cat("this script narrows where to look, it does not decide.\n")
    cat("Next: fill in every TODO in the dictionary, then run audit_data.py\n")
    cat("from audit-analysis for differential missingness, skew, and denominators.\n")
    0L
}

if (sys.nframe() == 0L) quit(status = main())
