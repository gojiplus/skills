#!/usr/bin/env python3
"""Regression tests for the provenance resolver's failure boundaries."""

from __future__ import annotations

import importlib.util
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
MODULE_PATH = ROOT / "audit-analysis" / "scripts" / "audit_provenance.py"
SPEC = importlib.util.spec_from_file_location("audit_provenance", MODULE_PATH)
assert SPEC is not None and SPEC.loader is not None
PROVENANCE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(PROVENANCE)


class ArtifactResolutionTest(unittest.TestCase):
    def setUp(self) -> None:
        self._tmp = tempfile.TemporaryDirectory()
        self.root = Path(self._tmp.name)
        self.addCleanup(self._tmp.cleanup)
        for directory, value in (("main", "2.86"), ("appendix", "7.14")):
            path = self.root / directory / "results.tex"
            path.parent.mkdir()
            path.write_text(value, encoding="utf-8")
        self.artifacts = PROVENANCE.artifact_values(self.root, [".tex"])

    def test_relative_paths_keep_duplicate_basenames_distinct(self) -> None:
        resolved, matches = PROVENANCE.resolve_artifact(
            "tables/main/results", self.artifacts
        )
        self.assertEqual(resolved, "main/results.tex")
        self.assertEqual(matches, ["main/results.tex"])

    def test_bare_duplicate_basename_is_ambiguous(self) -> None:
        resolved, matches = PROVENANCE.resolve_artifact("results", self.artifacts)
        self.assertIsNone(resolved)
        self.assertEqual(
            sorted(matches), ["appendix/results.tex", "main/results.tex"]
        )

    def test_markdown_input_is_rejected_explicitly(self) -> None:
        manuscript = self.root / "paper.md"
        manuscript.write_text("The estimate is 2.86.", encoding="utf-8")
        result = subprocess.run(
            [sys.executable, str(MODULE_PATH), str(manuscript), str(self.root)],
            check=False,
            capture_output=True,
            text=True,
        )
        self.assertEqual(result.returncode, 2)
        self.assertIn("supports LaTeX manuscripts only", result.stderr)

    def test_ambiguous_citation_fails_closed(self) -> None:
        manuscript = self.root / "paper.tex"
        manuscript.write_text(
            "The estimate is 2.86.\\input{results}\n", encoding="utf-8"
        )
        result = subprocess.run(
            [sys.executable, str(MODULE_PATH), str(manuscript), str(self.root)],
            check=False,
            capture_output=True,
            text=True,
        )
        self.assertEqual(result.returncode, 2)
        self.assertIn("AMBIGUOUS TABLE PATHS", result.stdout)

    def test_unresolved_citation_fails_even_when_another_resolves(self) -> None:
        manuscript = self.root / "paper.tex"
        manuscript.write_text(
            "The estimate is 2.86.\\input{main/results}\n\n"
            "The second estimate is 7.14.\\input{typo}\n",
            encoding="utf-8",
        )
        result = subprocess.run(
            [sys.executable, str(MODULE_PATH), str(manuscript), str(self.root)],
            check=False,
            capture_output=True,
            text=True,
        )
        self.assertEqual(result.returncode, 2)
        self.assertIn("UNRESOLVED TABLE PATHS OR LABELS", result.stdout)
        self.assertIn("  typo", result.stdout)


if __name__ == "__main__":
    unittest.main()
