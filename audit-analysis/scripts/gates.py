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


def _finite(value, what, name):
    """A gate whose statistic is NaN must fail, not pass.

    `abs(nan) > tol` is False, so every threshold comparison in this file used to
    return silently when its input contained a missing value -- the worst possible
    behavior for a gate, because "no exception" reads as "checked and clean". Any
    statistic that reaches a threshold test goes through here first.
    """
    v = float(value)
    if not np.isfinite(v):
        raise ValueError(
            f"{name}: {what} is {value!r}, so the check could not run. A gate that "
            "cannot compute its own statistic has not passed -- it has abstained. "
            "Find the missing or infinite input before proceeding."
        )
    return v


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
    obs = df[observed_col]
    # `astype(bool)` on an object column makes EVERY non-empty string True --
    # including "False", "0" and "no" -- and makes NaN True as well. A flag read
    # from CSV as the strings True/False therefore produced `~observed` all-False,
    # `bad == 0`, and a gate that passed the data it exists to reject. Refuse the
    # ambiguous dtypes instead of guessing at them.
    if obs.isna().any():
        raise ValueError(
            f"{name}: '{observed_col}' contains {int(obs.isna().sum()):,} missing "
            "values. 'We do not know whether it was measured' is not the same as "
            "'it was measured' -- recode the missing rows explicitly first."
        )
    if obs.dtype == object or pd.api.types.is_string_dtype(obs):
        raise ValueError(
            f"{name}: '{observed_col}' has dtype {obs.dtype}. Casting strings to "
            "bool makes every non-empty value True, including \"False\" and \"0\", "
            "so this gate would pass anything. Convert it to a real boolean or a "
            "0/1 integer first."
        )
    if not pd.api.types.is_bool_dtype(obs):
        extra = set(pd.unique(obs.dropna())) - {0, 1, True, False}
        if extra:
            raise ValueError(
                f"{name}: '{observed_col}' is not boolean and holds values outside "
                f"{{0, 1}}: {sorted(extra)[:5]}. Recode it before gating on it."
            )
    observed = obs.astype(bool)
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
        # Zero rates cannot reconstruct a denominator, so they are excluded -- but
        # if that leaves nothing, the check did not run and must say so rather than
        # passing on an all-NaN comparison.
        rate = df[rate_col].replace(0, np.nan)
        usable = rate.notna() & df[num_col].notna() & df[denominator].notna()
        if not usable.any():
            raise ValueError(
                f"{rate_col}: no row has a non-zero rate and a non-missing "
                f"numerator and denominator, so '{denominator}' could not be "
                "reconstructed anywhere. This is an abstention, not a pass."
            )
        implied = df.loc[usable, num_col] / rate[usable]
        # Relative, not absolute: float64 carries ~1e-16 relative error, so an
        # absolute 1e-9 false-alarms on any denominator above about 10^7.
        rel = ((implied - df.loc[usable, denominator]).abs()
               / df.loc[usable, denominator].abs().clip(lower=1.0))
        diff = _finite(rel.max(), f"max relative deviation for {rate_col}", rate_col)
        if diff > tol:
            bad.append((rate_col, diff))
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
    total = _finite(np.asarray(pi, dtype=float).sum(),
                    "the sum of the inclusion probabilities",
                    "inclusion probabilities")
    if abs(total - n) > tol:
        raise ValueError(
            f"inclusion probabilities sum to {total:.2f}, not {n}. A fixed-size-n "
            "design must satisfy sum(pi) = n, so this formula does not describe "
            "the design that drew the sample. Simulate pi under the actual design."
        )


def assert_bootstrap_draws_usable(n_ok, n_requested, min_fraction=0.5):
    """A standard error built on the draws that happened to converge is not the
    standard error you think it is."""
    if n_requested <= 0:
        raise ValueError(
            f"{n_requested:,} bootstrap draws were requested. A gate on zero draws "
            "used to pass silently, because 0 < 0 is False."
        )
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
    if published_key not in estimates:
        raise ValueError(
            f"{name}: '{published_key}' is not in the estimate family "
            f"({sorted(estimates)}). Name the published specification exactly."
        )
    published = _finite(estimates[published_key],
                        f"the published estimate '{published_key}'", name)
    for k, v in estimates.items():
        _finite(v, f"the estimate for '{k}'", name)

    # "Most conservative" means smallest in MAGNITUDE. Comparing signed values
    # inverts the gate for any negative effect -- a reduction, a closing gap, a
    # cost saving. With published = -0.5 it used to raise on -0.9 (a LARGER effect,
    # perfectly safe to have in the family) and pass silently on -0.2 (a genuinely
    # more conservative alternative, which is the thing the gate exists to catch).
    smaller = {
        k: v for k, v in estimates.items()
        if abs(v) < abs(published) and k != published_key
    }
    if smaller:
        detail = "; ".join(f"{k} = {v:,.4g}" for k, v in sorted(smaller.items()))
        raise ValueError(
            f"{name}: the published specification ({published:,.4g}) is no longer the "
            f"most conservative -- {detail} {'is' if len(smaller) == 1 else 'are'} "
            "smaller in magnitude. Any prose claiming the published estimate is a "
            "floor must be revised."
        )


def assert_decomposition_reconciles(components, total, tol=1e-6, name="decomposition"):
    """Components plus interaction must equal the total they decompose -- and
    the total must be the quantity the paper actually headlines."""
    got = _finite(np.sum(np.asarray(components, dtype=float)),
                  "the sum of the components", name)
    total = _finite(total, "the total being decomposed", name)
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
    draws = np.asarray([pipeline(rng) for _ in range(n_sims)], dtype=float)

    # A pipeline that blows up on some draws must not be averaged over the ones
    # that survived -- that is the same selected-subsample error as
    # assert_bootstrap_draws_usable, and it used to pass silently because
    # np.mean of an array containing NaN is NaN and abs(nan) > tol is False.
    n_bad = int((~np.isfinite(draws)).sum())
    if n_bad:
        raise ValueError(
            f"{name}: {n_bad:,} of {n_sims:,} simulation draws were not finite. "
            "Averaging over the draws that converged would describe a selected "
            "subsample. Fix the pipeline, or report the failure rate as the result."
        )

    bias = _finite(np.mean(draws) - truth, "the estimated bias", name)
    # The bias is itself a mean over n_sims draws, so it carries its own Monte
    # Carlo error. Without accounting for it, a tolerance tighter than the MCSE
    # fails a correct estimator most of the time, and a tolerance much wider than
    # it passes a genuinely biased one -- the verdict tracks the simulation size
    # rather than the estimator.
    mcse = float(draws.std(ddof=1) / np.sqrt(len(draws))) if len(draws) > 1 else 0.0
    if abs(bias) > tol + 2 * mcse:
        raise ValueError(
            f"{name}: over {n_sims} simulations the estimator returns "
            f"{np.mean(draws):,.6g} against a planted truth of {truth:,.6g} "
            f"(bias {bias:+,.6g}, tolerance {tol:g}, Monte Carlo SE {mcse:,.4g}). "
            "The procedure does not recover what it is supposed to estimate."
        )
    return bias
