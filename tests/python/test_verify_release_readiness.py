"""Fail-closed release evidence gates: adversarial Python fixtures (no MATLAB license)."""
import csv
import json
import hashlib
import importlib.util
from pathlib import Path
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]
SPEC = importlib.util.spec_from_file_location(
    "thermoweave_release_readiness", ROOT / "scripts/verify_release_readiness.py")
release = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(release)

REQUIRED = (
    "PHY-01", "PHY-02", "PHY-03", "PHY-04", "PHY-05",
    "NUM-01", "NUM-02", "NUM-03", "NUM-04",
    "CTRL-01", "CTRL-02", "CTRL-03", "CTRL-04",
    "FAULT-01", "FAULT-02", "FAULT-03", "FAULT-04",
    "SCN-01", "SCN-02", "SCN-03", "SCN-04",
    "DATA-01", "DATA-02", "DATA-03",
    "TEST-01", "TEST-02", "TEST-03",
    "CI-01", "GOV-01", "DOC-01", "DOC-02")


class ReleaseReadinessTests(unittest.TestCase):
    SHA = "a" * 40

    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.reports = self.root / "artifacts/reports"
        self.reports.mkdir(parents=True)
        self.web = {"matlabRelease": "2024a", "scenarios": [{"id": str(i)} for i in range(5)]}
        self.experiments = {"matlabRelease": "2024a", "records": [
            {"id": "E" + str(i), "status": "PASS"} for i in range(10)]}
        self.verification = {"gitCommit": self.SHA, "matlabRelease": "2024a",
                             "testCount": 63, "passed": 63, "failed": 0,
                             "incomplete": 0, "codeAnalyzerFindings": 0,
                             "simscapeAdapterStatus": "PASS"}
        self.study = {"matlabRelease": "2024a", "cases": [
            {"caseId": case, "gz_W_per_K": conductance,
             "nodeCount": 36, "edgeCount": 75, "scenarioHash": "a" * 64,
             "peakTemperature_K": 303.0, "peakEdgeGradient_K": 2.0,
             "finalLayerMeanTemperature_K": [300.0, 301.0, 302.0],
             "finalLayerSpread_K": 2.0, "energyResidualNormalized": 1e-12}
            for case, conductance in (("weak", 0.10), ("nominal", 0.25),
                                      ("strong", 0.75))],
            "artifacts": {"table": "artifacts/data/3d-study-results.csv"}}
        self.write("audit/SCIENTIFIC_VERIFICATION_MATRIX.md",
                   "# Scientific verification matrix\n\n" +
                   "".join(f"| {g} | **PASS** | Reviewed evidence |\n" for g in REQUIRED))
        self.write_json("audit/findings.json", {"schemaVersion": "thermoweave.audit-findings/v1",
                        "findings": [{"id": identity, "verification": {"status": "PASS",
                                      "evidence": ["test-only fixture"]}}
                                     for identity in release.REQUIRED_FINDINGS]})
        self.write_json("artifacts/reports/verification.json", self.verification)
        self.write_json("artifacts/reports/experiment-summary.json", self.experiments)
        self.write_json("artifacts/reports/3d-study-summary.json", self.study)
        csv_path = self.root / "artifacts/data/3d-study-results.csv"
        csv_path.parent.mkdir(parents=True, exist_ok=True)
        fields = ("caseId", "gz_W_per_K", "nodeCount", "edgeCount",
                  "peakTemperature_K", "peakEdgeGradient_K",
                  "finalLayerSpread_K", "energyResidualNormalized", "scenarioHash")
        with csv_path.open("w", encoding="utf-8", newline="") as stream:
            writer = csv.DictWriter(stream, fieldnames=fields)
            writer.writeheader()
            writer.writerows({key: case[key] for key in fields}
                             for case in self.study["cases"])
        self.write_json("artifacts/web-data/thermoweave-demo.json", self.web)
        self.write_json("docs/assets/thermoweave-demo.json", self.web)
        self.refresh_manifest()

    def write(self, path, text):
        target = self.root / path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(text, encoding="utf-8")

    def write_json(self, path, value):
        self.write(path, json.dumps(value, separators=(",", ":")))

    def refresh_manifest(self):
        webdata = (self.root / "artifacts/web-data/thermoweave-demo.json").read_bytes()
        self.write_json("artifacts/reports/artifact-manifest.json", {
            "matlabRelease": "2024a",
            "verification": self.verification,
            "webData": {"sha256": hashlib.sha256(webdata).hexdigest(),
                        "bytes": len(webdata), "scenarioCount": 5}})

    def assert_blocked(self):
        with self.assertRaises((AssertionError, ValueError)):
            release.verify_release_readiness(self.root, self.SHA)

    def test_happy_fixture_does_not_claim_real_cell_validation(self):
        release.verify_release_readiness(self.root, self.SHA)

    def test_missing_scientific_matrix_gate_blocks_release(self):
        path = self.root / "audit/SCIENTIFIC_VERIFICATION_MATRIX.md"
        path.write_text(path.read_text().replace("| PHY-05 |", "| OTHER-05 |"), encoding="utf-8")
        self.assert_blocked()

    def test_unverified_matrix_gate_blocks_release(self):
        path = self.root / "audit/SCIENTIFIC_VERIFICATION_MATRIX.md"
        path.write_text(path.read_text().replace("| **PASS** |", "| **NOT VERIFIED** |", 1),
                        encoding="utf-8")
        self.assert_blocked()

    def test_incomplete_licensed_qp_blocks_release(self):
        self.verification.update({"passed": 62, "incomplete": 1})
        self.write_json("artifacts/reports/verification.json", self.verification)
        self.refresh_manifest()
        self.assert_blocked()

    def test_simscape_skip_not_equivalent_to_parity(self):
        self.verification["simscapeAdapterStatus"] = "SKIPPED_MISSING_PRODUCT"
        self.write_json("artifacts/reports/verification.json", self.verification)
        self.refresh_manifest()
        self.assert_blocked()

    def test_e9_skip_blocks_release(self):
        self.experiments["records"][9]["status"] = "SKIPPED_MISSING_PRODUCT"
        self.write_json("artifacts/reports/experiment-summary.json", self.experiments)
        self.assert_blocked()

    def test_stale_source_sha_blocks_release(self):
        self.verification["gitCommit"] = "b" * 40
        self.write_json("artifacts/reports/verification.json", self.verification)
        self.refresh_manifest()
        self.assert_blocked()

    def test_stale_or_mismatched_web_json_blocks_release(self):
        self.web["scenarios"][0]["id"] = "modified"
        self.write_json("docs/assets/thermoweave-demo.json", self.web)
        self.assert_blocked()

    def test_manifest_sha_mismatch_blocks_release(self):
        self.web["scenarios"][0]["id"] = "tampered"
        self.write_json("artifacts/web-data/thermoweave-demo.json", self.web)
        self.write_json("docs/assets/thermoweave-demo.json", self.web)
        self.assert_blocked()

    def test_missing_e10_geometry_blocks_release(self):
        self.study["cases"][0]["edgeCount"] = 74
        self.write_json("artifacts/reports/3d-study-summary.json", self.study)
        self.assert_blocked()



