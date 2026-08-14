# ThermoWeave scientific and controls specification

ThermoWeave is a reproducible, reduced-order model for a synthetic battery-like assembly. Every numerical value in this document is an **assumption for software experiments**. It is not fitted to a named cell and must not be presented as validated real-cell accuracy.

## States, units, orientation, and signs

- There are $N$ thermal/electrical vertices (cells or lumped zones), indexed $i=1,\ldots,N$. The solver state is the $2N\times1$ column $y=[T;z]$, with temperature $T$ in kelvin and SOC $z$ dimensionless in $[0,1]$.
- Node-indexed inputs and derivatives are $N\times1$ columns ordered by node ID. Canonical result histories are **$N_t\times N$ matrices** (`time_s` is $N_t\times1$); row $k$ is the complete state at output time $t_k$ and column $i$ is node $i$. This row/time orientation is part of the result contract.
- Positive current $I_i$ (A) means discharge. It creates positive Joule heat and decreases SOC. Negative current means charge.
- Heat flow $q_{a\to b}>0$ is directed from $a$ into $b$. Temperatures are in kelvin in all laws; Celsius is display-only.
- Thermal capacity $C_i$ is J/K, edge conductance $g_e$ and boundary conductance $H$ are W/K, heat rate $q$ is W, current is A, resistance is ohm, capacity $Q_C$ is coulomb, mass flow is kg/s, and coolant heat capacity $c_p$ is J/(kg K).

## Graph thermal ODE

Let $E$ be the number of thermal edges and $B\in\mathbb R^{E\times N}$ an oriented incidence matrix (one $+1$ and one $-1$ for an ordinary edge). For edge conductances $g_e\ge0$,

$$L_g=B^\mathsf{T}\operatorname{diag}(g_e)B,\qquad C=\operatorname{diag}(C_i).$$

The solid balance is

$$C\dot T=-L_gT-H_a(T-T_a)+q_{\mathrm{gen}}(T,z,I)+q_{\mathrm{cool}}(T,T_c)+q_{\mathrm{ext}},\tag{1}$$

where $H_a=\operatorname{diag}(H_{a,i})$ and $H_{a,i}=h_iA_i$ (W/K). $T_a$ is an $N\times1$ vector after scalar or zonal expansion. Equivalently,

$$\dot T=C^{-1}\left[-(L_g+H_a)T+H_aT_a+q_{\mathrm{gen}}+q_{\mathrm{cool}}+q_{\mathrm{ext}}\right].$$

The graph Laplacian is positive semidefinite. Each connected component needs a finite thermal boundary (or a declared energy-conserving mode) to avoid an unobservable uniform-temperature mode. Internal edge fluxes cancel in the pack-level energy sum; they still matter for gradients.

### Joule and optional entropic heat

The irreversible term is always enabled:

$$q_{\mathrm{J},i}=I_i^2R_i(T_i,z_i,\theta_R)\quad [\mathrm W],\qquad R_i>0.$$

An explicit `entropicHeat` flag enables reversible heat:

$$q_{\mathrm{ent},i}=-I_iT_i\left(\frac{\partial U_{\mathrm{oc}}}{\partial T}\right)_i,\qquad q_{\mathrm{gen},i}=q_{\mathrm{J},i}+\mathbf 1_{\mathrm{ent}}q_{\mathrm{ent},i}.\tag{2}$$

The entropy slope is V/K, so $IT(\partial U_{\mathrm{oc}}/\partial T)$ is W. With positive discharge current, a positive slope makes a heat sink; charging reverses the sign. Do not clamp $q_{\mathrm{ent}}$; report its sign and magnitude.

A transparent synthetic resistance law is

$$R_i=R_{0,i}\left[1+\alpha_T(T_i-T_{\mathrm{ref}})+\alpha_z(1-z_i)\right],$$

with a positive lower bound only as a parameter-validity guard. It is not an electrochemical ageing model.

### SOC evolution

Let $Q_{i,C}$ be capacity in coulombs, $I_i^+=\max(I_i,0)$ and $I_i^-=\min(I_i,0)$. Coulomb counting with optional efficiencies is

$$\dot z_i=-\frac{I_i^+/\eta_{d,i}+\eta_{ch,i}I_i^-}{Q_{i,C}},\qquad 0\le z_i\le1,\tag{3}$$

where $0<\eta_d,\eta_{ch}\le1$. Set both to one for the ideal case. An out-of-range event is reported if integration leaves $[0,1]$; silent clipping hides an accounting error.

## Topology semantics

### Rectangular topology

For an $n_r\times n_c$ layout, node ID is

