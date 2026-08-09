"""Evidence for the skill's central claim: scanning slices for a correlate invents causes.

SKILL.md asserts under "Finding a correlate is not finding a cause" that the paper's first
generator manufactures false causes, and that q-values plus a minimum support plus confirmation
on a held-out half suppress them at no cost to real detection. That is a testable claim, so it is
tested here rather than argued.

The design is the skill's own rule applied to the skill (isolation-and-evidence.md §5, §8): plant
a cause and confirm the procedure recovers it; run with no cause and confirm it stays silent. A
method that only passes the first half is returning noise, and a method that only passes the
second half is useless.

What this does *not* establish: the simulation has independent dimensions and a single planted
cause. Real failure data has correlated dimensions and often several concurrent causes, where the
naive method does worse and the disciplined method also loses power. Read the null column as a
lower bound on the false-positive problem, not an estimate of it.

Usage:
    python3 test_slice_discipline.py            # 300 replications, ~4 min
    python3 test_slice_discipline.py --quick    # 30 replications, ~25s

Exit code is 1 if the disciplined procedure fires on more than 5% of null replications or
recovers the planted cause in fewer than 80%, so it can be used as a gate on any change to the
thresholds in this file.
"""

import numpy as np
from scipy import stats

N_ROWS, N_DIMS, REPS = 20_000, 15, 300
BASE_RATE, MIN_SUPPORT, ALPHA = 0.10, 100, 0.05
PLANTED_DIM, PLANTED_VAL, PLANTED_RATE = 7, 0, 0.25


def make_data(rng, planted):
    cards = rng.integers(2, 31, size=N_DIMS)
    X = np.stack([rng.integers(0, c, size=N_ROWS) for c in cards], axis=1)
    p = np.full(N_ROWS, BASE_RATE)
    if planted:
        p[X[:, PLANTED_DIM] == PLANTED_VAL] = PLANTED_RATE
    return X, rng.random(N_ROWS) < p


def scan(X, y, idx):
    """Every (dimension, value) slice meeting minimum support -> two-proportion z-test."""
    out = []
    Xs, ys = X[idx], y[idx]
    for d in range(N_DIMS):
        for v in np.unique(Xs[:, d]):
            m = Xs[:, d] == v
            n1, n2 = m.sum(), (~m).sum()
            if n1 < MIN_SUPPORT or n2 < MIN_SUPPORT:
                continue
            p1, p2 = ys[m].mean(), ys[~m].mean()
            pp = (ys[m].sum() + ys[~m].sum()) / (n1 + n2)
            se = np.sqrt(pp * (1 - pp) * (1 / n1 + 1 / n2))
            if se == 0:
                continue
            z = (p1 - p2) / se
            out.append((d, v, p1 / max(p2, 1e-12), 2 * stats.norm.sf(abs(z))))
    return out


def bh(pvals, alpha):
    """Benjamini-Hochberg; returns boolean mask of rejections."""
    p = np.asarray(pvals)
    o = np.argsort(p)
    thresh = alpha * (np.arange(1, len(p) + 1) / len(p))
    passing = np.where(p[o] <= thresh)[0]
    keep = np.zeros(len(p), bool)
    if len(passing):
        keep[o[: passing[-1] + 1]] = True
    return keep


def trial(rng, planted):
    X, y = make_data(rng, planted)
    half = rng.permutation(N_ROWS)
    explore, confirm = half[: N_ROWS // 2], half[N_ROWS // 2:]

    # Naive: scan everything, report the most striking slice at raw p < .05.
    res = scan(X, y, np.arange(N_ROWS))
    ps = [r[3] for r in res]
    lifts = [r[2] for r in res]
    top = int(np.argmax(lifts))
    naive_claim = res[top] if ps[top] < ALPHA else None

    # Disciplined: BH over the explore half, then confirm the survivor out of sample.
    er = scan(X, y, explore)
    if not er:
        return naive_claim, None, len(res)
    keep = bh([r[3] for r in er], ALPHA)
    if not keep.any():
        return naive_claim, None, len(res)
    surv = [er[i] for i in np.where(keep)[0]]
    best = max(surv, key=lambda r: r[2])
    cr = {(r[0], r[1]): r for r in scan(X, y, confirm)}
    hit = cr.get((best[0], best[1]))
    disc_claim = best if (hit and hit[3] < ALPHA and hit[2] > 1) else None
    return naive_claim, disc_claim, len(res)


def run(planted, label, reps):
    rng = np.random.default_rng(20231230 + int(planted))
    naive_fire = disc_fire = disc_right = naive_right = 0
    nslices = 0
    for _ in range(reps):
        nc, dc, ns = trial(rng, planted)
        nslices = ns
        if nc:
            naive_fire += 1
            naive_right += (nc[0], nc[1]) == (PLANTED_DIM, PLANTED_VAL)
        if dc:
            disc_fire += 1
            disc_right += (dc[0], dc[1]) == (PLANTED_DIM, PLANTED_VAL)
    print(f"\n{label}  ({reps} replications, ~{nslices} slices scanned per replication)")
    print(f"  naive  'report the striking slice':  fired {naive_fire/reps:6.1%}"
          + (f"   correct slice {naive_right/reps:6.1%}" if planted else "   <- all false"))
    print(f"  q-values + support + OOS confirm:    fired {disc_fire/reps:6.1%}"
          + (f"   correct slice {disc_right/reps:6.1%}" if planted else "   <- all false"))
    return disc_fire / reps, disc_right / reps


if __name__ == "__main__":
    import argparse

    ap = argparse.ArgumentParser(
        description="Evidence that scanning slices for a correlate invents causes.")
    ap.add_argument("--quick", action="store_true", help="30 replications instead of 300")
    reps = 30 if ap.parse_args().quick else REPS

    print(f"{N_ROWS} rows, {N_DIMS} dimensions, base failure rate {BASE_RATE:.0%}, "
          f"min support {MIN_SUPPORT}, alpha {ALPHA}")
    null_fire, _ = run(False, "NULL: no cause exists", reps)
    _, planted_right = run(True,
                           f"PLANTED: dim {PLANTED_DIM} == {PLANTED_VAL} fails "
                           f"at {PLANTED_RATE:.0%}", reps)

    failures = []
    if null_fire > 0.05:
        failures.append(f"discipline fired on {null_fire:.1%} of null runs (want <=5%)")
    if planted_right < 0.80:
        failures.append(f"discipline recovered the planted cause in {planted_right:.1%} "
                        "of runs (want >=80%)")
    if failures:
        print("\nFAIL: " + "; ".join(failures))
        raise SystemExit(1)
    print("\nPASS: silent under the null, recovers a planted cause.")