class SimulationOutputAdapterContractTests(unittest.TestCase):
    """Static guard for a known MATLAB SimulationOutput API mismatch.

    A licensed end-to-end Simscape test remains mandatory; these checks only
    keep the mapper from invoking an API the deployed SimulationOutput lacks.
    """

    def test_simulation_output_uses_supported_variable_inventory(self):
        mapper = (ROOT / "simscape/mapSimscapeResults.m").read_text(encoding="utf-8")
        self.assertIn("who(raw)", mapper,
                      "SimulationOutput must enumerate its logged variables with who")
        self.assertNotIn("raw.hasVariable(", mapper,
                         "SimulationOutput.hasVariable caused the licensed E9 adapter failure")

    def test_packaged_adapter_cannot_claim_parity_without_canonical_log(self):
        mapper = (ROOT / "simscape/mapSimscapeResults.m").read_text(encoding="utf-8")
        runner = (ROOT / "simscape/runSimscapeScenario.m").read_text(encoding="utf-8")
        self.assertIn('"thermoweaveRaw"', mapper)
        self.assertIn("thermoweave:simscape:MissingCanonicalLog", mapper)
        self.assertIn("mapSimscapeResults(out, config)", runner)
        self.assertLess(runner.index("mapSimscapeResults(out, config)"),
                        runner.index('adapterResult.status = "PASS"'))


if __name__ == "__main__":
    unittest.main()