$$i=r+(c-1)n_r,\qquad r=1,\ldots,n_r,\quad c=1,\ldots,n_c.$$

Edges join existing up/down/left/right neighbours. Horizontal and vertical conductances may differ. The index map is metadata only: dynamics use the edge list and $B$, so a permutation of node storage cannot change results.

### Staggered topology

Alternating rows are offset by half a pitch. Store physical $(x_i,y_i)$ and an explicit edge list from the declared neighbour rule (lateral neighbours plus nearest opposing-row centres within a fixed tolerance, for example). Unequal degree and edge length are allowed; edge conductance is supplied per edge or computed from declared $kA/\ell_e$. Never apply a rectangular stencil to staggered storage. The same $B,L_g$ equations apply.

### Three-dimensional Cartesian topology

For an $n_r\times n_c\times n_l$ cuboid, the deterministic node ID is

$$i=r+(c-1)n_r+(l-1)n_rn_c.$$

Orthogonal edges connect nearest neighbours in $x$, $y$, and $z$ with independently declared conductances $g_x$, $g_y$, and $g_z$. The result schema exposes physical $(x_i,y_i,z_i)$ coordinates, the axis label of each edge, and Boolean masks for the six exterior faces. These masks identify boundaries; they do not silently add heat transfer. A one-layer cuboid is required to produce the same in-plane edges, conductances, coordinates, and Laplacian as the legacy rectangular layout.

## Boundary representations

Every boundary declares its representation and units.

1. **Scalar:** one boundary temperature $T_a$ and one resolved node conductance $H$ (W/K) are broadcast to selected nodes. If source data is supplied as an area-normalized coefficient $h$ (W/(m$^2$ K)), the caller must convert it explicitly as $H_i=hA_i$ before validation; the core never silently guesses units.
2. **Vector:** an $N\times1$ value gives one quantity per node. Implicit row vectors or accidental broadcasting are invalid.
3. **Zonal:** a zone map $m_i\in\{1,\ldots,K\}$ and zone vector $v_z\in\mathbb R^{K\times1}$ expand as $v_i=v_{z,m_i}$. Weighted zone temperature is $T_{z,k}=\sum_{i:m_i=k}w_iT_i/\sum_{i:m_i=k}w_i$ with declared $w_i\ge0$.
4. **Coolant:** channel segment incidence $S_{ik}\ge0$ and conductance $H_{ik}$ (W/K) define $q_{\mathrm{cool},i}=\sum_kH_{ik}(T_{c,k}-T_i)$. Coolant is either algebraically marched or dynamic, never both in one run.

## Coolant marching and direction

For channel segments $k=1,\ldots,K$, inlet $T_{c,0}$, mass flow $\dot m>0$, and coolant heat capacity $c_p$, the default quasi-steady segment balance is

$$\left(\dot m c_p+\sum_iH_{ik}\right)T_{c,k}=\dot m c_pT_{c,k-1}+\sum_iH_{ik}T_i,\tag{4}$$

$$q_{\mathrm{solid}\to c,k}=\sum_iH_{ik}(T_i-T_{c,k}),\qquad q_{\mathrm{cool},i}=\sum_kH_{ik}(T_{c,k}-T_i).$$

Consequently, $\sum_kq_{\mathrm{solid}\to c,k}=\dot m c_p(T_{c,K}-T_{c,0})$ up to numerical error. A reverse-flow case reverses the declared segment order and inlet while preserving physical segment IDs; it must not negate $\dot m$ inside a forward march. If coolant inertia is required, add $C_{c,k}\dot T_{c,k}$ states and include inlet/outlet enthalpy in the residual.

## Controllers

### Baseline zonal controller

At sample time $t_j$, measure weighted zone means and apply zero-order hold between samples:

$$u_k=\operatorname{sat}_{[0,1]}\left(K_{p,k}(T_{z,k}-T_{\mathrm{ref}})\right),\qquad q_{\mathrm{rem},k}=u_kq_{\mathrm{max},k}.\tag{5}$$

Cooling is distributed as $q_{\mathrm{ext},i}=-w_{ik}q_{\mathrm{rem},k}$, with nonnegative weights summing to one in each zone. Any deadband, first-order sensor filter, rate limit, and sensor noise are fixed in the scenario manifest.

### Optional advanced controller

The included optional advanced policy solves a reduced-horizon quadratic program. It predicts each zone mean with $T_{z,k}^{+}=T_{z,k}-\beta_k u_k$, where $\beta_k=q_{\max,k}H_p/C_{z,k}$, and minimizes zone tracking error, deviation from the zone mean (a spread proxy), command movement, and cooling effort. It is a transparent supervisory approximation, not a full plant MPC implementation. A future full-graph MPC may use:

$$J=\sum_{j=0}^{H_p-1}\left(\lVert T_z-T_{\mathrm{ref}}\rVert_Q^2+\lambda_u\lVert\Delta u\rVert_2^2+\lambda_eE_{\mathrm{cool},j}+\lambda_g\lVert DT\rVert_2^2\right)+\lVert T_z(H_p)-T_{\mathrm{ref}}\rVert_{Q_f}^2.$$

The implemented constraints are actuator bounds and rate limits. A full MPC would additionally impose $T_{\min}\le T_i\le T_{\max}$, $|T_i-T_j|\le\Delta T_{\max}$ on every edge, $0\le z_i\le1$, and coolant-flow bounds. An optimization failure emits a fallback event and invokes the bounded baseline controller; constraints are never silently relaxed.

## Uncertainty and fault injection

Uncertainty is sampled from declared distributions with recorded seeds. A reference dispersion is lognormal $R_0$ with 5% coefficient of variation and independent uniform +/-10% perturbations for $C$, $g$, and $H$; correlations, if any, must be explicit. Faults are records $(t_{\mathrm{start}},t_{\mathrm{end}},\mathrm{target},\mathrm{type},\mathrm{magnitude})$. Examples include blocked channel (multiply $H$ or $\dot m$), pump loss, sensor bias/dropout, stuck actuator, contact-conductance change, current imbalance, and localized heat multiplier. Runs declare single-fault versus seeded combined-fault mode.

## Canonical metrics and energy residual

Every canonical core result reports $T_{\max}$, $T_{\min}$, mean and 95th-percentile temperature, peak/RMS edge gradient, time above the declared limit, SOC mean/spread and violations, cooling energy, actuator variation, aggregate constraint violations, declared/runtime events, and normalized energy residual. Coolant outlet temperature remains in boundary diagnostics rather than a canonical metric. Fault detection delay, excursion, and recovery are experiment-specific metrics and are not emitted unless a diagnostic experiment explicitly computes them.

For the solid, define stored energy $U_s=\sum_iC_iT_i$, ambient export $q_{a,i}=H_{a,i}(T_i-T_{a,i})$, and coolant export $q_{\mathrm{solid}\to c,k}$ as above. The instantaneous residual is

$$r_s(t)=\frac{dU_s}{dt}-\left[\sum_iq_{\mathrm{gen},i}+\sum_iq_{\mathrm{ext},i}-\sum_iq_{a,i}-\sum_kq_{\mathrm{solid}\to c,k}\right].$$

Report $\epsilon_E=\max_t|r_s(t)|/\max(P_{\mathrm{scale}},10^{-9}\ \mathrm W)$, where $P_{\mathrm{scale}}$ is the largest absolute bracketed power, plus integrated and sign-separated residual totals. For dynamic coolant, add $U_c=\sum_kC_{c,k}T_{c,k}$ and inlet/outlet enthalpy. A large residual invalidates controller comparisons.

## Synthetic default parameters (assumptions)

Reference case: 3x4 rectangular layout ($N=12$), node mass 0.045 kg, $c_p=900$ J/(kg K), $C_i=40.5$ J/K, $g_x=0.80$ W/K, $g_y=0.60$ W/K, $H_{a,i}=0.25$ W/K, $T_a=T_{\mathrm{ref}}=298.15$ K, $R_{0,i}=8$ mOhm, $\alpha_T=0.003$ K$^{-1}$, $\alpha_z=0.05$, and $Q_{i,C}=18000$ C. Entropic heat is off unless enabled with $(\partial U_{\mathrm{oc}}/\partial T)=0.0002$ V/K. Nominal discharge is 60 A (5 A/node). Four equal zones use $q_{\max}=25$ W/zone, $K_p=0.20$ K$^{-1}$, and a 2 s control period. A four-segment coolant uses $\dot m=0.010$ kg/s, $c_p=3800$ J/(kg K), and $H_{ik}=2.0$ W/K for each assigned three nodes. These values are convenient unit-test assumptions only.

## Solver assumptions and limitations

Use adaptive implicit BDF or Rosenbrock integration when conductance/coolant/controller coupling is stiff; explicit fixed-step integration requires a declared stability check. Controller commands are zero-order held. Algebraic coolant marching is evaluated consistently in each ODE right-hand-side call. Output interpolation must preserve event timing.

This is a lumped, isothermal-node model with simplified resistance/SOC laws. It omits electrochemical diffusion, phase change, radiation unless explicitly added, validated ageing, and safety chemistry. Results support implementation consistency and relative synthetic controller behaviour, not cell prediction, certification, or warranty claims.
