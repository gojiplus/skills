#!/usr/bin/env python3
"""Negative tests for the validator.

A validator with no failing case is not a validator — it is a function that
returns an empty list. Every rule in check_skill gets a fixture that trips it.
"""

from __future__ import annotations

import tempfile
import unittest
from pathlib import Path

from validate import DESCRIPTION_MAX, NAME_MAX, check_skill, parse_frontmatter

GOOD = """---
name: {name}
description: {description}
---

# Body
"""


def write_skill(root: Path, directory: str, body: str) -> Path:
    path = root / directory
    path.mkdir()
    (path / "SKILL.md").write_text(body, encoding="utf-8")
    return path


class CheckSkillTest(unittest.TestCase):
    def setUp(self) -> None:
        self._tmp = tempfile.TemporaryDirectory()
        self.root = Path(self._tmp.name)
        self.addCleanup(self._tmp.cleanup)

    def skill(self, directory: str, **fields: str) -> Path:
        fields.setdefault("name", directory)
        fields.setdefault("description", "Does a thing. Use when a thing is needed.")
        return write_skill(self.root, directory, GOOD.format(**fields))

    def test_valid_skill_passes(self) -> None:
        self.assertEqual(check_skill(self.skill("good-skill")), [])

    def test_missing_skill_md(self) -> None:
        path = self.root / "empty-skill"
        path.mkdir()
        self.assertEqual(check_skill(path), ["no SKILL.md"])

    def test_no_frontmatter(self) -> None:
        path = write_skill(self.root, "bare", "# Just a heading\n")
        self.assertIn("no YAML frontmatter", check_skill(path)[0])

    def test_unterminated_frontmatter(self) -> None:
        path = write_skill(self.root, "unterminated", "---\nname: unterminated\n")
        self.assertIn("no YAML frontmatter", check_skill(path)[0])

    def test_name_too_long(self) -> None:
        long_name = "a" * (NAME_MAX + 1)
        path = self.skill(long_name, name=long_name)
        self.assertTrue(any("max 64" in e for e in check_skill(path)))

    def test_name_with_uppercase_or_underscore(self) -> None:
        # Distinct directories per case: macOS is case-insensitive, so
        # "Bad_Name" and "bad_name" would collide in one temp dir.
        for index, bad in enumerate(("Bad-Name", "bad_name", "badName")):
            with self.subTest(bad=bad):
                path = self.skill(f"case{index}", name=bad)
                self.assertTrue(any("lowercase" in e for e in check_skill(path)))

    def test_reserved_words_in_name(self) -> None:
        for bad in ("claude-helper", "anthropic-tools"):
            with self.subTest(bad=bad):
                path = self.skill(bad, name=bad)
                self.assertTrue(any("reserved word" in e for e in check_skill(path)))

    def test_name_directory_mismatch(self) -> None:
        path = self.skill("on-disk", name="in-frontmatter")
        self.assertTrue(any("does not match directory" in e for e in check_skill(path)))

    def test_description_too_long(self) -> None:
        path = self.skill("wordy", description="x" * (DESCRIPTION_MAX + 1))
        self.assertTrue(any(f"max {DESCRIPTION_MAX}" in e for e in check_skill(path)))

    def test_description_empty(self) -> None:
        path = self.skill("silent", description="")
        self.assertTrue(any("description is missing" in e for e in check_skill(path)))

    def test_xml_tag_rejected(self) -> None:
        path = self.skill("taggy", description="Use when <important>this</important>.")
        self.assertTrue(any("XML tag" in e for e in check_skill(path)))


class ParseFrontmatterTest(unittest.TestCase):
    def test_unknown_and_nested_keys_are_kept_not_rejected(self) -> None:
        # on-writing carries license, compatibility, metadata and allowed-tools.
        # The spec permits extra keys; the validator must not choke on them.
        fields = parse_frontmatter(
            "---\n"
            "name: on-writing\n"
            "description: Edits prose.\n"
            "license: MIT\n"
            "compatibility: any-agent\n"
            "metadata:\n"
            "  version: 1.0.0\n"
            "allowed-tools:\n"
            "  - Read\n"
            "---\n"
        )
        assert fields is not None
        self.assertEqual(fields["name"], "on-writing")
        self.assertEqual(fields["description"], "Edits prose.")
        self.assertIn("license", fields)
        self.assertIn("allowed-tools", fields)

    def test_folded_description_is_joined(self) -> None:
        fields = parse_frontmatter(
            "---\nname: folded\ndescription: >\n  First line\n  second line\n---\n"
        )
        assert fields is not None
        self.assertEqual(fields["description"], "> First line second line")

    def test_quoted_description_is_decoded(self) -> None:
        fields = parse_frontmatter(
            '---\nname: quoted\ndescription: "Use when a label contains: punctuation."\n---\n'
        )
        assert fields is not None
        self.assertEqual(fields["description"], "Use when a label contains: punctuation.")


if __name__ == "__main__":
    unittest.main()
