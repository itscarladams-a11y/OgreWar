#!/usr/bin/env python3
from __future__ import annotations
import json
import wave
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CHAR = ROOT / "assets/castlehold/characters"
required_models = {
    "archer", "slinger", "enemy_slinger", "spearman", "swordsman", "knight",
    "raider", "enemy_archer", "orc_guard", "ogre", "ogre_warthog",
    "mounted_raider", "boss_gatebreaker",
}
required_anims = {"idle", "walk", "run", "attack_a", "attack_b", "shoot", "hit", "defeat"}
for name in sorted(required_models):
    doc = json.loads((CHAR / f"{name}.gltf").read_text())
    animations = {a.get("name") for a in doc.get("animations", [])}
    missing = required_anims - animations
    assert not missing, f"{name}: missing {sorted(missing)}"
    for buffer in doc.get("buffers", []):
        uri = buffer.get("uri")
        if uri:
            path = CHAR / uri
            assert path.is_file(), f"{name}: missing {uri}"
            assert path.stat().st_size >= int(buffer.get("byteLength", 0)), f"{name}: short buffer"
    for image in doc.get("images", []):
        uri = image.get("uri")
        if uri and not uri.startswith("data:"):
            assert (CHAR / uri).is_file(), f"{name}: missing texture {uri}"

audio = ROOT / "assets/castlehold/audio"
for wav in sorted(audio.rglob("*.wav")):
    with wave.open(str(wav), "rb") as f:
        assert f.getnchannels() >= 1
        assert f.getframerate() > 8000
        assert f.getnframes() > 100
assert (audio / "valley_watch.ogg").read_bytes()[:4] == b"OggS"

scripts = {p.name: p.read_text() for p in (ROOT / "scripts").glob("*.gd")}
assert 'const SIEGE_KINDS := ["ram", "torsion"]' in scripts["unit_visual.gd"]
assert "MarchUnitArt.new()" in scripts["unit_visual.gd"]  # emergency fallback only
assert "OgreWarSiegeVisual.new()" in scripts["unit_visual.gd"]
assert "func _build_ram()" in scripts["siege_visual.gd"]
assert "func _build_torsion()" in scripts["siege_visual.gd"]
assert "OgreWarBattleVFX.new()" in scripts["match.gd"]
assert "fortress_detail.apply(fort)" in scripts["match.gd"]
assert "func body_radius()" in scripts["soldier.gd"]
assert "game.projectiles.launch_unit" in scripts["soldier.gd"]
assert "game.projectiles.launch_structure" in scripts["soldier.gd"]
assert "func _ensure_music_playing()" in scripts["battle_audio.gd"]
assert "AudioEffectHardLimiter.new()" in scripts["battle_audio.gd"]
assert '"boss_roar": "res://assets/castlehold/audio/boss_roar.wav"' in scripts["battle_audio.gd"]
assert "func _battlefield_props()" in scripts["battlefield_art.gd"]
assert "Castlehold Detail Layer" in scripts["fortress_detail.gd"]

# Protect against accidental regression to the original invisible-ranged bug.
assert 'maxf(12.0, float(stats["range"]) + 4.0)' in scripts["soldier.gd"]
assert "move_ranged_support" in scripts["soldier.gd"]
assert "take_ranged_hit" in scripts["battle_projectiles.gd"]

print(
    f"PASS: {len(required_models)} Castlehold-derived GLTFs, "
    f"{len(list(audio.rglob('*.wav')))} Castlehold WAVs, "
    "new ram/torsion visuals, pooled VFX, formation spacing, fortress dressing and hardened music startup"
)
