# Reproducibility guide

ThermoWeave is a synthetic electrothermal demonstrator. Reproduction means regenerating the same declared scenario, result contract, metrics, and manifests; it does not establish real-cell accuracy, safety, lifetime, or certification.

## Version targets

- **Minimum portable target:** MATLAB R2024a or newer for the reduced-order core.
- **Local verification recorded at initialization:** MATLAB 26.1.0.3312084, R2026a Update 4, on Windows 11 NT 10.0.26200 AMD64.
- **CI target:** GitHub-hosted Ubuntu with `matlab-actions/setup-matlab@v3` at release `R2024a`, then `matlab-actions/run-build@v3`.
- **Optional integration:** a manually dispatched job on a runner labelled `[self-hosted, thermoweave-simscape]`, with a licensed installation and the required Simscape products.

The R2026a result is useful local evidence but is not evidence that the same path has run on R2024a. Record the MATLAB release and product manifest with every generated result.

## Fresh checkout

From a fresh checkout, use the repository root as the working directory:

```matlab
startup
buildtool test
```

Run the deterministic demo task named by the current `buildfile.m` after the core tests. If a task is unavailable, stop and update the build/documentation contract rather than silently substituting a different command. Keep generated output in the ignored `results/`, `coverage-report/`, `release/`, and cache directories.

## Determinism contract

For each run, preserve:

1. the exact scenario/configuration input and resolved configuration;
2. the random seed and variability/fault declarations;
3. solver name, tolerances, time grid, and MATLAB/product versions;
4. topology, units, boundary/controller modes, and initial state;
5. the canonical result schema version and source/configuration hashes; and
6. event records for fallbacks, skipped optional products, disturbances, and faults.

Compare summary values and hashes from manifests before comparing down-sampled JSON or visual exports. JSON exports may be down-sampled, but they must retain summary values and the source manifest hash.

## Optional Simscape behavior

The reduced-order core is the portable reference. Simscape Battery is an external dependency and is not redistributed. If product detection or licensing fails, the integration must emit `SKIPPED_MISSING_PRODUCT` (or the policy-equivalent explicit skip) with the detected product status. Never label a skipped run as a passing Simscape comparison.

## CI and release evidence

Core CI is expected to run the same build task on MATLAB R2024a. Full integration is manual and self-hosted. A semver-tagged release may be packaged only after the build task succeeds; the release workflow records the tag and checksum for the resulting archive. Before publication, review provenance, third-party notices, generated-file exclusions, and `git diff --check` from a clean checkout.

For a defensible reproduction report, include the command, revision, environment manifest, input/configuration hashes, seed, output manifest, test summary, and any explicit skips. Do not include credentials, license files, or machine-specific private paths.
