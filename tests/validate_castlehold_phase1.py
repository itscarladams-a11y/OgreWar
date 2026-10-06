#!/usr/bin/env python3
from __future__ import annotations
import json
import struct
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
    gltf_path = CHAR / f"{name}.gltf"
    assert gltf_path.is_file(), gltf_path
    doc = json.loads(gltf_path.read_text())
    animations = {a.get("name") for a in doc.get("animations", [])}
    missing = required_anims - animations
    assert not missing, f"{name}: missing animations {sorted(missing)}"
    for buffer in doc.get("buffers", []):
        uri = buffer.get("uri")
        if uri:
            target = CHAR / uri
            assert target.is_file(), f"{name}: missing buffer {uri}"
            if "byteLength" in buffer:
                assert target.stat().st_size >= int(buffer["byteLength"]), f"{name}: short binary buffer"
    for image in doc.get("images", []):
        uri = image.get("uri")
        if uri and not uri.startswith("data:"):
            assert (CHAR / uri).is_file(), f"{name}: missing image {uri}"

# Validate reusable WAV files can actually be opened as PCM/RIFF assets.
audio_root = ROOT / "assets/castlehold/audio"
for wav in sorted(audio_root.rglob("*.wav")):
    with wave.open(str(wav), "rb") as handle:
        assert handle.getnchannels() >= 1
        assert handle.getframerate() > 8000
        assert handle.getnframes() > 100

ogg = audio_root / "valley_watch.ogg"
assert ogg.read_bytes()[:4] == b"OggS", "valley_watch.ogg is not an Ogg stream"

# Basic script contracts that protect the specific bugs this phase fixes.
soldier = (ROOT / "scripts/soldier.gd").read_text()
assert "move_ranged_support" in soldier
assert "game.projectiles.launch_unit" in soldier
assert "game.projectiles.launch_structure" in soldier
assert 'maxf(12.0, float(stats["range"]) + 4.0)' in soldier

visual = (ROOT / "scripts/unit_visual.gd").read_text()
assert 'const SIEGE_KINDS := ["ram", "torsion"]' in visual
assert '"slinger": "slinger"' in visual
assert '"thrower": "enemy_slinger"' in visual

projectiles = (ROOT / "scripts/battle_projectiles.gd").read_text()
assert "const SLOT_COUNT := 96" in projectiles
assert "take_ranged_hit" in projectiles
assert '"stone": return 16.0' in projectiles

match = (ROOT / "scripts/match.gd").read_text()
assert "OgreWarProjectilePool.new()" in match
assert "OgreWarBattlefield.new().build(self)" in match
assert "fortress_skin.apply(fort)" in match

audio = (ROOT / "scripts/battle_audio.gd").read_text()
assert '"res://assets/castlehold/audio/valley_watch.ogg"' in audio
assert "const MUSIC_DB := -9.5" in audio
assert "play_defeat" in audio

print(f"PASS: {len(required_models)} Castlehold-derived GLTFs, {len(list(audio_root.rglob('*.wav')))} WAVs, OGG music, ranged/projectile/audio/fortress contracts")
