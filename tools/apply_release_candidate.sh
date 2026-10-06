#!/usr/bin/env bash
set -euo pipefail
DEST="${1:-.}"
HERE="$(cd "$(dirname "$0")/.." && pwd)"

for required in project.godot scripts/fortress.gd scenes/home.tscn tools/build_android_debug.sh; do
  test -s "$DEST/$required" || { echo "Target is not an Ogre War repository root: missing $required" >&2; exit 1; }
done

bash "$HERE/tools/apply_castlehold_phase7.sh" "$DEST"

# The source-level/asset checks below do not require Godot and catch bad copies
# immediately. Full import/smoke/build checks run through verify_codespaces.sh.
cd "$DEST"
for phase in 1 2 3 4 5 6 7; do
  bash "tests/castlehold_phase${phase}_static.sh"
  python3 "tests/validate_castlehold_phase${phase}.py"
done
python3 tests/release_asset_audit.py

echo 'Release-candidate overlay applied successfully.'
echo 'Next: bash tools/codespaces_setup.sh && bash tools/verify_codespaces.sh'
