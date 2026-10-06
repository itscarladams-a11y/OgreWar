#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
for p in \
  assets/ogre_modern/phase6/gear/human_bronze_helmet.obj \
  assets/ogre_modern/phase6/gear/human_iron_helmet.obj \
  assets/ogre_modern/phase6/gear/human_iron_breastplate.obj \
  assets/ogre_modern/phase6/gear/ogre_iron_breaker_helmet.obj \
  assets/ogre_modern/phase6/gear/ogre_captain_helmet.obj \
  assets/ogre_modern/phase6/gear/mount_iron_barding.obj \
  assets/ogre_modern/phase6/props/broken_cart_wood.obj \
  assets/ogre_modern/phase6/props/spike_barricade.obj \
  assets/ogre_modern/phase6/props/weapon_pile_iron.obj \
  assets/ogre_modern/phase6/props/ruined_palisade.obj; do
  test -s "$ROOT/$p"
done
grep -q 'GEAR_ROOT' "$ROOT/scripts/unit_refinement.gd"
grep -q '_attach_bespoke' "$ROOT/scripts/unit_refinement.gd"
grep -q 'ogre_captain_helmet' "$ROOT/scripts/unit_refinement.gd"
grep -q 'human_iron_breastplate' "$ROOT/scripts/unit_refinement.gd"
grep -q 'BODY_PROPORTION_BY_KIND' "$ROOT/scripts/unit_visual.gd"
grep -q 'PROP_ROOT' "$ROOT/scripts/battlefield_art.gd"
grep -q '_authored_prop' "$ROOT/scripts/battlefield_art.gd"
grep -q 'ogre_modern/materials/%s_albedo_512.png' "$ROOT/scripts/battlefield_art.gd"
echo 'Ogre War Castlehold Phase 6 bespoke-art conversion contract: PASS'
