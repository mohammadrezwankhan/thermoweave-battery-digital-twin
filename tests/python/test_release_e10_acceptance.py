"""Adversarial release-time E10 tests; synthetic fixtures, no MATLAB license."""
import csv
from pathlib import Path
import unittest

import test_verify_release_readiness as fixtures


COLUMNS = ("caseId", "gz_W_per_K", "nodeCount", "edgeCount",
           "peakTemperature_K", "peakEdgeGradient_K",
           "finalLayerSpread_K", "energyResidualNormalized", "scenarioHash")


class E10ReleaseScientificIntegrityTests(unittest.TestCase):
    def setUp(self):
        self.fixture = fixtures.ReleaseReadinessTests(
            "test_happy_fixture_does_not_claim_real_cell_validation")
        self.fixture.setUp()
        self.addCleanup(self.fixture.doCleanups)
        self.root = self.fixture.root
        self.study = self.fixture.study
        for case, g in zip(self.study["cases"], (0.1, 0.25, 0.75)):
            case.update({
                "gz_W_per_K": g,
                "scenarioHash": "a" * 64,
                "peakTemperature_K": 303.0,
                "peakEdgeGradient_K": 2.0,
                "finalLayerMeanTemperature_K": [300.0, 301.0, 302.0],
                "finalLayerSpread_K": 2.0,
                "energyResidualNormalized": 1e-12,
            })
        self.study["artifacts"] = {"table": "artifacts/data/3d-study-results.csv"}
        self.write_study_and_csv()

    def write_study_and_csv(self):
        self.fixture.write_json("artifacts/reports/3d-study-summary.json", self.study)
        target = self.root / "artifacts/data/3d-study-results.csv"
        target.parent.mkdir(parents=True, exist_ok=True)
        with target.open("w", encoding="utf-8", newline="") as stream:
            writer = csv.DictWriter(stream, fieldnames=COLUMNS)
            writer.writeheader()
            writer.writerows({k: case[k] for k in COLUMNS} for case in self.study["cases"])

    def assert_rejected(self):
        with self.assertRaises((AssertionError, ValueError, TypeError, OSError)):
            fixtures.release.verify_release_readiness(self.root, self.fixture.SHA)

    def test_control_valid_synthetic_bundle_passes_mechanical_veto(self):
        fixtures.release.verify_release_readiness(self.root, self.fixture.SHA)

    def test_rejects_e10_residual_above_documented_limit(self):
        self.study["cases"][0]["energyResidualNormalized"] = 0.2
        self.write_study_and_csv()
        self.assert_rejected()

    def test_rejects_negative_e10_absolute_residual(self):
        self.study["cases"][1]["energyResidualNormalized"] = -0.001
        self.write_study_and_csv()
        self.assert_rejected()

    def test_rejects_e10_layer_spread_inconsistent_with_layer_means(self):
        self.study["cases"][2]["finalLayerSpread_K"] = 0.1
        self.write_study_and_csv()
        self.assert_rejected()

    def test_rejects_physically_contradictory_e10_measurements(self):
        case = self.study["cases"][0]
        original = dict(case)
        mutations = {
            "peak below layer mean": {"peakTemperature_K": 301.0},
            "negative edge gradient": {"peakEdgeGradient_K": -0.01},
            "nonpositive absolute layer temperature": {
                "finalLayerMeanTemperature_K": [-1.0, 301.0, 302.0],
                "finalLayerSpread_K": 303.0,
            },
        }
        for description, changes in mutations.items():
            with self.subTest(description=description):
                case.clear()
                case.update(original)
                case.update(changes)
                self.write_study_and_csv()
                self.assert_rejected()
        case.clear()
        case.update(original)
        self.write_study_and_csv()
        fixtures.release.verify_release_readiness(self.root, self.fixture.SHA)

    def test_rejects_stale_e10_csv_even_when_json_is_valid(self):
        target = self.root / "artifacts/data/3d-study-results.csv"
        contents = target.read_text(encoding="utf-8")
        target.write_text(contents.replace("303.0", "333.0", 1), encoding="utf-8")
        self.assert_rejected()

    def test_rejects_missing_published_e10_csv(self):
        (self.root / "artifacts/data/3d-study-results.csv").unlink()
        self.assert_rejected()


if __name__ == "__main__":
    unittest.main()
