# Ogre War

**Phase 10.4: Bantam Entertainment studio opening and fresh Android build**

Ogre War is an offline, landscape, single-player Godot 4.7.2 siege game for Android and desktop development. Human and ogre armies independently advance through Stone, Bronze and Iron ages while fighting across one continuous valley. Break the opposing gate, then destroy the keep before your own falls.

## Current presentation

This repository no longer uses the original procedural troop art as its normal rendering path. The current battle presentation includes:

- Castlehold-derived rigged GLTF troops with authored animation clips and Ogre War-specific equipment/body refinements.
- Human and ogre Stone/Bronze/Iron fortress families built from age-specific modular meshes and Castlehold-derived surface materials.
- Visible pooled sling stones, rocks, arrows and torsion bolts, plus embedded arrow/bolt impacts.
- Pooled combat VFX, specific metal/wood/stone/pierce impacts, dust, debris and bounded camera trauma.
- Mobile-conscious directional shadows, height fog, filmic tonemapping and warm local fire lighting.
- Curving, worn battle road; matching ground contact at both keeps; layered ridge colors; instanced verge grass that avoids hundreds of separate grass nodes.
- Compact graphical battle HUD with all ten actions in one row, faction health, recruit icons, cooldown meters and age progress.
- New original painted main-menu and loading scenes, separate transparent title mark, launcher crest, and themed boot splash.
- Approved Bantam Entertainment studio art at startup, with a live resource-loading bar and an unobtrusive studio logo in the war room.
- A 24-second "Humanity's Last Stand" opening cinematic that plays once on first launch, can be skipped, and can be replayed with **WATCH STORY**.
- Visible fortress damage stages with soot, splinters, rubble, bent iron and collapse debris.
- Three age music roles, age/battle/result effects, human/orc/ogre defeat voices and an in-game **AUDIO CHECK** sequence.

`scripts/unit_art.gd` is intentionally retained only as an emergency visual fallback if a Castlehold-derived model cannot load.

## Play / controls

Run `project.godot`. The Bantam studio screen loads the opening story on first launch; tap **SKIP INTRO** to go straight to the war room. Later launches load the war room after the studio screen. Choose **MARCH TO WAR** to start, or **WATCH STORY** to replay the cinematic. Recruit from the bottom HUD. Troops move and fight automatically.

- Drag the battlefield to scout. Pinch to zoom in on troops; pinch out to
  return to the wide battlefield. The desktop mouse wheel also zooms.
- **OUR FORT / FRONT / ORCS** jump the camera.
- **HOLD / ADVANCE** changes the human army order.
- **REPAIR** can repair an unbreached human gate twice per battle.
- Earn age progress in combat and pay gold to advance Stone → Bronze → Iron.
- Pause to mute/unmute or run **AUDIO CHECK**.

The human and ogre economies, ages, recruitment cooldowns and population limits
are independent. The ogres have a stronger starting reserve, faster
reinforcements and more income to make an active human push harder to sustain.
Existing troops keep the era/type they were recruited in when a faction advances.

## Audio QA

The pause-menu **AUDIO CHECK** deliberately cycles:

1. Stone music
2. Bronze music
3. Iron music
4. all 23 registered battle/stinger effects
5. human defeat bank
6. orc defeat bank
7. ogre defeat bank

The game also performs a startup resource audit for all three music roles, registered effects, nine defeat voices and the Music/Combat/Voice buses. The QA sequence restores the prior audio state when it ends or is stopped.

## GitHub / Codespaces verification

The repository is designed to fail before APK export if source, asset, Godot import or smoke checks fail.

```bash
bash CODESPACES_APK_BUILD.sh
```

The script runs Godot setup, Android SDK setup (including interactive Android
license acceptance), the release verifier, and the debug APK export. See
`README_CODESPACES.md` for the commands individually.

A successful debug export is written to:

```text
build/Ogre-War-debug.apk
```

`tools/verify_codespaces.sh` runs:

- current release source contract;
- Phase 1–7 Castlehold/Ogre War contracts plus Phase 8–10 presentation, hero-art, menu and cinematic contracts;
- binary/model/image/audio integrity audit;
- Godot 4.7.2 headless import/parse;
- studio startup/first and later launch, home/records, cinematic first-launch/skip/replay, age progression, art, audio,
  visual stability, full scene flow, dock fit, camera bounds, pinch zoom,
  ogre reinforcements, and pause/result checks.

GitHub Actions runs the same verifier before Android export. Pull requests and pushes to `main` both pass through the release gate.

## Project identity and saves

Ogre War is a separate application from Castlehold. Package ID: `com.cladamswv.ogrewar`. Local records use Ogre War's own `user://` data and do not read or overwrite Castlehold saves.

## Asset provenance

Ogre War's icon/title art, synthesized original Ogre War audio, Ogre War-authored meshes and Castlehold-derived assets are documented in `ASSET_PROVENANCE.md` and `docs/CASTLEHOLD_ASSET_LICENSES.md`. No Age of War, CastleStorm, Lord of the Rings, or other third-party game art/audio is redistributed.

## Release status

The Phase 10.4 source and asset checks, Godot 4.7.2 headless import, and nine
runtime checks passed locally. Android export needs the SDK and templates
installed by the Codespaces build script. Inspect the studio opening and
battlefield on a phone after export. See `TEST_NOTES.md`.
