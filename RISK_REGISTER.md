# ThermoWeave Risk Register

| ID | Risk | Likelihood | Impact | Mitigation / evidence |
|---|---|---:|---:|---|
| R1 | Synthetic parameters are mistaken for calibrated cell data | Medium | High | Prominent synthetic-data labels; no real-cell accuracy claim |
| R2 | Energy residual metric uses inconsistent flux signs | Medium | High | Shared flux implementation; convergence and accounting tests |
| R3 | Row/column mismatch silently changes node mapping | Medium | High | Column convention and validation/error tests |
| R4 | Controller benefit is overgeneralized | Medium | High | Predeclared E3 scenario-specific criterion; E7 is descriptive only; no universal AC benefit claim |
| R5 | Sensor dropout creates NaN propagation | Medium | Medium | Explicit estimator/fallback rule and dimension/fault metadata tests |
| R6 | Optional toolbox absence appears as success | Medium | High | `SKIPPED_MISSING_PRODUCT` evidence and product manifest |
| R7 | Simulink adapter violates local library policy | Medium | Medium | Gate structural work on `.satk` declaration |
| R8 | Web metrics drift from MATLAB outputs | Low | High | Full source configurations simulated before downsampling; schema/shape/hash-format checks; exported JSON only |
| R9 | Figures/animations are nondeterministic across renderers | Medium | Low | Fixed sizes, seed, theme, downsampling; hash only where stable |
| R10 | Repository includes credentials, caches, or private paths | Low | High | Ignore rules, secret scan, staged-file inspection, red-team review |
| R11 | Current GitHub action syntax changes | Low | Medium | Use current official major versions and cite upstream documentation |
| R12 | Publication occurs before evidence gates | Low | High | Separate packaging from remote publication; provenance/QA vetoes |
| R13 | Test coverage misses important branches | Medium | Medium | 31 focused tests and red-team cases; report measured coverage honestly; retain 80% advisory target |
| R14 | Structural Simscape adapter is mistaken for tested fidelity | Medium | High | Explicit `SKIPPED_LIBRARY_POLICY_UNRESOLVED`; no generated model or trend/accuracy claim |
