# ThermoWeave independent red-team report

## Scope and method

This is an adversarial, read-only review of the repository tree (excluding `.git`, `results`, `release`, and generated project metadata where it was not material). I inspected MATLAB source, JSON configurations, tests, Simscape adapter code, documentation, website HTML/CSS/JavaScript, provenance/license notices, GitHub workflows, generated manifests, and the source ZIP. I ran targeted MATLAB checks and the current class suite with MATLAB R2026a Update 4 on Windows 11. The current source suite returned **31 passed, 0 failed, 0 incomplete**; the checked-in generated verification manifest still says 29, which is itself a finding. No R2024a or licensed Simscape model run was available.

Severity is based on release impact, not on whether a claim is intentional. “Definite” means directly reproduced or mechanically demonstrated. “Risk/untested” means a contract or claim that cannot be established from this repository.

## Release-blocking findings (1)

### RB-1 — Generated verification evidence is stale (definite)

At the audit snapshot, `artifacts/reports/verification.json:1` and the nested `verification` object in `artifacts/reports/artifact-manifest.json:1` report `testCount:29, passed:29`. The current tree has 31 discovered tests and the current MATLAB run is 31/31. README/docs may also be regenerated from a different count. A release archive that carries contradictory test evidence is not reproducible evidence. If the maintainer regenerates these files after this report, this finding becomes remediated but the regenerated hashes must be rechecked.

Remediation: run the final build/artifact task after all test edits, verify the 31-test count in every generated report and site claim, then package again and compare hashes from a clean checkout.

## High findings (2)

### H-1 — Canonical metrics documentation overstates the result contract (definite contract mismatch)

`docs/model.md:112` says every result reports coolant outlet rise, fault delay/excursion/recovery, solver events, and constraint violations. `src/+thermoweave/+results/makeResult.m:3-10` and `src/+thermoweave/+results/computeMetrics.m:13-18` do not emit outlet-rise or fault outcome metrics; the core result carries declared events and a scalar residual, not those promised measurements. This can cause consumers to treat absent metrics as validated outcomes.

Remediation: either add and test these fields (including a clear “not available” state) or narrow the canonical contract documentation to fields actually emitted.

### H-2 — Minimum MATLAB and optional Simscape claims remain unverified (risk/untested claim)

`ENVIRONMENT.md:10-25` records local R2026a evidence and a policy-gated optional adapter; `.github/workflows/core-ci.yml:22-30` targets R2024a, but that hosted CI path has not run in this repository. `artifacts/reports/verification.json:1` and `simscape/buildThermoWeaveModel.m:26-36` evidence the Simscape status as `SKIPPED_LIBRARY_POLICY_UNRESOLVED`; no generated model or numerical core-versus-Simscape comparison is present. This is honestly disclosed, but it prevents a claim of R2024a portability or Simscape integration.

Remediation: run the core workflow on R2024a and, separately, resolve the library policy on a licensed runner before publishing any high-fidelity comparison claim.

## Medium findings (4)

### M-1 — Coverage is below the declared advisory target (definite evidence gap)

`docs/validation.md:13` and generated verification report statement coverage of about 59.7% (536/899), below the buildfile’s advisory 80% target (`buildfile.m:20-28`). Passing tests do not establish coverage of fault, topology, malformed-input, or optional-adapter branches.

Remediation: add branch/negative-path tests or explicitly lower and justify the target; keep the shortfall visible in release notes.

### M-2 — Website integrity check validates hash syntax, not artifact identity (risk)

`docs/app.js:166-179` validates the web schema, array shapes, and that each scenario hash is 64 hexadecimal characters. It does not hash the fetched JSON or compare it with the SHA-256 in `artifacts/reports/artifact-manifest.json`; a changed-but-well-formed JSON file is therefore accepted as “traceable.” The table alternative, keyboard controls, focus styles, and reduced-motion handling are strengths, but the client-side integrity claim remains advisory.

Remediation: publish a digest alongside the site payload and verify it where feasible, or describe the check as schema/shape validation rather than cryptographic provenance.

### M-3 — MIT badge/Citation conflict with the conditional provenance policy (definite documentation inconsistency)

`LICENSE:1-25`, `CITATION.cff:10-12`, and `README.md:7` present MIT licensing, while `PROVENANCE.md:44-46` says MIT representation is conditional on a later repository-wide authorship/dependency/generated-asset audit. `THIRD_PARTY_NOTICES.md:27` also says action revisions remain mutable pending a release audit.

