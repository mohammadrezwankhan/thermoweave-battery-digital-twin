#!/usr/bin/env python3
"""Verify all workflow action SHAs are full-length and declared in notices.

Source integrity only: this does not constitute legal or IP clearance.
"""
import re
import sys
from pathlib import Path

root = Path(__file__).resolve().parents[1]
notice = (root / "THIRD_PARTY_NOTICES.md").read_text(encoding="utf-8")
use_line = re.compile(r"^\s*(?:-\s*)?uses:\s*(\S+)")
pinned_ref = re.compile(r"^([A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+)@([0-9a-f]{40})$")
errors = []
seen = set()
workflows = sorted((root / ".github" / "workflows").glob("*.yml"))
for path in workflows:
    for lineno, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
        match = use_line.match(line)
        if not match:
            continue
        action = match.group(1)
        if action.startswith("./") or action.startswith("docker://"):
            continue
        pinned = pinned_ref.fullmatch(action)
        if not pinned:
            errors.append(f"{path.name}:{lineno}: action is not pinned to full SHA: {action}")
            continue
        name, revision = pinned.groups()
        seen.add((name, revision))
        quote = chr(96)
        notice_entry = quote + name + quote + " commit " + quote + revision + quote
        if notice_entry not in notice:
            errors.append(f"{path.name}:{lineno}: notice missing {action}")
if not workflows or not seen:
    errors.append("No workflow pin inventory found")
if errors:
    print("\n".join(errors), file=sys.stderr)
    sys.exit(1)
print(f"Verified {len(seen)} distinct action pins across {len(workflows)} workflows.")
