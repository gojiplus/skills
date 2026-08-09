#!/usr/bin/env python3
"""Validate every skill against the strictest surface's rules.

Claude Code loads a skill that claude.ai would reject on upload, so a skill can
work locally for months and then fail the moment it is packaged. This checks the
constraints claude.ai documents, plus the one the spec leaves implicit: a skill's
`name` must match its directory, or clients that key on the directory and clients
that key on the frontmatter disagree about what is installed.

Stdlib only, and it parses the frontmatter itself rather than importing PyYAML —
this runs in CI and on a bare interpreter with nothing installed.
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

NAME_MAX = 64
DESCRIPTION_MAX = 1024
NAME_PATTERN = re.compile(r"^[a-z0-9-]+$")
RESERVED_WORDS = ("anthropic", "claude")
XML_TAG = re.compile(r"<[^>]+>")

# Directories that sit alongside the skills and are not skills themselves.
NOT_SKILLS = {".git", ".github", "scripts", "dist", "server"}


def parse_frontmatter(text: str) -> dict[str, str] | None:
    """Return top-level scalar keys of the YAML frontmatter, or None if absent.

    Nested and list values are collected as raw text: nothing here validates them,
    and unknown keys are deliberately kept rather than rejected — `license`,
    `compatibility` and the Claude Code-specific `allowed-tools` are all legal.
    """
    if not text.startswith("---"):
        return None
    end = text.find("\n---", 3)
    if end == -1:
        return None

    fields: dict[str, str] = {}
    key = None
    for line in text[3:end].splitlines():
        match = re.match(r"^([A-Za-z0-9_-]+):\s*(.*)$", line)
        if match:
            key, value = match.group(1), match.group(2).strip()
            fields[key] = value
        elif key is not None and line.strip():
            # Continuation of the previous key (folded scalar or nested block).
            fields[key] = (fields[key] + " " + line.strip()).strip()
    return fields


def check_skill(directory: Path) -> list[str]:
    """Return the failures for one skill directory; empty means it passes."""
    errors = []
    skill_md = directory / "SKILL.md"
    if not skill_md.is_file():
        return ["no SKILL.md"]

    fields = parse_frontmatter(skill_md.read_text(encoding="utf-8"))
    if fields is None:
        return ["no YAML frontmatter delimited by ---"]

    name = fields.get("name", "")
    if not name:
        errors.append("name is missing or empty")
    else:
        if len(name) > NAME_MAX:
            errors.append(f"name is {len(name)} chars, max {NAME_MAX}")
        if not NAME_PATTERN.match(name):
            errors.append(f"name {name!r} must be lowercase letters, numbers, hyphens")
        for word in RESERVED_WORDS:
            if word in name.lower():
                errors.append(f"name contains the reserved word {word!r}")
        if name != directory.name:
            errors.append(f"name {name!r} does not match directory {directory.name!r}")

    description = fields.get("description", "")
    if not description:
        errors.append("description is missing or empty")
    elif len(description) > DESCRIPTION_MAX:
        errors.append(f"description is {len(description)} chars, max {DESCRIPTION_MAX}")

    for field, value in (("name", name), ("description", description)):
        if value and XML_TAG.search(value):
            errors.append(f"{field} contains an XML tag")

    return errors


def main() -> int:
    root = Path(__file__).resolve().parent.parent
    directories = sorted(
        path
        for path in root.iterdir()
        if path.is_dir() and path.name not in NOT_SKILLS and not path.name.startswith(".")
    )
    if not directories:
        print(f"no skill directories found in {root}", file=sys.stderr)
        return 1

    failed = 0
    for directory in directories:
        errors = check_skill(directory)
        if errors:
            failed += 1
            print(f"FAIL {directory.name}")
            for error in errors:
                print(f"       {error}")
        else:
            print(f"ok   {directory.name}")

    print(f"\n{len(directories) - failed}/{len(directories)} skills valid")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