Remediation: record that the audit is complete and define the MIT scope, or remove the badge/CFF license claim until that decision is complete. Keep third-party product/action terms separate.

### M-4 — GitHub Actions are mutable major-version references (supply-chain risk)

`.github/workflows/*.yml` uses `actions/checkout@v6`, Pages actions at `@v4/@v5`, and MATLAB actions at `@v3`; `THIRD_PARTY_NOTICES.md:17-27` acknowledges these are mutable. This is acceptable for development but not immutable release provenance.

Remediation: resolve and pin commit SHAs for release workflows, record the resolved revisions and licenses, and review updates deliberately.

## Low findings (2)

### L-1 — `git diff --check` hygiene failure

The current diff reports trailing whitespace in `DECISIONS.md:48-49,54-55,60-61`. This does not alter execution, but it weakens clean-checkout and patch reproducibility gates.

Remediation: remove trailing spaces and rerun `git diff --check` before packaging.

### L-2 — Website/release are intentionally local only (risk, not a defect)

`docs/deployment.md` and `docs/index.html` state that no remote repository, release, or Pages deployment is claimed. The external repository link is therefore a prospective path, not evidence of a published artifact. Do not market the local Pages workflow as deployed until an authenticated remote run exists.

## Verified strengths

- Current source tests pass 31/31 on R2026a; Code Analyzer evidence is reported as zero findings for the configured check.
- Configuration schema, dimensions, finite/range checks, current-profile handling, per-segment coolant conductance, target parsing, and several fault/variability paths have targeted tests.
- Coolant segment targeting, controller bounds/rates, energy residual checks, deterministic seeds, canonical result orientation, and Simscape mapper signal validation are represented in tests.
- Generated artifact and release manifests now use portable relative paths; the source ZIP and checksums were produced locally, and a private workspace path was not found in the regenerated manifests.
- The site supplies a frame data table, semantic controls, focus-visible styles, and reduced-motion behavior; quantitative data is labeled synthetic.
- Simscape product/policy gating returns an explicit `SKIPPED_*` status and does not fabricate a comparison.
- `PROVENANCE.md`, `THIRD_PARTY_NOTICES.md`, the OpenAI asset prompt record, MathWorks attribution, and non-endorsement language are present.

## Remediated during this review (verify again after the final regeneration)

Earlier review passes found and the current tree now tests/fixes: targeted coolant blockage (rather than global scaling), target-aware heat/current/contact/pump faults, pump-loss factor semantics, SOC/edge constraint metrics, deterministic metadata, advanced-controller cooling sign/rate bounds, canonical Simscape mapping, per-interface variability, scalar boundary unit wording, current-profile scalars, per-segment coolant conductance, malformed fault targets, stale E0-E9 gate checks, and portable artifact/release paths. These are not counted as current findings, but regenerated evidence must reflect the final 31-test tree.

## Provenance and copied MathWorks structure

Repository evidence shows a high-level MathWorks citation and an explicit independent-implementation statement in `README.md:129`, `PROVENANCE.md:7-17`, and `THIRD_PARTY_NOTICES.md:9-13`. I found no copied MathWorks source, prose, diagram, screenshot, numerical scenario, page structure, or example-specific identifier in the repository. The MATLAB project XML is ordinary project metadata; no repository evidence supports a claim that MathWorks structure was copied. This is an evidence-limited determination, not an external provenance investigation.

## 3-D extension addendum (2026-08-14)

After the original audit snapshot, the repository added an independently authored 3-D Cartesian graph extension, six dedicated tests, a deterministic E10 sensitivity study, and a manuscript evidence package. The complete local R2026a suite now passes **37/37**. The added study is explicitly synthetic, and the manuscript preserves the unresolved Simscape policy, sub-80% coverage advisory, absence of measured validation, and human-review requirement. This addendum records the expanded evidence; it does not convert the original audit into journal peer review or predictive validation.

## Conclusion (not a release approval)

The portable core is substantially stronger and the current source suite passes, but I do **not** approve release. At minimum, regenerate and reconcile all verification/docs/package evidence to the actual 31-test tree, decide the canonical metrics contract, and preserve the explicit R2024a/Simscape/coverage limitations. Resolve the provenance/license policy and release-action pinning before any public release; only then should a maintainer make a separate release decision.
