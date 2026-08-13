# ThermoWeave roadmap

This roadmap follows the acceptance gates in `PROJECT_CHARTER.md`. Dates are intentionally omitted until a reproducible scope and owner are available.

## Near term: portable core

- Complete the graph electrothermal solver and canonical `thermoweave.result/v1` contract.
- Add scalar, per-cell, zonal, and coolant-propagation boundary modes with unit and energy-accounting tests.
- Implement bounded baseline control, seeded variability, declared faults, and deterministic demo artifacts.
- Establish MATLAB R2024a core CI and record local R2026a verification separately.

## Next: evidence and usability

- Add result manifests, hashes, scenario summaries, and data-traceable visual exports.
- Complete accessibility checks for the static case study and document reduced-motion behavior.
- Publish reproducibility bundles only after fresh-clone, test, provenance, and security gates pass.

## Optional integration

- Resolve the custom-library policy for `simscape/`.
- Add a product-detected Simscape Battery adapter that maps into the canonical result schema.
- Keep integration manual and self-hosted until licensed-product and structural-generation checks are reproducible.

## Later release work

- Add an evidence-backed advanced controller behind explicit product and solver gates.
- Re-audit all imported actions, datasets, media, and generated assets before a public semver release.
- Consider authenticated Pages or package publication only after the repository has a configured remote and release owner.
