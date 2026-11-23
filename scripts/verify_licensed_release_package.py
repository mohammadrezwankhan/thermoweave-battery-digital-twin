"""Verify the ZIP matches committed paths and the licensed evidence being published."""
import hashlib
import json
import os
from pathlib import Path
import re
import stat
import subprocess
import sys
import zipfile


SOURCE_ROOTS = (
    "README.md", "LICENSE", "CITATION.cff", "CHANGELOG.md",
    "PROVENANCE.md", "THIRD_PARTY_NOTICES.md", "ENVIRONMENT.md",
    "PROJECT_CHARTER.md", "ARCHITECTURE.md", "DECISIONS.md",
    "RISK_REGISTER.md", "RED_TEAM_REPORT.md", "TASKS.md", "ROADMAP.md",
    "CONTRIBUTING.md", "CODE_OF_CONDUCT.md", "SECURITY.md",
    "ThermoWeave.prj", "startup.m", "runDemo.m", "buildfile.m",
    "src", "config", "examples", "simscape", "tests", "tools",
    "docs", "artifacts", "resources", "manuscript", ".github",
)


EVIDENCE_FILES = (
    "artifacts/animation/thermal-field.gif",
    "artifacts/figures/thermal-overview.png",
    "artifacts/figures/3d-layer-response.png",
    "artifacts/figures/3d-module-temperature.png",
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
    # Inspect Git object metadata, not only tracked filenames. A locally
    # edited file can retain the same filename and be packaged with a freshly
    # calculated, self-consistent ZIP digest while differing from the commit.
    listing = subprocess.check_output(
        ["git", "ls-tree", "-r", "-z", expected_sha, "--", *contents], cwd=root,
    )
    tracked = {}
    for record in listing.split(b"\0"):
        if not record:
            continue
        metadata, separator, raw_name = record.partition(b"\t")
        fields = metadata.split()
        if not separator or len(fields) != 3:
            raise ValueError("Malformed Git source inventory")
        mode, kind, blob_id = fields
        if (mode not in (b"100644", b"100755") or kind != b"blob"
                or not re.fullmatch(rb"[0-9a-f]{40}", blob_id)):
            # Symlinks, gitlinks/submodules and other special entries are not
            # safe regular source files in a release archive.
            raise ValueError("Unsafe Git source entry")
        name = raw_name.decode("utf-8")
        if name in tracked:
            raise ValueError("Duplicate Git source entry")
        tracked[name] = blob_id.decode("ascii")
    # A self-consistent manifest must not define away the mandatory receipts
    # by narrowing its top-level contents to a harmless subset of the tree.
    missing_evidence = set(EVIDENCE_FILES) - tracked.keys()
    if missing_evidence:
        raise ValueError("Release package missing required evidence: "
                         + ", ".join(sorted(missing_evidence)))
    root_listing = subprocess.check_output(
        ["git", "ls-tree", "-z", expected_sha, "--", *SOURCE_ROOTS], cwd=root,
    )
    expected_roots = {record.partition(b"\t")[2].decode("utf-8")
                      for record in root_listing.split(b"\0") if record}
    if len(contents) != len(set(contents)) or set(contents) != expected_roots:
        raise ValueError("Release package source inventory differs from committed roots")
    with zipfile.ZipFile(package) as archive:
        entries = archive.infolist()
        if len(entries) != len({entry.filename for entry in entries}):
            raise ValueError("Duplicate release archive entries")
        names = []
        for entry in entries:
            name = entry.filename
            normalized = name[:-1] if entry.is_dir() else name
            if (not normalized or name.startswith("/")
                    or "\\" in name
                    or any(part in ("", ".", "..") for part in normalized.split("/"))
                    or entry.flag_bits & 1):
                raise ValueError("unsafe release archive path or encrypted member")
            unix_type = (stat.S_IFMT(entry.external_attr >> 16)
                         if entry.create_system == 3 else 0)
            if entry.is_dir():
                if unix_type not in (0, stat.S_IFDIR):
                    raise ValueError("unsafe release archive directory type")
            else:
                if unix_type not in (0, stat.S_IFREG):
                    raise ValueError("unsafe release archive member type")
                names.append(name)
        if (set(names) != set(tracked) or len(names) != len(tracked)
                or any(name.startswith((".satk/", "simscape/models/"))
                       or name.lower().endswith((".slx", ".mdl", ".slxc"))
                       for name in names)):
            raise ValueError("Release archive inventory contains missing or local-only files")
        if archive.testzip() is not None:
            raise ValueError("Corrupt release archive member")
        for name, blob_id in tracked.items():
            actual = archive.read(name)
            if name in EVIDENCE_FILES:
                # These and ONLY these regenerated outputs may differ from
                # their committed blobs. Their bytes must equal the fresh,
                # authenticated licensed workflow receipt.
                if actual != (evidence_root / name).read_bytes():
                    raise ValueError("Package evidence differs from licensed receipt: " + name)
            else:
                committed = subprocess.check_output(
                    ["git", "cat-file", "blob", blob_id], cwd=root,
                )
                if actual != committed:
                    raise ValueError("Release archive source bytes differ from exact Git commit: " + name)



if __name__ == "__main__":
    try:
        root = Path(".")
        evidence = Path(os.environ.get("SCIENTIFIC_EVIDENCE_ROOT") or root)
        verify_package(root, evidence, os.environ.get("EXPECTED_SOURCE_SHA", ""))
    except (OSError, ValueError, KeyError, subprocess.CalledProcessError, zipfile.BadZipFile) as exc:
        sys.exit(f"RELEASE HOLD: {exc}")
