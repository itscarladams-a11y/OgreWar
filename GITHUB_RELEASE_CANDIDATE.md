# Ogre War — GitHub release candidate

This Phase 10.4 ZIP is a **complete repository snapshot**, not an update-only overlay. It contains the original Ogre War project foundation, the Android/Codespaces build workflow, the Castlehold-derived Phase 1–7 game/art/audio rebuild and the Phase 8–10 presentation passes, plus the approved Bantam Entertainment studio opening.

## Release blockers fixed during the fine-toothcomb audit

1. Replaced obsolete cube-era smoke tests that contradicted the current Castlehold-derived art, shadow and audio systems.
2. Added a full binary/model/image/audio integrity audit to the release gate.
3. Corrected manual AUDIO CHECK timing so long stingers do not overlap later checks.
4. Added current audio-QA status directly to the pause panel.
5. Rebuilt the package from a clean Ogre War fresh install so GitHub no longer depends on earlier update ZIPs.
6. Corrected stale README and asset-provenance documentation.
7. Added the required Godot export-template `version.txt` creation to the Android build helper.
8. Expanded GitHub Actions to run on pull requests and install the documented Godot 4.7 Android SDK/NDK/CMake prerequisites.

## Codespaces release gate

From the repository root:

```bash
bash CODESPACES_APK_BUILD.sh
```

If all four commands succeed, the installable debug APK is:

```text
build/Ogre-War-debug.apk
```

## Verification scope

`verify_codespaces.sh` runs the current source contract, Phase 1–10 validators,
complete release asset audit, Godot headless import/parse, and nine smoke
tests covering Bantam studio startup, home/records, intro/skip/replay, three ages, art, audio, visual
stability, scene flow, touch/mouse camera behavior, and pause/result controls.
The runtime tests use isolated `user://` data.

GitHub Actions runs the same verifier before Android export, so a parse/resource/test failure stops the workflow before an APK is published as an artifact.

## Verification status

Phase 10.4 passed the complete local verification gate with Godot 4.7.2:
the source contracts, asset integrity, headless import and nine runtime tests.
Run `bash CODESPACES_APK_BUILD.sh` from the extracted repository root for an APK.
The Android SDK is installed in Codespaces and its licenses are accepted
interactively. GitHub Actions builds the same APK on push. The Android SDK is
not present in the preparation workspace, so an APK was not exported here.
