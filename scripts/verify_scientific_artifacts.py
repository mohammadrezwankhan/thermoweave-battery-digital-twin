"""Validate fresh R2024a ThermoWeave artifacts without masking scientific failures."""
import hashlib
import json
import os
from pathlib import Path
import sys


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
        data[key] = json.loads(file.read_text(encoding="utf-8"))
        actual_release = str(data[key].get("matlabRelease", ""))
        if actual_release != expected_release:
            raise AssertionError(
                f"Wrong MATLAB release for {name}: {actual_release!r} vs {expected_release}")
        print("Verified regenerated artifact", name, actual_release)
    manifest = data["manifest"]
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
    experiments = data["experiments"]
    if experiments.get("schemaVersion") != "thermoweave.experiments/v1":
        raise AssertionError("Experiment schema mismatch")
    rows = experiments.get("records", [])
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
    cases = study.get("cases", [])
    if len(cases) != 3 or any(
        c.get("nodeCount") != 36 or c.get("edgeCount") != 75 or
        not c.get("scenarioHash") for c in cases
    ):
        raise AssertionError("E10 geometry or scenario hashes invalid")
    verification = data["verification"]
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
