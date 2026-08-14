# Literature review and positioning

**Scope.** This review supports a proposed, independently authored electrothermal model: a configurable Cartesian three-dimensional graph whose nodes carry thermal capacitance, whose axis-aligned edges carry potentially different conductances, and whose six-face boundary masks select ambient/cooling links. The review is deliberately about transferable concepts (energy balance, thermal networks, anisotropy, reduced-order spatial models, and reproducibility), not a template for copying any software implementation, prose, figures, topology count, parameter set, or numerical example.

## What prior work establishes

1. **Heat-generation bookkeeping.** Bernardi, Pawlikowski, and Newman derive a general battery energy balance that separates irreversible and reversible contributions. This is the thermodynamic basis for treating an electrochemical or equivalent-circuit heat source as an input to a thermal state model; it does not prescribe a particular graph discretization [Bernardi1985].

2. **Thermal limits and management context.** Bandhauer, Garimella, and Fuller review heat-generation mechanisms, thermal transport, and safety implications in lithium-ion cells [Bandhauer2011]. Rao and Wang survey battery thermal models and cooling strategies [Rao2011]. These reviews motivate temperature uniformity and thermal-management coupling, but they are not specifications for the model proposed here.

3. **Lumped cell networks.** Forgez et al. identify heat capacity and heat-transfer coefficients for a cylindrical LiFePO4/graphite cell and use a lumped thermal model [Forgez2010]. Lin et al. couple an equivalent-circuit electrical model to a two-state core/surface thermal model and describe a parameter-identification workflow [Lin2014]. These studies support the usefulness of low-order thermal states and experimentally identifiable parameters; neither defines a Cartesian 3-D module graph.

4. **Thermal-equivalent circuits at module scale.** Gan et al. formulate a thermal equivalent-circuit model for a heat-pipe-cooled cylindrical-cell module and validate it over multiple operating conditions [Gan2020]. This is evidence that resistance/capacitance networks can represent pack-level heat paths, while the proposed work differs in using an explicit, configurable 3-D lattice and deterministic graph construction.

5. **Anisotropy is physically consequential.** For cylindrical cells, Drake et al. measure radial and axial thermophysical properties and report strong directional differences [Drake2014]. Lin et al. characterize anisotropic conductivity in large-format pouch cells and discuss effective conductivity tensors [Lin2022]. Al-Zareer, Da Silva, and Amon infer anisotropic properties and spatially distributed heat generation in pouch cells using inverse heat-transfer experiments and simulation [AlZareer2021]. These works justify separate conductances by coordinate direction; they do not establish the exact edge-weight or boundary-mask API proposed here.

6. **Spatially resolved reduced-order models.** Richardson, Zhao, and Howey derive a low-order 2-D spectral-Galerkin model for cylindrical cells that retains spatial temperature fields, anisotropic conduction, and nonuniform convection boundaries [Richardson2016]. Their result demonstrates the value of spatial states at control-oriented cost. A Cartesian graph Laplacian is an independent discretization choice and should be compared against, rather than represented as a reimplementation of, their spectral basis.

7. **Inter-cell heat exchange in engineering tools.** MathWorks documents that Simscape Battery can add thermal resistors between neighboring cell thermal nodes, parameterize scalar or per-connection resistance, and optionally add radiative paths [MathWorksInterCell; MathWorksModule]. The documentation also states that resistance values can be estimated from geometry/material properties or detailed 3-D simulations [MathWorksInterCell]. These pages are product documentation and high-level prior art only. The proposed manuscript must not copy their code, wording, figures, example counts, names, or parameter values.

8. **Reproducible computational practice.** Wilkinson et al. define FAIR principles (findability, accessibility, interoperability, and reusability) for data, algorithms, and workflows [Wilkinson2016]. Sandve et al. provide practical rules for reproducible computational research, including retaining inputs, code, and execution details [Sandve2013]; Taschuk and Wilson discuss robust research software and version control [Taschuk2017]. These principles support publishing canonical inputs, deterministic node ordering, machine-readable outputs, environment/version metadata, and independent reruns. They do not validate any battery result by themselves.

## Synthesis and gap

The literature spans (i) physically grounded heat-source terms, (ii) low-order cell thermal circuits, (iii) anisotropic property measurement, (iv) reduced-order spatial temperature fields, and (v) module thermal-management networks. A practical gap remains between those ingredients: a small, inspectable model that exposes a regular 3-D graph, allows independent conductance values for each axis, makes all six boundary faces explicit, and can be regenerated exactly from a compact configuration. The proposed contribution is therefore a software-and-method specification hypothesis, not a claim that the underlying heat equation or thermal-resistance analogy is new.

The manuscript should test, and not assume, the following hypotheses:

- canonical graph construction is invariant to repeated runs and platform-independent under a specified numerical tolerance;
- axis-specific conductances reproduce expected directional diffusion in manufactured tests;
- boundary masks conserve energy when links are disabled and produce the declared ambient/cooling flux when enabled;
- coupling to an electrical heat source preserves units and energy balance; and
- visualizations are derived from the same serialized state used for numerical checks.

No quantitative battery-performance claim is made here. Any future validation against measured data, finite-element solutions, or a commercial tool must identify the dataset, parameter provenance, uncertainty, and comparison protocol.

## Limitations

Several cited studies concern one cell, a particular chemistry/format, or a specialized cooling system. Their parameters are not transferable without characterization. Reviews summarize broad evidence but are not validation datasets. MathWorks pages describe software behavior that can change by release; the access date below records the version-independent URL, while exact release behavior should be checked when reproducing a result. The proposed graph is not a substitute for electrochemical, CFD, or abuse/thermal-runaway models when those phenomena are in scope.

## References used in text

Full records, DOI links, and access dates are in [`references.bib`](references.bib).
