# Governance and scope

ThermoWeave's charter makes the primary integrator responsible for interfaces and final acceptance, while provenance and verification reviews can veto public claims or release status. Core MATLAB is the portable implementation; optional Simscape evidence is recorded honestly and an explicit optional skip does not itself invalidate a core release when all mandatory gates pass. This page records those rules and proposes role-based operating practices; it assigns no new person or permission. [PROJECT_CHARTER.md:1–43](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/PROJECT_CHARTER.md#L1-L43)

## Decision boundaries

| Decision | Accountable role | Required evidence |
|---|---|---|
| Equations, units, topology, control or solver semantics | Scientific maintainer + primary integrator | Source-derived specification, independent review and native scenario/convergence tests |
| Public API/result/config compatibility | Interface maintainer + integrator | Consumer/shape/error/fallback review and migration decision |
| Documentation and educational presentation | Documentation maintainer | Pinned sources, accurate synthetic labels, static checks and accessibility review where applicable |
| Optional model structure/libraries | Model owner | Existing library/policy declaration, lawful product availability, inspected model provenance/callbacks |
| Merge and release | Authorized repository owner/integrator | Current branch policy, legitimate authorship/signature, required checks/review and exact identities |
| Public claims/provenance | Independent verification/provenance reviewer | Traceable sources and honest limits; no promotion of skipped or historical evidence |

Roles are proposals for continuity; the repository does not identify a complete staffing roster. Existing `DECISIONS.md` remains the accepted-decision source. A roadmap entry is a proposal until its acceptance evidence and owner decision exist. [DECISIONS.md:1–83](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/DECISIONS.md#L1-L83)

## Allowed and excluded claims

Describe this as a synthetic reduced-order graph electrothermal demonstrator. It does not establish real-cell accuracy, battery safety, certification, lifetime, measured controller performance or completed Simscape integration. The browser's scalar teaching model, historical graph playback and native solver must be named separately. No company/product endorsement is implied by citing MathWorks APIs. [PROJECT_CHARTER.md:1–43](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/PROJECT_CHARTER.md#L1-L43) [PROVENANCE.md:1–60](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/PROVENANCE.md#L1-L60) [THIRD_PARTY_NOTICES.md:1–48](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/THIRD_PARTY_NOTICES.md#L1-L48)

CITATION.cff retains the group author `ThermoWeave contributors`, version 0.2.0 and date 2026-08-14. Those preserved metadata are not a declaration that a new semantic release exists. The dated provider snapshot returned no tags/releases. Do not invent an individual author, DOI, release date or signed commit to complete a checklist. [CITATION.cff:1–18](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/blob/5f29e34788b0f7ee58e2feeafc4df5d48a9a687a/CITATION.cff#L1-L18) [Provider snapshot](../maintainer/VERIFICATION_EVIDENCE_LEDGER.md).

## Review and escalation

Use ordinary pull requests and current repository policy. Keep content, merge and publication outcomes separate. An inaccessible protection endpoint means policy is unresolved, not waived. Never forge commit identities or bypass required checks to meet an autonomous request. Complete the reversible research/documentation work and prepare a concrete reviewable candidate before escalating an actual integration blocker.

For a scientific disagreement, preserve the exact fixture and two competing interpretations, then test the smallest discriminating case on a supported native runtime. For a vulnerability, follow [SECURITY.md](../../SECURITY.md), use a verified private channel and omit secrets from public issues. For new external data/assets, document acquisition rights and limitations before importing; the existing MIT file covers original contributions and does not relicense commercial dependencies.

## Proposed operating cadence

At each substantive change, refresh affected source claims and relevant checks. Before release, do a clean-environment reproduction, provenance review and actual delivery check. At roadmap horizon reviews, compare acceptance evidence and available capacity, then update proposed dates rather than reporting unstaffed tasks as committed. This cadence is documentation only; no scheduled job or notification was created.
