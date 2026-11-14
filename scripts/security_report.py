"""Gate SARIF findings without printing source snippets or infrastructure values."""

import argparse
import json
import os
from pathlib import Path


def findings(path, minimum_cvss=None):
    """Compare rule, path and message so newly affected packages cannot hide in debt."""
    document = json.loads(Path(path).read_text())
    if document.get("version") != "2.1.0" or not document.get("runs"):
        raise ValueError("A non-empty SARIF 2.1.0 report is required")
    identities = set()
    for run in document["runs"]:
        if any(invocation.get("executionSuccessful") is False for invocation in run.get("invocations", [])):
            raise ValueError("Scanner execution was unsuccessful")
        if not isinstance(run.get("results"), list):
            raise ValueError("SARIF results are missing")
        rules = {rule["id"]: rule for rule in run.get("tool", {}).get("driver", {}).get("rules", [])}
        for result in run["results"]:
            # A failed scanner must never be interpreted as a clean report.
            if result.get("kind") in {"pass", "notApplicable"}:
                continue
            rule = result["ruleId"]
            if minimum_cvss is not None:
                score = rules.get(rule, {}).get("properties", {}).get("security-severity")
                if score is None or float(score) < minimum_cvss:
                    continue
            locations = result.get("locations") or []
            if not locations:
                raise ValueError("Finding location is missing")
            for location in locations:
                uri = location["physicalLocation"]["artifactLocation"]["uri"]
                # Trivy may emit absolute paths for the extracted baseline snapshot.
                base = os.environ.get("RUNNER_TEMP", "") + "/security-base/"
                uri = uri.removeprefix("file://").removeprefix(base).removeprefix("./")
                identities.add((rule, uri, result["message"]["text"]))
    return identities


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("report")
    parser.add_argument("--baseline")
    parser.add_argument("--minimum-cvss", type=float)
    args = parser.parse_args()
    current = findings(args.report, args.minimum_cvss)
    baseline = findings(args.baseline, args.minimum_cvss) if args.baseline else set()
    new = current - baseline
    summary = (
        f"High/critical findings: {len(current)}. "
        f"{'New findings' if args.baseline else 'Blocking findings'}: {len(new)}.\n\n"
        "Review detailed findings in the repository Security tab and PR annotations. "
        "Changes must be proposed and reviewed through pull requests.\n"
    )
    print(summary)
    if os.environ.get("GITHUB_STEP_SUMMARY"):
        with Path(os.environ["GITHUB_STEP_SUMMARY"]).open("a") as stream:
            stream.write(summary)
    return bool(new)


if __name__ == "__main__":
    raise SystemExit(main())
