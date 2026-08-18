#!/usr/bin/env Rscript
# check_join.R
# Enforce a join contract: declared key, declared cardinality, row conservation,
# and match rate BY GROUP.
#
# A merge is the only operation in a pipeline that can change the number of rows
# without anyone noticing. This turns the four statements you should have written
# before the merge into an exit code.
#
# Usage:
#     Rscript check_join.R --left L.parquet --right R.parquet --key gp_code --card m:1
#     Rscript check_join.R --left L.parquet --left-key gp_code year \
#                          --right R.parquet --right-key gp_id yr \
#                          --card m:1 --group treat wave --min-match 0.95 --type left
#
# Flags:
#   --left/--right PATH     the two tables (parquet, csv, tsv, dta, rds)
#   --key COL...            key on both sides; or --left-key/--right-key separately
#   --card 1:1|m:1|1:m      declared cardinality; m:m is refused
#   --type left|inner       join type, default left
#   --group COL...          columns to break the match rate down by
#   --min-match P           floor on the overall match rate, a proportion in [0,1]
#
# Cardinality:
#     1:1   key unique on BOTH sides
#     m:1   key unique on the RIGHT   (the canonical lookup join)
#     1:m   key unique on the LEFT
#     m:m   rejected outright -- it is an undiscovered key, not a plan
#
# Exit code is 1 if any HARD check fails (missing key, cardinality violation,
# row loss or row growth under a left join, match rate below --min-match).

suppressWarnings(suppressMessages({
    ok_readr <- requireNamespace("readr", quietly = TRUE)
    ok_arrow <- requireNamespace("arrow", quietly = TRUE)
    ok_haven <- requireNamespace("haven", quietly = TRUE)
}))

HARD_FAIL <- character(0)

parse_args <- function(argv) {
    if (!length(argv) || argv[1] %in% c("-h", "--help")) {
        cat(readLines(sub("^--file=", "", grep("^--file=", commandArgs(FALSE),
                                               value = TRUE)))[2:26], sep = "\n")
        quit(status = 0)
    }
    out <- list(left = NULL, right = NULL, key = character(0),
                `left-key` = character(0), `right-key` = character(0),
                card = "m:1", group = character(0), type = "left", `min-match` = "0")
    single <- c("left", "right", "card", "type", "min-match")
    multi  <- c("key", "left-key", "right-key", "group")
    known  <- c(single, multi)
    i <- 1L
    cur <- NULL
    while (i <= length(argv)) {
        a <- argv[i]
        if (startsWith(a, "--")) {
            cur <- sub("^--", "", a)
            # An unrecognised flag used to be absorbed into the list and never
            # reported, so `--min_match 0.95` (underscore) left min-match at its
            # default 0 and the documented match-rate gate could never fail.
            if (!cur %in% known) {
                die(sprintf("unknown flag '--%s'. Known flags: %s",
                            cur, paste0("--", sort(known), collapse = " ")))
            }
            if (cur %in% single) {
                if (i + 1L > length(argv) || startsWith(argv[i + 1L], "--")) {
                    die(sprintf("--%s needs a value", cur))
                }
                i <- i + 1L
                out[[cur]] <- argv[i]
                cur <- NULL
            }
        } else if (!is.null(cur)) {
            out[[cur]] <- c(out[[cur]], a)
        } else {
            die(sprintf("unexpected argument '%s' (every value must follow a flag)", a))
        }
        i <- i + 1L
    }
    if (!length(out$`left-key`))  out$`left-key`  <- out$key
    if (!length(out$`right-key`)) out$`right-key` <- out$`left-key`
    out$`min-match` <- as.numeric(out$`min-match`)
    out
}

