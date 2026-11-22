# Native E9 model adapter

The standard adapter accepts the canonical `thermoweaveRaw` output. For the approved fixed-input native E9 model, set `"outputContract": "thermoweave.native-e9/v1"` in the local generated model manifest. The model's `nativeE9` timeseries contains the per-cell temperatures, one common SOC channel, and the held zone temperatures, in that order.

This contract accepts only the default scenario and changes to its solver step and tolerances. The adapter reconstructs the signed heat ledger from native states and the held controller, then uses the canonical result mapper. Preserve the reviewed model and manifest separately from the tracked source. E9 acceptance still requires the independent baseline and refinement comparison.
