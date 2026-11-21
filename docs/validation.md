# Verification and numerical evidence

ThermoWeave separates implementation consistency from real-cell validation. The current evidence demonstrates behavior of the independently authored synthetic model; it does **not** establish predictive accuracy for a physical battery.

## Local evidence

Tested on MATLAB R2026a Update 4 on Windows 11. The class-based suite contains 37 tests:

- 16 unit tests for strict configuration validation, graph contracts, heat/SOC signs, coolant balance/targeting/per-segment conductance, declared variability interfaces, scalar/vector equivalence, and scalar current profiles;
- 9 integration tests for equilibrium, relaxation, energy residual and solver convergence, graph relabelling, prescribed vector mapping, coolant flow reversal, baseline/advanced controller constraints, and the predeclared E3 benefit criterion;
- 6 regression tests for deterministic seeded results, canonical schema/export traceability, fault metadata, Simscape mapper completeness/orientation, and explicit optional-integration status.
- 6 three-dimensional tests for cuboid counts and masks, axis conductances, Laplacian structure, one-layer reduction, 36-node canonical simulation, insulated-state conservation, and headless rendering.

Result: **37 passed, 0 failed, 0 incomplete** in the local run. Code Analyzer reported 0 errors, 0 warnings, and 0 informational findings over the prior configured source/adapter/example/tool check; the final 3-D branch is rechecked before publication. Statement coverage remains below the advisory 80% target; the exact regenerated rate is recorded in `artifacts/reports/verification.json`. This is a declared coverage gap, not a pass claim. The Simscape test accepts a real mapped result only when execution succeeds; otherwise it requires an explicit `SKIPPED_*` status. In the current repository state the adapter reports `SKIPPED_LIBRARY_POLICY_UNRESOLVED`.

## Latest public CI baseline (19 November 2026)

At source SHA `6b48646da2f6f8b60a13b14e19c4c65e45b17383`, [Core CI run 44626427308](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/actions/runs/44626427308) executed MATLAB R2024a with **40 total tests, 39 passed, 0 failed, 1 incomplete**. The incomplete test was `TestSimulationIntegration/advancedControllerCoolsHotZonesAndHonorsRate`, filtered by an unmet Optimization Toolbox assumption. The Code Analyzer reported 0 errors and 0 warnings across 47 checked files. This supersedes the *test count* in the dated local summary above, but does not supersede its numerical result values or constitute verification of later audit-branch changes. The [Pages deployment run](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/actions/runs/44626427373) also reported success for that SHA.


The energy accounting test requires a finite normalized residual and compares `ode15s` with `ode45` at an absolute temperature tolerance of $10^{-4}$ K for the declared short convergence case. The deterministic demo produced a normalized residual of approximately $4.39\times10^{-15}$ on R2026a. This residual is a consistency measure for the implemented flux bookkeeping, not an accuracy comparison against measurements.

## Audit candidate execution (21 November 2026)

At audit source/test SHA `a4d424d971fe14d59df6a9e3a9339cca4a437598`, [GitHub Core CI run 44959047806](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/actions/runs/44959047806) executed MATLAB R2024a: **54 total, 53 passed, 0 failed, 1 incomplete**. The original Optimization Toolbox-dependent advanced-controller test was still filtered; this is not an optional QP pass. Eight additional integration audit methods verify bounded clock behavior, exact off-grid thermal fault duration, independent adiabatic/ambient/coolant signed heat ledgers, versioned nested canonical hash behavior and truthful controller method/objective metadata. The six preexisting focused audit regressions also pass. This CI receipt does not verify proprietary Simscape parity, multi-release reproducibility, published data regeneration or legal provenance.

## Commands

```matlab
startup
results = runtests("tests", IncludeSubfolders=true)
buildtool test
```

The build task emits JUnit and Cobertura-compatible files under `results/`. On 2026-08-14, the public GitHub Core CI workflow provisioned MATLAB R2024a and completed the configured core build and tests successfully. This establishes the declared core path on the minimum release; it does not validate optional Simscape integration or physical-cell accuracy.

## Important interpretation of the energy diagnostic

The current core's `energyResidualNormalized` is an **instantaneous, algebraic RHS-closure check**: it computes both sides from the same derivative/flux calculation. Its normalization also uses the maximum individual generated-heat sample, not the global power scale described in the formal model specification. A near-machine-precision value therefore does **not** independently establish integrated conservation, accuracy of coolant energy transport, or correct event timing. The audit candidate additionally reports a signed, solver-time-integrated energy ledger and an endpoint-temperature stored-energy delta; adiabatic, ambient and coolant signed cases pass in R2024a. Broad solver tolerance/stiffness convergence and independently validated coolant-model physics remain open; neither metric proves measured-cell accuracy.

## Remaining validation work

- Resolve the custom Simulink-library declaration, generate the optional model, and record the exact licensed-product result.
- Add measured held-out cell/module data under compatible terms before making any predictive-accuracy statement.
- Perform solver/mesh reduction studies over a broader stiffness and fault envelope.
