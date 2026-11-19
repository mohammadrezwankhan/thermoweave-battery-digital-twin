# Setup and reproducibility

Use a clean checkout at the revision you intend to test and record `git rev-parse HEAD` before execution. This guide describes the inspected source; native commands below were **not run in this author environment**, which has neither MATLAB nor Octave. Historical native evidence and source-head GitHub checks are separated in the [evidence ledger](../maintainer/VERIFICATION_EVIDENCE_LEDGER.md).

## Environments

| Path | Declared requirement | Observed evidence and limit |
|---|---|---|
| Graph simulation and baseline controller | MATLAB R2024a or newer | Source CI config targets R2024a; saved source-head provider metadata reports success, not a local rerun |
| Advanced controller | Optimization Toolbox `quadprog` | Missing/failed solver produces a baseline fallback; MATLAB alone still runs the baseline |
| Simscape comparison | Simulink, Simscape, Simscape Battery plus resolved library policy and model | No generated model tracked; local invocation not run |
| Historical desktop outputs | R2026a Update 4 on Windows 11 | Stored 2026-08-14 report, earlier revision; preserved history |
| Browser analytic lab | Modern JavaScript browser | Local pure arithmetic can be checked in Node; no visual/keyboard runtime verification performed here |
| Documentation handbook | Python 3.11+ and Pandoc used for this package | Build is offline; generated HTML needs no JavaScript |

Source requirements: [ENVIRONMENT.md:1–40](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/ENVIRONMENT.md#L1-L40) [.github/workflows/core-ci.yml:1–34](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/.github/workflows/core-ci.yml#L1-L34) [src/+thermoweave/+control/advancedController.m:1–60](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/src/%2Bthermoweave/%2Bcontrol/advancedController.m#L1-L60) [simscape/buildThermoWeaveModel.m:1–105](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/simscape/buildThermoWeaveModel.m#L1-L105).

## Core setup and first result

From the repository root in MATLAB:

```matlab
startup
result = thermoweave.simulate([]);
disp(result.metrics)
```

For a faster entrypoint, `result = runDemo();` shortens defaults to 30 seconds. A file scenario remains its declared duration:

```matlab
startup
result = thermoweave.simulate(fullfile('config','baseline.json'));
thermoweave.visualization.renderFigure(result, Visible="on");
```

The callable examples require an extra path, because `startup` does not add `examples`:

```matlab
startup
addpath(fullfile(pwd,'examples'))
result3d = run3DStudy();
```

`compareCoreAndSimscape.m` is a script, rather than a function; read the optional-model gate before running it. Sources: [startup.m:1–10](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/startup.m#L1-L10) [runDemo.m:1–11](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/runDemo.m#L1-L11) [examples/run3DStudy.m:1–9](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/examples/run3DStudy.m#L1-L9) [examples/compareCoreAndSimscape.m:1–17](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/examples/compareCoreAndSimscape.m#L1-L17).

## Native checks and artifact generation

```matlab
startup
buildtool test
```

The `test` task depends on `check` and writes JUnit/coverage files under `results/`. `coverage` is an additional advisory task: it reports coverage below 80% without failing that task. The default build selects check/test/coverage. `buildtool artifacts`, `buildtool docs` and `buildtool package` have broader side effects, regenerating tracked scientific presentation artifacts and creating release files; run them in a disposable checkout and review the diff. The `integration` task selects only `tests/integration`, containing `TestSimulationIntegration` and `Test3DStudy` for the core simulation and 3-D results. The optional adapter status and mapper checks are in `tests/regression/TestRegressionContracts.m`, included by the full `test` task. The adapter status check accepts explicit skip statuses. The integration task alone does not invoke the adapter or enforce its product, library-policy and generated-model gates; it is not proof that a Simscape model ran. [buildfile.m:1–102](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/buildfile.m#L1-L102) [tests/regression/TestRegressionContracts.m:76–110](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/tests/regression/TestRegressionContracts.m#L76-L110) [tests/integration/TestSimulationIntegration.m:1–13](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/tests/integration/TestSimulationIntegration.m#L1-L13) [tests/integration/Test3DStudy.m:1–13](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/tests/integration/Test3DStudy.m#L1-L13) [tools/generateArtifacts.m:1–54](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/tools/generateArtifacts.m#L1-L54) [tools/packageRelease.m:1–43](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/tools/packageRelease.m#L1-L43)

## Reproduction receipt

Keep the command, UTC observation time, source commit and dirty state, MATLAB/product versions, OS, input and resolved configuration hashes, seed, solver/tolerances, actual time grid, topology order, result schema and artifact hashes. Keep actual test counts and skips separate from test definitions. Preserve the complete result before downsampling; compare temperature/SOC and metrics under a declared tolerance. The current export can omit the last sample when stride does not divide the grid, and retains full-resolution metrics and `metadata.timeBase_s`. [src/+thermoweave/+results/exportJSON.m:1–12](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/src/%2Bthermoweave/%2Bresults/exportJSON.m#L1-L12) [src/+thermoweave/simulate.m:85–100](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/src/%2Bthermoweave/simulate.m#L85-L100)

Resolved `thermalCapacity_J_per_K` drives the ODE directly: changing `mass_kg` or `specificHeat_J_per_kgK` alone does not recompute it. Scalar/vector mode uses `boundary.conductance_W_per_K`; changing the ambient conductance field alone need not affect those modes. Start from `defaultConfig`, edit the active fields explicitly, then use `loadScenario`/`simulate` to validate. [src/+thermoweave/+config/defaultConfig.m:1–32](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/src/%2Bthermoweave/%2Bconfig/defaultConfig.m#L1-L32) [src/+thermoweave/+coolant/evaluate.m:1–28](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/src/%2Bthermoweave/%2Bcoolant/evaluate.m#L1-L28) [src/+thermoweave/simulate.m:54–59](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/src/%2Bthermoweave/simulate.m#L54-L59)

## Static documentation and browser arithmetic

```bash
python scripts/portfolio/validate_guide.py
node docs/reference/check_lesson.cjs
python docs/reference/build_reference.py --check
```

The first command validates the existing learning-path configuration and selected HTML markers. The second executes only the inspected pure model script and its eight declared thermal checkpoints. The last compares generated reading HTML with canonical Markdown/CFF inputs. None starts MATLAB, opens a generated model, deploys Pages or checks browser layout. To regenerate after editing canonical docs, run `python docs/reference/build_reference.py` and review only the documentation diff.

The main analytic lab embeds its inputs and can be opened as a local file. Legacy playback fetches a separate JSON file and may need a local HTTP server, for example `python -m http.server 8000 --directory docs`, then `http://localhost:8000/original-index.html`. This command is an optional local viewing step, not an observed browser result. [docs/index.html:146–150](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/docs/index.html#L146-L150) [docs/app.js:182–207](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/docs/app.js#L182-L207)
