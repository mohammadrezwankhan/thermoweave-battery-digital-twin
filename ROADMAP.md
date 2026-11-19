# ThermoWeave roadmap

This roadmap follows the acceptance gates in `PROJECT_CHARTER.md`. Dates are intentionally omitted until a reproducible scope and owner are available.

## Near term: portable core

- Complete the graph electrothermal solver and canonical `thermoweave.result/v1` contract.
- Add scalar, per-cell, zonal, and coolant-propagation boundary modes with unit and energy-accounting tests.
- Implement bounded baseline control, seeded variability, declared faults, and deterministic demo artifacts.
- Establish MATLAB R2024a core CI and record local R2026a verification separately.

## Next: evidence and usability

- Add result manifests, hashes, scenario summaries, and data-traceable visual exports.
- Complete accessibility checks for the static case study and document reduced-motion behavior.
- Publish reproducibility bundles only after fresh-clone, test, provenance, and security gates pass.

## Optional integration

- Resolve the custom-library policy for `simscape/`.
- Add a product-detected Simscape Battery adapter that maps into the canonical result schema.
- Keep integration manual and self-hosted until licensed-product and structural-generation checks are reproducible.

## Later release work

- Add an evidence-backed advanced controller behind explicit product and solver gates.
- Re-audit all imported actions, datasets, media, and generated assets before a public semver release.
- Consider authenticated Pages or package publication only after the repository has a configured remote and release owner.

## Proposed twelve-month plan: 2026-11-19 through 2027-11-18

This dated proposal supersedes the undated scheduling discussion above without rewriting its history. It is a plan for future work, **not a claim that the listed changes are implemented or staffed**. Owner roles and effort ranges are planning assumptions. The native graph/scalar-vector-zonal-coolant core, bounded controllers, seeded faults, 3-D topology, historical artifacts and browser lessons already exist; their current behavior/limits are documented in [the source-backed guide](docs/INDEX.md).

Priorities address evidence and correctness before optional model expansion. `P1` means resolve before relying on the affected scientific contract; `P2` means strengthen reliability/maintainability; `P3` means exploratory scope. No roadmap item promises measured accuracy, cost savings or a release date. Every item has source evidence, dependencies and a verifiable acceptance gate.

| Horizon | Proposed dates | Focus | Items |
|---|---|---|---|
| Now | 2026-11-19–2026-12-31 | Fresh native receipts, control semantics, variability defect | R01–R03 |
| Next | 2027-01-01–2027-03-31 | Independent energy evidence, faults/zero flow, export contracts | R04–R06 |
| Later | 2027-04-01–2027-06-30 | Educational provenance, browser review, optional model decision | R07–R08 |
| Horizon | 2027-07-01–2027-11-18 | Measured-data protocol and release/recovery rehearsal | R09–R10 |

### R01 — Establish exact-revision native evidence

**Proposed:** 2026-11-19–2026-12-31 (Now); **priority:** P1; **owner role:** Scientific maintainer + release maintainer; **effort:** 3–5 working days; **confidence:** High.

**Why this matters:** The stored report records 37 tests at an earlier revision while the inspected source defines 40 methods. Fresh receipts prevent historical values from being mistaken for candidate verification.

**Proposal:** Run a clean supported MATLAB core checkout, archive its command/products/config/results and test/skips/coverage, then define report freshness using source/input identities rather than only mtimes.

