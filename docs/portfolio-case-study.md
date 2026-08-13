# ThermoWeave portfolio case study

## Problem

Pack averages hide the spatial behavior that often drives thermal decisions. A single boundary temperature cannot explain inlet-to-outlet coolant warming, localized restrictions, uneven cell resistance, or a controller acting on zones. The project needed a transparent way to make those effects inspectable without requiring Simscape Battery for the core workflow.

## Approach

ThermoWeave represents cells as thermal graph nodes with independently generated rectangular or staggered geometry. Electrical current and SOC drive a deliberately compact heat model. Boundary providers supply scalar, per-cell, zonal, or coolant-marched temperature fields. The solver returns one stable `thermoweave.result/v1` structure that feeds metrics, tests, the MATLAB dashboard, deterministic artifacts, and the static website.

## Engineering decisions

- Kelvin is used internally; presentation layers convert to Celsius.
- Cell and zone arrays are explicit columns; histories are time-by-entity matrices.
- Coolant mode solves a finite-capacity flow balance rather than relabelling a constant vector.
- The baseline controller is always available, bounded, and rate-limited. Optional optimization records fallback status.
- Random variation is seeded and embedded in result metadata.
- The optional Simscape adapter stops with a machine-readable skip until product, policy, and generated-model gates are all satisfied.

## Demonstrated results

The locally generated compact bundle contains five website scenarios spanning scalar, vectorized, zonal, coolant, and sensor-fault cases. The default 30-second demo reached a peak temperature of 298.230683 K and a normalized energy-accounting residual of approximately $4.39\times10^{-15}$ on MATLAB R2026a Update 4. The automated suite passed 31 of 31 local tests; statement coverage remains below the declared advisory 80% target. These are synthetic implementation results, not measured accuracy evidence.

## Limitations

The graph nodes are lumped and isothermal. Parameter defaults are convenient synthetic assumptions. No ageing, runaway chemistry, electrochemical diffusion, or certified safety logic is modeled. Controller benefit is scenario-specific. Simscape structural generation is still gated by the repository's unresolved custom-library declaration and therefore no core-versus-Simscape numerical comparison is claimed.
