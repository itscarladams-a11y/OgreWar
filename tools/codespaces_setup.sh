#!/usr/bin/env bash
set -euo pipefail

# Installs the official standard Godot editor for headless imports and tests.
# The game files and user records are not modified by this setup.
godot_version="4.7.2"
godot_zip_sha256="cadd3204e728a35d3f13adb7fd0d7902636b79f6b95c40c265eb73b6c35329e4"
binary_name="Godot_v${godot_version}-stable_linux.x86_64"
download_url="https://github.com/godotengine/godot-builds/releases/download/${godot_version}-stable/${binary_name}.zip"
install_path="${HOME}/.local/bin/godot"

# The image validator checks launcher alpha with Pillow. Fresh devcontainers
# include it; older Codespaces and Actions runners may need to install it.
if ! python3 -c 'import PIL' >/dev/null 2>&1; then
  if ! python3 -m pip install --user --disable-pip-version-check Pillow >/dev/null 2>&1; then
    if command -v sudo >/dev/null 2>&1; then
      sudo apt-get update
      sudo apt-get install -y --no-install-recommends python3-pil
    fi
  fi
  python3 -c 'import PIL' >/dev/null 2>&1 || {
    echo 'Pillow is missing. Install python3-pil or Pillow for this Python interpreter.' >&2
    exit 1
  }
fi

if [[ -x "$install_path" ]] && "$install_path" --headless --version | grep -q "^${godot_version}"; then
  echo "Godot ${godot_version} is installed at ${install_path}"
  exit 0
fi

command -v curl >/dev/null || { echo 'curl is required. Rebuild the dev container.' >&2; exit 1; }
command -v unzip >/dev/null || { echo 'unzip is required. Rebuild the dev container.' >&2; exit 1; }

temp_dir="$(mktemp -d)"
trap 'rm -rf "$temp_dir"' EXIT
echo "Downloading official Godot ${godot_version} editor..."
curl --fail --location --retry 3 --retry-delay 2 --silent --show-error \
  "$download_url" --output "$temp_dir/godot.zip"
echo "${godot_zip_sha256}  $temp_dir/godot.zip" | sha256sum -c -
unzip -tq "$temp_dir/godot.zip" >/dev/null
unzip -jq "$temp_dir/godot.zip" "$binary_name" -d "$temp_dir"
mkdir -p "$(dirname "$install_path")"
install -m 755 "$temp_dir/$binary_name" "$install_path"
"$install_path" --headless --version
echo 'Run bash tools/verify_codespaces.sh to import and check Ogre War.'
