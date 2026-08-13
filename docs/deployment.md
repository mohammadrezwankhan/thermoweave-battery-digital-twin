# Publication and deployment status

The source repository and static documentation site were published on 2026-08-14:

- repository: <https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin>
- project site: <https://mohammadrezwankhan.github.io/thermoweave-battery-digital-twin/>

All external GitHub Actions are pinned to immutable commits recorded in `THIRD_PARTY_NOTICES.md`. Local MATLAB R2026a verification passed 31/31 tests. The first hosted R2024a run provisioned MATLAB but could not obtain a MathWorks license, so no repository code executed and no R2024a compatibility claim is made.

GitHub Pages uses **GitHub Actions** as its source; `.github/workflows/pages.yml` publishes `docs/` after a push to `main`.

No semantic-version release is currently claimed. Before creating one, run:

```matlab
buildtool package
```

Then inspect `release/release-manifest.json`, the archive checksum, provenance/notices, test evidence, and `git status`. Resolve the hosted R2024a license gate or retain the limitation explicitly in release notes. The optional Simscape integration remains `SKIPPED_LIBRARY_POLICY_UNRESOLVED` and must not be marketed as a completed comparison.

Profile pinning remains manual: open the GitHub profile, choose **Customize your pins**, select the repository, and save.
