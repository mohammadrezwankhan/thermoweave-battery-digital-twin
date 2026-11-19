# Troubleshooting by failed contract

Begin with the exact command, working directory, source revision, complete error identifier and detected MATLAB products. Preserve a small synthetic reproducer and the original log. Avoid replacing a failed scientific assertion with a looser threshold before checking units, mapping and timing. [Setup](SETUP_AND_REPRODUCIBILITY.md) and [interfaces](API_CLI_AND_INTERFACES.md) give the valid entrypoints.

| Symptom | Evidence-based cause to check | Recovery / verification |
|---|---|---|
| `thermoweave` is undefined | `src` package not on the path | Run `startup` from repository root; inspect `which thermoweave.simulate -all` |
| `run3DStudy` is undefined | `startup` omits `examples` | Add `fullfile(pwd,'examples')`; then invoke it |
| No-input `thermoweave.simulate` fails | Public wrapper references required `source` argument | Use `thermoweave.simulate([])` or `runDemo()` |
| Cell count or vector dimension error | Rows×columns×layers and array counts disagree | Resolve configuration, inspect topology order, use scalar or correctly sized values |
| Multi-layer rectangular variability dimension error | Rectangular variability count omits layers | Record the defect; use the documented cuboid study for its intended case; do not patch science in a docs change |
| SOC leaves `[0,1]` | Current integration has no saturation/termination event | Shorten/adjust the declared experiment and inspect current/capacity/sign; report recorded violation |
| Changing `samplePeriod_s` has no expected effect | Main simulation updates on output intervals | Inspect outputStep and final short interval; avoid claiming an independent control clock |
| Changing mass/cp changes nothing | ODE consumes `thermalCapacity_J_per_K` directly | Explicitly update resolved thermal capacity with a documented unit calculation |
| Changing ambient H changes nothing | Scalar/vector boundary uses its own conductance | Edit the mode's active field; inspect stored boundary histories |
| Advanced mode falls back | Missing `quadprog`, exception or unsuccessful optimization | Inspect status/event and product list; report fallback, not advanced success |
| Simscape skips | Product, library policy, manifest or model missing | Retain exact skip; resolve prerequisites through authorized modeling setup |
| Legacy playback fails from a local file | `fetch()` of separate JSON may be restricted | Use a local HTTP server; inspect response/schema; main analytic lab is a different surface |
| Tiny residual seems inconsistent with a transient error | Residual reuses the same RHS algebra | Compare independent integrated balance and solver convergence; tiny residual is insufficient |
| Exported histories do not match metadata grid | Stride affects arrays but not `metadata.timeBase_s` | Use `time_s` for exported rows; preserve source result and full-grid metrics |

Source contracts: [startup.m:1–10](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/startup.m#L1-L10) [src/+thermoweave/simulate.m:1–102](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/src/%2Bthermoweave/simulate.m#L1-L102) [src/+thermoweave/+uncertainty/applyVariability.m:1–36](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/src/%2Bthermoweave/%2Buncertainty/applyVariability.m#L1-L36) [src/+thermoweave/+control/advancedController.m:1–60](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/src/%2Bthermoweave/%2Bcontrol/advancedController.m#L1-L60) [src/+thermoweave/+results/exportJSON.m:1–12](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/src/%2Bthermoweave/%2Bresults/exportJSON.m#L1-L12) [docs/app.js:166–207](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/docs/app.js#L166-L207).

## Browser lesson disagreement

Reset or apply the selected module preset, check the fixed checkpoint time, and inspect all four inputs. The analytic API's generic thermal defaults differ from this repository's configured values. A strict `<` or `>` checkpoint ignores the tolerance; equality uses absolute tolerance. Prior module verification is retained in the page's in-memory progress map even after inputs change, while the currently displayed check results are cleared. Recheck the current experiment before interpreting completion. [docs/index.html:320–337](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/docs/index.html#L320-L337) [docs/index.html:338–475](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/docs/index.html#L338-L475)

If clipboard access fails, the lesson UI attempts a copy fallback and then selects JSON for manual copying. The learning-path guide keeps notes in local storage and offers an exported study plan when storage is unavailable. Neither action runs the copied MATLAB command. DOM, keyboard, download and storage behavior still require an actual supported-browser check; source inspection does not establish accessibility conformance. [docs/native-lessons.html:114–164](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/docs/native-lessons.html#L114-L164) [docs/portfolio/index.html:437–468](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/docs/portfolio/index.html#L437-L468)

## Documentation renderer errors

`Reference HTML is stale` means a canonical input or the renderer changed. Run `python docs/reference/build_reference.py`, inspect the resulting HTML diff and rerun `--check`. A missing `pandoc` executable is a documentation-tool prerequisite, not a MATLAB failure. A rejected escaping/missing path should be fixed in the canonical Markdown link; do not weaken path validation. The generated handbook uses local CSS and MathML with no script, and its manifest binds the input hashes to the pinned scientific source.

## Reporting an unresolved result

Include whether the observation is a source inference, pure arithmetic execution, native runtime, provider check or browser interaction. Attach sanitized configuration and actual status; state any unavailable product or unknown policy. Follow [SECURITY.md](../../SECURITY.md) for vulnerability reporting and [known debt](../maintainer/FAILURE_MODES_AND_TECH_DEBT.md) for existing issue categories. A stored report or a successful source-head check cannot clear a later changed candidate.
