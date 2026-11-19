# Contributing to ThermoWeave

Thank you for helping improve ThermoWeave. Contributions should preserve the project's scope: this is a synthetic, reproducibility-focused demonstrator, not a calibrated cell predictor, safety controller, or certification artifact.

## Before opening a change

- Read `PROJECT_CHARTER.md`, `ARCHITECTURE.md`, `PROVENANCE.md`, and `THIRD_PARTY_NOTICES.md`.
- Keep public claims tied to reproducible evidence. Do not add real-cell, safety, lifetime, or performance claims without a declared method and review.
- Keep the reduced-order core portable to MATLAB R2024a or newer. Treat Simscape Battery as optional and report product-gated skips honestly.
- Do not commit credentials, license files, generated Simscape libraries, caches, or machine-specific paths.

## Local workflow

Work from the repository root and use a supported MATLAB release. Run `startup` before invoking source entry points. Use the task names in `buildfile.m`; the normal core check is:

```matlab
buildtool test
```

Run the deterministic demo and any scenario-specific checks required by the change. Review generated manifests for release, product, seed, solver/tolerance, and hash metadata. Keep generated outputs in the ignored directories described by `.gitignore`.

Optional Simscape integration belongs on a licensed runner labelled `self-hosted, thermoweave-simscape` and must remain behind the manual integration workflow. A missing product is a recorded skip, not a reason to fabricate output.

## Change guidelines

- Preserve the contracts in `ARCHITECTURE.md`, especially column-vector ordering, units, result schema, and failure semantics.
- Add or update tests for changed equations, units, dimensions, boundary modes, controller limits, faults, and result metadata.
- Update scenario, provenance, notice, reproducibility, changelog, or roadmap documentation when behavior or dependencies change.
- Keep commits focused and explain any intentional compatibility or numerical change.
- Use pull requests for review. CI must pass, and changes affecting scientific claims or release status need an evidence-oriented review.

## Pull request checklist

- [ ] Core tests and deterministic demo pass on the local supported release.
- [ ] Optional-product status is explicit and truthful.
- [ ] No secrets, private paths, generated files, or unreviewed third-party material are included.
- [ ] Documentation, citation, provenance, and notices match the change.
- [ ] `git diff --check` is clean.

## Documentation evidence workflow — 2026-11-19

Use [docs/INDEX.md](docs/INDEX.md) for canonical Developer/Maintainer/Owner material. New claims require immutable source links, exact units/shapes/failure semantics, and a clear distinction between source inspection, actual execution, historical results and proposals. Do not relabel an old native report after editing documentation. Keep public material limited to this repository's approved public evidence.

For the static reading guide, edit Markdown/CFF, run `python docs/reference/build_reference.py`, then `python docs/reference/build_reference.py --check`. `node docs/reference/check_lesson.cjs` checks the existing pure teaching model's eight fixtures; `python scripts/portfolio/validate_guide.py` checks the existing source-linked guide. These do not replace native tests or supported-browser review. [Maintenance runbook](docs/maintainer/DOCS_MAINTENANCE_RUNBOOK.md).

The independent reviewer must inspect the exact candidate and permitted diff. The author cannot certify independent QA. Native-science changes require their own focused reproduction and review; documented defects in a docs-only change are proposals until implemented separately. Use legitimate authorship/signature and current protected-branch rules for integration; unavailable policy/check evidence stays unresolved.
