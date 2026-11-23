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


def run_artifacts(actions, run_id):
    result = api(f"{actions}/runs/{run_id}/artifacts?name={ARTIFACT_NAME}")
    if result["total_count"] != len(result["artifacts"]):
        raise ValueError("Unexpected number of licensed evidence artifacts")
    return result["artifacts"]


def latest_artifact(actions, workflow_id, repository, sha):
    if not re.fullmatch(r"[0-9a-f]{40}", sha):
        raise ValueError("Expected an exact source commit")
    response = api(f"{actions}/workflows/{workflow_id}/runs?"
                   f"head_sha={sha}&branch=main&event=workflow_dispatch&status=success&per_page=100")
    for run in response["workflow_runs"]:
        run_id = run.get("id")
        if type(run_id) is not int or run_id < 1:
            continue
        rows = run_artifacts(actions, run_id)
        try:
            return run_id, select_artifact(run, rows, workflow_id, repository, sha)
        except ValueError:
            continue
    raise ValueError("No usable licensed integration artifact for the exact source commit")


def main():
    repository = os.environ["GITHUB_REPOSITORY"]
    sha = os.environ.get("EXPECTED_SOURCE_SHA") or os.environ["GITHUB_SHA"]
    actions = f"repos/{repository}/actions"
    workflow = api(f"{actions}/workflows/simscape-integration.yml")
    if sys.argv[1:] == ["--latest"]:
        print(*latest_artifact(actions, workflow["id"], repository, sha))
        return
    run_id = os.environ["LICENSED_EVIDENCE_RUN_ID"]
    if not re.fullmatch(r"[1-9][0-9]*", run_id):
        raise ValueError("Licensed evidence run ID must be numeric")
    run = api(f"{actions}/runs/{run_id}")
    artifacts = run_artifacts(actions, run_id)
    print(select_artifact(run, artifacts, workflow["id"], repository, sha))


if __name__ == "__main__":
    try:
        main()
    except (ValueError, KeyError, subprocess.CalledProcessError) as exc:
        sys.exit(f"RELEASE HOLD: {exc}")
