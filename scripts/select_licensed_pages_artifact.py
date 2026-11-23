"""Select the exact-source receipt from a trusted licensed integration run."""
import json
import os
import re
import subprocess
import sys


ARTIFACT_NAME = "thermoweave-licensed-pages-evidence"


def select_artifact(run, artifacts, workflow_id, repository, expected_sha):
    required = {"workflow_id": workflow_id, "head_sha": expected_sha,
                "head_branch": "main", "event": "workflow_dispatch",
                "status": "completed", "conclusion": "success"}
    if (any(run.get(key) != value for key, value in required.items())
            or any((run.get(key) or {}).get("full_name") != repository
                   for key in ("repository", "head_repository"))):
        raise ValueError("Expected a successful exact-main licensed Simscape workflow run")
    matches = [item for item in artifacts if item.get("name") == ARTIFACT_NAME]
    if len(matches) != 1:
        raise ValueError("Expected one licensed Pages evidence artifact")
    artifact = matches[0]
    artifact_id = artifact.get("id")
    if (artifact.get("expired") is not False or type(artifact_id) is not int or artifact_id < 1
            or not re.fullmatch(r"sha256:[0-9a-f]{64}", artifact.get("digest") or "")):
        raise ValueError("Licensed Pages evidence archive is expired or has invalid metadata")
    return artifact_id


def api(path):
    return json.loads(subprocess.check_output(["gh", "api", path], encoding="utf-8"))


def main():
    repository = os.environ["GITHUB_REPOSITORY"]
    sha = os.environ["GITHUB_SHA"]
    run_id = os.environ["LICENSED_EVIDENCE_RUN_ID"]
    if not re.fullmatch(r"[1-9][0-9]*", run_id):
        raise ValueError("Licensed evidence run ID must be numeric")
    actions = f"repos/{repository}/actions"
    workflow = api(f"{actions}/workflows/simscape-integration.yml")
    run = api(f"{actions}/runs/{run_id}")
    artifacts = api(f"{actions}/runs/{run_id}/artifacts?name={ARTIFACT_NAME}")
    if artifacts["total_count"] != len(artifacts["artifacts"]):
        raise ValueError("Unexpected number of licensed evidence artifacts")
    print(select_artifact(run, artifacts["artifacts"], workflow["id"], repository, sha))


if __name__ == "__main__":
    try:
        main()
    except (ValueError, KeyError, subprocess.CalledProcessError) as exc:
        sys.exit(f"RELEASE HOLD: {exc}")
