from pathlib import Path
import re
ROOT=Path(__file__).resolve().parents[1]
GEAR=ROOT/'assets'/'ogre_modern'/'phase6'/'gear'
PROPS=ROOT/'assets'/'ogre_modern'/'phase6'/'props'
FORT=ROOT/'assets'/'ogre_modern'/'fortress_modules'

def parse_obj(p,min_v=20,min_f=15):
    vs=[]; fs=[]
    for ln,line in enumerate(p.read_text().splitlines(),1):
        if line.startswith('v '):
            xyz=[float(x) for x in line.split()[1:4]]
            assert all(abs(x)<1000 for x in xyz),(p.name,ln)
            vs.append(xyz)
        elif line.startswith('f '):
            ids=[int(x.split('/')[0]) for x in line.split()[1:]]
            assert len(ids)>=3,(p.name,ln)
            fs.append(ids)
    assert len(vs)>=min_v and len(fs)>=min_f,(p.name,len(vs),len(fs))
    for face in fs:
        assert min(face)>=1 and max(face)<=len(vs),(p.name,face,len(vs))
    return len(vs),len(fs)

required_gear={
'human_bronze_helmet','human_bronze_pauldron','human_iron_helmet','human_iron_pauldron','human_iron_breastplate',
'ogre_raider_helmet','ogre_bronze_guard_helmet','ogre_iron_breaker_helmet','ogre_captain_helmet','ogre_spiked_pauldron',
'ogre_iron_breastplate','ogre_captain_jaw','mount_iron_barding'}
required_props={'broken_cart_wood','spike_barricade','weapon_pile_iron','ruined_palisade','boulder_cluster','shield_stack'}
assert required_gear <= {p.stem for p in GEAR.glob('*.obj')}
assert required_props <= {p.stem for p in PROPS.glob('*.obj')}
gv=gf=pv=pf=0
for stem in required_gear:
    v,f=parse_obj(GEAR/f'{stem}.obj'); gv+=v; gf+=f
for stem in required_props:
    v,f=parse_obj(PROPS/f'{stem}.obj'); pv+=v; pf+=f
assert gv>=1400 and gf>=1100,(gv,gf)
assert pv>=550 and pf>=400,(pv,pf)

# Hero architecture gets most of the environment budget while walls remain cheap.
hv=hf=0
for faction in ('human','ogre'):
    for age in ('stone','bronze','iron'):
        for part in ('gatehouse','keep'):
            v,f=parse_obj(FORT/f'{faction}_{part}_{age}.obj',100,90); hv+=v; hf+=f
assert hv>=3000 and hf>=2400,(hv,hf)
assert parse_obj(FORT/'human_gatehouse_iron.obj')[0]>=450
assert parse_obj(FORT/'human_keep_iron.obj')[0]>=400
assert parse_obj(FORT/'ogre_gatehouse_iron.obj')[0]>=300

refine=(ROOT/'scripts'/'unit_refinement.gd').read_text()
visual=(ROOT/'scripts'/'unit_visual.gd').read_text()
battle=(ROOT/'scripts'/'battlefield_art.gd').read_text()
for phrase in ['GEAR_ROOT','_attach_bespoke','human_bronze_helmet','human_iron_breastplate','ogre_iron_breaker_helmet','ogre_captain_helmet','mount_iron_barding']:
    assert phrase in refine, phrase
assert refine.count('_attach_bespoke')>=15
assert 'BODY_PROPORTION_BY_KIND' in visual and 'body_proportion * unit_scale' in visual
for phrase in ['PROP_ROOT','_authored_prop','broken_cart_wood','spike_barricade','weapon_pile_iron','ruined_palisade','boulder_cluster','shield_stack','ogre_modern/materials/%s_albedo_512.png']:
    assert phrase in battle, phrase
assert battle.count('_authored_prop(')>=10

def balanced(p):
    text=p.read_text(); text=re.sub(r'#[^\n]*','',text); text=re.sub(r'"(?:\\.|[^"\\])*"','""',text)
    pairs={')':'(',']':'[','}':'{'}; st=[]
    for ch in text:
        if ch in '([{': st.append(ch)
        elif ch in ')]}': assert st and st[-1]==pairs[ch],f'delimiter mismatch {p.name}'; st.pop()
    assert not st,f'unclosed delimiter {p.name}'
for n in ['unit_refinement.gd','unit_visual.gd','battlefield_art.gd','fortress_detail.gd']:
    balanced(ROOT/'scripts'/n)
print(f'PASS: Phase 6 bespoke art: {len(required_gear)} gear meshes ({gv}v/{gf}f), {len(required_props)} authored props ({pv}v/{pf}f), 12 hero fortress meshes ({hv}v/{hf}f), rig attachments and body-proportion contracts')
