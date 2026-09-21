#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
# Verify that the vendored inputs still match the recorded Scout snapshot.
python3 - <<'VERIFY'
import hashlib
import json
from pathlib import Path

for source in json.loads(Path("source.json").read_text())["files"]:
    path = Path(source["path"])
    if hashlib.sha256(path.read_bytes()).hexdigest() != source["sha256"]:
        raise SystemExit(f"{path}: source checksum mismatch; use scripts/sync-source.py")
VERIFY
mkdir -p .bin
export GOBIN="$PWD/.bin"
go install github.com/bufbuild/buf/cmd/buf@v1.72.0
go install google.golang.org/protobuf/cmd/protoc-gen-go@v1.36.12
go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@v1.6.2
.bin/buf generate
