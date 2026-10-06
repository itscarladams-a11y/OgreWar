#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
need(){ test -e "$1" || { echo "MISSING: $1" >&2; exit 1; }; }
contains(){ grep -Fq "$2" "$1" || { echo "EXPECTED '$2' in $1" >&2; exit 1; }; }
for faction in human ogre; do
  for part in wall tower gatehouse keep; do
    for age in stone bronze iron; do need "assets/ogre_modern/fortress_modules/${faction}_${part}_${age}.obj"; done
  done
done
for f in sandstone_albedo_512 sandstone_normal_512 oak_albedo_512 oak_normal_512 slate_albedo_512 slate_normal_512; do need "assets/ogre_modern/materials/${f}.png"; done
for f in hunter slinger hauler shield bowman ram swordsman lancer torsion age hold repair fort front ogres pause gold; do need "assets/ogre_modern/ui/phase5/${f}.svg"; done
contains scripts/fortress_detail.gd '"human_wall_" + era_name'
contains scripts/fortress_detail.gd '"ogre_keep_" + era_name'
contains scripts/fortress_detail.gd 'sandstone_albedo_512.png'
contains scripts/battle_hud.gd 'UNIT_ICON'
contains scripts/battle_hud.gd 'cooldown_bars'
contains scripts/battle_hud.gd 'age_progress_bar'
contains scripts/battle_projectiles.gd 'Trail'
contains scripts/battle_vfx.gd 'Impact Glow'
contains scripts/battle_vfx.gd 'fortress_event'
contains scripts/unit_visual.gd 'animator.speed_scale'
contains scripts/match.gd 'vfx.fortress_event'
echo "Ogre War Castlehold Phase 5 current-generation presentation contract: PASS"
