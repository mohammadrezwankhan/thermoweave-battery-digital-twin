# Complete MATLAB entrypoint catalogue

Pinned source: `5f29e34788b0f7ee58e2feeafc4df5d48a9a687a`. All 53 MATLAB files were read completely for their implemented contracts; runtime execution is separate. There are 47 file-callable functions, one script and five test classes. Local/nested functions are indexed in the structured handoff without incorrectly labeling them independent public calls. [API guide](API_CLI_AND_INTERFACES.md) · [verification](../maintainer/VERIFICATION_EVIDENCE_LEDGER.md).

## buildfile

```matlab
function plan = buildfile
```

Returns MATLAB build plan. Tasks check/test/coverage/integration/artifacts/docs/package have declared dependencies. Test/artifact/package tasks write output; advisory coverage does not fail below 80%.

[buildfile.m:1–102](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/buildfile.m#L1-L102)

## compareBoundaryModes

```matlab
function summary = compareBoundaryModes()
```

No arguments; simulates four configuration files and returns/displays a table of scenario, mode, peak temperature, edge gradient under the PeakSpread_K label, and extraction energy.

[examples/compareBoundaryModes.m:1–21](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/examples/compareBoundaryModes.m#L1-L21)

## run3DStudy

```matlab
function result = run3DStudy()
```

No arguments; runs config/3d-intercell-study.json, opens the native 3-D figure and returns the result.

[examples/run3DStudy.m:1–9](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/examples/run3DStudy.m#L1-L9)

## runAdaptiveCooling

```matlab
function comparison = runAdaptiveCooling()
```

No arguments; compares open-loop/baseline at 18 A, 180 s, 2 s output intervals and 298.25 K reference; returns/displays a two-row table.

[examples/runAdaptiveCooling.m:1–26](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/examples/runAdaptiveCooling.m#L1-L26)

## runMonteCarloStudy

```matlab
function summary = runMonteCarloStudy(numberOfRuns)
```

Positive integer numberOfRuns defaults to 20. Seeds begin at 6100; 120 s variability runs produce seed/peak/energy table. Requires addpath examples after startup.

[examples/runMonteCarloStudy.m:1–28](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/examples/runMonteCarloStudy.m#L1-L28)

## runDemo

```matlab
function result = runDemo(varargin)
```

No arguments creates a 30 s default run; first argument supplies a scenario, second writes JSON with stride 5. Returns canonical result; no-output call prints metrics.

[runDemo.m:1–11](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/runDemo.m#L1-L11)

## buildThermoWeaveModel

```matlab
function report = buildThermoWeaveModel(options)
```

Name-value ProjectRoot defaults to repository root. Returns product/policy/manifest gate status. Does not construct a model; READY is prerequisite status only.

[simscape/buildThermoWeaveModel.m:1–105](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/simscape/buildThermoWeaveModel.m#L1-L105)

## mapSimscapeResults

```matlab
function result = mapSimscapeResults(raw, config)
```

Accepts struct or SimulationOutput.thermoweaveRaw plus config. Requires time, temperature_K, soc, current_A and nonnegative residual; maps optional arrays/defaults into canonical result with MAPPED_NOT_GROUND_TRUTH.

[simscape/mapSimscapeResults.m:1–132](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/simscape/mapSimscapeResults.m#L1-L132)

## runSimscapeScenario

```matlab
function adapterResult = runSimscapeScenario(config, options)
```

Accepts config plus ProjectRoot option; StopTime comes from config.simulation.duration_s; runs the gating function, then may open/simulate a supplied generated model. Inspect callbacks first; skip status is returned when prerequisites fail.

[simscape/runSimscapeScenario.m:1–40](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/simscape/runSimscapeScenario.m#L1-L40)

## thermoweave.config.defaultConfig

```matlab
function cfg = defaultConfig()
```

No arguments; returns synthetic config/v1 values. Does not infer parameters from physical measurements.

[src/+thermoweave/+config/defaultConfig.m:1–32](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/src/%2Bthermoweave/%2Bconfig/defaultConfig.m#L1-L32)

## thermoweave.config.loadScenario

```matlab
function cfg = loadScenario(source)
```

No argument/empty defaults; JSON path or struct recursively overrides defaults. Missing file, malformed JSON/type/schema/domain throw named errors; unknown extra fields are preserved.

[src/+thermoweave/+config/loadScenario.m:1–31](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/src/%2Bthermoweave/%2Bconfig/loadScenario.m#L1-L31)

## thermoweave.config.validate

```matlab
function cfg=validate(cfg)
```

Compatibility alias of validateConfig; returns canonicalized config and raises its validation errors.

[src/+thermoweave/+config/validate.m:1–1](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/src/%2Bthermoweave/%2Bconfig/validate.m#L1-L1)

## thermoweave.config.validateConfig

```matlab
function cfg = validateConfig(cfg)
```

Checks required sections, dimensions, modes and domain restrictions; sets cell/controller counts and selected defaults. Shape validation is not exhaustive; several configured fields are not consumed downstream.

[src/+thermoweave/+config/validateConfig.m:1–392](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/src/%2Bthermoweave/%2Bconfig/validateConfig.m#L1-L392)

## thermoweave.control.advancedController

```matlab
function [u,info,state] = advancedController(input,cfg,state)
```

Input/config/prior state; returns u, info and state. Uses quadprog if present/successful; otherwise baseline with status/usedFallback. Reduced zonal one-horizon QP, not full plant MPC.

[src/+thermoweave/+control/advancedController.m:1–60](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/src/%2Bthermoweave/%2Bcontrol/advancedController.m#L1-L60)

## thermoweave.control.baselineController

```matlab
function [u,state] = baselineController(input,cfg,state)
```

Input temperatures/zones/weights/reference/elapsedStep and config/prior state. Returns bounded/rate-limited zone command and updated state; named deadband is subtracted after gain.

[src/+thermoweave/+control/baselineController.m:1–17](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/src/%2Bthermoweave/%2Bcontrol/baselineController.m#L1-L17)

## thermoweave.coolant.evaluate

```matlab
function b = evaluate(T,cfg,topo,zoneCommand,t)
```

T/config/topology/zone command/time; returns effective boundary, qCool and net extraction proxy. Scalar/vector/zonal or serial coolant, then active zone removal; faults include segment blockage.

[src/+thermoweave/+coolant/evaluate.m:1–68](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/src/%2Bthermoweave/%2Bcoolant/evaluate.m#L1-L68)

## thermoweave.coolant.evaluateBoundary

```matlab
function b=evaluateBoundary(varargin)
```

Forwarding alias to evaluate with its full argument/result contract.

[src/+thermoweave/+coolant/evaluateBoundary.m:1–1](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/src/%2Bthermoweave/%2Bcoolant/evaluateBoundary.m#L1-L1)

## thermoweave.coolant.march

```matlab
function [coolantT,qSolidCool] = march(T,H,inlet,massFlow,cp)
```

T(N), H(N,K), inlet K, mass flow kg/s, cp J/(kg K). Returns K coolant temperatures and K heat-into-coolant values. Direct helper does not repeat validated configuration checks.

[src/+thermoweave/+coolant/march.m:1–8](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/src/%2Bthermoweave/%2Bcoolant/march.m#L1-L8)

## thermoweave.electrical.heatGeneration

```matlab
function [q,details] = heatGeneration(T,soc,I,cfg)
```

T/SOC vectors, scalar-or-N current, config. Returns total Joule/optional entropy heat W and details including resistance/current. Positive current is discharge; entropy can be negative.

[src/+thermoweave/+electrical/heatGeneration.m:1–10](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/src/%2Bthermoweave/%2Belectrical/heatGeneration.m#L1-L10)

## thermoweave.electrical.socDerivative

```matlab
function dz = socDerivative(soc,I,cfg)
```

SOC establishes N; current/config produce dz/dt. Capacity_C with sign-specific efficiencies; no SOC clipping or termination.

[src/+thermoweave/+electrical/socDerivative.m:1–7](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/src/%2Bthermoweave/%2Belectrical/socDerivative.m#L1-L7)

## thermoweave.results.computeMetrics

```matlab
function m = computeMetrics(result,cfg)
```

Result/config produces sampled extrema/spreads, percentile, time/extraction integrals, variation and mixed violation count. Residual may be NaN before main simulation installs it.

[src/+thermoweave/+results/computeMetrics.m:1–24](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/src/%2Bthermoweave/%2Bresults/computeMetrics.m#L1-L24)

## thermoweave.results.export

```matlab
function m=export(varargin)
```

Alias forwarding to exportJSON; same filesystem and downsampling behavior.

[src/+thermoweave/+results/export.m:1–1](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/src/%2Bthermoweave/%2Bresults/export.m#L1-L1)

## thermoweave.results.exportJSON

```matlab
function manifest = exportJSON(result,path,varargin)
```

Result/path/optional stride writes jsonencode payload and returns path/hash/numel(text) under bytes name. Integer stride advisable; full-grid metrics/timeBase remain and final sample can be omitted.

[src/+thermoweave/+results/exportJSON.m:1–12](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/src/%2Bthermoweave/%2Bresults/exportJSON.m#L1-L12)

## thermoweave.results.makeResult

```matlab
function result = makeResult(data,cfg,topo,metadata)
```

Data/config/topology/metadata produces canonical result/v1 and metrics. No general complete input-schema validator; called with assembled simulation data.

[src/+thermoweave/+results/makeResult.m:1–10](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/src/%2Bthermoweave/%2Bresults/makeResult.m#L1-L10)

## thermoweave.thermal.buildTopology

```matlab
function topo = buildTopology(layout)
```

Layout struct produces node/edge counts, coordinates, edges, axes, incidence/Laplacian, zones, ordering and surface masks. Positive conductance/geometry/count validations; scalar units are W/K and m.

[src/+thermoweave/+thermal/buildTopology.m:1–178](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/src/%2Bthermoweave/%2Bthermal/buildTopology.m#L1-L178)

## thermoweave.thermal.integrate

```matlab
function result=integrate(varargin)
```

Alias forwarding to thermoweave.simulate; no independent integrator or accuracy guarantee.

[src/+thermoweave/+thermal/integrate.m:1–4](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/src/%2Bthermoweave/%2Bthermal/integrate.m#L1-L4)

## thermoweave.thermal.simulate

```matlab
function result=simulate(varargin)
```

Compatibility wrapper forwarding all supplied arguments to thermoweave.simulate; same implementation and limits.

[src/+thermoweave/+thermal/simulate.m:1–4](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/src/%2Bthermoweave/%2Bthermal/simulate.m#L1-L4)

## thermoweave.uncertainty.applyFaults

```matlab
function [p,active] = applyFaults(cfg,t,p)
```

Config/time/parameter struct returns modified parameters plus currently active records. Inclusive windows and target-specific multipliers; sensor/actuator handling is elsewhere.

[src/+thermoweave/+uncertainty/applyFaults.m:1–34](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/src/%2Bthermoweave/%2Buncertainty/applyFaults.m#L1-L34)

## thermoweave.uncertainty.applyVariability

```matlab
function [cfg,info] = applyVariability(cfg,seed)
```

Config and optional seed; returns modified config and draw info, or unchanged config if disabled. Local mt19937ar; resistance lognormal and independent uniform capacity/conductance scales. Rectangular multilayer edge count defect documented.

[src/+thermoweave/+uncertainty/applyVariability.m:1–36](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/src/%2Bthermoweave/%2Buncertainty/applyVariability.m#L1-L36)

## thermoweave.util.hashFile

```matlab
function digest = hashFile(path)
```

Path to readable file; SHA-256 via Java over fread uint8. Raises thermoweave:hash:IO on open failure; returns lowercase digest.

[src/+thermoweave/+util/hashFile.m:1–13](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/src/%2Bthermoweave/%2Butil/hashFile.m#L1-L13)

## thermoweave.util.hashStruct

```matlab
function h=hashStruct(s)
```

Hashes jsonencode of supplied struct through hashText. Field order/serialization matter; no semantic canonicalization guarantee.

[src/+thermoweave/+util/hashStruct.m:1–1](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/src/%2Bthermoweave/%2Butil/hashStruct.m#L1-L1)

## thermoweave.util.hashText

```matlab
function h=hashText(txt)
```

Character payload converted to UTF-8 bytes then Java SHA-256. Returns lowercase hex; requires Java-enabled MATLAB runtime.

[src/+thermoweave/+util/hashText.m:1–4](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/src/%2Bthermoweave/%2Butil/hashText.m#L1-L4)

## thermoweave.visualization.dashboard

```matlab
function app = dashboard(results, options)
```

Result or cell array; ReducedMotion defaults false. Returns app handles and opens UI for scenario/play/scrub/PNG/GIF. Schema presence is checked, not every array. GUI callbacks remain unexecuted here.

[src/+thermoweave/+visualization/dashboard.m:1–205](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/src/%2Bthermoweave/%2Bvisualization/dashboard.m#L1-L205)

## thermoweave.visualization.exportAnimation

```matlab
function manifest = exportAnimation(result, path, options)
```

Result/path; positive integer FrameCount default 30, positive Delay_s default 0.08. Writes selected-frame looping GIF via temporary PNG; returns hash/frame/delay manifest and cleans temporary figure/image.

[src/+thermoweave/+visualization/exportAnimation.m:1–83](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/src/%2Bthermoweave/%2Bvisualization/exportAnimation.m#L1-L83)

## thermoweave.visualization.render3DModule

```matlab
function figureHandle = render3DModule(result, options)
```

Result/v1 and coordinate shape validation, TimeIndex/Visible options. Returns figure with one colored cuboid per node and graph edges, fixed view [35 24]. No full accessibility conformance proof.

[src/+thermoweave/+visualization/render3DModule.m:1–126](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/src/%2Bthermoweave/%2Bvisualization/render3DModule.m#L1-L126)

## thermoweave.visualization.renderFigure

```matlab
function figureHandle = renderFigure(result, options)
```

Canonical-like result; TimeIndex positive integer defaults final, capped to length; Visible defaults on. Opens 2-D summary figure with Celsius display and command traces.

[src/+thermoweave/+visualization/renderFigure.m:1–75](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/src/%2Bthermoweave/%2Bvisualization/renderFigure.m#L1-L75)

## thermoweave.run

```matlab
function result = run(source,varargin)
```

Alias forwarding required source and optional arguments to thermoweave.simulate; use [] for default source.

[src/+thermoweave/run.m:1–4](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/src/%2Bthermoweave/run.m#L1-L4)

## thermoweave.simulate

```matlab
function result = simulate(source,varargin)
```

Required source (use []), optional seed override. Resolves config/variability/topology; integrates T/SOC with output-interval control and produces canonical result/events. No file output by itself.

[src/+thermoweave/simulate.m:1–102](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/src/%2Bthermoweave/simulate.m#L1-L102)

## startup

```matlab
function root = startup()
```

Returns the project root and adds src/simscape/tools; does not add examples. MATLAB path mutation only.

[startup.m:1–10](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/startup.m#L1-L10)

## createSocialPreview

```matlab
function path = createSocialPreview()
```

Runs demo/renderFigure with hidden figure, writes docs/assets/social-preview.png at fixed size; returns path. Not run for documentation.

[tools/createSocialPreview.m:1–13](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/tools/createSocialPreview.m#L1-L13)

## exportWebData

```matlab
function manifest = exportWebData(outputPath)
```

Optional output path defaults artifacts/web-data/thermoweave-demo.json. Simulates five declared scenarios; downsamples and converts to Celsius, writes/copies data to docs/assets, returns manifest.

[tools/exportWebData.m:1–72](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/tools/exportWebData.m#L1-L72)

## generate3DResearchArtifacts

```matlab
function evidence = generate3DResearchArtifacts()
```

No arguments; sweeps gz [0.10,0.25,0.75] for canonical cuboid; writes two PNG figures, CSV and JSON summary. Historical outputs are preserved.

[tools/generate3DResearchArtifacts.m:1–151](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/tools/generate3DResearchArtifacts.m#L1-L151)

## generateArtifacts

```matlab
function evidence = generateArtifacts()
```

No arguments; runs demo, plots/web data/GIF, verification report, experiments and 3-D research artifacts; writes artifact-manifest.json. Broad regeneration, not a static docs check.

[tools/generateArtifacts.m:1–54](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/tools/generateArtifacts.m#L1-L54)

## generateDocs

```matlab
function report = generateDocs()
```

No arguments; checks presence of eight existing docs/assets entrypoints and returns report. Does not validate all links/content/new handbook.

[tools/generateDocs.m:1–16](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/tools/generateDocs.m#L1-L16)

## packageRelease

```matlab
function manifest = packageRelease()
```

No arguments; ZIPs declared source/evidence roots and writes release manifest with SHA/git metadata. No remote publication, no proven bytewise ZIP determinism.

[tools/packageRelease.m:1–43](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/tools/packageRelease.m#L1-L43)

## runExperimentSuite

```matlab
function manifest = runExperimentSuite(options)
```

Name-values MonteCarloRuns positive integer default 20, OutputPath default artifacts/reports/experiment-summary.json. Runs E0–E9 and writes records/statuses; inspect each record instead of assuming manifest creation means every experiment passed.

[tools/runExperimentSuite.m:1–227](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/tools/runExperimentSuite.m#L1-L227)

## writeVerificationReport

```matlab
function report = writeVerificationReport()
```

No arguments; may reuse JUnit based on limited tests/src mtime comparison or run tests; reads optional coverage/SARIF, runs demo and adapter gate, writes verification JSON. Historical reuse needs explicit provenance.

[tools/writeVerificationReport.m:1–95](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/tools/writeVerificationReport.m#L1-L95)

## Script entrypoint

Runs core baseline and optional gated adapter; prints comparison status, never treats either result as ground truth. Inspect optional model callbacks before any future simulation.

[examples/compareCoreAndSimscape.m:1–17](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/examples/compareCoreAndSimscape.m#L1-L17)

## Test classes and method inventory

These methods define assertions; none was executed locally in this documentation environment. Setup methods are excluded from the 40 count. Test tolerances and conditional product skips are discussed in the evidence ledger.

### Test3DStudy

[tests/integration/Test3DStudy.m:1–80](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/tests/integration/Test3DStudy.m#L1-L80)

- `canonicalResultHasThreeDimensionalState` — [tests/integration/Test3DStudy.m:12–12](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/tests/integration/Test3DStudy.m#L12-L12)
- `insulatedThreeDimensionalLatticeConservesUniformState` — [tests/integration/Test3DStudy.m:34–34](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/tests/integration/Test3DStudy.m#L34-L34)
- `renderCreatesAccessibleDeterministicThreeDimensionalFigure` — [tests/integration/Test3DStudy.m:58–58](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/tests/integration/Test3DStudy.m#L58-L58)

### TestSimulationIntegration

[tests/integration/TestSimulationIntegration.m:1–205](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/tests/integration/TestSimulationIntegration.m#L1-L205)

- `isothermalE0RemainsExactlyAtEquilibrium` — [tests/integration/TestSimulationIntegration.m:15–15](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/tests/integration/TestSimulationIntegration.m#L15-L15)
- `thermalRelaxationMovesTowardAmbient` — [tests/integration/TestSimulationIntegration.m:36–36](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/tests/integration/TestSimulationIntegration.m#L36-L36)
- `energyAccountingAndSolverConvergenceAgree` — [tests/integration/TestSimulationIntegration.m:51–51](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/tests/integration/TestSimulationIntegration.m#L51-L51)
- `signalHistoriesUseTheirDeclaredSampleTimes` — [tests/integration/TestSimulationIntegration.m:67–67](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/tests/integration/TestSimulationIntegration.m#L67-L67)
- `externalHeatPreservesEnergyAccounting` — [tests/integration/TestSimulationIntegration.m:84–84](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/tests/integration/TestSimulationIntegration.m#L84-L84)
- `storagePermutationPreservesSymmetricChainBehavior` — [tests/integration/TestSimulationIntegration.m:95–95](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/tests/integration/TestSimulationIntegration.m#L95-L95)
- `prescribedGradientPreservesNodeSpecificOrdering` — [tests/integration/TestSimulationIntegration.m:116–116](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/tests/integration/TestSimulationIntegration.m#L116-L116)
- `reversingCoolantSegmentsChangesSpatialPattern` — [tests/integration/TestSimulationIntegration.m:130–130](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/tests/integration/TestSimulationIntegration.m#L130-L130)
- `baselineControllerRespectsBoundsAndRateLimit` — [tests/integration/TestSimulationIntegration.m:151–151](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/tests/integration/TestSimulationIntegration.m#L151-L151)
- `advancedControllerCoolsHotZonesAndHonorsRate` — [tests/integration/TestSimulationIntegration.m:168–168](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/tests/integration/TestSimulationIntegration.m#L168-L168)
- `e3PulseBaselineMeetsPredeclaredBenefit` — [tests/integration/TestSimulationIntegration.m:181–181](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/tests/integration/TestSimulationIntegration.m#L181-L181)

### TestRegressionContracts

[tests/regression/TestRegressionContracts.m:1–111](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/tests/regression/TestRegressionContracts.m#L1-L111)

- `repeatedSeedReproducesConfigurationAndMetrics` — [tests/regression/TestRegressionContracts.m:21–21](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/tests/regression/TestRegressionContracts.m#L21-L21)
- `canonicalSchemaAndExportManifestRemainTraceable` — [tests/regression/TestRegressionContracts.m:35–35](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/tests/regression/TestRegressionContracts.m#L35-L35)
- `declaredFaultsExposeMetadataAndPreserveDimensions` — [tests/regression/TestRegressionContracts.m:56–56](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/tests/regression/TestRegressionContracts.m#L56-L56)
- `optionalSimscapeStatusIsExplicit` — [tests/regression/TestRegressionContracts.m:76–76](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/tests/regression/TestRegressionContracts.m#L76-L76)
- `simscapeMapperCompletesCanonicalContract` — [tests/regression/TestRegressionContracts.m:86–86](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/tests/regression/TestRegressionContracts.m#L86-L86)
- `simscapeMapperRejectsNoncanonicalCurrent` — [tests/regression/TestRegressionContracts.m:101–101](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/tests/regression/TestRegressionContracts.m#L101-L101)

### TestConfigAndPhysics

[tests/unit/TestConfigAndPhysics.m:1–204](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/tests/unit/TestConfigAndPhysics.m#L1-L204)

- `rejectsInvalidCellDimensions` — [tests/unit/TestConfigAndPhysics.m:15–15](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/tests/unit/TestConfigAndPhysics.m#L15-L15)
- `rejectsNegativeThermalMass` — [tests/unit/TestConfigAndPhysics.m:22–22](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/tests/unit/TestConfigAndPhysics.m#L22-L22)
- `rejectsInvalidConductance` — [tests/unit/TestConfigAndPhysics.m:29–29](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/tests/unit/TestConfigAndPhysics.m#L29-L29)
- `rejectsUnsupportedBoundaryMode` — [tests/unit/TestConfigAndPhysics.m:37–37](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/tests/unit/TestConfigAndPhysics.m#L37-L37)
- `rejectsUnsafeCoolantAndElectricalValues` — [tests/unit/TestConfigAndPhysics.m:44–44](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/tests/unit/TestConfigAndPhysics.m#L44-L44)
- `rejectsNonfiniteAndMalformedFaultDeclarations` — [tests/unit/TestConfigAndPhysics.m:55–55](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/tests/unit/TestConfigAndPhysics.m#L55-L55)
- `rejectsNegativeRuntimeResistanceFactor` — [tests/unit/TestConfigAndPhysics.m:72–72](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/tests/unit/TestConfigAndPhysics.m#L72-L72)
- `rejectsUnknownConfigurationSchema` — [tests/unit/TestConfigAndPhysics.m:80–80](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/tests/unit/TestConfigAndPhysics.m#L80-L80)
- `topologyContractAndPermutationMetadata` — [tests/unit/TestConfigAndPhysics.m:87–87](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/tests/unit/TestConfigAndPhysics.m#L87-L87)
- `jouleAndEntropicHeatSigns` — [tests/unit/TestConfigAndPhysics.m:99–99](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/tests/unit/TestConfigAndPhysics.m#L99-L99)
- `socDerivativeHonorsChargeAndDischarge` — [tests/unit/TestConfigAndPhysics.m:111–111](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/tests/unit/TestConfigAndPhysics.m#L111-L111)
- `coolantForwardAndReversePatternConserveHeat` — [tests/unit/TestConfigAndPhysics.m:124–124](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/tests/unit/TestConfigAndPhysics.m#L124-L124)
- `coolantRestrictionTargetsOnlyDeclaredSegment` — [tests/unit/TestConfigAndPhysics.m:139–139](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/tests/unit/TestConfigAndPhysics.m#L139-L139)
- `coolantSupportsPerSegmentConductance` — [tests/unit/TestConfigAndPhysics.m:154–154](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/tests/unit/TestConfigAndPhysics.m#L154-L154)
- `variabilityIncludesAllDeclaredThermalInterfaces` — [tests/unit/TestConfigAndPhysics.m:165–165](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/tests/unit/TestConfigAndPhysics.m#L165-L165)
- `scalarAndUniformVectorBoundaryAreEquivalent` — [tests/unit/TestConfigAndPhysics.m:179–179](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/tests/unit/TestConfigAndPhysics.m#L179-L179)
- `scalarCurrentProfileActsAsConstant` — [tests/unit/TestConfigAndPhysics.m:194–194](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/tests/unit/TestConfigAndPhysics.m#L194-L194)

### TestTopology3D

[tests/unit/TestTopology3D.m:1–79](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/tests/unit/TestTopology3D.m#L1-L79)

- `cuboidNodeAndSurfaceContracts` — [tests/unit/TestTopology3D.m:12–12](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/tests/unit/TestTopology3D.m#L12-L12)
- `conductanceAxesAndLaplacianArePhysical` — [tests/unit/TestTopology3D.m:35–35](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/tests/unit/TestTopology3D.m#L35-L35)
- `oneLayerCuboidReducesToLegacyRectangularTopology` — [tests/unit/TestTopology3D.m:55–55](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/tests/unit/TestTopology3D.m#L55-L55)

## Other executable tools

`python scripts/portfolio/validate_guide.py` takes no CLI options; it reads the learning configuration/HTML/SVG and prints a validation summary or raises on a mismatch. This existing helper is source-reviewed and executed separately. `python tools/build_manuscript.py` is a historical python-docx manuscript builder with a fixed input/output; its top-level purpose/imports and AST-defined functions are indexed, but its full rendering behavior and Word outputs are not revalidated here. `tools/export_manuscript_pdf.ps1` uses Windows Word COM to open the existing DOCX read-only and export PDF; it is source-reviewed but not run. It requires Windows/Microsoft Word and writes the manuscript PDF.
[scripts/portfolio/validate_guide.py:1–33](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/scripts/portfolio/validate_guide.py#L1-L33) [tools/build_manuscript.py:1–32](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/tools/build_manuscript.py#L1-L32) [tools/export_manuscript_pdf.ps1:1–16](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/tools/export_manuscript_pdf.ps1#L1-L16)
