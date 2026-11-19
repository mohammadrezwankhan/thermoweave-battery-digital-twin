# Worked examples and labs

Examples here keep mathematical expectation, observed arithmetic and native execution separate. MATLAB snippets are runnable from a configured checkout but were **NOT_RUN** locally during this documentation pass. The pure browser fixture check is separately executable with Node and does not validate the native model. [Setup](SETUP_AND_REPRODUCIBILITY.md) · [equation derivations](../math-and-physics/EQUATIONS_AND_DERIVATIONS.md).

## One thermal mass: an arithmetic example

The configured first lesson uses heat input 600 W, conductance 30 W/K, thermal capacity 12000 J/K and ambient 20 °C. Its time constant is `C/h = 400 s`, or `6.6666667 min`. Starting at ambient, at 10 min:

$$\Delta T = \frac{600}{30}\left(1-e^{-30\cdot600/12000}\right)=15.5373968\ \mathrm{K}.$$

Temperature is 35.5373968 °C; stored heat is 186.4487616 kJ; removed power is 466.121904 W; net heating is 133.878096 W. The lesson's `residualW` is that last positive physical rate, not an integration error. These values follow the exact closed form and declared inputs. The two first-module checkpoints use 0.02 absolute tolerance. [docs/index.html:257–260](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/docs/index.html#L257-L260) [docs/lesson-config.json:1–320](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/docs/lesson-config.json#L1-L320)

From the repository root:

```bash
node docs/reference/check_lesson.cjs
```

The helper reads the existing pure model script and lesson JSON, requires their embedded configuration to agree, evaluates all four presets and all eight checkpoints, and prints values with their actual pass/fail results. It also records bounds/default behavior. It never executes the DOM script or changes a fixture. A failing checkpoint should be investigated against equations and configuration before changing a tolerance.

## Insulated equilibrium: a native contract

```matlab
startup
cfg = thermoweave.config.defaultConfig();
cfg.simulation.duration_s = 10;
cfg.cell.initialTemperature_K = 300;
cfg.thermal.ambientTemperature_K = 300;
cfg.boundary.temperature_K = 300;
cfg.electrical.current_A = 0;
cfg.controller.mode = 'openloop';
result = thermoweave.simulate(cfg);
drift = max(abs(result.state.temperature_K(:)-300));
assert(drift <= 1e-10)
```

Every edge starts with zero temperature difference; boundary temperatures match the cells and electrical/active heat is zero. The RHS is therefore zero. This checks equilibrium, shape and sign behavior under one scenario. It does not establish transient accuracy or measured fidelity. The source test additionally checks zero spread/residual/events under its own complete configuration. [tests/integration/TestSimulationIntegration.m:15–35](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/tests/integration/TestSimulationIntegration.m#L15-L35)

## A 3-D field with explicit ordering

```matlab
startup
cfg = thermoweave.config.loadScenario(fullfile('config','3d-intercell-study.json'));
result = thermoweave.simulate(cfg);
assert(result.topology.nodeCount == 36)
assert(result.topology.edgeCount == 75)
thermoweave.visualization.render3DModule(result, Visible="on");
```

The scenario is a 3×4×3 cuboid with 12 cells per layer and prescribed boundary levels 298.15, 302.15 and 306.15 K. It uses 8 A per node, open-loop control, `gz=0.25 W/K`, 120 s duration and 2 s output spacing. Its active vector boundary conductance is 0.35 W/K. The listed ambient conductance 0.08 W/K is not an extra parallel path in vector mode. Examine node indices and layer means before interpreting a plot. [config/3d-intercell-study.json:1–66](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/config/3d-intercell-study.json#L1-L66) [src/+thermoweave/+coolant/evaluate.m:1–20](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/src/%2Bthermoweave/%2Bcoolant/evaluate.m#L1-L20)

For the cuboid, edge count is `L[R(C-1)+C(R-1)] + RC(L-1) = 3(9+8)+24 = 75`. This is an independently checkable counting calculation. Do not switch this example to `layout.type='rectangular'` with enabled variability and assume equivalent behavior: the current rectangular variability helper counts only its two-dimensional edges. [src/+thermoweave/+thermal/buildTopology.m:74–93](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/src/%2Bthermoweave/%2Bthermal/buildTopology.m#L74-L93) [src/+thermoweave/+uncertainty/applyVariability.m:28–36](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/src/%2Bthermoweave/%2Buncertainty/applyVariability.m#L28-L36)

## Coolant direction and an independent static balance

The scalar march can be probed independently of ODE integration:

```matlab
startup
T = [310; 315];
H = [2 0; 0 2];
[Tc, q] = thermoweave.coolant.march(T,H,300,0.01,3800);
balanceW = sum(q)-0.01*3800*(Tc(end)-300);
assert(abs(balanceW) <= 1e-9)
```

The expected first coolant segment is 300.5 K; the second is 301.225 K. Heat into the two segments is 19 W and 27.55 W, giving 46.55 W total. Algebra gives the same total from outlet enthalpy. Reverse node-to-segment assignment to investigate direction; negative mass flow is rejected in validated configurations and is not the reverse-flow experiment. These are analytic expectations, not new MATLAB receipts. [src/+thermoweave/+coolant/march.m:1–8](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/src/%2Bthermoweave/%2Bcoolant/march.m#L1-L8) [tests/unit/TestConfigAndPhysics.m:124–138](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/tests/unit/TestConfigAndPhysics.m#L124-L138)

## Controlled comparison and seeded variation

```matlab
startup
addpath(fullfile(pwd,'examples'))
comparison = runAdaptiveCooling();
summary = runMonteCarloStudy(20);
```

The comparison uses 180 s, 18 A per cell and 298.25 K reference, reporting peak temperature and extraction energy for open-loop/baseline. It does not claim a universal improvement. Monte Carlo uses consecutive seeds beginning at 6100, 120 s runs and default electrical current; save the full config, sample count and quantile definition before comparing studies. The experiment-suite E8 has its own declared setup; matching a label does not substitute for matching inputs. [examples/runAdaptiveCooling.m:1–26](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/examples/runAdaptiveCooling.m#L1-L26) [examples/runMonteCarloStudy.m:1–28](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/examples/runMonteCarloStudy.m#L1-L28) [tools/runExperimentSuite.m:1–227](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/tools/runExperimentSuite.m#L1-L227)

For exported JSON, use a new path and an integer stride, and keep the original result:

```matlab
manifest = thermoweave.results.exportJSON(result,fullfile('results','study.json'),1);
disp(manifest)
```

Stride 1 avoids loss of the terminal sample. JSON equality depends on environment metadata and serialized field order as well as numerical state; compare declared numerical tolerances separately. [src/+thermoweave/+results/exportJSON.m:1–12](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/src/%2Bthermoweave/%2Bresults/exportJSON.m#L1-L12) [src/+thermoweave/+util/hashStruct.m:1–1](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/src/%2Bthermoweave/%2Butil/hashStruct.m#L1-L1)
