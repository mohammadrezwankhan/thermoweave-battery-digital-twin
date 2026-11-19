# Verification evidence ledger

This is a dated source/documentation review for **2026-11-19**, pinned to `5f29e34788b0f7ee58e2feeafc4df5d48a9a687a` and source Git tree `a711d4e91e89cb7c18448cd6fbf45805eecdfc9b`. A documentation candidate is a later uncommitted working tree at author handoff; its exact manifest/fingerprint and eventual commit, merge and deployment identities belong in external run receipts. No release, merge or publication success is implied here.

## Evidence classes

| Class | Method | Appropriate claim |
|---|---|---|
| Implemented | Read pinned source and tests, with exact path/line links | What code computes or asserts |
| Declared | Read config, workflow or policy | Intended settings and trigger/gate configuration |
| Observed local | Execute inspected bounded checks and preserve stdout/status | Exactly that command in that environment |
| Observed provider | Read provider check-run identity/conclusion | Provider's status for its actual head SHA/context |
| Historical | Read committed result/report | What the stored report says at its own recorded revision/time |
| Proposal | Source-derived future work with acceptance criteria | Planned investigation, not implemented behavior |
| Unavailable | Tool, permission, product or artifact missing | A named unresolved verification boundary |

## Current source definitions versus history

Static enumeration finds **40 current test methods in five classes**: 17 in `TestConfigAndPhysics`, 3 in `TestTopology3D`, 11 in `TestSimulationIntegration`, 3 in `Test3DStudy`, and 6 in `TestRegressionContracts`. Setup methods are excluded. This is source counting, **not 40 executed passes**. The advanced optimization test can skip when `quadprog` is unavailable; the adapter test accepts explicit skip statuses. [tests/unit/TestConfigAndPhysics.m:1–204](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/tests/unit/TestConfigAndPhysics.m#L1-L204) [tests/unit/TestTopology3D.m:1–79](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/tests/unit/TestTopology3D.m#L1-L79) [tests/integration/TestSimulationIntegration.m:1–205](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/tests/integration/TestSimulationIntegration.m#L1-L205) [tests/integration/Test3DStudy.m:1–80](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/tests/integration/Test3DStudy.m#L1-L80) [tests/regression/TestRegressionContracts.m:1–111](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/tests/regression/TestRegressionContracts.m#L1-L111)

The stored verification report records 37 passed / 0 failed / 0 incomplete, `statementCoverage=0.63351`, zero Code Analyzer findings and adapter `SKIPPED_LIBRARY_POLICY_UNRESOLVED`, at `2026-08-14T02:05:03Z`, MATLAB `2026a`, Git revision `af0f815510fb29832679ef6dbe84a2e8eb386fae`. Its demo peak 298.2306825072806 K and residual about 4.394e−15 are historical synthetic output. Preserve these values as history; do not reuse them as the current candidate's verification. [artifacts/reports/verification.json:1–1](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/artifacts/reports/verification.json#L1-L1)

The separate 3-D report contains weak/nominal/strong cross-layer cases with 36 nodes and 75 edges, reported peak temperatures about 303.9873, 303.6345 and 302.9179 K. It records `2026a` and configuration hashes but no independent measured validation. The experiment report contains ten E0–E9 records and synthetic labeling. Reading their JSON is not regeneration. [artifacts/reports/3d-study-summary.json:1–65](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/artifacts/reports/3d-study-summary.json#L1-L65) [artifacts/reports/experiment-summary.json:1–1](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/artifacts/reports/experiment-summary.json#L1-L1)

## Source-head provider snapshot

The authenticated read-only snapshot at **2026-11-19T19:51:50.120Z** returned seven completed checks on source `5f29e34788b0f7ee58e2feeafc4df5d48a9a687a`: six success and one skipped. Each link below identifies the actual job; the two `deploy` names are different workflows.

| Context | Conclusion | Provider reference |
|---|---|---|
| MATLAB R2024a core build | success | [job 132914380830](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/actions/runs/43747651216/job/132914380830) |
| human-authorship-policy | success | [job 132914380752](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/actions/runs/43747651169/job/132914380752) |
| Pages build | success | [job 132914380825](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/actions/runs/43747651184/job/132914380825) |
| Pages deploy | success | [job 132914455232](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/actions/runs/43747651184/job/132914455232) |
| Dashboard validate | success | [job 132914380678](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/actions/runs/43747651164/job/132914380678) |
| Dashboard deploy | skipped | [job 132914472278](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/actions/runs/43747651164/job/132914472278) |
| Dependabot | success | [job 132948265052](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/actions/runs/43758660816/job/132948265052) |

This author inspected provider metadata, not complete native logs or downloaded CI artifacts. These source-head checks do not clear future candidate-head CI. The ruleset endpoint returned an empty list, while classic main protection returned **403 Resource not accessible by integration**. Empty rulesets do not establish that classic protection is absent. No tags/releases were returned in that dated snapshot. Current integration must refresh policy and check evidence through an authorized route; missing visibility is not a bypass permission.

## Local author checks and limitations

The documentation pass uses Python 3.12.14, Node v24.22.3 and Pandoc 3.1.11.1. Executable commands are documented so they can be repeated:

```bash
python scripts/portfolio/validate_guide.py
node docs/reference/check_lesson.cjs
python docs/reference/build_reference.py --check
```

The author run verifies the exact canonical object hashes, all tracked-entry dispositions, requested output paths, unchanged protected files, syntax/structured formats, local links/fragments, pinned-source line ranges, CFF schema, handbook input hashes and permitted diff. The Node helper executes the thermal teaching model and all eight configured checkpoints. Its independent analytic probes concern only that scalar formula. The complete per-check outputs and exact candidate identity are retained with the handoff, separately from this source snapshot.

**NOT_RUN locally:** MATLAB tests/demo, native plotting, optional optimization/Simscape, Code Analyzer/coverage generation, artifact regeneration, manuscript rendering, release archive, actual desktop/mobile browser journeys, assistive technology, deployed-page inspection and independent measured/physical validation. No MATLAB/Octave executable is installed. Local Chromium launch is unavailable; the cancelled browser sign-in path was not retried. No browser success or screenshot result is fabricated.

## Test evidence map and missing oracles

| Question | Existing source evidence | Remaining limit |
|---|---|---|
| Equilibrium and temperature direction | Isothermal, relaxation and scalar/vector equivalence tests | Selected fixtures; not a calibrated transient response |
| Solver agreement | ode15s/ode45 final comparison at 1e−4 K | Not independent global error or all discontinuity alignment |
| Heat accounting | RHS residual checks; static coolant balance at 1e−9 W | RHS residual reuses same algebra; integrated energy defect proposed |
| Graph consistency | Node/order/edge/PSD and one-layer reduction tests | Rectangular multi-layer variability case absent |
| Controller limits | Bounds/rate and conditional advanced test | Independent sample clock/deadband-unit contract absent |
| Repetition/export | Repeated seed/JSON and canonical schema tests | Cross-release, noninteger stride and terminal-sample contract incomplete |
| Faults | Declared events, dimensions, selected restriction test | No demonstrated independent fault detector |
| Interface rendering | 3-D patch/axes/view assertions | Not complete GUI or accessibility verification |

Source locations are in [the API catalogue](../developer/API_REFERENCE.md); scientific limits are in [ASSUMPTIONS_AND_LIMITS](../math-and-physics/ASSUMPTIONS_AND_LIMITS.md). A reviewer must re-run applicable gates on the frozen candidate. Author-side checking is not independent QA. Record `PASS`, `FAIL`, `SKIPPED`, `NOT_RUN` and `INACCESSIBLE` without collapsing them into a single health badge.
