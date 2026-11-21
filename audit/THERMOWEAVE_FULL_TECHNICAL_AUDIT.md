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

**Three material assurance gaps remain open:** (1) the reported energy residual is a near-tautological RHS check, not an independently integrated energy balance; (2) controller updates follow the result output grid rather than the declared independent `samplePeriod_s`; and (3) `hashStruct` hashes raw `jsonencode` without an explicitly canonical, versioned key-order contract. No real licensed Simscape parity has been observed. Therefore: **INCOMPLETE — essential scientific verification remains unavailable**, not PASS or a safety-certification statement.

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

**High finding TW-PHY-001:** `simulate.m` computes `res=sum(C.*dT)-(sum(q)+sum(qCool)+sum(externalHeat)-sum(H.*(T-Tb))+sum(flow))` using values from the *same* derivative calculation. The reported normalized residual therefore cannot be accepted as independent integrated-energy proof. Its denominator is the maximum *cell-level* generated heat, not the documented pack-level power scale. A new constant-source stored-energy test uses `sum(C_i (T_i(t_f)-T_i(0)))` against `N I^2 R t_f`; general integrated energy ledgers, coolant enthalpy accumulation and discontinuous-event checks remain pending.

### A2 — Solvers and numerical stability

The implementation allows `ode15s` and `ode45`, with configured relative/absolute tolerances and `MaxStep`. The baseline suite tests a short two-solver final-temperature comparison, equilibrium, uniform boundary and one symmetric chain reversal. No full tightening-tolerance sweep, spectral stiffness study, independently constructed arbitrary node relabelling, or event-aligned integration proof was executed. The solver advances in output intervals; mid-interval fault starts/ends may not be resolved exactly. Record these as unverified, not passing.

### A3 — Control and optimization

The bounded baseline controller uses zero-to-one saturation and per-step slew limits. Its historical temperature deadband was dimensionally misplaced after the proportional gain; it is patched to apply `deadband_K` **before** `Kp_per_K`. The simulator now tracks **actually executed** commands when faults hold an actuator, so recovery slew is referenced to the held state. The advanced QP path uses `quadprog` if available; fallback exists, but successful QP solver identity/objective is not carried into the canonical run result. The configuration's `samplePeriod_s` is currently not an independent scheduler. Full QP/MPC parity and executable identity remain open.

### A4 — Stochastic models and faults

`applyVariability.m` constructs a local `RandStream('mt19937ar','Seed',...)` and samples per-cell resistance/capacity/ambient plus edge and coolant-interface perturbations; repeat-seed equality is historically tested. No serial-versus-parallel or cross-release bitwise evidence exists. The controller receives `applySensorFaults`-modified measurements, not hidden true temperatures (positive source check). A sensor dropout substitutes peer-zone measurements; its safety policy and exact recovery semantics require additional documentation/tests. Stuck actuator semantics are patched as a last-executed-value freeze. Fault starts between output samples remain a separate event-timing gap.

### A5 — Scenarios, graph topology and hashes

`docs/scenarios.md` specifies E0–E10. For a 3x4x3 Cartesian graph, the independent combinatorial result is `N=3*4*3=36` nodes and `E=(3-1)*4*3 + 3*(4-1)*3 + 3*4*(3-1)=24+27+24=75` undirected interfaces. The baseline 3-D topology test checks these numbers. A historical 3-D artifact reports layer-spread sensitivity at `gz=0.10` and `0.75` W/K; this was **not reproduced** under the candidate. `hashStruct.m` hashes raw `jsonencode(s)`; the absence of a documented recursive, versioned canonicalization means order-independent/config-equivalent hashes are **not established**. Changing this function would invalidate existing artifact IDs without a controlled regeneration/migration; it is deliberately left open.

### A6 — Result schema, exports and visualization

`makeResult.m` produces `thermoweave.result/v1`, with temperature/SOC histories, topology, boundary, controls, metrics and metadata. The optional `exportJSON(result,path,stride)` previously lost the terminal time unless its index aligned with stride, and retained a mismatched full timebase. Both are patched; summary metrics deliberately remain **full-run** values. Invalid noninteger strides now reject explicitly. `tools/exportWebData.m` derives published scenario metrics from result structs, but no fresh MATLAB data regeneration, independent artifact hash comparison or complete site browser/data parity was performed.

