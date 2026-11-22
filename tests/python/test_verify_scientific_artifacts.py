"""Adversarial regression tests for provenance acceptance (no MATLAB required)."""
import copy
import csv
import hashlib
import importlib.util
import json
from pathlib import Path
import tempfile
import unittest
import xml.etree.ElementTree as ET
from unittest import mock


HERE = Path(__file__).resolve().parents[2]
SPEC = importlib.util.spec_from_file_location(
    "thermoweave_artifact_verifier", HERE / "scripts/verify_scientific_artifacts.py"
)
verifier = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(verifier)


class ArtifactAcceptanceTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        self.expected_sha = "a" * 40
        env_patch = mock.patch.dict("os.environ", {"EXPECTED_SOURCE_SHA": self.expected_sha})
        env_patch.start()
        self.addCleanup(env_patch.stop)
        marker = self.root / "results/artifact-regeneration-start.flag"
        marker.parent.mkdir(parents=True, exist_ok=True)
        marker.touch()
        self.names = {
            "manifest": "artifacts/reports/artifact-manifest.json",
            "verification": "artifacts/reports/verification.json",
            "experiments": "artifacts/reports/experiment-summary.json",
            "study": "artifacts/reports/3d-study-summary.json",
            "web": "artifacts/web-data/thermoweave-demo.json",
            "web-copy": "docs/assets/thermoweave-demo.json",
        }
        self.web = {
            "matlabRelease": "2024a", "schemaVersion": "thermoweave.web/v1",
            "syntheticData": True,
            "scenarios": [
                {"id": str(i), "sourceSchema": "thermoweave.result/v1",
                 "scenarioHash": "a" * 64, "time_s": [0, 1],
                 "temperature_C": [[20, 21], [22, 23]],
                 "boundaryTemperature_C": [[20, 20], [20, 20]],
                 "zoneCommand": [[0], [0]]}
                for i in range(5)
            ],
        }
        self.study = {
            "matlabRelease": "2024a",
            "schemaVersion": "thermoweave.study3d/v1",
            "cases": [
                {"caseId": case, "gz_W_per_K": conductance,
                 "nodeCount": 36, "edgeCount": 75, "scenarioHash": "b" * 64,
                 "peakTemperature_K": 304.0, "peakEdgeGradient_K": 2.0,
                 "finalLayerMeanTemperature_K": [300, 302, 304],
                 "finalLayerSpread_K": 4.0, "energyResidualNormalized": 1e-12}
                for case, conductance in (
                    ("weak", 0.10), ("nominal", 0.25), ("strong", 0.75))
            ],
        }
        self.verification = {
            "schemaVersion": "thermoweave.verification/v1",
            "matlabRelease": "2024a", "testCount": 58,
            "passed": 57, "failed": 0, "incomplete": 1,
            "codeAnalyzerFindings": 0, "gitCommit": "a" * 40,
        }
        self.experiments = {
            "matlabRelease": "2024a", "schemaVersion": "thermoweave.experiments/v1",
            "records": [{"id": "E" + str(i),
                         "status": "PASS" if i < 9 else "SKIPPED_MISSING_PRODUCT"}
                        for i in range(10)],
        }
        self.manifest = {
            "matlabRelease": "2024a",
            "schemaVersion": "thermoweave.artifacts/v1",
            "webData": {
                "path": self.names["web"],
                "bytes": 0, "sha256": "", "scenarioCount": 5,
            },
        }
        self.write_fixture()

    def write(self, key, value):
        file = self.root / self.names[key]
        file.parent.mkdir(parents=True, exist_ok=True)
        file.write_text(json.dumps(value, separators=(",", ":")), encoding="utf-8")

    def write_fixture(self):
        self.write("web", self.web)
        self.write("web-copy", self.web)
        web_bytes = (self.root / self.names["web"]).read_bytes()
        self.manifest["webData"]["sha256"] = hashlib.sha256(web_bytes).hexdigest()
        self.manifest["webData"]["bytes"] = len(web_bytes)
        for key, item in [
            ("manifest", self.manifest), ("verification", self.verification),
            ("experiments", self.experiments), ("study", self.study)
        ]:
            self.write(key, item)
        self.manifest["experiments"] = {
            "path": self.names["experiments"],
            "sha256": hashlib.sha256(
                (self.root / self.names["experiments"]).read_bytes()
            ).hexdigest(),
            "scenarioCount": len(self.experiments["records"]),
        }
        self.manifest["verification"] = copy.deepcopy(self.verification)
        self.manifest["study3d"] = copy.deepcopy(self.study)
        self.write("manifest", self.manifest)
        self.write_junit_fixture()
        self.write_study_csv_fixture()

    def write_study_csv_fixture(self):
        # Mirror the published 3-D study CSV independently of JSON fixtures.
        path = self.root / "artifacts/data/3d-study-results.csv"
        path.parent.mkdir(parents=True, exist_ok=True)
        columns = ["caseId", "gz_W_per_K", "nodeCount", "edgeCount",
                   "peakTemperature_K", "peakEdgeGradient_K",
                   "finalLayerSpread_K", "energyResidualNormalized",
                   "scenarioHash"]
        with path.open("w", encoding="utf-8", newline="") as stream:
            writer = csv.DictWriter(stream, fieldnames=columns)
            writer.writeheader()
            for case in self.study["cases"]:
                writer.writerow({key: case[key] for key in columns})

    def write_junit_fixture(self):
        # Match the actual MATLAB JUnit shape: one suite has the optional
        # Optimization Toolbox assumption, all other test cases succeed.
        root = ET.Element("testsuites")
        passing = ET.SubElement(root, "testsuite", {
            "name": "TestAuditRegressions", "tests": "57",
            "failures": "0", "errors": "0", "skipped": "0",
        })
        for index in range(57):
            ET.SubElement(passing, "testcase", {
                "classname": "TestAuditRegressions",
                "name": f"fixtureCase{index:02d}",
            })
        incomplete = ET.SubElement(root, "testsuite", {
            "name": "TestSimulationIntegration", "tests": "1",
            "failures": "0", "errors": "0", "skipped": "1",
        })
        optional = ET.SubElement(incomplete, "testcase", {
            "classname": "TestSimulationIntegration",
            "name": "advancedControllerCoolsHotZonesAndHonorsRate",
        })
        ET.SubElement(optional, "skipped")
        path = self.root / "results/test-results.xml"
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_bytes(ET.tostring(root, encoding="utf-8"))

    def verify(self):
        with mock.patch.object(
            verifier, "__file__",
            str(self.root / "scripts/verify_scientific_artifacts.py"),
        ):
            verifier.verify()

    def test_rejects_missing_published_e10_csv(self):
        # Previously the manifest validated JSON but never read the CSV.
        (self.root / "artifacts/data/3d-study-results.csv").unlink()
        with self.assertRaisesRegex(AssertionError, "E10 CSV"):
            self.verify()

    def test_rejects_e10_csv_measurement_inconsistent_with_json(self):
        # A different peak temperature must not be published as verified.
        path = self.root / "artifacts/data/3d-study-results.csv"
        with path.open(encoding="utf-8", newline="") as stream:
            rows = list(csv.DictReader(stream))
        rows[1]["peakTemperature_K"] = "999"
        with path.open("w", encoding="utf-8", newline="") as stream:
            writer = csv.DictWriter(stream, fieldnames=list(rows[0]))
            writer.writeheader()
            writer.writerows(rows)
        with self.assertRaisesRegex(AssertionError, "E10 CSV"):
            self.verify()

    def test_valid_complete_synthetic_bundle_is_accepted(self):
        self.verify()

    def test_rejects_duplicate_e10_conductance_case(self):
        self.study["cases"][0]["caseId"] = "nominal"
        self.study["cases"][0]["gz_W_per_K"] = 0.25
        self.write_fixture()
        with self.assertRaises(AssertionError):
            self.verify()

    def test_rejects_nonfinite_e10_measurements(self):
        self.study["cases"][1]["peakTemperature_K"] = float("nan")
        self.write_fixture()
        with self.assertRaises((AssertionError, ValueError)):
            self.verify()

    def test_rejects_inconsistent_matlab_test_inventory(self):
        self.verification["passed"] = 1
        self.write_fixture()
        with self.assertRaises(AssertionError):
            self.verify()

    def test_rejects_unaligned_website_temperature_history(self):
        self.web["scenarios"][0]["temperature_C"].pop()
        self.write_fixture()
        with self.assertRaises(AssertionError):
            self.verify()

    def test_rejects_incorrect_artifact_manifest_schema(self):
        self.manifest["schemaVersion"] = "thermoweave.artifacts/unknown"
        self.write_fixture()
        with self.assertRaises(AssertionError):
            self.verify()


    def test_accepts_artifacts_attributed_to_exact_source_commit(self):
        self.verification["gitCommit"] = "a" * 40
        self.write_fixture()
        with mock.patch.dict("os.environ", {"EXPECTED_SOURCE_SHA": "a" * 40}):
            self.verify()

    def test_rejects_artifacts_attributed_to_wrong_git_commit(self):
        self.verification["gitCommit"] = "b" * 40
        self.write_fixture()
        with mock.patch.dict("os.environ", {"EXPECTED_SOURCE_SHA": "a" * 40}):
            with self.assertRaises(AssertionError):
                self.verify()

    def test_rejects_artifacts_without_git_commit(self):
        self.verification.pop("gitCommit", None)
        self.write_fixture()
        with mock.patch.dict("os.environ", {"EXPECTED_SOURCE_SHA": "a" * 40}):
            with self.assertRaises(AssertionError):
                self.verify()



    def test_rejects_missing_expected_source_sha(self):
        # A standalone invocation must not silently disable commit binding.
        with mock.patch.dict("os.environ", {"EXPECTED_SOURCE_SHA": ""}):
            with self.assertRaisesRegex(AssertionError, "EXPECTED_SOURCE_SHA"):
                self.verify()

    def test_rejects_duplicated_web_scenario_ids(self):
        # Five records are not five distinct selectable dashboard scenarios.
        self.web["scenarios"][1]["id"] = self.web["scenarios"][0]["id"]
        self.write_fixture()
        with self.assertRaisesRegex(AssertionError, "scenario.*duplicate"):
            self.verify()

    def test_rejects_wrong_experiment_manifest_digest(self):
        self.manifest["experiments"]["sha256"] = "0" * 64
        self.write("manifest", self.manifest)
        with self.assertRaisesRegex(AssertionError, "Experiment.*SHA"):
            self.verify()

    def test_rejects_conflicting_embedded_verification_result(self):
        self.manifest["verification"]["passed"] = 55
        self.write("manifest", self.manifest)
        with self.assertRaisesRegex(AssertionError, "verification.*mismatch"):
            self.verify()

    def test_rejects_conflicting_manifest_e10_study(self):
        self.manifest["study3d"]["cases"][1]["edgeCount"] = 1
        self.write("manifest", self.manifest)
        with self.assertRaisesRegex(AssertionError, "study.*mismatch"):
            self.verify()


    def test_rejects_junit_claim_disagreement(self):
        # A forged JSON claim of 58 green tests must not override the
        # actual 57-pass/1-incomplete MATLAB JUnit evidence.
        self.verification["passed"] = 58
        self.verification["incomplete"] = 0
        self.write_fixture()
        with self.assertRaisesRegex(AssertionError, "JUnit"):
            self.verify()

    def test_rejects_missing_junit_test_evidence(self):
        (self.root / "results/test-results.xml").unlink()
        with self.assertRaisesRegex(AssertionError, "JUnit"):
            self.verify()

    def test_rejects_duplicate_junit_test_identity(self):
        path = self.root / "results/test-results.xml"
        xml = ET.parse(path)
        cases = list(xml.iter("testcase"))
        cases[1].set("name", cases[0].get("name"))
        xml.write(path, encoding="utf-8")
        with self.assertRaisesRegex(AssertionError, "JUnit"):
            self.verify()

if __name__ == "__main__":
    unittest.main()
