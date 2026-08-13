# Publication and deployment checklist

No remote repository, pull request, release, Pages site, or personal-site integration is currently claimed.

After installing and authenticating GitHub CLI, the owner can publish the verified branch:

```powershell
git add --all
git commit -m "feat: build ThermoWeave battery digital twin"
gh repo create thermoweave-battery-digital-twin --public --source . --remote origin
git push -u origin main
gh pr create --fill
```

If the first push is the intended protected default branch, create the repository with `--push` only after reviewing the full staged tree and test evidence. Enable GitHub Pages with **GitHub Actions** as the source; `.github/workflows/pages.yml` publishes `docs/` after a push to `main`.

Before a semantic-version tag:

```matlab
buildtool package
```

Then inspect `release/release-manifest.json`, the archive checksum, provenance/notices, and the staged files. Create `v1.0.0` only after every mandatory gate is satisfied, including the intended release claim policy.

Profile pinning remains manual: open the GitHub profile, choose **Customize your pins**, select the repository, and save.
