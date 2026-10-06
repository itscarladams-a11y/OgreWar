#!/usr/bin/env bash
set -euo pipefail

project_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

required=(
  project.godot scenes/studio_splash.tscn scenes/home.tscn scenes/loading.tscn scenes/intro.tscn scenes/match.tscn
  scripts/studio_splash.gd scripts/home.gd scripts/loading.gd scripts/intro.gd scripts/records.gd scripts/fortress.gd
  scripts/soldier.gd scripts/unit_art.gd scripts/unit_visual.gd scripts/unit_refinement.gd
  scripts/siege_visual.gd scripts/battle_audio.gd scripts/battle_projectiles.gd
  scripts/battle_vfx.gd scripts/battlefield_art.gd scripts/fortress_skin.gd
  scripts/fortress_detail.gd scripts/fortress_damage.gd scripts/battle_hud.gd scripts/match.gd
  assets/ogre_war_icon.png assets/ogre_war_title.png
  assets/ui/phase10/menu_backdrop.png assets/ui/phase10/loading_backdrop.png
  assets/ui/phase10/ogre_war_logo.png assets/ui/phase10/launcher_crest.png
  assets/ui/phase10/launcher_foreground.png assets/ui/phase10/launcher_background.png
  assets/ui/phase10/boot_splash.png assets/ui/phase10/humanitys_last_stand.ogv
  assets/ui/bantam/studio_logo.png assets/ui/bantam/studio_loading_screen.png
  assets/castlehold/audio/valley_watch.ogg
  assets/castlehold/characters/spearman.gltf assets/castlehold/characters/ogre.bin
  assets/ogre_modern/materials/sandstone_albedo_512.png
  assets/ogre_modern/fortress_modules/human_gatehouse_iron.obj
  assets/ogre_modern/phase7/damage/stone_rubble_large.obj
  assets/ogre_modern/ui/phase5/hunter.svg
  assets/audio/music_bronze.wav assets/audio/music_iron.wav
  tests/home_smoke.gd tests/intro_smoke.gd tests/flow_smoke.gd tests/audio_smoke.gd
  tests/visual_stability_smoke.gd tests/age_smoke.gd tests/art_smoke.gd
  tools/verify_codespaces.sh tools/codespaces_android_setup.sh
  tools/build_android_debug.sh CODESPACES_APK_BUILD.sh tests/studio_splash_smoke.gd export_presets.cfg
)
for path in "${required[@]}"; do
  test -s "$project_dir/$path" || { echo "Missing release file: $path" >&2; exit 1; }
done

grep -Eq 'run/main_scene="res://scenes/studio_splash.tscn"' "$project_dir/project.godot"
grep -Eq 'config/name="Ogre War"' "$project_dir/project.godot"
grep -Eq 'package/unique_name="com\.cladamswv\.ogrewar"' "$project_dir/export_presets.cfg"

grep -Eq 'class_name MarchMatch' "$project_dir/scripts/match.gd"
grep -Eq 'class_name MarchFortress' "$project_dir/scripts/fortress.gd"
grep -Eq 'class_name MarchSoldier' "$project_dir/scripts/soldier.gd"
grep -Eq 'class_name OgreWarUnitVisual' "$project_dir/scripts/unit_visual.gd"
grep -Eq 'class_name OgreWarSiegeVisual' "$project_dir/scripts/siege_visual.gd"
grep -Eq 'class_name OgreWarProjectilePool' "$project_dir/scripts/battle_projectiles.gd"
grep -Eq 'class_name OgreWarBattleVFX' "$project_dir/scripts/battle_vfx.gd"
grep -Eq 'class_name OgreWarAudio' "$project_dir/scripts/battle_audio.gd"
grep -Eq 'class_name MarchHUD' "$project_dir/scripts/battle_hud.gd"

