#!/usr/bin/env bash
set -euo pipefail

project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
godot_bin="${GODOT_BIN:-${HOME}/.local/bin/godot}"

if [[ ! -x "$godot_bin" ]]; then
  echo "Godot editor not found at $godot_bin" >&2
  echo 'Run bash tools/codespaces_setup.sh first.' >&2
  exit 1
fi

cd "$project_root"

echo '== Release source contract =='
bash tests/static_contract.sh

echo '== Castlehold/Ogre War phase contracts =='
for phase in 1 2 3 4 5 6 7; do
  bash "tests/castlehold_phase${phase}_static.sh"
  python3 "tests/validate_castlehold_phase${phase}.py"
done

echo '== Phase 8 presentation contract =='
bash tests/phase8_static.sh

echo '== Phase 9 hero art contract =='
bash tests/phase9_static.sh

echo '== Phase 10 mobile UI and cinematic contract =='
python3 tests/validate_phase10_ui.py

echo '== Binary / asset integrity =='
python3 tests/release_asset_audit.py

echo '== Godot import / parse gate =='
import_log="$(mktemp)"
if ! "$godot_bin" --headless --path . --editor --quit >"$import_log" 2>&1; then
  cat "$import_log"
  rm -f "$import_log"
  exit 1
fi
if grep -Eq 'SCRIPT ERROR|Parse Error|ERROR:|WARNING:.*leaked' "$import_log"; then
  cat "$import_log"
  rm -f "$import_log"
  exit 1
fi
rm -f "$import_log"
echo 'Godot import / parse passed.'

# First-launch tests clear and rewrite user:// intro data. Give the whole
# runtime suite its own data directory so verification never touches a
# developer's real records or first-launch state.
smoke_data_dir="$(mktemp -d)"
trap 'rm -rf "$smoke_data_dir"' EXIT
for script in studio_splash_smoke.gd home_smoke.gd intro_smoke.gd age_smoke.gd art_smoke.gd audio_smoke.gd visual_stability_smoke.gd flow_smoke.gd gameplay_regression.gd; do
  echo "== $script =="
  log_file="$(mktemp)"
  if XDG_DATA_HOME="$smoke_data_dir" timeout 90s "$godot_bin" --headless --path . --script "res://tests/$script" >"$log_file" 2>&1; then
    :
  else
    status=$?
    cat "$log_file"
    rm -f "$log_file"
    if [[ $status -eq 124 ]]; then
      echo "Smoke test timed out after 90 seconds: $script" >&2
    fi
    exit 1
  fi
  if grep -Eq 'SCRIPT ERROR|Parse Error|FAIL:|ERROR:|WARNING:.*leaked' "$log_file"; then
    cat "$log_file"
    rm -f "$log_file"
    exit 1
  fi
  if ! grep -qi 'passed' "$log_file"; then
    cat "$log_file"
    rm -f "$log_file"
    echo "Test did not report success: $script" >&2
    exit 1
  fi
  rm -f "$log_file"
done

echo 'Ogre War release-candidate Codespaces/headless checks passed.'
