# ThermoWeave engineering audit — CI and optional Simscape verification

**Report date:** 2026-11-21  
**Baseline:** `6b48646da2f6f8b60a13b14e19c4c65e45b17383`  
**Candidate:** `audit/thermoweave-engineering-20261121`

## Live provider evidence obtained for the baseline

| Workflow/job | Run and evidence | Observed provider result | Correct interpretation |
|---|---|---|---|
| Core CI / MATLAB R2024a core build | [Run 44626427308](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/actions/runs/44626427308), job `135921365013`, 2026-11-19 | **SUCCESS**. `Test Summary: Total Tests: 40; Passed: 39; Failed: 0; Incomplete: 1`. Code Analyzer 47 files, Errors: 0, Warnings: 0. | The incomplete test was `TestSimulationIntegration/advancedControllerCoolsHotZonesAndHonorsRate`: **Filtered by assumption**; Optimization Toolbox-dependent success was **not** proved |
| Human authorship policy | [Run 44626427276](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/actions/runs/44626427276) | **SUCCESS** at baseline | Policy check is not substitute for science |
| Documentation Pages | [Run 44626427373](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/actions/runs/44626427373), build job `135921364487`, deploy job `135921471303` | **SUCCESS**. Deploy log says `Reported success!` with URL `https://mohammadrezwankhan.github.io/thermoweave-battery-digital-twin/` and baseline SHA | Confirms provider deployment for baseline; does not establish browser responsiveness, mathematical data parity or accessibility |
| Flagship dashboard | [Run 44626427370](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/actions/runs/44626427370) | Static validation **SUCCESS**, its secondary deploy job **SKIPPED** | The primary Pages workflow deploys; a conditional skipped second deploy is not a deployment failure |

The baseline Core CI uses pinned immutable revisions of `actions/checkout`, `matlab-actions/setup-matlab` and `matlab-actions/run-build`, GitHub-hosted Ubuntu runner, MATLAB `R2024a`, and `tasks: test` (`check` is an explicit dependency in `buildfile.m`). Core CI covers pushes to `main`, PRs to `main`, and manual dispatch. Deployment has scoped `pages: write` and `id-token: write` permissions on the guarded deployment job. The optional integration workflow is dispatch-only on `[self-hosted, thermoweave-simscape]` with a 60-minute timeout.

The human-authorship policy is a required `main` status context. Protected-branch configuration was readable only in limited form; no rules were modified or bypassed.

## Baseline versus candidate execution

- **Baseline MATLAB tests:** 40 total, **39 PASS / 0 FAIL / 1 INCOMPLETE**; **not** 40 clean passes.
- **Candidate MATLAB tests:** Six new regression tests were authored in `tests/unit/TestAuditRegressions.m` for scientific, control and serialization defects. **The six methods passed in [candidate CI run 44945399849](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/actions/runs/44945399849), job 136971493310: 46 total, 45 PASS, 0 FAIL, 1 optional INCOMPLETE at source/test SHA 0287e46.** A PR creation or green historical badge is not candidate execution evidence.
- **Local MATLAB execution:** **BLOCKED_ENVIRONMENT**. No MATLAB/Octave executable is provided to the connected audit session.
- **Enhanced R2026a verification:** **NOT RUN** against the audit branch. Committed 2026-08-14 JSON documents a different SHA.
- **Artifact regeneration:** **NOT RUN** against the branch. Existing `artifacts/` values may be historical.
- **Independent energy and control checks:** Six focused new tests PASS on R2024a candidate; broad independent integrated energy, event timing, and controller clock **remain NOT VERIFIED**.

## Why optional advanced and Simscape checks remain blocked

### Advanced controller

`src/+thermoweave/+control/advancedController.m` invokes `quadprog` only if available, otherwise deliberately calls the bounded baseline. The test `advancedControllerCoolsHotZonesAndHonorsRate` uses `assumeEqual(info.status,'OPTIMAL')`, which marks missing `quadprog` as an **incomplete/filtered test**, not a passing optimized-control run. Recorded controller success metadata should identify actual QP execution vs fallback. The current result schema does not preserve successful per-update QP status/objective.

### Simscape

