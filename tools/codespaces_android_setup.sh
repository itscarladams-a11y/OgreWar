#!/usr/bin/env bash
set -euo pipefail

# Godot 4.7.2's Android package versions. The download archive's checksum is
# published on the Android Studio command-line-tools download page.
archive_url='https://dl.google.com/android/repository/commandlinetools-linux-15859902_latest.zip'
archive_sha256='4e4c464f145a7512b57d088ac6c278c03c9eea610886b35a5e0804e74eedf583'
android_sdk="${ANDROID_HOME:-${HOME}/Android/Sdk}"
manager="${android_sdk}/cmdline-tools/latest/bin/sdkmanager"

if [[ ! -x /usr/lib/jvm/java-17-openjdk-amd64/bin/keytool ]]; then
  if command -v sudo >/dev/null 2>&1; then
    echo 'Installing OpenJDK 17 in the existing Codespace...'
    sudo apt-get update
    sudo apt-get install -y --no-install-recommends openjdk-17-jdk-headless
  else
    echo 'OpenJDK 17 is missing. Rebuild the Codespace container.' >&2
    exit 1
  fi
fi

if [[ -x "${android_sdk}/build-tools/35.0.1/zipalign" \
      && -x "${android_sdk}/platform-tools/adb" \
      && -f "${android_sdk}/platforms/android-35/android.jar" \
      && -d "${android_sdk}/cmake/3.10.2.4988404" \
      && -d "${android_sdk}/ndk/28.1.13356709" ]]; then
  echo "Android SDK is already ready at ${android_sdk}"
  exit 0
fi

if [[ ! -x "$manager" ]]; then
  command -v curl >/dev/null || { echo 'curl is required.' >&2; exit 1; }
  command -v unzip >/dev/null || { echo 'unzip is required.' >&2; exit 1; }
  temp_dir="$(mktemp -d)"
  trap 'rm -rf "$temp_dir"' EXIT
  echo 'Downloading verified Android command-line tools...'
  curl --fail --location --retry 3 --retry-delay 2 --silent --show-error "$archive_url" --output "$temp_dir/cmdline-tools.zip"
  echo "${archive_sha256}  $temp_dir/cmdline-tools.zip" | sha256sum -c -
  unzip -q "$temp_dir/cmdline-tools.zip" -d "$temp_dir"
  mkdir -p "${android_sdk}/cmdline-tools"
  mv "$temp_dir/cmdline-tools" "${android_sdk}/cmdline-tools/latest"
fi

# sdkmanager displays the Android SDK licenses and asks the user to accept
# them in the terminal. Never silently agree to a third-party license.
echo 'Review and accept the Android SDK license prompts to continue.'
"$manager" --sdk_root="$android_sdk" --licenses
"$manager" --sdk_root="$android_sdk" \
  'platform-tools' 'build-tools;35.0.1' 'platforms;android-35' \
  'cmdline-tools;latest' 'cmake;3.10.2.4988404' 'ndk;28.1.13356709'

test -x "${android_sdk}/build-tools/35.0.1/zipalign"
test -x "${android_sdk}/platform-tools/adb"
test -f "${android_sdk}/platforms/android-35/android.jar"
test -d "${android_sdk}/cmake/3.10.2.4988404"
test -d "${android_sdk}/ndk/28.1.13356709"
echo "Android SDK ready at ${android_sdk}"
