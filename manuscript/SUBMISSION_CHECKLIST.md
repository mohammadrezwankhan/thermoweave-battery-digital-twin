# Manuscript submission checklist

The repository produces a journal-style draft autonomously, but journal submission requires accountable human review. Do not mark this checklist complete by assumption.

## Required before submission

- [ ] Confirm author name, affiliation, ORCID, email, and corresponding-author role.
- [ ] Select a target journal and adapt length, template, reference style, declarations, data policy, and AI-use disclosure.
- [ ] Re-open every DOI/publisher record and verify authors, title, year, volume, pages/article number, and license.
- [ ] Review every equation, unit, sign convention, parameter, generated result, figure, table, and interpretation.
- [ ] Add an independent analytical, finite-element, or measured comparison with parameter provenance and uncertainty before making predictive-accuracy claims.
- [ ] Run the new 3-D suite on the minimum supported MATLAB release through public CI.
- [ ] Resolve the optional Simscape library policy before making a Simscape comparison claim; otherwise preserve the explicit skip.
- [ ] Improve or justify statement coverage relative to the repository's 80% advisory goal.
- [ ] Obtain co-author and institutional approvals, if applicable.
- [ ] Confirm funding, competing interests, author contributions, permissions, and data/code availability statements.
- [ ] Create a versioned archival deposit and DOI if required by the journal.
- [ ] Perform plagiarism/similarity and research-integrity review using the journal or institution's approved process.

## Current evidence boundary

- 37/37 local MATLAB R2026a tests pass.
- The E10 3-D study is synthetic and deterministic.
- No measured cell/module validation is included.
- No detailed CFD/finite-element benchmark is included.
- No thermal-runaway, ageing, certification, or safety-decision claim is supported.
- AI assisted the code, tests, literature organization, figures, manuscript, and site; it is not an author or reviewer.
