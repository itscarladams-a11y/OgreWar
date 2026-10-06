#!/usr/bin/env bash
set -euo pipefail

project_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
godot_bin="${GODOT_BIN:-${HOME}/.local/bin/godot}"
godot_version="4.7.2"
templates_sha256="f298490b8d44d934be425a5a65a51bf15f422428b229a06a6e11d9ffea248011"

export ANDROID_HOME="${ANDROID_HOME:-${HOME}/Android/Sdk}"
export JAVA_HOME="${JAVA_HOME:-/usr/lib/jvm/java-17-openjdk-amd64}"
test -x "$godot_bin" || { echo 'Godot is missing. Run bash tools/codespaces_setup.sh first.' >&2; exit 1; }
"$godot_bin" --headless --version | grep -q "^${godot_version}"
test -f "$project_dir/export_presets.cfg" || { echo 'Missing Android export preset.' >&2; exit 1; }
test -x "$JAVA_HOME/bin/keytool" || { echo 'OpenJDK 17 is required. Run bash tools/codespaces_android_setup.sh' >&2; exit 1; }
test -x "$ANDROID_HOME/build-tools/35.0.1/zipalign" || { echo 'Android build tools are missing. Run bash tools/codespaces_android_setup.sh' >&2; exit 1; }
test -x "$ANDROID_HOME/platform-tools/adb" || { echo 'Android platform tools are missing. Run bash tools/codespaces_android_setup.sh' >&2; exit 1; }
test -f "$ANDROID_HOME/platforms/android-35/android.jar" || { echo 'Android API 35 is missing. Run bash tools/codespaces_android_setup.sh' >&2; exit 1; }
test -d "$ANDROID_HOME/ndk/28.1.13356709" || { echo 'Android NDK is missing. Run bash tools/codespaces_android_setup.sh' >&2; exit 1; }

templates="${HOME}/.local/share/godot/export_templates/${godot_version}.stable"
temp_dir="$(mktemp -d)"
trap 'rm -rf "$temp_dir"' EXIT
if [[ ! -s "$templates/android_debug.apk" || ! -s "$templates/android_release.apk" ]]; then
  archive="$temp_dir/templates.tpz"
  url="https://github.com/godotengine/godot-builds/releases/download/${godot_version}-stable/Godot_v${godot_version}-stable_export_templates.tpz"
  echo "Downloading official Godot ${godot_version} export templates..."
  curl --fail --location --retry 3 --retry-delay 2 --silent --show-error "$url" --output "$archive"
  echo "${templates_sha256}  $archive" | sha256sum -c -
  unzip -tq "$archive" >/dev/null
  mkdir -p "$templates"
  unzip -jqo "$archive" 'templates/android_debug.apk' 'templates/android_release.apk' -d "$templates"
fi
printf '%s\n' "${godot_version}.stable" > "$templates/version.txt"
test -s "$templates/android_debug.apk"
test -s "$templates/android_release.apk"
grep -qx "${godot_version}.stable" "$templates/version.txt"

# Reuse the local debug key so a later APK can install over an earlier build.
# It stays outside the game and is never included in source or ZIP releases.
keystore_dir="${XDG_DATA_HOME:-${HOME}/.local/share}/ogre-war"
keystore="$keystore_dir/debug.keystore"
mkdir -p "$keystore_dir"
chmod 700 "$keystore_dir"
if [[ ! -e "$keystore" ]]; then
  (umask 077; "$JAVA_HOME/bin/keytool" -genkeypair -noprompt -keystore "$keystore" -alias androiddebugkey \
    -storepass android -keypass android -keyalg RSA -keysize 2048 -validity 10000 \
    -dname 'CN=Android Debug,O=Android,C=US' >/dev/null 2>&1)
fi
"$JAVA_HOME/bin/keytool" -list -keystore "$keystore" -alias androiddebugkey -storepass android >/dev/null 2>&1 || {
  echo "Debug keystore is invalid: $keystore" >&2
  exit 1
}
export GODOT_ANDROID_KEYSTORE_DEBUG_PATH="$keystore"
export GODOT_ANDROID_KEYSTORE_DEBUG_USER=androiddebugkey
export GODOT_ANDROID_KEYSTORE_DEBUG_PASSWORD=android

cd "$project_dir"
mkdir -p build
rm -f build/Ogre-War-debug.apk
"$godot_bin" --headless --path . --editor --quit
# Godot's SDK paths are editor settings rather than project settings. Set both
# after the editor creates its config so exports work in a fresh Codespace.
python3 - "${XDG_CONFIG_HOME:-${HOME}/.config}/godot/editor_settings-4.7.tres" "$ANDROID_HOME" "$JAVA_HOME" <<'PY'
from pathlib import Path
import json, re, sys
settings = Path(sys.argv[1])
sdk, java = sys.argv[2:]
if not settings.is_file():
    raise SystemExit(f'Missing Godot editor settings: {settings}')
content = settings.read_text()
for key, value in [('android_sdk_path', sdk), ('java_sdk_path', java)]:
    pattern = rf'(?m)^export/android/{key} = .*?$'
    replacement = f'export/android/{key} = {json.dumps(value)}'
    content, count = re.subn(pattern, lambda _match: replacement, content)
    if count != 1:
        raise SystemExit(f'Godot setting not found: export/android/{key}')
settings.write_text(content)
PY
"$godot_bin" --headless --path . --export-debug Android build/Ogre-War-debug.apk
test -s build/Ogre-War-debug.apk
unzip -tq build/Ogre-War-debug.apk >/dev/null
unzip -Z1 build/Ogre-War-debug.apk | grep -Fx 'lib/arm64-v8a/libgodot_android.so' >/dev/null
echo 'Android debug APK: build/Ogre-War-debug.apk'
