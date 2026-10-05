#!/usr/bin/env bash
# Regenerates the bindings from the latest @nominal-io/proto-zip-npm-files on GitHub Packages and
# records its version in SCOUT_VERSION. npm needs a token that can read @nominal-io packages.
set -euo pipefail

package=@nominal-io/proto-zip-npm-files
registry=https://npm.pkg.github.com
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

current=$(cat "$root/SCOUT_VERSION")
latest=$(npm view "$package" version --registry "$registry")
echo "$package: $current -> $latest"
if [[ "$current" == "$latest" ]]; then
  exit 0
fi

scratch=$(mktemp -d)
trap 'rm -rf "$scratch"' EXIT
tarball=$(npm pack "$package@$latest" --registry "$registry" --pack-destination "$scratch" --silent)
tar -xzf "$scratch/$tarball" -C "$scratch"
"$root/scripts/generate.sh" "$scratch/package/protos.zip"

# Leave SCOUT_VERSION alone when no published proto changed, so no PR or release is cut.
if [[ -z "$(git -C "$root" status --porcelain -- nominal)" ]]; then
  echo "Generated code is unchanged."
  exit 0
fi
echo "$latest" > "$root/SCOUT_VERSION"
