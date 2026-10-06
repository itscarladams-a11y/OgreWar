#!/usr/bin/env bash
set -euo pipefail
DEST="${1:-.}"
HERE="$(cd "$(dirname "$0")/.." && pwd)"
for item in assets scripts docs tests CASTLEHOLD_REUSE_PHASE1.md CASTLEHOLD_REUSE_PHASE2.md CASTLEHOLD_REUSE_PHASE3.md CASTLEHOLD_REUSE_PHASE4.md CASTLEHOLD_REUSE_PHASE5.md CASTLEHOLD_REUSE_PHASE6.md CASTLEHOLD_REUSE_PHASE7.md; do
  if [ -e "$HERE/$item" ]; then cp -R "$HERE/$item" "$DEST/"; fi
done
mkdir -p "$DEST/tools/castlehold_adapt"
if [ -f "$HERE/tools/castlehold_adapt/build_characters.py" ]; then cp "$HERE/tools/castlehold_adapt/build_characters.py" "$DEST/tools/castlehold_adapt/build_characters.py"; fi
for tool in generate_fortress_modules.py generate_fortress_modules_phase5.py build_phase5_materials.py generate_phase5_icons.py generate_phase6_art.py generate_phase7_art.py; do
  if [ -f "$HERE/tools/$tool" ]; then cp "$HERE/tools/$tool" "$DEST/tools/$tool"; fi
done
# Release-candidate verification files replace the obsolete pre-Castlehold smoke harness.
cp "$HERE/tools/verify_codespaces.sh" "$DEST/tools/verify_codespaces.sh"
cp "$HERE/tests/static_contract.sh" "$DEST/tests/static_contract.sh"
cp "$HERE/tests/art_smoke.gd" "$DEST/tests/art_smoke.gd"
cp "$HERE/tests/audio_smoke.gd" "$DEST/tests/audio_smoke.gd"
cp "$HERE/tests/visual_stability_smoke.gd" "$DEST/tests/visual_stability_smoke.gd"
cp "$HERE/tests/release_asset_audit.py" "$DEST/tests/release_asset_audit.py"
chmod +x "$DEST/tools/verify_codespaces.sh" "$DEST/tests/static_contract.sh" "$DEST/tests/release_asset_audit.py"
echo "Ogre War Phase 7 release-candidate overlay copied to $DEST"
