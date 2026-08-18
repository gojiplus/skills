#!/usr/bin/env Rscript
# se_ladder.R
# One specification, every variance estimator, side by side.
#
# The design picks which rung is reported in the main table; the ladder goes in
# the SI. If the conclusion moves across the ladder, that IS the result -- the
# estimate depends on a variance approximation rather than on the data, and the
# paper should say so instead of reporting the friendliest rung.
#
# Usage:
#     Rscript se_ladder.R --data d.parquet --formula "y ~ treat + x" --param treat
#     Rscript se_ladder.R --data d.parquet --formula "y ~ treat" --param treat \
#                         --clusters district --boot 9999
#     Rscript se_ladder.R --data d.parquet --formula "y ~ treat | district^block" \
#                         --param treat --clusters district      # a | means fixest
#     --boot 0 disables the wild cluster bootstrap; --ri 0 disables randomization inference
#
# Also usable as a library:
#     source("se_ladder.R"); se_ladder(fit, param = "treat", clusters = df$district)
#     se_note(fit)     # the sentence for a table note, generated from the object
#
# Exit code is 1 if a 95% interval crosses zero on some rungs and not others, or
# if the regressor has no within-cluster variation while the model also absorbs
# fixed effects at that level -- so it can be dropped into a pipeline as a gate.
# Exit code 2 means the run was misconfigured and no ladder was produced.

suppressWarnings(suppressMessages({
    has <- function(p) requireNamespace(p, quietly = TRUE)
    ok_estimatr <- has("estimatr");   ok_fixest  <- has("fixest")
    ok_sandwich <- has("sandwich");   ok_lmtest  <- has("lmtest")
    ok_club     <- has("clubSandwich"); ok_wcb   <- has("fwildclusterboot")
    ok_arrow    <- has("arrow");      ok_readr   <- has("readr")
}))

# Below this many clusters -- or this many TREATED clusters -- compare CR2 with
# the wild cluster bootstrap or randomization inference. MacKinnon, Nielsen and
# Webb (2023).
FEW_CLUSTERS <- 40L

`%||%` <- function(a, b) if (is.null(a) || (length(a) == 1 && is.na(a))) b else a

# --------------------------------------------------------------------------- #
# se_note(): the sentence for a table note, generated from the fitted object.
# Typing this by hand is how 15 notes in one repo came to say "heteroskedasticity-
# robust" about columns that were iid and cluster-robust respectively.
# --------------------------------------------------------------------------- #

# Build the table note from the LADDER ROW you are actually reporting. Generating
# it from the base lm() -- which is what an earlier version did -- reproduces the
# exact error this script exists to prevent: a note reading "classical (iid)" over
# a column that was clustered.
ladder_note <- function(res, rung_name, n_cl = NA_integer_, n_tr = NA_integer_) {
    r <- res[res$rung == rung_name, ][1, ]
    if (is.na(r$rung)) return("Standard errors: unknown.")
    txt <- sprintf("Standard errors: %s", r$rung)
    if (grepl("^CR|bootstrap", r$rung) && !is.na(n_cl)) {
        txt <- sprintf("%s, clustered at the specified level (%s clusters%s)", txt,
                       format(n_cl, big.mark = ","),
                       if (!is.na(n_tr)) sprintf(", %s treated", format(n_tr, big.mark = ",")) else "")
    }
    if (is.finite(r$dof)) txt <- sprintf("%s, %.1f degrees of freedom", txt, r$dof)
    paste0(txt, ".")
}

se_note <- function(m, clusters = NULL) {
    lab <- NULL
    if (inherits(m, "fixest")) {
        v <- tryCatch(attr(summary(m)$cov.scaled, "type"), error = function(e) NULL)
        lab <- v %||% tryCatch(summary(m)$se_type, error = function(e) NULL)
    } else if (inherits(m, "lm_robust")) {
        lab <- m$se_type
        if (!is.null(m$clusters) || length(m$cluster)) {
            lab <- paste0(lab, ", clustered")
        }
    } else if (inherits(m, "lm")) {
        lab <- "classical (iid)"
    }
    lab <- lab %||% "unknown"
    # Only claim clusters when the fitted object actually used them. A note that
    # says "14 clusters" beside an iid variance is the error this function exists
    # to prevent, not a shorthand for it.
    clustered <- grepl("cluster|^CR", lab, ignore.case = TRUE)
    k <- if (clustered && !is.null(clusters)) length(unique(clusters)) else NA_integer_
    sprintf("Standard errors: %s%s.", lab,
            if (!is.na(k)) sprintf(", %s clusters", format(k, big.mark = ",")) else "")
}

