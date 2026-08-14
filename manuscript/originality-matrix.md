# Originality and provenance matrix

This matrix separates established concepts from the independently authored implementation and from claims that require peer review. It is a provenance aid, not a novelty determination.

| Area | Prior concept supported by literature | Explicitly excluded copied expression/assets | Independently authored implementation element | Novelty hypothesis / review requirement |
|---|---|---|---|---|
| Energy balance | Bernardi et al.'s battery energy balance; irreversible/reversible heat terms | No copied equations beyond standard notation; no source-specific examples | A documented heat-source interface with units and sign convention | Interface composition may be useful, but is not claimed as novel without comparison to prior electrothermal APIs. |
| Lumped thermal states | Core/surface RC models (Forgez; Lin) | No copied circuit diagrams, state names, parameter values, or validation traces | Node heat capacities and edge conductances represented in a generic graph | A graph implementation is an engineering design choice; reviewers must compare accuracy/cost with RC and finite-element baselines. |
| Inter-cell exchange | Neighbor thermal resistors and optional radiation in Simscape Battery docs | No MathWorks code, prose, figures, object/property names, topology counts, parameter values, or page structure | Configurable adjacency generated from Cartesian coordinates, with serialized edge lists | Whether explicit 3-D adjacency plus masks improves inspectability is a hypothesis requiring ablation and comparison. |
| 3-D spatial resolution | 2-D low-order spatial model (Richardson et al.); 3-D thermal characterization (Al-Zareer et al.) | No copied spectral basis, meshes, figures, or data | Cartesian 3-D graph Laplacian with deterministic canonical node ordering | Generality/accuracy/speed trade-off must be demonstrated on manufactured and measured cases; “first 3-D graph” is not asserted. |
| Directional transport | Measured anisotropic radial/axial or in-plane/through-plane conductivities (Drake; Lin; Al-Zareer) | No copied conductivity values or cell-specific geometry | Independent (g_x,g_y,g_z) edge conductance parameters and tests that isolate each axis | Direction-specific parameterization is established prior art; any claim of a new parameter-estimation method requires peer review. |
| Boundary conditions | Nonuniform convection boundaries in Richardson et al.; thermal paths in MathWorks docs | No copied boundary diagrams, mask labels, or API names | Six-face boundary masks and explicit ambient/cooling links | Mask semantics and conservation checks may be a reproducibility contribution, not automatically a scientific novelty claim. |
| Thermal-management coupling | Reviews and module TECM studies (Rao; Bandhauer; Gan) | No copied cooling-system design, coolant data, or performance numbers | Optional boundary sink/source hooks independent of a specific coolant technology | Control or cooling conclusions require a declared physical plant and experiments; this manuscript makes none. |
| Determinism | FAIR and reproducible-computing guidance (Wilkinson; Sandve; Taschuk) | No copied checklist text or third-party workflow | Canonical ordering, fixed tolerances, machine-readable snapshots, environment metadata, repeat-run checks | Determinism is a quality criterion. Any claim of platform independence needs cross-platform evidence. |
| Visualization | Spatial-temperature visualization is common in thermal modeling | No copied figures, color maps, layouts, or screenshots | 3-D visualization rendered from the same serialized state used by tests | Visual encoding is original artwork/software only if independently authored; scientific interpretation still needs validation. |

## Authorship and AI-assistance disclosure

- The model equations, graph-construction choices, software, tests, figures, and manuscript interpretation must be reviewed and accepted by the named human authors.
- If generative AI was used for literature discovery, drafting, or code assistance, disclose the tool/provider, approximate dates, scope of assistance, and the human verification process in the manuscript and any required submission form. AI tools cannot be listed as authors and cannot take responsibility for the work.
- Every bibliographic record must be checked against its DOI landing page or publisher record before submission. The FAIR article uses a conventional “and others” author-list truncation in BibTeX; expand it to the journal’s preferred full list if required by the target style.
- Do not present the current repository's deterministic examples as experimental battery validation. Label them as manufactured tests or software checks unless independent measurements and uncertainty analysis are supplied.

## Required evidence before making novelty claims

1. Compare graph predictions with at least one independent analytical, finite-element, or measured reference while reporting parameter provenance and tolerances.
2. Run ablations for isotropic versus axis-specific conductance, boundary masks, and node-resolution changes.
3. Report runtime, state count, solver settings, and deterministic output hashes for all canonical cases.
4. Have domain reviewers assess whether the contribution is methodological novelty, software engineering, or a reproducibility artifact; use cautious language until that assessment is complete.
