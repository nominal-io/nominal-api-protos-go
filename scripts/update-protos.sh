#!/usr/bin/env bash
# Regenerates the bindings from @nominal-io/proto-zip-npm-files on GitHub Packages.
# Usage: update-protos.sh [version]; defaults to the latest published version.
# npm needs a token that can read @nominal-io packages.
set -euo pipefail

package=@nominal-io/proto-zip-npm-files
registry=https://npm.pkg.github.com
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
scratch=$(mktemp -d)
trap 'rm -rf "$scratch"' EXIT

version="${1:-$(npm view "$package" version --registry "$registry")}"
tarball=$(npm pack "$package@$version" --registry "$registry" --pack-destination "$scratch" --silent)
tar -xzf "$scratch/$tarball" -C "$scratch"
"$root/scripts/generate.sh" "$scratch/package/protos.zip"
(cd "$root" && go mod tidy)

# Record the version only when the bindings changed, so an unchanged run opens no PR.
if [[ -n "$(git -C "$root" status --porcelain -- nominal)" ]]; then
  echo "$version" > "$root/PROTO_SOURCE_VERSION"
fi
