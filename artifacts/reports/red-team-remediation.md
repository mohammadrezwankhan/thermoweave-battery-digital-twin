# Red-team remediation disposition

Date: 2026-08-13

Scope: local ThermoWeave package candidate

This disposition supplements, but does not rewrite, `RED_TEAM_REPORT.md`. The report records the adversarial snapshot and its original recommendation. The final package pipeline ran after that snapshot.

## Closed after the report snapshot

- **RB-1 stale verification evidence:** regenerated reports now record 31 tests, 31 passed, 0 failed, 0 incomplete; the artifact manifest embeds the same values.
- **H-1 canonical metrics overclaim:** `docs/model.md` now distinguishes canonical metrics, boundary diagnostics, and experiment-specific fault metrics.
- **M-3 MIT/provenance inconsistency:** the independent provenance auditor completed the repository-wide audit, approved MIT for original ThermoWeave contributions, and preserved external terms in `PROVENANCE.md` and `THIRD_PARTY_NOTICES.md`.
- **L-1 patch hygiene:** `git diff --check` passes.
- The final source check covers 44 MATLAB source, adapter, example, and tool files with zero findings.
- The release ZIP was exercised from an isolated temporary extraction: `startup`, 31 tests, `runDemo`, `generateArtifacts`, and `generateDocs` all passed.

## Open publication gates

- Core CI has not yet run on the documented minimum MATLAB R2024a target.
- Simscape integration remains `SKIPPED_LIBRARY_POLICY_UNRESOLVED`; no high-fidelity comparison claim is made.
- Statement coverage is 60.0%, below the advisory 80% target.
- GitHub Action references use reviewed major-version tags rather than immutable commit pins.
- The website JSON performs schema, shape, and scenario-hash-format checks, not cryptographic payload verification in the browser.
- No GitHub remote, release, Pages deployment, or personal-site integration has occurred.

## Decision

The provenance auditor returned **APPROVE LOCAL PACKAGE**. Public release is not approved until the publication gates above are deliberately resolved or accepted through the documented owner workflow.
