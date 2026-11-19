# Portfolio integration boundaries

This public package describes **ThermoWeave only**. Its integration surface is a documented synthetic electrothermal example, canonical result/config schemas, generated presentation data, a standalone teaching lab and a source-linked study guide. No cross-repository runtime coupling, shared private dataset or portfolio-wide performance claim is established by the inspected source. [PROJECT_CHARTER.md:1–43](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/PROJECT_CHARTER.md#L1-L43) [src/+thermoweave/+results/makeResult.m:1–10](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/src/%2Bthermoweave/%2Bresults/makeResult.m#L1-L10) [docs/portfolio/lesson-config.json:1–373](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/docs/portfolio/lesson-config.json#L1-L373)

## Implemented local integration

`startup` connects the native source, tools and optional adapter paths. Result producers feed MATLAB visualization and `exportWebData`; the latter supplies the historical browser playback schema. The analytic browser lab has its own embedded scalar-model configuration. The learning-path guide links eight paths to an older immutable source revision and stores review state locally; those links are educational navigation, not service integration. [startup.m:1–10](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/startup.m#L1-L10) [tools/exportWebData.m:1–72](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/tools/exportWebData.m#L1-L72) [docs/app.js:1–207](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/docs/app.js#L1-L207) [docs/index.html:146–337](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/docs/index.html#L146-L337) [docs/portfolio/index.html:437–468](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/docs/portfolio/index.html#L437-L468)

The new documentation index/reference view links Developer, Maintainer and Owner material on the existing Pages route. Existing source/catalogue revisions remain unchanged. This deliberately preserves the meaning of older snapshot records while giving readers a dated current-source guide.

## Proposed reusable vocabulary

| Concept | ThermoWeave representation | Constraint on future exchange |
|---|---|---|
| Source identity | Immutable commit plus configuration hash | Distinguish source/test/documentation/merge/deployment revisions |
| Temperature | Native K; browser display °C | Convert only at explicit presentation boundary; entropy uses K |
| Thermal conductance | W/K per node/edge/segment | Never silently accept W/(m² K) or multiply by area twice |
| Current | A per cell; stored current signal is mean | Label sum/mean/topology assumptions; no implied pack circuit |
| SOC | Dimensionless integrated state | No clipping or chemistry validity implied |
| Evidence status | Observed / historical / skipped / unavailable | Preserve exact status and runtime instead of a universal green badge |
| Data origin | Synthetic scenario/export | No measured calibration or product endorsement |

These are proposed documentation conventions for future public comparisons. They are not implemented adapters. A shared catalogue would need explicit schema/version mapping, dimension/unit tests, provenance and consumer examples. It should publish only information approved for that public scope; this repository does not enumerate other repositories or their findings.

## Entry points for a public profile

Link to the project repository, existing Pages lab, [reference handbook](../reference/index.html) and [source evidence](../SOURCE_EVIDENCE.md). Describe the graph and browser models separately. Use dated claims such as “synthetic 3-D graph study with source-defined tests” unless actual exact-revision native/provider evidence supports a more specific statement. Do not promote preserved 37-test or release metadata as current portfolio-wide health.

Any later profile summary must first read the final independent QA, merge and deployed-content receipts. It may summarize completed outcomes but must carry unresolved optional-product, policy, native-runtime and browser boundaries. The twelve-month roadmap's cross-cutting vocabulary/provenance work remains a proposal with its own acceptance criteria, not an existing dependency on another project.
