import hashlib
import importlib.util
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch
import zipfile

ROOT = Path(__file__).resolve().parents[2]


def load_script(name):
    spec = importlib.util.spec_from_file_location(name, ROOT / "scripts" / (name + ".py"))
    script = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(script)
    return script


class TagReleaseTests(unittest.TestCase):
    def test_tag_keeps_release_veto_before_publishing(self):
        workflow = (ROOT / ".github/workflows/release.yml").read_text(encoding="utf-8")
        steps = [
            "select_licensed_pages_artifact.py --latest",
            "digest-mismatch: error",
            "verify_release_readiness.py",
            "verify_licensed_release_package.py",
            "gh release create",
        ]
        self.assertEqual(sorted(workflow.index(step) for step in steps),
                         [workflow.index(step) for step in steps])
        self.assertIn("tags:", workflow)
        self.assertIn("--verify-tag", workflow)

    def test_latest_ignores_an_expired_run_and_selects_an_exact_receipt(self):
        selector = load_script("select_licensed_pages_artifact")
        repo = "owner/repo"
        sha = "a" * 40
        run = {
            "workflow_id": 7, "head_sha": sha, "head_branch": "main",
            "event": "workflow_dispatch", "status": "completed", "conclusion": "success",
            "repository": {"full_name": repo}, "head_repository": {"full_name": repo},
        }
        receipt = {"name": selector.ARTIFACT_NAME, "id": 42,
                   "expired": False, "digest": "sha256:" + "b" * 64}
        with patch.object(selector, "api", side_effect=[
            {"workflow_runs": [{**run, "id": 3}, {**run, "id": 2}]},
            {"total_count": 1, "artifacts": [{**receipt, "expired": True}]},
            {"total_count": 1, "artifacts": [receipt]},
        ]):
            self.assertEqual(selector.latest_artifact("repos/" + repo + "/actions", 7, repo, sha),
                             (2, 42))


class PackageEvidenceTests(unittest.TestCase):
    SHA = "a" * 40

    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.module = load_script("verify_licensed_release_package")
        self.entries = {"README.md": b"source"}
        for path in self.module.EVIDENCE_FILES:
            file = self.root / path
            file.parent.mkdir(parents=True, exist_ok=True)
            file.write_bytes(b"licensed evidence")
            self.entries[path] = b"licensed evidence"
        (self.root / "release").mkdir()
        self.tracked = sorted(self.entries)

    def make_package(self, revision=SHA):
        package = self.root / "release/thermoweave-source.zip"
        with zipfile.ZipFile(package, "w") as archive:
            for path, content in self.entries.items():
                archive.writestr(path, content)
        manifest = {"gitCommit": revision, "sha256": hashlib.sha256(package.read_bytes()).hexdigest(),
                    "bytes": package.stat().st_size, "contents": ["README.md", "docs", "artifacts"]}
        (self.root / "release/release-manifest.json").write_text(json.dumps(manifest), encoding="utf-8")

    def verify(self):
        listing = ("\0".join(self.tracked) + "\0").encode()
        with patch.object(self.module.subprocess, "check_output", return_value=listing):
            self.module.verify_package(self.root, self.root, self.SHA)

    def test_accepts_exact_archive_and_evidence(self):
        self.make_package()
        self.verify()

    def test_rejects_staged_local_model_in_archive(self):
        self.entries["simscape/models/local.slx"] = b"placeholder"
        self.make_package()
        with self.assertRaisesRegex(ValueError, "archive inventory"):
            self.verify()

    def test_rejects_mismatched_science_and_revision(self):
        self.entries[self.module.EVIDENCE_FILES[0]] = b"different evidence"
        self.make_package()
        with self.assertRaisesRegex(ValueError, "differs"):
            self.verify()
        self.make_package(revision="b" * 40)
        with self.assertRaisesRegex(ValueError, "source commit"):
            self.verify()


if __name__ == "__main__":
    unittest.main()
