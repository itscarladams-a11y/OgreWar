# Ogre War Phase 9 — Hero Art & Battlefield Depth

Phase 9 builds directly on the Phase 8 premium-presentation release. It deliberately avoids adding another age or gameplay subsystem and instead spends the visual budget where the phone camera can actually see it.

## Fortress hero art

- Added 12 authored hero-overlay meshes: human/ogre gate and keep treatments for Stone, Bronze and Iron.
- The Phase 5/6 mobile-friendly fortress modules remain the base architecture; Phase 9 adds concentrated silhouette detail to the gatehouse and keep rather than multiplying wall geometry everywhere.
- Human hero overlays emphasize Western-European buttresses, crenellation rhythm, murder-hole framing and Iron-age tower crowns.
- Ogre hero overlays emphasize asymmetry, crude bracing, spikes, brutal crowns and irregular heavy silhouettes.
- Final damage stages now add secondary rubble/shards, bent iron and additional soot around breached gates and ruined keeps.

## Battlefield composition

- Added 8 authored environment mesh families: distant hamlet, chapel ruin, siege-tower wreck, charred-tree cluster, ridge ruin, wagon barricade, banner cluster and rock outcrop.
- Phase 9 places these as larger horizon/midground landmarks outside the five combat lanes, creating foreground/midground/background composition instead of simply increasing prop density.
- Existing Phase 6/7 battle-history props remain in use.

## Hero-unit readability

- Added 10 authored hero-equipment meshes attached to the existing Castlehold rigs.
- Iron Swordsman, Lancer, Iron Breaker, Warg and Ogre Captain receive additional silhouette-defining equipment.
- Character scaling/proportion differences are strengthened for Iron-age hero units while preserving collision/gameplay values.
- Signature secondary attack motion now differentiates Ogre Captain slams, Iron Breaker drives, Lancer thrusts, Swordsman lunges, shielded strikes and Warg charges on top of the shared Castlehold animation clips.
- The orthographic camera tightens from 31.0 to 29.5 so upgraded units and fortress details remain legible at phone size.

## Recruit-card art

- Added nine square SVG recruit portrait badges for the full human Stone/Bronze/Iron roster.
- Recruit buttons now prefer Phase 9 portrait badges and fall back to the Phase 5 icon set if an asset is unavailable.

## Performance strategy

Phase 9 adds 3,478 vertices / 2,688 faces across all new authored OBJ assets. Detail is concentrated in static fortress hero pieces and sparse environment landmarks. Combat logic, population cap and pathing are unchanged.

## Verification

`tests/validate_phase9_art.py` verifies asset counts, OBJ face indices, SVG parsing, runtime references, intended rig bone availability, hero-unit scale contracts and the tighter camera contract. `tools/verify_codespaces.sh` runs the Phase 9 contract before the Godot import/parse and smoke-test gates.
