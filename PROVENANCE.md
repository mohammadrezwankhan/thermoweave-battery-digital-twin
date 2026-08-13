# ThermoWeave provenance and licensing record

Status: repository-wide provenance audit complete for the local package (2026-08-13); workflow pin audit refreshed 2026-08-14. This file describes provenance for the independent MATLAB graph-based battery electrothermal digital twin named ThermoWeave. It is a record of design inspiration and attribution, not a statement of endorsement by any third party.

## Sources consulted

- MathWorks, “Add Vectorized and Scalar Thermal Boundary Conditions to Battery Models,” *MATLAB & Simulink Documentation*, available at <https://www.mathworks.com/help/simscape-battery/ug/battery-thermal-boundary-conditions-vectorized-scalar-example.html> (documentation page states availability since R2024a; accessed 2026-08-13).

The MathWorks page was consulted only to understand high-level terminology and modeling motivation. It is not a source of implementation code for this project.

## High-level concepts learned

The consulted material illustrates that thermal conditions at a battery assembly boundary can be represented either as one common boundary condition or as values that vary by boundary location/cell, and that boundary-to-cell thermal coupling can influence temperature spread. These broad scalar-versus-varying-boundary ideas informed the problem framing only. ThermoWeave's equations, graph representation, parameters, interfaces, scenarios, and validation approach are independently selected and implemented.

## Explicitly excluded / copied-none statement

No source code, prose passages, diagrams, screenshots, numerical scenarios, sample identifiers, API calls, or page structure from the consulted material are copied, translated, or adapted into ThermoWeave. In particular, ThermoWeave does not reproduce the source page's example models, command sequences, object names, or visual layout. Any similarity is limited to unavoidable high-level scientific vocabulary and the general distinction described above.

## Independently developed contributions

Subject to the repository history and any later attribution notices, the following are project-created contributions:

- the graph-based representation of cells, thermal nodes, and electrical/thermal connections;
- the electrothermal state/update logic, parameterization, and coupling choices;
- MATLAB scripts, model/configuration files, tests, examples, figures, and explanatory documentation authored for this repository; and
- project-specific reproducibility, validation, and reporting conventions.

These statements do not transfer ownership of any third-party product, trademark, documentation, or service used to run or publish the project.

## Third-party assets and dependencies

At initialization, no third-party source code, binary, image, diagram, dataset, or generated asset was vendored in this repository. MATLAB and, where applicable, Simulink/Simscape products are external execution dependencies supplied under The MathWorks, Inc. product terms; they are not redistributed here. The final audit found no vendored third-party code, assets, or data. Workflow files reference external GitHub Actions but do not vendor their source. A future dependency, downloaded fixture, benchmark dataset, GitHub Action, or imported media must be recorded in `THIRD_PARTY_NOTICES.md` (including version, source, and applicable license) before release.

After initialization, `docs/assets/og.png` was generated specifically for ThermoWeave using OpenAI's built-in image-generation tool without an input image. The generation record is preserved in `docs/assets/og-prompt.md`. It is used only as a social preview and is not scientific evidence; all quantitative visuals remain traceable to MATLAB result exports.

## Claims and attribution rules

- Describe ThermoWeave as independent work inspired by high-level concepts, never as a MathWorks sample, derivative, certification, or endorsed product.
- Keep source-backed statements separate from project measurements. Performance, accuracy, safety, and validation claims require a reproducible method, inputs, version information, and results; do not infer them from the cited documentation.
- Attribute external documentation and preserve its canonical link. Do not imply that a citation grants permission to copy code, images, or other protected expression.
- Mark generated or imported material at the time it enters the repository. Do not present third-party data or assets as project-created.
- Re-check this record whenever dependencies, datasets, workflows, or redistributable artifacts are added.

## Repository-wide audit conclusion

The audit of the source, documentation, workflows, assets, manifests, `RED_TEAM_REPORT.md`, `LICENSE`, and `CITATION.cff` found the source to be independently authored. It found no copied MathWorks code, prose, diagrams, screenshots, numerical scenarios, names, or page structure. The OpenAI-generated social preview has a retained prompt record and no supplied input image. External GitHub Actions are pinned to recorded commits and are not vendored. On that evidence, the repository-wide audit permits the MIT license for original ThermoWeave contributions as identified by `LICENSE` and `CITATION.cff`.

That permission is scoped: it does not relicense MATLAB, Simulink, Simscape, Simscape Battery, MathWorks documentation, GitHub or its Actions, or any future external dependency. `docs/assets/og.png` remains subject to the applicable OpenAI service terms; the MIT scope does not override those terms. Third-party components and services retain their own notices and restrictions. The local package may therefore present itself as MIT-licensed for original ThermoWeave material, while public claims remain separately constrained by the release-evidence items recorded below and in `RED_TEAM_REPORT.md`.

## Public-release gate status

The provenance decision approves the local package; it is not evidence of numerical certification. On 2026-08-14, every external GitHub Action reference was resolved and pinned to an immutable commit, with revisions and licenses recorded in `THIRD_PARTY_NOTICES.md`, and the public R2024a core workflow completed successfully. The optional Simscape library policy remains unresolved, so E9 retains its explicit skipped status and no Simscape integration claim is made. Local evidence is 31/31 tests on MATLAB R2026a Update 4, E0–E8 passing with E9 skipped, and a fresh portable-ZIP extraction smoke pass. Statement coverage is about 60% versus an 80% advisory target; these limitations remain visible in any release decision.

## License considerations

`LICENSE` is effective for original ThermoWeave contributions after this completed audit; it is not a blanket license for external products, documentation, services, or workflow actions. Any later imported or generated material must be re-audited and attributed before release, and any conflict between an upstream term and the project license must be resolved in favor of the upstream term.
