#!/usr/bin/env python3
"""Fail-closed release *precondition* checks; not a substitute for independent approval.

This script intentionally cannot confer scientific, licensing, real-cell or legal
acceptance. A tagged release must also execute fresh source-bound artifact
verification, have authorized independent review, and pass protected workflows.
"""
from __future__ import annotations

import hashlib
import json
import os
from pathlib import Path
import re
import sys


REQUIRED_GATES = frozenset((
    "PHY-01", "PHY-02", "PHY-03", "PHY-04", "PHY-05",
    "NUM-01", "NUM-02", "NUM-03", "NUM-04",
    "CTRL-01", "CTRL-02", "CTRL-03", "CTRL-04",
    "FAULT-01", "FAULT-02", "FAULT-03", "FAULT-04",
    "SCN-01", "SCN-02", "SCN-03", "SCN-04",
    "DATA-01", "DATA-02", "DATA-03",
    "TEST-01", "TEST-02", "TEST-03",
    "CI-01", "GOV-01", "DOC-01", "DOC-02"))
REQUIRED_FINDINGS = frozenset((
    "TW-PHY-001", "TW-PHY-002", "TW-CTRL-001", "TW-CTRL-002",
    "TW-CTRL-003", "TW-FAULT-001", "TW-CFG-001", "TW-DATA-001",
    "TW-DATA-002", "TW-DOC-001", "TW-DOC-002", "TW-SIM-001",
    "TW-GOV-001"))
EXPECTED_E10 = {"weak", "nominal", "strong"}


def _read_json(root: Path, relative: str):
    path = root / relative
    if not path.is_file():
        raise AssertionError("Release evidence missing: " + relative)
    def reject_nonfinite(value):
        raise AssertionError("Nonfinite release evidence: " + value)
    return json.loads(path.read_text(encoding="utf-8"),
                      parse_constant=reject_nonfinite)


def _verify_matrix(root: Path):
    path = root / "audit/SCIENTIFIC_VERIFICATION_MATRIX.md"
    if not path.is_file():
        raise AssertionError("Scientific acceptance matrix is missing")
    states = {}
    for line in path.read_text(encoding="utf-8").splitlines():
        columns = [c.strip() for c in line.split("|")[1:-1]]
        if len(columns) < 2 or not re.fullmatch(r"[A-Z]+-[0-9]+", columns[0]):
            continue
        gate, state = columns[:2]
        state = state.replace("*", "").strip().upper()
        if gate in states:
            raise AssertionError("Duplicate scientific acceptance gate: " + gate)
        states[gate] = state
    missing = REQUIRED_GATES - states.keys()
    if missing:
        raise AssertionError("Scientific acceptance gates omitted: " + ", ".join(sorted(missing)))
    incomplete = {gate: state for gate, state in states.items() if state != "PASS"}
    if incomplete:
        raise AssertionError("Mandatory scientific matrix not PASS: " + repr(incomplete))


def _verify_findings(root: Path):
    report = _read_json(root, "audit/findings.json")
    if report.get("schemaVersion") != "thermoweave.audit-findings/v1":
        raise AssertionError("Unknown audit findings schema")
    seen = {}
    for finding in report.get("findings", []):
        identity = finding.get("id")
        if not isinstance(identity, str) or identity in seen:
            raise AssertionError("Missing or duplicate audit finding identity")
        seen[identity] = finding
    missing = REQUIRED_FINDINGS - seen.keys()
    if missing:
        raise AssertionError("Audit findings removed: " + ", ".join(sorted(missing)))
    for identity, finding in seen.items():
        verdict = finding.get("verification", {})
        if verdict.get("status") != "PASS" or not verdict.get("evidence"):
            raise AssertionError("Unverified or unsupported audit finding: " + identity)



