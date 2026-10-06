from pathlib import Path
import json, re, xml.etree.ElementTree as ET
ROOT=Path(__file__).resolve().parents[1]
FORT=ROOT/'assets/ogre_modern/phase9/fortress_hero'
PROPS=ROOT/'assets/ogre_modern/phase9/props'
GEAR=ROOT/'assets/ogre_modern/phase9/gear'
UI=ROOT/'assets/ogre_modern/ui/phase9'
expected_fort={f'{f}_{m}_hero_{a}.obj' for f in ('human','ogre') for m in ('gate','keep') for a in ('stone','bronze','iron')}
expected_props={'distant_hamlet.obj','chapel_ruin.obj','siege_tower_wreck.obj','charred_tree_cluster.obj','ridge_ruin.obj','wagon_barricade.obj','banner_cluster.obj','rock_outcrop.obj'}
expected_gear={'human_swordsman_greathelm.obj','human_swordsman_shoulderguard.obj','human_lancer_crest.obj','human_lancer_lanceguard.obj','human_bowman_quiverguard.obj','ogre_breaker_crown.obj','ogre_breaker_pauldron.obj','ogre_captain_crown.obj','ogre_captain_pauldron.obj','warg_faceplate.obj'}
expected_ui={f'{n}.svg' for n in ('hunter','slinger','hauler','shield','bowman','ram','swordsman','lancer','torsion')}
assert {p.name for p in FORT.glob('*.obj')} == expected_fort
assert {p.name for p in PROPS.glob('*.obj')} == expected_props
assert {p.name for p in GEAR.glob('*.obj')} == expected_gear
assert {p.name for p in UI.glob('*.svg')} == expected_ui

def inspect_obj(path: Path):
    verts=[]; faces=[]
    for line in path.read_text().splitlines():
        if line.startswith('v '): verts.append(line)
        elif line.startswith('f '): faces.append(line)
    assert len(verts) >= 8, f'{path.name}: too few vertices'
    assert len(faces) >= 6, f'{path.name}: too few faces'
    for line in faces:
        for token in line.split()[1:]:
            idx=int(token.split('/')[0]); assert 1 <= idx <= len(verts), f'{path.name}: bad face index {idx}'
    return len(verts),len(faces)

tv=tf=0
for p in sorted(list(FORT.glob('*.obj'))+list(PROPS.glob('*.obj'))+list(GEAR.glob('*.obj'))):
    v,f=inspect_obj(p); tv+=v; tf+=f
assert tv >= 3000 and tf >= 2200
for p in UI.glob('*.svg'):
    ET.parse(p)

fort=(ROOT/'scripts/fortress_detail.gd').read_text()
battle=(ROOT/'scripts/battlefield_art.gd').read_text()
refine=(ROOT/'scripts/unit_refinement.gd').read_text()
hud=(ROOT/'scripts/battle_hud.gd').read_text()
units=(ROOT/'scripts/unit_visual.gd').read_text()
match=(ROOT/'scripts/match.gd').read_text()
damage=(ROOT/'scripts/fortress_damage.gd').read_text()
assert 'PHASE9_HERO_ROOT' in fort and 'human_gate_hero_' in fort and 'ogre_keep_hero_' in fort
assert 'PHASE9_PROP_ROOT' in battle and '_phase9_depth_props()' in battle and 'distant_hamlet' in battle and 'siege_tower_wreck' in battle
assert 'PHASE9_GEAR_ROOT' in refine and '_attach_bespoke9' in refine and 'ogre_captain_crown' in refine and 'warg_faceplate' in refine
assert 'P9_UNIT_ROOT' in hud and 'ResourceLoader.exists(wanted)' in hud
assert '"swordsman": 1.19' in units and '"iron_breaker": 1.25' in units and '"ogre_captain": 0.72' in units
assert 'Phase 9 gives the highest-value silhouettes distinct attack weight' in units and 'kind == "warg"' in units
assert 'CAMERA_WIDE_SIZE := 29.5' in match and 'camera.size = CAMERA_WIDE_SIZE' in match
assert 'Vector3(x - front * 1.55' in damage and 'Vector3(face_x - front * 1.82' in damage
# Ensure every intended bone exists in the rig family where it is used.
for model in ('swordsman.gltf','archer.gltf','knight.gltf','orc_guard.gltf','mounted_raider.gltf','boss_gatebreaker.gltf'):
    data=json.loads((ROOT/'assets/castlehold/characters'/model).read_text())
    names={n.get('name','') for n in data.get('nodes',[])}
    for common in ('head','chest'):
        assert common in names, f'{model}: missing {common}'
assert 'horse_head' in {n.get('name','') for n in json.loads((ROOT/'assets/castlehold/characters/mounted_raider.gltf').read_text()).get('nodes',[])}
print(f'PASS: Phase 9 hero art contract ({tv} verts / {tf} faces across authored OBJ assets)')
