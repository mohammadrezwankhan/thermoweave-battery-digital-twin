# Equations and derivations

This page explains implemented equations at source `5f29e34788b0f7ee58e2feeafc4df5d48a9a687a`, with deductions clearly separated from observed execution. All parameter values are synthetic. No measured calibration, high-fidelity validation or safety qualification is established by this review. [Symbols](PARAMETERS_AND_SYMBOLS.md) · [limits](ASSUMPTIONS_AND_LIMITS.md) · [worked examples](../developer/WORKED_EXAMPLES_AND_LABS.md).

## State, graph and positive heat direction

There are `N` temperatures $T_i$ in K and SOC fractions $z_i$. The state is $y=[T;z]$. For an edge joining cells $i,j$, conductance $g_{ij}>0$ is in W/K and heat entering $i$ is $g_{ij}(T_j-T_i)$. This is a lumped graph representation; cell spacing and conductance are separately supplied assumptions, not a finite-volume material discretization derived automatically from geometry. [src/+thermoweave/+thermal/buildTopology.m:1–178](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/src/%2Bthermoweave/%2Bthermal/buildTopology.m#L1-L178) [src/+thermoweave/simulate.m:54–59](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/src/%2Bthermoweave/simulate.m#L54-L59)

Choose each incidence row as +1 at its first node and −1 at the other. Then $L=B^T\operatorname{diag}(g)B$ and conductive inflow is $-LT$. Symmetry and nonnegative conductances imply $T^TLT=\sum_e g_e(T_i-T_j)^2\ge0$ and $L\mathbf1=0$. Summing all cell equations cancels internal edge flows. These are algebraic properties of the constructed graph, not experimental findings. The topology test checks symmetry, row sums and an eigenvalue tolerance for one 2×3×2 case. [src/+thermoweave/+thermal/buildTopology.m:145–169](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/src/%2Bthermoweave/%2Bthermal/buildTopology.m#L145-L169) [tests/unit/TestTopology3D.m:35–54](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/tests/unit/TestTopology3D.m#L35-L54)

The implemented temperature ODE is

$$C_i\dot T_i=\sum_j g_{ij}s_{ij}(T_j-T_i)+H_i(T_{b,i}-T_i)+q_i+q_{\mathrm{cool},i}+q_{\mathrm{ext},i}.$$

$C_i$ is the explicitly resolved `thermalCapacity_J_per_K`; it is not recomputed from mass and heat capacity at runtime. $s_{ij}$ is a fault conductance multiplier. $q_{\mathrm{cool}}$ includes passive segment exchange and active zone extraction. Every term on the right has units W, yielding K/s after division by J/K. Negative heat removes energy. [src/+thermoweave/simulate.m:54–59](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/src/%2Bthermoweave/simulate.m#L54-L59) [src/+thermoweave/+config/defaultConfig.m:12–20](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/src/%2Bthermoweave/%2Bconfig/defaultConfig.m#L12-L20)

## Electrical heat and SOC

The implementation uses a temperature/SOC-dependent resistance, with a machine-epsilon floor:

$$R_i=\max\left(R_{0,i}[1+\alpha_T(T_i-T_{\mathrm{ref}})+\alpha_z(1-z_i)],\epsilon\right),$$

$$q_{J,i}=I_i^2R_i,\qquad q_{S,i}=-I_iT_i\frac{\partial U_{\mathrm{oc}}}{\partial T},\qquad q_i=m_{q,i}(q_{J,i}+\chi_Sq_{S,i}).$$

$\chi_S$ enables entropy heat; it is false by default. Positive current means discharge. Joule heat is nonnegative, while the entropy contribution can heat or cool according to current and slope. K, not °C, must be used in the entropy expression. A `current_scale` fault changes current before heat/SOC evaluation; a heat multiplier changes generated heat without equivalently changing SOC. [src/+thermoweave/+electrical/heatGeneration.m:1–10](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/src/%2Bthermoweave/%2Belectrical/heatGeneration.m#L1-L10) [src/+thermoweave/simulate.m:54–58](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/src/%2Bthermoweave/simulate.m#L54-L58) [src/+thermoweave/+uncertainty/applyFaults.m:1–34](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/src/%2Bthermoweave/%2Buncertainty/applyFaults.m#L1-L34)

$$\dot z_i=-\frac{\max(I_i,0)/\eta_d+\min(I_i,0)\eta_c}{Q_i}.$$

Here capacity $Q_i$ is in coulombs, $1\ \mathrm{Ah}=3600\ \mathrm C$, and efficiencies are dimensionless. Positive discharge reduces SOC and negative charge increases it. The argument `soc` to `socDerivative` determines node count, but the RHS does not taper at SOC limits. Integration is not clipped; out-of-range values produce events/metrics. The source sign test checks both current signs with a $10^{-15}$ absolute tolerance, but that test was not run locally during this pass. [src/+thermoweave/+electrical/socDerivative.m:1–7](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/src/%2Bthermoweave/%2Belectrical/socDerivative.m#L1-L7) [tests/unit/TestConfigAndPhysics.m:99–123](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/tests/unit/TestConfigAndPhysics.m#L99-L123) [src/+thermoweave/simulate.m:23–24](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/src/%2Bthermoweave/simulate.m#L23-L24)

## Prescribed and coolant boundaries

Scalar and vector modes use the configured boundary temperature/conductance expanded to `N` cells. Zonal mode expands zone inputs through `topo.zoneId`, not a supplied `boundary.zoneId`. Coolant mode retains an ambient path in parallel and adds quasi-steady serial coolant exchange. [src/+thermoweave/+coolant/evaluate.m:1–28](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/src/%2Bthermoweave/%2Bcoolant/evaluate.m#L1-L28)

For segment $k$, incoming coolant temperature is $T_{c,k-1}$ and `H(i,k)` is node-to-segment conductance. A steady enthalpy balance gives

$$\dot m c_p(T_{c,k}-T_{c,k-1})=\sum_i H_{ik}(T_i-T_{c,k}),$$

$$T_{c,k}=\frac{\dot m c_p T_{c,k-1}+\sum_i H_{ik}T_i}{\dot m c_p+\sum_i H_{ik}},\qquad q_{\mathrm{seg},i}=\sum_kH_{ik}(T_{c,k}-T_i).$$

The code replaces the denominator with `max(denominator,eps)`. With strictly positive flow and nonnegative conductances, this is a weighted temperature average. There is no coolant thermal-storage state or transport delay. When flow becomes zero through a pump fault, the formula's degenerate behavior is an implementation limit, especially if all conductances are also zero. Negative nominal flow is invalid; the supplied reverse-flow study reassigns segment order. [src/+thermoweave/+coolant/march.m:1–8](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/src/%2Bthermoweave/%2Bcoolant/march.m#L1-L8) [src/+thermoweave/+coolant/evaluate.m:1–68](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/src/%2Bthermoweave/%2Bcoolant/evaluate.m#L1-L68) [tests/unit/TestConfigAndPhysics.m:124–153](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/tests/unit/TestConfigAndPhysics.m#L124-L153)

Summing the segment balance telescopes to $\sum_k q_{\mathrm{into\ coolant},k}=\dot m c_p(T_{c,K}-T_{c,0})$. A direct static march check is more independent than reusing the ODE residual and is tested at $10^{-9}$ W in the source test. This proves a limited algebraic balance for the chosen fixture, not fluid accuracy.

## Cooling controllers

For baseline control, form weighted zone temperatures $\bar T_z=\sum_{i\in z}w_iT_i/\max(\sum_{i\in z}w_i,\epsilon)$. The controller supports weights, but the main simulation passes all ones. The actual unslewed command is

$$u_z^*=\operatorname{clip}_{[0,1]}\left(\max[0,K_{p,z}(\bar T_z-T_{\mathrm{set}})-d]\right).$$

The name `deadband_K` suggests a temperature deadband, but the code subtracts it **after** gain multiplication. For nonzero gain, the effective threshold is `d/Kp`. A future correction requires a compatibility decision, not a silent documentation reinterpretation. The final command is limited to the previous command ± rate × elapsed output interval, then clipped to `[0,1]`. [src/+thermoweave/+control/baselineController.m:1–17](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/src/%2Bthermoweave/%2Bcontrol/baselineController.m#L1-L17) [src/+thermoweave/simulate.m:9–20](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/src/%2Bthermoweave/simulate.m#L9-L20)

Each zone command removes $q_{\max,z}u_z/n_z$ W from every cell in that zone. Total commanded extraction is $\sum_zq_{\max,z}u_z$, subject to actuator faults. No pump motor or compressor efficiency is modeled. `coolingPower_W = max(0,-sum(qCool_W))` is a net extraction proxy that also includes passive coolant exchange, and `coolingEnergy_J` integrates that proxy. [src/+thermoweave/+coolant/evaluate.m:22–28](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/src/%2Bthermoweave/%2Bcoolant/evaluate.m#L22-L28) [src/+thermoweave/+results/computeMetrics.m:1–24](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/src/%2Bthermoweave/%2Bresults/computeMetrics.m#L1-L24)

Advanced control constructs a reduced zonal quadratic problem. With $\beta_z=q_{\max,z}h/C_z$, $D=\operatorname{diag}(\beta)$, $P=I-\mathbf1\mathbf1^T/Z$, $W=I+\lambda_G P^TP$, the implemented matrices are

$$H=D^TWD+\lambda_U I,\quad f=-D^TW(\bar T-T_{\mathrm{set}}\mathbf1)-\lambda_Uu_{\mathrm{prev}}+\lambda_Es,$$

where $s=q_{\max}/\max(\max q_{\max},\epsilon)$. `quadprog` minimizes $\tfrac12u^THu+f^Tu$ under command and rate bounds. The horizon enters a reduced predicted temperature drop; there is no full plant trajectory, hard cell-temperature/SOC constraint or full MPC model. The exact factors above matter: replacing them with an assumed sum-of-squares objective changes the relative weights. `exitflag>0` gives `OPTIMAL`; unavailable/failing solving returns baseline with explicit information/events. [src/+thermoweave/+control/advancedController.m:1–60](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/src/%2Bthermoweave/%2Bcontrol/advancedController.m#L1-L60) [DECISIONS.md:77–83](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/DECISIONS.md#L77-L83). The objective convention is also documented by [MathWorks quadprog](https://www.mathworks.com/help/optim/ug/quadprog.html), consulted 2026-11-19; it supplies solver semantics, not repository execution evidence.

## Numerical stepping, discontinuities and residual interpretation

Output intervals split ODE integration and hold the controller command. The default is `ode15s`, relative tolerance $10^{-6}$, absolute tolerance $10^{-8}$ and max step 0.25 s; `ode45` is selectable. The same scalar absolute tolerance is used across temperature and SOC states. This deserves scale-aware convergence study. Fault/profile breakpoints are evaluated inside the RHS but are not all inserted into the output grid as explicit event stops. Source tests compare selected final temperatures from both solvers at $10^{-4}$ K; that is not a global error bound for arbitrary scenarios. [src/+thermoweave/simulate.m:4–25](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/src/%2Bthermoweave/simulate.m#L4-L25) [src/+thermoweave/+config/defaultConfig.m:6–7](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/src/%2Bthermoweave/%2Bconfig/defaultConfig.m#L6-L7) [tests/integration/TestSimulationIntegration.m:51–83](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/tests/integration/TestSimulationIntegration.m#L51-L83)

MathWorks describes `ode15s` as an adaptive solver for stiff differential equations and explains local error control using `RelTol` and `AbsTol`. Its current [ode15s](https://www.mathworks.com/help/matlab/ref/ode15s.html) and [odeset](https://www.mathworks.com/help/matlab/ref/odeset.html) pages were consulted on 2026-11-19. These general semantics do not demonstrate convergence of this model or certify cross-release agreement.

The code computes, at the same RHS evaluation,

$$r(t)=\sum_i C_i\dot T_i-\left[\sum_iq_i+\sum_iq_{\mathrm{cool},i}+\sum_iq_{\mathrm{ext},i}-\sum_iH_i(T_i-T_{b,i})+\sum_i\mathrm{flow}_i\right],$$

$$r_{\mathrm{norm}}=\frac{\max_k|r(t_k)|}{\max(\max_{k,i}|q_i(t_k)|,10^{-9})}.$$

Since $\dot T$ was just computed from the bracketed terms, this is principally an algebraic self-consistency check. It is not the independently integrated energy defect $\sum_iC_i[T_i(t)-T_i(0)]-\int_0^tP_{\mathrm{external}}\,dt$. Near zero electrical heat the tiny denominator also makes its scaling sensitive. The older `docs/model.md` describes a different normalization and integrated/sign-separated residuals; those statements are not implemented by the inspected path. This page documents the implementation without rewriting historical artifacts. [src/+thermoweave/simulate.m:49–59](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/src/%2Bthermoweave/simulate.m#L49-L59) [docs/model.md:121–136](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/docs/model.md#L121-L136)

## Variability and the separate browser model

The resistance multiplier is $\exp(\sigma X-\sigma^2/2)$ for standard normal $X$ and `sigma = R0CV`. Its mathematical mean is 1 and its coefficient of variation is $\sqrt{e^{\sigma^2}-1}$, approximately `sigma` only for small values. Capacity and conductance scales use uniform draws in $[1-f,1+f]`. The local `RandStream` and explicit seed support repeated scenarios, not a validated manufacturing distribution. [src/+thermoweave/+uncertainty/applyVariability.m:1–36](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/src/%2Bthermoweave/%2Buncertainty/applyVariability.m#L1-L36)

The browser thermal kind solves a different model with Celsius display state, constant heat/conductance/capacity and initial temperature equal to ambient:

$$C\dot T=Q-h(T-T_a),\quad T(t)=T_a+\frac Qh(1-e^{-h(60t)/C}),$$

where browser $t$ is in minutes. Stored heat is $C(T-T_a)/1000$ kJ, removed power is $h(T-T_a)$ W, and `residualW` is $Q-h(T-T_a)$ W. Its allowed input ranges keep $h,C>0$. No graph, SOC, faults, native optimizer or coolant model is executed. Analytic checkpoint agreement cannot validate those native features. [docs/index.html:167–173](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/docs/index.html#L167-L173) [docs/index.html:231–260](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/docs/index.html#L231-L260) [docs/lesson-config.json:1–320](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/docs/lesson-config.json#L1-L320)
