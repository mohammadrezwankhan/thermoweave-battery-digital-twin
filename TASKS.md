# ThermoWeave Task Ledger

Status values: `DONE`, `BLOCKED`, `SKIPPED`, `FAILED`, `IN_PROGRESS`, `PENDING`.

| Phase | Work item | Status | Evidence |
|---|---|---|---|
| 0 | Environment, product, Git, GitHub, and site audit | DONE | `ENVIRONMENT.md`; MATLAB R2026a Update 4; Git present; no remote/`gh`/site repo |
| 1 | Charter and architecture contracts | DONE | `PROJECT_CHARTER.md`, `ARCHITECTURE.md`, `DECISIONS.md`, `RISK_REGISTER.md` |
| 1 | Initial provenance and notices | DONE | `PROVENANCE.md`, `THIRD_PARTY_NOTICES.md`; final release audit pending |
| 1 | Scientific equations and experiment declarations | DONE | `docs/model.md`, `docs/scenarios.md` |
| 2 | Reduced-order core and boundary modes | DONE | `src/+thermoweave`, `config/`, `runDemo.m` |
| 3 | Control, variability, uncertainty, and faults | DONE | Controller/fault/variability packages; E0-E9 experiment manifest |
| 4 | Optional Simscape adapter | SKIPPED | `SKIPPED_LIBRARY_POLICY_UNRESOLVED`; canonical mapper and explicit adapter gate are tested |
| 5 | Visualization and deterministic artifacts | DONE | `artifacts/`; MATLAB dashboard; PNG/GIF/JSON/manifests |
| 6 | Documentation, CI, and release metadata | DONE | README, technical docs, `buildfile.m`, workflows, community files |
| 7 | Data-driven static website | DONE | `docs/index.html`; accessible canvas table; source-data validation; not deployed |
| 8 | Independent red-team review and remediation | DONE | `RED_TEAM_REPORT.md`; source findings remediated; final regeneration resolves snapshot RB-1; public-release limitations retained |
| 9 | Verified local release package | DONE | `release/thermoweave-source.zip`, `release/release-manifest.json`; final rebuild follows audit report |
| 9 | GitHub repository, Pages, PR, and tagged release | SKIPPED | No remote and GitHub CLI unavailable; owner commands in `docs/deployment.md` |
