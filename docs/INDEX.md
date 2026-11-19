# ThermoWeave documentation index

Reviewed 2026-11-19 at source `5f29e34788b0f7ee58e2feeafc4df5d48a9a687a`. This reference separates implemented native graph behavior, standalone scalar teaching, preserved historical outputs and proposed follow-up work. [Read the handbook](reference/index.html) · [interactive lab](index.html) · [native lessons](native-lessons.html) · [learning paths](portfolio/index.html).

## Choose a reading path

Developers: start with setup and the worked examples, then inspect exact API/shape and equation contracts. Maintainers: read evidence, failure modes and CI/release gates before interpreting status. Owners: read scope, decisions and recovery before authorizing new claims or releases. No native MATLAB/browser execution, merge or deployed-content verification is implied by a documentation snapshot.

## Canonical required outputs

| Audience | Document | Purpose |
|---|---|---|
| Project | [README.md](../README.md) | Project entrypoint plus dated current-source clarification |
| Project | [CONTRIBUTING.md](../CONTRIBUTING.md) | Change/review/evidence workflow |
| Project | [CHANGELOG.md](../CHANGELOG.md) | Preserved history and documentation snapshot |
| Project | [CITATION.cff](../CITATION.cff) | Preserved author/version/date metadata |
| Project | [SECURITY.md](../SECURITY.md) | Existing vulnerability reporting/scope policy |
| Project | [ROADMAP.md](../ROADMAP.md) | Ten source-grounded proposals through 2027-11-18 |
| Navigation | [INDEX.md](INDEX.md) | Canonical navigation |
| Developer | [ARCHITECTURE.md](developer/ARCHITECTURE.md) | Execution/data boundaries |
| Developer | [SETUP_AND_REPRODUCIBILITY.md](developer/SETUP_AND_REPRODUCIBILITY.md) | Supported/observed environments and commands |
| Developer | [API_CLI_AND_INTERFACES.md](developer/API_CLI_AND_INTERFACES.md) | Call/input/output/failure contracts |
| Developer | [WORKED_EXAMPLES_AND_LABS.md](developer/WORKED_EXAMPLES_AND_LABS.md) | Runnable native examples and bounded arithmetic |
| Developer | [TROUBLESHOOTING.md](developer/TROUBLESHOOTING.md) | Recover from specific contract failures |
| Science | [EQUATIONS_AND_DERIVATIONS.md](math-and-physics/EQUATIONS_AND_DERIVATIONS.md) | Implemented signs, units, control/coolant/numerical derivations |
| Science | [PARAMETERS_AND_SYMBOLS.md](math-and-physics/PARAMETERS_AND_SYMBOLS.md) | Synthetic defaults, active fields and metric meanings |
| Science | [ASSUMPTIONS_AND_LIMITS.md](math-and-physics/ASSUMPTIONS_AND_LIMITS.md) | Physical, numerical and evidence validity boundaries |
| Maintainer | [VERIFICATION_EVIDENCE_LEDGER.md](maintainer/VERIFICATION_EVIDENCE_LEDGER.md) | Current/source/historical/unavailable statuses |
| Maintainer | [CI_CD_AND_RELEASE_PLAYBOOK.md](maintainer/CI_CD_AND_RELEASE_PLAYBOOK.md) | Actual configured triggers, policy and delivery gates |
| Maintainer | [TOOLCHAIN_AND_DEPENDENCY_MATRIX.md](maintainer/TOOLCHAIN_AND_DEPENDENCY_MATRIX.md) | Dependencies, capabilities and provenance limits |
| Maintainer | [FAILURE_MODES_AND_TECH_DEBT.md](maintainer/FAILURE_MODES_AND_TECH_DEBT.md) | Eleven documented source findings |
| Maintainer | [DOCS_MAINTENANCE_RUNBOOK.md](maintainer/DOCS_MAINTENANCE_RUNBOOK.md) | Canonical updates, renderer and review procedure |
| Owner | [ADR-0000-INDEX.md](owner/ADR/ADR-0000-INDEX.md) | Historical decisions and proposed decisions |
| Owner | [GOVERNANCE_AND_SCOPE.md](owner/GOVERNANCE_AND_SCOPE.md) | Authority and truthful-claim boundaries |
| Owner | [BUS_FACTOR_RECOVERY_RUNBOOK.md](owner/BUS_FACTOR_RECOVERY_RUNBOOK.md) | Successor recovery, reproduction and delivery |
| Owner | [PORTFOLIO_INTEGRATION.md](owner/PORTFOLIO_INTEGRATION.md) | This public project’s implemented/proposed exchange boundaries |

## Supporting catalogues

- [SOURCE_EVIDENCE.md](SOURCE_EVIDENCE.md): complete acquisition/accounting scope and reviewed-source links.
- [API_REFERENCE.md](developer/API_REFERENCE.md): all 47 callable MATLAB file functions, script and test-method list.
- [BROWSER_MODEL_CATALOG.md](developer/BROWSER_MODEL_CATALOG.md): all browser surfaces, exports and model boundaries.

## How to read the evidence

Source definitions are not runtime outcomes. The current tree defines 40 test methods; an older stored record says 37 passes. The source-head provider snapshot has six success checks and one skip, while local native and GUI execution remain unavailable. Follow the evidence ledger for exact identities and limits. Proposed roadmap items are future work, not hidden implementation changes. This package preserves scientific/application/test/config/workflow/result/license bytes and adds only documentation, narrow navigation and isolated documentation helpers.