# --------------------------------------------------------------------------- #
# the ladder
# --------------------------------------------------------------------------- #

rung <- function(name, est, se, dof = Inf, note = "") {
    crit <- if (is.finite(dof)) stats::qt(0.975, dof) else stats::qnorm(0.975)
    data.frame(rung = name, estimate = est, se = se,
               ci_lo = est - crit * se, ci_hi = est + crit * se,
               dof = dof, note = note, stringsAsFactors = FALSE)
}

se_ladder <- function(fit, param, clusters = NULL, cluster_name = NULL,
                      treat = NULL, boot = 9999L, data = NULL, has_fe = FALSE) {
    out <- list()
    b <- stats::coef(fit)[param]
    if (is.na(b)) stop(sprintf("parameter '%s' is not in the fitted model", param))
    n <- stats::nobs(fit)
    k <- length(stats::coef(fit))
    if (stats::df.residual(fit) <= 0) {
        stop("the fitted model has no residual degrees of freedom; no variance estimator is defined")
    }

    # --- no-cluster rungs -------------------------------------------------- #
    if (ok_sandwich) {
        for (ty in c("const", "HC0", "HC1", "HC2", "HC3")) {
            v <- tryCatch(sandwich::vcovHC(fit, type = ty), error = function(e) NULL)
            if (is.null(v) || !param %in% rownames(v)) next
            lab <- if (ty == "const") "iid (classical)" else ty
            out[[length(out) + 1]] <- rung(lab, b, sqrt(v[param, param]), n - k)
        }
    }

    # --- cluster rungs ----------------------------------------------------- #
    n_cl <- NA_integer_; n_cl_treated <- NA_integer_; within_var <- NA_real_
    if (!is.null(clusters)) {
        n_cl <- length(unique(clusters))
        if (!is.null(treat)) {
            n_cl_treated <- length(unique(clusters[!is.na(treat) & treat != 0]))
            # Share of the parameter's variance that is WITHIN cluster. If this is
            # ~0 the regressor is constant within cluster, and any fixed effect at
            # or below the clustering level absorbs it: the cluster-robust meat
            # matrix collapses and the SE comes out absurdly small rather than
            # erroring. Seen in testing at CR0 = 0.0002 against HC1 = 0.078.
            tv <- stats::var(treat, na.rm = TRUE)
            if (is.finite(tv) && tv > 0) {
                grp_mean <- stats::ave(treat, clusters, FUN = function(z) mean(z, na.rm = TRUE))
                within_var <- stats::var(treat - grp_mean, na.rm = TRUE) / tv
            }
        }
        if (ok_sandwich) {
            v <- tryCatch(sandwich::vcovCL(fit, cluster = clusters, type = "HC0",
                                           cadjust = FALSE), error = function(e) NULL)
            if (!is.null(v) && param %in% rownames(v)) {
                out[[length(out) + 1]] <- rung("CR0", b, sqrt(v[param, param]), n_cl - 1)
            }
            v <- tryCatch(sandwich::vcovCL(fit, cluster = clusters, type = "HC1"),
                          error = function(e) NULL)
            if (!is.null(v) && param %in% rownames(v)) {
                out[[length(out) + 1]] <- rung("CR1 (Stata default)", b,
                                               sqrt(v[param, param]), n_cl - 1)
            }
        }
        if (ok_club) {
            v <- tryCatch(clubSandwich::vcovCR(fit, cluster = clusters, type = "CR2"),
                          error = function(e) NULL)
            if (!is.null(v) && param %in% rownames(as.matrix(v))) {
                ct <- tryCatch(clubSandwich::coef_test(fit, vcov = v, cluster = clusters,
                                                       test = "Satterthwaite",
                                                       coefs = param),
                               error = function(e) NULL)
                if (!is.null(ct)) {
                    out[[length(out) + 1]] <- rung("CR2 (Bell-McCaffrey)", b, ct$SE[1],
                                                   ct$df_Satt[1], "estimatr default")
                } else {
                    out[[length(out) + 1]] <- rung("CR2 (Bell-McCaffrey)", b,
                                                   sqrt(as.matrix(v)[param, param]),
                                                   n_cl - 1, "estimatr default")
                }
            }
        }
        # --- wild cluster bootstrap ---------------------------------------- #
        # Only meaningful when clusters are few; run it anyway so the ladder is
        # complete, but the summary says whether it was required or decorative.
        #
        # Two calls, deliberately. MacKinnon-Nielsen-Webb argue for the "31"
        # variant, which fwildclusterboot supports for p-values but NOT for
        # confidence intervals; intervals come from "fnw11". Reporting the "31"
        # p-value beside an "fnw11" interval is honest as long as both are named,
        # which is why the note column carries the variant that actually ran.
        #
        # Verified against fwildclusterboot 0.14.3: bootstrap_type "31" and "33"
        # throw "incorrect number of dimensions" when the model has exactly one
        # regressor besides the intercept (`y ~ treat`); they work as soon as a
        # covariate is added (`y ~ treat + x`). Hence the fallback chain rather
        # than a single call -- a silent NULL here would drop the rung that
        # matters most in the few-cluster case.
        # boottest() takes clustid as the NAME of a column reachable from the
        # model's data, not as a vector -- passing the vector fails with
        # "object '<first cluster value>' not found".
        if (boot > 0 && ok_wcb && inherits(fit, "lm") && !is.null(cluster_name)) {
            boot_run <- function(type, ci) {
                res <- NULL
                utils::capture.output(suppressWarnings(suppressMessages(
                    res <- tryCatch(
                        fwildclusterboot::boottest(
                            fit, clustid = cluster_name, param = param, B = boot,
                            bootstrap_type = type, impose_null = TRUE, conf_int = ci),
                        error = function(e) NULL))), type = "message")
                res
            }
            wbp <- NULL; variant <- NA_character_
            for (ty in c("31", "13", "fnw11")) {
                wbp <- boot_run(ty, FALSE)
                if (!is.null(wbp)) { variant <- ty; break }
            }
            wbci <- boot_run("fnw11", TRUE)
            ci <- tryCatch(wbci$conf_int, error = function(e) NULL)
            if (is.null(ci) || length(ci) != 2) ci <- c(NA_real_, NA_real_)
            if (!is.null(wbp) || !is.null(wbci)) {
                # back out an implied SE from the interval so the column lines up
                # with the others; it is an implied width, not an analytic SE.
                se_imp <- if (all(is.finite(ci))) (ci[2] - ci[1]) / (2 * 1.959964) else NA_real_
                pv <- if (!is.null(wbp)) wbp$p_val else wbci$p_val
                if (is.na(variant)) variant <- "fnw11"
                r <- rung("wild cluster bootstrap", b, se_imp, Inf,
                          sprintf("p = %.4f (%s), CI from fnw11, B = %s",
                                  pv, variant, format(boot, big.mark = ",")))
                if (all(is.finite(ci))) { r$ci_lo <- ci[1]; r$ci_hi <- ci[2] }
                out[[length(out) + 1]] <- r
            }
        }
    }

    if (!length(out)) {
        stop("no variance estimator ran. Install 'sandwich' (and 'clubSandwich' ",
             "for the CR2 rung); without them there is no ladder to report.")
    }
    res <- do.call(rbind, out)
    attr(res, "n_clusters") <- n_cl
    attr(res, "n_clusters_treated") <- n_cl_treated
    attr(res, "within_share") <- within_var
    attr(res, "has_absorbing_fe") <- isTRUE(has_fe)
    attr(res, "nobs") <- n
    res
}

