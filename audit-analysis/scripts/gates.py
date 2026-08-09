"""gates.py
Assertions to embed in a pipeline so a fixed bug fails loudly if it returns.

A repair without a gate is a repair that regresses. Every one of these
corresponds to a real bug that reached a compiled manuscript; each raises with
a message that says what went wrong in the language of the analysis, not the
language of the traceback, because the person who trips it in eighteen months
will not remember the incident.

Import what you need:

    from gates import assert_unique_key, assert_row_conservation

The costlier gates (`assert_recovers_known_truth`) belong in a test or a
once-per-run check, not in a hot loop.
"""

import numpy as np
import pandas as pd

__all__ = [
    "assert_unique_key",
    "assert_row_conservation",
    "assert_injective_transform",
    "assert_zero_is_structural",
    "assert_same_denominator",
    "assert_bounded",
    "assert_inclusion_probs_sum_to_n",
    "assert_bootstrap_draws_usable",
    "assert_published_is_conservative",
    "assert_decomposition_reconciles",
    "assert_recovers_known_truth",
]


def assert_unique_key(df, keys, name="frame"):
    """The join key must be unique on the side that must be unique."""
    dup = int(df.duplicated(subset=keys).sum())
    if dup:
        example = df[df.duplicated(subset=keys, keep=False)].head(3)
        raise ValueError(
            f"{name}: {keys} is not unique -- {dup:,} duplicate rows. A merge on "
            f"this key will fan out and silently reweight every downstream mean.\n"
            f"{example}"
        )


def assert_row_conservation(before, after, expected=None, name="merge"):
    """Rows disappear without error in more ways than they appear."""
    n_before = len(before) if hasattr(before, "__len__") else int(before)
    n_after = len(after) if hasattr(after, "__len__") else int(after)
    target = expected if expected is not None else n_before
    if n_after != target:
        raise ValueError(
            f"{name}: {n_before:,} rows in, {n_after:,} out, {target:,} expected "
            f"({n_after - target:+,}). Check whether the loss is differential across "
            "groups or waves -- random loss costs power, differential loss is bias."
        )


def assert_injective_transform(original, transformed, name="key transform"):
    """String key transforms collide: `.`->`_`, case folding, truncation."""
    n_in = pd.Series(original).nunique()
    n_out = pd.Series(transformed).nunique()
    if n_in != n_out:
        raise ValueError(
            f"{name}: {n_in:,} distinct values became {n_out:,} -- "
            f"{n_in - n_out:,} collision(s). Two originally distinct units now "
            "share a key and will be merged into one."
        )


def assert_zero_is_structural(df, value_col, observed_col, name=None):
    """A zero must mean 'measured, none found', never 'not measured'.

    `observed_col` is the flag saying the measurement was actually attempted.
    Raises if any row is zero where nothing was measured.
    """
    name = name or value_col
    observed = df[observed_col].astype(bool)
    bad = int(((df[value_col] == 0) & ~observed).sum())
    if bad:
        raise ValueError(
            f"{name}: {bad:,} rows are 0 where {observed_col} is False -- "
            "'not measured' has been recorded as 'measured, none found'. If the "
            "rate of unmeasured rows differs across groups or waves, this "
            "manufactures a trend rather than attenuating one."
        )


def assert_same_denominator(df, rate_cols, denominator, tol=1e-9):
    """Every rate compared against another must be built on the same base.

    Each entry of `rate_cols` is (rate_col, numerator_col).
    """
    bad = []
    for rate_col, num_col in rate_cols:
        implied = df[num_col] / df[rate_col].replace(0, np.nan)
        diff = (implied - df[denominator]).abs().max()
        if pd.notna(diff) and diff > tol:
            bad.append((rate_col, float(diff)))
    if bad:
        detail = "; ".join(f"{c} off by up to {d:,.4g}" for c, d in bad)
        raise ValueError(
            f"rate column(s) are not built on '{denominator}': {detail}. "
            "Comparing rates with different denominators compares different "
            "quantities -- this is the single most common number-changing bug."
        )


