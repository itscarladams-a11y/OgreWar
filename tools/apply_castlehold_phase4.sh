#!/usr/bin/env bash
set -euo pipefail
DEST="${1:-.}"
HERE="$(cd "$(dirname "$0")/.." && pwd)"
for item in assets scripts docs tests CASTLEHOLD_REUSE_PHASE1.md CASTLEHOLD_REUSE_PHASE2.md CASTLEHOLD_REUSE_PHASE3.md CASTLEHOLD_REUSE_PHASE4.md; do
  if [ -e "$HERE/$item" ]; then cp -R "$HERE/$item" "$DEST/"; fi
done
mkdir -p "$DEST/tools/castlehold_adapt"
cp "$HERE/tools/castlehold_adapt/build_characters.py" "$DEST/tools/castlehold_adapt/build_characters.py"
cp "$HERE/tools/generate_fortress_modules.py" "$DEST/tools/generate_fortress_modules.py"
echo "Ogre War Modern Mobile Presentation update copied to $DEST"
