# Ogre War: Castlehold Visual Rebuild, Phase 1

This update corrects the visual implementation direction of Ogre War. Castlehold is now the primary asset and presentation foundation instead of a loose reference.

## Castlehold source used

- Source archive: `Castlehold-Battle-Speed-Full.zip`
- Library version used during this rebuild: version 3, dated September 17, 2026
- The Castlehold source archive itself is not modified by this update.
- Castlehold's asset provenance states that the reused character meshes, rigs, animations, environment materials, audio, music and related authoring code are original project assets that the user may use and modify commercially. A copy of that provenance is included at `docs/CASTLEHOLD_ASSET_LICENSES.md`.

## Reused Castlehold character assets

Ogre War now loads real rigged GLTF models instead of using `unit_art.gd` primitives for the normal troop roster.

| Ogre War unit | Castlehold base |
|---|---|
| Spear Hunter | Spearman |
| Sling Skirmisher | New slinger variant authored from Castlehold's human rig/material pipeline |
| Stone Hauler | Swordsman base, Stone-age material treatment |
| Bone Raider | Raider |
| Rock Thrower | New enemy slinger/thrower variant authored from Castlehold's enemy rig/material pipeline |
| Cave Ogre | Ogre |
| Bronze Shield | Swordsman base |
| Recurve Bowman | Archer |
| Orc Bulwark | Orc Guard |
| Horn Bowman | Enemy Archer |
| Ram Beast | Ogre Warthog |
| Iron Swordsman | Swordsman |
| Armored Lancer | Knight |
| Ironclad Breaker | Orc Guard base |
| Warg Outrider | Mounted Raider |
| Ogre Siege Captain | Gatebreaker boss base |

The Bronze Ram and Torsion Crew still use the old procedural fallback in this phase because Castlehold does not have direct matching siege-machine models. They are explicitly marked for a later asset pass rather than pretending the primitive versions are final art.

## Animation changes

Castlehold animation clips are now used when available:

- idle
- walk / run
- attack_a / attack_b
- shoot
- hit
- defeat

Death is no longer an instant `queue_free()`. Units get a short defeat-animation window before cleanup.

## Ranged-combat fix

The old Ogre War behavior allowed ranged troops to walk into the friendly unit in front of them, stop, and remain outside attack range. The new behavior:

- finds the allied melee front;
- forms a rear firing line roughly 3.15 world units behind it;
- permits small lateral lane adjustments when another ally blocks movement;
- uses a larger target sensing distance for ranged units;
- launches visible pooled projectiles rather than applying invisible instant damage.

Projectile profiles currently include sling stones, thrown rocks, arrows and heavy bolts. Projectiles arc across friendly formations and apply damage on impact.

## Castlehold battlefield reuse

The flat Ogre War battlefield is replaced with a Castlehold-derived valley presentation layer using:

- `valley_ground.gdshader`;
- layered ridgelines;
- Castlehold-style procedural trees, rocks and grass;
- procedural sky and valley lighting;
- Castlehold contact-shadow texture beneath imported troops.

Castlehold sandstone, oak and slate surface maps are applied to Ogre War fortress geometry at runtime using triplanar texturing and normal maps. The skin is reapplied after every age transformation, preserving the existing gate/keep gameplay logic while replacing the flat-color surface treatment.

## Castlehold audio reuse

The Stone-age music bed now uses Castlehold's original `The Valley Watch` track, mixed materially louder than Ogre War's previous -17 dB startup. Castlehold bow, hit, gate, victory, defeat, horn and collapse sounds are included, along with human/orc/ogre defeat voice banks.

Ogre War's existing Bronze/Iron music and specialized age weapon effects remain where Castlehold has no matching sound.

## Files replaced / added

Replaced:
- `scripts/soldier.gd`
- `scripts/match.gd`
- `scripts/battle_audio.gd`

Added:
- `scripts/unit_visual.gd`
- `scripts/battle_projectiles.gd`
- `scripts/battlefield_art.gd`
- `scripts/fortress_skin.gd`
- `assets/castlehold/...`
- `tools/castlehold_adapt/build_characters.py`

The old `scripts/unit_art.gd` stays in the project only as a temporary fallback for siege equipment.
