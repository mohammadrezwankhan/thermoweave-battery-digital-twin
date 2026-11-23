import hashlib
import importlib.util
import json
import re
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
    def test_verifier_source_roots_match_packager_contract(self):
        verifier = load_script("verify_licensed_release_package")
        packager = (ROOT / "tools/packageRelease.m").read_text(encoding="utf-8")
        match = re.search(r"include\s*=\s*\[(.*?)\];", packager, re.DOTALL)
        self.assertIsNotNone(match, "package include list was not found")
        roots = re.findall(r'"([^"\n]+)"', match.group(1))
        self.assertEqual(len(roots), len(set(roots)), "duplicate packager root")
        self.assertEqual(set(roots), set(verifier.SOURCE_ROOTS))

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
    """Exercise archive provenance against real Git objects, not mocked names."""

    def setUp(self):
        import subprocess

        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.module = load_script("verify_licensed_release_package")
        self.entries = {"README.md": b"committed source", "src/model.m": b"source model"}
        for path in self.module.EVIDENCE_FILES:
            file = self.root / path
            file.parent.mkdir(parents=True, exist_ok=True)
            file.write_bytes(b"licensed evidence")
            self.entries[path] = b"licensed evidence"
        (self.root / "README.md").write_bytes(self.entries["README.md"])
        (self.root / "src").mkdir()
        (self.root / "src/model.m").write_bytes(self.entries["src/model.m"])
        (self.root / "release").mkdir()
        subprocess.run(["git", "init", "-q"], cwd=self.root, check=True)
        subprocess.run(["git", "add", "README.md", "src", "artifacts", "docs"],
                       cwd=self.root, check=True)
        subprocess.run(["git", "-c", "user.name=Scientific Fixture",
                        "-c", "user.email=fixture@example.invalid",
                        "commit", "-qm", "Fixture source"],
                       cwd=self.root, check=True)
        self.sha = subprocess.check_output(
            ["git", "rev-parse", "HEAD"], cwd=self.root, text=True
        ).strip()

    def make_package(self, revision=None, symlink=False):
        import stat

        package = self.root / "release/thermoweave-source.zip"
        with zipfile.ZipFile(package, "w") as archive:
            for path, content in self.entries.items():
                if path == "README.md" and symlink:
                    info = zipfile.ZipInfo(path)
                    info.create_system = 3
                    info.external_attr = (stat.S_IFLNK | 0o777) << 16
                    archive.writestr(info, b"outside-target")
                else:
                    archive.writestr(path, content)
        manifest = {
            "gitCommit": revision or self.sha,
            "sha256": hashlib.sha256(package.read_bytes()).hexdigest(),
            "bytes": package.stat().st_size,
            "contents": ["README.md", "src", "docs", "artifacts"],
        }
        (self.root / "release/release-manifest.json").write_text(
            json.dumps(manifest), encoding="utf-8"
        )

    def verify(self):
        self.module.verify_package(self.root, self.root, self.sha)

    def test_generated_graphics_are_required_licensed_evidence(self):
        graphics = {
            "artifacts/animation/thermal-field.gif",
            "artifacts/figures/thermal-overview.png",
            "artifacts/figures/3d-layer-response.png",
            "artifacts/figures/3d-module-temperature.png",
        }
        self.assertTrue(graphics.issubset(self.module.EVIDENCE_FILES))
        workflow = (ROOT / ".github/workflows/simscape-integration.yml").read_text(encoding="utf-8")
        for path in graphics:
            self.assertIn(path, workflow)

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

    def test_rejects_changed_committed_source_bytes_with_valid_zip_digest(self):
        # The same tracked path and a self-consistent ZIP manifest must NOT
        # authorize uncommitted executable or documentation source changes.
        self.entries["README.md"] = b"uncommitted replacement"
        self.make_package()
        with self.assertRaisesRegex(ValueError, "source bytes"):
            self.verify()

    def test_rejects_manifest_omitting_required_licensed_science_files(self):
        # A malicious archive can narrow contents to only README.md,
        # yielding a valid SHA, valid source bytes and matching inventory.
        # Such a package lacks the mandatory exact-source science receipts.
        self.entries = {"README.md": b"committed source"}
        self.make_package()
        manifest_path = self.root / "release/release-manifest.json"
        manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
        manifest["contents"] = ["README.md"]
        manifest_path.write_text(json.dumps(manifest), encoding="utf-8")
        with self.assertRaisesRegex(ValueError, "required evidence"):
            self.verify()

    def test_rejects_manifest_omitting_committed_source_root(self):
        del self.entries["src/model.m"]
        self.make_package()
        manifest_path = self.root / "release/release-manifest.json"
        manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
        manifest["contents"].remove("src")
        manifest_path.write_text(json.dumps(manifest), encoding="utf-8")
        with self.assertRaisesRegex(ValueError, "source inventory"):
            self.verify()

    def test_rejects_symlink_disguised_as_committed_regular_file(self):
        # A link is not the committed Git blob even if its filename matches.
        self.make_package(symlink=True)
        with self.assertRaisesRegex(ValueError, "unsafe"):
            self.verify()


if __name__ == "__main__":
    unittest.main()
