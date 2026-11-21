# ThermoWeave: source-grounded technical audit and remediation

**Audit date:** 2026-11-21  
**Target:** `mohammadrezwankhan/thermoweave-battery-digital-twin`  
**Frozen baseline:** `6b48646da2f6f8b60a13b14e19c4c65e45b17383` (`main`)  
**Candidate branch:** `audit/thermoweave-engineering-20261121`  
**Scope:** Electrothermal physics, numerical solver, controllers, uncertainty/faults, topology/scenarios, data contract/site, tests/Simscape, CI/security/governance.  
**Method:** Direct GitHub tree/file review, exact source-path inspection, dated Actions job-log checks, independent analytical oracles, focused candidate edits, six executed R2024a regression tests, and separately executed independent Python/SciPy E10 checks. **No native Gemini Carbon / Antigravity multi-agent environment was available.** Domain review was coordinated in this GitHub-connected session; it is not represented as 10 independently executed agents.

## Executive summary and assurance decision

The repository's latest available **baseline** Core CI run at the frozen SHA is legitimately green: MATLAB R2024a ran 40 tests, of which **39 passed, 0 failed, and 1 was incomplete**, filtered by an Optimization Toolbox assumption. The run also reported Code Analyzer **0 errors and 0 warnings** across 47 files. The [19 November 2026 Core CI log](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/actions/runs/44626427308) establishes this **for the baseline**, not this candidate. The [same-date Pages run](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/actions/runs/44626427373) deployed that SHA to the GitHub Pages project URL. Repository metadata currently points to the same GitHub Pages URL; the older separately hosted URL is not proof of Pages deployment.

The source review identified concrete, bounded implementation defects and added focused fixes for **temperature-deadband units**, **stuck-command actual-value holding**, **singular coolant segments**, **negative optional interface scaling**, and **downsampled result integrity**. Six new regression tests include an **independent total stored-energy versus known constant electrical-heat input** check. All six new regression tests passed in the candidate R2024a Core CI (45 PASS / 0 FAIL / 1 optional INCOMPLETE). This does not establish broad scientific verification.

**Material acceptance remains INCOMPLETE:** R2024a candidate tests now cover an independently integrated signed thermal ledger, a separate controller sample clock, off-output-grid thermal fault timing, versioned nested canonical hashing and honest controller method provenance. General solver/stiffness convergence, dynamic coolant energy modelling, cross-release hash migration, regenerated site artifacts, licensed Optimization Toolbox QP execution, authorized Simscape parity and independent IP/provenance review remain NOT VERIFIED or BLOCKED. No physical safety or overall PASS is claimed.

## Repository and environment preflight

The baseline Git tree contains **658 entries**, including `src/+thermoweave/`, five MATLAB test classes, E0–E10 scenario documentation, MATLAB build tasks, optional Simscape adapter, generated web artifacts, and all listed governance files. The only observed source-head SHA at branch creation was `6b48646...`; the audit branch was created from that SHA without changing protected `main`. The GitHub connector reports write permission; no uncommitted local checkout was accessed or overwritten.

- **Baseline CI:** Ubuntu-hosted MATLAB R2024a via pinned `matlab-actions/setup-matlab` and `run-build`; task `test` has `check` as a dependency. Test log is provider evidence, not local re-execution.
- **Local runtime:** neither `matlab` nor `octave` executable is installed in this session; container network DNS cannot clone GitHub. MATLAB R2026a Update 4 values in `artifacts/reports/verification.json` are historical and carry a different recorded commit.
- **Optional products:** Optimization Toolbox test was filtered in hosted CI. Simscape structural generation remains explicitly gated by `.satk` library policy; no authorized licensed Simscape run was performed.
- **Published artifacts:** `artifacts/web-data/thermoweave-demo.json`, `docs/assets/thermoweave-demo.json`, and 3-D summaries exist. They were inspected as committed reports, **not regenerated**.
- **Deployment:** Pages workflow `pages.yml` successfully published `docs/` for baseline; `deploy-dashboard.yml` has a separate validation-only path and its secondary deploy job is skipped by design. Live-browser accessibility was not verified.

## Audit by engineering domain

### A1 — Electrothermal physics

The coded Joule heat `I.^2.*R`, reversible heat `-I.*T.*dUoc_dT`, and positive-discharge SOC derivative agree with the explicit sign convention in `docs/model.md`. Thermal graph exchanges use equal/opposite entries for each undirected edge; the total internal exchange cancels algebraically. The quasi-steady coolant march solves the stated enthalpy balance at positive flow. **Limitation:** dynamic coolant thermal storage does not exist, and a zero-flow/zero-interface segment previously returned 0 K. This singular case is patched to retain the previous/inlet temperature.

