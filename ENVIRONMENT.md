# ThermoWeave environment baseline

Status: observed baseline (2026-08-13), publication state refreshed 2026-08-14. This record describes the machine used for local verification and the portable minimum targeted by CI. It is not a guarantee that every optional product is available on another machine.

## Local verification baseline

| Capability | Observed value |
|---|---|
| Operating system | Windows 11, NT 10.0.26200, AMD64 |
| MATLAB | 26.1.0.3312084, R2026a Update 4 |
| Installed MATLAB products | MATLAB, Simulink, Simscape, Simscape Battery, Optimization Toolbox, Model Predictive Control Toolbox, MATLAB Test |
| Build system | MATLAB `buildtool` is available |
| Git | 2.53.0.windows.3 |
| Repository state | Committed `main` branch with GitHub `origin` at `mohammadrezwankhan/thermoweave-battery-digital-twin` |
| GitHub CLI | 2.97.0; authenticated publication completed 2026-08-14 |
| Node.js/npm | Not detected during the baseline audit |
| Website repository | No separate website repository detected inside this repository |

The local MATLAB release is newer than the portable target. Results marked as locally verified should include the exact release and product manifest; they must not be described as R2024a verification unless they were run there.

## Portable target and CI

The reduced-order core targets MATLAB R2024a or newer. Core CI runs on an Ubuntu GitHub-hosted runner with immutable-pinned MATLAB Actions configured for `R2024a`. The first published run installed R2024a but stopped at MATLAB startup because no usable MathWorks license was available; repository tests did not execute. R2024a is therefore a portability target, not a verified compatibility claim.

The full Simscape integration workflow is deliberately manual and requires a runner labelled `[self-hosted, thermoweave-simscape]`. That runner must have a licensed MATLAB installation and the products required by the selected integration task. A missing optional product is recorded as an explicit skip, never as a passing simulation.

## Reproducing the local setup

From the repository root:

1. Open MATLAB R2024a or newer and confirm the required products with `ver`.
2. Run `startup` to add the repository's `src` tree to the MATLAB path.
3. Run the build task used by the current `buildfile.m`, for example `buildtool test` for core tests. Use the task names documented by that buildfile; do not infer success from an empty output directory.
4. Record the MATLAB release, product list, Git revision, scenario/configuration hashes, random seed, solver/tolerance settings, and any explicit optional-product skip in the generated manifest.

The reproducibility guide in [`docs/reproducibility.md`](docs/reproducibility.md) defines the evidence expected for a release bundle.

## Environment hygiene

Credentials, license files, machine-specific settings, generated Simscape libraries, solver caches, and build outputs are intentionally excluded from version control. If a new external dependency or downloaded fixture is introduced, record its source, version, and license in `THIRD_PARTY_NOTICES.md` before release.
