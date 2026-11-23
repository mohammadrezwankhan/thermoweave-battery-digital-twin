"""Validate fresh R2024a ThermoWeave artifacts without masking scientific failures."""
import csv
import hashlib
import json
import math
import os
from pathlib import Path
import re
import sys
import xml.etree.ElementTree as ET


def _reject_nonfinite(value):
    raise ValueError("Non-finite JSON number: " + value)


def _finite_number(value):
    return type(value) in (int, float) and math.isfinite(value)


# A correct aggregate count is not proof that the intended scientific
# regressions actually ran. Require these named cases as well as green totals.
# These are synthetic/model/provenance tests, NOT licensed Simscape or
# real-cell validation.
REQUIRED_SCIENTIFIC_TESTS = frozenset({
    ("TestScientificAuditGates", "downsampledControlHistoriesAlignWithTimeVector"),
    ("TestAuditRegressions", "downsampleExportRetainsTerminalStateAndMatchingTimebase"),
    ("TestScientificAuditGates", "controllerExecutionIdentityIsRecorded"),
    ("TestScientificAuditGates", "faultBetweenOutputTimesHasExactHeatDuration"),
    ("TestIndependentEnergyAcceptance", "forgedLegacyZeroCannotHideIncorrectHeat"),
    ("Test3DStudy", "canonicalResultHasThreeDimensionalState"),
    ("TestSimscapeModelProvenance", "modifiedModelBytesFailClosed"),
    ("TestIndependentEnergyAcceptance", "coolantEnergyResidualConvergesUnderRefinement"),
    ("TestScientificAuditGates", "advancedExecutionMetadataCannotClaimUnexecutedQP"),
    # Prove the optional licensed QP test was run or explicitly skipped;
    # it must not disappear from an otherwise green synthetic test inventory.
    ("TestSimulationIntegration", "advancedControllerCoolsHotZonesAndHonorsRate"),
})


def _is_v2_digest(value):
    return isinstance(value, str) and re.fullmatch(r"[0-9a-f]{64}", value) is not None


