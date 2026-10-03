#!/usr/bin/env bash
# Builds a clean stage for recording the demo (scripts/demo.tape) in ~/sirus-demo:
#
#   finsec-gui/   a git archive of ../finsec-gui, the project the opening /scan runs over
#   clifintech/   a git archive of this repo at HEAD, in a git repo so `baseline set` works
#   .bin/sirus    a shim to this checkout's build, so nothing is installed globally
#
# Archives rather than the working trees: a recording must not show local leftovers.
set -euo pipefail

repo="$(cd "$(dirname "$0")/.." && pwd)"
gui="${SIRUS_DEMO_GUI:-$repo/../finsec-gui}"
stage="${SIRUS_DEMO_STAGE:-$HOME/sirus-demo}"

rm -rf "$stage"
mkdir -p "$stage/.bin" "$stage/clifintech" "$stage/finsec-gui"

printf '#!/bin/sh\nexec node %q "$@"\n' "$repo/packages/cli/dist/cli.js" > "$stage/.bin/sirus"
chmod +x "$stage/.bin/sirus"

git -C "$repo" archive HEAD | tar -x -C "$stage/clifintech"
git -C "$gui" archive HEAD | tar -x -C "$stage/finsec-gui"

# The committed sample report predates D-046's key binding and does not verify;
# the recording verifies the report it writes itself.
rm -f "$stage"/clifintech/sirus-report-*.json

(
  cd "$stage/clifintech"
  git init -q
  git add -A
  git -c user.name=demo -c user.email=demo@localhost commit -q -m stage
)

echo "stage ready: $stage"
