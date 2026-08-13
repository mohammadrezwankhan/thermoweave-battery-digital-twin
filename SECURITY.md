# Security policy

ThermoWeave is an early-stage research demonstrator. It is not a safety-certified controller and must not be connected to a live battery or used to make safety-critical decisions.

## Reporting a vulnerability

Please do not publish exploitable details, credentials, license files, private paths, or personal data in a public issue or pull request. If private GitHub reporting is enabled for the repository, use a GitHub Security Advisory. Otherwise, contact a project maintainer through the repository's authenticated administrative channel and request a private security discussion; do not send secrets through an unverified channel.

Include the affected revision, a concise description, impact, reproduction steps that use synthetic data only, and any suggested mitigation. Allow maintainers reasonable time to investigate and coordinate a fix before public disclosure.

## Scope and handling

Reports may include code execution, unsafe file handling, path or secret disclosure, dependency/workflow compromise, incorrect release artifacts, and reproducibility or provenance tampering. Scientific model limitations and ordinary numerical disagreements belong in a normal issue unless they create a security consequence.

Maintainers will acknowledge a report when practical, validate it, assign a severity, and document remediation in the changelog or release notes. Do not include credentials in a report; revoke and rotate exposed credentials immediately through the relevant provider.

## Supported versions

There is no long-term-supported release line yet. The current default branch and the latest tagged release, when one exists, receive security review. Older revisions may require upgrading before a fix is provided.
