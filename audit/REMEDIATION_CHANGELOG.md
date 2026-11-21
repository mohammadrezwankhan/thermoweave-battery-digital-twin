# ThermoWeave engineering audit — remediation changelog

**Date:** 2026-11-21  
**Original source:** `main` at `6b48646da2f6f8b60a13b14e19c4c65e45b17383`  
**Branch:** `audit/thermoweave-engineering-20261121`  
**Scope:** Changes below were committed by the connected GitHub API. Source edits and test addition are **not** test execution. Current test outcomes require a candidate-head CI log.

## Implemented source changes

| Finding | Root cause and problem | Changed files | Correction | Regression test | Compatibility / verification |
|---|---|---|---|---|---|
| TW-CTRL-002 | Controller subtracted Kelvin `deadband_K` after dimensionless `Kp_per_K` scaling; units and nonzero-deadband commands were wrong | `src/+thermoweave/+control/baselineController.m`; `src/+thermoweave/+config/validateConfig.m` | Expand per-zone deadband and subtract it from Kelvin error before gain; enforce valid zone dimensions | `deadbandUsesKelvinBeforeProportionalGain` | Zero-deadband baseline unchanged; nonzero deadband now responds correctly. Targeted regression PASS in R2024a candidate CI run 44945399849 at source/test SHA 0287e46 |
| TW-CTRL-001 | Stuck-actuator fault forced `magnitude` setpoint; controller state retained unexecuted proposal | `src/+thermoweave/simulate.m` | Preserve last **executed** command during active fault; use executed state for subsequent slew/recovery | `stuckActuatorHoldsAppliedCommandWithoutSlewJump` | Event `magnitude` retains legacy metadata but is no longer a prescribed target. API remains unchanged; semantics explicitly documented. Targeted regression PASS in R2024a candidate CI run 44945399849 at source/test SHA 0287e46 |
| TW-PHY-002 | Coolant segment with zero mass flow and zero conductance divided a zero numerator by machine epsilon, yielding 0 K for an undetermined outlet | `src/+thermoweave/+coolant/evaluate.m`; `src/+thermoweave/+coolant/march.m` | Preserve previous/inlet temperature for a fully inactive segment; heat exchange remains zero | `inactiveCoolantSegmentsKeepLastDefinedTemperature` | Singular zero-transfer case only. Targeted regression PASS in R2024a candidate CI run 44945399849 at source/test SHA 0287e46 |
| TW-CFG-001 | Optional `thermal.edgeConductanceScale` and `boundary.coolant.cellConductanceScale` were never validated | `src/+thermoweave/+config/validateConfig.m` | Enforce finite nonnegative scale values with scalar/vector dimension checks | `rejectsNonphysicalInterfaceScaling` | Previously accepted nonphysical or malformed scales now fail explicitly. Targeted regression PASS in R2024a candidate CI run 44945399849 at source/test SHA 0287e46 |
| TW-DATA-001 | Downsampled exports sometimes omitted final state and retained unsampled `metadata.timeBase_s` | `src/+thermoweave/+results/exportJSON.m` | Include terminal sample; subset metadata timebase; store original sample count; reject nonintegral strides | `downsampleExportRetainsTerminalStateAndMatchingTimebase` | Only the optional stride export path changes. Full-run result schema `thermoweave.result/v1` remains. Targeted regression PASS in R2024a candidate CI run 44945399849 at source/test SHA 0287e46 |

## Independent scientific regression addition

| Finding | New test | Oracle and intent | Status |
|---|---|---|---|
| TW-PHY-001 | `independentStoredEnergyMatchesConstantHeatInput` in `tests/unit/TestAuditRegressions.m` | In an adiabatic, uncontrolled constant-resistance/constant-current case, compare independently calculated stored energy change `sum_i C_i * (T_final_i - T_initial_i)` with `N * I^2 * R0 * duration`. This does not reuse the derivative's algebraic residual. | Targeted stored-energy regression PASS on R2024a CI; does **not** repair missing general integrated energy ledger |

## Documentation and evidence updates

| Artifact | Revision |
|---|---|
| `README.md` | Core CI badge replaces stale static local-test badge; latest baseline test count is dated and source-linked; heat equation is aligned and retains all subtraction signs |
| `docs/model.md` | Deadband units, executed actuator freeze, unscheduled controller sample clock, and RHS-only residual limitations documented |
| `docs/validation.md` | 40-total/39-pass/1-incomplete R2024a baseline evidence separated from older 37/37 R2026a history; algebraic residual caveat |
| `docs/deployment.md` | Verified November 19 Pages deployment source SHA and URL separated from browser/live-site verification |
| `audit/findings.json` | Machine-readable source-anchored finding register |
| `audit/SCIENTIFIC_VERIFICATION_MATRIX.md` | Acceptance matrix with actual evidence and unresolved FAIL / NOT VERIFIED categories |
| `audit/THERMOWEAVE_FULL_TECHNICAL_AUDIT.md` | Domain-specific audit, evidence boundaries, limitations, and assurance verdict |

## Deliberately unresolved material findings

The following are **not** patched and are not disguised as remediated: `TW-PHY-001` integrated energy accounting and power-scale normalization; `TW-CTRL-003` independent controller sample clock; `TW-FAULT-001` off-output-grid event alignment; `TW-DATA-002` versioned canonical scenario hashing; optional QP execution metadata; licensed Simscape numerical parity; and independent IP/provenance clearance. Correcting these requires additional mathematical acceptance or a controlled artifact/hash migration and re-run.

## Commit/verification policy

- All edits were made on a new isolated branch from the frozen source SHA, not on protected `main`.
- No physical constants, benchmark target values, generated numerical reports, or published web-data payloads were modified to force a test pass.
- The six new tests were actually executed in source/test CI [run 44945399849](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/actions/runs/44945399849): 46 total / 45 passed / 0 failed / 1 optional incomplete.
- No 10-agent Gemini Carbon/Antigravity execution was available in the connected environment; the audit domains were reviewed in a single GitHub-connected engineering session.
- Independent source calculations are labelled separately from provider-executed test results.
- Reconcile candidate CI, diff and any test failures before promotion to protected `main`.

**Verified candidate-source MATLAB R2024a CI:** [run 44945399849](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/actions/runs/44945399849), job `136971493310`, on source/test SHA `0287e46ed273d3154e0bed9309a318a809702683`: **46 total, 45 PASSED, 0 FAILED, 1 INCOMPLETE** (optional advanced-controller test filtered by unmet Optimization Toolbox assumption). Code Analyzer reports 0 errors and 0 warnings. The six new regression methods executed in this passing run; unrun scientific acceptance gates remain unverified. The report-update commit follows this receipt and must itself be checked at its final SHA.
