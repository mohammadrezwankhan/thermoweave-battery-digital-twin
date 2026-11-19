# CI, delivery and release playbook

Inspect the current workflow files and repository policy before a change. The source below is pinned to the documentation snapshot; provider settings can change independently. This package preserves every workflow byte, trigger, permission, matrix, pin and guard. The repository's [AGENTS.md](../../AGENTS.md) requires measured CI economics and prohibits removing required validation to create apparent savings. [AGENTS.md:1–10](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/AGENTS.md#L1-L10)

## Configured workflows

| Workflow | Triggers / runner | Job behavior and gate |
|---|---|---|
| `core-ci.yml` | Main push, PR to main, manual; Ubuntu, 30 min | R2024a `buildtool test`; readonly token; cancel only superseded PR runs |
| `no-codex-attribution.yml` | PR, merge group, main push and tags | Checks author/committer/co-author identities across selected commit range; readonly checkout |
| `pages.yml` | Main push/manual; Ubuntu | Validate source files, upload all `docs/`, deploy guarded main with Pages/id-token write only in deployment job |
| `deploy-dashboard.yml` | Main pushes affecting docs/assets/workflow and manual | Static validation; separate deploy condition is literal false in this source |
| `portfolio-dashboard-check.yml` | Selected PR/main/tag paths | Python source-path/config/HTML-marker validator |
| `simscape-integration.yml` | Manual only; self-hosted `thermoweave-simscape` | R2024a `integration` task selects the core `tests/integration` subset; 60 min. It does not invoke the adapter or enforce its product, library-policy or generated-model gates. |
| `release.yml` | `v*` tags; Ubuntu, 45 min | Semver guard, package build, archive checksum and GitHub release creation |

Sources: [.github/workflows/core-ci.yml:1–34](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/.github/workflows/core-ci.yml#L1-L34) [.github/workflows/no-codex-attribution.yml:1–99](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/.github/workflows/no-codex-attribution.yml#L1-L99) [.github/workflows/pages.yml:1–67](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/.github/workflows/pages.yml#L1-L67) [.github/workflows/deploy-dashboard.yml:1–82](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/.github/workflows/deploy-dashboard.yml#L1-L82) [.github/workflows/portfolio-dashboard-check.yml:1–24](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/.github/workflows/portfolio-dashboard-check.yml#L1-L24) [.github/workflows/simscape-integration.yml:1–28](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/.github/workflows/simscape-integration.yml#L1-L28) [.github/workflows/release.yml:1–60](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/.github/workflows/release.yml#L1-L60). No CircleCI/Buildkite configuration exists in the reviewed canonical tree; no account-level provider claim follows from that absence.

The manual workflow's name and runner label do not establish Simscape execution. `buildtool integration` selects `tests/integration`; the optional adapter status and mapper checks live in `tests/regression/TestRegressionContracts.m` and are included by the full `test` task. The adapter status test accepts `SKIPPED_*` outcomes, so even that test's success is not evidence that a generated model ran. A required real-model gate would be future work, separate from this documentation repair. [buildfile.m:15–33](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/buildfile.m#L15-L33) [tests/regression/TestRegressionContracts.m:76–110](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/tests/regression/TestRegressionContracts.m#L76-L110)

`pages.yml` uploads the existing `docs/` tree, so the static reference handbook is included without a new workflow. The dashboard workflow's disabled deployment job is separate from the active Pages workflow. A skipped duplicate deployment is not equivalent to a failed Pages deployment. Tags trigger the release path, so creating a tag is a publication operation, not a harmless way to test packaging.

## Before opening or updating a PR

1. Record base and candidate commits (or reproducible working-tree fingerprint before commit), scope and source inventory. Preserve native/scientific inputs in a documentation-only change.
2. Run applicable static documentation checks and any required native tests for the actual change. Keep environmental exclusions explicit. Do not edit workflow path filters or skip markers to evade checks.
3. Require independent review of source claims, equations, examples and permitted diff. Fix actual findings and bind new checks to the changed candidate.
4. Read branch protection/rulesets and requested reviewers. In this author's source snapshot, classic protection was inaccessible with 403; that blocks a complete merge-policy determination, not documentation authoring.
5. Use the legitimate authenticated author's supported signing/authorship route. The human-authorship policy must not be satisfied by forged author metadata, impersonation or suppressing assistance disclosure.

The source-head check table in [the ledger](VERIFICATION_EVIDENCE_LEDGER.md) is historical relative to a later candidate. Candidate success must identify head SHA, check context, provider run/job and conclusion. A synthetic merge or merge-queue revision also needs base/head mapping. Unknown required checks remain unknown.

## Native packaging gate

From a clean, licensed checkout:

```matlab
startup
buildtool package
```

`package` depends on coverage and docs/artifact tasks. Coverage below 80% is advisory in this implementation. Artifact generation creates reports/figures/web payloads and can change tracked generated files. Inspect all output records, actual test counts/skips, scenario hashes, source revision and archive checksum; do not infer fresh verification from old files left in the workspace. `writeVerificationReport` uses a limited test/src timestamp staleness heuristic, which does not prove every configuration/tool change was exercised. [buildfile.m:1–102](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/buildfile.m#L1-L102) [tools/writeVerificationReport.m:1–95](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/tools/writeVerificationReport.m#L1-L95) [tools/packageRelease.m:1–43](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/tools/packageRelease.m#L1-L43)

ZIP generation is described as reproducible by source comments, but archive timestamps and environment-dependent rendered bytes have not been verified for bitwise reproducibility here. Keep numerical reproducibility and archive byte identity separate. Packaging itself does not create a GitHub release; the tag-triggered workflow does. No new version/date/tag is assigned by this documentation package.

## Merge and publication evidence

After independent approval and all currently applicable policy/check gates, use the ordinary guarded merge route. Record source, tested head, documentation commit, merged commit and deployment identity separately. After Pages completes, inspect the live root, handbook, native lessons and learning-path links; check desktop/mobile overflow, navigation, keyboard focus, tables/formulas, retained controls and source identity in a supported browser. Record actual deployed content hashes where available. A provider deployment success without this page inspection is insufficient for a `PUBLICATION_VERIFIED` claim.

If publication fails, preserve the run log and serving revision, identify whether build, upload, deployment or content validation failed, and propose a focused repair. Do not disable security guards, replace source evidence with an older passing job or silently change repository visibility. Billed CI savings remain **UNKNOWN** without measured usage and current account pricing/allowances.
