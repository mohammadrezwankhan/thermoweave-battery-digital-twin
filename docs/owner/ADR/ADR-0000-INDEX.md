# Architecture decision index

The canonical historical decisions remain in [DECISIONS.md](../../../DECISIONS.md). This index links them without reassigning their statuses or authorship. Source snapshot: 2026-11-19, `5f29e34788b0f7ee58e2feeafc4df5d48a9a687a`.

| ID | Recorded decision | Recorded status / source |
|---|---|---|
| D-001 | Portable MATLAB graph core is authoritative for mandatory gates | Accepted. [DECISIONS.md:3–9](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/DECISIONS.md#L3-L9) |
| D-002 | Kelvin internally; Celsius only at presentation boundaries | Accepted. [DECISIONS.md:11–17](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/DECISIONS.md#L11-L17) |
| D-003 | Column runtime vectors; time-by-entity histories | Accepted. [DECISIONS.md:19–25](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/DECISIONS.md#L19-L25) |
| D-004 | Coolant boundaries computed by finite-flow march | Accepted. [DECISIONS.md:27–33](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/DECISIONS.md#L27-L33) |
| D-005 | Baseline availability and observable advanced fallback | Accepted. [DECISIONS.md:35–41](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/DECISIONS.md#L35-L41) |
| D-006 | Static web delivery consumes exported data | Accepted historically. [DECISIONS.md:43–49](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/DECISIONS.md#L43-L49) |
| D-007 | Structural Simulink work awaits library-policy declaration | Pending owner input. [DECISIONS.md:51–57](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/DECISIONS.md#L51-L57) |
| D-008 | Canonical core omits wall-clock timestamps | Accepted. [DECISIONS.md:59–65](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/DECISIONS.md#L59-L65) |
| D-009 | Conductance fields are resolved W/K | Accepted. [DECISIONS.md:67–73](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/DECISIONS.md#L67-L73) |
| D-010 | Advanced control is a reduced-horizon quadratic supervisor | Accepted. [DECISIONS.md:75–83](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/DECISIONS.md#L75-L83) |

## Current interpretation and proposed decisions

D-003 describes a convention; current validators often accept matching element counts and flatten row vectors. D-006 accurately describes legacy playback, while the newer main browser lesson is an independent embedded scalar teaching model. D-008 covers core result time fields; environment metadata and serialization still affect hashes. These source observations do not silently rewrite the accepted records. [src/+thermoweave/+config/validateConfig.m:1–392](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/src/%2Bthermoweave/%2Bconfig/validateConfig.m#L1-L392) [docs/app.js:1–207](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/docs/app.js#L1-L207) [docs/index.html:147–337](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/docs/index.html#L147-L337) [src/+thermoweave/simulate.m:85–100](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/src/%2Bthermoweave/simulate.m#L85-L100)

Proposed new decisions should resolve the control clock/deadband contract, independent energy-defect definition, versioned export timebase, and a real optional-model acceptance gate. Their source evidence and acceptance criteria are in [ROADMAP.md](../../../ROADMAP.md); no new decision is marked accepted by this documentation pass.

## Decision template

Record an ID, date, status, accountable role, problem and source evidence; list viable options, selected behavior, unit/shape/compatibility consequences, verification requirements, and a migration/reversal strategy. Mark an option as proposed until its owner/reviewer decision is observed. Link actual implementation and exact-revision checks when accepted. Keep historical superseded decisions for traceability and never invent approval, authorship or completion evidence.
