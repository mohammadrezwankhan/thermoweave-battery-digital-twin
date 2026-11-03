# CI maintenance

## CI economics

- Inspect workflow events and required check names before changes. Preserve security, permissions, required contexts, tests, matrices, supported platforms, release guards, deployment gates, and reproducibility evidence.
- Run PR validation once per change: use `pull_request` and limit redundant push validation to the actual default or release branches. Preserve merge-queue, tag, release, manual, scheduled, and deployment events. Do not use path filters or skip markers to evade required checks.
- Cancel only superseded PR validation with a workflow and event specific group keyed by PR number, falling back to run ID. Keep manual, scheduled, release, and deployment runs isolated; a PR must never cancel production work.
- Reuse compatible jobs and the smallest suitable standard runner. Set timeouts from observed runtime plus headroom. Cache package downloads by OS, runtime, and lockfile; never cache credentials. Install committed locks and update manifests and locks together. Measure before reducing a matrix or moving tests off PRs.
- Default tokens to read only, pin third party actions to immutable commits, isolate untrusted PR code, and scope publication permissions to guarded jobs. Keep transient artifacts for 7–14 days; retain release and compliance evidence by project policy. Do not delete evidence as cleanup.
- Batch compatible dependency maintenance and avoid extra scheduled or policy workflows. Validate YAML, event behavior, check dependencies, and deployment guards. Record remote outcomes; report run/job counts and elapsed time separately from billed usage. State savings as UNKNOWN unless billed usage, current prices, and account allowances are measured.
