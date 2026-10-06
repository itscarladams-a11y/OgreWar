#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
for p in \
  assets/ogre_modern/phase7/props/fallen_banner.obj \
  assets/ogre_modern/phase7/props/supply_crates.obj \
  assets/ogre_modern/phase7/props/ruined_watchpost.obj \
  assets/ogre_modern/phase7/props/weapon_rack.obj \
  assets/ogre_modern/phase7/damage/timber_splinters.obj \
  assets/ogre_modern/phase7/damage/stone_rubble_large.obj \
  assets/ogre_modern/phase7/damage/gate_shards.obj \
  assets/ogre_modern/phase7/damage/keep_debris.obj \
  docs/AUDIO_QA_MANIFEST.json; do
  test -s "$ROOT/$p"
done

grep -q 'class_name OgreWarFortressDamage' "$ROOT/scripts/fortress_damage.gd"
grep -q 'fortress_damage.update' "$ROOT/scripts/match.gd"
grep -q 'AUDIO_QA_EFFECT_ORDER' "$ROOT/scripts/battle_audio.gd"
grep -q 'func audio_health_report' "$ROOT/scripts/battle_audio.gd"
grep -q 'func start_audio_qa' "$ROOT/scripts/battle_audio.gd"
grep -q 'last_attack_by_sound' "$ROOT/scripts/battle_audio.gd"
grep -q 'AUDIO CHECK' "$ROOT/scripts/battle_hud.gd"
grep -q 'AUDIO RESOURCES OK' "$ROOT/scripts/battle_hud.gd"
grep -q 'PHASE7_PROP_ROOT' "$ROOT/scripts/battlefield_art.gd"
grep -q '_authored_prop7' "$ROOT/scripts/battlefield_art.gd"
grep -q 'footstep_dust' "$ROOT/scripts/battle_vfx.gd"
grep -q '_stick_projectile' "$ROOT/scripts/battle_projectiles.gd"
grep -q 'Slingers visibly wind' "$ROOT/scripts/unit_visual.gd"
grep -q 'torsion engine visibly winds' "$ROOT/scripts/siege_visual.gd"
echo 'Ogre War Castlehold Phase 7 animation/environment/damage/audio QA contract: PASS'
grep -q 'AUDIO_QA_EFFECT_DURATION' scripts/battle_audio.gd
grep -q 'duration":float(AUDIO_QA_EFFECT_DURATION.get' scripts/battle_audio.gd
grep -q 'set_audio_qa_state(is_instance_valid(audio) and audio.qa_active, message)' scripts/match.gd
