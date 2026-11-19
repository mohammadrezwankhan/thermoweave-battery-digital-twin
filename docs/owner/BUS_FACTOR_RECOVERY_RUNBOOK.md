# Recovery runbook for a new maintainer

The recovery goal is a reproducible, reviewed state with clear evidence. Possessing a checkout or historical report is insufficient to claim a working release. Preserve the source and logs before changing anything. [Setup](../developer/SETUP_AND_REPRODUCIBILITY.md) · [toolchain](../maintainer/TOOLCHAIN_AND_DEPENDENCY_MATRIX.md) · [release gates](../maintainer/CI_CD_AND_RELEASE_PLAYBOOK.md).

## Establish identity and access

Record repository URL, current branch, commit/tree, working changes and available tags/releases. Acquire access through the repository owner's legitimate GitHub and product-license administration; there is no credential, license key or secret recovery mechanism in this repository. Re-read current protection/rulesets and environment permissions. The 2026-11-19 author snapshot could not inspect classic protection, so that snapshot is not a complete merge policy.

Read `PROJECT_CHARTER.md`, `DECISIONS.md`, `SECURITY.md`, `PROVENANCE.md`, `THIRD_PARTY_NOTICES.md` and `AGENTS.md`. Preserve existing attribution/license/CFF metadata. Create an isolated working branch/check-out and avoid running any model callback or source generation until its inputs and side effects are reviewed. [PROJECT_CHARTER.md:1–43](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/PROJECT_CHARTER.md#L1-L43) [DECISIONS.md:1–83](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/DECISIONS.md#L1-L83) [AGENTS.md:1–10](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/AGENTS.md#L1-L10)

## Recover the core first

```matlab
startup
buildtool test
result = runDemo();
```

Use the configured R2024a core or record the actual supported release used. Save all native logs/products/results with the tested SHA. Compare schemas, topology order, selected numerical assertions and explicit skips. Source currently defines 40 test methods; discover actual executed/passed/incomplete counts rather than hard-coding that number as a runtime expectation. Historical 37-test and coverage values remain historical. [buildfile.m:1–102](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/buildfile.m#L1-L102) [artifacts/reports/verification.json:1–1](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/artifacts/reports/verification.json#L1-L1)

If native execution is unavailable, recover the reading surface and source inventory, mark native gates `NOT_RUN`, and keep the work reviewable. Do not substitute browser scalar arithmetic for the graph tests. For a tiny reproducible native problem use the equilibrium example; for 3-D mapping use the provided cuboid scenario before custom layouts. Review [known debt](../maintainer/FAILURE_MODES_AND_TECH_DEBT.md) before using multi-layer rectangular variability.

## Recover derived artifacts without losing history

Preserve original report/figure/web-data hashes. Generate new outputs in a disposable checkout, compare their manifests and record changes. `generateArtifacts` runs simulations, writes historical-facing reports/figures/data and invokes experiment/3-D studies. `writeVerificationReport` may reuse available JUnit based on limited mtimes; start clean for a release receipt. `packageRelease` archives selected roots and creates a manifest; its output does not prove a remote release exists. [tools/generateArtifacts.m:1–54](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/tools/generateArtifacts.m#L1-L54) [tools/writeVerificationReport.m:1–95](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/tools/writeVerificationReport.m#L1-L95) [tools/packageRelease.m:1–43](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/tools/packageRelease.m#L1-L43)

For the reference handbook, edit canonical Markdown, run `python docs/reference/build_reference.py`, and then `--check`. Restore a broken generated HTML from approved inputs. Do not overwrite the browser's teaching config or native result JSON to match a screenshot. The existing `docs/` upload path covers the handbook once ordinary integration and Pages gates complete.

## Recover optional modeling only with its owner decision

Relative to `ProjectRoot`, the adapter looks for `.satk/reuse-libraries.json` and `simscape/models/thermoweave-model-manifest.json`; neither is a tracked completed model in this snapshot. Resolve reusable-library policy through the intended modeling setup, verify licensed products, inspect any supplied model and callbacks, then run the manual comparison. `READY` from the gating function means prerequisites appear present, not that the model was built/tested. Preserve exact `SKIPPED_*` statuses. [simscape/buildThermoWeaveModel.m:1–105](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/simscape/buildThermoWeaveModel.m#L1-L105) [simscape/runSimscapeScenario.m:1–40](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/simscape/runSimscapeScenario.m#L1-L40)

## Restore publication and retain evidence

Check current Pages settings and run identities. After a reviewed candidate passes current policy/CI and merges normally, verify the actual deployed revision and reading routes in a supported browser. If a deployment regresses, use a reviewed forward fix or ordinary revert through the same protections; do not force-push or rewrite release history. Record the failure, recovery commit and new deployed identity.

Success means a successor can point to the exact source, commands, input/output hashes, real test statuses and remaining limits. If credentials, licenses, model policy, branch rules or an independent reviewer remain unavailable, name that boundary and stop the affected integration claim while retaining completed documentation work.
