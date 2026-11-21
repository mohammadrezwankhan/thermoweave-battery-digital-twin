# ThermoWeave scientific verification matrix

**Snapshot:** 2026-11-21 · **Baseline:** `6b48646da2f6f8b60a13b14e19c4c65e45b17383` · **Candidate:** `audit/thermoweave-engineering-20261121`.

States refer to the **candidate**, except where a note explicitly identifies a historical baseline or an independent static mathematical identity. PASS for a bounded static/documentary gate is not physical-cell validation. `FAIL` means that the implementation does not currently demonstrate a required acceptance condition; `NOT VERIFIED` is never counted as PASS. The MATLAB runtime and optional Simscape licenses are unavailable in this review environment.

| Gate | State | Evidence / limitation |
|---|---|---|
| PHY-01 | **NOT VERIFIED** | Static RHS sign review and candidate signed-power experiments PASS, but full independent model-form verification is absent |
| PHY-02 | **NOT VERIFIED** | Adiabatic stored-energy and signed power tests PASS on candidate CI; graph-wide solver/stiffness convergence remains unverified |
| PHY-03 | **NOT VERIFIED** | Coolant signed-energy and inactive segment regressions PASS on candidate R2024a CI; dynamic coolant storage/enthalpy validation unresolved |
| PHY-04 | **NOT VERIFIED** | Joule I^2R and signed entropic -ITdU/dT match declared convention; broader charge transitions unrun |
| PHY-05 | **NOT VERIFIED** | New integrated signed flux ledger and independent CΔT endpoint oracle pass three R2024a experiments; broad mesh/tolerance convergence and independent thermophysical validation remain open |
| NUM-01 | **NOT VERIFIED** | Historic 20s ode15s/ode45 comparison passed; no systematic tolerance convergence |
| NUM-02 | **NOT VERIFIED** | No multi-parameter stiffness sweep captured |
| NUM-03 | **NOT VERIFIED** | Symmetric chain storage-reversal test exists; arbitrary graph relabelling not comprehensively verified |
| NUM-04 | **NOT VERIFIED** | E0 and relaxation baseline checks pass; isolated/passive-mixed cases not comprehensive |
| CTRL-01 | **NOT VERIFIED** | Executed-command and controller provenance regressions PASS; exhaustive actuator paths and constrained QP paths unverified |
| CTRL-02 | **NOT VERIFIED** | Separate sample clock and rate-limit regression PASS; concurrent sensor/actuator fault transients and QP constraints unverified |
| CTRL-03 | **NOT VERIFIED** | New per-sample method/status/objective history identifies executed QP vs bounded fallback and honest provenance test PASS; licensed quadprog optimization remains filtered/incomplete |
| CTRL-04 | **NOT VERIFIED** | Advanced-controller metadata validates fallback identification on available runner; arbitrary fault/solver fallback combinations unverified |
| FAULT-01 | **NOT VERIFIED** | RandStream('mt19937ar') seed local; cross-release/parallel reproducibility untested |
| FAULT-02 | **NOT VERIFIED** | Solver mesh now splits at declared fault start/end times; off-grid heat-multiplier duration regression PASS; mixed fault modes and full convergence unresolved |
| FAULT-03 | **PASS** | Static source confirms controller receives applySensorFaults(sensed,...) rather than true T |
| FAULT-04 | **NOT VERIFIED** | Stuck-command sample-clock recovery and provenance PASS; arbitrary mid-clock actuator onset/end and compound faults not comprehensively tested |
| SCN-01 | **NOT VERIFIED** | Candidate R2024a full artifact run: E0–E8 PASS, E10 3D sweep reproduced; E9 explicitly SKIPPED_MISSING_PRODUCT, exhaustive overrides still unverified |
| SCN-02 | **PASS** | Independent 3x4x3 count gives N=36, E=24+27+24=75; baseline TestTopology3D passed |
| SCN-03 | **NOT VERIFIED** | E10 regenerated at candidate PR head 63f0a09: three g_z cases 0.10/0.25/0.75 W/K, each 36 nodes / 75 edges; independent convergence and cross-release reproduction outstanding |
| SCN-04 | **NOT VERIFIED** | New thermoweave.canonical-json/v1 nested key-order regression PASS; legacy hash deliberately retained, cross-release reproducibility and controlled artifact migration remain unverified |
| DATA-01 | **NOT VERIFIED** | makeResult emits result/v1; edge/fault/runtime validation incomplete |
| DATA-02 | **NOT VERIFIED** | Fresh R2024a reports and two byte-identical web JSON files verified at candidate head 63f0a09, artifact run #44961412929; published Pages/browser parity and hash migration outstanding |
| DATA-03 | **NOT VERIFIED** | exportWebData uses result.metrics; complete browser-display parity not independently inspected |
| TEST-01 | **PASS** | Candidate head 63f0a09 [MATLAB R2024a Core #44961412965](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/actions/runs/44961412965): 56 total / 55 PASS / 0 FAIL / 1 optional INCOMPLETE; analyzer 0 errors/0 warnings |
| TEST-02 | **NOT VERIFIED** | All six focused audit regressions and eight new integration methods PASS; comprehensive invalid-input and stiff solver coverage unverified |
| TEST-03 | **PASS** | Optional adapter skips explicitly rather than returning fabricated Simscape parity; parity itself remains BLOCKED |
| CI-01 | **PASS** | Candidate head 63f0a09 Core #44961412965, scientific artifact #44961412929, human-authorship #44961412934 all succeeded; external vendor checks and deployment independently unverified |
| GOV-01 | **NOT VERIFIED** | Governance files exist, but no independent rights/asset provenance review |
| DOC-01 | **PASS** | Repo homepage, docs/deployment and 2026-11-19 Pages logs identify same GitHub Pages URL |
| DOC-02 | **NOT VERIFIED** | README math rewritten as aligned subtraction; final GitHub renderer review pending |

## Evidence anchors

- [Baseline MATLAB R2024a CI run](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/actions/runs/44626427308): 40 tests total, 39 passed, 0 failed, 1 incomplete (Optimization Toolbox assumption).
- [Baseline GitHub Pages run](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/actions/runs/44626427373): deployment success and environment URL.
- `tests/unit/TestAuditRegressions.m` (six methods) and `tests/integration/TestScientificAuditGates.m` (eight test methods) executed at the recorded R2024a code/test SHA; their scope is bounded and the single optional QP test is still incomplete.
- `artifacts/reports/verification.json`: August 2026 R2026a historical artifact at a different SHA, not regenerated candidate evidence.

**Current executable code/test receipt:** [MATLAB R2024a run 44959047806](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/actions/runs/44959047806), job `137013536188`, SHA `a4d424d971fe14d59df6a9e3a9339cca4a437598`: **54 total / 53 PASSED / 0 FAILED / 1 INCOMPLETE** (licensed Optimization Toolbox advanced test filtered). The [human-authorship-policy run 44959047829](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/actions/runs/44959047829) also completed successfully at that SHA. Static Pages/portfolio jobs are not triggered by this science-only PR; candidate deployment is NOT VERIFIED.

**Overall candidate verdict:** INCOMPLETE. Required scientific, license, reproducibility and governance checks remain unverified. Green baseline CI does not override these open gates.

**Verified candidate-source MATLAB R2024a CI:** [run 44945399849](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/actions/runs/44945399849), job `136971493310`, on source/test SHA `0287e46ed273d3154e0bed9309a318a809702683`: **46 total, 45 PASSED, 0 FAILED, 1 INCOMPLETE** (optional advanced-controller test filtered by unmet Optimization Toolbox assumption). Code Analyzer reports 0 errors and 0 warnings. The six new regression methods executed in this passing run; unrun scientific acceptance gates remain unverified. The report-update commit follows this receipt and must itself be checked at its final SHA.

**Scientific verdict stays INCOMPLETE.** Tested regressions do not clear PHY-05, CTRL-03, or SCN-04.


### Executed artifact integration receipt — 21 November 2026 (UTC)

Primary audit source head `63f0a09b13197955f90bc8166157509d1ec79874` passed [Core R2024a #44961412965](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/actions/runs/44961412965), [artifact reproduction #44961412929](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/actions/runs/44961412929), and [human-authorship #44961412934](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/actions/runs/44961412934), all on the same candidate source SHA. GitHub Actions checked out test merge SHA `8693f51415c1bbf917a21570adf1ce7d7fced44f`, **not** a protected-main merge. Both MATLAB workflows: 56 tests, 55 PASS, 0 FAIL, 1 optional Optimization Toolbox INCOMPLETE; zero MATLAB Code Analyzer errors/warnings. Independently inspected [artifact ZIP #14729727027](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/actions/runs/44961412929/artifacts/14729727027): SHA-256 `a1f154b411a2279f97de2281cfe34931e1cabfb700d9e131cb89f3eff5c80c58`, 56 distinct JUnit test cases with the two new regressions executed, six JSON outputs bearing MATLAB release `2024a`, E0–E8 PASS and E9 `SKIPPED_MISSING_PRODUCT`, E10 three 36-node/75-edge cases at g_z 0.10/0.25/0.75 W/K. Website JSON equals docs copy (221607 bytes; SHA-256 `d119392a892dbb27dc5415b0b556f2df83b484c5098ac3e6500605851d63620f` matching the manifest).

**This is scoped synthetic-source and artifact consistency evidence, not real-cell safety validation, licensed QP/Simscape parity, cross-release canonical hashing, legal clearance or browser deployment validation.** Updating these reports and hardening Code Analyzer warning threshold will change the final candidate SHA; inspect the NEW final SHA checks before any later scientific verdict. Earlier statements of “not regenerated” reflect a superseded pre-integration snapshot.
