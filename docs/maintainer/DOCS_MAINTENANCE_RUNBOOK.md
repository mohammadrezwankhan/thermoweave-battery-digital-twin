# Documentation maintenance runbook

Canonical Markdown/CFF is edited directly; `docs/reference/index.html` is generated from `docs/reference/chapters.json`. Existing interactive surfaces keep their own scripts/configuration and receive only a reference link. Keep native science, historical evidence and browser teaching descriptions separate. [Index](../INDEX.md) · [release playbook](CI_CD_AND_RELEASE_PLAYBOOK.md).

## Updating a source claim

1. Record the new immutable source SHA and complete canonical tree. Inspect the relevant implementation, callers, tests and active configuration rather than relying on a README summary.
2. Check path, line range, symbol, units, sign convention, shape, fallback/error behavior and whether the code was actually executed. Use source links pinned to that SHA.
3. Update the architecture/API/example/science pages affected. Preserve dated historical results; add a new receipt instead of relabeling an older one.
4. For a changed numerical contract, require a separate scientific review and applicable native checks. For a docs-only change, keep implementation/model/result/workflow/dependency/license bytes unchanged.
5. Run focused checks, regenerate the reference view and inspect the exact diff. Freeze the candidate identity for independent QA.

The three command helpers are intentionally narrow:

```bash
python scripts/portfolio/validate_guide.py
node docs/reference/check_lesson.cjs
python docs/reference/build_reference.py
python docs/reference/build_reference.py --check
```

The existing guide validator checks source-path/config alignment and selected HTML markers. The lesson helper checks embedded configuration/pure math fixtures without DOM execution. The renderer converts canonical Markdown using Pandoc/MathML, namespaces chapter anchors and rewrites internal links. It rejects active embedded chapter HTML and escaping/missing paths. It does not deploy or run native tools. [scripts/portfolio/validate_guide.py:1–33](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/scripts/portfolio/validate_guide.py#L1-L33)

## Documentation synchronization map

| Changed source | Documentation and evidence to revisit |
|---|---|
| Defaults/validation/scenarios | Parameter table, setup/examples, input contracts, config/field inventory |
| Graph/electrical/coolant/controller/RHS | Equations, sign/units/limits, scientific debt, test evidence and native receipts |
| Result/export/metrics | Schema/shape table, consumer caveats, full-grid vs sampled evidence |
| MATLAB build or workflows | Toolchain, CI triggers/gates, release/rollback procedure, current policy snapshot |
| Browser model/checkpoints | Browser catalogue, exact eight fixtures, synthetic labels, supported-browser behavior |
| Learning catalogues/provenance | Their own immutable revision/config synchronization and personal-state semantics |
| Licenses/authorship/citation | Preserve named authors; verify exact release facts; no invented version/date |
| Roadmap decisions | Status and dependency changes backed by completed acceptance evidence |

## Review and accessibility

The reading view uses the incumbent warm/dark palette, a constrained prose width, a sidebar that collapses to native disclosure navigation, visible focus styles, scrollable tables and script-free MathML. Its static checks verify anchors, syntax and source freshness. A later actual browser review must check desktop/mobile line wrapping, formula overflow, keyboard navigation, contrast, zoom and assistive-technology behavior; those are not automatically guaranteed by semantic tags.

Do not edit generated HTML by hand. If a Markdown heading or path changes, inspect all chapter links and fragment destinations after generation. Keep CSS/renderer hashes in the embedded input manifest. Avoid remote script/font dependencies for the handbook. When a command needs a missing licensed product, mark it `NOT_RUN` and preserve the precise gate rather than substituting a synthetic result.

## Change and recovery records

Keep the command, timestamp, environment, exact candidate fingerprint/commit, stdout/stderr, status and limitations with each receipt. Review all required 24 outputs and all tracked-entry dispositions; indexed metadata/binaries must remain labeled as indexed. An author verifies its own work but cannot supply independent QA. Any final merge/deployment identity must be observed after that action, not embedded as a predicted SHA in the very commit it describes.

If the handbook is stale, rebuild it from the approved canonical files. If a source statement is wrong, correct it and identify the old claim rather than touching physics to make prose true. If delivery fails, use the [recovery runbook](../owner/BUS_FACTOR_RECOVERY_RUNBOOK.md) and retain evidence. No regular schedule or automation is created by this runbook; the owner may later adopt the proposed cadence.