def assert_bounded(series, lo=0.0, hi=1.0, name="value"):
    """A share is in [0, 1]. Out of range is a construction bug, always."""
    s = pd.Series(series).dropna()
    bad = int(((s < lo) | (s > hi)).sum())
    if bad:
        raise ValueError(
            f"{name}: {bad:,} values outside [{lo}, {hi}] "
            f"(observed [{s.min():.6g}, {s.max():.6g}])."
        )


def assert_inclusion_probs_sum_to_n(pi, n, tol=0.5):
    """Any fixed-size-n design satisfies sum(pi) = n. One line, falsifies a
    wrong formula immediately.

    `pi = min(n*p, 1)` is NOT the inclusion probability for successive sampling
    (numpy's `choice(replace=False, p=...)`), which has no closed form -- in the
    case that motivated this gate, sum(min(n*p,1)) was 91.10 for n = 100.
    """
    total = float(np.asarray(pi).sum())
    if abs(total - n) > tol:
        raise ValueError(
            f"inclusion probabilities sum to {total:.2f}, not {n}. A fixed-size-n "
            "design must satisfy sum(pi) = n, so this formula does not describe "
            "the design that drew the sample. Simulate pi under the actual design."
        )


def assert_bootstrap_draws_usable(n_ok, n_requested, min_fraction=0.5):
    """A standard error built on the draws that happened to converge is not the
    standard error you think it is."""
    if n_ok < min_fraction * n_requested:
        raise ValueError(
            f"only {n_ok:,} of {n_requested:,} bootstrap draws fit "
            f"({100 * n_ok / n_requested:.0f}%). The interval would describe the "
            "draws that converged, which is a selected subsample."
        )


def assert_published_is_conservative(estimates, published_key, name="estimate"):
    """The useful robustness claim is not 'it survives' but 'the published
    number is the smallest of the defensible family'. Gate it so it cannot go
    stale in prose.

    `estimates` maps specification name -> point estimate.
    """
    published = estimates[published_key]
    smaller = {k: v for k, v in estimates.items() if v < published and k != published_key}
    if smaller:
        detail = "; ".join(f"{k} = {v:,.4g}" for k, v in sorted(smaller.items()))
        raise ValueError(
            f"{name}: the published specification ({published:,.4g}) is no longer the "
            f"most conservative -- {detail}. Any prose claiming the published "
            "estimate is a floor must be revised."
        )


def assert_decomposition_reconciles(components, total, tol=1e-6, name="decomposition"):
    """Components plus interaction must equal the total they decompose -- and
    the total must be the quantity the paper actually headlines."""
    got = float(np.sum(components))
    if abs(got - total) > tol:
        raise ValueError(
            f"{name}: components sum to {got:,.6g}, total is {total:,.6g} "
            f"(off by {got - total:+,.6g}). Note this checks only internal "
            "consistency; separately confirm `total` is the paper's estimand and "
            "not, say, a visit-weighted analogue of a person-level claim."
        )


def assert_recovers_known_truth(
    pipeline, truth, tol, n_sims=100, seed=0, name="pipeline"
):
    """Fake-data simulation: the strongest check here, and the least used.

    `pipeline(rng)` simulates data with parameters `truth` and returns the
    estimate. If the procedure cannot recover a planted answer, no amount of
    staring at real output will reveal it -- with real data you never know the
    answer.
    """
    rng = np.random.default_rng(seed)
    draws = np.array([pipeline(rng) for _ in range(n_sims)])
    bias = float(np.mean(draws) - truth)
    if abs(bias) > tol:
        raise ValueError(
            f"{name}: over {n_sims} simulations the estimator returns "
            f"{np.mean(draws):,.6g} against a planted truth of {truth:,.6g} "
            f"(bias {bias:+,.6g}, tolerance {tol:g}). The procedure does not "
            "recover what it is supposed to estimate."
        )
    return bias
