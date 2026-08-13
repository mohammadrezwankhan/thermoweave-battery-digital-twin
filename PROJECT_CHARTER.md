# ThermoWeave Project Charter

## Purpose

ThermoWeave is an independently engineered MATLAB platform for studying how spatially and temporally varying thermal boundaries influence a synthetic multi-cell battery assembly. It is a design and reproducibility demonstrator, not a calibrated cell predictor or production controller.

## Product outcomes

1. A toolbox-light graph electrothermal core with deterministic entry points.
2. Scalar, per-cell, zonal, and coolant-propagation thermal boundary modes.
3. Baseline adaptive zonal cooling plus a product-gated advanced controller.
4. Seeded variability and declared fault scenarios.
5. A stable result contract consumed by tests, MATLAB visualization, and a static web case study.
6. An optional, honestly product-gated Simscape Battery comparison adapter.

## Scope boundaries

- All cell parameters and experiments are synthetic demonstration assumptions.
- The project makes no safety, certification, lifetime, or real-cell accuracy claim.
- The reduced-order core is the mandatory portable implementation.
- Simscape integration is optional and is never reported as tested unless it actually runs on a licensed installation.
- Publication, releases, and website deployment require authenticated access and satisfied gates.

## Acceptance gates

| Gate | Acceptance evidence |
|---|---|
| Provenance | `PROVENANCE.md`, notices, source/asset review, conservative claims |
| Scientific coherence | Equation/unit review, equilibrium and energy-accounting tests |
| Software quality | Fresh-clone demo, class-based tests, static analysis evidence |
| Simscape honesty | Tested manifest or explicit `SKIPPED_MISSING_PRODUCT`/policy-gated status |
| UX/accessibility | Data-traceable visuals, keyboard semantics, reduced-motion support |
| Documentation | Reproduction commands, limitations, scenario definitions, citation |
| Security/privacy | Secret scan, path review, generated/cache exclusions |
| Release presentation | Coherent README, artifacts, case study, package manifest |

## Decision authority

The primary integrator owns interfaces and final acceptance. Provenance and verification reviews may veto public claims or release status. A skipped optional integration cannot veto a core release when the skip is explicit and the required core gates pass.

## Definition of done

The local deliverable is complete when the core tests and deterministic demo pass in the detected MATLAB release, artifacts are generated from recorded manifests, optional-product status is truthful, documentation matches evidence, and a reproducible release bundle is produced. Remote publication is a separate authenticated action.