**Evidence:** [artifacts/reports/verification.json:1–1](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/artifacts/reports/verification.json#L1-L1) [tools/writeVerificationReport.m:1–95](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/tools/writeVerificationReport.m#L1-L95) [buildfile.m:1–102](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/buildfile.m#L1-L102) [.github/workflows/core-ci.yml:1–34](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/.github/workflows/core-ci.yml#L1-L34)

**Dependencies:** None; prerequisite for the dependent native work.

**Acceptance criteria:**

- Actual test counts, skips, coverage and source SHA are recorded from fresh execution; no count is copied from documentation.
- A changed configuration/tool input cannot reuse an older report without an explicit historical label.
- Documentation-only changes remain separate from generated scientific artifact refreshes.

**Verification:** Execute the current core workflow task on the exact candidate and inspect its JUnit/coverage/artifacts; independently compare receipt/source identities.

**Risks:** Lawful MATLAB runtime and CI capacity must be available; regenerated artifacts can differ by release/renderer.

**Unresolved assumptions:** R2024a remains the supported core floor unless a separately reviewed compatibility decision changes it.

### R02 — Make timing and deadband semantics explicit

**Proposed:** 2026-11-19–2026-12-31 (Now); **priority:** P1; **owner role:** Control maintainer; **effort:** 4–7 working days; **confidence:** High.

**Why this matters:** Output intervals currently schedule controller updates and the named kelvin deadband is subtracted after gain, so benign-looking configuration changes can alter feedback or threshold meaning.

**Proposal:** Choose a backward-compatible or versioned control-clock/deadband contract, including zone weights, final short intervals and rate limiting; implement only after the behavior decision.

**Evidence:** [src/+thermoweave/simulate.m:1–102](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/src/%2Bthermoweave/simulate.m#L1-L102) [src/+thermoweave/+control/baselineController.m:1–17](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/src/%2Bthermoweave/%2Bcontrol/baselineController.m#L1-L17) [tests/integration/TestSimulationIntegration.m:1–205](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/tests/integration/TestSimulationIntegration.m#L1-L205)

**Dependencies:** R01

**Acceptance criteria:**

- A test distinguishes output sampling from the chosen control clock and covers a nondivisible final interval.
- A dimensional deadband example with two gains verifies the agreed threshold behavior.
- Old/new scenario changes and any migration instructions are quantified and reviewed.

**Verification:** Native closed-loop tests with fixed physics and independently chosen sample/control periods, plus source/equation review.

**Risks:** Numerical baselines and controller benefit can change; preserving undocumented behavior may conflict with clearer units.

**Unresolved assumptions:** Owner must decide whether current semantics need compatibility preservation or a versioned correction.

### R03 — Repair topology/variability contracts

**Proposed:** 2026-11-19–2026-12-31 (Now); **priority:** P1; **owner role:** Thermal topology maintainer; **effort:** 2–4 working days; **confidence:** High.

**Why this matters:** The rectangular multi-layer variability helper counts one layer while the topology builds all layers. The R0CV name also obscures its use as lognormal sigma.

**Proposal:** Add the failing rectangular 3×4×3 variability regression, derive draw count from the chosen graph, and document/decide the distribution parameter naming without silently changing distributions.

**Evidence:** [src/+thermoweave/+uncertainty/applyVariability.m:1–36](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/src/%2Bthermoweave/%2Buncertainty/applyVariability.m#L1-L36) [src/+thermoweave/+thermal/buildTopology.m:1–178](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/src/%2Bthermoweave/%2Bthermal/buildTopology.m#L1-L178) [tests/unit/TestTopology3D.m:1–79](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/tests/unit/TestTopology3D.m#L1-L79)

**Dependencies:** R01

**Acceptance criteria:**

- A rectangular 3×4×3 variability run has exactly 75 edge scales and completes on the supported native runtime.
- One-layer/cuboid/staggered fixtures retain declared ordering, deterministic seed behavior and positive-conductance requirements.
- The lognormal sigma versus actual CV distinction is reflected in config/API documentation and tests.

**Verification:** Native topology/variability tests; independent edge enumeration and repeated-seed comparison.

**Risks:** Changing draw order can change scenario hashes and downstream random draws.

**Unresolved assumptions:** Decide whether legacy seeded draws must remain byte-compatible or require a versioned distribution contract.

### R04 — Add independent energy and convergence evidence

**Proposed:** 2027-01-01–2027-03-31 (Next); **priority:** P1; **owner role:** Scientific verification reviewer; **effort:** 6–10 working days; **confidence:** High.

**Why this matters:** The reported residual is computed from the same RHS and cannot bound integration error or omitted fluxes; normalization becomes fragile near zero electrical heat.

**Proposal:** Define an independent integrated energy defect with explicit units/scales, expose sign-separated flux traces, and refine tolerances/time grids while holding the agreed control schedule fixed.

**Evidence:** [src/+thermoweave/simulate.m:1–102](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/src/%2Bthermoweave/simulate.m#L1-L102) [tests/integration/TestSimulationIntegration.m:1–205](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/tests/integration/TestSimulationIntegration.m#L1-L205) [docs/model.md:1–136](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/docs/model.md#L1-L136)

**Dependencies:** R01, R02, R03

**Acceptance criteria:**

- Insulated, externally heated, scalar-boundary and coolant fixtures report independent energy defect in J with declared normalization.
- A deliberate sign/flux omission is detected by an oracle that does not reuse the same assembled RHS expression.
- A refinement study reports error trends and discontinuity alignment rather than asserting a universal solver tolerance.

**Verification:** Compare analytic lumped cases, independently integrated fluxes and multiple solver/tolerance settings; retain all run receipts.

**Risks:** Quadrature and discontinuities can dominate a defect; careless normalization can hide errors.

**Unresolved assumptions:** Select tolerances from dimensional error targets and expected numeric scales, not historical tiny residual values.

### R05 — Specify zero-flow, fault and active-field behavior

**Proposed:** 2027-01-01–2027-03-31 (Next); **priority:** P2; **owner role:** Coolant and input-contract maintainer; **effort:** 5–8 working days; **confidence:** Medium.

**Why this matters:** Pump-loss can enter an epsilon-regularized zero-flow regime, active boundary fields override ambient variability, and empty/global targets are not handled uniformly.

**Proposal:** Declare supported zero-flow physical semantics or an explicit unsupported state; define active configuration fields, target domains, fault timing and declaration-versus-activation evidence.

**Evidence:** [src/+thermoweave/+coolant/evaluate.m:1–68](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/src/%2Bthermoweave/%2Bcoolant/evaluate.m#L1-L68) [src/+thermoweave/+uncertainty/applyFaults.m:1–34](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/src/%2Bthermoweave/%2Buncertainty/applyFaults.m#L1-L34) [src/+thermoweave/+config/validateConfig.m:1–392](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/src/%2Bthermoweave/%2Bconfig/validateConfig.m#L1-L392) [src/+thermoweave/simulate.m:1–102](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/src/%2Bthermoweave/simulate.m#L1-L102)

**Dependencies:** R01, R02, R03

**Acceptance criteria:**

- Zero-flow with positive/zero segment conductance has explicit expected behavior and no fabricated physical interpretation.
- Empty, malformed and out-of-range targets have consistent documented rejection or expansion for each fault family.
- Inactive/overridden parameter changes are either rejected, warned or documented through verified examples.

**Verification:** Table-driven native invalid-input and boundary/fault edge-case tests; independent static coolant energy checks.

**Risks:** A zero-flow physical model may require a new coolant state rather than a numeric guard tweak.

**Unresolved assumptions:** The owner must choose whether unsupported cases should reject input or receive a separately validated model extension.

### R06 — Version result/export and consumer contracts

**Proposed:** 2027-01-01–2027-03-31 (Next); **priority:** P2; **owner role:** Interface maintainer; **effort:** 4–6 working days; **confidence:** High.

**Why this matters:** Downsampled arrays can omit final time while retaining full-grid metadata and metrics, and legacy playback only checks a subset of its payload.

**Proposal:** Specify integer stride, terminal sample policy, byte counts, sampled/full-resolution metadata, and minimum consumer validation while preserving or explicitly migrating schema versions.

**Evidence:** [src/+thermoweave/+results/exportJSON.m:1–12](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/src/%2Bthermoweave/%2Bresults/exportJSON.m#L1-L12) [src/+thermoweave/+results/makeResult.m:1–10](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/src/%2Bthermoweave/%2Bresults/makeResult.m#L1-L10) [tools/exportWebData.m:1–72](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/tools/exportWebData.m#L1-L72) [docs/app.js:1–207](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/docs/app.js#L1-L207)

**Dependencies:** R01

**Acceptance criteria:**

- Invalid/noninteger stride is rejected and endpoint inclusion follows the documented rule.
- Every exported history aligns with its declared timebase; metrics retain explicit full-resolution provenance.
- A consumer rejects missing/empty/nonfinite/misordered required fields and distinguishes hash syntax from verified content identity.

**Verification:** Native export fixtures plus an independent JSON consumer; Unicode byte-count and 12/36-node cases.

**Risks:** Strict consumers may reject historical files; schema changes need migration examples.

**Unresolved assumptions:** Decide whether to extend v1 compatibly or introduce a v2 with explicit provenance fields.

### R07 — Refresh educational provenance and actual browser review

**Proposed:** 2027-04-01–2027-06-30 (Later); **priority:** P2; **owner role:** Documentation + accessibility maintainer; **effort:** 5–8 working days; **confidence:** Medium.

**Why this matters:** Existing learning catalogues point to older snapshots and browser DOM behavior has not been exercised by this author. Scalar teaching and native playback need visible provenance boundaries.

**Proposal:** Refresh catalogues only from reviewed source, preserve historical identities explicitly, and perform desktop/mobile/keyboard/formula/download/storage checks on the actual deployed routes.

**Evidence:** [docs/lesson-config.json:1–320](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/docs/lesson-config.json#L1-L320) [docs/native-lessons.json:1–353](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/docs/native-lessons.json#L1-L353) [docs/portfolio/lesson-config.json:1–373](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/docs/portfolio/lesson-config.json#L1-L373) [docs/index.html:1–475](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/docs/index.html#L1-L475) [docs/app.js:1–207](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/docs/app.js#L1-L207)

**Dependencies:** R02, R04, R06

**Acceptance criteria:**

- Each catalogue has a coherent pinned source/config identity and no inaccurate command path.
- All eight scalar fixtures remain derived from declared inputs; native claims use native evidence.
- A supported-browser receipt covers responsive reading, focus/keyboard, reduced motion, fallback/error states and download/storage behavior with exact deployed identity.

**Verification:** Existing guide validator, bounded arithmetic helper, link checks and actual browser/accessibility testing with recorded outcomes.

**Risks:** Browser/platform behavior differs and old personal learning state may require migration.

**Unresolved assumptions:** Supported browser/device and assistive-technology targets need an owner-approved test matrix.

### R08 — Decide and implement the optional model gate

**Proposed:** 2027-04-01–2027-06-30 (Later); **priority:** P2; **owner role:** Model owner + licensed-runner maintainer; **effort:** 2–4 weeks; **confidence:** Medium.

**Why this matters:** The optional builder currently reports prerequisites but creates no model; no generated model is tracked and mapping is not independent fidelity evidence.

**Proposal:** Resolve library policy, choose whether to build/maintain a model, inspect dependencies/callbacks and define required mapped signals plus a bounded comparison protocol.

**Evidence:** [simscape/buildThermoWeaveModel.m:1–105](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/simscape/buildThermoWeaveModel.m#L1-L105) [simscape/runSimscapeScenario.m:1–40](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/simscape/runSimscapeScenario.m#L1-L40) [simscape/mapSimscapeResults.m:1–132](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/simscape/mapSimscapeResults.m#L1-L132) [DECISIONS.md:1–83](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/DECISIONS.md#L1-L83) [.github/workflows/simscape-integration.yml:1–28](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/.github/workflows/simscape-integration.yml#L1-L28)

**Dependencies:** R01, R04, R06

**Acceptance criteria:**

- Owner decision records reusable-library policy and lawful licensed runner/product availability.
- If implementation proceeds, a generated-model manifest is validated, the actual model compiles/runs, and complete mapped fields/residual provenance are checked.
- Absent prerequisites remain explicit skips; comparison metrics do not call either implementation ground truth.

**Verification:** Manual licensed integration with actual model/manifest/source hashes, compile/run logs and independently reviewed comparison limits.

**Risks:** License/runner/library availability and structural modeling effort may exceed this horizon.

**Unresolved assumptions:** This is optional and must not block a core-only release when mandatory gates are independently met.

### R09 — Design a measured-data validation program

**Proposed:** 2027-07-01–2027-11-18 (Horizon); **priority:** P3; **owner role:** Scientific owner + data/provenance reviewer; **effort:** 2–3 weeks for protocol; execution unestimated; **confidence:** Low.

**Why this matters:** All existing physics parameters/studies are synthetic, so predictive accuracy cannot be responsibly claimed.

**Proposal:** Evaluate data access and rights, define instrumentation/calibration/uncertainty, parameter identification and held-out validation before choosing whether to expand beyond a demonstrator.

**Evidence:** [PROJECT_CHARTER.md:1–43](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/PROJECT_CHARTER.md#L1-L43) [PROVENANCE.md:1–60](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/PROVENANCE.md#L1-L60) [manuscript/SUBMISSION_CHECKLIST.md:1–27](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/manuscript/SUBMISSION_CHECKLIST.md#L1-L27)

**Dependencies:** R04, R05, R08

**Acceptance criteria:**

- A written go/no-go protocol identifies lawful data sources, measured quantities, uncertainty, model domain and held-out evaluation.
- No synthetic result is relabeled measured and no unsupported accuracy/lifetime/safety claim is published.
- Any proposed implementation is separately scoped after protocol/data feasibility review.

**Verification:** Independent scientific/provenance review of the protocol; actual data execution remains conditional and separately evidenced.

**Risks:** Data acquisition, rights and identifiability may make validation infeasible; model discrepancy may dominate fit.

**Unresolved assumptions:** No measured dataset, lab access, budget or calibration effort is promised by this roadmap.

### R10 — Rehearse recovery and a release with defensible evidence

**Proposed:** 2027-07-01–2027-11-18 (Horizon); **priority:** P2; **owner role:** Release owner + independent reviewer; **effort:** 4–7 working days; **confidence:** Medium.

**Why this matters:** A release needs source/runtime/artifact/claim provenance and current policy; historical CFF version and successful source jobs are insufficient.

**Proposal:** Run a fresh-maintainer recovery drill, examine numerical versus archive/render reproducibility, refresh notices/security/citation facts and complete an ordinary guarded release only if the owner authorizes its exact scope.

**Evidence:** [tools/packageRelease.m:1–43](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/tools/packageRelease.m#L1-L43) [.github/workflows/release.yml:1–60](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/.github/workflows/release.yml#L1-L60) [SECURITY.md:1–19](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/SECURITY.md#L1-L19) [CITATION.cff:1–18](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/CITATION.cff#L1-L18)

**Dependencies:** R01, R04, R06, R07

**Acceptance criteria:**

- A second maintainer reproduces the core from documented prerequisites with complete hashes and actual statuses.
- Archive, rendered artifacts and numerical results have distinct reproducibility statements and any variability is explained.
- Current branch/review/signature/check policy is satisfied; any tag/release/deployment has observed identities and actual content review.

**Verification:** Clean-environment recovery, checksum/provenance review, native gates, independent QA and supported-browser deployed-content review.

**Risks:** Current policy, signer access, product availability or publication checks may block release.

**Unresolved assumptions:** No new release number, date, tag or deployment is preassigned by this plan.

### Decisions and scope beyond this plan

Keep the graph core usable while optional product work is unavailable. A missing measured dataset or unresolved optional model can result in a documented no-go decision instead of fabricated completion. Hardware deployment, safety certification, production control, guaranteed aging/thermal-runaway prediction and commercial support remain outside the current charter. Reassess dates/capacity at each horizon using completed acceptance evidence; do not convert scheduled targets into progress percentages without actual work receipts.

Link accepted decisions in [the ADR index](docs/owner/ADR/ADR-0000-INDEX.md), actual checks in [the verification ledger](docs/maintainer/VERIFICATION_EVIDENCE_LEDGER.md), and compatibility changes in the API/equation pages. Roadmap documentation creates no automation, model code, workflow, tag or deployment.
