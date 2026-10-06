#!/usr/bin/env bash
set -euo pipefail
DEST="${1:-.}"
HERE="$(cd "$(dirname "$0")/.." && pwd)"
for item in assets scripts docs tests CASTLEHOLD_REUSE_PHASE1.md CASTLEHOLD_REUSE_PHASE2.md; do
  if [ -e "$HERE/$item" ]; then
    cp -R "$HERE/$item" "$DEST/"
  fi
done
mkdir -p "$DEST/tools/castlehold_adapt"
cp "$HERE/tools/castlehold_adapt/build_characters.py" "$DEST/tools/castlehold_adapt/build_characters.py"
echo "Ogre War Castlehold Combat + Battlefield update copied to $DEST"
