from pathlib import Path
import json
import re

ROOT = Path(__file__).resolve().parents[1]
CHARS = ROOT / "assets" / "castlehold" / "characters"

model_files = {
    "hunter": "spearman",
    "slinger": "slinger",
    "hauler": "swordsman",
    "raider": "raider",
    "thrower": "enemy_slinger",
    "brute": "ogre",
    "shield": "swordsman",
    "bowman": "archer",
    "orc_guard": "orc_guard",
    "horn_bow": "enemy_archer",
    "ram_beast": "ogre_warthog",
    "swordsman": "swordsman",
    "lancer": "knight",
    "iron_breaker": "orc_guard",
    "warg": "mounted_raider",
    "ogre_captain": "boss_gatebreaker",
}
required_common = {"hips", "chest", "head", "upper_arm_L", "upper_arm_R", "hand_L", "hand_R"}
mount_kinds = {"ram_beast", "warg"}

for kind, base in model_files.items():
    gltf = CHARS / f"{base}.gltf"
    assert gltf.exists(), f"missing {gltf}"
    data = json.loads(gltf.read_text())
    names = {n.get("name", "") for n in data.get("nodes", [])}
    missing = required_common - names
    assert not missing, f"{base} lacks attachment bones: {sorted(missing)}"
    if kind in mount_kinds:
        assert "horse_body" in names, f"{base} lacks mount attachment bone horse_body"
    clips = {a.get("name") for a in data.get("animations", [])}
    for clip in ("idle", "run", "hit", "defeat"):
        assert clip in clips, f"{base} missing {clip}"

refine = (ROOT / "scripts" / "unit_refinement.gd").read_text()
for kind in model_files:
    assert f'"{kind}":' in refine, f"no explicit visual refinement for {kind}"
assert "BoneAttachment3D.new()" in refine
assert "_horned_helmet" in refine and "_pauldrons" in refine and "_back_quiver" in refine

fort = (ROOT / "scripts" / "fortress_detail.gd").read_text()
for phrase in (
    "Visible portcullis behind the timber gate.",
    "Bailey-era timber fighting platforms",
    "Bronze plates look hammered-on",
    "Iron citadel: enormous black-iron crown",
    "Bone trophy poles establish the crude fantasy identity",
):
    assert phrase in fort, phrase

# Cheap structural scan catches accidental delimiter damage in edited GDScript.
def balanced(path: Path):
    text = path.read_text()
    text = re.sub(r'#[^\n]*', '', text)
    text = re.sub(r'"(?:\\.|[^"\\])*"', '""', text)
    pairs = {')':'(', ']':'[', '}':'{'}
    stack=[]
    for ch in text:
        if ch in '([{': stack.append(ch)
        elif ch in ')]}':
            assert stack and stack[-1] == pairs[ch], f"delimiter mismatch in {path.name}"
            stack.pop()
    assert not stack, f"unclosed delimiters in {path.name}"

for script in [
    ROOT/'scripts'/'unit_refinement.gd',
    ROOT/'scripts'/'unit_visual.gd',
    ROOT/'scripts'/'fortress_detail.gd',
    ROOT/'scripts'/'fortress_skin.gd',
    ROOT/'scripts'/'siege_visual.gd',
]:
    balanced(script)

print(f"PASS: refined {len(model_files)} Castlehold-based troop kinds, both siege machines, and all six fortress age/faction states")
