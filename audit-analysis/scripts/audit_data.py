"""audit_data.py
Mechanical integrity and EDA sweep over an analysis dataset.

Runs the Tier-1 and Tier-2A checks that need no judgement, which is where most
number-changing bugs actually live. Everything it reports is a *candidate*: the
script says "this column is 47% missing and the missing rate differs by group",
not "this is a bug". Deciding is the analyst's job.

Usage:
    python audit_data.py DATA.csv
    python audit_data.py DATA.parquet --key caseid
    python audit_data.py DATA.csv --key wave id --group treatment wave
    python audit_data.py DATA.csv --outcome y --covariates a b c   # adds leverage

Exit code is 1 if any HARD check fails (duplicate keys, out-of-range shares),
so it can be dropped into a pipeline as a gate.
"""

import argparse
import sys

import numpy as np
import pandas as pd

# A share/rate/proportion should sit in [0, 1]; flagged if the name suggests one
# and the values do not. Deliberately name-based -- it is a heuristic that costs
# nothing and has caught real construction bugs.
SHARE_HINTS = ("share", "pct", "percent", "prop", "frac", "rate_of")
RATE_HINTS = ("_rate", "rate_", "per_", "_per")

HARD_FAIL = []


def _fail(msg):
    HARD_FAIL.append(msg)
    return f"FAIL  {msg}"


def load(path):
    if str(path).endswith((".parquet", ".pq")):
        return pd.read_parquet(path)
    if str(path).endswith((".dta",)):
        return pd.read_stata(path)
    return pd.read_csv(path)


def section(title):
    print(f"\n{'=' * 72}\n{title}\n{'=' * 72}")


def shape_and_keys(df, keys):
    section("1. SHAPE AND KEYS")
    print(f"rows {len(df):,}   columns {df.shape[1]}")
    if not keys:
        print("no --key given; skipping uniqueness (pass one, it is the cheapest check)")
        return
    dup = int(df.duplicated(subset=keys).sum())
    n_uniq = len(df.drop_duplicates(subset=keys))
    print(f"key {keys}: {n_uniq:,} distinct, {dup:,} duplicate rows")
    if dup:
        print(_fail(f"key {keys} is not unique -- {dup:,} duplicate rows"))
        print(df[df.duplicated(subset=keys, keep=False)].head(6).to_string())


def missingness(df, groups):
    section("2. MISSINGNESS (level, and -- what matters -- differential)")
    miss = df.isna().mean().sort_values(ascending=False)
    nonzero = miss[miss > 0]
    if nonzero.empty:
        print("no missing values anywhere")
    else:
        print("columns with any missing:")
        for col, frac in nonzero.items():
            print(f"  {col:44s} {100 * frac:6.2f}%  ({int(df[col].isna().sum()):,})")

    if not groups:
        print(
            "\nno --group given. Overall missingness is nearly useless on its own:\n"
            "the question is always whether the RATE DIFFERS across groups or waves.\n"
            "Re-run with --group <arm|wave|period> before concluding anything."
        )
        return
    for g in groups:
        if g not in df.columns:
            print(f"\n  (group '{g}' not a column, skipped)")
            continue
        by = df.groupby(g).apply(lambda d: d.isna().mean(), include_groups=False)
        spread = (by.max() - by.min()).sort_values(ascending=False)
        differential = spread[spread > 0.02]
        print(f"\ndifferential missingness by '{g}' (max-min fill rate > 2pp):")
        if differential.empty:
            print("  none")
        for col, s in differential.items():
            rates = "  ".join(f"{k}={100 * v:.1f}%" for k, v in by[col].items())
            print(f"  {col:36s} spread {100 * s:5.1f}pp   {rates}")
        if not differential.empty:
            print(
                "  ^ differential missingness MANUFACTURES trends and gaps.\n"
                "    Constant missingness only attenuates. Check each of these."
            )


