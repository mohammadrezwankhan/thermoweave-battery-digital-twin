# Publication and deployment status

The source repository and static documentation site were published on 2026-08-14:

- repository: <https://github.com/mohammadrezwankhan/thermoweave-battery-digital-twin>
- project site: <https://mohammadrezwankhan.github.io/thermoweave-battery-digital-twin/>

All external GitHub Actions are pinned to immutable commits recorded in `THIRD_PARTY_NOTICES.md`. Local MATLAB R2026a verification passed 31/31 tests. The first private-repository R2024a attempt could not obtain a MathWorks license; after publication, the public GitHub Core CI workflow provisioned R2024a and completed the core build and tests successfully.

GitHub Pages uses **GitHub Actions** as its source; `.github/workflows/pages.yml` publishes `docs/` after a push to `main`.

No semantic-version release is currently claimed. Before creating one, run:

```matlab
buildtool package
```

Then inspect `release/release-manifest.json`, the archive checksum, provenance/notices, test evidence, and `git status`. The optional Simscape integration remains `SKIPPED_LIBRARY_POLICY_UNRESOLVED` and must not be marketed as a completed comparison.

Profile pinning remains manual: open the GitHub profile, choose **Customize your pins**, select the repository, and save.
