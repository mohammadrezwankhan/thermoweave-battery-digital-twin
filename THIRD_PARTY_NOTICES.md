# ThermoWeave third-party notices

Status: repository-wide provenance audit complete for the local package (2026-08-13).

## MATLAB, Simulink, and related products

MATLAB®, Simulink®, Simscape™, and Simscape Battery™ are product and/or service marks of The MathWorks, Inc. Product names are used descriptively to identify the software that may be required to run this project. ThermoWeave is an independent project and is not sponsored, approved, or endorsed by The MathWorks, Inc. The MathWorks products, installers, libraries, and documentation remain subject to their applicable commercial terms; this repository does not redistribute them.

Documentation consulted for design context:

> MathWorks, “Add Vectorized and Scalar Thermal Boundary Conditions to Battery Models,” *MATLAB & Simulink Documentation* (available since R2024a), <https://www.mathworks.com/help/simscape-battery/ug/battery-thermal-boundary-conditions-vectorized-scalar-example.html>, accessed 2026-08-13.

The citation above does not grant a license to copy source code, prose, diagrams, screenshots, numerical examples, or other protected material from the documentation.

## GitHub and GitHub Actions

GitHub-hosted repository and workflow services, if used, are provided under GitHub's terms. The workflow files reference these external actions; their source is not vendored here:

- `actions/checkout@v6`, <https://github.com/actions/checkout>, MIT License.
- `actions/configure-pages@v5`, <https://github.com/actions/configure-pages>, MIT License.
- `actions/upload-pages-artifact@v4`, <https://github.com/actions/upload-pages-artifact>, MIT License.
- `actions/deploy-pages@v4`, <https://github.com/actions/deploy-pages>, MIT License.
- `actions/upload-artifact@v4`, <https://github.com/actions/upload-artifact>, MIT License.
- `matlab-actions/setup-matlab@v3`, <https://github.com/matlab-actions/setup-matlab>, BSD 3-Clause License.
- `matlab-actions/run-build@v3`, <https://github.com/matlab-actions/run-build>, BSD 3-Clause License.

These major-version references are intentionally readable but mutable. Their source is not included in this repository, and the listed licenses are the upstream license classifications for the referenced actions, not a license grant for bundled code. Before a public release, audit the resolved commits and pin immutable revisions, record the resolved revisions and notices, and review any license change. GitHub trademarks remain the property of GitHub, Inc.; their appearance does not imply endorsement.

## Project-created assets

MATLAB source, model/configuration files, tests, figures, result summaries, and documentation created in this repository are project-created unless a file explicitly carries a third-party notice. Generated files should retain the metadata needed to reproduce them and must not be described as third-party or MathWorks-provided material.

The social preview `docs/assets/og.png` was generated for this project using OpenAI's image-generation service and is subject to the applicable OpenAI service terms. Its prompt record is stored in `docs/assets/og-prompt.md`. It does not incorporate a supplied third-party image and must not be presented as a measured thermal field.

## Vendoring statement and audit status

At initialization, no third-party code, assets, images, diagrams, datasets, binaries, or generated artifacts were vendored. At the final audit snapshot, no third-party code, assets, or data are vendored; workflow references identify external actions but do not include their source. The included `docs/assets/og.png` is a project-specific OpenAI-generated social preview with a retained prompt record, not an imported third-party image, and remains subject to applicable OpenAI service terms. External products and services needed for development or execution are dependencies, not bundled content. This statement must be updated if that status changes.

## Notice maintenance

The repository-wide provenance audit is complete for the local package. `LICENSE` and `CITATION.cff` may therefore identify original ThermoWeave contributions as MIT-licensed. That conclusion does not relicense MathWorks products or documentation, GitHub services or Actions, OpenAI services or generated-media terms, or any other third-party dependency. Before a public release, audit the tree and build/workflow configuration again for imported material, pin and record action revisions, add applicable copyright and license text, and reconcile this notice with `PROVENANCE.md`.
