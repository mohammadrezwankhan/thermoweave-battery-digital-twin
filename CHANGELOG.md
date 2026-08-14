# Changelog

## [0.2.0] - 2026-08-14

### Added

- Backward-compatible 3-D cuboid and stacked-staggered graph topologies with layer coordinates, axis-labelled conductances, and six-face masks.
- A canonical 3x4x3 synthetic E10 scenario, 3-D renderer, deterministic sensitivity pipeline, CSV/JSON evidence, and two scientific figures.
- Six automated 3-D tests; the complete local MATLAB R2026a suite now passes 37/37.
- A journal-formatted manuscript source, DOCX, PDF, bibliography, literature review, originality matrix, and submission checklist.

### Limitations

- The 3-D study is synthetic and has no measured-cell or independent high-fidelity validation.
- Structural Simscape generation remains policy-gated; no Simscape integration claim is made.

All notable changes to ThermoWeave are recorded here. Release notes describe evidence-backed behavior and distinguish local verification from optional-product status.

## [Unreleased]

### Added

- Initial repository environment, contribution, security, licensing, and citation records.
- Reproducibility guidance and guarded GitHub Actions for core CI, optional Simscape integration, Pages documentation, and semver-tagged packaging.

### Verification

- Local baseline: MATLAB R2026a Update 4 on Windows 11 AMD64.
- Portable CI target: MATLAB R2024a or newer for the reduced-order core.

### Notes

- Simscape integration remains optional and manual, and must report an explicit skip when the required product is unavailable.
- No public release tag has been created by this initial repository record.
