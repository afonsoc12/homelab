"""Regression tests for the security gate's trust and baseline boundaries."""

import importlib.util
import json
import os
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

spec = importlib.util.spec_from_file_location("security_report", Path(__file__).parents[1] / "security_report.py")
security_report = importlib.util.module_from_spec(spec)
spec.loader.exec_module(security_report)


def finding(rule="CVE-example", uri="uv.lock", message="package-a is vulnerable"):
    return {
        "ruleId": rule,
        "message": {"text": message},
        "locations": [{"physicalLocation": {"artifactLocation": {"uri": uri}}}],
    }


class SecurityReportTests(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.directory.cleanup)
        self.root = Path(self.directory.name)

    def report(self, name, results):
        path = self.root / name
        path.write_text(json.dumps({"version": "2.1.0", "runs": [{"results": results}]}))
        return path

    def test_clean_report(self):
        self.assertEqual(security_report.findings(self.report("clean.json", [])), set())

    def test_existing_debt_does_not_hide_a_new_package_with_the_same_cve(self):
        baseline = security_report.findings(self.report("base.json", [finding()]))
        current = security_report.findings(self.report("new.json", [finding(), finding(message="package-b is vulnerable")]))
        self.assertEqual(len(current - baseline), 1)

    def test_baseline_absolute_paths_match_current_relative_paths(self):
        with patch.dict(os.environ, {"RUNNER_TEMP": str(self.root)}):
            base = self.report("base.json", [finding(uri=f"file://{self.root}/security-base/uv.lock")])
            current = self.report("new.json", [finding(uri="./uv.lock")])
            self.assertEqual(security_report.findings(base), security_report.findings(current))

    def test_missing_report_fails_closed(self):
        with self.assertRaises(FileNotFoundError):
            security_report.findings(self.root / "missing.json")

    def test_empty_runs_fail_closed(self):
        path = self.root / "empty.json"
        path.write_text(json.dumps({"version": "2.1.0", "runs": []}))
        with self.assertRaises(ValueError):
            security_report.findings(path)

    def test_missing_results_fail_closed(self):
        path = self.root / "invalid.json"
        path.write_text(json.dumps({"version": "2.1.0", "runs": [{}]}))
        with self.assertRaises(ValueError):
            security_report.findings(path)

    def test_failed_scanner_cannot_report_clean(self):
        path = self.report("failed.json", [])
        document = json.loads(path.read_text())
        document["runs"][0]["invocations"] = [{"executionSuccessful": False}]
        path.write_text(json.dumps(document))
        with self.assertRaises(ValueError):
            security_report.findings(path)

    def test_codeql_gate_selects_only_high_or_critical_security_rules(self):
        path = self.report("codeql.json", [finding("high"), finding("medium"), finding("quality")])
        document = json.loads(path.read_text())
        document["runs"][0]["tool"] = {"driver": {"rules": [
            {"id": "high", "properties": {"security-severity": "7.5"}},
            {"id": "medium", "properties": {"security-severity": "6.0"}},
            {"id": "quality", "properties": {}},
        ]}}
        path.write_text(json.dumps(document))
        self.assertEqual(len(security_report.findings(path, minimum_cvss=7)), 1)

    def test_missing_finding_location_fails_closed(self):
        result = finding()
        del result["locations"]
        with self.assertRaises(ValueError):
            security_report.findings(self.report("invalid.json", [result]))

    def test_gate_blocks_new_findings_and_summarizes_without_snippets(self):
        path = self.report("new.json", [finding(message="sensitive source snippet")])
        summary = self.root / "summary.md"
        with patch("sys.argv", ["security_report.py", str(path)]), patch.dict(os.environ, {"GITHUB_STEP_SUMMARY": str(summary)}):
            self.assertTrue(security_report.main())
        self.assertNotIn("sensitive source snippet", summary.read_text())


if __name__ == "__main__":
    unittest.main()
