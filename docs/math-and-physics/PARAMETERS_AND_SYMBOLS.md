# Parameters, symbols and units

Values below are **synthetic defaults**, not fitted cell or coolant properties. Scenario JSON overrides defaults recursively. The runtime consumes the resolved configuration and uses explicit node/zone expansion. Source: [src/+thermoweave/+config/defaultConfig.m:1–32](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/src/%2Bthermoweave/%2Bconfig/defaultConfig.m#L1-L32) [src/+thermoweave/+config/loadScenario.m:1–31](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/src/%2Bthermoweave/%2Bconfig/loadScenario.m#L1-L31). [Equations](EQUATIONS_AND_DERIVATIONS.md) explain signs and derivations.

## Native defaults and active meaning

| Fields / symbols | Default | Units / dimension | Interpretation |
|---|---|---|---|
| `simulation.duration_s`, `outputStep_s` | 600, 1 | s | Stored output intervals also drive control updates |
| `solver`, `relativeTolerance`, `absoluteTolerance`, `maxStep_s` | ode15s, 1e−6, 1e−8, 0.25 | solver, relative, state-scaled absolute, s | Adaptive solver controls, not global error guarantees |
| `simulation.seed` | 0 | scalar | Passed to variability; overrides its configured seed in the main path |
| `layout.type`, rows/columns/layers | rectangular, 3/4/1 | labels/counts | 12 cells, 17 edges in this default |
| `pitchX_m`, `pitchY_m`, `pitchZ_m` | 0.03, 0.03, 0.07 | m | Coordinates/neighbor geometry; no automatic material law |
| `gx_W_per_K`, `gy_W_per_K`, `gz_W_per_K` | 0.8, 0.6, 0.3 | W/K | Axial conductance, positive |
| `edgeConductance_W_per_K` | 0.7 | W/K | Base staggered edge conductance before distance adjustment |
| `layout.zoneCount`, `controller.zoneCount` | 4 | count | Validator aligns controller count with layout; zones from storage order |
| `cell.count`, `initialTemperature_K`, `initialSOC` | 12, 298.15, 0.8 | count, K, fraction | Scalar expansion for initial state |
| `mass_kg`, `specificHeat_J_per_kgK`, `area_m2` | 0.045, 900, 0.001 | kg, J/(kg K), m² | Descriptive inputs; no automatic runtime recomputation of C/H |
| `thermalCapacity_J_per_K`, $C_i$ | 40.5 | J/K | Direct ODE divisor; default equals 0.045×900 |
| `thermal.ambientTemperature_K`, `ambientConductance_W_per_K` | 298.15, 0.25 | K, W/K | Ambient path used in coolant mode; boundary fields govern other modes |
| `externalHeat_W`, $q_{ext}$ | 0 | W/cell | Positive adds heat; scalar or N elements |
| `thermal.contactConductance_W_per_K` | empty | W/K | Validated if supplied, but graph builder consumes layout conductances |
| `current_A`, $I_i$ | 5 | A/cell | Positive discharge; result signal stores mean, not sum |
| `currentProfile` | empty | A, optionally time s | Previous interpolation; vector profile uses implicit seconds |
| `capacity_C`, `capacity_Ah`, $Q_i$ | 18000, 5 | C, Ah | Positive C value is authoritative; Ah fallback when C is nonpositive |
| `R0_Ohm`, $R_0$ | 0.008 | Ω | Resistance base, zero allowed by validation then runtime ε floor |
| `alphaT_per_K`, $\alpha_T$ | 0.003 | K⁻¹ | Linear temperature factor around reference |
| `alphaSOC`, $\alpha_z$ | 0.05 | dimensionless | Multiplies `(1-SOC)` |
| `temperatureReference_K`, $T_{ref}$ in electrical | 298.15 | K | Electrical resistance reference |
| `dischargeEfficiency`, `chargeEfficiency` | 1, 1 | fraction | Positive ≤1; sign-specific SOC conversion |
| `entropicHeat`, `dUoc_dT_V_per_K` | false, 0.0002 | boolean, V/K | Enabled entropy term uses absolute T in K |
| `boundary.mode`, `temperature_K`, `conductance_W_per_K` | scalar, 298.15, 0.25 | mode, K, W/K | Resolved conductance, not W/(m² K) |
| `zoneTemperature_K`, `zoneConductance_W_per_K`, `zoneId` | empty | zone K, W/K, labels | Explicit zone values required in zonal use; mapping comes from topology |
| coolant segments, massFlow, specificHeat, inlet | 4, 0.01, 3800, 298.15 | count, kg/s, J/(kg K), K | Strictly positive nominal flow; no dynamic coolant state |
| coolant `segmentConductance_W_per_K`, `segmentNodes` | 2, empty | W/K, assignment | Empty maps nodes via topology zones capped at segment count |
| `controller.mode`, `referenceTemperature_K` | baseline, 298.15 | mode, K | Actual sensed-zone comparison |
| `samplePeriod_s` | 2 | s | Direct-controller fallback dt; main simulation supplies output interval |
| `Kp_per_K`, `qMax_W` | 0.2, 25 | K⁻¹, W/zone | Command gain and total zone extraction |
| `rateLimit_per_s`, `deadband_K` | Inf, 0 | s⁻¹, misleading K name | Unlimited default rate; deadband is subtracted after gain |
| advanced horizon, lambdaU/E/G | 20, 0.1/0.01/0.1 | s, numerical weights | Reduced zonal QP; weights are not calibrated economic costs |
| `variability.enabled`, `seed`, `R0CV`, `uniformFraction` | false, 0, 0.05, 0.10 | bool, seed, log σ, fraction | R0CV name approximates actual lognormal CV only at small σ |
| `faults.events` | empty | records | Type/target/start/end/magnitude; inclusive windows |
| temperature/edge/SOC thresholds | 318.15, Inf, [0,1] | K, K, fraction | Metrics/event reporting; no automatic protective shutdown |

Validation constraints are in [src/+thermoweave/+config/validateConfig.m:1–392](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/src/%2Bthermoweave/%2Bconfig/validateConfig.m#L1-L392). Some nominally scalar fields use checks that do not enforce scalar shape; valid-looking malformed arrays can still fail downstream. The table is a supported-use guide, not a claim of exhaustive runtime rejection.

## Ordering and symbol distinctions

| Symbol | Meaning | Scope / unit |
|---|---|---|
| $N,E,Z,K$ | Cells, graph edges, controller zones, coolant segments | Counts; K here is a segment count, while upright K denotes kelvin |
| $N_t$ | Stored samples | Output grid length |
| $B,L$ | Edge incidence and graph Laplacian | `E×N` dimensionless and `N×N` W/K |
| $T_i,z_i$ | Temperature and state of charge | K and dimensionless |
| $g_{ij},H_i,H_{ik}$ | Edge, boundary and segment conductance | All W/K, already resolved |
| $q_i,q_{cool,i},q_{ext,i}$ | Heat entering cell | W; active extraction is negative |
| $\dot m c_p$ | Coolant heat-capacity flow | W/K |
| $u_z,q_{max,z}$ | Command and available zone extraction | Fraction and W |
| $r_{norm}$ | Native RHS residual ratio | W/W; peak individual generated heat denominator |
| `residualW` | Browser net heating | W; different quantity from native residual |

The graph's `r + (c−1)R + (l−1)RC` ordering makes rows vary fastest. Histories are `Nt×N`, state vectors are columns, and serialized JSON dimensions can collapse when scalar dimensions arise. Validate consumer shapes instead of assuming a plotting image establishes ordering. [src/+thermoweave/+thermal/buildTopology.m:1–178](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/src/%2Bthermoweave/%2Bthermal/buildTopology.m#L1-L178) [src/+thermoweave/+results/makeResult.m:1–10](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/src/%2Bthermoweave/%2Bresults/makeResult.m#L1-L10)

## Derived metrics

`peakTemperature_K` is the maximum over every sample/cell. `meanTemperature_K` averages every array element. The 95th percentile uses sorted finite values with linear interpolation. `peakEdgeGradient_K` is the maximum connected-edge difference; `rmsEdgeGradient_K` is the RMS of the per-time maximum edge difference, not RMS of all edge differences. `timeAboveThreshold_s` uses trapezoidal integration of the sampled maximum-temperature indicator, not continuous event localization or cell-duration. `coolingEnergy_J` is trapezoidal nonnegative net extraction. Actuator variation is the sum of absolute command changes without time weighting. Violation count adds different categories of sampled violations and should not be interpreted as distinct incidents. [src/+thermoweave/+results/computeMetrics.m:1–24](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/src/%2Bthermoweave/%2Bresults/computeMetrics.m#L1-L24)

## Browser parameter map

| API key | Repo UI default | Generic API default | Range / unit |
|---|---:|---:|---|
| `heatW` | 600 | 1200 | 100–3000 W |
| `coolingWK` | 30 | 40 | 10–120 W/K |
| `capacityJPerK` | 12000 | 18000 | 3000–60000 J/K |
| `ambientC` | 20 | 25 | 0–45 °C |

Generic `resolveParameters('thermal',{})` uses generic defaults; the UI overlays repository defaults before calling it. Inputs are clamped to ranges but not snapped to slider increments; nonfinite/non-numeric values fall back. Time is clamped to 0–60 min, with invalid time set to zero. The fourth preset uses 600 W, 30 W/K, 24000 J/K and 35 °C. These constants are not a calibration of the 12/36-cell native model. [docs/index.html:167–173](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/docs/index.html#L167-L173) [docs/index.html:231–260](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/docs/index.html#L231-L260) [docs/lesson-config.json:1–320](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/docs/lesson-config.json#L1-L320)
