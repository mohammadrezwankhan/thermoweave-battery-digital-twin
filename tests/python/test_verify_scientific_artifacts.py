"""Adversarial regression tests for provenance acceptance (no MATLAB required)."""
import copy
import csv
from datetime import datetime, timezone
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
                 "temperature_C": [[20 + j for j in range(12)],
                                    [22 + j for j in range(12)]],
                 "boundaryTemperature_C": [[20] * 12, [20] * 12],
                 "zoneCommand": [[0] * 4, [0] * 4],
                 "metrics": {
                     "minimumTemperature_K": 292.15,
                     "peakTemperature_K": 307.15,
                     "coolingEnergy_J": 0.0,
                     "timeAboveThreshold_s": 0.0,
                     "peakEdgeGradient_K": 1.0,
                     "energyResidualNormalized": 1e-12,
                 }}
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
            "timestampUtc": datetime.fromtimestamp(
                marker.stat().st_mtime, timezone.utc
            ).strftime("%Y-%m-%dT%H:%M:%SZ"),
        }
        self.experiments = {
            "matlabRelease": "2024a", "schemaVersion": "thermoweave.experiments/v1",
            "records": [{"id": "E" + str(i),
                         "status": "PASS" if i < 9 else "SKIPPED_MISSING_PRODUCT",
                         "evidence": ({"adapterStatus": "SKIPPED_MISSING_PRODUCT"}
                                      if i == 9 else {})}
                        for i in range(10)],
        }
        # Populate the observable E0-E8 evidence, not just PASS labels.
        # These synthetic fixtures are independent of MATLAB execution.
        records = self.experiments["records"]
        for i in (0, 1, 2, 3, 5, 6, 7):
            records[i]["metrics"] = {
                "peakTemperature_K": 300.0, "peakEdgeGradient_K": 0.5,
                "coolingEnergy_J": 1.0, "energyResidualNormalized": 1e-8,
                "integratedEnergyResidualNormalized": 1e-5,
                "scenarioHash": f"{i + 100:064x}",
            }
        evidence = {
            0: {"maximumDrift_K": 0.0},
            1: {"distinctBoundaryValues": 7},
            2: {"reversePatternDifference_K": 0.4,
                "reverseResidual": 1e-8,
                "reverseIntegratedEnergyResidualNormalized": 1e-5,
                "coolantBalanceError_W": 1e-12},
            3: {"peakRiseReductionFraction": 0.5,
                "openLoopPeakTemperature_K": 302.0},
            4: {"seeds": [4401, 4402, 4403],
                "peakTemperature_K": [299.0, 300.0, 301.0],
                "scenarioHashes": [f"{i:064x}" for i in range(200, 203)],
                "drawsPositive": [True, True, True],
                "firstSeedRepeatedExactly": True},
            5: {"faultTarget": 2, "measuredConductanceFactor": 0.2,
                "otherSegmentsUnchanged": True},
            6: {"faultTarget": 2, "bias_K": 5},
            7: {"openLoopPeakTemperature_K": 302.0,
                "advancedPeakTemperature_K": 299.0,
                "advancedFallbackEvents": 0, "commandsBounded": True,
                "benefitClaim": "descriptive-only"},
            8: {"runCount": 20, "firstSeed": 6100, "lastSeed": 6119,
                "peakTemperature95th_K": 299.0},
        }
        for i, item in evidence.items():
            records[i]["evidence"] = item
        records[0]["metrics"].update(peakEdgeGradient_K=0.0,
                                     coolingEnergy_J=0.0,
                                     energyResidualNormalized=0.0,
                                     integratedEnergyResidualNormalized=0.0)
        records[4]["metrics"] = {"peakTemperature_K": 301.0}
        records[8]["metrics"] = {"peakTemperature_K": 300.0,
                                  "coolingEnergy_J": 1.0}
        records[9]["metrics"] = {}
        self.experiments["syntheticData"] = True
        self.experiments["scenarioSpecification"] = "docs/scenarios.md"
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
            records[i]["metrics"]["scenarioCanonicalHashV2"] = digest(i + 20)
        records[4]["evidence"].update(
            seeds=[4401, 4402, 4403],
            scenarioCanonicalHashesV2=[digest(i) for i in range(30, 33)])
        records[7]["evidence"]["controllerScenarioCanonicalHashesV2"] = {
            "openloop": digest(40), "baseline": digest(27), "advanced": digest(41),
        }
        records[8]["evidence"].update(
            scenarioCanonicalHashesV2=[digest(i) for i in range(50, 70)])
        self.write_fixture()

    def test_rejects_contradictory_website_metrics(self):
        # The dashboard displays full-trajectory metrics beside a downsampled
        # history. Full-history extrema must enclose the exported samples;
        # they need not equal them. Rehashing contradictory data is not proof.
        cases = (
            ("peakTemperature_K", 300.0),
            ("minimumTemperature_K", 295.0),
            ("coolingEnergy_J", -1.0),
            ("timeAboveThreshold_s", 2.0),
            ("peakEdgeGradient_K", None),
            ("peakEdgeGradient_K", True),
            ("peakEdgeGradient_K", -0.01),
            ("peakEdgeGradient_K", 16.0),
            ("energyResidualNormalized", None),
            ("energyResidualNormalized", "1e-9"),
            ("energyResidualNormalized", -1e-9),
        )
        for key, invalid in cases:
            with self.subTest(metric=key):
                original = self.web["scenarios"][0]["metrics"][key]
                self.web["scenarios"][0]["metrics"][key] = invalid
                try:
                    self.write_fixture()
                    with self.assertRaisesRegex(AssertionError, "website.*metrics"):
                        self.verify()
                finally:
                    self.web["scenarios"][0]["metrics"][key] = original

    def test_fresh_artifacts_require_v2_algorithm(self):
        with mock.patch.dict(os.environ, {"REQUIRE_SCENARIO_HASH_V2": "1"}):
            with self.assertRaisesRegex(AssertionError, "scenario hash v2 algorithm"):
                self.verify()

    def test_licensed_release_workflow_requires_canonical_v2(self):
        # The manual licensed Pages/tag evidence workflow must enforce the
        # same canonical identity policy as hosted scientific reproduction.
        # A missing manifest declaration otherwise disables v2 validation.
        workflow = (HERE / ".github/workflows/simscape-integration.yml").read_text(
            encoding="utf-8")
        step = workflow.split(
            "- name: Require complete exact-source licensed evidence", 1)[1]
        step = step.split("\n      - name:", 1)[0]
        self.assertIn("python3 scripts/verify_scientific_artifacts.py", step)
        self.assertRegex(step, r"(?m)^\s+REQUIRE_SCENARIO_HASH_V2:\s*['\"]?1['\"]?\s*$",
                         "Licensed release must require canonical v2 provenance")

    def test_licensed_main_producer_requires_numerical_e9(self):
        # Both licensed evidence producers must reject execution-only E9
        # before uploading. The later publication veto is not a substitute
        # for checking numerical parity at the producer.
        workflow = (HERE / ".github/workflows/simscape-integration.yml").read_text(
            encoding="utf-8")
        step = workflow.split(
            "- name: Require complete exact-source licensed evidence", 1)[1]
        step = step.split("\n      - name:", 1)[0]
        self.assertIn("python3 scripts/verify_scientific_artifacts.py", step)
        self.assertRegex(step, r"(?m)^\s+REQUIRE_LICENSED_E9:\s*['\"]?1['\"]?\s*$",
                         "Licensed main producer must enforce numerical E9 parity")

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

    def test_declared_v2_rejects_duplicate_e10_conductance_digest(self):
        # Distinct E10 conductance configurations require distinct typed hashes.
        # Copying a valid hash to another case must not pass provenance review.
        self.add_v2_fixture()
        cases = self.study["cases"]
        cases[1]["scenarioCanonicalHashV2"] = cases[0]["scenarioCanonicalHashV2"]
        self.write_fixture()
        with self.assertRaisesRegex(AssertionError, "Duplicate E10 scenario hash v2"):
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
            "monteCarloRuns": 20,
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
            ("TestAuditRegressions",
             "overlappingFaultsRespectControllerClock(controllerMode=baseline)"),
            ("TestAuditRegressions",
             "overlappingFaultsRespectControllerClock(controllerMode=advanced)"),
            ("TestAnisotropicThermalGraph",
             "toleranceSweepConvergesAcrossStiffness(solver=ode45,scenario=mild)"),
            ("TestAnisotropicThermalGraph",
             "toleranceSweepConvergesAcrossStiffness(solver=ode45,scenario=moderate)"),
            ("TestAnisotropicThermalGraph",
             "toleranceSweepConvergesAcrossStiffness(solver=ode45,scenario=stiff)"),
            ("TestAnisotropicThermalGraph",
             "toleranceSweepConvergesAcrossStiffness(solver=ode15s,scenario=mild)"),
            ("TestAnisotropicThermalGraph",
             "toleranceSweepConvergesAcrossStiffness(solver=ode15s,scenario=moderate)"),
            ("TestAnisotropicThermalGraph",
             "toleranceSweepConvergesAcrossStiffness(solver=ode15s,scenario=stiff)"),
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

    def test_rejects_contradictory_pass_experiment_receipts(self):
        # Recompute the report digest and retain PASS, so only scientific
        # consistency (not corruption or a stale hash) can reject the bundle.
        cases = [
            (0, "evidence", "maximumDrift_K", 1.0),
            (1, "evidence", "distinctBoundaryValues", 1),
            (2, "evidence", "reversePatternDifference_K", 0.0),
            (2, "evidence", "coolantBalanceError_W", 1e-3),
            (2, "evidence", "reverseIntegratedEnergyResidualNormalized", 0.1),
            (3, "evidence", "peakRiseReductionFraction", 0.01),
            (3, "metrics", "peakTemperature_K", 330.0),
            (4, "evidence", "drawsPositive", [True, False, True]),
            (4, "evidence", "firstSeedRepeatedExactly", False),
            (5, "evidence", "measuredConductanceFactor", 1.0),
            (5, "evidence", "otherSegmentsUnchanged", False),
            (6, "evidence", "faultTarget", 3),
            (7, "evidence", "commandsBounded", False),
            (7, "evidence", "benefitClaim", "universal-superiority"),
            (8, "evidence", "lastSeed", 6118),
            (8, "evidence", "peakTemperature95th_K", 400.0),
            (1, "metrics", "integratedEnergyResidualNormalized", 0.1),
            (5, "metrics", "integratedEnergyResidualNormalized", -0.1),
        ]
        original = copy.deepcopy(self.experiments)
        for index, section, field, invalid in cases:
            with self.subTest(experiment=index, field=field):
                self.experiments = copy.deepcopy(original)
                self.experiments["records"][index][section][field] = invalid
                self.write_fixture()
                with self.assertRaisesRegex(AssertionError, r"E[0-8]"):
                    self.verify()

    def test_rejects_nonphysical_experiment_kelvin(self):
        # Keep PASS labels and recompute the manifest digest. All reported
        # thermodynamic temperatures must be strictly positive in Kelvin.
        original = copy.deepcopy(self.experiments)
        cases = [
            (i, "metrics", "peakTemperature_K", -1.0)
            for i in (0, 1, 2, 3, 5, 6, 7, 8)
        ] + [
            (3, "evidence", "openLoopPeakTemperature_K", 0.0),
            (4, "evidence", "peakTemperature_K", [-1.0, 300.0, 301.0]),
            (7, "evidence", "openLoopPeakTemperature_K", -1.0),
            (7, "evidence", "advancedPeakTemperature_K", 0.0),
            (8, "evidence", "peakTemperature95th_K", -1.0),
        ]
        for index, section, field, invalid in cases:
            with self.subTest(experiment=index, field=field):
                self.experiments = copy.deepcopy(original)
                self.experiments["records"][index][section][field] = invalid
                self.write_fixture()
                with self.assertRaisesRegex(AssertionError, r"E[0-8]"):
                    self.verify()
        self.experiments = original
        self.write_fixture()
        self.verify()

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

    def test_rejects_nonphysical_website_kelvin(self):
        # Consistent dimensions, finite values and a recomputed manifest cannot
        # establish physical validity below absolute zero. Include a cell
        # history with enclosing metrics, a boundary history, and metrics alone.
        original = copy.deepcopy(self.web)
        for target in ("cell", "boundary", "minimum"):
            with self.subTest(target=target):
                self.web = copy.deepcopy(original)
                scenario = self.web["scenarios"][0]
                if target == "cell":
                    scenario["temperature_C"][1][0] = -274.15
                    scenario["metrics"]["minimumTemperature_K"] = -1.0
                elif target == "boundary":
                    scenario["boundaryTemperature_C"][1][0] = -274.15
                else:
                    scenario["metrics"]["minimumTemperature_K"] = -1.0
                self.write_fixture()
                with self.assertRaisesRegex(AssertionError, "website.*temperature|website.*metrics"):
                    self.verify()
        self.web = original
        self.write_fixture()
        self.verify()

    def test_rejects_downsampled_zone_command_width_change(self):
        # Zone commands cannot silently gain or lose actuators between two
        # downsampled samples even when the sample timestamps still align.
        self.web["scenarios"][0]["zoneCommand"][1] = [0, 0]
        self.write_fixture()
        with self.assertRaisesRegex(AssertionError, "website.*width"):
            self.verify()

    def test_rejects_out_of_range_downsampled_zone_commands(self):
        # docs/model.md declares normalized actuator commands in [0, 1].
        # Recomputing both website copies and their digest must not hide a
        # finite but physically invalid command in an otherwise aligned row.
        for value in (-0.01, 1.01):
            with self.subTest(value=value):
                self.web["scenarios"][0]["zoneCommand"][1][2] = value
                self.write_fixture()
                with self.assertRaisesRegex(AssertionError, "website.*zoneCommand.*bounds"):
                    self.verify()

    def test_accepts_zone_command_endpoints(self):
        self.web["scenarios"][0]["zoneCommand"][1] = [0, 1, 0.25, 0.75]
        self.write_fixture()
        self.verify()

    def test_rejects_consistently_truncated_cell_inventory(self):
        # The time/width guards alone cannot detect uniformly losing a cell:
        # all samples and both temperature fields can still agree at 11 cells.
        scenario = self.web["scenarios"][0]
        for field in ("temperature_C", "boundaryTemperature_C"):
            scenario[field] = [row[:-1] for row in scenario[field]]
        self.write_fixture()
        with self.assertRaisesRegex(AssertionError, "website.*12 cell"):
            self.verify()

    def test_rejects_consistently_truncated_zone_command_inventory(self):
        # A missing actuator from every sample must not be accepted just
        # because the downsampled timebase and row widths are consistent.
        scenario = self.web["scenarios"][0]
        scenario["zoneCommand"] = [row[:-1] for row in scenario["zoneCommand"]]
        self.write_fixture()
        with self.assertRaisesRegex(AssertionError, "website.*4 zone"):
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



    def test_rejects_missing_stale_or_future_verification_timestamp(self):
        # The files can be freshly rewritten while the embedded verification
        # timestamp is missing or belongs to an unrelated run. Match the
        # duplicated manifest receipt so that its equality check cannot mask
        # this defect. MATLAB emits UTC timestamps with whole-second precision.
        marker = self.root / "results/artifact-regeneration-start.flag"
        start = marker.stat().st_mtime
        from datetime import datetime, timezone
        def utc_stamp(seconds):
            return datetime.fromtimestamp(seconds, timezone.utc).strftime(
                "%Y-%m-%dT%H:%M:%SZ")
        self.verification["timestampUtc"] = utc_stamp(start)
        self.write_fixture()
        self.verify()
        for label, value in (
                ("missing", None), ("malformed", "not-a-timestamp"),
                ("stale", utc_stamp(start - 3600)),
                ("future", utc_stamp(start + 86400))):
            with self.subTest(timestamp=label):
                if value is None:
                    self.verification.pop("timestampUtc", None)
                else:
                    self.verification["timestampUtc"] = value
                self.write_fixture()
                with self.assertRaisesRegex(AssertionError, "timestamp"):
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

    def test_rejects_fixture_only_experiment_evidence(self):
        # The manifest is refreshed for each marker: rejection must be based
        # on provenance, not a stale digest or inconsistent numerical data.
        self.verify()
        self.experiments["fixtureOnly"] = False
        self.write_fixture()
        self.verify()
        for marker in (True, None, 0, 1, "false", [], {}):
            with self.subTest(marker=marker):
                self.experiments["fixtureOnly"] = marker
                self.write_fixture()
                with self.assertRaisesRegex(AssertionError, "[Ff]ixture-only"):
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

    def test_rejects_omitted_overlap_and_stiffness_regressions_with_same_totals(self):
        # Independently named parameterized cases support the bounded CTRL,
        # FAULT and NUM evidence. Replacing any one with an unrelated passing
        # test must not preserve scientific acceptance just by keeping counts.
        required_cases = [
            ("TestAuditRegressions",
             "overlappingFaultsRespectControllerClock(controllerMode=baseline)"),
            ("TestAuditRegressions",
             "overlappingFaultsRespectControllerClock(controllerMode=advanced)"),
            ("TestAnisotropicThermalGraph",
             "toleranceSweepConvergesAcrossStiffness(solver=ode45,scenario=mild)"),
            ("TestAnisotropicThermalGraph",
             "toleranceSweepConvergesAcrossStiffness(solver=ode45,scenario=moderate)"),
            ("TestAnisotropicThermalGraph",
             "toleranceSweepConvergesAcrossStiffness(solver=ode45,scenario=stiff)"),
            ("TestAnisotropicThermalGraph",
             "toleranceSweepConvergesAcrossStiffness(solver=ode15s,scenario=mild)"),
            ("TestAnisotropicThermalGraph",
             "toleranceSweepConvergesAcrossStiffness(solver=ode15s,scenario=moderate)"),
            ("TestAnisotropicThermalGraph",
             "toleranceSweepConvergesAcrossStiffness(solver=ode15s,scenario=stiff)"),
        ]
        path = self.root / "results/test-results.xml"
        original = path.read_bytes()
        for classname, name in required_cases:
            with self.subTest(classname=classname, name=name):
                junit = ET.fromstring(original)
                case = next(case for case in junit.iter("testcase")
                            if (case.get("classname"), case.get("name"))
                            == (classname, name))
                case.set("name", "unrelatedPassingScientificTest")
                path.write_bytes(ET.tostring(junit, encoding="utf-8"))
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

    def test_licensed_candidate_requires_numerical_e9(self):
        # Opt-in candidate qualification must not accept ordinary hosted
        # missing-product receipts. These fixtures are software tests only.
        with mock.patch.dict(os.environ, {"REQUIRE_LICENSED_E9": "1"}):
            with self.assertRaisesRegex(AssertionError, "(?i)E9|Simscape|licensed"):
                self.verify()

        def trace():
            return {
                "time_s": list(range(601)),
                "temperature_K": [[298.15] * 12 for _ in range(601)],
                "soc": [[0.8] * 12 for _ in range(601)],
                "energyLedger": {
                    "generatedHeat_J": 10.0, "ambientHeat_J": -4.0,
                    "coolantHeat_J": -6.0, "externalHeat_J": 0.0,
                    "storedEnergyChange_J": 0.0, "normalizedResidual": 0.0},
            }

        row = self.experiments["records"][9]
        row["status"] = "PASS"
        self.verification.update(simscapeAdapterStatus="PASS", passed=58, incomplete=0)
        receipt = {
            "schemaVersion": "thermoweave.e9-parity/v1",
            "gitCommit": self.expected_sha, "matlabRelease": "2024a",
            "modelSha256": "18ad387d658f52930209938881d50ad724a4e7038b8e756b094a82df1812adda",
            "baseline": {"maxStep_s": 0.25, "core": trace(), "simscape": trace()},
            "refined": {"maxStep_s": 0.125, "core": trace(), "simscape": trace()},
        }

        def complete_fixture():
            self.write_fixture()
            path = self.root / "results/test-results.xml"
            junit = ET.parse(path)
            suite = junit.getroot().find("./testsuite[@name='TestSimulationIntegration']")
            case = suite.find("testcase")
            case.remove(case.find("skipped"))
            suite.set("skipped", "0")
            junit.write(path, encoding="utf-8")

        with mock.patch.dict(os.environ, {"REQUIRE_LICENSED_E9": "1"}):
            for defect in ("missing", "source", "temperature", "refinement"):
                with self.subTest(defect=defect):
                    row["evidence"] = {"adapterStatus": "PASS",
                                       "numericalParity": copy.deepcopy(receipt)}
                    value = row["evidence"]["numericalParity"]
                    if defect == "missing":
                        del row["evidence"]["numericalParity"]
                    elif defect == "source":
                        value["gitCommit"] = "b" * 40
                    elif defect == "temperature":
                        value["baseline"]["simscape"]["temperature_K"][300][0] += 0.11
                    elif defect == "refinement":
                        for solver in ("core", "simscape"):
                            value["refined"][solver]["temperature_K"][300][0] += 0.06
                    complete_fixture()
                    with self.assertRaisesRegex(AssertionError, "(?i)E9|parity"):
                        self.verify()
            row["evidence"] = {"adapterStatus": "PASS", "numericalParity": receipt}
            complete_fixture()
            self.verify()
            # A matching parity receipt cannot hide incomplete licensed QP.
            self.verification.update(passed=57, incomplete=1)
            self.write_fixture()
            with self.assertRaisesRegex(AssertionError, "(?i)licensed|incomplete|QP"):
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


    def test_licensed_candidate_workflow_is_separate_and_nonpublishing(self):
        # Existing manual workflow is already on main, so its candidate
        # mode can be reviewed and run on a branch without merging first.
        # This is a static contract, not a license or runner authorization.
        workflow = (HERE / ".github/workflows/simscape-integration.yml").read_text(
            encoding="utf-8")
        self.assertRegex(workflow, r"(?m)^      candidate_evidence:$")
        self.assertRegex(workflow, r"(?m)^      expected_candidate_sha:$")
        self.assertRegex(workflow, r"(?m)^  candidate:$")
        existing, candidate = workflow.split("\n  candidate:\n", 1)
        self.assertRegex(existing, r"(?m)^    if:.*!inputs\.candidate_evidence")
        self.assertRegex(candidate, r"(?m)^    if:.*inputs\.candidate_evidence.*!inputs\.pages_evidence")
        self.assertRegex(candidate, r"(?m)^    environment: thermoweave-licensed-candidate$")
        self.assertIn("runs-on: [self-hosted, thermoweave-simscape]", candidate)
        self.assertIn("persist-credentials: false", candidate)
        self.assertIn("inputs.expected_candidate_sha", candidate)
        self.assertIn('test "$GITHUB_REF" != refs/heads/main', candidate)
        self.assertIn('test "$(git rev-parse HEAD)" = "$EXPECTED_SOURCE_SHA"', candidate)
        self.assertIn("tasks: artifacts", candidate)
        self.assertIn("REQUIRE_LICENSED_E9: '1'", candidate)
        self.assertIn("python3 scripts/verify_scientific_artifacts.py", candidate)
        self.assertIn("name: thermoweave-licensed-candidate-evidence", candidate)
        self.assertIn("if-no-files-found: error", candidate)
        for forbidden in ("pages: write", "contents: write", "id-token: write",
                          "deploy-pages@", "release/thermoweave-source.zip",
                          "release/release-manifest.json", "tasks: package"):
            self.assertNotIn(forbidden, candidate)
        # Do not upload local licensed model or library declaration.
        for forbidden in ("simscape/models/", ".satk/"):
            upload = candidate.split("uses: actions/upload-artifact@", 1)[1]
            self.assertNotIn(forbidden, upload)


    def test_legacy_licensed_job_requires_main_and_approval_before_runner(self):
        # A job-level guard is required before a licensed self-hosted runner
        # is assigned. A Pages-only check inside the job cannot protect the
        # ordinary integration mode. Environment protection and runner-group
        # access controls must additionally be established outside this test.
        workflow = (HERE / ".github/workflows/simscape-integration.yml").read_text(
            encoding="utf-8")
        legacy = workflow.split("\n  integration:\n", 1)[1].split(
            "\n  candidate:\n", 1)[0]
        header = legacy.split("\n    steps:\n", 1)[0]
        self.assertRegex(
            header, r"(?m)^    if:.*!inputs\.candidate_evidence.*github\.ref\s*==\s*'refs/heads/main'",
            "Legacy licensed execution must be restricted to main before runner assignment")
        self.assertRegex(header, r"(?m)^    environment: thermoweave-licensed-main$")
        self.assertIn("needs: validate-inputs", header)
        self.assertIn("runs-on: [self-hosted, thermoweave-simscape]", header)


    def test_main_licensed_staging_is_fail_closed(self):
        # Run the actual main staging Python against disposable placeholder
        # files. Never access a licensed model, library or runner in this test.
        import subprocess
        import sys
        import textwrap

        workflow = (HERE / ".github/workflows/simscape-integration.yml").read_text(
            encoding="utf-8")
        legacy = workflow.split("\n  integration:\n", 1)[1].split(
            "\n  candidate:\n", 1)[0]
        step = legacy.split("name: Stage the locally approved E9 model and library declaration", 1)[1]
        script = textwrap.dedent(step.split("python3 - <<'PY'\n", 1)[1].split("\n          PY", 1)[0])
        names = (".satk/reuse-libraries.json",
                 "simscape/models/ThermoWeaveE9Candidate.slx",
                 "simscape/models/thermoweave-model-manifest.json")
        for defect in ("none", "existing-target", "external-source", "missing-last"):
            with self.subTest(defect=defect):
                sandbox = self.root / defect
                source = sandbox / "source"
                checkout = sandbox / "checkout"
                checkout.mkdir(parents=True)
                for name in names:
                    path = source / name
                    path.parent.mkdir(parents=True, exist_ok=True)
                    path.write_bytes(b"placeholder only")
                if defect == "existing-target":
                    target = checkout / names[1]
                    target.parent.mkdir(parents=True)
                    target.write_bytes(b"preserve existing bytes")
                elif defect == "external-source":
                    outside = sandbox / "outside.txt"
                    outside.write_bytes(b"outside approved root")
                    path = source / names[1]
                    path.unlink()
                    path.symlink_to(outside)
                elif defect == "missing-last":
                    (source / names[2]).unlink()
                result = subprocess.run(
                    [sys.executable, "-c", script], cwd=checkout,
                    env={**os.environ, "THERMOWEAVE_LICENSED_INPUT_ROOT": str(source)},
                    capture_output=True, text=True, check=False)
                marker = checkout / "results/artifact-regeneration-start.flag"
                if defect == "none":
                    self.assertEqual(result.returncode, 0, result.stderr)
                    self.assertTrue(marker.is_file())
                    for name in names:
                        self.assertEqual((checkout / name).read_bytes(), b"placeholder only")
                else:
                    self.assertNotEqual(result.returncode, 0,
                                        "Unsafe main licensed staging was accepted")
                    self.assertFalse(marker.exists())
                    for name in names:
                        target = checkout / name
                        if defect == "existing-target" and name == names[1]:
                            self.assertEqual(target.read_bytes(), b"preserve existing bytes")
                        else:
                            self.assertFalse(target.exists(),
                                             "Failed staging left local inputs behind")

    def test_main_licensed_staging_has_unconditional_cleanup(self):
        # Successful staging must be cleaned up even when the native build
        # or parity verifier fails, before any evidence upload.
        workflow = (HERE / ".github/workflows/simscape-integration.yml").read_text(
            encoding="utf-8")
        legacy = workflow.split("\n  integration:\n", 1)[1].split(
            "\n  candidate:\n", 1)[0]
        before_upload = legacy.split("uses: actions/upload-artifact@", 1)[0]
        self.assertRegex(before_upload, r"(?m)^      - name: Remove staged local licensed inputs$")
        cleanup = before_upload.split("name: Remove staged local licensed inputs", 1)[1]
        self.assertRegex(cleanup, r"(?m)^        if:.*always\(\).*steps\.stage\.outcome.*success")
        for name in (".satk/reuse-libraries.json",
                     "simscape/models/ThermoWeaveE9Candidate.slx",
                     "simscape/models/thermoweave-model-manifest.json"):
            self.assertIn(name, cleanup)




    def test_candidate_marker_is_created_transactionally(self):
        # Run the entire staging shell step, including marker creation, on
        # disposable placeholders. A failed step cannot rely on later cleanup
        # conditioned on stage success; it must roll back its own inputs.
        import subprocess
        import textwrap

        workflow = (HERE / ".github/workflows/simscape-integration.yml").read_text(
            encoding="utf-8")
        candidate = workflow.split("\n  candidate:\n", 1)[1]
        step = candidate.split("name: Stage approved inputs without overwriting existing files", 1)[1]
        script = textwrap.dedent(step.split("        run: |\n", 1)[1].split(
            "\n      - name:", 1)[0])
        names = (".satk/reuse-libraries.json",
                 "simscape/models/ThermoWeaveE9Candidate.slx",
                 "simscape/models/thermoweave-model-manifest.json")
        for defect in ("none", "stale-marker", "linked-marker", "blocked-parent"):
            with self.subTest(defect=defect):
                sandbox = self.root / ("candidate-" + defect)
                source = sandbox / "source"
                checkout = sandbox / "checkout"
                checkout.mkdir(parents=True)
                for name in names:
                    path = source / name
                    path.parent.mkdir(parents=True, exist_ok=True)
                    path.write_bytes(b"placeholder only")
                marker = checkout / "results/artifact-regeneration-start.flag"
                outside = sandbox / "outside.txt"
                outside.write_bytes(b"outside approved checkout")
                before = outside.stat().st_mtime_ns
                if defect == "stale-marker":
                    marker.parent.mkdir()
                    marker.write_bytes(b"old receipt")
                    os.utime(marker, ns=(1000000000, 1000000000))
                elif defect == "linked-marker":
                    marker.parent.mkdir()
                    marker.symlink_to(outside)
                elif defect == "blocked-parent":
                    marker.parent.write_bytes(b"preserve parent file")
                result = subprocess.run(
                    ["bash", "-c", script], cwd=checkout,
                    env={**os.environ, "THERMOWEAVE_LICENSED_INPUT_ROOT": str(source)},
                    capture_output=True, text=True, check=False)
                if defect == "none":
                    self.assertEqual(result.returncode, 0, result.stderr)
                    self.assertTrue(marker.is_file())
                    for name in names:
                        self.assertEqual((checkout / name).read_bytes(), b"placeholder only")
                else:
                    self.assertNotEqual(result.returncode, 0,
                                        "Unsafe candidate marker accepted")
                    for name in names:
                        self.assertFalse((checkout / name).exists(),
                                         "Failed candidate staging left local inputs behind")
                    if defect == "stale-marker":
                        self.assertEqual(marker.read_bytes(), b"old receipt")
                        self.assertEqual(marker.stat().st_mtime_ns, 1000000000)
                    elif defect == "linked-marker":
                        self.assertTrue(marker.is_symlink())
                        self.assertEqual(outside.read_bytes(), b"outside approved checkout")
                        self.assertEqual(outside.stat().st_mtime_ns, before)
                    elif defect == "blocked-parent":
                        self.assertEqual(marker.parent.read_bytes(), b"preserve parent file")


if __name__ == "__main__":
    unittest.main()
