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
#
# Also usable as a library:
#     source("se_ladder.R"); se_ladder(fit, param = "treat", clusters = df$district)
#     se_note(fit)     # the sentence for a table note, generated from the object
#
# Exit code is 1 if the ladder changes the sign of the estimate or moves a 95%
# interval across zero, so it can be dropped into a pipeline as a gate.

suppressWarnings(suppressMessages({
    has <- function(p) requireNamespace(p, quietly = TRUE)
    ok_estimatr <- has("estimatr");   ok_fixest  <- has("fixest")
    ok_sandwich <- has("sandwich");   ok_lmtest  <- has("lmtest")
    ok_club     <- has("clubSandwich"); ok_wcb   <- has("fwildclusterboot")
    ok_arrow    <- has("arrow");      ok_readr   <- has("readr")
}))

# Below this many clusters -- or this many TREATED clusters -- CR2 undercovers and
# the wild cluster bootstrap or randomisation inference is required rather than
# optional. MacKinnon, Nielsen and Webb (2023).
FEW_CLUSTERS <- 40L

`%||%` <- function(a, b) if (is.null(a) || (length(a) == 1 && is.na(a))) b else a

# --------------------------------------------------------------------------- #
# se_note(): the sentence for a table note, generated from the fitted object.
# Typing this by hand is how 15 notes in one repo came to say "heteroskedasticity-
# robust" about columns that were iid and cluster-robust respectively.
# --------------------------------------------------------------------------- #

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
                      treat = NULL, boot = 9999L, data = NULL) {
    out <- list()
    b <- stats::coef(fit)[param]
    if (is.na(b)) stop(sprintf("parameter '%s' is not in the fitted model", param))
    n <- stats::nobs(fit)
    k <- length(stats::coef(fit))

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
        if (ok_wcb && inherits(fit, "lm") && !is.null(cluster_name)) {
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

    res <- do.call(rbind, out)
    attr(res, "n_clusters") <- n_cl
    attr(res, "n_clusters_treated") <- n_cl_treated
    attr(res, "within_share") <- within_var
    attr(res, "nobs") <- n
    res
}

# --------------------------------------------------------------------------- #
# randomisation inference: correct by construction when assignment is known
# --------------------------------------------------------------------------- #

ri_pvalue <- function(fit, data, param, clusters = NULL, sims = 2000L, seed = 1234567L) {
    set.seed(seed)
    if (!param %in% names(data)) return(NULL)
    b_obs <- unname(stats::coef(fit)[param])
    d <- data
    cl <- if (is.null(clusters)) seq_len(nrow(d)) else clusters
    ucl <- unique(cl)
    assign_by_cluster <- tapply(d[[param]], cl, function(z) z[1])
    draws <- vapply(seq_len(sims), function(i) {
        perm <- sample(assign_by_cluster)
        d[[param]] <- unname(perm[match(cl, ucl)])
        unname(stats::coef(stats::update(fit, data = d))[param])
    }, numeric(1))
    list(p = mean(abs(draws) >= abs(b_obs)), sims = sims,
         null_sd = stats::sd(draws), observed = b_obs)
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
        cat(sprintf("\n%-28s %10.5f %10s  randomisation inference p = %.4f (%s draws)\n",
                    "RI (permutation)", ri$observed, sprintf("%.5f", ri$null_sd),
                    ri$p, format(ri$sims, big.mark = ",")))
        cat("   ^ the SE column here is the SD of the null distribution, not an\n")
        cat("     analytic standard error. The p-value is the object of interest.\n")
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

    ws <- attr(res, "within_share")
    if (!is.na(ws) && ws < 0.01) {
        cat(sprintf("\nWITHIN-CLUSTER VARIATION IN '%s' IS %.3f%% OF TOTAL.\n", param, 100 * ws))
        cat("The regressor is (near-)constant within cluster. Any fixed effect at or\n")
        cat("below the clustering level absorbs it, and the cluster-robust SE then\n")
        cat("collapses toward zero instead of erroring -- every cluster rung above is\n")
        cat("meaningless. Either the FE are at the wrong level or the clustering is.\n")
        fails <- c(fails, sprintf(
            "no within-cluster variation in '%s' (%.3f%% of variance); cluster rungs are invalid",
            param, 100 * ws))
    }

    e <- excl[have_ci]
    if (length(e) > 1 && any(e) && !all(e)) {
        fails <- c(fails, sprintf(
            "the 95%% interval excludes zero on [%s] and includes it on [%s]",
            paste(res$rung[have_ci][e], collapse = ", "),
            paste(res$rung[have_ci][!e], collapse = ", ")))
    }
    if (length(unique(sign(res$estimate))) > 1) {
        fails <- c(fails, "the estimate changes sign across rungs")
    }

    if (!is.na(n_cl)) {
        few <- n_cl < FEW_CLUSTERS || (!is.na(n_tr) && n_tr < FEW_CLUSTERS)
        if (few) {
            cat(sprintf("\nFEW CLUSTERS (%s total%s, threshold %d).\n",
                        format(n_cl, big.mark = ","),
                        if (!is.na(n_tr)) sprintf(", %s treated", format(n_tr, big.mark = ",")) else "",
                        FEW_CLUSTERS))
            cat("CR2 undercovers here. Report the wild cluster bootstrap or\n")
            cat("randomisation inference, not CR0 or the Stata default.\n")
        } else {
            cat(sprintf("\nCluster count (%s) is above the few-cluster threshold (%d).\n",
                        format(n_cl, big.mark = ","), FEW_CLUSTERS))
            cat("CR2 is sufficient. The bootstrap buys runtime, not coverage --\n")
            cat("reporting it here is decoration.\n")
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
    cat("\nThe conclusion is stable across the ladder. Report the rung the DESIGN\n")
    cat("justifies -- not the narrowest -- and put the ladder in the SI.\n")
    0L
}

# --------------------------------------------------------------------------- #

parse_args <- function(argv) {
    if (!length(argv) || argv[1] %in% c("-h", "--help")) {
        cat(readLines(sub("^--file=", "", grep("^--file=", commandArgs(FALSE),
                                               value = TRUE)))[2:24], sep = "\n")
        quit(status = 0)
    }
    out <- list(data = NULL, formula = NULL, param = NULL, clusters = NULL,
                boot = "9999", ri = "0")
    i <- 1L
    while (i <= length(argv)) {
        a <- argv[i]
        if (startsWith(a, "--")) { k <- sub("^--", "", a); i <- i + 1L; out[[k]] <- argv[i] }
        i <- i + 1L
    }
    out$boot <- as.integer(out$boot); out$ri <- as.integer(out$ri)
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

    # A "|" in the formula means fixed effects, which needs fixest. Absorbed models
    # do not work with sandwich/clubSandwich, so fall back to dummies when the FE
    # count is small enough to make that honest, and say so.
    if (grepl("|", a$formula, fixed = TRUE)) {
        rhs <- trimws(strsplit(a$formula, "|", fixed = TRUE)[[1]])
        fes <- strsplit(gsub("\\^", " + ", rhs[2]), "\\+")[[1]]
        fes <- trimws(fes)
        n_lev <- sum(vapply(fes, function(f) length(unique(df[[f]])), numeric(1)))
        cat(sprintf("fixed effects [%s] -> %s levels; entering them as factors so the\n",
                    paste(fes, collapse = ", "), format(n_lev, big.mark = ",")))
        cat("full ladder is available (absorbed models do not expose a design matrix).\n")
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
                                       paste(sprintf("factor(%s)", fes), collapse = " + ")))
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

    cl <- if (!is.null(a$clusters)) df[[a$clusters]] else NULL
    tr <- if (a$param %in% names(df)) df[[a$param]] else NULL

    cat(sprintf("se_ladder.R  %s\n", a$data))
    cat(sprintf("formula: %s\n", deparse1(stats::formula(fit))))
    cat(sprintf("note as generated: %s\n", se_note(fit, cl)))

    res <- se_ladder(fit, param = a$param, clusters = cl, cluster_name = a$clusters,
                     treat = tr, boot = a$boot)
    ri <- if (a$ri > 0) ri_pvalue(fit, df, a$param, cl, sims = a$ri) else NULL
    report(res, a$param, ri)
}

if (sys.nframe() == 0L && !interactive()) quit(status = main())