# --------------------------------------------------------------------------- #
# randomisation inference: correct by construction when assignment is known
# --------------------------------------------------------------------------- #

ri_pvalue <- function(fit, data, param, clusters = NULL, sims = 2000L,
                      seed = 1234567L) {
    set.seed(seed)
    b_obs <- unname(stats::coef(fit)[param])
    if (!param %in% names(data)) {
        stop("RI requires param to name the raw assignment column in the data")
    }

    # Rebuild the complete design matrix from the permuted RAW assignment. Changing
    # one model-matrix column directly makes impossible rows whenever treatment also
    # appears in an interaction or transformation. Requiring a raw column means
    # factor(treat)B needs a separate assignment option that this script does not
    # pretend to infer.
    X <- stats::model.matrix(fit)
    y <- stats::model.response(stats::model.frame(fit))
    if (!param %in% colnames(X)) return(NULL)
    j <- match(param, colnames(X))
    if (nrow(data) != nrow(X)) {
        stop("RI data must be aligned to the estimation sample")
    }
    assignment <- data[[param]]

    # The clustering level need not be the assignment level. If treatment is
    # constant within cluster, permute whole clusters; otherwise permute rows.
    # Treating every clustered analysis as cluster-randomized silently changes the
    # design for individually randomized experiments.
    if (is.null(clusters)) {
        unit <- seq_len(nrow(X))
        assignment_level <- "row"
    } else {
        if (length(clusters) != nrow(X) || anyNA(clusters)) {
            stop("RI clusters must be complete and aligned to the estimation sample")
        }
        constant <- all(vapply(split(assignment, clusters, drop = TRUE), function(z) {
            length(unique(z)) == 1L
        }, logical(1)))
        unit <- if (constant) clusters else seq_len(nrow(X))
        assignment_level <- if (constant) "cluster" else "row"
    }
    units <- unique(unit)
    by_unit <- vapply(units, function(u) assignment[unit == u][1], numeric(1))
    pos <- match(unit, units)

    draws <- vapply(seq_len(sims), function(i) {
        permuted <- data
        permuted[[param]] <- sample(by_unit)[pos]
        Xp <- tryCatch(stats::model.matrix(
            fit$terms,
            data = permuted,
            contrasts.arg = fit$contrasts,
            xlev = fit$xlevels
        ), error = function(e) NULL)
        if (is.null(Xp) || nrow(Xp) != nrow(X) ||
            !identical(colnames(Xp), colnames(X))) return(NA_real_)
        fitp <- tryCatch(stats::lm.fit(Xp, y), error = function(e) NULL)
        if (is.null(fitp)) return(NA_real_)
        unname(fitp$coefficients[j])
    }, numeric(1))
    draws <- draws[is.finite(draws)]
    if (!length(draws)) return(NULL)
    extreme <- sum(abs(draws) >= abs(b_obs))
    list(p = (extreme + 1) / (length(draws) + 1), sims = length(draws),
         null_sd = stats::sd(draws), observed = b_obs, level = assignment_level)
}