`simscape/buildThermoWeaveModel.m` checks installed Simulink/Simscape/Simscape Battery, then custom-library policy at `.satk/reuse-libraries.json`, then a generated model manifest under `simscape/models`. It returns explicit `SKIPPED_MISSING_PRODUCT`, `SKIPPED_LIBRARY_POLICY_UNRESOLVED` or `SKIPPED_MODEL_NOT_GENERATED` rather than generating fake measurements. `simscape/runSimscapeScenario.m` maps real output only if a verified generated model is ready.

**No licensed integration was run here.** There is no evidence of a real Simscape temperature/energy parity comparison and no permission to assert its PASS. A required missing proprietary toolbox/license is an environmental blocker, not licenseable evidence that the model is valid.

## CI security and governance review

- Immutable pinned workflow actions and default read-only tokens are present in inspected workflows.
- Manual Simscape self-hosted runner may execute sensitive workloads; enforce authorization and threat isolation before running untrusted PR branches.
- Static Pages publishing is guarded to `main`; documentation/dashboard validation does not check native MATLAB science.
- No workflow was altered to skip, ignore or weaken failing tests. No branch protection or permissions changed.
- `LICENSE`, `PROVENANCE.md`, `THIRD_PARTY_NOTICES.md`, `CITATION.cff`, `SECURITY.md`, `RISK_REGISTER.md` and `RED_TEAM_REPORT.md` are present but not a substitute for an independent legal/IP evidence review.

## Verification table

| Gate | Status | Next required evidence |
|---|---|---|
| Core R2024a baseline | **PASS** within tested baseline scope | Existing provider job logs |
| New audit-branch regression suite | **PASS** for six new tests (46 total, 45 PASS, 0 FAIL, 1 optional INCOMPLETE) | [Core CI run 44945399849](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/actions/runs/44945399849), job 136971493310, source/test SHA 0287e46 |
| Optional QP-specific algorithm | **SKIP_OPTIONAL_DEPENDENCY** baseline | Authorized licensed Optimization Toolbox `quadprog` trial |
| Licensed Simscape core parity | **BLOCKED_ENVIRONMENT** | Licensed authorized runner, resolved custom-library policy, generated model and numerical comparison |
| Dynamic coolant validation | **NOT VERIFIED** | Model-form specification and physically independent energy tests |
| Pages provider deployment baseline | **PASS** provider workflow | Browser/site accessibility and source-artifact parity separately |
| Dashboard numerical parity | **NOT VERIFIED** | Rebuild from canonical result under same MATLAB version and inspect site values |
| Full physics acceptance | **FAIL / NOT VERIFIED** | Integrated energy residual, controller sample/event alignment and solver convergence |
| Governance claims | **NOT VERIFIED** | Independent licensing/provenance confirmation |

**CI/Simscape conclusion:** R2024a baseline CI succeeds with a documented optional incomplete test. This cannot certify candidate fixes or optional Simscape parity; remaining scientific assurance is **INCOMPLETE**.

## Candidate pull request provider visibility (initial check)

[Draft PR #20](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/pull/20) was opened from this audit branch into protected `main`. Immediately after PR creation, a provider read of the source head `98209edcff50a7da139675113cd6ec76de2055f5` returned **no GitHub Actions workflow runs** and no test check runs yet. Three external check suites (Sentry, Codemagic CI/CD, Buildkite) were visible as **queued**. Queued check suites are **not** test execution and may never result in runnable MATLAB jobs. This initial snapshot is transitory; refresh the exact PR head SHA, workflows and logs rather than relying on these initial states. No failed or pending candidate test has been described as passed.

## Verified post-PR MATLAB execution

**Verified candidate-source MATLAB R2024a CI:** [run 44945399849](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/actions/runs/44945399849), job `136971493310`, on source/test SHA `0287e46ed273d3154e0bed9309a318a809702683`: **46 total, 45 PASSED, 0 FAILED, 1 INCOMPLETE** (optional advanced-controller test filtered by unmet Optimization Toolbox assumption). Code Analyzer reports 0 errors and 0 warnings. The six new regression methods executed in this passing run; unrun scientific acceptance gates remain unverified. The report-update commit follows this receipt and must itself be checked at its final SHA.

This updates the **initial** check-suite snapshot above, which captured statuses before the provider queued/ran Actions. The optional Simscape workflow remains unexecuted and no CI badge constitutes physical safety validation.
