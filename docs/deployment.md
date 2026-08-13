# Publication and deployment checklist

No remote repository, pull request, release, Pages site, or personal-site integration is currently claimed.

The local repository is already committed on `main`. Before any public release, replace every major-version Action reference with an audited immutable commit SHA and rerun the local package gate. Then install/authenticate GitHub CLI without pasting credentials into chat.

One conservative route is to create a private remote first so R2024a CI can run before changing visibility:

```powershell
gh auth login
gh repo create thermoweave-battery-digital-twin --private --source . --remote origin
git push -u origin main
gh run list --workflow core-ci.yml
```

Inspect the R2024a workflow to completion with `gh run watch <run-id> --exit-status`. Resolve the Simscape policy separately or preserve the explicit skip/no-comparison posture. When the provenance and engineering gates are accepted, make the repository public using the GitHub repository settings (visibility changes are deliberately not automated here). Enable GitHub Pages with **GitHub Actions** as the source; `.github/workflows/pages.yml` publishes `docs/` after a push to `main`.

Before a semantic-version tag:

```matlab
buildtool package
```

Then inspect `release/release-manifest.json`, the archive checksum, provenance/notices, and `git status`. Create and push `v1.0.0` only after every mandatory gate is satisfied:

```powershell
git tag -a v1.0.0 -m "ThermoWeave v1.0.0"
git push origin v1.0.0
```

Profile pinning remains manual: open the GitHub profile, choose **Customize your pins**, select the repository, and save.
