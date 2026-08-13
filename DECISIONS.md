# Architecture Decision Record

## D-001 — Portable graph core is authoritative for mandatory gates

**Status:** Accepted.

**Decision:** Implement the required demonstrations in plain MATLAB first. Treat Simscape Battery as an optional comparison adapter.

**Why:** This keeps the project reproducible without licensed add-ons while allowing higher-fidelity comparison where available.

**Consequence:** No claim may frame either implementation as ground truth.

## D-002 — Kelvin internally, Celsius only at presentation boundaries

**Status:** Accepted.

**Decision:** All thermal computation and persisted canonical arrays use kelvin. User-facing plots may convert to degrees Celsius and must label the conversion.

**Why:** It avoids ambiguity in entropic and energy calculations.

## D-003 — Explicit column-vector convention

**Status:** Accepted.

**Decision:** Cell-indexed and zone-indexed runtime arrays are columns; time histories are time-by-entity matrices. Scalar expansion is performed only by validation utilities.

**Why:** It prevents accidental MATLAB row/column broadcasting.

## D-004 — Coolant boundaries are computed, not renamed constants

**Status:** Accepted.

**Decision:** Coolant mode marches inlet temperature through a declared channel order with a finite-capacity flow balance.

**Why:** Spatial variation must arise from physics or an explicitly prescribed field.

## D-005 — Controller fallback is observable

**Status:** Accepted.

**Decision:** The baseline policy is always available. Advanced optimization is product- and solve-status-gated, and fallback is recorded as an event.

**Why:** Optional tooling or infeasible optimization must not silently change behavior.

## D-006 — Static web delivery consumes exported data only

**Status:** Accepted.

**Decision:** The project page is framework-free and reads compact project-generated JSON. No benchmark number is hand-entered in presentation code.

**Why:** This supports GitHub Pages and preserves result traceability.

## D-007 — Simulink structural work waits for library-policy declaration

**Status:** Pending owner input.

**Decision:** No Simulink block architecture will be assumed until custom reusable libraries are declared or explicitly declined through the required setup workflow.

**Why:** The installed modeling skill treats reuse and block-policy discovery as a blocking gate.

## D-008 — Core result timestamps are deterministic by default

**Status:** Accepted.

**Decision:** Canonical core results omit a wall-clock value (`timestampUTC=""`) and record `timestampPolicy="omitted-for-deterministic-core"`; verification/build reports may retain their own generation timestamp.

**Why:** Scientific result JSON and hashes must reproduce for the same configuration and seed. A packaging timestamp is not part of model state.

## D-009 — Boundary conductance is resolved W/K

**Status:** Accepted.

**Decision:** Core configuration fields ending in `Conductance_W_per_K` are already-resolved node/edge conductances. Area-normalized coefficients must be explicitly converted by the caller.

**Why:** Silent multiplication by cell area would make units ambiguous and could mis-scale user configurations.

## D-010 — Advanced control is a reduced-horizon quadratic supervisor

**Status:** Accepted.

**Decision:** The optional controller predicts zonal temperature response over a declared horizon and penalizes temperature tracking, zone spread, actuator movement, and cooling effort under bounds/rates. It is not represented as full plant MPC.

**Why:** This matches the implemented transparent model and installed Optimization Toolbox while retaining explicit fallback behavior.
