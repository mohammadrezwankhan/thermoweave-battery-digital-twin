# ThermoWeave scientific verification matrix

**Snapshot:** 2026-11-21 · **Baseline:** `6b48646da2f6f8b60a13b14e19c4c65e45b17383` · **Candidate:** `audit/thermoweave-engineering-20261121`.

States refer to the **candidate**, except where a note explicitly identifies a historical baseline or an independent static mathematical identity. PASS for a bounded static/documentary gate is not physical-cell validation. `FAIL` means that the implementation does not currently demonstrate a required acceptance condition; `NOT VERIFIED` is never counted as PASS. The MATLAB runtime and optional Simscape licenses are unavailable in this review environment.

| Gate | State | Evidence / limitation |
|---|---|---|
| PHY-01 | **NOT VERIFIED** | RHS signs match docs/model.md statically; no independent on-branch execution |
| PHY-02 | **NOT VERIFIED** | Incidence/Laplacian structure conserves edge transfers algebraically; targeted energy test queued |
| PHY-03 | **NOT VERIFIED** | Quasi-steady coolant enthalpy is unit-tested historically; zero-flow corner patched, CI pending |
| PHY-04 | **NOT VERIFIED** | Joule I^2R and signed entropic -ITdU/dT match declared convention; broader charge transitions unrun |
| PHY-05 | **FAIL** | Current residual is a same-RHS algebraic identity, not an independently integrated energy audit (TW-PHY-001) |
| NUM-01 | **NOT VERIFIED** | Historic 20s ode15s/ode45 comparison passed; no systematic tolerance convergence |
| NUM-02 | **NOT VERIFIED** | No multi-parameter stiffness sweep captured |
| NUM-03 | **NOT VERIFIED** | Symmetric chain storage-reversal test exists; arbitrary graph relabelling not comprehensively verified |
| NUM-04 | **NOT VERIFIED** | E0 and relaxation baseline checks pass; isolated/passive-mixed cases not comprehensive |
| CTRL-01 | **NOT VERIFIED** | Baseline bound checks pass historically; actual faulted command checks pending audit CI |
| CTRL-02 | **NOT VERIFIED** | Executed-command slew behavior patched; fault-onset/recovery regression pending |
| CTRL-03 | **FAIL** | No per-run executed QP identity/objective recorded after successful advanced call; optional toolbox test incomplete in CI |
| CTRL-04 | **NOT VERIFIED** | Baseline fallback path exists, but fully deterministic fault/fallback validation not performed |
| FAULT-01 | **NOT VERIFIED** | RandStream('mt19937ar') seed local; cross-release/parallel reproducibility untested |
| FAULT-02 | **NOT VERIFIED** | Fault timeline evaluated inside output-interval solver chunks; arbitrary event alignment unresolved |
| FAULT-03 | **PASS** | Static source confirms controller receives applySensorFaults(sensed,...) rather than true T |
| FAULT-04 | **NOT VERIFIED** | Stuck-command semantics patched with regression; not yet run on candidate |
| SCN-01 | **NOT VERIFIED** | docs/scenarios.md declares E0-E10; all programmatic paths/overrides not comprehensively replayed |
| SCN-02 | **PASS** | Independent 3x4x3 count gives N=36, E=24+27+24=75; baseline TestTopology3D passed |
| SCN-03 | **NOT VERIFIED** | Historical 3-D artifact available; conductance sweep not regenerated on candidate |
| SCN-04 | **FAIL** | hashStruct uses raw jsonencode with no recursive canonical key ordering or versioned migration |
| DATA-01 | **NOT VERIFIED** | makeResult emits result/v1; edge/fault/runtime validation incomplete |
| DATA-02 | **NOT VERIFIED** | Web JSON and report data were not regenerated with MATLAB after changes |
| DATA-03 | **NOT VERIFIED** | exportWebData uses result.metrics; complete browser-display parity not independently inspected |
| TEST-01 | **NOT VERIFIED** | Baseline 2026-11-19: 40 total, 39 passed, 0 failed, 1 incomplete; candidate CI pending |
| TEST-02 | **NOT VERIFIED** | Six audit regression tests added; candidate results pending |
| TEST-03 | **PASS** | Optional adapter skips explicitly rather than returning fabricated Simscape parity; parity itself remains BLOCKED |
| CI-01 | **PASS** | Core CI uses pinned official MATLAB actions and ran 40 tests at baseline SHA |
| GOV-01 | **NOT VERIFIED** | Governance files exist, but no independent rights/asset provenance review |
| DOC-01 | **PASS** | Repo homepage, docs/deployment and 2026-11-19 Pages logs identify same GitHub Pages URL |
| DOC-02 | **NOT VERIFIED** | README math rewritten as aligned subtraction; final GitHub renderer review pending |

## Evidence anchors

- [Baseline MATLAB R2024a CI run](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/actions/runs/44626427308): 40 tests total, 39 passed, 0 failed, 1 incomplete (Optimization Toolbox assumption).
- [Baseline GitHub Pages run](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/actions/runs/44626427373): deployment success and environment URL.
- `tests/unit/TestAuditRegressions.m`: newly added independent finite-energy, deadband, actuator, zero-flow, validation and serialization tests; do not mark passed before a CI log for this branch is obtained.
- `artifacts/reports/verification.json`: August 2026 R2026a historical artifact at a different SHA, not regenerated candidate evidence.

**Overall candidate verdict:** INCOMPLETE. Required physics/control/hash checks remain failed or unverified. Green baseline CI does not override these open gates.
