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
