# Ogre War — Phase 6 Bespoke Art Conversion

Phase 6 targets the remaining visual tells that made Ogre War read like a cleverly assembled prototype rather than a deliberately authored modern mobile title. It preserves Castlehold's proven rigs, animations, PBR character materials, audio and gameplay systems while replacing the most visible runtime primitive additions with reusable mesh assets.

## Bespoke character equipment

Thirteen new authored OBJ equipment meshes live under `assets/ogre_modern/phase6/gear/`. These cover Bronze and Iron human helmets/pauldrons/breastplate pieces plus raider, Bronze guard, Iron Breaker and Ogre Captain head/torso armor, spiked ogre pauldrons, the captain jaw guard and mounted iron barding.

Priority units now attach those meshes directly to Castlehold skeleton bones through `BoneAttachment3D`. The base Castlehold characters and animation clips remain untouched. Heavy ogres also receive controlled body-proportion changes so Brutes, Iron Breakers and the Ogre Captain differ in mass as well as equipment.

Lower-priority fieldcraft details such as pouches, quivers, small bracers, bone charms and banners remain inexpensive procedural accessories where their screen footprint does not justify another unique mesh.

## Fortress hero-mesh upgrade

Phase 5 already introduced twenty-four age/faction fortress modules. Phase 6 keeps lightweight walls and towers, but rebuilds all twelve **gatehouse and keep** modules at a higher detail budget. These are the structures that dominate gameplay screenshots and the breach/endgame camera views.

Human hero architecture adds stronger arch construction, corbels, murder-hole/machicolation language, watch turrets, layered buttresses and heavier Iron-age crowns. Ogre hero architecture adds deeper asymmetry, jaw-like lintels, irregular buttresses, hanging fangs, heavy crown teeth, trophy sockets and larger Iron-age crown masses.

## Authored battlefield props

Six new OBJ prop families replace the most obvious runtime-box scenery: broken siege carts, spike barricades, ruined palisade sections, weapon piles, shield stacks and clustered boulders. They use Ogre War's 512px Castlehold-derived materials and remain outside the five combat lanes.

The project intentionally keeps grass, distant trees and tiny filler rocks procedural because they are numerous background elements where bespoke meshes would add cost without equivalent visual return.

## Validation

Run:

```bash
bash tests/castlehold_phase6_static.sh
python3 tests/validate_castlehold_phase6.py
```

The Phase 6 validator checks OBJ face indices, mesh density, required gear/prop/hero assets, Castlehold-bone attachment code, body-proportion changes, authored-prop placement and GDScript delimiter integrity. All prior Phase 1–5 contracts should also continue to pass.

A Godot 4.7.2 import and real Android screenshot/video are still required to tune exact helmet/pauldron placement, hero-mesh scale and mobile shadow behavior. Static validation cannot judge those final screen-space details.