**High finding TW-PHY-001:** The legacy normalized residual remains an RHS algebraic-closure check and is not valid as independent energy proof. The audit candidate separately integrates signed generated/ambient/coolant/external powers across solver-accepted states and compares them against endpoint thermal-capacity energy change. Three distinct independent adiabatic, ambient and coolant R2024a oracles pass, but convergence over stiffness/event envelopes and dynamic coolant-model physics remain required.

### A2 — Solvers and numerical stability

The implementation allows `ode15s` and `ode45` with declared tolerances and maximum step. The new event scheduler splits integration at output samples, controller ticks, fault starts/ends and current-profile transitions, rather than only output boundaries; an off-grid heat fault test passes. The baseline solver comparison remains bounded. No systematic shrinking-tolerance/stiffness sweep, arbitrary graph-isomorphism test or compound discontinuity proof has been executed.

### A3 — Control and optimization

The bounded baseline controller now applies Kelvin deadband before the dimensionless gain and uses independent configured clock ticks for bounded, rate-limited zero-order-held commands. The simulator preserves the last executed value through a stuck-actuator fault. New `methodHistory`, `statusHistory` and `objectiveHistory` record successful advanced QP execution versus fallback without inventing optimization success; focused tests pass. The licensed QP path remains filtered/incomplete, and constraint/physical controller validity remains unverified.

### A4 — Stochastic models and faults

`applyVariability.m` constructs a local seeded `RandStream('mt19937ar',...)` and repeat-seed behavior is historically tested; serial/parallel and cross-release reproducibility remain unverified. The controller observes sensor-faulted measurements, not hidden ground truth. The candidate splits thermal fault discontinuities at configured start/end times; the off-grid heat multiplier fixture passes. Concurrent sensor/actuator fault timing, safety policy and recovery remain inadequately covered.

### A5 — Scenarios, graph topology and hashes

`docs/scenarios.md` specifies E0–E10. Independent 3×4×3 topology counting gives 36 nodes and 75 undirected edges and is covered by historical topology tests. The R2026a three-dimensional sensitivity values remain unregenerated on the candidate. `hashStruct` intentionally continues its legacy raw-JSON digest; a new separate `thermoweave.canonical-json/v1` helper recursively sorts nested keys and passes the field-insertion-order regression. Cross-release canonical stability and migration of published hashes/artifacts remain unverified.

### A6 — Result schema, exports and visualization

`makeResult.m` produces `thermoweave.result/v1`, with temperature/SOC histories, topology, boundary, controls, metrics and metadata. The optional `exportJSON(result,path,stride)` previously lost the terminal time unless its index aligned with stride, and retained a mismatched full timebase. Both are patched; summary metrics deliberately remain **full-run** values. Invalid noninteger strides now reject explicitly. `tools/exportWebData.m` derives published scenario metrics from result structs, but no fresh MATLAB data regeneration, independent artifact hash comparison or complete site browser/data parity was performed.

### A7 — Tests and licensed Simscape

The baseline MATLAB R2024a test evidence was 40 total / 39 PASS / 0 FAIL / 1 optional INCOMPLETE. The latest executed candidate code/test SHA `a4d424d971fe14d59df6a9e3a9339cca4a437598` passed [Core CI run 44959047806](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/actions/runs/44959047806): **54 total / 53 PASS / 0 FAIL / 1 INCOMPLETE**. Six original audit regressions plus eight independent control/fault/energy/hash/provenance tests are present. The incomplete test is the Optimization Toolbox-dependent QP case, not evidence of executed optimization. No licensed Simscape parity was run.

### A8 — CI, security, governance and documentation

Core CI runs on `push(main)`, `pull_request(main)` and manual dispatch; pinned actions and read-only token are used. Pages deployment has separate scoped privileges and source gating; latest baseline Pages deployment succeeds. The optional self-hosted Simscape job is manual and labelled `thermoweave-simscape`; no live runner authorization or licensing evidence was inspected. Governance files `LICENSE`, `PROVENANCE.md`, `THIRD_PARTY_NOTICES.md`, `CITATION.cff`, `SECURITY.md`, `RED_TEAM_REPORT.md` and `RISK_REGISTER.md` exist, but legal clean-room/provenance claims cannot be certified merely by reading them. The README's stale static local-test badge was replaced with a Core CI workflow badge, its historical/baseline counts were separated, and the heat equation was rewritten to keep minus signs out of Markdown list syntax.

