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

## Second engineering remediation batch (21 November 2026)

| Scientific issue | Candidate change | Focused independent evidence | Remaining qualification |
|---|---|---|---|
| TW-CTRL-003 | Independent `controller.samplePeriod_s` scheduler and zero-order hold across merged simulation mesh | `controlClockDoesNotFollowOutputSpacing` | Asynchronous mixed sensor/actuator fault envelope not exhaustive |
| TW-FAULT-001 | Split solver integration at declared thermal fault transitions; sample physical fault state one-sided within each interval | `faultBetweenOutputTimesHasExactHeatDuration` | Compound and stiff transient event convergence unverified |
| TW-PHY-001 | Integrate signed generated, ambient, coolant and external power over accepted ODE states and compare with independently calculated stored-energy change | `signedIntegratedLedgerMatchesIndependentAdiabaticCase`, `signedBoundaryEnergyShowsNetCooling`, `signedCoolantEnergyShowsNetCooling` | Dynamic coolant model form, tolerance convergence, physical calibration and artifacts unverified |
| TW-DATA-002 | Add separate `thermoweave.canonical-json/v1` recursive stable-field hash, preserving legacy `scenarioHash` | `canonicalHashIgnoresObjectFieldInsertionOrder` | Cross-release reproducibility and controlled public artifact migration unverified |
| QP execution provenance | Add per-result `methodHistory`, `objectiveHistory`, `statusHistory` and distinguish actual fallback | `controllerExecutionIdentityIsRecorded`, `advancedExecutionMetadataCannotClaimUnexecutedQP` | Successful licensed QP branch unexecuted on current runner |

**Verified code/test SHA:** `a4d424d971fe14d59df6a9e3a9339cca4a437598`, [MATLAB R2024a Core CI run 44959047806](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/actions/runs/44959047806), job `137013536188`: **54 total, 53 PASS, 0 FAIL, 1 INCOMPLETE**. [Human-authorship policy run 44959047829](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/actions/runs/44959047829) passed at the same SHA. The one incomplete test is an Optimization Toolbox-dependent QP case, **not** an acceptance PASS.

No physical parameter, legacy result/v1 scenario hash, reference numerical artifact, protective CI rule, protected-main branch, or proprietary-license state was modified to force a pass. The independent scientific gate matrix remains **INCOMPLETE**.

## Deliberately unresolved material findings

The previously missing integrated signed energy ledger, independent controller clock, off-output-grid thermal fault integration and versioned nested canonical hash **now have scoped implementations and passing R2024a tests**. They are not declared system-wide scientific PASS: tolerance/stiffness and dynamic coolant validation, artifact/hash migration, licensed QP success, authorized Simscape parity and independent IP/provenance clearance remain outstanding. The existing optional incomplete QP check is not a pass.

## Commit/verification policy

- All edits were made on a new isolated branch from the frozen source SHA, not on protected `main`.
- No physical constants, benchmark target values, generated numerical reports, or published web-data payloads were modified to force a test pass.
- The six new tests were actually executed in source/test CI [run 44945399849](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/actions/runs/44945399849): 46 total / 45 passed / 0 failed / 1 optional incomplete.
- No 10-agent Gemini Carbon/Antigravity execution was available in the connected environment; the audit domains were reviewed in a single GitHub-connected engineering session.
- Independent source calculations are labelled separately from provider-executed test results.
- Reconcile candidate CI, diff and any test failures before promotion to protected `main`.

**Verified candidate-source MATLAB R2024a CI:** [run 44945399849](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/actions/runs/44945399849), job `136971493310`, on source/test SHA `0287e46ed273d3154e0bed9309a318a809702683`: **46 total, 45 PASSED, 0 FAILED, 1 INCOMPLETE** (optional advanced-controller test filtered by unmet Optimization Toolbox assumption). Code Analyzer reports 0 errors and 0 warnings. The six new regression methods executed in this passing run; unrun scientific acceptance gates remain unverified. The report-update commit follows this receipt and must itself be checked at its final SHA.


### Proven artifact branch integration, 21 November 2026 (UTC)

Primary PR #20 received six selectively reviewed additions from supporting PR #21 at `63f0a09b13197955f90bc8166157509d1ec79874`: pinned R2024a artifact workflow, independent Python provenance verifier, scalar numeric current-profile event mesh correction, per-sample controller history export alignment, MATLAB R2024a-safe experiment metrics validation, and two RED→GREEN regression methods. All three candidate checks succeeded at `63f0a09b13197955f90bc8166157509d1ec79874` (Core #44961412965, artifact #44961412929, authorship #44961412934); QP and Simscape remain incomplete/skipped. This follow-up tightens `buildfile.m` from `WarningThreshold=Inf` to `WarningThreshold=0`; no checks were bypassed, validation PR #21 remains unmerged, and PR #20 remains draft. See scientific matrix for evidence hashes and unresolved limits.
