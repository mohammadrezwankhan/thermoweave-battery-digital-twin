"""Validate fresh R2024a ThermoWeave artifacts without masking scientific failures."""
import hashlib
import json
import math
import os
from pathlib import Path
import sys


def _reject_nonfinite(value):
    raise ValueError("Non-finite JSON number: " + value)


def _finite_number(value):
    return type(value) in (int, float) and math.isfinite(value)


def verify():
    root = Path(__file__).resolve().parents[1]
    expected_release = os.environ.get("EXPECTED_MATLAB_RELEASE", "2024a")
    marker = root / "results/artifact-regeneration-start.flag"
    if not marker.is_file():
        raise AssertionError("Missing fresh-generation start marker")
    required = {
        "manifest": "artifacts/reports/artifact-manifest.json",
        "verification": "artifacts/reports/verification.json",
        "experiments": "artifacts/reports/experiment-summary.json",
        "study": "artifacts/reports/3d-study-summary.json",
        "web": "artifacts/web-data/thermoweave-demo.json",
        "web-copy": "docs/assets/thermoweave-demo.json",
    }
    data = {}
    for key, name in required.items():
        file = root / name
        if not file.is_file():
            raise AssertionError("Missing artifact: " + name)
        if file.stat().st_mtime + 0.001 < marker.stat().st_mtime:
            raise AssertionError("Stale artifact from checkout, not this run: " + name)
        data[key] = json.loads(file.read_text(encoding="utf-8"), parse_constant=_reject_nonfinite)
        actual_release = str(data[key].get("matlabRelease", ""))
        if actual_release != expected_release:
            raise AssertionError(
                f"Wrong MATLAB release for {name}: {actual_release!r} vs {expected_release}")
        print("Verified regenerated artifact", name, actual_release)
    manifest = data["manifest"]
    if manifest.get("schemaVersion") != "thermoweave.artifacts/v1":
        raise AssertionError("Unexpected artifact-manifest schema")
    web_bytes = (root / required["web"]).read_bytes()
    if (root / required["web-copy"]).read_bytes() != web_bytes:
        raise AssertionError("Website and documentation exports differ")
    web_record = manifest.get("webData", {})
    if web_record.get("path") != required["web"]:
        raise AssertionError("Web artifact path mismatch")
    if web_record.get("sha256") != hashlib.sha256(web_bytes).hexdigest():
        raise AssertionError("Web SHA256 does not match manifest")
    if web_record.get("bytes") != len(web_bytes):
        raise AssertionError("Web byte length mismatch")
    website = data["web"]
    if website.get("schemaVersion") != "thermoweave.web/v1":
        raise AssertionError("Unexpected website schema")
    if website.get("syntheticData") is not True:
        raise AssertionError("Synthetic model disclaimer missing")
    scenarios = website.get("scenarios", [])
    if len(scenarios) != 5 or web_record.get("scenarioCount") != 5:
        raise AssertionError("Expected five declared website scenarios")
    if any(s.get("sourceSchema") != "thermoweave.result/v1"
           or not s.get("scenarioHash") for s in scenarios):
        raise AssertionError("Website scenario schema/hash invalid")
    for scenario in scenarios:
        times = scenario.get("time_s")
        if (not isinstance(times, list) or len(times) < 2
                or not all(_finite_number(t) for t in times)
                or any(right <= left for left, right in zip(times, times[1:]))):
            raise AssertionError("Invalid website time grid for " + str(scenario.get("id")))
        for field in ("temperature_C", "boundaryTemperature_C", "zoneCommand"):
            series = scenario.get(field)
            if (not isinstance(series, list) or len(series) != len(times)
                    or any(not isinstance(row, list) or len(row) == 0
                           or not all(_finite_number(value) for value in row)
                           for row in series)):
                raise AssertionError("Unaligned/nonfinite website field " + field)
    experiments = data["experiments"]
    if experiments.get("schemaVersion") != "thermoweave.experiments/v1":
        raise AssertionError("Experiment schema mismatch")
    rows = experiments.get("records", [])
    experiments_record = manifest.get("experiments", {})
    if (not isinstance(experiments_record, dict)
            or experiments_record.get("path") != required["experiments"]):
        raise AssertionError("Experiment manifest path mismatch")
    experiments_sha = hashlib.sha256(
        (root / required["experiments"]).read_bytes()).hexdigest()
    if experiments_record.get("sha256") != experiments_sha:
        raise AssertionError("Experiment SHA256 mismatch with regenerated report")
    if experiments_record.get("scenarioCount") != len(rows):
        raise AssertionError("Experiment manifest count mismatch")
    if [r.get("id") for r in rows] != [f"E{i}" for i in range(10)]:
        raise AssertionError("E0-E9 incomplete or reordered")
    failed = [r.get("id") for r in rows[:9] if r.get("status") != "PASS"]
    if failed:
        raise AssertionError("E0-E8 must PASS: " + ", ".join(failed))
    e9 = rows[9].get("status", "")
    if not (e9 == "PASS" or e9.startswith("SKIPPED_")):
        raise AssertionError("Untruthful optional Simscape status")
    print("E0-E8 PASS; E9 status", e9, "(not accepted as numerical parity if skipped)")
    study = data["study"]
    if study.get("schemaVersion") != "thermoweave.study3d/v1":
        raise AssertionError("E10 study schema mismatch")
    embedded_study = manifest.get("study3d")
    if (not isinstance(embedded_study, dict)
            or any(embedded_study.get(key) != value
                   for key, value in study.items())):
        raise AssertionError("Embedded study mismatch with regenerated E10 report")
    cases = study.get("cases", [])
    if len(cases) != 3 or any(
        c.get("nodeCount") != 36 or c.get("edgeCount") != 75 or
        not c.get("scenarioHash") for c in cases
    ):
        raise AssertionError("E10 geometry or scenario hashes invalid")
    expected_cases = (("weak", 0.10), ("nominal", 0.25), ("strong", 0.75))
    for case, (expected_id, expected_gz) in zip(cases, expected_cases):
        if (case.get("caseId") != expected_id
                or not _finite_number(case.get("gz_W_per_K"))
                or not math.isclose(case["gz_W_per_K"], expected_gz, abs_tol=1e-12)):
            raise AssertionError("E10 conductance cases missing, reordered or duplicated")
        layers = case.get("finalLayerMeanTemperature_K")
        if (not isinstance(layers, list) or len(layers) != 3
                or not all(_finite_number(value) for value in layers)
                or not all(_finite_number(case.get(name)) for name in (
                    "peakTemperature_K", "peakEdgeGradient_K",
                    "finalLayerSpread_K", "energyResidualNormalized"))):
            raise AssertionError("E10 nonfinite or missing scientific measurement")
        if not math.isclose(max(layers) - min(layers),
                            case["finalLayerSpread_K"], rel_tol=1e-7, abs_tol=1e-8):
            raise AssertionError("E10 final layer-spread contradicts layer temperatures")
    verification = data["verification"]
    expected_source_sha = os.environ.get("EXPECTED_SOURCE_SHA", "").strip().lower()
    if expected_source_sha:
        if len(expected_source_sha) != 40 or any(
                character not in "0123456789abcdef" for character in expected_source_sha):
            raise AssertionError("EXPECTED_SOURCE_SHA must be a full Git commit SHA")
        actual_commit = str(verification.get("gitCommit", "")).strip().lower()
        if actual_commit != expected_source_sha:
            raise AssertionError(
                "Regenerated MATLAB artifacts belong to a different source commit: "
                + actual_commit + " vs " + expected_source_sha)
    if verification.get("schemaVersion") != "thermoweave.verification/v1":
        raise AssertionError("Unexpected MATLAB verification schema")
    if manifest.get("verification") != verification:
        raise AssertionError("Embedded verification mismatch with regenerated test report")
    counts = [verification.get(key) for key in
              ("testCount", "passed", "failed", "incomplete")]
    if any(type(n) is not int or n < 0 for n in counts):
        raise AssertionError("MATLAB test totals must be nonnegative integers")
    if sum(counts[1:]) != counts[0] or counts[3] > 1:
        raise AssertionError("MATLAB test totals inconsistent or optional skips excessive")
    if verification.get("failed") != 0:
        raise AssertionError("Native MATLAB test failures recorded")
    if verification.get("testCount", 0) < 51:
        raise AssertionError("Missing the audited MATLAB regression inventory")
    if verification.get("codeAnalyzerFindings") != 0:
        raise AssertionError("MATLAB Code Analyzer findings remain; inspect SARIF")
    print("PASS: fresh versioned MATLAB artifacts, sources, digests and checks")
    print("Optional licensed Simscape and field-cell validation remain separate gates")


if __name__ == "__main__":
    try:
        verify()
    except (AssertionError, ValueError, OSError, KeyError) as ex:
        print("Artifact provenance verification FAILED:", ex, file=sys.stderr)
        sys.exit(1)