## Independent challenge and evidence boundaries (A9 role)

The adversarial suite now includes an independent constant-heat stored-energy oracle, a signed integrated heat ledger under adiabatic, ambient-cooling and coolant-cooling experiments, off-grid heat fault duration, independent controller-clock behavior, stable nested hash equality and honest fallback metadata. These tests executed in provider MATLAB R2024a at the recorded code/test SHA, not in this local unlicensed runtime. Remaining counterexamples include flow reversal, charged/discharged current switches, simultaneous sensor/actuator faults, near-isolated nodes and stiff graphs; independently operated physical validation remains absent.

## Confirmed patches and regression risk

| Change | Files | New independent oracle | Principal risk |
|---|---|---|---|
| Temperature deadband before gain | `+control/baselineController.m` | Kelvin/gain arithmetic | Only nonzero-deadband cases change |
| Freeze executed actuator command | `simulate.m` | Fault onset/hold/recovery slew | Legacy `magnitude` semantics change; documented |
| Inactive coolant segment hold | `+coolant/evaluate.m`, `+coolant/march.m` | 0 flow + 0 interfaces | Singular corner only |
| Nonnegative optional interface scales | `+config/validateConfig.m` | Invalid inputs rejected | Previously accepted invalid configs now reject |
| Complete downsampled exports | `+results/exportJSON.m` | Terminal sample/timebase/hash | Downsampled JSON layout slightly changes |
| Evidence/docs truthfulness | `README.md`, `docs/model.md`, `docs/validation.md`, `docs/deployment.md` | Source-run matching | Visual render check pending |

The exact line-level register contains reproduction steps, root cause, evidence and verification status. No generated scenario JSON, numerical benchmarks, physical constants, licensing policies or public result schema major version have been silently changed.

## What would satisfy final acceptance

1. Run PR branch Core CI, inspect **actual test logs** and repair regressions without weakening tests.
2. Extend the implemented signed ledger beyond passing adiabatic/ambient/coolant cases to independent numerical convergence, stiffness, dynamic coolant enthalpy and complex fault regimes.
3. Expand the implemented controller clock/off-grid event scheduler to simultaneous actuator/sensor faults and regenerate published benchmarks in the same MATLAB release.
4. Independently verify the candidate's versioned canonical hash across supported MATLAB releases and migrate `artifacts/` and `docs/` only under a controlled, reviewed compatibility plan.
5. Exercise licensed QP/Simscape workflows where permissions and product licenses permit; retain explicit blocked/skip outcomes otherwise.
6. Regenerate all artifacts, compare canonical MATLAB/JSON/site values, and independently verify GitHub Pages rendering and accessibility.
7. Obtain independent source/asset provenance review before any blanket IP-cleared assertion.

**Verdict: INCOMPLETE.** The applied changes are bounded engineering remediation, not a claim of full model validation, real-cell predictive accuracy or certified safety. A green build alone is insufficient to overturn remaining FAIL/NOT VERIFIED gates.

## Latest executed source/test assurance (21 November 2026)

[MATLAB R2024a Core CI run 44959047806](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/actions/runs/44959047806) completed successfully on code/test SHA `a4d424d971fe14d59df6a9e3a9339cca4a437598`: **54 tests, 53 passed, zero failed, one optional Optimization Toolbox test incomplete**. [Human-authorship policy run 44959047829](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/actions/runs/44959047829) also passed at that exact SHA. This branch's report commits are newer and require a final exact-SHA recheck. Documentation Pages and optional licensed Simscape workflows were **not run** for that code/test SHA. **Overall scientific/CI/deployment verdict: INCOMPLETE.**

## Verified candidate source/test receipt

**Verified candidate-source MATLAB R2024a CI:** [run 44945399849](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/actions/runs/44945399849), job `136971493310`, on source/test SHA `0287e46ed273d3154e0bed9309a318a809702683`: **46 total, 45 PASSED, 0 FAILED, 1 INCOMPLETE** (optional advanced-controller test filtered by unmet Optimization Toolbox assumption). Code Analyzer reports 0 errors and 0 warnings. The six new regression methods executed in this passing run; unrun scientific acceptance gates remain unverified. The report-update commit follows this receipt and must itself be checked at its final SHA.

Independent Python/SciPy E10 sensitivity checks yielded layer spreads **4.590248617, 3.884283666, 2.450641915 K** for through-layer conductances 0.10/0.25/0.75 W/K, within 0.0014 K of historical artifact values. These are approximate independent synthetic-model calculations, not exact regenerated MATLAB artifacts. Overall verdict remains **INCOMPLETE**.
