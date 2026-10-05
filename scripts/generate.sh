#!/usr/bin/env bash
# Regenerates the bindings from the protos.zip in scout's @nominal-io/proto-zip-npm-files package.
set -euo pipefail

zip="$(realpath "${1:?usage: generate.sh <protos.zip>}")"
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
scratch=$(mktemp -d)
trap 'rm -rf "$scratch"' EXIT

export GOBIN="$root/.bin"
export PATH="$GOBIN:$PATH"
go install github.com/bufbuild/buf/cmd/buf@v1.72.0
go install google.golang.org/protobuf/cmd/protoc-gen-go@v1.36.12
go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@v1.6.2

cd "$scratch"
unzip -q "$zip" -d proto
# workflows-service-api ships in the zip but is not a public API.
buf generate proto --template "$root/buf.gen.yaml" --output out \
  --path proto/nominal --exclude-path proto/nominal/workflows

# Replace generated files only, keeping handwritten tests.
find "$root/nominal" -name '*.pb.go' -delete
cp -R out/nominal "$root/"
