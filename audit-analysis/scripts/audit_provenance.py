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
    python audit_provenance.py ms/paper.tex tables/ --tol 0.05
"""

import argparse
import os
import re
import sys
from pathlib import Path

TOKEN = re.compile(r"-?\d[\d,]*(?:\.\d+)?|-?\.\d+")
# Years and YYYYMMDD crawl stamps are structure, not claims.
STRUCTURAL = re.compile(r"^(19|20)\d{2}$|^(19|20)\d{6}$")

# The \input path is matched loosely on purpose: repositories put fragments in
# tables/, tabs/, ../tabs/, output/tables/ and so on, and hardcoding one prefix
# meant a citation in any other layout silently failed to resolve.
CITE = re.compile(r"\\[cC]?ref\{([^}]*)\}|\\input\{([^}]*)\}")
LABEL = re.compile(r"\\label\{(tab:[^}]*)\}")
INPUT = re.compile(r"\\input\{([^}]*)\}")


def normalized_path(path):
    """Return a slash-normalized relative path without leading ``./``."""
    value = os.path.normpath(path.strip().replace("\\", "/")).replace("\\", "/")
    while value.startswith("./"):
        value = value[2:]
    return value


def resolve_artifact(path, artifacts):
    """Resolve an input path to one artifact without collapsing directories.

    A manuscript may write ``tables/main/results`` while the artifact root is
    already ``tables/``. Suffix matching supports that layout. A bare
    ``results`` is deliberately unresolved when both ``main/results.tex`` and
    ``appendix/results.tex`` exist.
    """
    requested = normalized_path(path)
    requested_stem = os.path.splitext(requested)[0]

    exact = [
        key
        for key in artifacts
        if key == requested or os.path.splitext(key)[0] == requested_stem
    ]
    if len(exact) == 1:
        return exact[0], exact
    if len(exact) > 1:
        return None, exact

    suffix = []
    for key in artifacts:
        key_stem = os.path.splitext(key)[0]
        if (
            requested.endswith("/" + key)
            or requested_stem.endswith("/" + key_stem)
            or key.endswith("/" + requested)
            or key_stem.endswith("/" + requested_stem)
        ):
            suffix.append(key)
    return (suffix[0], suffix) if len(suffix) == 1 else (None, suffix)

STRIP = [
    re.compile(
        r"\\(?:label|ref|cref|Cref|cite[a-z]*|input|include|includegraphics)"
        r"\s*\{[^}]*\}"
    ),
    # A percent sign in LaTeX prose is written `\%`. Without this lookbehind the
    # pattern deleted everything after it on the line, so "rose 12.4\% from a base
    # of 2.28 million in 2015" lost both 2.28 and 2015 from every check below --
    # silently, and disproportionately on the percentage sentences an empirical
    # paper is largely made of.
    re.compile(r"(?<!\\)%.*$", re.M),
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
                mapping.setdefault(lab, set()).add(inp.strip())
    return mapping


def artifact_values(dirpath, exts):
    vals = {}
    for root, _, files in os.walk(dirpath):
        for fn in files:
            if not fn.endswith(tuple(exts)):
                continue
            key = os.path.relpath(os.path.join(root, fn), dirpath).replace(os.sep, "/")
            try:
                body = Path(os.path.join(root, fn)).read_text(
                    encoding="utf-8", errors="replace"
                )
            except OSError:
                continue
            vals[key] = {
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

    if not a.manuscript.lower().endswith(".tex"):
        print(
            "audit_provenance.py: scoped provenance currently supports LaTeX "
            "manuscripts only; pass a .tex file.",
            file=sys.stderr,
        )
        return 2

    raw = Path(a.manuscript).read_text(encoding="utf-8", errors="replace")
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
    ambiguous = set()
    unresolved = set()
    for pi, para in enumerate(paragraphs, 1):
        para_numbers = numbers_in(clean(para), a.min, precise_only=True)
        raw_citations = set()
        for ref, inp in CITE.findall(para):
            for r in ref.split(","):
                r = r.strip()
                mapped = lab2file.get(r)
                if mapped:
                    raw_citations |= mapped
                elif para_numbers and r.startswith("tab:"):
                    unresolved.add(r)
            if inp:
                raw_citations.add(inp.strip())
        cited = set()
        for raw_path in raw_citations:
            resolved, matches = resolve_artifact(raw_path, arts)
            if resolved is not None:
                cited.add(resolved)
            elif len(matches) > 1:
                ambiguous.add((raw_path, tuple(sorted(matches))))
            elif para_numbers:
                unresolved.add(raw_path)
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
    if ambiguous:
        print("AMBIGUOUS TABLE PATHS (not compared):")
        for raw_path, matches in sorted(ambiguous):
            print(f"  {raw_path}: {', '.join(matches)}")
        print()
    if unresolved:
        print("UNRESOLVED TABLE PATHS OR LABELS (not compared):")
        for raw_path in sorted(unresolved):
            print(f"  {raw_path}")
        print()
    if not scoped and checked_paras == 0:
        # "none" here used to assert that everything matched, when in fact the
        # check never ran. This can happen when no paragraph cites a resolvable
        # artifact, or when the artifacts path is wrong or empty. Both used to
        # exit 0.
        print(
            "THE SCOPED CHECK DID NOT RUN. No paragraph cites a table that could be\n"
            "resolved to a file, so nothing was compared. This is not a pass.\n"
            "  - do paragraphs use \\ref/\\input citations?\n"
            "  - does the artifacts directory exist and contain the .tex fragments?\n"
            f"  - artifacts loaded: {len(arts)} file(s)"
        )
    elif not scoped:
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
    # A check that could not run has not passed. Exiting 0 there made a mistyped
    # artifacts path look like a clean result.
    if ambiguous or unresolved or checked_paras == 0:
        return 2
    return 1 if scoped else 0


if __name__ == "__main__":
    sys.exit(main())