grep -Fq 'art = OgreWarUnitVisual.new()' "$project_dir/scripts/soldier.gd"
grep -Fq 'fortress_detail.apply(human_fort)' "$project_dir/scripts/match.gd"
grep -Fq 'fortress_damage.apply(human_fort)' "$project_dir/scripts/match.gd"
grep -Fq 'OgreWarBattlefield.new().build(self)' "$project_dir/scripts/match.gd"
grep -Fq 'projectiles = OgreWarProjectilePool.new()' "$project_dir/scripts/match.gd"
grep -Fq 'vfx = OgreWarBattleVFX.new()' "$project_dir/scripts/match.gd"
grep -Fq 'sun.shadow_enabled = true' "$project_dir/scripts/battlefield_art.gd"
grep -Fq 'directional_shadow_max_distance = 58.0' "$project_dir/scripts/battlefield_art.gd"
grep -Fq 'env.set("fog_enabled", true)' "$project_dir/scripts/battlefield_art.gd"
if grep -Fq 'ssao_enabled' "$project_dir/scripts/battlefield_art.gd"; then
  echo 'SSAO must stay disabled on the Mobile renderer.' >&2
  exit 1
fi
grep -Fq 'Mobile-safe fog only' "$project_dir/scripts/battlefield_art.gd"

grep -Fq 'move_ranged_support' "$project_dir/scripts/soldier.gd"
grep -Fq 'game.projectiles.launch_unit' "$project_dir/scripts/soldier.gd"
grep -Fq 'game.projectiles.launch_structure' "$project_dir/scripts/soldier.gd"
grep -Fq 'func _stick_projectile' "$project_dir/scripts/battle_projectiles.gd"
grep -Fq 'func footstep_dust' "$project_dir/scripts/battle_vfx.gd"

grep -Fq 'res://assets/castlehold/audio/valley_watch.ogg' "$project_dir/scripts/battle_audio.gd"
grep -Fq 'res://assets/audio/music_bronze.wav' "$project_dir/scripts/battle_audio.gd"
grep -Fq 'res://assets/audio/music_iron.wav' "$project_dir/scripts/battle_audio.gd"
grep -Fq 'func audio_health_report' "$project_dir/scripts/battle_audio.gd"
grep -Fq 'func start_audio_qa' "$project_dir/scripts/battle_audio.gd"
grep -Fq 'AUDIO CHECK' "$project_dir/scripts/battle_hud.gd"

grep -Fq 'OgreWarRecords.record_match' "$project_dir/scripts/match.gd"
grep -Fq 'func ai_decision' "$project_dir/scripts/match.gd"
grep -Fq 'func toggle_hold' "$project_dir/scripts/match.gd"
grep -Fq 'func try_repair' "$project_dir/scripts/match.gd"
grep -Fq 'func advance_age' "$project_dir/scripts/match.gd"
grep -Fq '"shield", "bowman", "ram"' "$project_dir/scripts/match.gd"
grep -Fq '"swordsman", "lancer", "torsion"' "$project_dir/scripts/match.gd"
grep -Fq '"iron_breaker", "warg", "ogre_captain"' "$project_dir/scripts/match.gd"

if grep -ERq 'hit_flash\(' "$project_dir/scripts"; then
  echo 'Unexpected full-screen/bright hit-flash path remains in battle scripts.' >&2
  exit 1
fi
if grep -ERq 'user://.*castlehold|continuous_siege|WaveDirector' "$project_dir/scripts"; then
  echo 'Unexpected Castlehold save/wave-system reference in Ogre War.' >&2
  exit 1
fi
# MarchUnitArt is intentionally retained only as a safety fallback inside OgreWarUnitVisual.
if grep -R --include='*.gd' -n 'MarchUnitArt.new()' "$project_dir/scripts" | grep -v 'unit_visual.gd'; then
  echo 'Legacy procedural unit art is still instantiated outside the fallback path.' >&2
  exit 1
fi

grep -Fq 'version.txt' "$project_dir/tools/build_android_debug.sh"
grep -Fq 'GODOT_ANDROID_KEYSTORE_DEBUG_PATH' "$project_dir/tools/build_android_debug.sh"
grep -Fq 'f298490b8d44d934be425a5a65a51bf15f422428b229a06a6e11d9ffea248011' "$project_dir/tools/build_android_debug.sh"
grep -Fq 'cadd3204e728a35d3f13adb7fd0d7902636b79f6b95c40c265eb73b6c35329e4' "$project_dir/tools/codespaces_setup.sh"
grep -Fq 'tests/release_asset_audit.py' "$project_dir/tools/verify_codespaces.sh"
grep -Fq 'validate_castlehold_phase${phase}.py' "$project_dir/tools/verify_codespaces.sh"

printf '%s\n' 'Ogre War release-candidate source contract: PASS'
