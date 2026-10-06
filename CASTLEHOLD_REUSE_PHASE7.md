# Ogre War — Phase 7 Animation, Environment, Damage & Audio QA

Phase 7 is a polish-only overlay on top of Phase 6. It does not add ages, troop classes, economy systems, or match rules. It concentrates on movement individuality, battlefield density, fortress damage readability, combat contact, UI finishing, and end-to-end audio verification.

## Animation individuality

Castlehold's rigged base characters remain the animation foundation, but Ogre War now adds unit-specific secondary motion on top of those clips:

- slingers / rock throwers visibly wind away from the target and snap through release;
- bow units receive a draw/release recovery cue;
- lancers commit to a longer forward thrust;
- swords/shields/raiders get shorter melee lunges;
- brutes, iron breakers, and the ogre captain crouch/wind before heavy overhead impact;
- mounted units get a short charge/recoil movement;
- heavy and mounted movement gets restrained body-weight bob;
- defeat animation receives small alternating fall direction so crowds do not collapse identically.

The Bronze Ram now visibly draws its suspended beam back before the strike. The Torsion Crew winds its arms, snaps forward, and recoils while Castlehold crew clips continue to play.

## Battlefield authored-prop expansion

Eight new Phase 7 OBJ prop families are used outside the five combat lanes:

- fallen banners;
- supply crates;
- stump clusters;
- ruined watchposts;
- abandoned siege wheels;
- camp bundles;
- rubble fields;
- weapon racks.

These join the Phase 6 broken carts, barricades, palisades, weapon piles, shield stacks, and boulder clusters. Ruined watchposts are deliberately positioned in the middle distance to break the procedural valley silhouette without interfering with combat readability.

## Fortress damage states

`fortress_damage.gd` adds a visual state layer driven by the existing gate/keep HP values. The gameplay fortress remains authoritative.

Each gate and keep has four visible damage thresholds after pristine:

1. soot + light splinter/rubble cues;
2. additional rubble and broken material;
3. bent metal, larger timber/stone debris, heavier soot;
4. breached/destroyed debris piles and gate shards.

Repairs update the visual state back toward cleaner stages. Age changes rebuild the damage layer against the new fortress architecture.

## Combat contact polish

- metal weapons bias toward bright sparks;
- clubs/gates bias toward wood chips;
- sling stones and rocks create stone chips and dust;
- arrows use restrained pierce impacts;
- heavy/mounted units kick small footstep dust puffs;
- arrows and torsion bolts remain visibly embedded for a short bounded period after impact;
- embedded projectiles use a fixed pool so long battles do not leak nodes.

## UI polish

The existing Phase 5 graphical HUD remains. Phase 7 adds faction crest treatment to fortress panels and result presentation, plus an Audio QA status/readout in the pause panel.

## Audio QA & mix validation

Audio is now a first-class test surface.

### Startup resource audit

`OgreWarAudio.audio_health_report()` checks that the expected resources are addressable and confirms the runtime has:

- 3 age music players;
- all 23 registered battle/stinger effects;
- 3 human defeat voices;
- 3 orc defeat voices;
- 3 ogre defeat voices;
- dedicated Music, Combat, and Voice buses.

The pause panel displays the result of this startup audit.

### Manual Android audio test bench

Pause the battle and press **AUDIO CHECK**. The process-always audio node cycles through:

1. Stone Age music;
2. Bronze Age music;
3. Iron Age music;
4. every registered battle/stinger effect;
5. one human death voice;
6. one orc death voice;
7. one ogre death voice.

The HUD names each sound while it plays. When complete, the pre-test battle age/music and audio-enabled state are restored. Pressing the button again stops the check.

### Mix fixes

The previous global 62 ms attack-sound lockout has been replaced by a short global safety gap plus per-sound cooldowns. Distinct weapons can now be audible in the same clash without allowing a single repeated sound to dominate the mix. Human/orc/ogre defeat banks also have separate cooldowns, so mixed casualties are less likely to suppress one another.

`docs/AUDIO_QA_MANIFEST.json` records the verified September 23, 2026 GitHub blob SHAs/sizes for Ogre War's base generated audio and measured duration/RMS/peak data for the Castlehold WAVs bundled in this overlay.

## Validation

Run:

```bash
bash tests/castlehold_phase7_static.sh
python3 tests/validate_castlehold_phase7.py
```

Phase 7 static validation checks authored OBJ integrity, all registered attack-to-effect mappings, QA coverage of all effect keys, the three music roles, all nine defeat voices, non-silent bundled Castlehold WAV data, fortress damage integration, secondary animation contracts, embedded projectile pooling, combat-contact effects, UI QA controls, and balanced script delimiters.

A real Godot/Android run remains necessary to confirm audible device output, mixer balance through the phone speaker/headphones, final animation placement, and visual clipping.
