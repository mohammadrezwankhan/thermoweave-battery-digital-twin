# Verification and numerical evidence

ThermoWeave separates implementation consistency from real-cell validation. The current evidence demonstrates behavior of the independently authored synthetic model; it does **not** establish predictive accuracy for a physical battery.

## Local evidence

Tested on MATLAB R2026a Update 4 on Windows 11. The class-based suite contains 31 tests:

- 16 unit tests for strict configuration validation, graph contracts, heat/SOC signs, coolant balance/targeting/per-segment conductance, declared variability interfaces, scalar/vector equivalence, and scalar current profiles;
- 9 integration tests for equilibrium, relaxation, energy residual and solver convergence, graph relabelling, prescribed vector mapping, coolant flow reversal, baseline/advanced controller constraints, and the predeclared E3 benefit criterion;
- 6 regression tests for deterministic seeded results, canonical schema/export traceability, fault metadata, Simscape mapper completeness/orientation, and explicit optional-integration status.

Result: **31 passed, 0 failed, 0 incomplete** in the local run. Code Analyzer reported 0 errors, 0 warnings, and 0 informational findings over the configured 44-file source/adapter/example/tool check. Statement coverage remains below the advisory 80% target; the exact regenerated rate is recorded in `artifacts/reports/verification.json`. This is a declared coverage gap, not a pass claim. The Simscape test accepts a real mapped result only when execution succeeds; otherwise it requires an explicit `SKIPPED_*` status. In the current repository state the adapter reports `SKIPPED_LIBRARY_POLICY_UNRESOLVED`.

## Numerical tolerances

The energy accounting test requires a finite normalized residual and compares `ode15s` with `ode45` at an absolute temperature tolerance of $10^{-4}$ K for the declared short convergence case. The deterministic demo produced a normalized residual of approximately $4.39\times10^{-15}$ on R2026a. This residual is a consistency measure for the implemented flux bookkeeping, not an accuracy comparison against measurements.

## Commands

```matlab
startup
results = runtests("tests", IncludeSubfolders=true)
buildtool test
```

The build task emits JUnit and Cobertura-compatible files under `results/`. On 2026-08-14, the public GitHub Core CI workflow provisioned MATLAB R2024a and completed the configured core build and tests successfully. This establishes the declared core path on the minimum release; it does not validate optional Simscape integration or physical-cell accuracy.

## Remaining validation work

- Resolve the custom Simulink-library declaration, generate the optional model, and record the exact licensed-product result.
- Add measured held-out cell/module data under compatible terms before making any predictive-accuracy statement.
- Perform solver/mesh reduction studies over a broader stiffness and fault envelope.
