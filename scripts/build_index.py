#!/usr/bin/env python3
"""Generate the MCP index and README catalog from skill metadata.

SEP-2640 requires each skill entry to carry a SHA-256 digest of every file, so a
host can verify that what it reads is what the listing promised. Computing those
per request would mean hashing the whole repo on every skills/list, so the index
is built here and committed, and CI fails if it drifts from the tree. Same
bargain as any generated artifact: cheap to serve, and it cannot go stale
silently.

Stdlib only — this runs in CI and in a pre-commit path with nothing installed.
"""

from __future__ import annotations

import hashlib
import json
import sys
from pathlib import Path

from validate import NOT_SKILLS, parse_frontmatter

INDEX = "index.json"
CATALOG_START = "<!-- skills:start -->"
CATALOG_END = "<!-- skills:end -->"
# Never served: build output, VCS internals, and macOS noise.
SKIP_FILES = {".DS_Store"}
SKIP_DIRS = {"__pycache__"}


def digest(path: Path) -> str:
    return "sha256:" + hashlib.sha256(path.read_bytes()).hexdigest()


def skill_files(directory: Path) -> list[Path]:
    return sorted(
        path
        for path in directory.rglob("*")
        if path.is_file()
        and path.name not in SKIP_FILES
        and not any(part in SKIP_DIRS for part in path.parts)
    )


def build(root: Path) -> dict:
    skills = []
    directories = sorted(
        path
        for path in root.iterdir()
        if path.is_dir()
        and path.name not in NOT_SKILLS
        and not path.name.startswith(".")
    )

    for directory in directories:
        skill_md = directory / "SKILL.md"
        frontmatter = parse_frontmatter(skill_md.read_text(encoding="utf-8"))
        if frontmatter is None:
            raise SystemExit(
                f"{directory.name}: no frontmatter — run validate.py first"
            )

        files = skill_files(directory)
        skills.append(
            {
                "name": directory.name,
                # SKILL.md first: it is the entry point, and hosts that read the
                # list in order should see it before the supporting files.
                "files": [
                    {
                        "path": str(path.relative_to(directory)),
                        "digest": digest(path),
                        "size": path.stat().st_size,
                    }
                    for path in sorted(files, key=lambda p: (p.name != "SKILL.md", p))
                ],
                "frontmatter": frontmatter,
            }
        )

    return {"skills": skills}


def update_readme(text: str, index: dict) -> str:
    """Replace only the generated catalog, preserving surrounding prose."""
    if text.count(CATALOG_START) != 1 or text.count(CATALOG_END) != 1:
        raise ValueError("README.md needs exactly one pair of skills catalog markers")
    before, rest = text.split(CATALOG_START)
    _, after = rest.split(CATALOG_END)
    rows = ["| Skill | When to use it |", "|---|---|"]
    for skill in index["skills"]:
        name = skill["name"]
        description = skill["frontmatter"]["description"].replace("|", "&#124;")
        rows.append(f"| [{name}]({name}/) | {description} |")
    catalog = "\n".join(rows)
    return f"{before}{CATALOG_START}\n\n{catalog}\n\n{CATALOG_END}{after}"


def main() -> int:
    root = Path(__file__).resolve().parent.parent
    index = build(root)
    rendered = json.dumps(index, indent=2, ensure_ascii=False) + "\n"
    target = root / INDEX
    readme = root / "README.md"
    current_readme = readme.read_text(encoding="utf-8")
    rendered_readme = update_readme(current_readme, index)

    if "--check" in sys.argv:
        current = target.read_text(encoding="utf-8") if target.exists() else ""
        stale = []
        if current != rendered:
            stale.append(INDEX)
        if current_readme != rendered_readme:
            stale.append("README.md catalog")
        if stale:
            print(f"{', '.join(stale)} stale — run `make index`", file=sys.stderr)
            return 1
        print(f"Catalogs are current ({len(index['skills'])} skills)")
        return 0

    target.write_text(rendered, encoding="utf-8")
    readme.write_text(rendered_readme, encoding="utf-8")
    total = sum(len(skill["files"]) for skill in index["skills"])
    print(
        f"wrote {INDEX} and README catalog: "
        f"{len(index['skills'])} skills, {total} files"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
