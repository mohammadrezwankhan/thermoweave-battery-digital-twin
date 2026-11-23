# Publication and deployment status

The source repository and static documentation site were published on 2026-08-14:

- repository: <https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin>
- project site: <https://mohammadrezwankhan.github.io/thermoweave-battery-digital-twin/>

All external GitHub Actions are pinned to immutable commits recorded in `THIRD_PARTY_NOTICES.md`. Local MATLAB R2026a verification passes 37/37 tests after the 3-D extension. The first private-repository R2024a attempt could not obtain a MathWorks license; after the original publication, the public GitHub Core CI workflow provisioned R2024a and completed the then-current core build. The new 3-D extension must complete the same CI path after publication.

GitHub Pages uses **GitHub Actions** as its source; `.github/workflows/pages.yml` publishes `docs/` after a push to `main`. The [19 November 2026 Pages deployment run](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/actions/runs/44626427373) successfully published source `6b48646da2f6f8b60a13b14e19c4c65e45b17383` to `https://mohammadrezwankhan.github.io/thermoweave-battery-digital-twin/` according to the deployment job log. This is verified provider deployment evidence, not a real-time browser availability or accessibility audit. The separately referenced `chatgpt.site` host, if present in metadata, is not proof of a GitHub Pages deployment.

[Release v0.2.0](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/releases/tag/v0.2.0) was published on 22 November 2026 from commit [bfd1ca6](https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin/commit/bfd1ca6aab7e2aa16339b5e2c3baf39267b3253a). It includes the source ZIP, its SHA-256 checksum and the release manifest. Its R2024a receipt records E9 as skipped because a required product was missing.

To build a local source package for inspection, run:

```matlab
buildtool package
```

Then inspect `release/release-manifest.json`, the archive checksum, provenance/notices, test evidence, and `git status`. Use the exact-source licensed process below for a future release that requires a passing Simscape comparison.

Profile pinning remains manual: open the GitHub profile, choose **Customize your pins**, select the repository, and save.

## Licensed evidence for Pages and tag releases

The Pages job requires the independent scientific matrix and findings recorded in the checked-out source, plus evidence generated for that exact commit. For publication after scientific approval, the authorized maintainer can dispatch **Optional Simscape integration** on `main` with `pages_evidence` enabled. Use a Unix self-hosted runner with the `thermoweave-simscape` label, a Bourne-compatible shell, Python 3, and licensed MATLAB R2024a, Simulink, Simscape, Simscape Battery and Optimization Toolbox. The [pinned MATLAB setup action](https://github.com/matlab-actions/setup-matlab/blob/f9e43010f1ae678f7cfa0542fe2a4f60f7d1ad8d/README.md) uses the Unix self-hosted setup path. Install the action's required system dependencies before dispatch. Configure `THERMOWEAVE_LICENSED_INPUT_ROOT` on that runner with the locally approved `.satk/reuse-libraries.json`, `simscape/models/thermoweave-model-manifest.json` and `simscape/models/ThermoWeaveE9Candidate.slx`. The build checks the pinned model bytes. The evidence archive contains reports and test receipts. The model and library declaration stay on the runner.

After reviewing the successful run and its evidence, use its numeric run ID as `licensed_evidence_run_id` in the **Documentation Pages** manual workflow on the same `main` revision. Pages verifies the run's repository, workflow and SHA, requires an intact archive, applies the existing release veto and stages the validated demo data only when that veto passes. The archive is retained for 14 days.

## Exact-source tag releases

First integrate the tracked-path source packager, then run the licensed workflow on the reviewed main commit with `pages_evidence` enabled. The tag workflow selects the newest usable bundle for the exact tag commit. It verifies the package against the uploaded science evidence and the independent review records in the checkout. Create the tag while the licensed evidence is still retained.
