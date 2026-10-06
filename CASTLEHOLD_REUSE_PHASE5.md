# Ogre War — Phase 5 Current-Generation Art & Presentation Pass

Phase 5 does not add new ages, units or game systems. It upgrades the presentation of the existing Ogre War battle while preserving the Castlehold-first reuse rule.

## Fortress architecture

The eight generic Phase-4 fortress modules remain in the archive for compatibility, but the live presentation now selects one of **24 age-specific authored OBJ modules**:

- Human: Stone/Bronze/Iron wall, tower, gatehouse and keep.
- Ogre: Stone/Bronze/Iron wall, tower, gatehouse and keep.

Stone humans use lower stone footings, timber palisades, roofs and early gate structures. Bronze shifts to masonry, crenellation and formal gate arches. Iron uses taller round towers, machicolated wall crowns, reinforced gatehouses and a larger keep crown.

Ogre architecture evolves independently from irregular slab/timber defenses into heavier buttressed Bronze works and a much larger spiked Iron citadel. Ogre towers, gates and keeps remain deliberately asymmetric.

The new age-specific kit totals roughly 4.5k source OBJ vertices / 3.5k faces before Godot import. This remains intentionally lightweight for Android while providing materially different silhouettes per age.

## Castlehold-derived material upgrade

Castlehold's authored sandstone, oak and slate maps remain the source material. Phase 5 derives 512×512 Ogre War variants from those originals, adding restrained high-frequency albedo variation and regenerated micro-normal detail rather than simply scaling the 256×256 images. Fortress materials now use these 512 maps.

## Graphical HUD

Recruitment and command controls now use real SVG icons instead of relying on text glyphs. The dock includes:

- icons for all nine human recruit types across Stone/Bronze/Iron;
- age, hold, repair, fort, front, ogre and pause icons;
- live recruit cooldown meters;
- live age-progress meter.

Text remains alongside the icons for accessibility and quick cost reading.

## Combat presentation

- Arrow and torsion-bolt projectiles now use restrained emissive trail geometry.
- Heavy impacts use a small pooled local-light flash in addition to dust/chip/shock VFX.
- Age transitions, gate breaches and keep destruction trigger localized fortress-event VFX.
- Castlehold skeletal clips remain the animation authority, but playback timing now differs by action/body class and heavy attacks have slower, weightier presentation.
- Small visual recoil/settling offsets are layered on top of the Castlehold animation rather than replacing it.

## Scope intentionally unchanged

Economy, age rules, unit statistics, AI, population, victory rules, ranged logic and save behavior are not expanded by this pass. Phase 5 is presentation work, not feature creep.
