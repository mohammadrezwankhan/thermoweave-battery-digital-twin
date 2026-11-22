# ThermoWeave engineering audit — reproducibility report

**Prepared:** 2026-11-21  
**Frozen baseline:** `6b48646da2f6f8b60a13b14e19c4c65e45b17383`  
**Audit branch:** `audit/thermoweave-engineering-20261121`  
**State:** **INCOMPLETE — R2024a candidate tests executed; required scientific/licensed reproducibility contracts remain unverified**


### Executed artifact integration receipt — 21 November 2026 (UTC)

Primary audit source head `63f0a09b13197955f90bc8166157509d1ec79874` passed [Core R2024a #44961412965](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/actions/runs/44961412965), [artifact reproduction #44961412929](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/actions/runs/44961412929), and [human-authorship #44961412934](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/actions/runs/44961412934), all on the same candidate source SHA. GitHub Actions checked out test merge SHA `8693f51415c1bbf917a21570adf1ce7d7fced44f`, **not** a protected-main merge. Both MATLAB workflows: 56 tests, 55 PASS, 0 FAIL, 1 optional Optimization Toolbox INCOMPLETE; zero MATLAB Code Analyzer errors/warnings. Independently inspected [artifact ZIP #14729727027](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/actions/runs/44961412929/artifacts/14729727027): SHA-256 `a1f154b411a2279f97de2281cfe34931e1cabfb700d9e131cb89f3eff5c80c58`, 56 distinct JUnit test cases with the two new regressions executed, six JSON outputs bearing MATLAB release `2024a`, E0–E8 PASS and E9 `SKIPPED_MISSING_PRODUCT`, E10 three 36-node/75-edge cases at g_z 0.10/0.25/0.75 W/K. Website JSON equals docs copy (221607 bytes; SHA-256 `d119392a892dbb27dc5415b0b556f2df83b484c5098ac3e6500605851d63620f` matching the manifest).

**This is scoped synthetic-source and artifact consistency evidence, not real-cell safety validation, licensed QP/Simscape parity, cross-release canonical hashing, legal clearance or browser deployment validation.** Updating these reports and hardening Code Analyzer warning threshold will change the final candidate SHA; inspect the NEW final SHA checks before any later scientific verdict. Earlier statements of “not regenerated” reflect a superseded pre-integration snapshot.

## 1. Environment and evidence classes

| Source | Environment / version | Execution status | What it can establish |
|---|---|---|---|
| [19 November 2026 Core CI](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/actions/runs/44626427308) | GitHub-hosted Ubuntu, MATLAB **R2024a** via official pinned MATLAB Actions, baseline SHA above | **Executed:** 40 total, 39 passed, 0 failed, 1 incomplete; Code Analyzer 47 files, 0 errors, 0 warnings | Baseline class test coverage only. The Optimization Toolbox-dependent advanced-controller test was filtered |
| Committed `artifacts/reports/verification.json` | Historical Windows 11, **MATLAB R2026a Update 4**, artifact timestamp 2026-08-14, embedded Git SHA `af0f815510fb29832679ef6dbe84a2e8eb386fae` | **Historical only:** 37 passed, no failures, 63.351% statement coverage | Demonstration result values at the historical code/environment, not current candidate confirmation |
| Current connected audit environment | GitHub connector; no local MATLAB or Octave executable, no managed Gemini Carbon / Antigravity runtime | **Static source and provider-log inspection; GitHub commits applied** | Reviewed source and provider evidence, authored tests; **does not** verify numerical candidate run |
| Optional Simscape | Model requires Simulink + Simscape + Simscape Battery and resolved `.satk` custom-library policy | **BLOCKED / SKIPPED** | No real Core/Simscape parity, dynamic-cell calibration or safety validation |

Do not combine results from different SHAs, MATLAB releases or optional products as though they were one executed test run.

## 2. Configuration seeds, hashes and numerical contracts

- `thermoweave.simulate` validates/merges configuration via `thermoweave.config.loadScenario`, applies seeded variability, constructs thermal topology and integrates coupled temperature/SOC states with `ode15s` or `ode45`.
- `thermoweave.uncertainty.applyVariability` uses a local `RandStream('mt19937ar','Seed',double(seed))`. The documented E4 seeds are **4401–4403**; E8 default `runMonteCarloStudy(20)` seeds are **6100–6119**. These are declared inputs, not newly executed Monte Carlo evidence.
- Legacy `thermoweave.util.hashStruct` still hashes raw `jsonencode(s)` for `scenarioHash`. The audit candidate adds `hashCanonicalStruct` with explicit `thermoweave.canonical-json/v1` version, recursively sorted object fields, normalized negative zero, explicit Infinity tags and NaN rejection. Nested-field equality passes in R2024a; **cross-release equivalence and artifact migration remain NOT VERIFIED**.
- A reproducible scenario identifier requires the resolved configuration, hash algorithm/version, code SHA, MATLAB release, seed and solver/tolerance manifest. The new canonical digest is **additional metadata only**; legacy/public artifact hashes have not been replaced. Controlled migration and full regeneration are still required before treating it as a public canonical identifier.
- The source result schema is `thermoweave.result/v1`; the website compact export is `thermoweave.web/v1`. Data values exposed in `tools/exportWebData.m` are converted from internal kelvin to degrees Celsius for browser presentation.

## 3. Algebraic E10 geometry, separated from execution

The predeclared 3×4×3 cuboid yields a mathematical node count `N = 3 * 4 * 3 = 36`. The unique nearest-neighbor edges are:

`E = (3-1)*4*3 + 3*(4-1)*3 + 3*4*(3-1) = 24 + 27 + 24 = 75`.

The source constructor `src/+thermoweave/+thermal/buildTopology.m` connects orthogonal x/y/z nearest neighbors and the baseline 3-D test asserts 36/75. This independently derived count is a **topology identity**, not proof that the R2026a E10 sensitivity values reproduce on the current branch.

The README reports synthetic layer-mean spread declining from **4.589 K** at `g_z=0.10 W/K` to **2.450 K** at `g_z=0.75 W/K`; these remain reported historical results, not replicated candidate observations. Geometry, external boundary area, material properties and solver settings must be matched before reproducing any sweep.

## 4. Historical demo receipt (not current acceptance threshold)

The committed `artifacts/reports/verification.json` lists:
- peak temperature `298.23068250728062 K`;
- energy residual `4.3940570997464412e-15`;
- scenario hash `200383e2747995652ab0c9a4de40a35e32598f33003abd653f0aed80c9351d03`;
- test count 37, passed 37, failed 0, incomplete 0;
- statement coverage 0.63351;
- optional adapter `SKIPPED_LIBRARY_POLICY_UNRESOLVED`.

**Do not treat 4.39e-15 as an integrated-energy acceptance threshold:** source `simulate.m` computes that scalar as an RHS closure using the same flux terms as `dT`, divided by a maximum individual heat input. An integrated signed source/ambient/coolant/external heat ledger and separate endpoint CΔT now exist and pass independent synthetic R2024a adiabatic, ambient and coolant tests. Broad timestep/stiffness convergence and dynamic coolant-model accuracy remain NOT VERIFIED.

## 5. Exact reproducibility commands

From a clean checkout with MATLAB R2024a+ and the declared toolboxes available:

```matlab
startup
buildtool test
results = runtests("tests", IncludeSubfolders=true);
result = runDemo;
run3DStudy
runMonteCarloStudy(20)
compareBoundaryModes
runAdaptiveCooling
compareCoreAndSimscape
```

The existing `buildfile.m` task is named **`artifacts`**, not `generateArtifacts`. Therefore regenerate with:

```matlab
buildtool artifacts
```

or invoke `generateArtifacts` *as a MATLAB function* after `startup`. In the build graph `artifacts` depends on `test`, so a full artifacts build re-runs the relevant tests. Do not claim `buildtool test generateArtifacts` is an existing buildtool task.

Required receipt for a true candidate verification:
```text
Candidate branch + SHA
MATLAB release and product manifest
Toolbox license/capability status
Exact build command and CI job/run URL
Test count, passed/failed/incomplete/blocked with identifiers
Solver, tolerances, time grid, mesh and seed
Scenario ID + canonical config payload + hash policy
Initial/final stored energy, integrated signed heat inputs/outputs
Independent maximum/final/integrated residual and power normalization
Artifacts: SHA-256 hashes, MATLAB/JSON/browser value parity and schema
Source code diff, verification of reviewed modifications and Pages identity
```

## 6. Cross-release and cross-surface comparison status

| Check | R2024a baseline | R2026a historical | Audit branch |
|---|---|---|---|
| MATLAB class suite | 39 PASS, 1 INCOMPLETE at Nov 19 baseline | 37 PASS in Aug 14 stored report | **54 total / 53 PASS / 0 FAIL / 1 optional INCOMPLETE** in [2026-11-21 R2024a CI](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/actions/runs/44959047806) at code/test SHA a4d424d |
| 3-D node/edge identity | Baseline test passed | Historical study metadata reported | Mathematically 36/75; candidate 3-D regression suite passed |
| Seeded repeated result | Baseline deterministic seed test included | Historical report claims stable demo | **NOT VERIFIED cross-release** |
| E10 0.10–0.75 W/K sensitivity | No candidate reproduction | Historical README figures | **NOT REGENERATED** |
| Full `result/v1` schema / JSON | Some baseline tests passed | Artifact committed | Added downsample fix; focused new export regression passed in R2024a CI |
| Static website data | Pages published baseline docs | Published synthetic web payload | **NOT REGENERATED / NOT browser-verified** |
| QP/MPC / optional Simscape parity | QP test incomplete; Simscape skip accepted | Adapter skip recorded | **NOT RUN / BLOCKED** |

**Reproducibility verdict:** Focused R2024a source/clock/fault/energy/hash checks pass; cross-release, full physical and numerical convergence, canonical hash migration, licensed Simscape/QP and published-artifact regeneration remain NOT VERIFIED. Do not infer PASS from old numerical constants or an optional skip.

## New source/test receipt and hash migration boundary

[GitHub Actions R2024a Core CI run 44959047806](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/actions/runs/44959047806), job `137013536188`, executed code/test SHA `a4d424d971fe14d59df6a9e3a9339cca4a437598`: **54 total / 53 passed / 0 failed / 1 optional incomplete**. [Human authorship run 44959047829](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/actions/runs/44959047829) was also successful on that SHA. The acceptance package changed after this code/test receipt; the final documentation SHA still requires its own exact-SHA check. No published JSON, R2026a result or Simscape model has been regenerated.

## Executed candidate check and independent E10 cross-check

**Verified candidate-source MATLAB R2024a CI:** [run 44945399849](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/actions/runs/44945399849), job `136971493310`, on source/test SHA `0287e46ed273d3154e0bed9309a318a809702683`: **46 total, 45 PASSED, 0 FAILED, 1 INCOMPLETE** (optional advanced-controller test filtered by unmet Optimization Toolbox assumption). Code Analyzer reports 0 errors and 0 warnings. The six new regression methods executed in this passing run; unrun scientific acceptance gates remain unverified. The report-update commit follows this receipt and must itself be checked at its final SHA.

A separately implemented 36-node/75-edge Python SciPy BDF solve (`rtol=1e-10, atol=1e-12`) produced final layer-mean spreads of **4.590248617 K**, **3.884283666 K**, and **2.450641915 K** at `g_z=0.10,0.25,0.75 W/K`. Committed historical MATLAB values are **4.588879025 K**, **3.883132142 K**, and **2.450127386 K**, so differences are **+0.001370, +0.001152, +0.000515 K**. This is independent approximate sensitivity support, **not** exact MATLAB artifact re-execution, hash parity, or real-cell validation.