def _verify_e10(root: Path, study: dict) -> None:
    """Check published E10 numerical claims AND their independent CSV copy.

    This is a release-time cross-check of checked-in evidence, not a new
    simulator execution or independent numerical/physical validation.
    """
    import csv
    import math

    cases = study.get("cases")
    expected = (("weak", 0.10), ("nominal", 0.25), ("strong", 0.75))
    if not isinstance(cases, list) or len(cases) != len(expected):
        raise AssertionError("E10 case inventory incomplete")

    columns = ("caseId", "gz_W_per_K", "nodeCount", "edgeCount",
               "peakTemperature_K", "peakEdgeGradient_K",
               "finalLayerSpread_K", "energyResidualNormalized", "scenarioHash")
    numeric = [key for key in columns if key not in ("caseId", "scenarioHash")]

    for case, (identity, conductance) in zip(cases, expected):
        if not isinstance(case, dict) or case.get("caseId") != identity:
            raise AssertionError("E10 cases are missing, reordered or duplicated")
        if case.get("nodeCount") != 36 or case.get("edgeCount") != 75:
            raise AssertionError("E10 geometry must be 36 nodes / 75 edges")
        g = case.get("gz_W_per_K")
        if type(g) not in (int, float) or not math.isfinite(g) or not math.isclose(
                g, conductance, rel_tol=0, abs_tol=1e-12):
            raise AssertionError("E10 conductance cases altered")
        scenario_hash = case.get("scenarioHash")
        if not isinstance(scenario_hash, str) or not re.fullmatch(
                r"[0-9a-f]{64}", scenario_hash):
            raise AssertionError("E10 scenario SHA-256 identity missing")
        for key in numeric:
            value = case.get(key)
            if type(value) not in (int, float) or not math.isfinite(value):
                raise AssertionError("Missing/nonfinite E10 numerical measurement: " + key)
        residual = case["energyResidualNormalized"]
        if not 0 <= residual <= 1e-3:
            raise AssertionError("E10 energy residual violates [0, 1e-3] acceptance")
        layers = case.get("finalLayerMeanTemperature_K")
        if not isinstance(layers, list) or len(layers) != 3 or any(
                type(v) not in (int, float) or not math.isfinite(v) for v in layers):
            raise AssertionError("E10 layer temperature inventory incomplete")
        spread = max(layers) - min(layers)
        if not math.isclose(spread, case["finalLayerSpread_K"],
                            rel_tol=1e-7, abs_tol=1e-8):
            raise AssertionError("E10 claimed layer spread disagrees with temperatures")

    csv_rel = "artifacts/data/3d-study-results.csv"
    if study.get("artifacts", {}).get("table") != csv_rel:
        raise AssertionError("E10 report does not identify its canonical CSV")
    csv_path = root / csv_rel
    if not csv_path.is_file():
        raise AssertionError("Published E10 numerical CSV missing")
    try:
        with csv_path.open("r", encoding="utf-8-sig", newline="") as stream:
            reader = csv.DictReader(stream, strict=True)
            if reader.fieldnames != list(columns):
                raise AssertionError("E10 published CSV schema differs from report")
            rows = list(reader)
        if len(rows) != len(cases):
            raise AssertionError("E10 CSV record inventory differs from report")
        for row, case in zip(rows, cases):
            for key in ("caseId", "scenarioHash"):
                if row.get(key) != case.get(key):
                    raise AssertionError("E10 CSV identity differs from report: " + key)
            for key in numeric:
                value = float(row[key])
                if not math.isfinite(value) or not math.isclose(
                        value, float(case[key]), rel_tol=1e-10, abs_tol=1e-10):
                    raise AssertionError("E10 CSV numerical claim differs: " + key)
    except (ValueError, TypeError, KeyError, OverflowError, csv.Error) as exc:
        raise AssertionError("E10 CSV has malformed or nonfinite measurements") from exc


