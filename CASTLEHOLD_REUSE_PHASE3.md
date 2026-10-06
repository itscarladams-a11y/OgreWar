# Ogre War — Castle & Unit Visual Refinement Update

This pass deliberately concentrates on the two most visible asset families in Ogre War: every fortress age state and every battlefield unit family. It keeps the Castlehold-first rule from the earlier rebuilds: retain the proven Castlehold rigs, animation clips, textures and materials; add Ogre War-specific detail around those foundations instead of replacing working assets with new placeholders.

## Unit refinement

A new `scripts/unit_refinement.gd` layer attaches age/faction equipment directly to named Castlehold skeleton bones. The attachments follow Castlehold's existing idle, run, attack, shoot, hit and defeat animations.

Human refinements now distinguish:

- Stone Spear Hunter: leather shoulder protection and bone fieldcraft details.
- Stone Sling Skirmisher: ammunition pouch and rear gear on the Castlehold slinger rig.
- Stone Hauler: heavier leather silhouette and load-bearing gear.
- Bronze Shield: bronze brow/helmet hardware, pauldrons and reinforced shield boss.
- Bronze Bowman: bronze headband/bracer and a visible Castlehold-style quiver.
- Iron Swordsman: heavier steel shoulder armor, shield boss and blue crest.
- Iron Lancer: reinforced helmet/pauldrons, mounted pennant and lance-hand hardware.

Ogre/orc refinements now distinguish:

- Bone Raider: crude horned headgear, leather armor and shoulder spikes.
- Rock Thrower: larger stone/ammunition bag plus bone trophies.
- Cave Ogre: broader horned silhouette, spiked shoulders and visible tusks.
- Orc Bulwark: bronze horned helmet, bronze pauldrons and shield reinforcement.
- Horn Bowman: quiver and horned field gear.
- Ram Beast: bronze mount plate plus crude faction standard.
- Ironclad Breaker: black-iron helmet, spiked pauldrons, chest plate and heavy shield boss.
- Warg Outrider: iron rider armor and mount barding.
- Ogre Siege Captain: oversized black-iron crown/helmet, huge spiked pauldrons, tusks, jaw armor and a back banner.

The Bronze Ram and Torsion Crew are still Castlehold-derived assemblies, now with additional age-readable side plating, lashings, pennants, spare bolts, protective screens and refined Castlehold crew. Enemy torsion crews now correctly use enemy/orc character models instead of human-looking crew.

## Fortress refinement

`scripts/fortress_detail.gd` was expanded into six intentionally different visual states while preserving Ogre War's existing gate/keep damage nodes.

### Human

- Stone: timber fighting platforms, braced gatehouse, slate tower roofs, early masonry and bailey-style detailing.
- Bronze: more formal battlements, bronze gate hardware, visible portcullis, rounder tower crowns, bronze wall bosses and blue banners.
- Iron: heavier gate ironwork, machicolation-style keep detailing, steel bracing, larger crenellations, slate keep crown and taller military standards.

### Ogre

- Stone: uneven boulder buttresses, rough timber braces, primitive spikes, tusk-framed gate, palisade platforms and trophy poles.
- Bronze: hammered bronze plates, heavier masonry, larger braziers and more organized but still crude fortification layers.
- Iron: black-iron upper crown, layered gate jaws, dense spikes, heavy iron braces and a much darker late-game silhouette.

Castlehold sandstone, oak and slate texture/normal maps remain the surface foundation. `fortress_skin.gd` now also adjusts the Castlehold surface treatment by faction and age, so the architecture changes in material character as well as shape.

## Validation

Run from the extracted update directory:

```bash
bash tests/castlehold_phase1_static.sh
bash tests/castlehold_phase2_static.sh
bash tests/castlehold_phase3_static.sh
python3 tests/validate_castlehold_phase1.py
python3 tests/validate_castlehold_phase2.py
python3 tests/validate_castlehold_phase3.py
```

Static validation cannot replace a real Godot 4.7.2 import and Android device review. The next runtime review should focus on imported-model orientation, equipment placement, fortress silhouette at gameplay camera distance, and mobile draw cost.
