# ThermoWeave Battery Digital Twin — learning map

A MATLAB electrothermal battery twin with graph-based cooling, scenario configuration and traceable evidence.

This companion organises 8 selected source-backed paths. It complements the repository's full documentation and native lessons. It does not execute its scientific or operational models.

Open `index.html` locally for search, topic filters, source/configuration inspection, personal notes and study-plan export. The guide has no network or build dependency.

Open the [offline interactive lesson lab](../index.html) and inspect its [lesson configuration](../lesson-config.json).

| Path | Learning objective | Level | First source |
| --- | --- | --- | --- |
| path-01 | Core configuration and equilibrium | Foundation | [config/baseline.json](../../config/baseline.json) |
| path-02 | Compare scalar and vector boundaries | Foundation | [config/vectorized-gradient.json](../../config/vectorized-gradient.json) |
| path-03 | Coolant propagation and restriction | Applied | [config/channel-restriction.json](../../config/channel-restriction.json) |
| path-04 | Bounded zonal cooling | Applied | [examples/runAdaptiveCooling.m](../../examples/runAdaptiveCooling.m) |
| path-05 | Sensor bias and provenance | Applied | [config/sensor-fault.json](../../config/sensor-fault.json) |
| path-06 | Seeded variability study | Applied | [examples/runMonteCarloStudy.m](../../examples/runMonteCarloStudy.m) |
| path-07 | Three-dimensional inter-cell conduction | Advanced | [config/3d-intercell-study.json](../../config/3d-intercell-study.json) |
| path-08 | Optional core/Simscape comparison | Advanced | [examples/compareCoreAndSimscape.m](../../examples/compareCoreAndSimscape.m) |

## Provenance

Repository: <https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin>

Pinned source: 1e8eb66a767104cffbb5c7d921228d9f0b6419fd

Native commands and expected outputs are guidance unless accompanied by a separate execution record. Reviewed-path progress is a personal learning record.
