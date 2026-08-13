# ThermoWeave third-party notices

Status: repository-wide provenance audit complete; workflow pin audit refreshed 2026-08-14.

## MATLAB, Simulink, and related products

MATLAB®, Simulink®, Simscape™, and Simscape Battery™ are product and/or service marks of The MathWorks, Inc. Product names are used descriptively to identify the software that may be required to run this project. ThermoWeave is an independent project and is not sponsored, approved, or endorsed by The MathWorks, Inc. The MathWorks products, installers, libraries, and documentation remain subject to their applicable commercial terms; this repository does not redistribute them.

Documentation consulted for design context:

> MathWorks, “Add Vectorized and Scalar Thermal Boundary Conditions to Battery Models,” *MATLAB & Simulink Documentation* (available since R2024a), <https://www.mathworks.com/help/simscape-battery/ug/battery-thermal-boundary-conditions-vectorized-scalar-example.html>, accessed 2026-08-13.

The citation above does not grant a license to copy source code, prose, diagrams, screenshots, numerical examples, or other protected material from the documentation.

## GitHub and GitHub Actions

GitHub-hosted repository and workflow services, if used, are provided under GitHub's terms. The workflow files reference these external actions; their source is not vendored here:

- `actions/checkout` commit `d23441a48e516b6c34aea4fa41551a30e30af803` (resolved from `v6` on 2026-08-14), <https://github.com/actions/checkout>, MIT License.
- `actions/configure-pages` commit `983d7736d9b0ae728b81ab479565c72886d7745b` (resolved from `v5` on 2026-08-14), <https://github.com/actions/configure-pages>, MIT License.
- `actions/upload-pages-artifact` commit `7b1f4a764d45c48632c6b24a0339c27f5614fb0b` (resolved from `v4` on 2026-08-14), <https://github.com/actions/upload-pages-artifact>, MIT License.
- `actions/deploy-pages` commit `d6db90164ac5ed86f2b6aed7e0febac5b3c0c03e` (resolved from `v4` on 2026-08-14), <https://github.com/actions/deploy-pages>, MIT License.
- `matlab-actions/setup-matlab` commit `2323adb8243827ea460b0def4c413545aaec46a9` (resolved from `v3` on 2026-08-14), <https://github.com/matlab-actions/setup-matlab>, BSD 3-Clause License.
- `matlab-actions/run-build` commit `ed1a00aeaf0b3e7946e28e8263eb5fe5ec232106` (resolved from `v3` on 2026-08-14), <https://github.com/matlab-actions/run-build>, BSD 3-Clause License.

The workflow references are pinned to the immutable commits recorded above; readable version comments remain beside the pins. Their source is not included in this repository, and the listed licenses are the upstream license classifications for the referenced actions, not a license grant for bundled code. Future updates require resolving and recording a new commit and reviewing any license change. GitHub trademarks remain the property of GitHub, Inc.; their appearance does not imply endorsement.

## Project-created assets

MATLAB source, model/configuration files, tests, figures, result summaries, and documentation created in this repository are project-created unless a file explicitly carries a third-party notice. Generated files should retain the metadata needed to reproduce them and must not be described as third-party or MathWorks-provided material.

The social preview `docs/assets/og.png` was generated for this project using OpenAI's image-generation service and is subject to the applicable OpenAI service terms. Its prompt record is stored in `docs/assets/og-prompt.md`. It does not incorporate a supplied third-party image and must not be presented as a measured thermal field.

## Vendoring statement and audit status

At initialization, no third-party code, assets, images, diagrams, datasets, binaries, or generated artifacts were vendored. At the final audit snapshot, no third-party code, assets, or data are vendored; workflow references identify external actions but do not include their source. The included `docs/assets/og.png` is a project-specific OpenAI-generated social preview with a retained prompt record, not an imported third-party image, and remains subject to applicable OpenAI service terms. External products and services needed for development or execution are dependencies, not bundled content. This statement must be updated if that status changes.

## Notice maintenance

The repository-wide provenance audit is complete for the local package. `LICENSE` and `CITATION.cff` may therefore identify original ThermoWeave contributions as MIT-licensed. That conclusion does not relicense MathWorks products or documentation, GitHub services or Actions, OpenAI services or generated-media terms, or any other third-party dependency. Before a public release, audit the tree and build/workflow configuration again for imported material, confirm the recorded action revisions, add applicable copyright and license text, and reconcile this notice with `PROVENANCE.md`.