def zeros_vs_missing(df):
    section("3. ZEROS VS MISSING")
    num = df.select_dtypes("number")
    rows = []
    for col in num.columns:
        z = int((num[col] == 0).sum())
        m = int(num[col].isna().sum())
        if z or m:
            rows.append((col, z, 100 * z / len(df), m, 100 * m / len(df)))
    if not rows:
        print("no zeros and no missing in numeric columns")
        return
    print(f"{'column':44s} {'zeros':>9s} {'%':>7s} {'missing':>9s} {'%':>7s}")
    for col, z, zp, m, mp in sorted(rows, key=lambda r: -r[1]):
        print(f"{col:44s} {z:9,} {zp:6.1f}% {m:9,} {mp:6.1f}%")
    print(
        "\nFor every column with BOTH: is the zero 'measured, none found' or\n"
        "'not measured'? If the data cannot tell them apart, neither can the model."
    )


def dtype_traps(df):
    section("4. DTYPE TRAPS")
    hits = 0
    for col in df.columns:
        s = df[col]
        if s.dtype == object:
            vals = set(s.dropna().unique()[:20])
            if vals and vals <= {True, False, 0, 1, "True", "False"}:
                hits += 1
                print(
                    f"  {col:44s} boolean-valued but OBJECT dtype.\n"
                    f"    `~{col}` is integer bitwise NOT here (~True == -2), not\n"
                    f"    logical negation. Cast with .astype(bool) before masking."
                )
        if hasattr(s.dtype, "na_value") and s.dtype.na_value is pd.NA:
            hits += 1
            print(
                f"  {col:44s} pandas-NA dtype. .describe() on this returns\n"
                f"    count/unique/top/freq, NOT mean/std/quantiles. A summary table\n"
                f"    built from it will silently report the wrong statistic."
            )
    if not hits:
        print("none found")


def ranges(df):
    section("5. VALUES OUTSIDE THEIR LOGICAL RANGE")
    hits = 0
    for col in df.select_dtypes("number").columns:
        low = col.lower()
        s = df[col].dropna()
        if s.empty:
            continue
        if any(h in low for h in SHARE_HINTS):
            bad = int(((s < 0) | (s > 1)).sum())
            if bad and s.max() > 1.0000001:
                hits += 1
                print(
                    _fail(
                        f"{col} looks like a share but ranges "
                        f"[{s.min():.4g}, {s.max():.4g}] ({bad:,} outside [0,1])"
                    )
                )
        if ("count" in low or "n_" in low or low.startswith("num")) and s.min() < 0:
            hits += 1
            print(_fail(f"{col} looks like a count but has negatives (min {s.min()})"))
    if not hits:
        print("none found")