### A7 — Tests and licensed Simscape

The baseline test evidence is precisely **40 total / 39 pass / 0 fail / 1 incomplete** on R2024a, not the historically committed 37/37 local snapshot. Six new unit tests cover deadband unit contract, applied-value fault freeze and recovery, inactive coolant singularity, independent energy accumulation, nonnegative interface validation, and terminal JSON sample/timebase. All six methods were executed in the verified R2024a audit-branch Core CI run 44945399849 (46 total, 45 PASS, 0 FAIL, 1 optional INCOMPLETE). `simscape/runSimscapeScenario.m` returns explicit `SKIPPED_*` when model/licensing/policy is not ready; this is not Core/Simscape physical parity.

### A8 — CI, security, governance and documentation

Core CI runs on `push(main)`, `pull_request(main)` and manual dispatch; pinned actions and read-only token are used. Pages deployment has separate scoped privileges and source gating; latest baseline Pages deployment succeeds. The optional self-hosted Simscape job is manual and labelled `thermoweave-simscape`; no live runner authorization or licensing evidence was inspected. Governance files `LICENSE`, `PROVENANCE.md`, `THIRD_PARTY_NOTICES.md`, `CITATION.cff`, `SECURITY.md`, `RED_TEAM_REPORT.md` and `RISK_REGISTER.md` exist, but legal clean-room/provenance claims cannot be certified merely by reading them. The README's stale static local-test badge was replaced with a Core CI workflow badge, its historical/baseline counts were separated, and the heat equation was rewritten to keep minus signs out of Markdown list syntax.

## Independent challenge and evidence boundaries (A9 role)

The adversarial review uses a constant-source, zero-boundary stored-energy oracle that does not reuse `simulate.m`'s RHS residual; separate zero-flow/zero-interface, fault-onset and terminal-time assertions are added. Algebraic E10 geometry is checked independently of a site visualization. The six newly authored regression methods executed under the verified R2024a GitHub Actions run; the mathematical test fixtures remain authored by the same engineering reviewer, not independently operated MATLAB validation. Remaining priority counterexamples include flow reversal with unequal branches, charge/discharge switching, sample-clock mismatch, sensor failure on control boundary, near-isolated nodes and stiff graphs. All high issues are tracked in `audit/findings.json`.

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
2. Implement a separate integrated signed heat ledger and compare independent time-integrated source/boundary/coolant terms with stored energy over convergence/stiffness/event studies.
3. Introduce a controller sample clock and exact fault-event integration; regenerate benchmarks from the same MATLAB environment.
4. Define canonical configuration hashing and a versioned migration before changing hashes embedded in `artifacts/` and `docs/`.
5. Exercise licensed QP/Simscape workflows where permissions and product licenses permit; retain explicit blocked/skip outcomes otherwise.
6. Regenerate all artifacts, compare canonical MATLAB/JSON/site values, and independently verify GitHub Pages rendering and accessibility.
7. Obtain independent source/asset provenance review before any blanket IP-cleared assertion.

**Verdict: INCOMPLETE.** The applied changes are bounded engineering remediation, not a claim of full model validation, real-cell predictive accuracy or certified safety. A green build alone is insufficient to overturn remaining FAIL/NOT VERIFIED gates.

## Verified candidate source/test receipt

**Verified candidate-source MATLAB R2024a CI:** [run 44945399849](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/actions/runs/44945399849), job `136971493310`, on source/test SHA `0287e46ed273d3154e0bed9309a318a809702683`: **46 total, 45 PASSED, 0 FAILED, 1 INCOMPLETE** (optional advanced-controller test filtered by unmet Optimization Toolbox assumption). Code Analyzer reports 0 errors and 0 warnings. The six new regression methods executed in this passing run; unrun scientific acceptance gates remain unverified. The report-update commit follows this receipt and must itself be checked at its final SHA.

Independent Python/SciPy E10 sensitivity checks yielded layer spreads **4.590248617, 3.884283666, 2.450641915 K** for through-layer conductances 0.10/0.25/0.75 W/K, within 0.0014 K of historical artifact values. These are approximate independent synthetic-model calculations, not exact regenerated MATLAB artifacts. Overall verdict remains **INCOMPLETE**.
