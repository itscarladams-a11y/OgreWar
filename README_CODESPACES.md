# Ogre War in GitHub Codespaces

Extract the release ZIP into the repository root so that `project.godot`,
`assets/`, `scenes/`, `scripts/`, and `tools/` are directly in that directory.
Then run each command from the repository root:

```bash
bash CODESPACES_APK_BUILD.sh
```

Or run the four included setup, verification and export scripts individually:

```bash
bash tools/codespaces_setup.sh
bash tools/codespaces_android_setup.sh
bash tools/verify_codespaces.sh
bash tools/build_android_debug.sh
```

`codespaces_setup.sh` installs the official Godot 4.7.2 Linux editor in `~/.local/bin/godot`.

`codespaces_android_setup.sh` installs the documented Android SDK components. The command-line SDK installer displays its licenses for you to accept in the Codespaces terminal. If upgrading an older Codespace, it also installs JDK 17 when missing.

`verify_codespaces.sh` is the release gate. It runs the source contract,
Phase 1–10 validators, the full asset audit, Godot headless import/parse,
and nine gameplay smoke tests, including Bantam studio startup, cinematic first launch, skip and
replay, battle audio, full scene flow, camera bounds, the compact single-row
button layout, instanced scenery, pinch zoom, ogre reinforcements and pause.

`build_android_debug.sh` checks Android SDK + JDK 17, configures Godot's
per-user export paths, installs matching official Godot Android export
templates if needed, writes the required template `version.txt`, and
exports an ARM64 debug APK. It keeps the debug keystore under
`~/.local/share/ogre-war/debug.keystore` so a later build in the same
Codespace can install over this build. Keep that file if you want to update
the installed app without uninstalling it.

```text
build/Ogre-War-debug.apk
```

GitHub Actions performs the same sequence automatically on pull requests, pushes to `main`, or manual workflow dispatch.

To publish this source to GitHub from a Codespace after extracting and
verifying it, run `git add -A`, `git commit -m "Import Ogre War Phase 10.4"`,
and `git push origin main`. The APK remains an ignored build artifact; download
it from `build/Ogre-War-debug.apk` or the GitHub Actions run. The scripts print
specific setup errors if Godot, Java or Android SDK components are missing.