# --------------------------------------------------------------------------- #
# reporting
# --------------------------------------------------------------------------- #

report <- function(res, param, ri = NULL) {
    n_cl <- attr(res, "n_clusters"); n_tr <- attr(res, "n_clusters_treated")
    cat("\n", strrep("=", 84), "\n", sprintf("SE LADDER for '%s'", param), "\n",
        strrep("=", 84), "\n", sep = "")
    cat(sprintf("observations %s", format(attr(res, "nobs"), big.mark = ",")))
    if (!is.na(n_cl)) cat(sprintf("   clusters %s", format(n_cl, big.mark = ",")))
    if (!is.na(n_tr)) cat(sprintf("   TREATED clusters %s", format(n_tr, big.mark = ",")))
    cat("\n\n")

    cat(sprintf("%-28s %10s %10s %22s %8s\n",
                "rung", "estimate", "SE", "95% CI", "dof"))
    cat(strrep("-", 84), "\n")
    for (i in seq_len(nrow(res))) {
        r <- res[i, ]
        cat(sprintf("%-28s %10.5f %10.5f  [%9.5f, %9.5f] %8s%s\n",
                    r$rung, r$estimate, r$se, r$ci_lo, r$ci_hi,
                    if (is.finite(r$dof)) sprintf("%.1f", r$dof) else "Inf",
                    if (nzchar(r$note)) paste0("   ", r$note) else ""))
    }

    if (!is.null(ri)) {
        cat(sprintf("\n%-28s %10.5f %10s  randomization inference p = %.4f (%s draws)\n",
                    "RI (permutation)", ri$observed, sprintf("%.5f", ri$null_sd),
                    ri$p, format(ri$sims, big.mark = ",")))
        cat(sprintf("   assignment permuted at the %s level. The SE column is the SD\n",
                    ri$level))
        cat("   of the null distribution, not an analytic standard error. The p-value\n")
        cat("   uses (extreme + 1) / (draws + 1).\n")
    }

    # --- the verdict ------------------------------------------------------- #
    cat("\n", strrep("-", 84), "\n", sep = "")
    have_ci <- is.finite(res$ci_lo) & is.finite(res$ci_hi)
    excl <- (res$ci_lo > 0) | (res$ci_hi < 0)
    ratio <- max(res$se, na.rm = TRUE) / min(res$se, na.rm = TRUE)
    cat(sprintf("widest SE / narrowest SE: %.2fx\n", ratio))
    if (any(!have_ci)) {
        cat(sprintf("no interval available for: %s\n",
                    paste(res$rung[!have_ci], collapse = ", ")))
    }

    fails <- character(0)
    incomplete <- FALSE

    # Zero within-cluster variation is NORMAL and correct for a cluster-assigned
    # treatment -- every cluster-randomised trial and every district-level policy
    # has it, and cluster-robust SEs are exactly the right tool there. It is only a
    # problem when the model ALSO absorbs fixed effects at or below the clustering
    # level, which leaves nothing to identify the coefficient and collapses the
    # cluster-robust meat matrix toward zero instead of erroring.
    ws <- attr(res, "within_share")
    has_fe <- isTRUE(attr(res, "has_absorbing_fe"))
    if (!is.na(ws) && ws < 0.01) {
        if (has_fe) {
            cat(sprintf("\nWITHIN-CLUSTER VARIATION IN '%s' IS %.3f%% OF TOTAL, AND THE MODEL\n",
                        param, 100 * ws))
            cat("ABSORBS FIXED EFFECTS AT OR BELOW THE CLUSTERING LEVEL.\n")
            cat("Nothing is left to identify the coefficient. The cluster-robust SE\n")
            cat("collapses toward zero rather than erroring, so every cluster rung above\n")
            cat("is meaningless. Either the fixed effects are at the wrong level or the\n")
            cat("clustering is.\n")
            fails <- c(fails, sprintf(
                "'%s' has no within-cluster variation (%.3f%%) and the model absorbs FE at that level",
                param, 100 * ws))
        } else {
            cat(sprintf("\nNote: '%s' is constant within cluster (%.3f%% of its variance is\n",
                        param, 100 * ws))
            cat("within). That is the normal shape of a cluster-assigned treatment, not a\n")
            cat("problem -- it is the reason to cluster. Two consequences: no fixed effect\n")
            cat("at or below this level can be added without absorbing the treatment, and\n")
            cat("the effective sample size is the cluster count, not the row count.\n")
        }
    }

    e <- excl[have_ci]
    decision_names <- res$rung[have_ci]
    if (!is.null(ri) && is.finite(ri$p)) {
        e <- c(e, ri$p < 0.05)
        decision_names <- c(decision_names, "RI (permutation)")
    }
    if (length(e) > 1 && any(e) && !all(e)) {
        fails <- c(fails, sprintf(
            "the 5%% decision rejects zero on [%s] and does not reject on [%s]",
            paste(decision_names[e], collapse = ", "),
            paste(decision_names[!e], collapse = ", ")))
    }
    # (Every rung shares one point estimate by construction, so a sign-change check
    # on res$estimate was dead code. What can change sign is the INTERVAL, and that
    # is the comparison above.)

    if (!is.na(n_cl)) {
        # The nominal count is a screen; the Satterthwaite dof on the CR2 rung is
        # the honest summary of leverage, imbalance and treated-cluster
        # concentration together. Judging "enough clusters" on the nominal count
        # alone called the bootstrap "decoration" on designs where 300 clusters
        # behave like a dozen.
        dof_cr2 <- res$dof[grepl("^CR2", res$rung)][1]
        effective_few <- !is.na(dof_cr2) && dof_cr2 < FEW_CLUSTERS
        few <- n_cl < FEW_CLUSTERS || (!is.na(n_tr) && n_tr < FEW_CLUSTERS)
        if (few || effective_few) {
            cat(sprintf("\nFEW CLUSTERS (%s total%s, threshold %d).\n",
                        format(n_cl, big.mark = ","),
                        if (!is.na(n_tr)) sprintf(", %s treated", format(n_tr, big.mark = ",")) else "",
                        FEW_CLUSTERS))
            if (!few && effective_few) {
                cat(sprintf("The nominal count clears the threshold, but the CR2\n"))
                cat(sprintf("Satterthwaite dof is %.1f -- imbalance, leverage, or the\n", dof_cr2))
                cat("concentration of treated clusters has cut the EFFECTIVE count.\n")
            }
            cat("Use CR2 with Satterthwaite degrees of freedom and compare it with\n")
            cat("the wild cluster bootstrap or randomization inference. Do not rely\n")
            cat("on CR0 or the Stata default.\n")
            if (!"wild cluster bootstrap" %in% res$rung && is.null(ri)) {
                incomplete <- TRUE
                cat("Neither small-sample comparison ran, so this ladder cannot make\n")
                cat("a stability claim. Re-run with --boot N or --ri N.\n")
            }
        } else {
            cat(sprintf("\n%s clusters%s, CR2 Satterthwaite dof %s -- both above the\n",
                        format(n_cl, big.mark = ","),
                        if (!is.na(n_tr)) sprintf(" (%s treated)", format(n_tr, big.mark = ",")) else "",
                        if (is.na(dof_cr2)) "n/a" else sprintf("%.1f", dof_cr2)))
            cat(sprintf("few-cluster threshold (%d). CR2 is sufficient; the bootstrap\n",
                        FEW_CLUSTERS))
            cat("mostly buys runtime here rather than coverage.\n")
        }
    }

    if (length(fails)) {
        cat("\nCONCLUSION MOVES ACROSS THE LADDER:\n")
        for (f in fails) cat(sprintf("  - %s\n", f))
        cat("\nThis is the result, not a robustness footnote. The estimate depends on\n")
        cat("a variance approximation rather than on the data. Say so in the paper;\n")
        cat("do not report the friendliest rung.\n")
        return(1L)
    }
    if (incomplete) {
        cat("\nINCOMPLETE LADDER: no stability verdict.\n")
        return(2L)
    }
    cat("\nThe conclusion is stable across the ladder. Report the rung the DESIGN\n")
    cat("justifies -- not the narrowest -- and put the ladder in the SI.\n")
    0L
}

