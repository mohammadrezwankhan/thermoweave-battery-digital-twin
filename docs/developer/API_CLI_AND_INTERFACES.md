# APIs, commands and data contracts

This guide describes the public call surface of source `5f29e34788b0f7ee58e2feeafc4df5d48a9a687a`. [All file entrypoints and signatures](API_REFERENCE.md) and [browser contracts](BROWSER_MODEL_CATALOG.md) provide the complete inventories. Runtime availability and actual observations appear in the [evidence ledger](../maintainer/VERIFICATION_EVIDENCE_LEDGER.md).

## MATLAB entrypoints

| Call | Inputs and result | Failure or side-effect boundary |
|---|---|---|
| `startup()` | Returns repository root and adds three source paths | Does not add `examples`; modifies MATLAB path |
| `runDemo()` / `runDemo(source, exportPath)` | 30 s default demo, or supplied scenario; canonical result | Optional path writes downsampled JSON; no-output call prints a summary |
| `thermoweave.simulate(source, seed)` | `source=[]`, JSON path or struct; optional seed override; canonical result | Seed override occurs after loader validation; simulation can raise dimension/solver errors |
| `thermoweave.run(source, ...)` | Alias of `simulate` | Requires source argument in wrapper |
| `thermoweave.thermal.simulate(...)` / `integrate(...)` | Forwarding compatibility aliases | Ultimately same solver, not a second implementation |
| `thermoweave.config.loadScenario(source)` | Deep merges defaults and supplied struct/JSON | Missing file, invalid JSON/type/schema and invalid domain errors |
| `thermoweave.results.exportJSON(result,path,stride)` | JSON plus hash/path/character-count manifest | Creates directories and writes; use positive integer stride despite weaker validation |

