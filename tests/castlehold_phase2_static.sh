#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
need() { test -e "$ROOT/$1" || { echo "MISSING: $1" >&2; exit 1; }; }
contains() { grep -Fq "$2" "$ROOT/$1" || { echo "EXPECTED '$2' in $1" >&2; exit 1; }; }

for f in \
  scripts/siege_visual.gd scripts/battle_vfx.gd scripts/fortress_detail.gd \
  scripts/unit_visual.gd scripts/soldier.gd scripts/match.gd scripts/battle_audio.gd \
  scripts/battle_projectiles.gd scripts/battlefield_art.gd; do need "$f"; done
need assets/castlehold/audio/boss_roar.wav
need assets/castlehold/audio/boss_slam.wav
need assets/castlehold/materials/oak_albedo.png
need assets/castlehold/characters/archer.gltf
need assets/castlehold/characters/orc_guard.gltf

contains scripts/unit_visual.gd 'const SIEGE_KINDS := ["ram", "torsion"]'
contains scripts/unit_visual.gd 'OgreWarSiegeVisual.new()'
contains scripts/siege_visual.gd 'res://assets/castlehold/characters/%s.gltf'
contains scripts/siege_visual.gd 'func _build_ram()'
contains scripts/siege_visual.gd 'func _build_torsion()'
contains scripts/match.gd 'OgreWarBattleVFX.new()'
contains scripts/match.gd 'fortress_detail.apply(human_fort)'
contains scripts/match.gd 'fortress_detail.apply(orc_fort)'
contains scripts/soldier.gd 'func body_radius()'
contains scripts/soldier.gd 'move_ranged_support'
contains scripts/battlefield_art.gd 'func _broken_cart'
contains scripts/battlefield_art.gd 'func _campfire'
contains assets/castlehold/materials/valley_ground.gdshader 'float rut_wear'
contains scripts/battle_audio.gd 'func _configure_mixer()'
contains scripts/battle_audio.gd 'AudioEffectHardLimiter.new()'
contains scripts/battle_audio.gd 'func _ensure_music_playing()'
contains scripts/battle_projectiles.gd 'game.vfx'
contains scripts/fortress_detail.gd 'Castlehold Detail Layer'

echo "Ogre War Castlehold Phase 2 static contract: PASS"
