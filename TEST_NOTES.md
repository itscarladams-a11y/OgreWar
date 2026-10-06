# Ogre War release-candidate test notes

## Phase 10.4 Bantam Entertainment startup

The approved studio logo and loading illustration were copied byte for byte
into `assets/ui/bantam`. The startup scene shows the illustration's upper art
and replaces its decorative bar with real Godot `ResourceLoader` progress.
It stays up until the requested scene is ready and the studio mark has appeared
for at least 1.4 seconds; failure offers an explicit retry.

The Phase 1–10 contracts, binary/asset audit, Godot 4.7.2 headless import and
all nine runtime smoke tests passed. A new startup test covers first install
→ cinematic → war room and returning install → war room, including artwork,
live bar and home studio logo. The existing battle loading, camera bounds,
pinch zoom, bottom dock, ogre AI and gameplay tests passed again.

This workspace has no Android SDK, so no new APK was exported locally. From a
fresh Codespace run `bash CODESPACES_APK_BUILD.sh`, then inspect the APK's
studio opening, touch layout, game loading and frame rate on an Android phone.

## Preparation audit

The final GitHub release candidate was assembled from the 0.7.1 Codespaces fresh install, the Android-build update, and the Castlehold-derived Phase 1–7 rebuild. The preparation environment ran the following successfully:

- current release source contract;
- Phase 1–7 shell contracts;
- Phase 1–7 Python validators;
- release asset integrity audit across the complete repository;
- GLTF/BIN external-buffer validation;
- OBJ face/index validation;
- PNG/SVG/WAV/OGG container checks;
- zero-byte and case-collision scan;
- duplicate `class_name` scan;
- mixed-indentation scan;
- shell syntax validation;
- Python compilation validation.

The release audit also replaced obsolete smoke tests from the old procedural-art build. Those tests incorrectly required `MarchUnitArt` as the active renderer, disabled directional shadows, WAV-only age music and removed fields such as `body_material`/`weapon_joint`. The release candidate tests now target the current Castlehold-derived architecture.

## Audio checks

The startup audio audit expects:

- 3 music roles;
- 23 registered battle/stinger effects;
- 3 human defeat clips;
- 3 orc defeat clips;
- 3 ogre defeat clips;
- Music, Combat and Voice buses.

The manual pause-menu AUDIO CHECK cycles all of them with category-aware timing so longer stingers do not overlap the next check.

## Phase 10 verification

The preparation workspace installed the official Godot 4.7.2 Linux editor and passed the complete `verify_codespaces.sh` gate: source contracts, all Phase 1–10 validators, the release asset audit, Godot import/parse, and home/records, intro first-launch/skip/replay, age, art, audio, visual-stability and complete scene-flow smoke tests. The 24-second supplied cinematic was transcoded to Theora/Vorbis and inspected with `ffprobe`.

For the Android debug export in Codespaces, run:

```bash
bash tools/codespaces_setup.sh
bash tools/codespaces_android_setup.sh
bash tools/verify_codespaces.sh
bash tools/build_android_debug.sh
```

`verify_codespaces.sh` performs the same headless tests before APK export.

## Phase 10.3 battlefield presentation pass

The battlefield road now bends across the valley with broken shader-based
tracks. Castle contact dirt follows both keeps; the previous shader darkened
most of the left battlefield. The four long rectangular rut meshes were
removed. Layered ridges use graduated color, and 460 grass clumps share one
MultiMesh instead of adding an individual scene node for each clump.

The compact top status bar and one-row action tray reclaim at least 60 vertical
pixels at the reference 1280×720 layout. The gameplay regression confirms all
ten controls stay inside the viewport, the new status bar fits above the
battlefield and pinch gestures have the newly exposed touch area. The scene
stability check verifies the instanced grass is created. Phase 1–10 source and
asset checks, headless Godot import, and eight runtime checks passed. The game
still needs an Android APK export and a visual/performance check on a phone;
headless rendering cannot measure sustained frame time or judge materials.

## Phase 10.2 battlefield and mobile review

The two Android screenshots showed the world ending beyond the castles and
the OGRES command cropped at the right side. The new camera limit accounts for
viewport aspect ratio and zoom, and the ground extends beyond it. The dock has
two rows with all ten actions inside the viewport. Two fingers pinch between
20.0 and 29.5 world units; a touch/mouse regression test covers pinch, bounds,
pause, button layout and ogre army composition.

The loading illustration now remains in a separate canvas until the new
battlefield has rendered beneath it; the project clear color is dark in case
the renderer briefly shows an empty frame. Ogre income increased from 46 to
66 gold per interval, first decision starts sooner, and the AI no longer
skips two of five recruitment opportunities when it can field a mixed army.

All Phase 1–10 source validators, model/asset checks, shell syntax checks and
Python compilation checks passed for Phase 10.2. The complete
`tools/verify_codespaces.sh` gate passed with Godot 4.7.2, including headless
import and eight runtime smoke tests. Android SDK build tools are unavailable
here, so an APK export and on-device visual and difficulty checks remain for
Codespaces and the phone.

## Phase 10.1 debugging and fresh-install audit

The clean Phase 10 source was imported again with Godot 4.7.2. The complete
`verify_codespaces.sh` gate passed source and asset checks, Godot import/parse,
and all eight runtime smoke tests. The verifier isolates `user://` test data,
so its first-launch test does not change the developer's story or records.
A new regression test reproduces touch
emulation sending mouse and touch motion in the same swipe. The game now moves
the camera once per swipe and ignores camera input after a match finishes or
while paused. Audio nodes stop and release their streams and owned mixer
configuration when a battle ends; smoke tests wait for decoder shutdown.
Two development-only capture probes with a hard-coded local path were removed.
The export script verifies its prerequisites, clears a stale APK before
building, and reuses one local debug keystore across builds in a Codespace.

The preparation environment has JDK 17 and Godot 4.7.2, but it does not have
Android SDK build tools. No APK was exported here. Run the Android export gate
in Codespaces or GitHub Actions to produce `build/Ogre-War-debug.apk`.

## Phase 9 hero-art pass

The preparation environment passed the complete source/static/asset suite through Phase 9, including 12 hero-fortress overlays, 8 battlefield-depth props, 10 hero-equipment meshes and 9 recruit portrait SVGs. Phase 10 also passes Godot 4.7.2 import and runtime smoke checks locally; Android export remains enforced by `tools/build_android_debug.sh` and GitHub Actions.
