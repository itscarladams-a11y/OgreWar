from pathlib import Path
import re

ROOT=Path(__file__).resolve().parents[1]
mods=ROOT/'assets'/'ogre_modern'/'fortress_modules'
required=['human_wall','human_tower','human_gatehouse','human_keep','ogre_wall','ogre_tower','ogre_gatehouse','ogre_keep']

def parse_obj(path):
    verts=[]; faces=[]
    for ln,line in enumerate(path.read_text().splitlines(),1):
        if line.startswith('v '):
            xyz=[float(v) for v in line.split()[1:4]]
            assert all(abs(v)<1000 for v in xyz), (path,ln,'bad vertex')
            verts.append(xyz)
        elif line.startswith('f '):
            ids=[int(v.split('/')[0]) for v in line.split()[1:]]
            assert len(ids)>=3, (path,ln,'short face')
            faces.append(ids)
    assert len(verts)>=80, f'{path.name}: too few vertices ({len(verts)})'
    assert len(faces)>=60, f'{path.name}: too few faces ({len(faces)})'
    for face in faces:
        assert min(face)>=1 and max(face)<=len(verts), f'{path.name}: invalid face index'
    return len(verts),len(faces)

tot_v=tot_f=0
for name in required:
    p=mods/f'{name}.obj'
    assert p.exists(), p
    v,f=parse_obj(p); tot_v+=v; tot_f+=f

# Ensure all authored modules are actually referenced.
fort=(ROOT/'scripts'/'fortress_detail.gd').read_text()
for name in required:
    assert f'"{name}"' in fort, f'{name} not instantiated'
assert 'child == fort.gate_mesh' in fort

# Presentation contracts.
battle=(ROOT/'scripts'/'battlefield_art.gd').read_text()
for phrase in ['shadow_enabled = true','SHADOW_PARALLEL_2_SPLITS','directional_shadow_max_distance = 58.0','fog_enabled','Mobile-safe fog only','Campfire Glow']:
    assert phrase in battle, phrase
assert 'ssao_enabled' not in battle, 'SSAO is unsupported by the Mobile renderer'
hud=(ROOT/'scripts'/'battle_hud.gd').read_text()
for phrase in ['ProgressBar','HUMAN KEEP','OGRE STRONGHOLD','_build_command_dock','_role_color','result_panel']:
    assert phrase in hud, phrase
match=(ROOT/'scripts'/'match.gd').read_text()
assert 'camera_trauma' in match and 'add_camera_trauma' in match
vfx=(ROOT/'scripts'/'battle_vfx.gd').read_text()
assert '"shock"' in vfx and 'CylinderMesh.new()' in vfx

# Cheap structural scan across edited GDScript files.
def balanced(path):
    text=path.read_text()
    text=re.sub(r'#[^\n]*','',text)
    text=re.sub(r'"(?:\\.|[^"\\])*"','""',text)
    pairs={')':'(',']':'[','}':'{'}; stack=[]
    for ch in text:
        if ch in '([{': stack.append(ch)
        elif ch in ')]}':
            assert stack and stack[-1]==pairs[ch], f'delimiter mismatch in {path.name}'
            stack.pop()
    assert not stack, f'unclosed delimiter in {path.name}'

for name in ['fortress_detail.gd','battlefield_art.gd','battle_hud.gd','battle_vfx.gd','match.gd','soldier.gd','unit_visual.gd']:
    balanced(ROOT/'scripts'/name)

print(f'PASS: 8 authored fortress modules ({tot_v} vertices/{tot_f} faces total), modern HUD, bounded shadows/mobile-safe fog and localized combat-weight contracts')
