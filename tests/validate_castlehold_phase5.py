from pathlib import Path
from PIL import Image
import re
ROOT=Path(__file__).resolve().parents[1]
mods=ROOT/'assets'/'ogre_modern'/'fortress_modules'
ages=('stone','bronze','iron')
parts=('wall','tower','gatehouse','keep')

def parse_obj(p):
    v=[]; f=[]
    for ln,line in enumerate(p.read_text().splitlines(),1):
        if line.startswith('v '):
            xyz=[float(x) for x in line.split()[1:4]]; assert all(abs(x)<1000 for x in xyz); v.append(xyz)
        elif line.startswith('f '):
            ids=[int(x.split('/')[0]) for x in line.split()[1:]]; assert len(ids)>=3; f.append(ids)
    assert len(v)>=40 and len(f)>=30, (p.name,len(v),len(f))
    for face in f: assert 1<=min(face)<=max(face)<=len(v), p.name
    return len(v),len(f)

tv=tf=0
for faction in ('human','ogre'):
    for age in ages:
        for part in parts:
            p=mods/f'{faction}_{part}_{age}.obj'; assert p.exists(),p
            v,f=parse_obj(p); tv+=v; tf+=f
assert tv>=4000 and tf>=3000,(tv,tf)

mat=ROOT/'assets'/'ogre_modern'/'materials'
for family in ('sandstone','oak','slate'):
    for channel in ('albedo','normal'):
        p=mat/f'{family}_{channel}_512.png'; assert p.exists(); assert Image.open(p).size==(512,512)

icons=ROOT/'assets'/'ogre_modern'/'ui'/'phase5'
required={'hunter','slinger','hauler','shield','bowman','ram','swordsman','lancer','torsion','age','hold','repair','fort','front','ogres','pause','gold'}
assert required <= {p.stem for p in icons.glob('*.svg')}

fort=(ROOT/'scripts'/'fortress_detail.gd').read_text(); hud=(ROOT/'scripts'/'battle_hud.gd').read_text(); proj=(ROOT/'scripts'/'battle_projectiles.gd').read_text(); vfx=(ROOT/'scripts'/'battle_vfx.gd').read_text(); unit=(ROOT/'scripts'/'unit_visual.gd').read_text(); match=(ROOT/'scripts'/'match.gd').read_text()
for phrase in ['"human_wall_" + era_name','"human_gatehouse_" + era_name','"ogre_tower_" + era_name','"ogre_keep_" + era_name','512.png']:
    assert phrase in fort, phrase
for phrase in ['ICON_ROOT','UNIT_ICON','_button_meter','cooldown_bars','age_progress_bar','_set_icon']:
    assert phrase in hud, phrase
assert 'Trail' in proj and 'emission_energy_multiplier' in proj
assert 'Impact Glow' in vfx and 'fortress_event' in vfx and 'OmniLight3D.new()' in vfx
assert 'animator.speed_scale' in unit and 'target_roll' in unit
assert match.count('vfx.fortress_event')>=2

def balanced(p):
    text=p.read_text(); text=re.sub(r'#[^\n]*','',text); text=re.sub(r'"(?:\\.|[^"\\])*"','""',text)
    pairs={')':'(',']':'[','}':'{'}; st=[]
    for ch in text:
        if ch in '([{': st.append(ch)
        elif ch in ')]}': assert st and st[-1]==pairs[ch],f'delimiter mismatch {p.name}'; st.pop()
    assert not st,f'unclosed delimiter {p.name}'
for name in ['fortress_detail.gd','battle_hud.gd','battle_projectiles.gd','battle_vfx.gd','unit_visual.gd','match.gd']:
    balanced(ROOT/'scripts'/name)
print(f'PASS: 24 age-specific fortress modules ({tv} vertices/{tf} faces), 512px derived materials, {len(required)} graphical HUD icons, projectile trails, impact lights and animation-weight contracts')
