"""Adversarial regression tests for provenance acceptance (no MATLAB required)."""
import copy
import csv
import hashlib
import importlib.util
import json
import os
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
            "simscapeAdapterStatus": "SKIPPED_MISSING_PRODUCT",
        }
        self.experiments = {
            "matlabRelease": "2024a", "schemaVersion": "thermoweave.experiments/v1",
            "records": [{"id": "E" + str(i),
                         "status": "PASS" if i < 9 else "SKIPPED_MISSING_PRODUCT",
                         "evidence": ({"adapterStatus": "SKIPPED_MISSING_PRODUCT"}
                                      if i == 9 else {})}
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

    def add_v2_fixture(self):
        def digest(number):
            return f"{number:064x}"

        self.manifest["scenarioCanonicalHashV2Algorithm"] = "thermoweave.canonical-json/v2"
        for i, scenario in enumerate(self.web["scenarios"]):
            scenario["scenarioCanonicalHashV2"] = digest(i + 1)
        self.verification["demo"] = {"scenarioCanonicalHashV2": digest(10)}
        self.study["sourceScenarioCanonicalHashV2"] = digest(11)
        for i, case in enumerate(self.study["cases"]):
            case["scenarioCanonicalHashV2"] = digest(i + 12)
        records = self.experiments["records"]
        for i in (0, 1, 2, 3, 5, 6, 7):
            records[i]["metrics"] = {"scenarioCanonicalHashV2": digest(i + 20)}
        records[4]["evidence"].update(
            seeds=[4401, 4402, 4403],
            scenarioCanonicalHashesV2=[digest(i) for i in range(30, 33)])
        records[7]["evidence"]["controllerScenarioCanonicalHashesV2"] = {
            "openloop": digest(40), "baseline": digest(27), "advanced": digest(41),
        }
        records[8]["evidence"].update(
            runCount=2, scenarioCanonicalHashesV2=[digest(50), digest(51)])
        self.write_fixture()

    def test_fresh_artifacts_require_v2_algorithm(self):
        with mock.patch.dict(os.environ, {"REQUIRE_SCENARIO_HASH_V2": "1"}):
            with self.assertRaisesRegex(AssertionError, "scenario hash v2 algorithm"):
                self.verify()

    def test_accepts_complete_v2_identity_bundle(self):
        self.add_v2_fixture()
        self.verify()

    def test_declared_v2_rejects_invalid_website_digest(self):
        self.add_v2_fixture()
        self.web["scenarios"][0]["scenarioCanonicalHashV2"] = "broken"
        self.write_fixture()
        with self.assertRaisesRegex(AssertionError, "Invalid scenario hash v2"):
            self.verify()

    def test_declared_v2_rejects_unpaired_controller_digest(self):
        self.add_v2_fixture()
        controllers = self.experiments["records"][7]["evidence"]["controllerScenarioCanonicalHashesV2"]
        controllers["baseline"] = "f" * 64
        self.write_fixture()
        with self.assertRaisesRegex(AssertionError, "E7 baseline scenario hash v2 mismatch"):
            self.verify()

    def test_declared_v2_rejects_missing_seeded_case_digest(self):
        self.add_v2_fixture()
        self.experiments["records"][8]["evidence"]["scenarioCanonicalHashesV2"].pop()
        self.write_fixture()
        with self.assertRaisesRegex(AssertionError, "Invalid seeded scenario hashes v2 for E8"):
            self.verify()

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
        self.write_sarif_fixture()

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

    def write_sarif_fixture(self):
        # The archived MATLAB Code Analyzer receipt reports zero findings.
        # Checking verification.json alone would trust a self-reported zero.
        path = self.root / "results/code-issues.sarif"
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(json.dumps({
            "version": "2.1.0",
            "runs": [{"tool": {"driver": {"name": "Code Analyzer"}}, "results": []}]
        }), encoding="utf-8")

    def write_junit_fixture(self):
        # Match the actual MATLAB JUnit shape: one suite has the optional
        # Optimization Toolbox assumption, all other test cases succeed.
        root = ET.Element("testsuites")
        # These named MATLAB regressions are essential evidence, not merely
        # interchangeable contributors to the aggregate pass count.
        required_cases = [
            ("TestScientificAuditGates", "downsampledControlHistoriesAlignWithTimeVector"),
            ("TestAuditRegressions", "downsampleExportRetainsTerminalStateAndMatchingTimebase"),
            ("TestScientificAuditGates", "controllerExecutionIdentityIsRecorded"),
            ("TestScientificAuditGates", "faultBetweenOutputTimesHasExactHeatDuration"),
            ("TestIndependentEnergyAcceptance", "forgedLegacyZeroCannotHideIncorrectHeat"),
            ("Test3DStudy", "canonicalResultHasThreeDimensionalState"),
            ("TestSimscapeModelProvenance", "modifiedModelBytesFailClosed"),
            ("TestIndependentEnergyAcceptance", "coolantEnergyResidualConvergesUnderRefinement"),
            ("TestScientificAuditGates", "advancedExecutionMetadataCannotClaimUnexecutedQP"),
        ]
        passing_by_class = {
            "TestAuditRegressions": [
                f"fixtureCase{index:02d}"
                for index in range(57 - len(required_cases))
            ],
        }
        for classname, name in required_cases:
            passing_by_class.setdefault(classname, []).append(name)
        for classname, names in passing_by_class.items():
            passing = ET.SubElement(root, "testsuite", {
                "name": classname, "tests": str(len(names)),
                "failures": "0", "errors": "0", "skipped": "0",
            })
            for name in names:
                ET.SubElement(passing, "testcase", {
                    "classname": classname, "name": name,
                })
        incomplete = ET.SubElement(root, "testsuite", {
            "name": "TestSimulationIntegration", "tests": "1",
            "failures": "0", "errors": "0", "skipped": "1",
        })
        optional = ET.SubElement(incomplete, "testcase", {
            "classname": "TestSimulationIntegration",
            "name": "advancedControllerCoolsHotZonesAndHonorsRate",
        })
        ET.SubElement(optional, "skipped").text = "Optimization Toolbox unavailable."
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

    def test_rejects_e10_energy_residual_above_declared_limit(self):
        # docs/scenarios.md sets <=1e-3 for the E10 synthetic model.
        # A finite but unacceptably large residual must not be attested.
        self.study["cases"][1]["energyResidualNormalized"] = 0.01
        self.write_fixture()
        with self.assertRaisesRegex(AssertionError, "E10 energy residual"):
            self.verify()

    def test_rejects_negative_e10_energy_residual(self):
        # Normalized absolute residual is a nonnegative metric.
        self.study["cases"][0]["energyResidualNormalized"] = -0.01
        self.write_fixture()
        with self.assertRaisesRegex(AssertionError, "E10 energy residual"):
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

    def test_rejects_downsampled_cell_width_change(self):
        # A matching time-axis length is not sufficient: temperature vectors
        # must retain one fixed physical-cell dimension after downsampling.
        self.web["scenarios"][0]["temperature_C"][1] = [22]
        self.write_fixture()
        with self.assertRaisesRegex(AssertionError, "website.*width"):
            self.verify()

    def test_rejects_downsampled_boundary_cell_mismatch(self):
        # The boundary temperature must address exactly the same physical
        # cells as the model temperature at every exported timestamp.
        self.web["scenarios"][0]["boundaryTemperature_C"] = [[20], [20]]
        self.write_fixture()
        with self.assertRaisesRegex(AssertionError, "website.*width"):
            self.verify()

    def test_rejects_downsampled_zone_command_width_change(self):
        # Zone commands cannot silently gain or lose actuators between two
        # downsampled samples even when the sample timestamps still align.
        self.web["scenarios"][0]["zoneCommand"][1] = [0, 0]
        self.write_fixture()
        with self.assertRaisesRegex(AssertionError, "website.*width"):
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

    def test_rejects_missing_qp_regression_disguised_as_all_green(self):
        # 58/58 PASS is not proof that the licensed advanced-controller
        # regression ran. A replaced JUnit testcase must fail provenance even
        # if both the XML and regenerated JSON totals agree exactly.
        self.verification["passed"] += 1
        self.verification["incomplete"] = 0
        self.write_fixture()
        path = self.root / "results/test-results.xml"
        junit = ET.parse(path)
        case = next(case for case in junit.iter("testcase")
                    if case.get("name") == "advancedControllerCoolsHotZonesAndHonorsRate")
        case.set("name", "unrelatedPassingQPPlaceholder")
        case.remove(case.find("skipped"))
        suite = next(suite for suite in junit.iter("testsuite")
                     if suite.get("name") == "TestSimulationIntegration")
        suite.set("skipped", "0")
        junit.write(path, encoding="utf-8")
        with self.assertRaisesRegex(AssertionError, "required scientific regression"):
            self.verify()

    def test_rejects_qp_skip_for_unrelated_failure_reason(self):
        # A named QP regression cannot be filtered for a scientific defect
        # while claiming the only permitted optional license assumption.
        path = self.root / "results/test-results.xml"
        junit = ET.parse(path)
        case = next(case for case in junit.iter("testcase")
                    if case.get("name") == "advancedControllerCoolsHotZonesAndHonorsRate")
        case.find("skipped").text = "Numerical convergence assumption failed."
        junit.write(path, encoding="utf-8")
        with self.assertRaisesRegex(AssertionError, "QP skip reason"):
            self.verify()

    def test_rejects_qp_skip_without_diagnostic(self):
        path = self.root / "results/test-results.xml"
        junit = ET.parse(path)
        case = next(case for case in junit.iter("testcase")
                    if case.get("name") == "advancedControllerCoolsHotZonesAndHonorsRate")
        case.find("skipped").text = None
        junit.write(path, encoding="utf-8")
        with self.assertRaisesRegex(AssertionError, "QP skip reason"):
            self.verify()

    def test_rejects_omitted_downsampled_history_test_with_same_totals(self):
        # A misleading 57-pass/1-skip receipt can omit the critical
        # downsampled controller-history regression without changing counts.
        path = self.root / "results/test-results.xml"
        junit = ET.parse(path)
        case = next(case for case in junit.iter("testcase")
                    if case.get("name") == "downsampledControlHistoriesAlignWithTimeVector")
        case.set("name", "unrelatedPassingTest")
        junit.write(path, encoding="utf-8")
        with self.assertRaisesRegex(AssertionError, "required scientific regression"):
            self.verify()

    def test_rejects_omitted_model_provenance_regression_with_same_totals(self):
        # A green aggregate count is not evidence that the model-byte
        # tampering regression actually executed.
        path = self.root / "results/test-results.xml"
        junit = ET.parse(path)
        case = next(case for case in junit.iter("testcase")
                    if case.get("name") == "modifiedModelBytesFailClosed")
        case.set("name", "otherPassingTest")
        junit.write(path, encoding="utf-8")
        with self.assertRaisesRegex(AssertionError, "required scientific regression"):
            self.verify()

    def test_rejects_simscape_skip_not_attributable_to_missing_product(self):
        # Missing approved model or unresolved policy is not a licensed
        # scientific success and must not be an acceptable hosted E9 skip.
        self.experiments["records"][9]["status"] = "SKIPPED_MODEL_NOT_GENERATED"
        self.experiments["records"][9]["evidence"]["adapterStatus"] = (
            "SKIPPED_MODEL_NOT_GENERATED"
        )
        self.verification["simscapeAdapterStatus"] = "SKIPPED_MODEL_NOT_GENERATED"
        self.write_fixture()
        with self.assertRaisesRegex(AssertionError, "Simscape"):
            self.verify()

    def test_rejects_e9_pass_when_verification_records_product_skip(self):
        # Rewriting only E9 experiment/evidence to PASS must not override
        # an independent verification.json missing-license record.
        self.experiments["records"][9]["status"] = "PASS"
        self.experiments["records"][9]["evidence"]["adapterStatus"] = "PASS"
        self.write_fixture()
        with self.assertRaisesRegex(AssertionError, "Simscape"):
            self.verify()

    def test_rejects_e9_evidence_status_mismatch(self):
        # Each of experiment summary, adapter evidence, and verification
        # report must describe the same executed/skip outcome.
        self.experiments["records"][9]["evidence"]["adapterStatus"] = "PASS"
        self.write_fixture()
        with self.assertRaisesRegex(AssertionError, "Simscape"):
            self.verify()

    def test_rejects_missing_code_analyzer_sarif(self):
        # The JSON claim of zero findings is not a separate static receipt.
        (self.root / "results/code-issues.sarif").unlink()
        with self.assertRaisesRegex(AssertionError, "SARIF"):
            self.verify()

    def test_rejects_sarif_warning_hidden_by_zero_json_count(self):
        sarif = self.root / "results/code-issues.sarif"
        payload = json.loads(sarif.read_text(encoding="utf-8"))
        payload["runs"][0]["results"] = [{
            "ruleId": "MATLAB:WARN", "level": "warning",
            "message": {"text": "Synthetic warning for acceptance test"}
        }]
        sarif.write_text(json.dumps(payload), encoding="utf-8")
        with self.assertRaisesRegex(AssertionError, "SARIF"):
            self.verify()

    def test_rejects_stale_code_analyzer_sarif(self):
        sarif = self.root / "results/code-issues.sarif"
        marker = self.root / "results/artifact-regeneration-start.flag"
        stale = marker.stat().st_mtime - 60
        os.utime(sarif, (stale, stale))
        with self.assertRaisesRegex(AssertionError, "SARIF"):
            self.verify()

    def test_rejects_sarif_missing_code_analyzer_run(self):
        sarif = self.root / "results/code-issues.sarif"
        sarif.write_text('{"version":"2.1.0","runs":[]}', encoding="utf-8")
        with self.assertRaisesRegex(AssertionError, "SARIF"):
            self.verify()


if __name__ == "__main__":
    unittest.main()