# printed after the verdict so the note is copied from the rung, never retyped
suggest_note <- function(res, n_cl, n_tr) {
    default <- if (!is.na(n_cl)) "CR2 (Bell-McCaffrey)" else "HC2"
    if (!default %in% res$rung) default <- res$rung[nrow(res)]
    cat("\ntable note for the default rung (copy this, do not retype it):\n")
    cat(sprintf("  %s\n", ladder_note(res, default, n_cl, n_tr)))
    cat("If the design justifies a different rung, pass its name to ladder_note().\n")
}

# --------------------------------------------------------------------------- #

parse_args <- function(argv) {
    if (!length(argv) || argv[1] %in% c("-h", "--help")) {
        cat(readLines(sub("^--file=", "", grep("^--file=", commandArgs(FALSE),
                                               value = TRUE)))[2:24], sep = "\n")
        quit(status = 0)
    }
    out <- list(data = NULL, formula = NULL, param = NULL, clusters = NULL,
                boot = "9999", ri = NA_character_)
    known <- names(out)
    i <- 1L
    while (i <= length(argv)) {
        a <- argv[i]
        if (startsWith(a, "--")) {
            k <- sub("^--", "", a)
            # An unrecognised flag was absorbed silently, so `--cluster district`
            # (singular) produced the no-cluster ladder with no warning.
            if (!k %in% known) {
                cat(sprintf("se_ladder.R: unknown flag '--%s'. Known: %s\n", k,
                            paste0("--", known, collapse = " ")), file = stderr())
                quit(status = 2)
            }
            if (i + 1L > length(argv) || startsWith(argv[i + 1L], "--")) {
                cat(sprintf("se_ladder.R: --%s needs a value\n", k), file = stderr())
                quit(status = 2)
            }
            i <- i + 1L
            out[[k]] <- argv[i]
        } else {
            cat(sprintf("se_ladder.R: unexpected argument '%s'\n", a), file = stderr())
            quit(status = 2)
        }
        i <- i + 1L
    }
    out$boot <- suppressWarnings(as.integer(out$boot))
    if (is.na(out$boot) || out$boot < 0L) {
        cat("se_ladder.R: --boot must be a nonnegative integer\n", file = stderr())
        quit(status = 2)
    }
    if (is.na(out$ri)) {
        out$ri <- NA_integer_
    } else {
        out$ri <- suppressWarnings(as.integer(out$ri))
        if (is.na(out$ri) || out$ri < 0L) {
            cat("se_ladder.R: --ri must be a nonnegative integer\n", file = stderr())
            quit(status = 2)
        }
    }
    out
}