def _verify_scenario_hash_v2(data):
    manifest = data["manifest"]
    algorithm = "scenarioCanonicalHashV2Algorithm"
    if algorithm not in manifest and os.environ.get("REQUIRE_SCENARIO_HASH_V2") != "1":
        return
    if manifest.get(algorithm) != "thermoweave.canonical-json/v2":
        raise AssertionError("Missing or unrecognized scenario hash v2 algorithm")

    digest_key = "scenarioCanonicalHashV2"
    records = data["experiments"]["records"]
    study = data["study"]
    standalone = [
        ("website " + scenario["id"], scenario.get(digest_key))
        for scenario in data["web"]["scenarios"]
    ] + [
        ("verification demo", data["verification"].get("demo", {}).get(digest_key)),
        ("E10 source", study.get("sourceScenarioCanonicalHashV2")),
    ] + [
        ("E10 " + case["caseId"], case.get(digest_key)) for case in study["cases"]
    ] + [
        (records[i]["id"], records[i].get("metrics", {}).get(digest_key))
        for i in (0, 1, 2, 3, 5, 6, 7)
    ]
    for label, digest in standalone:
        if not _is_v2_digest(digest):
            raise AssertionError("Invalid scenario hash v2 for " + label)
    # The three E10 conductances are distinct and therefore cannot
    # legitimately share an identical typed canonical scenario digest.
    # Reject a copied-but-well-formed digest rather than accepting its shape.
    e10_digests = [case[digest_key] for case in study["cases"]]
    if len(set(e10_digests)) != len(e10_digests):
        raise AssertionError("Duplicate E10 scenario hash v2 across distinct conductances")

    e4 = records[4]["evidence"]
    e8 = records[8]["evidence"]
    seeds = e4.get("seeds")
    for label, evidence, size in (
            ("E4", e4, len(seeds) if isinstance(seeds, list) else 0),
            ("E8", e8, e8.get("runCount"))):
        digests = evidence.get("scenarioCanonicalHashesV2")
        if (type(size) is not int or size < 1 or not isinstance(digests, list)
                or len(digests) != size or not all(map(_is_v2_digest, digests))
                or len(set(digests)) != size):
            raise AssertionError("Invalid seeded scenario hashes v2 for " + label)

    e7 = records[7]
    controllers = e7["evidence"].get("controllerScenarioCanonicalHashesV2")
    if (not isinstance(controllers, dict)
            or set(controllers) != {"openloop", "baseline", "advanced"}
            or not all(map(_is_v2_digest, controllers.values()))
            or len(set(controllers.values())) != 3):
        raise AssertionError("Invalid E7 controller scenario hashes v2")
    if controllers["baseline"] != e7["metrics"][digest_key]:
        raise AssertionError("E7 baseline scenario hash v2 mismatch")


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
    ids = [s.get("id") for s in scenarios]
    if (any(not isinstance(identifier, str) or not identifier.strip()
            for identifier in ids) or len(set(ids)) != len(ids)):
        raise AssertionError("Website scenario IDs missing or duplicate")
    if any(s.get("sourceSchema") != "thermoweave.result/v1"
           or not s.get("scenarioHash") for s in scenarios):
        raise AssertionError("Website scenario schema/hash invalid")
    for scenario in scenarios:
        times = scenario.get("time_s")
        if (not isinstance(times, list) or len(times) < 2
                or not all(_finite_number(t) for t in times)
                or any(right <= left for left, right in zip(times, times[1:]))):
            raise AssertionError("Invalid website time grid for " + str(scenario.get("id")))
        # Matching the time-axis length alone can conceal a dropped cell or
        # actuator in one downsampled record. Temperature and boundary vectors
        # refer to the same physical cells; zone commands have their own fixed
        # width and must remain consistent across samples.
        cell_width = None
        for field in ("temperature_C", "boundaryTemperature_C", "zoneCommand"):
            series = scenario.get(field)
            if (not isinstance(series, list) or len(series) != len(times)
                    or any(not isinstance(row, list) or len(row) == 0
                           or not all(_finite_number(value) for value in row)
                           for row in series)):
                raise AssertionError("Unaligned/nonfinite website field " + field)
            width = len(series[0])
            if any(len(row) != width for row in series):
                raise AssertionError("website " + field + " width changes over time")
            if field == "temperature_C":
                cell_width = width
                # All five current website demonstrations are the declared
                # 3x4 (12-cell) model. A uniformly cropped history would pass
                # the ordinary time-alignment and constant-width checks.
                if cell_width != 12:
                    raise AssertionError("website must retain 12 cell temperatures")
            elif field == "boundaryTemperature_C" and width != cell_width:
                raise AssertionError("website boundaryTemperature_C width differs from cells")
            elif field == "zoneCommand" and width != 4:
                # The site exposes four actuator zones in every scenario.
                # Cropping every command row to three zones is still data loss.
                raise AssertionError("website must retain 4 zone commands")
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
    # The hosted license-free runner may report only missing products, not a
    # model/policy/adapter defect disguised as an arbitrary SKIPPED_* success.
    # A PASS here is just a consistency statement; licensed model parity and
    # independent approval remain separate mandatory release gates.
    if e9 not in ("PASS", "SKIPPED_MISSING_PRODUCT"):
        raise AssertionError("Simscape E9 status is not an approved execution/skip result")
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
        # docs/scenarios.md defines a <=1e-3 normalized energy-residual
        # acceptance gate for E10. Merely requiring finiteness could permit
        # a physically unacceptable study to be published as verified.
        energy_residual = case["energyResidualNormalized"]
        if not 0 <= energy_residual <= 1e-3:
            raise AssertionError(
                "E10 energy residual outside declared [0, 1e-3] limit")
        if not math.isclose(max(layers) - min(layers),
                            case["finalLayerSpread_K"], rel_tol=1e-7, abs_tol=1e-8):
            raise AssertionError("E10 final layer-spread contradicts layer temperatures")
    # E10's published CSV is a separate numerical artifact. A correct JSON
    # report must not mask a stale, missing or contradictory research table.
    csv_rel = "artifacts/data/3d-study-results.csv"
    if study.get("artifacts", {}).get("table", csv_rel) != csv_rel:
        raise AssertionError("E10 CSV table path disagrees with study metadata")
    csv_path = root / csv_rel
    if not csv_path.is_file():
        raise AssertionError("E10 CSV missing from regenerated evidence")
    if csv_path.stat().st_mtime + 0.001 < marker.stat().st_mtime:
        raise AssertionError("E10 CSV predates artifact regeneration")
    columns = ["caseId", "gz_W_per_K", "nodeCount", "edgeCount",
               "peakTemperature_K", "peakEdgeGradient_K",
               "finalLayerSpread_K", "energyResidualNormalized",
               "scenarioHash"]
    numeric_columns = [name for name in columns
                       if name not in ("caseId", "scenarioHash")]
    try:
        with csv_path.open("r", encoding="utf-8-sig", newline="") as stream:
            reader = csv.DictReader(stream, strict=True)
            if reader.fieldnames != columns:
                raise AssertionError("E10 CSV columns differ from study schema")
            csv_rows = list(reader)
        if len(csv_rows) != len(cases):
            raise AssertionError("E10 CSV row count disagrees with JSON study")
        for row, case in zip(csv_rows, cases):
            for key in ("caseId", "scenarioHash"):
                if row.get(key) != case.get(key):
                    raise AssertionError("E10 CSV case identity/hash disagrees with JSON")
            for key in numeric_columns:
                value = float(row[key])
                expected = float(case[key])
                if (not math.isfinite(value)
                        or not math.isclose(value, expected, rel_tol=1e-10,
                                            abs_tol=1e-10)):
                    raise AssertionError("E10 CSV scientific measurement disagrees with JSON: " + key)
    except (ValueError, TypeError, OverflowError, csv.Error) as error:
        raise AssertionError("E10 CSV has malformed scientific values") from error

    verification = data["verification"]
    # E9 is reported independently by the experiment, adapter evidence, and
    # regenerated MATLAB verification report. None can silently overrule a
    # missing-product skip or forge a licensed execution claim.
    e9_evidence = rows[9].get("evidence")
    if (not isinstance(e9_evidence, dict)
            or e9_evidence.get("adapterStatus") != e9
            or verification.get("simscapeAdapterStatus") != e9):
        raise AssertionError(
            "Simscape E9 experiment, adapter and verification statuses disagree")
    expected_source_sha = os.environ.get("EXPECTED_SOURCE_SHA", "").strip().lower()
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
    # The independent MATLAB JUnit report is the executable test inventory.
    # Reject forged JSON success totals, omitted testcases, duplicate names,
    # unexpected assumption skips and error/failure markers. A green build
    # badge alone does not establish these test assertions.
    junit_file = root / "results/test-results.xml"
    if not junit_file.is_file():
        raise AssertionError("JUnit receipt missing from this MATLAB run")
    if junit_file.stat().st_mtime + 0.001 < marker.stat().st_mtime:
        raise AssertionError("JUnit receipt predates artifact regeneration")
    try:
        junit = ET.parse(junit_file).getroot()
    except ET.ParseError as exception:
        raise AssertionError("JUnit receipt is malformed XML") from exception
    if junit.tag != "testsuites":
        raise AssertionError("JUnit root must be testsuites")
    suites = junit.findall("testsuite")
    if not suites:
        raise AssertionError("JUnit receipt contains no test suites")
    junit_count = 0
    junit_failed = 0
    junit_incomplete = 0
    seen_test_ids = set()
    optional_skips = {
        ("TestSimulationIntegration", "advancedControllerCoolsHotZonesAndHonorsRate"),
    }
    for suite in suites:
        cases = suite.findall("testcase")
        suite_skipped = 0
        suite_failed = 0
        suite_errors = 0
        for case in cases:
            identity = (case.get("classname"), case.get("name"))
            if not all(identity) or identity in seen_test_ids:
                raise AssertionError("JUnit has missing or duplicate test identity")
            seen_test_ids.add(identity)
            skipped = case.find("skipped") is not None
            failed = case.find("failure") is not None
            errored = case.find("error") is not None
            if sum((skipped, failed, errored)) > 1:
                raise AssertionError("JUnit testcase contains conflicting outcomes")
            if skipped and identity not in optional_skips:
                raise AssertionError("JUnit has an unapproved incomplete test: "
                                     + "/".join(identity))
            if skipped and identity in optional_skips:
                # This is the sole approved optional licensed regression. A
                # numerical/physics assumption failure must not masquerade as
                # missing Optimization Toolbox just because its test ID matches.
                skip_record = case.find("skipped")
                diagnostic = " ".join((
                    skip_record.get("message", ""), skip_record.text or ""
                )).lower()
                if "optimization toolbox unavailable" not in diagnostic:
                    raise AssertionError(
                        "QP skip reason must identify unavailable Optimization Toolbox")
            suite_skipped += int(skipped)
            suite_failed += int(failed)
            suite_errors += int(errored)
        expected_suite = {
            "tests": len(cases), "skipped": suite_skipped,
            "failures": suite_failed, "errors": suite_errors,
        }
        for key, actual in expected_suite.items():
            if suite.get(key) != str(actual):
                raise AssertionError("JUnit suite summary disagrees with testcases: "
                                     + str(suite.get("name")) + "/" + key)
        junit_count += len(cases)
        junit_incomplete += suite_skipped
        junit_failed += suite_failed + suite_errors
    junit_counts = (junit_count, junit_count - junit_failed - junit_incomplete,
                    junit_failed, junit_incomplete)
    if tuple(counts) != junit_counts:
        raise AssertionError("JUnit summary disagrees with MATLAB verification JSON: "
                             + str(junit_counts) + " vs " + str(tuple(counts)))
    missing_required = REQUIRED_SCIENTIFIC_TESTS - seen_test_ids
    if missing_required:
        missing_names = ", ".join(
            f"{class_name}/{case_name}"
            for class_name, case_name in sorted(missing_required))
        raise AssertionError("JUnit missing required scientific regression: " + missing_names)
    if verification.get("testCount", 0) < 51:
        raise AssertionError("Missing the audited MATLAB regression inventory")
    if verification.get("codeAnalyzerFindings") != 0:
        raise AssertionError("MATLAB Code Analyzer findings remain; inspect SARIF")
    # The analyzer's SARIF is an independent receipt, not just a reported
    # count in verification.json. A missing/stale/malformed report or any
    # diagnostic must fail evidence acceptance, even if the JSON says zero.
    sarif_path = root / "results/code-issues.sarif"
    if not sarif_path.is_file():
        raise AssertionError("Code Analyzer SARIF receipt missing")
    if sarif_path.stat().st_mtime + 0.001 < marker.stat().st_mtime:
        raise AssertionError("Code Analyzer SARIF receipt predates regeneration")
    try:
        sarif = json.loads(sarif_path.read_text(encoding="utf-8"),
                           parse_constant=_reject_nonfinite)
    except (json.JSONDecodeError, ValueError) as exception:
        raise AssertionError("Code Analyzer SARIF receipt malformed") from exception
    runs = sarif.get("runs") if isinstance(sarif, dict) else None
    if (sarif.get("version") != "2.1.0" or not isinstance(runs, list)
            or len(runs) != 1 or not isinstance(runs[0], dict)
            or runs[0].get("tool", {}).get("driver", {}).get("name")
                != "Code Analyzer"):
        raise AssertionError("Code Analyzer SARIF run missing or unrecognized")
    findings = runs[0].get("results")
    if not isinstance(findings, list) or findings:
        raise AssertionError("Code Analyzer SARIF findings contradict zero warnings")
    _verify_scenario_hash_v2(data)
    print("PASS: fresh versioned MATLAB artifacts, sources, digests and checks")
    print("Optional licensed Simscape and field-cell validation remain separate gates")


if __name__ == "__main__":
    try:
        verify()
    except (AssertionError, ValueError, OSError, KeyError) as ex:
        print("Artifact provenance verification FAILED:", ex, file=sys.stderr)
        sys.exit(1)
