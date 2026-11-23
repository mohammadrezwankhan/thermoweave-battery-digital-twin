# ThermoWeave third-party notices

Status: maintainer-maintained dependency inventory (reviewed 2026-11-21); independent legal/IP provenance clearance remains pending.

## MATLAB, Simulink, and related products

MATLAB®, Simulink®, Simscape™, and Simscape Battery™ are product and/or service marks of The MathWorks, Inc. Product names are used descriptively to identify the software that may be required to run this project. ThermoWeave is an independent project and is not sponsored, approved, or endorsed by The MathWorks, Inc. The MathWorks products, installers, libraries, and documentation remain subject to their applicable commercial terms; this repository does not redistribute them.

Documentation consulted for design context:

> MathWorks, "Build Model of Battery Module with Inter-Cell Heat Exchange," *MATLAB & Simulink Documentation*, <https://www.mathworks.com/help/simscape-battery/ug/build-battery-module-with-inter-cell-heat-exchange.html>, accessed 2026-08-14.

> MathWorks, "Model Heat Exchange Between Cells," *MATLAB & Simulink Documentation*, <https://www.mathworks.com/help/simscape-battery/ug/inter-cell-thermal-path-workflow.html>, accessed 2026-08-14.

> MathWorks, “Add Vectorized and Scalar Thermal Boundary Conditions to Battery Models,” *MATLAB & Simulink Documentation* (available since R2024a), <https://www.mathworks.com/help/simscape-battery/ug/battery-thermal-boundary-conditions-vectorized-scalar-example.html>, accessed 2026-08-13.

The citation above does not grant a license to copy source code, prose, diagrams, screenshots, numerical examples, or other protected material from the documentation.

## GitHub and GitHub Actions

GitHub-hosted repository and workflow services, if used, are provided under GitHub's terms. The workflow files reference these external actions; their source is not vendored here:

- `actions/checkout` commit `3d3c42e5aac5ba805825da76410c181273ba90b1` (v7.0.1, reviewed 2026-10-21), <https://github.com/actions/checkout>, MIT License.
- `actions/download-artifact` commit `9000827ccba6bdab643e8b6fd33ac0654aef8333` (v8.0.2, verified 2026-11-23), <https://github.com/actions/download-artifact>, MIT License.
- `actions/configure-pages` commit `45bfe0192ca1faeb007ade9deae92b16b8254a0d` (v6.0.0, reviewed 2026-10-21), <https://github.com/actions/configure-pages>, MIT License.
- `actions/upload-pages-artifact` commit `fc324d3547104276b827a68afc52ff2a11cc49c9` (v5.0.0, reviewed 2026-10-21), <https://github.com/actions/upload-pages-artifact>, MIT License.
- `actions/upload-artifact` commit `cf430e030ddbb5b0abf93d22962f4752f3646cd9` (v7.0.2, verified 2026-11-23), <https://github.com/actions/upload-artifact>, MIT License.
- `actions/deploy-pages` commit `368f82528645a54fb793d4d04e342629a3f51346` (v5.0.1, verified against workflow source 2026-11-21), <https://github.com/actions/deploy-pages>, MIT License.
- `matlab-actions/setup-matlab` commit `f9e43010f1ae678f7cfa0542fe2a4f60f7d1ad8d` (v3, reviewed 2026-10-21), <https://github.com/matlab-actions/setup-matlab>, BSD 3-Clause License.
- `matlab-actions/run-build` commit `cf54c2229a74d57eb4e6ba1bbebd45793d37797e` (v3, reviewed 2026-10-21), <https://github.com/matlab-actions/run-build>, BSD 3-Clause License.

The workflow references are pinned to the immutable commits recorded above; readable version comments remain beside the pins. Their source is not included in this repository, and the listed licenses are the upstream license classifications for the referenced actions, not a license grant for bundled code. Future updates require resolving and recording a new commit and reviewing any license change. GitHub trademarks remain the property of GitHub, Inc.; their appearance does not imply endorsement.

## Project-created assets

MATLAB source, model/configuration files, tests, figures, result summaries, and documentation created in this repository are project-created unless a file explicitly carries a third-party notice. Generated files should retain the metadata needed to reproduce them and must not be described as third-party or MathWorks-provided material.

The social preview `docs/assets/og.png` was generated for this project using OpenAI's image-generation service and is subject to the applicable OpenAI service terms. Its prompt record is stored in `docs/assets/og-prompt.md`. It does not incorporate a supplied third-party image and must not be presented as a measured thermal field.

## Vendoring statement and audit status

At initialization, no third-party code, assets, images, diagrams, datasets, binaries, or generated artifacts were vendored. In the maintainer's current inventory, no intentionally imported third-party source or datasets are identified; this claim awaits independent inspection and is not a legal approval. workflow references identify external actions but do not include their source. The included `docs/assets/og.png` is a project-specific OpenAI-generated social preview with a retained prompt record, not an imported third-party image, and remains subject to applicable OpenAI service terms. External products and services needed for development or execution are dependencies, not bundled content. This statement must be updated if that status changes.

## Notice maintenance

The source inventory is internal maintenance evidence, not independent chain-of-title or license clearance. `LICENSE` and `CITATION.cff` record MIT licensing only for contributions where the rights holder can lawfully grant it. That conclusion does not relicense MathWorks products or documentation, GitHub services or Actions, OpenAI services or generated-media terms, or any other third-party dependency. Before a public release, audit the tree and build/workflow configuration again for imported material, confirm the recorded action revisions, add applicable copyright and license text, and reconcile this notice with `PROVENANCE.md`.

## Actions runner compatibility

The updated checkout and MATLAB Actions use Node 24 and require Actions runner 2.327.1 or newer. Before manually dispatching the optional licensed Simscape workflow, the operator must verify the dedicated self-hosted runner meets that minimum and has the declared licensed products. Optional integration remains unvalidated until that workflow succeeds; the core hosted R2024a gate is separate. No authenticated Git operations inside Docker are used by these workflows.