Source: [runDemo.m:1–11](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/runDemo.m#L1-L11) [src/+thermoweave/simulate.m:1–102](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/src/%2Bthermoweave/simulate.m#L1-L102) [src/+thermoweave/+config/loadScenario.m:1–31](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/src/%2Bthermoweave/%2Bconfig/loadScenario.m#L1-L31) [src/+thermoweave/+results/exportJSON.m:1–12](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/src/%2Bthermoweave/%2Bresults/exportJSON.m#L1-L12).

## Configuration

The root schema string is `thermoweave.config/v1`. Sections include `scenario`, `simulation`, `layout`, `cell`, `thermal`, `electrical`, `boundary`, `controller`, `variability`, `faults`, `metrics`. Unknown extra fields survive recursive merging; acceptance by the loader does not mean a field is consumed by the solver. The validator accepts scalar or matching element counts for many cell/zone values and downstream code flattens vectors; older prose saying all row vectors are rejected is stronger than current implementation. [src/+thermoweave/+config/loadScenario.m:1–31](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/src/%2Bthermoweave/%2Bconfig/loadScenario.m#L1-L31) [src/+thermoweave/+config/validateConfig.m:1–392](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/src/%2Bthermoweave/%2Bconfig/validateConfig.m#L1-L392)

Cell count must equal rows × columns × layers. State/thermal/electrical fields are scalar or node-sized where the validator checks that size. Supported layouts are rectangular, staggered, cuboid and stacked-staggered; boundary modes are scalar, vector, zonal and coolant. Controller aliases `openloop/ol/none`, `baseline` and `advanced/ac` are recognized. Current profile is empty, a constant scalar, a vector on implicit second-spaced times, or a `time_s`/`current_A` struct using previous-value interpolation/extrapolation. It is not a general per-node time-series matrix contract. [src/+thermoweave/+config/validateConfig.m:1–392](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/src/%2Bthermoweave/%2Bconfig/validateConfig.m#L1-L392) [src/+thermoweave/simulate.m:63–72](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/src/%2Bthermoweave/simulate.m#L63-L72)

Fault windows include both endpoints. Targets identify cells, edges, zones or coolant segments depending on type. Physical-parameter faults can use an empty target for all elements, while sensor/actuator handlers have narrower target assumptions; use explicit valid targets for those paths. Configured events are logged from declarations, including events outside the simulated window; their presence alone is not proof that an effect occurred or a detector found a fault. [src/+thermoweave/+uncertainty/applyFaults.m:1–34](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/src/%2Bthermoweave/%2Buncertainty/applyFaults.m#L1-L34) [src/+thermoweave/simulate.m:34–48](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/src/%2Bthermoweave/simulate.m#L34-L48) [src/+thermoweave/simulate.m:69–84](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/src/%2Bthermoweave/simulate.m#L69-L84)

## Canonical result

Let `Nt` be stored times, `N` cells and `Z` zones. All temperature computation/persisted canonical arrays use K; plotting/export conversion to °C subtracts 273.15. A temperature difference in K has the same magnitude as a difference in °C.

| Field | Shape / units | Meaning |
|---|---|---|
| `schemaVersion` | string | `thermoweave.result/v1` |
| `time_s` | `Nt×1`, s | Output grid plus final duration if required |
| `state.temperature_K`, `state.soc` | `Nt×N`, K / fraction | Temperature and un-clipped integrated SOC |
| `boundary.temperature_K`, `boundary.conductance_W_per_K` | `Nt×N`, K / W K⁻¹ | Effective sampled boundary |
| `control.zoneCommand` | `Nt×Z`, dimensionless | Held cooling commands |
| `signals.current_A` | `Nt×1`, A | Mean of per-cell currents; not total pack current |
| `signals.heatGeneration_W` | `Nt×N`, W | Joule plus enabled entropy heat, with heat fault factor |
| `signals.coolingPowerProxy_W` | `Nt×1`, W | Nonnegative net heat-extraction proxy; no pump electrical power model |
| `metrics` | scalar fields | Sampled extrema, spreads, trapz energy/time and counts |
| `topology`, `configuration`, `metadata`, `events` | structs | Mapping, resolved inputs, environment/hash record and declarations/fallbacks |
| `energyResidualNormalized` | scalar | Algebraic RHS consistency normalized by peak individual heat generation |

Source: [src/+thermoweave/+results/makeResult.m:1–10](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/src/%2Bthermoweave/%2Bresults/makeResult.m#L1-L10) [src/+thermoweave/+results/computeMetrics.m:1–24](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/src/%2Bthermoweave/%2Bresults/computeMetrics.m#L1-L24) [src/+thermoweave/simulate.m:49–59](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/src/%2Bthermoweave/simulate.m#L49-L59). The parameter/symbol page defines normalization and the metric limits precisely.

## Exported and optional interfaces

`exportWebData(outputPath)` simulates five declared configurations, downsamples to roughly 90 samples, appends the final time when needed, converts temperature to °C and copies the JSON to `docs/assets/`. Its `thermoweave.web/v1` payload is separate from a raw result JSON. The legacy browser validates selected shape/hash-format fields and assumes 12 cells; it does not recompute a cryptographic payload hash or validate every metric. [tools/exportWebData.m:1–72](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/tools/exportWebData.m#L1-L72) [docs/app.js:166–207](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/docs/app.js#L166-L207)

Simscape mapping accepts a struct or `Simulink.SimulationOutput` containing `thermoweaveRaw`, with finite increasing time, `Nt×N` temperature/SOC, `Nt×1` current and a nonnegative finite residual. Several omitted optional arrays become NaN/zero defaults; optional boundary/heat arrays are shape checked without equivalent finite-value checks. `MAPPED_NOT_GROUND_TRUTH` metadata is deliberate. [simscape/mapSimscapeResults.m:1–132](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/simscape/mapSimscapeResults.m#L1-L132)

There is no repository HTTP service, database migration CLI, container entrypoint or native C/Python binding in the canonical tree. Python/PowerShell tooling includes a manuscript builder and the learning-guide validator; their command surfaces are indexed with their execution limits. No extra provider or integration is inferred from package labels.
