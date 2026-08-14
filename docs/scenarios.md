# ThermoWeave predeclared experiment matrix (E0-E10)

These IDs and settings define the synthetic demonstration suite. They are independent of the cited MathWorks example. Every run uses `thermoweave.result/v1`, records the resolved configuration and scenario hash, and reports normalized energy residual. Thresholds are engineering-demo assumptions, not validated battery limits.

## Common rules

- **OL** is open loop (`controller.mode="openloop"`).
- **BZ** is the bounded baseline zonal controller: 2 s update, $K_p=0.20$ K$^{-1}$, $q_{\max}=25$ W/zone unless a scenario overrides it.
- **AC** is the optional reduced-horizon quadratic controller. It uses Optimization Toolbox, reports solver/fallback status, and retains the same command and rate bounds as BZ.
- Compared runs share topology, initial state, uncertainty draw, current profile, and fault timeline.
- A comparison is admissible only when every run has $\epsilon_E\le10^{-4}$ and no unreported bounds or solver event.

## Implemented settings and evidence

| ID | Predeclared synthetic settings | Primary evidence and acceptance |
|---|---|---|
| **E0 Isothermal sanity** | 3x4 rectangular graph; all cells and scalar boundary at 300 K; zero current; OL; 10 s. | Automated integration test requires maximum spread and drift $\le10^{-10}$ K, residual $\le10^{-10}$, and no events. |
| **E1 Prescribed spatial gradient** | `config/vectorized-gradient.json`: 3x4 graph; zero current; smooth independently authored 298.15-302.33 K per-cell field; $H=0.5$ W/K; 240 s; OL. | Scalar/vector equivalence is tested separately. The scenario export must preserve 12 distinct node positions, finite metrics, its config hash, and residual $\le10^{-4}$. |
| **E2 Coolant propagation** | Four quasi-steady segments; $\dot m=0.010$ kg/s; $c_p=3800$ J/(kg K); 298.15 K inlet. Forward and reverse segment maps use the same cell field. | Unit evidence requires coolant heat to equal $\dot m c_p(T_{out}-T_{in})$ within $10^{-9}$ W and integration evidence requires reversal to change the spatial pattern without violating residual tolerance. |
| **E3 Zonal control** | 3x4 graph; four zones; 10 A/cell pulse from 60-240 s; 300 s; OL versus BZ. `config/nonuniform-cooling.json` is a separate `D3` prescribed-zonal website demonstration. | Automated comparison requires BZ to reduce peak temperature rise by at least 15%, keep every cell below 318.15 K, and satisfy residual tolerance. The benefit is scenario-specific. |
| **E4 Cell variability** | Seeds 4401-4403; 5% CV lognormal $R_0$ and independent +/-10% draws for thermal capacity, graph/contact conductance, ambient conductance, and coolant-interface conductance; 10 A/cell; 120 s. | Tests require positive dimensions, interface-specific draws, identical full result JSON for a repeated seed, and stable scenario hashes. No population-level controller benefit is claimed. |
| **E5 Channel restriction** | `config/channel-restriction.json`: four coolant segments; segment 2 conductance multiplied by 0.2 from 150-240 s; 10 A/cell; 240 s. | Automated evidence requires only segment 2 to change by the declared factor, preserves the fault event in result metadata, and enforces the residual gate. |
| **E6 Sensor fault** | `config/sensor-fault.json`: zone-2 measurement has +5 K bias from 180-240 s; 10 A/cell; BZ; 240 s. | Tests require declared sensor/cooling faults in metadata with canonical array dimensions. A dropout path is supported by the same event API. No fault-detection claim is made. |
| **E7 Controller comparison** | `examples/runAdaptiveCooling.m`: 3x4 nominal graph; 18 A/cell; 180 s; OL versus BZ. AC is evaluated separately on the same bounded command contract when Optimization Toolbox exists. | BZ and AC command/rate limits are automated. AC must command positive cooling for hot zones; optimization failure must emit fallback metadata. No universal AC energy advantage is claimed. |
| **E8 Monte Carlo robustness** | `examples/runMonteCarloStudy.m`: default 20 runs, seeds 6100-6119; 5 A/cell; BZ; 120 s; declared variability model. | The returned table is the seed manifest. Runs must remain finite and rerunnable; population percentiles are descriptive only until a convergence study is added. |
| **E9 Core versus Simscape** | `examples/compareCoreAndSimscape.m`: one resolved core configuration passed to the optional adapter. | Missing products or unresolved library policy must produce an explicit `SKIPPED_*` record. A real adapter result must satisfy the same schema; neither model is called ground truth. |
| **E10 Three-dimensional inter-cell study** | `config/3d-intercell-study.json`: independently authored 3x4x3 cuboid graph; 36 nodes; 75 axis-labelled edges; a synthetic 298.15/302.15/306.15 K layer boundary field; $g_z\in\{0.10,0.25,0.75\}$ W/K; 8 A/cell; 120 s; OL. | Six dedicated tests require topology counts, six-face masks, positive-semidefinite Laplacian, one-layer reduction, canonical 36-node result dimensions, isothermal conservation, finite state, residual $\le10^{-3}$, and headless 3-D rendering. The sensitivity output is descriptive synthetic evidence, not physical-cell validation. |

## Reproduction entry points

```matlab
startup
result = runDemo
compareBoundaryModes
runAdaptiveCooling
runMonteCarloStudy(20)
compareCoreAndSimscape
run3DStudy
```

The static site consumes five compact, downsampled scenario exports from `tools/exportWebData.m`; simulations retain each source configuration's full duration and output step before presentation downsampling. `D0` and `D3` explicitly identify website demonstrations rather than E0/E3 acceptance cases. The class tests cover the physics and schema contracts used by all ten experiments; longer distribution studies remain opt-in so core CI stays bounded.