load_table <- function(path) {
    ext <- tolower(tools::file_ext(path))
    if (ext %in% c("parquet", "pq")) {
        if (!ok_arrow) stop("reading parquet needs the arrow package")
        return(as.data.frame(arrow::read_parquet(path)))
    }
    if (ext == "dta") {
        if (!ok_haven) stop("reading .dta needs the haven package")
        return(as.data.frame(haven::read_dta(path)))
    }
    if (ext == "rds") return(as.data.frame(readRDS(path)))
    if (!ok_readr) stop("reading delimited text needs the readr package")
    as.data.frame(readr::read_delim(
        path, delim = if (ext == "tsv") "\t" else ",",
        col_types = readr::cols(.default = readr::col_character()),
        na = character(), show_col_types = FALSE, progress = FALSE))
}

fail <- function(msg) { HARD_FAIL <<- c(HARD_FAIL, msg); cat(sprintf("FAIL  %s\n", msg)) }
die  <- function(msg) { cat(sprintf("check_join.R: %s\n", msg), file = stderr()); quit(status = 2) }
section <- function(t) cat("\n", strrep("=", 76), "\n", t, "\n", strrep("=", 76), "\n", sep = "")
pct <- function(x) sprintf("%.2f%%", 100 * x)
cma <- function(x) format(x, big.mark = ",")

# Paste key columns into one comparable string. Type coercion here is deliberate and
# is itself a check: "08" and 8 must not silently match, so a mismatch shows up as a
# zero match rate rather than a wrong one.
#
# But as.character() on a double is not a faithful rendering: as.character(100000)
# is "1e+05" and as.character(1e15) is "1e+15", so joining a parquet whose id is
# numeric against a CSV of the same ids gives 0% on exactly the round-magnitude
# keys -- a formatting artifact that reads as a key mismatch. Worse, ids above 2^53
# lose precision as doubles and silently COLLIDE (123456789012345678 renders as
# ...696). Render numerics in full, and refuse to key on a non-integral double.
render_key <- function(x, col) {
    if (is.numeric(x)) {
        finite <- x[is.finite(x)]
        if (length(finite) && any(finite != floor(finite))) {
            die(sprintf(paste0(
                "key column '%s' is a non-integral numeric. Floating point is not a ",
                "join key -- 0.1 + 0.2 does not equal 0.3. Round it to an integer or ",
                "store it as text upstream."), col))
        }
        if (length(finite) && max(abs(finite)) > 2^53) {
            die(sprintf(paste0(
                "key column '%s' holds values above 2^53, where doubles cannot ",
                "represent consecutive integers. Distinct ids may already have ",
                "collided in memory. Read this column as character."), col))
        }
        return(format(x, scientific = FALSE, trim = TRUE, justify = "none"))
    }
    as.character(x)
}

keyvec <- function(df, cols) {
    parts <- lapply(cols, function(c) render_key(df[[c]], c))
    do.call(paste, c(parts, sep = "\r"))
}

