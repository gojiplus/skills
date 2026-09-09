"""Check catalog generation and nested-resource integrity."""

from __future__ import annotations

import hashlib
import tempfile
import unittest
from pathlib import Path

from build_index import CATALOG_END, CATALOG_START, build, update_readme


class CatalogTest(unittest.TestCase):
    def test_nested_resources_are_hashed_and_noise_is_excluded(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            skill = root / "example"
            nested = skill / "references" / "service" / "scripts"
            nested.mkdir(parents=True)
            (skill / "SKILL.md").write_text(
                "---\nname: example\ndescription: Handle a specific task.\n---\n"
            )
            helper = nested / "check.sh"
            helper.write_text("#!/bin/sh\nexit 0\n")
            (nested / "__pycache__").mkdir()
            (nested / "__pycache__" / "ignored.pyc").write_bytes(b"ignored")
            (skill / ".DS_Store").write_bytes(b"ignored")

            index = build(root)
            files = index["skills"][0]["files"]
            self.assertEqual(
                [file["path"] for file in files],
                ["SKILL.md", "references/service/scripts/check.sh"],
            )
            self.assertEqual(
                files[1]["digest"],
                "sha256:" + hashlib.sha256(helper.read_bytes()).hexdigest(),
            )
            helper.write_text("#!/bin/sh\nexit 1\n")
            self.assertNotEqual(build(root)["skills"][0]["files"][1], files[1])

    def test_readme_sync_preserves_prose_and_is_idempotent(self) -> None:
        source = f"Opening\n{CATALOG_START}\nOld table\n{CATALOG_END}\nClosing\n"
        index = {
            "skills": [{"name": "example", "frontmatter": {"description": "A | B"}}]
        }
        rendered = update_readme(source, index)
        self.assertTrue(rendered.startswith("Opening\n"))
        self.assertTrue(rendered.endswith("\nClosing\n"))
        self.assertIn("[example](example/)", rendered)
        self.assertIn("A &#124; B", rendered)
        self.assertNotIn("Old table", rendered)
        self.assertEqual(update_readme(rendered, index), rendered)
        self.assertNotIn("[example]", update_readme(rendered, {"skills": []}))

    def test_missing_or_duplicate_markers_fail_without_overwriting(self) -> None:
        for source in ("No markers", CATALOG_START * 2 + CATALOG_END):
            with self.subTest(source=source), self.assertRaises(ValueError):
                update_readme(source, {"skills": []})


if __name__ == "__main__":
    unittest.main()
