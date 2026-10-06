# Ogre War — Castlehold Combat + Battlefield Overhaul

This update continues the Castlehold-first rebuild. It is an overlay for the existing Ogre War repository and intentionally preserves Ogre War's economy, ages, match state, fortress HP and win/loss systems.

## What changed

- Replaced the final player siege placeholders with purpose-built siege assemblies that reuse Castlehold textures, character crew meshes and animation clips:
  - Bronze Ram: four-wheel oak frame, suspended ram, bronze beak and two animated crew.
  - Torsion Crew: wheeled torsion engine/ballista, visible bolt rail, winch, torsion arms and two animated crew.
- Added a bounded Castlehold-derived battle VFX pool for sparks, chips and soft dust. Hits no longer rely on bright screen flashes.
- Added actual defeat presentation before cleanup, with Castlehold defeat clips and debris effects.
- Improved formation readability:
  - five spawn lanes instead of three;
  - body-size-aware spacing for infantry, mounted/heavy troops and siege machines;
  - ranged support-line behavior remains enabled;
  - rams prioritize the gate unless an enemy is already on top of them.
- Added Castlehold-style fortress detail layers without replacing working gate/keep damage nodes:
  - human gatehouse buttresses, battlements, slate tower crowns, banners, hoardings and iron bracing;
  - ogre buttresses, spikes, braces, dark banners, braziers and heavier iron-age roofline massing.
- Added battlefield history/details: wheel ruts, broken siege carts, faction banners, campfires/smoke and extra rubble while preserving a clear combat lane.
- Hardened audio using Castlehold's mixer strategy:
  - dedicated music/combat/voice buses;
  - master hard limiter;
  - deferred music-start recheck for Android decoder/start timing;
  - Castlehold boss roar/slam added for the late-game ogre captain.
- Gate breaches now trigger collapse audio plus wood/dust debris. Heavy projectile and melee impacts generate localized VFX.

## Castlehold assets reused

This update continues to reuse the Castlehold rigged character family, Fieldcraft textures, contact shadows, valley materials, oak/sandstone/slate maps, battle audio, voices, and pooled-effects design. New siege geometry is an Ogre War assembly built around those Castlehold resources rather than a new standalone asset pipeline.

## Validation

Run from the extracted update directory:

```bash
bash tests/castlehold_phase2_static.sh
python3 tests/validate_castlehold_phase2.py
```

A real Godot 4.7.2 import/runtime test is still required after applying the overlay, because static validation cannot prove GLTF import scale, Android audio output or final mobile frame pacing.