main <- function() {
    a <- parse_args(commandArgs(trailingOnly = TRUE))
    if (is.null(a$left) || is.null(a$right)) die("--left and --right are required")
    if (!length(a$`left-key`)) die("--key (or --left-key/--right-key) is required")
    if (length(a$`left-key`) != length(a$`right-key`))
        die("--left-key and --right-key must name the same number of columns")
    if (a$card == "m:m")
        die("m:m is not a join contract. It is an undiscovered key -- find it first.")
    if (!a$card %in% c("1:1", "m:1", "1:m"))
        die("--card must be one of 1:1, m:1, 1:m")
    if (!a$type %in% c("left", "inner"))
        die("--type must be 'left' or 'inner'")
    if (!is.finite(a$`min-match`) || a$`min-match` < 0 || a$`min-match` > 1) {
        die(sprintf("--min-match must be a proportion in [0, 1], got '%s'",
                    a$`min-match`))
    }

    L <- load_table(a$left)
    R <- load_table(a$right)

    section("1. THE CONTRACT")
    cat(sprintf("LEFT   %s\n       key: %s   rows: %s\n", a$left,
                paste(a$`left-key`, collapse = " + "), cma(nrow(L))))
    cat(sprintf("RIGHT  %s\n       key: %s   rows: %s\n", a$right,
                paste(a$`right-key`, collapse = " + "), cma(nrow(R))))
    cat(sprintf("CARD   %s      JOIN TYPE  %s\n", a$card, a$type))

    miss_l <- setdiff(a$`left-key`, names(L))
    miss_r <- setdiff(a$`right-key`, names(R))
    if (length(miss_l)) fail(sprintf("left key column(s) absent: %s", paste(miss_l, collapse = ", ")))
    if (length(miss_r)) fail(sprintf("right key column(s) absent: %s", paste(miss_r, collapse = ", ")))
    if (length(HARD_FAIL)) return(1L)

    kl <- keyvec(L, a$`left-key`)
    kr <- keyvec(R, a$`right-key`)

    section("2. KEY UNIQUENESS")
    dl <- sum(duplicated(kl)); dr <- sum(duplicated(kr))
    cat(sprintf("left  : %s distinct, %s duplicate rows\n", cma(length(unique(kl))), cma(dl)))
    cat(sprintf("right : %s distinct, %s duplicate rows\n", cma(length(unique(kr))), cma(dr)))
    need_l <- a$card %in% c("1:1", "1:m")
    need_r <- a$card %in% c("1:1", "m:1")
    if (need_l && dl > 0) {
        fail(sprintf("card %s requires a unique LEFT key; %s duplicate rows", a$card, cma(dl)))
        print(utils::head(L[duplicated(kl) | duplicated(kl, fromLast = TRUE),
                            a$`left-key`, drop = FALSE], 6))
    }
    if (need_r && dr > 0) {
        fail(sprintf("card %s requires a unique RIGHT key; %s duplicate rows", a$card, cma(dr)))
        print(utils::head(R[duplicated(kr) | duplicated(kr, fromLast = TRUE),
                            a$`right-key`, drop = FALSE], 6))
        cat("  ^ each duplicate multiplies the matching left rows. This is the\n")
        cat("    single most common way a merge silently reweights an estimate.\n")
    }
    if (!need_l && !need_r) cat("(1:m declared; neither side asserted unique on the right)\n")

    section("3. ROW CONSERVATION")
    matched_l <- kl %in% kr
    n_out <- if (a$type == "inner") {
        # Was: vapply over every matched left key, each scanning the whole right
        # vector -- O(n_left x n_right), which hangs on two 100k-row tables. One
        # table() lookup instead, the same technique the left branch already uses.
        mult <- table(kr)
        sum(as.numeric(mult[kl[matched_l]]), na.rm = TRUE)
    } else {
        # left join: each left row appears once per matching right row, at least once
        mult <- table(kr)
        rep_per_left <- ifelse(matched_l, as.numeric(mult[kl]), 1)
        rep_per_left[is.na(rep_per_left)] <- 1
        sum(rep_per_left)
    }
    cat(sprintf("left rows in           %s\n", cma(nrow(L))))
    cat(sprintf("rows out (%s join)   %s\n", a$type, cma(n_out)))
    if (a$type == "left" && a$card == "m:1" && n_out != nrow(L)) {
        fail(sprintf("row conservation broken: %s in, %s out under a left m:1 join",
                     cma(nrow(L)), cma(n_out)))
    }
    if (a$type == "left" && a$card == "1:1" && n_out != nrow(L)) {
        fail(sprintf("row conservation broken: %s in, %s out under a left 1:1 join",
                     cma(nrow(L)), cma(n_out)))
    }
    if (n_out > nrow(L)) {
        cat(sprintf("  the result GREW by %s rows. Under 1:m that is intended;\n",
                    cma(n_out - nrow(L))))
        cat("  under anything else the right side has duplicates.\n")
    }
    # An inner join that silently drops part of the left table used to produce no
    # FAIL at all, because the conservation checks above are gated on type=="left".
    if (a$type == "inner") {
        lost <- nrow(L) - sum(matched_l)
        if (lost > 0) {
            fail(sprintf(
                "inner join drops %s of %s left rows (%s). If the estimand is about the left unit, that changes the sample",
                cma(lost), cma(nrow(L)), pct(lost / nrow(L))))
            cat("  Use a left join and handle the misses explicitly, or state in the\n")
            cat("  contract that the estimand is defined only on matched rows.\n")
        }
    }

    section("4. MATCH RATE")
    mr <- mean(matched_l)
    cat(sprintf("left  matched: %s / %s  = %s\n", cma(sum(matched_l)), cma(nrow(L)), pct(mr)))
    matched_r <- kr %in% kl
    cat(sprintf("right matched: %s / %s  = %s\n", cma(sum(matched_r)), cma(nrow(R)),
                pct(mean(matched_r))))
    if (mr < a$`min-match`) {
        fail(sprintf("match rate %s is below the declared floor %s", pct(mr),
                     pct(a$`min-match`)))
    }
    if (mean(matched_r) < 0.5) {
        cat("  a large right-only set usually means the right table is at a\n")
        cat("  different level than you thought. Check the unit, not the key.\n")
    }

    if (length(a$group)) {
        cat("\nmatch rate BY GROUP -- this is the finding, not the nuisance:\n")
        for (g in a$group) {
            if (!g %in% names(L)) { cat(sprintf("  (group '%s' not on the left, skipped)\n", g)); next }
            lv <- unique(L[[g]]); lv <- lv[!is.na(lv)]
            if (length(lv) > 20) { cat(sprintf("  (group '%s' has %d levels, skipped)\n", g, length(lv))); next }
            rates <- vapply(lv, function(l) mean(matched_l[!is.na(L[[g]]) & L[[g]] == l]), numeric(1))
            ns    <- vapply(lv, function(l) sum(!is.na(L[[g]]) & L[[g]] == l), numeric(1))
            cat(sprintf("\n  by %s:\n", g))
            for (i in order(rates)) {
                cat(sprintf("    %-24s n=%-10s %s\n", as.character(lv[i]), cma(ns[i]), pct(rates[i])))
            }
            spread <- max(rates) - min(rates)
            cat(sprintf("    spread %.1fpp\n", 100 * spread))
            if (spread > 0.02) {
                cat("    ^ DIFFERENTIAL match rate. This is differential attrition\n")
                cat("      wearing a merge costume, and it biases every downstream\n")
                cat("      estimate in a direction you can sign. Report it.\n")
            }
        }
    } else {
        cat("\nno --group given. An overall match rate is nearly useless on its own:\n")
        cat("the question is always whether the rate DIFFERS across arms or waves.\n")
        cat("Re-run with --group <arm|wave|region> before concluding anything.\n")
    }

    section("5. UNMATCHED EXEMPLARS (they name the failure mode)")
    ul <- unique(kl[!matched_l]); ur <- unique(kr[!matched_r])
    show <- function(v, lab) {
        cat(sprintf("\n%s-only keys: %s distinct\n", lab, cma(length(v))))
        if (length(v)) {
            for (k in utils::head(v, 10)) cat(sprintf("  %s\n", gsub("\r", " + ", k)))
        }
    }
    show(ul, "left")
    show(ur, "right")
    if (length(ul) && length(ur)) {
        # Cheap diagnosis of the usual culprits, in the order they occur.
        strip0 <- function(v) sub("^0+", "", v)
        if (length(intersect(strip0(ul), strip0(ur)))) {
            cat("\n  * stripping leading zeros creates matches -- a CSV read turned an\n")
            cat("    ID into a number on one side. Store IDs as character.\n")
        }
        if (length(intersect(trimws(ul), trimws(ur)))) {
            cat("\n  * trimming whitespace creates matches -- normalise before joining.\n")
        }
        if (length(intersect(tolower(ul), tolower(ur)))) {
            cat("\n  * lowercasing creates matches -- normalise before joining.\n")
        }
    }

    section("SUMMARY")
    if (length(HARD_FAIL)) {
        cat(sprintf("%d hard failure(s):\n", length(HARD_FAIL)))
        for (m in HARD_FAIL) cat(sprintf("  - %s\n", m))
        return(1L)
    }
    cat("contract holds. Record the match rate by group in the join contract --\n")
    cat("a flat rate is a result worth stating, not a check worth omitting.\n")
    0L
}

if (sys.nframe() == 0L) quit(status = main())
