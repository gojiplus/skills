"""audit_provenance.py
Trace every number in a write-up back to the artifact that produces it.

The most productive check in the skill, and entirely mechanical. Prose is not
compiled against its sources, so a regenerated table and a stale sentence
disagree silently and forever. In the case this skill was built from, eight of
nineteen manuscript errors were exactly this -- every one introduced by an
earlier *correct* fix to the table.

Two checks, in descending order of signal:

  SCOPED     For each paragraph, look only at the tables that paragraph
             actually cites. A number that is CLOSE BUT NOT EQUAL to a value in
             its own cited table is what staleness looks like: prose saying 2.28
             beside a table that now says 2.86. Very few false positives,
             because the comparison set is small and genuinely related.

  ORPHAN     A number in prose matching nothing in any artifact. Either typed by
             hand -- so it cannot be regenerated and nothing will catch it
             drifting -- or derived without documentation.

An unscoped "near any value anywhere" search was tried and abandoned: against a
few hundred artifact values almost every number has something within 2%, and the
false-positive rate made it useless. Scope is what makes this work.

Usage:
    python audit_provenance.py ms/paper.tex tables/
    python audit_provenance.py paper.md outputs/ --ext .tex .csv
    python audit_provenance.py ms/paper.tex tables/ --tol 0.05
"""

import argparse
import os
import re
import sys

TOKEN = re.compile(r"-?\d[\d,]*(?:\.\d+)?|-?\.\d+")
# Years and YYYYMMDD crawl stamps are structure, not claims.
STRUCTURAL = re.compile(r"^(19|20)\d{2}$|^(19|20)\d{6}$")

CITE = re.compile(r"\\[cC]?ref\{([^}]*)\}|\\input\{tables/([^}]*)\}")
LABEL = re.compile(r"\\label\{(tab:[^}]*)\}")
INPUT = re.compile(r"\\input\{tables/([^}]*)\}")

STRIP = [
    re.compile(
        r"\\(?:label|ref|cref|Cref|cite[a-z]*|input|include|includegraphics)"
        r"\s*\{[^}]*\}"
    ),
    re.compile(r"%.*$", re.M),
    re.compile(r"\\[a-zA-Z]+\d*"),
    re.compile(r"```.*?```", re.S),
]


def clean(text):
    for pat in STRIP:
        text = pat.sub(" ", text)
    return text


def norm(tok):
    try:
        return float(tok.replace(",", "").replace("{", "").replace("}", ""))
    except ValueError:
        return None


def numbers_in(text, min_abs=2.0, precise_only=False):
    """Numeric tokens in prose.

    `precise_only` keeps just the tokens stated with enough precision for a
    near-miss comparison to mean anything: a decimal point, or three or more
    digits. Comparing a prose "2" against a table's 1.95 is not evidence of
    staleness -- 2 was only ever stated to one significant figure. Dropping
    those took the false-positive rate on a real manuscript from 8 to 0.
    """
    out = set()
    for tok in TOKEN.findall(text):
        v = norm(tok)
        if v is None or STRUCTURAL.match(tok.replace(",", "")):
            continue
        if abs(v) < min_abs and float(v).is_integer():
            continue
        if precise_only and "." not in tok and abs(v) < 100:
            continue
        out.add(v)
    return out


def label_to_file(raw):
    """Map \\label{tab:X} to the \\input{tables/Y} inside the same float."""
    mapping = {}
    for block in re.split(r"\\begin\{table\*?\}", raw):
        labels = LABEL.findall(block)
        inputs = INPUT.findall(block)
        for lab in labels:
            for inp in inputs:
                mapping.setdefault(lab, set()).add(inp)
    return mapping


