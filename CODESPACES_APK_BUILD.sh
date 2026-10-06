#!/usr/bin/env bash
set -euo pipefail

project_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$project_dir"
bash tools/codespaces_setup.sh
bash tools/codespaces_android_setup.sh
bash tools/verify_codespaces.sh
bash tools/build_android_debug.sh
printf '\nInstallable Android APK: %s\n' "$project_dir/build/Ogre-War-debug.apk"
