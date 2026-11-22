# Native E9 model adapter

The standard adapter accepts the canonical `thermoweaveRaw` output. For the approved fixed-input native E9 model, set `"outputContract": "thermoweave.native-e9/v1"` in the local generated model manifest. The model's `nativeE9` timeseries contains the per-cell temperatures, one common SOC channel, and the held zone temperatures, in that order.

This contract accepts only the default scenario and changes to its solver step and tolerances. The adapter reconstructs the signed heat ledger from native states and the held controller, then uses the canonical result mapper. Preserve the reviewed model and manifest separately from the tracked source. E9 acceptance still requires the independent baseline and refinement comparison.

## Executable model provenance (review hold)

For a local generated model, the JSON manifest under `simscape/models/thermoweave-model-manifest.json` must provide `modelFile` (a simple filename or `simscape/models/<filename>.slx`), `modelSha256` (the **exact bytes** of the SLX that will execute), and the appropriate `outputContract`. The adapter rejects absolute/traversal paths, missing or mismatched SHA-256, and any model digest not pinned in `approvedSimscapeModelDigests.m`; it also checks the Simulink-loaded file path and rejects an unsaved dirty model. A SHA pin is **not** proof of independent authorship, licence rights, scientific correctness, or real-cell qualification.

The two currently pinned digests refer only to the owner's E9 model and R2024a-compatible copy documented in [release hold #25](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/issues/25#issuecomment-7078136432). The copied R2024a model requires explicit compatibility review because the export warned that Simscape down-export was unsupported. Any model pin rotation requires a reviewed source change and new exact-head licensed baseline/refinement receipts. Untracked model files or manifest assertions alone must never clear the release gate.