def artifact_values(dirpath, exts):
    vals = {}
    for root, _, files in os.walk(dirpath):
        for fn in files:
            if not fn.endswith(tuple(exts)):
                continue
            stem = os.path.splitext(fn)[0]
            try:
                body = open(
                    os.path.join(root, fn), encoding="utf-8", errors="replace"
                ).read()
            except OSError:
                continue
            vals[stem] = {
                v for v in (norm(t) for t in TOKEN.findall(body)) if v is not None
            }
    return vals


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("manuscript")
    ap.add_argument("artifacts")
    ap.add_argument("--ext", nargs="*", default=[".tex", ".csv", ".txt"])
    ap.add_argument(
        "--tol",
        type=float,
        default=0.03,
        help="relative distance counting as a near-miss (default 3%%)",
    )
    ap.add_argument("--min", type=float, default=2.0)
    a = ap.parse_args()

    raw = open(a.manuscript, encoding="utf-8", errors="replace").read()
    arts = artifact_values(a.artifacts, a.ext)
    all_vals = set().union(*arts.values()) if arts else set()
    lab2file = label_to_file(raw)

    print("audit_provenance.py")
    print(f"  manuscript : {a.manuscript}")
    print(
        f"  artifacts  : {a.artifacts}  ({len(arts)} files, "
        f"{len(all_vals):,} distinct values)"
    )
    print(f"  labels mapped to files: {len(lab2file)}\n")

    # --- SCOPED: paragraph numbers vs the tables that paragraph cites ---------
    paragraphs = re.split(r"\n\s*\n", raw)
    scoped = []
    checked_paras = 0
    for pi, para in enumerate(paragraphs, 1):
        cited = set()
        for ref, inp in CITE.findall(para):
            for r in ref.split(","):
                r = r.strip()
                cited |= lab2file.get(r, set())
            if inp:
                cited.add(inp)
        cited = {c for c in cited if c in arts}
        if not cited:
            continue
        checked_paras += 1
        target = set().union(*(arts[c] for c in cited))
        for v in numbers_in(clean(para), a.min, precise_only=True):
            if v in target:
                continue
            best, bestd = None, None
            for w in target:
                if w == 0:
                    continue
                d = abs(w - v) / abs(w)
                if bestd is None or d < bestd:
                    best, bestd = w, d
            if best is not None and bestd is not None and 0 < bestd <= a.tol:
                scoped.append((pi, v, best, bestd, sorted(cited)))

    print("=" * 74)
    print(
        f"SCOPED NEAR-MISS  {len(scoped)}   "
        f"({checked_paras} paragraphs cite a resolvable table)"
    )
    print("=" * 74)
    if not scoped:
        print(
            "none -- every prose number in a table-citing paragraph either matches\n"
            "its cited table exactly or is far enough away to be a different quantity."
        )
    else:
        print(
            "Prose close to, but not equal to, a value in the table it cites.\n"
            "This is what a stale sentence looks like. Check each.\n"
        )
        for pi, v, best, d, cited in sorted(scoped, key=lambda r: -r[3]):
            print(
                f"  para {pi:4d}  prose {v:>12,.6g}   cited table has {best:>12,.6g}"
                f"   {100 * d:5.2f}% apart"
            )
            print(f"            tables cited: {', '.join(cited[:3])}")

    # --- ORPHANS -------------------------------------------------------------
    prose_all = numbers_in(clean(raw), a.min)
    orphans = sorted(prose_all - all_vals, key=lambda v: -abs(v))
    print("\n" + "=" * 74)
    print(
        f"ORPHAN  {len(orphans)} of {len(prose_all)} distinct prose numbers "
        f"appear in NO artifact"
    )
    print("=" * 74)
    print(
        "Typed by hand or derived undocumented -- neither can be regenerated,\n"
        "so neither will ever be caught drifting. Triage the ones that look\n"
        "like estimates rather than sample sizes.\n"
    )
    for v in orphans[:50]:
        print(f"  {v:>16,.6g}")
    if len(orphans) > 50:
        print(f"  ... and {len(orphans) - 50} more")

    print("\n" + "=" * 74)
    print(f"MATCHED  {len(prose_all) - len(orphans)} of {len(prose_all)}")
    print("=" * 74)
    print(
        "A match means the value EXISTS somewhere -- not that the prose reads it\n"
        "from the right place. The SCOPED check above is the one with teeth."
    )
    return 1 if scoped else 0


if __name__ == "__main__":
    sys.exit(main())