def verify_release_readiness(
    root: Path, expected_sha: str, *, evidence_root: Path | None = None
) -> None:
    """Check mechanical veto conditions before publication.

    Governance records are rooted in the source checkout. The optional
    evidence directory supplies only generated reports and dashboard data.

    Passing this function is NOT proof of authorized licenses or genuine
    independent approval. Scientific gate evidence must also be reviewed.
    """
    root = Path(root)
    if not re.fullmatch(r"[0-9a-f]{40}", expected_sha):
        raise AssertionError("Release requires full exact 40-hex source SHA")
    _verify_matrix(root)
    _verify_findings(root)

    evidence = root if evidence_root is None else Path(evidence_root)
    verification = _read_json(evidence, "artifacts/reports/verification.json")
    manifest = _read_json(evidence, "artifacts/reports/artifact-manifest.json")
    experiments = _read_json(evidence, "artifacts/reports/experiment-summary.json")
    study = _read_json(evidence, "artifacts/reports/3d-study-summary.json")
    if verification.get("gitCommit", "").lower() != expected_sha:
        raise AssertionError("Release verification is not bound to tagged source SHA")
    if any(item.get("matlabRelease") != "2024a" for item in
           (verification, manifest, experiments, study)):
        raise AssertionError("Release evidence is not MATLAB R2024a")
    if manifest.get("verification") != verification:
        raise AssertionError("Manifest and native test evidence disagree")
    counts = [verification.get(k) for k in ("testCount", "passed", "failed", "incomplete")]
    if any(type(n) is not int or n < 0 for n in counts):
        raise AssertionError("Malformed MATLAB test totals")
    total, passed, failed, incomplete = counts
    if total < 63 or passed != total or failed or incomplete:
        raise AssertionError("Release cannot contain failed/incomplete licensed tests")
    if verification.get("codeAnalyzerFindings") != 0:
        raise AssertionError("Release contains Code Analyzer findings")
    if verification.get("simscapeAdapterStatus") != "PASS":
        raise AssertionError("Authorized licensed Simscape parity not demonstrated")
    records = experiments.get("records")
    if not isinstance(records, list) or len(records) != 10:
        raise AssertionError("Experiment inventory incomplete")
    if {x.get("id") for x in records} != {"E" + str(i) for i in range(10)}:
        raise AssertionError("Missing or duplicate experiment identifiers")
    if any(x.get("status") != "PASS" for x in records):
        raise AssertionError("Synthetic E0-E9 experiment incomplete; E9 parity mandatory")
    _verify_e10(evidence, study)

    web_path = evidence / "artifacts/web-data/thermoweave-demo.json"
    docs_path = evidence / "docs/assets/thermoweave-demo.json"
    if not web_path.is_file() or not docs_path.is_file():
        raise AssertionError("Release web-data copies missing")
    web_bytes = web_path.read_bytes()
    if web_bytes != docs_path.read_bytes():
        raise AssertionError("Release website and documentation JSON differ")
    web = _read_json(evidence, "artifacts/web-data/thermoweave-demo.json")
    scenarios = web.get("scenarios")
    if web.get("matlabRelease") != "2024a" or not isinstance(scenarios, list) or len(scenarios) != 5:
        raise AssertionError("Wrong release web JSON or scenario inventory")
    identities = [x.get("id") for x in scenarios]
    if any(not x for x in identities) or len(set(identities)) != len(identities):
        raise AssertionError("Duplicate or empty web scenario identities")
    inventory = manifest.get("webData", {})
    if (inventory.get("sha256") != hashlib.sha256(web_bytes).hexdigest()
            or inventory.get("bytes") != len(web_bytes)
            or inventory.get("scenarioCount") != 5):
        raise AssertionError("Release web SHA-256/size/scenario manifest mismatch")
    print("PASS: deterministic release veto checks passed; independent review still required")


if __name__ == "__main__":
    try:
        evidence_root = os.environ.get("SCIENTIFIC_EVIDENCE_ROOT")
        verify_release_readiness(
            Path("."), os.environ.get("EXPECTED_SOURCE_SHA", "").lower(),
            evidence_root=Path(evidence_root) if evidence_root else None,
        )
    except (AssertionError, ValueError, KeyError, TypeError, OSError) as exc:
        print("RELEASE HOLD: " + str(exc), file=sys.stderr)
        sys.exit(1)