load_table <- function(path) {
    ext <- tolower(tools::file_ext(path))
    if (ext %in% c("parquet", "pq")) {
        if (!ok_arrow) stop("reading parquet needs the arrow package")
        return(as.data.frame(arrow::read_parquet(path)))
    }
    if (ext == "rds") return(as.data.frame(readRDS(path)))
    if (!ok_readr) stop("reading delimited text needs the readr package")
    as.data.frame(readr::read_csv(path, show_col_types = FALSE, progress = FALSE))
}

main <- function() {
    a <- parse_args(commandArgs(trailingOnly = TRUE))
    for (r in c("data", "formula", "param")) {
        if (is.null(a[[r]])) {
            cat(sprintf("se_ladder.R: --%s is required\n", r), file = stderr())
            quit(status = 2)
        }
    }
    df <- load_table(a$data)
    fml <- stats::as.formula(a$formula)
    has_fe <- grepl("|", a$formula, fixed = TRUE)

    # A "|" in the formula means fixed effects, which needs fixest. Absorbed models
    # do not work with sandwich/clubSandwich, so fall back to dummies when the FE
    # count is small enough to make that honest, and say so.
    if (grepl("|", a$formula, fixed = TRUE)) {
        rhs <- trimws(strsplit(a$formula, "|", fixed = TRUE)[[1]])
        if (length(rhs) > 2) {
            cat("se_ladder.R: this handles 'y ~ x | fe' only. A third |-separated\n",
                file = stderr())
            cat("part (an IV stage) would be silently dropped. Fit it with feols and\n",
                file = stderr())
            cat("an explicit vcov instead.\n", file = stderr())
            quit(status = 2)
        }
        # In fixest, `a^b` is the INTERACTION of two fixed effects. Rewriting it to
        # `a + b` fitted additive effects instead -- a different, less demanding
        # model -- and reported it as the one requested. It also understated the
        # level count, so the size guard below did not fire when it should have.
        terms_fe <- trimws(strsplit(rhs[2], "\\+")[[1]])
        terms_fe <- terms_fe[nzchar(terms_fe)]
        fes <- unique(unlist(strsplit(terms_fe, "\\^")))
        fes <- trimws(fes)
        absent <- fes[!fes %in% names(df)]
        if (length(absent)) {
            cat(sprintf("se_ladder.R: fixed-effect column(s) not in the data: %s\n",
                        paste(absent, collapse = ", ")), file = stderr())
            quit(status = 2)
        }
        as_factor <- vapply(terms_fe, function(t) {
            parts <- trimws(strsplit(t, "\\^")[[1]])
            if (length(parts) == 1) sprintf("factor(%s)", parts)
            else sprintf("interaction(%s, drop = TRUE)", paste(parts, collapse = ", "))
        }, character(1))
        n_lev <- sum(vapply(terms_fe, function(t) {
            parts <- trimws(strsplit(t, "\\^")[[1]])
            length(unique(do.call(paste, c(unname(df[parts]), sep = "\r"))))
        }, numeric(1)))
        cat(sprintf("fixed effects [%s] -> %s levels; entering them as factors so the\n",
                    paste(terms_fe, collapse = ", "), format(n_lev, big.mark = ",")))
        cat("full ladder is available (absorbed models do not expose a design matrix).\n")
        if (any(grepl("\\^", terms_fe))) {
            cat("'^' read as an interaction, matching fixest -- not as '+'.\n")
        }
        # CR2 inverts a per-cluster matrix whose size grows with the parameter
        # count, so dummy expansion is what makes this slow, not the sample size.
        # Measured: 14 levels ~35s, 300 levels did not finish in 120s.
        if (n_lev > 150) {
            cat(sprintf("\nse_ladder.R: %s dummy columns is too many for the CR2 and bootstrap\n",
                        format(n_lev, big.mark = ",")), file = stderr())
            cat("rungs to finish in reasonable time. Either estimate with feols() and a\n",
                file = stderr())
            cat("single explicit vcov, or run the ladder on a coarser fixed effect.\n",
                file = stderr())
            quit(status = 2)
        }
        fml <- stats::as.formula(paste(rhs[1], "+",
                                       paste(as_factor, collapse = " + ")))
    }

    # fwildclusterboot and stats::update() both re-evaluate fit$call, so the
    # formula and the data have to resolve from somewhere they can reach. Fitting
    # inside main()'s frame gives "object 'fml' not found" the moment either one
    # tries. Bind them globally and fit there.
    # The eval() below evaluates a fixed quoted call, not user text -- the only
    # user input is --formula, already parsed by as.formula() above.
    assign("fml", fml, envir = .GlobalEnv)
    assign("df", df, envir = .GlobalEnv)
    fit <- eval(quote(stats::lm(fml, data = df)), envir = .GlobalEnv)
    if (stats::df.residual(fit) <= 0) {
        cat("se_ladder.R: the model has no residual degrees of freedom; no variance estimator is defined.\n",
            file = stderr())
        quit(status = 2)
    }

    # A typo in --clusters used to give df[["nope"]] -> NULL -> the whole cluster
    # block skipped, no warning, and a final verdict of "stable across the ladder"
    # with exit 0. And `cl` was the FULL column while `fit` is on the complete
    # cases, so any NA in the model made every CR rung error inside a tryCatch and
    # vanish silently -- while the header still printed a cluster count taken from
    # the full column. Both are resolved here: fail loudly on a bad name, and
    # subset to the estimation sample.
    if (!is.null(a$clusters) && !a$clusters %in% names(df)) {
        cat(sprintf("se_ladder.R: --clusters column '%s' is not in the data.\n",
                    a$clusters), file = stderr())
        cat(sprintf("Columns: %s\n", paste(names(df), collapse = ", ")), file = stderr())
        quit(status = 2)
    }
    used <- match(rownames(stats::model.frame(fit)), rownames(df))
    if (anyNA(used) || length(used) != stats::nobs(fit)) {
        cat("se_ladder.R: could not align the fitted rows to the input data.\n",
            file = stderr())
        quit(status = 2)
    }
    dropped <- nrow(df) - length(used)
    if (dropped > 0) {
        cat(sprintf("note: %s of %s rows dropped for missingness; all counts below\n",
                    format(dropped, big.mark = ","), format(nrow(df), big.mark = ",")))
        cat("      refer to the estimation sample, not the file.\n")
    }
    cl <- if (!is.null(a$clusters)) df[[a$clusters]][used] else NULL
    tr <- if (a$param %in% names(df)) df[[a$param]][used] else NULL

    cat(sprintf("se_ladder.R  %s\n", a$data))
    cat(sprintf("formula: %s\n", deparse1(stats::formula(fit))))

    # A binary regressor does not prove random assignment. Require --ri N as the
    # user's assertion that complete randomization is the design; otherwise an
    # observational treatment would receive a meaningless permutation p-value.
    binary_treat <- !is.null(tr) && all(stats::na.omit(unique(tr)) %in% c(0, 1))
    ri_given <- !is.na(a$ri)
    n_ri <- if (ri_given) a$ri else 0L
    estimation_data <- df[used, , drop = FALSE]
    if (n_ri > 0 && !a$param %in% names(estimation_data)) {
        cat(sprintf(paste0(
            "se_ladder.R: --ri requires --param to name the raw assignment column; ",
            "'%s' is only a derived model term.\n"), a$param), file = stderr())
        return(2L)
    }

    res <- se_ladder(fit, param = a$param, clusters = cl, cluster_name = a$clusters,
                     treat = tr, boot = a$boot, has_fe = has_fe)

    if (ri_given && a$ri == 0) cat("\nrandomization inference disabled (--ri 0).\n")
    if (!ri_given && binary_treat) {
        cat("\nrandomization inference not run: a binary regressor does not establish\n")
        cat("random assignment. Pass --ri N only when complete randomization is the\n")
        cat("design; the script will permute clusters when treatment is constant within\n")
        cat("cluster and rows otherwise.\n")
    }
    ri <- if (n_ri > 0) {
        ri_pvalue(fit, estimation_data, a$param, cl, sims = n_ri)
    } else NULL
    if (n_ri > 0 && is.null(ri)) {
        cat("se_ladder.R: randomization inference produced no usable draws.\n",
            file = stderr())
        return(2L)
    }

    status <- report(res, a$param, ri)
    if (status != 2L) {
        suggest_note(res, attr(res, "n_clusters"), attr(res, "n_clusters_treated"))
    }
    status
}

if (sys.nframe() == 0L && !interactive()) quit(status = main())
