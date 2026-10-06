#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

need() { test -e "$ROOT/$1" || { echo "MISSING: $1" >&2; exit 1; }; }
contains() { grep -Fq "$2" "$ROOT/$1" || { echo "EXPECTED '$2' in $1" >&2; exit 1; }; }

need scripts/unit_visual.gd
need scripts/battle_projectiles.gd
need scripts/battlefield_art.gd
need scripts/battle_audio.gd
need scripts/fortress_skin.gd
need assets/castlehold/characters/slinger.gltf
need assets/castlehold/characters/enemy_slinger.gltf
need assets/castlehold/characters/archer.gltf
need assets/castlehold/characters/ogre.gltf
need assets/castlehold/characters/ogre_warthog.gltf
need assets/castlehold/characters/boss_gatebreaker.gltf
need assets/castlehold/materials/valley_ground.gdshader
need assets/castlehold/audio/valley_watch.ogg
need assets/castlehold/audio/voices/human_defeat_1.wav
need docs/CASTLEHOLD_ASSET_LICENSES.md

contains scripts/soldier.gd "move_ranged_support"
contains scripts/soldier.gd "game.projectiles.launch_unit"
contains scripts/soldier.gd "game.projectiles.launch_structure"
contains scripts/match.gd "OgreWarProjectilePool.new()"
contains scripts/match.gd "OgreWarBattlefield.new().build(self)"
contains scripts/match.gd "fortress_skin.apply(human_fort)"
contains scripts/match.gd "fortress_skin.apply(orc_fort)"
contains scripts/fortress_skin.gd "sandstone_albedo.png"
contains scripts/fortress_skin.gd "uv1_triplanar = true"
contains scripts/battle_audio.gd "valley_watch.ogg"
contains scripts/battle_audio.gd "const MUSIC_DB := -9.5"
contains scripts/unit_visual.gd '"slinger": "slinger"'
contains scripts/unit_visual.gd '"ogre_captain": "boss_gatebreaker"'

echo "Ogre War Castlehold Phase 1 static contract: PASS"
