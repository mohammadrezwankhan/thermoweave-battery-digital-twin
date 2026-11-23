"""Verify the ZIP matches committed paths and the licensed evidence being published."""
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
import sys
import zipfile


EVIDENCE_FILES = (
    "artifacts/reports/verification.json",
    "artifacts/reports/artifact-manifest.json",
    "artifacts/reports/experiment-summary.json",
    "artifacts/reports/3d-study-summary.json",
    "artifacts/data/3d-study-results.csv",
    "artifacts/web-data/thermoweave-demo.json",
    "docs/assets/thermoweave-demo.json",
)


def verify_package(root, evidence_root, expected_sha):
    if not re.fullmatch(r"[0-9a-f]{40}", expected_sha):
        raise ValueError("Expected an exact source commit")
    release = evidence_root / "release"
    manifest = json.loads((release / "release-manifest.json").read_text(encoding="utf-8"))
    if manifest.get("gitCommit") != expected_sha:
        raise ValueError("Release package source commit differs from checkout")
    package = release / "thermoweave-source.zip"
    if (manifest.get("bytes") != package.stat().st_size
            or manifest.get("sha256") != hashlib.sha256(package.read_bytes()).hexdigest()):
        raise ValueError("Release package size or SHA-256 differs from manifest")
    contents = manifest.get("contents")
    if (not isinstance(contents, list) or not contents
            or any(not isinstance(path, str) or not re.fullmatch(r"[\w.-]+", path)
                   or path in (".", "..") for path in contents)):
        raise ValueError("Invalid package source inventory")
    listing = subprocess.check_output(
        ["git", "ls-tree", "-r", "-z", "--name-only", expected_sha, "--", *contents],
        cwd=root,
    )
    tracked = set(listing.decode("utf-8").split("\0")) - {""}
    with zipfile.ZipFile(package) as archive:
        names = [entry.filename for entry in archive.infolist() if not entry.is_dir()]
        if (set(names) != tracked or len(names) != len(tracked)
                or any(name.startswith((".satk/", "simscape/models/"))
                       or name.lower().endswith((".slx", ".mdl", ".slxc")) for name in names)):
            raise ValueError("Release archive inventory contains missing or local-only files")
        if archive.testzip() is not None:
            raise ValueError("Corrupt release archive member")
        for path in EVIDENCE_FILES:
            if archive.read(path) != (evidence_root / path).read_bytes():
                raise ValueError("Package evidence differs from licensed receipt: " + path)


if __name__ == "__main__":
    try:
        root = Path(".")
        evidence = Path(os.environ.get("SCIENTIFIC_EVIDENCE_ROOT") or root)
        verify_package(root, evidence, os.environ.get("EXPECTED_SOURCE_SHA", ""))
    except (OSError, ValueError, KeyError, subprocess.CalledProcessError, zipfile.BadZipFile) as exc:
        sys.exit(f"RELEASE HOLD: {exc}")