def distributions(df):
    section("6. DISTRIBUTIONS, SKEW AND TAILS")
    num = df.select_dtypes("number")
    rows = []
    for col in num.columns:
        s = num[col].dropna()
        if len(s) < 10 or s.nunique() < 3:
            continue
        med = s.median()
        rows.append(
            {
                "column": col,
                "median": med,
                "max": s.max(),
                "max/med": s.max() / med if med else np.inf,
                "skew": s.skew(),
                "top1%_mass": (
                    s.nlargest(max(1, len(s) // 100)).sum() / s.sum() if s.sum() else 0
                ),
            }
        )
    if not rows:
        print("nothing with enough variation to summarise")
        return
    out = pd.DataFrame(rows).sort_values("skew", key=abs, ascending=False)
    with pd.option_context("display.width", 200, "display.max_rows", 200):
        print(out.to_string(index=False, float_format=lambda x: f"{x:,.3f}"))
    heavy = out[(out["skew"].abs() > 2) | (out["max/med"] > 20)]
    if not heavy.empty:
        print(
            f"\n{len(heavy)} column(s) are heavily skewed. Before choosing a method,\n"
            "decide whether the MEAN or the MEDIAN is the estimand -- see\n"
            "checks/tier2-statistical.md section F. Asymptotic SEs are optimistic here."
        )


def denominators(df):
    section("7. RATE COLUMNS AND THEIR RECONSTRUCTED DENOMINATORS")
    num = df.select_dtypes("number")
    rate_cols = [c for c in num.columns if any(h in c.lower() for h in RATE_HINTS)]
    if not rate_cols:
        print("no columns whose name suggests a rate; skipping")
        return
    # A denominator may legitimately contain zeros (a unit observed zero times).
    # Requiring strict positivity here produced false NOT-FOUNDs on the very
    # column the rates were actually built from, so allow zeros and compare only
    # where the denominator is positive.
    cands = [
        c
        for c in num.columns
        if c not in rate_cols and (num[c] >= 0).all() and num[c].nunique() > 10
    ]
    print(
        f"{len(rate_cols)} rate-like column(s); testing each against "
        f"{len(cands)} candidate denominator(s).\n"
        "A rate whose numerator is present should reconstruct EXACTLY.\n"
    )
    resolved = {}
    for rc in rate_cols:
        stem = rc
        for h in ("_rate", "rate_", "_per", "per_"):
            stem = stem.replace(h, "")
        if stem not in num.columns:
            print(f"  {rc:44s} no numerator column '{stem}'; cannot reconstruct")
            continue
        matched = None
        for d in cands:
            ok = num[d] > 0
            if ok.sum() < 10:
                continue
            with np.errstate(divide="ignore", invalid="ignore"):
                diff = (num.loc[ok, stem] / num.loc[ok, d] - num.loc[ok, rc]).abs().max()
            if pd.notna(diff) and diff < 1e-9:
                matched = d
                break
        resolved.setdefault(matched, []).append(rc)
        print(f"  {rc:44s} numerator '{stem}' -> denominator: {matched or 'NOT FOUND'}")

    known = {k: v for k, v in resolved.items() if k is not None}
    if len(known) > 1:
        print(f"\n  *** {len(known)} DIFFERENT denominators in use across rate columns:")
        for d, cols in known.items():
            print(
                f"      {d:28s} {len(cols)} column(s): {', '.join(cols[:4])}"
                + (" ..." if len(cols) > 4 else "")
            )
        print(
            "      Any comparison, regression, or table mixing rates from two of\n"
            "      these groups compares different quantities. This is Tier 1\n"
            "      check 1 and the highest-yield finding in the skill."
        )
    print(
        "\nEvery rate compared against another must share a denominator.\n"
        "Where two differ, that is Tier 1 check 1 and it is worth a hard look."
    )


def leverage(df, outcome, covariates):
    if not outcome:
        return
    section("8. LEVERAGE ON THE HEADLINE OUTCOME")
    try:
        import statsmodels.formula.api as smf
    except ImportError:
        print("statsmodels not installed; skipping")
        return
    covs = covariates or []
    if not covs:
        print("no --covariates given; skipping")
        return
    d = df[[outcome] + covs].dropna()
    formula = f"{outcome} ~ " + " + ".join(covs)
    full = smf.ols(formula, d).fit(cov_type="HC1")
    print(f"n = {int(full.nobs):,}   formula: {formula}\n")
    print(f"{'term':32s} {'full':>12s} {'worst LOO':>12s} {'shift':>10s}")
    for term in full.params.index:
        if term == "Intercept":
            continue
        base = full.params[term]
        worst, worst_i = base, None
        for i in range(len(d)):
            b = smf.ols(formula, d.drop(d.index[i])).fit().params[term]
            if abs(b - base) > abs(worst - base):
                worst, worst_i = b, i
        shift = abs(worst - base) / (abs(base) if base else 1)
        flag = "  <-- one observation moves this >10%" if shift > 0.10 else ""
        print(f"{term:32s} {base:12.4f} {worst:12.4f} {100 * shift:9.1f}%{flag}")
        if worst_i is not None and shift > 0.10:
            print(f"    driven by row {d.index[worst_i]}")


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("path")
    ap.add_argument("--key", nargs="*", default=[], help="columns that must be unique")
    ap.add_argument("--group", nargs="*", default=[], help="arm/wave/period columns")
    ap.add_argument("--outcome", help="headline outcome, for the leverage check")
    ap.add_argument("--covariates", nargs="*", default=[])
    a = ap.parse_args()

    df = load(a.path)
    print(f"audit_data.py  {a.path}")

    shape_and_keys(df, a.key)
    missingness(df, a.group)
    zeros_vs_missing(df)
    dtype_traps(df)
    ranges(df)
    distributions(df)
    denominators(df)
    leverage(df, a.outcome, a.covariates)

    section("SUMMARY")
    if HARD_FAIL:
        print(f"{len(HARD_FAIL)} hard failure(s):")
        for m in HARD_FAIL:
            print(f"  - {m}")
        return 1
    print("no hard failures. The soft findings above still need judgement --")
    print("this script narrows where to look, it does not decide.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
