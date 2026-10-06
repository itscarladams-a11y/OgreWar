#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
need() { test -e "$1" || { echo "MISSING: $1" >&2; exit 1; }; }
contains() { grep -Fq "$2" "$1" || { echo "EXPECTED '$2' in $1" >&2; exit 1; }; }

for f in \
  assets/ogre_modern/fortress_modules/human_wall.obj \
  assets/ogre_modern/fortress_modules/human_tower.obj \
  assets/ogre_modern/fortress_modules/human_gatehouse.obj \
  assets/ogre_modern/fortress_modules/human_keep.obj \
  assets/ogre_modern/fortress_modules/ogre_wall.obj \
  assets/ogre_modern/fortress_modules/ogre_tower.obj \
  assets/ogre_modern/fortress_modules/ogre_gatehouse.obj \
  assets/ogre_modern/fortress_modules/ogre_keep.obj \
  scripts/battle_hud.gd scripts/fortress_detail.gd scripts/battlefield_art.gd scripts/battle_vfx.gd scripts/match.gd; do need "$f"; done

contains scripts/fortress_detail.gd 'Modern Fortress Mesh Layer'
contains scripts/fortress_detail.gd 'human_wall'
contains scripts/fortress_detail.gd 'ogre_gatehouse'
contains scripts/fortress_detail.gd 'primary castle silhouette'
contains scripts/battlefield_art.gd 'sun.shadow_enabled = true'
contains scripts/battlefield_art.gd 'SHADOW_PARALLEL_2_SPLITS'
contains scripts/battlefield_art.gd 'fog_enabled'
if grep -Fq 'ssao_enabled' scripts/battlefield_art.gd; then echo 'SSAO must stay disabled on the Mobile renderer' >&2; exit 1; fi
contains scripts/battlefield_art.gd 'Mobile-safe fog only'
contains scripts/battle_hud.gd 'human_keep_bar: ProgressBar'
contains scripts/battle_hud.gd 'OGRE STRONGHOLD'
contains scripts/battle_hud.gd '_build_command_dock'
contains scripts/battle_vfx.gd '"shock"'
contains scripts/match.gd 'camera_trauma'
contains scripts/match.gd 'func add_camera_trauma'
contains scripts/soldier.gd 'game.add_camera_trauma'
contains scripts/unit_visual.gd 'SHADOW_CASTING_SETTING_ON'

echo "Ogre War Castlehold Phase 4 modern-mobile presentation contract: PASS"
