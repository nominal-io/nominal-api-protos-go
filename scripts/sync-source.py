#!/usr/bin/env python3
"""Refresh the existing proto snapshot from a local Scout checkout and commit."""

import argparse
import hashlib
import json
import subprocess
from pathlib import Path

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("scout", type=Path)
parser.add_argument("revision", help="Scout commit or tag to pin")
args = parser.parse_args()
root = Path(__file__).resolve().parent.parent
manifest = json.loads((root / "source.json").read_text())
revision = subprocess.check_output(
    ["git", "-C", str(args.scout), "rev-parse", "--verify", f"{args.revision}^{{commit}}"], text=True
).strip()
# Read every input before updating files, so a missing source leaves the snapshot intact.
sources = [
    subprocess.check_output(["git", "-C", str(args.scout), "show", f"{revision}:{entry['source_path']}"])
    for entry in manifest["files"]
]
for entry, contents in zip(manifest["files"], sources):
    (root / entry["path"]).write_bytes(contents)
    entry["sha256"] = hashlib.sha256(contents).hexdigest()
manifest["revision"] = revision
(root / "source.json").write_text(json.dumps(manifest, indent=2) + "\n")
print(f"Pinned Scout {revision}")
