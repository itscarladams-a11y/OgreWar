from pathlib import Path
import json, re, wave, math, struct
ROOT=Path(__file__).resolve().parents[1]
PROPS=ROOT/'assets'/'ogre_modern'/'phase7'/'props'
DAMAGE=ROOT/'assets'/'ogre_modern'/'phase7'/'damage'

def parse_obj(p,min_v=16,min_f=10):
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

required_props={'fallen_banner','supply_crates','stump_cluster','ruined_watchpost','abandoned_wheel','camp_bundle','rubble_field','weapon_rack'}
required_damage={'timber_splinters','stone_rubble_small','stone_rubble_large','bent_iron','gate_shards','keep_debris'}
assert required_props <= {p.stem for p in PROPS.glob('*.obj')}
assert required_damage <= {p.stem for p in DAMAGE.glob('*.obj')}
pv=pf=dv=df=0
for stem in required_props:
    v,f=parse_obj(PROPS/f'{stem}.obj'); pv+=v; pf+=f
for stem in required_damage:
    v,f=parse_obj(DAMAGE/f'{stem}.obj'); dv+=v; df+=f
assert pv>=650 and pf>=450,(pv,pf)
assert dv>=350 and df>=250,(dv,df)

# Audio manifest and bundled Castlehold audio must be physically non-silent.
manifest=json.loads((ROOT/'docs'/'AUDIO_QA_MANIFEST.json').read_text())
base=manifest['base_repo_verified_2026_09_23']
assert len(base)==16
assert {x['path'] for x in base} >= {'assets/audio/music_bronze.wav','assets/audio/music_iron.wav','assets/audio/stone_sling.wav','assets/audio/iron_sword.wav'}
for x in base:
    assert x['size_bytes']>5000 and re.fullmatch(r'[0-9a-f]{40}',x['git_blob_sha'])
bundled=manifest['bundled_castlehold_audio']
assert len(bundled)==19
for x in bundled:
    p=ROOT/x['path']; assert p.exists() and p.stat().st_size==x['size_bytes']
    if p.suffix=='.wav':
        with wave.open(str(p),'rb') as w:
            assert w.getnframes()>1000 and w.getframerate()>=22050 and w.getnchannels()==1 and w.getsampwidth()==2
            raw=w.readframes(w.getnframes()); vals=struct.unpack('<%dh'%(len(raw)//2),raw)
            rms=math.sqrt(sum(v*v for v in vals)/len(vals))/32768
            peak=max(abs(v) for v in vals)/32768
            assert rms>0.04 and peak>0.20,(p.name,rms,peak)
stone=ROOT/manifest['music_roles']['stone']; assert stone.exists() and stone.stat().st_size>100000

# Every troop attack must map to a registered sound, and the manual QA sequence
# must exercise every registered battle/stinger effect plus all three death banks.
audio=(ROOT/'scripts'/'battle_audio.gd').read_text()
attack_block=re.search(r'const ATTACK_SOUND := \{(.*?)\n\}',audio,re.S).group(1)
effect_block=re.search(r'const EFFECT_PATHS := \{(.*?)\n\}',audio,re.S).group(1)
qa_block=re.search(r'const AUDIO_QA_EFFECT_ORDER := \[(.*?)\n\]',audio,re.S).group(1)
attacks=dict(re.findall(r'"([a-z_]+)"\s*:\s*"([a-z_]+)"',attack_block))
effect_keys=set(re.findall(r'"([a-z_]+)"\s*:',effect_block))
qa_effects=set(re.findall(r'"([a-z_]+)"',qa_block))
classes_block=re.search(r'const CLASSES := \{(.*?)\n\}',(ROOT/'scripts'/'soldier.gd').read_text(),re.S).group(1)
class_keys=set(re.findall(r'^\s*"([a-z_]+)"\s*:',classes_block,re.M))
assert class_keys == set(attacks), (class_keys-set(attacks),set(attacks)-class_keys)
assert set(attacks.values()) <= effect_keys
assert qa_effects == effect_keys,(effect_keys-qa_effects,qa_effects-effect_keys)
for phrase in ['audio_health_report','start_audio_qa','_qa_play_music_age','_qa_play_death','last_attack_by_sound','last_defeat_by_group','MUSIC_BUS','COMBAT_BUS','VOICE_BUS']:
    assert phrase in audio,phrase
assert audio.count('"res://assets/castlehold/audio/voices/')>=9

# Visual polish contracts.
fort=(ROOT/'scripts'/'fortress_damage.gd').read_text(); match=(ROOT/'scripts'/'match.gd').read_text()
for phrase in ['Fortress Damage State','gate_stage','keep_stage','timber_splinters','stone_rubble_large','bent_iron','gate_shards','keep_debris']:
    assert phrase in fort,phrase
assert match.count('fortress_damage.update')>=3 and match.count('fortress_damage.apply')>=3
battle=(ROOT/'scripts'/'battlefield_art.gd').read_text()
assert battle.count('_authored_prop7(')>=14
for stem in required_props: assert stem in battle,stem
visual=(ROOT/'scripts'/'unit_visual.gd').read_text()
for phrase in ['Slingers visibly wind','kind == "lancer"','"brute", "ogre_captain", "iron_breaker"','fall_roll']:
    assert phrase in visual,phrase
siege=(ROOT/'scripts'/'siege_visual.gd').read_text()
for phrase in ['ram_offset','var twist','torsion engine visibly winds']:
    assert phrase in siege,phrase
vfx=(ROOT/'scripts'/'battle_vfx.gd').read_text(); projectiles=(ROOT/'scripts'/'battle_projectiles.gd').read_text(); soldier=(ROOT/'scripts'/'soldier.gd').read_text(); hud=(ROOT/'scripts'/'battle_hud.gd').read_text()
for phrase in ['element == "metal"','element == "stone"','element == "pierce"','footstep_dust']:
    assert phrase in vfx,phrase
for phrase in ['embedded','_stick_projectile','Embedded Projectile']:
    assert phrase in projectiles,phrase
assert 'step_fx_clock' in soldier and 'impact_element' in soldier
assert 'AUDIO CHECK' in hud and 'AUDIO RESOURCES OK' in hud and 'result_crest' in hud

def balanced(p):
    text=p.read_text(); text=re.sub(r'#[^\n]*','',text); text=re.sub(r'"(?:\\.|[^"\\])*"','""',text)
    pairs={')':'(',']':'[','}':'{'}; st=[]
    for ch in text:
        if ch in '([{': st.append(ch)
        elif ch in ')]}': assert st and st[-1]==pairs[ch],f'delimiter mismatch {p.name}'; st.pop()
    assert not st,f'unclosed delimiter {p.name}'
for p in (ROOT/'scripts').glob('*.gd'): balanced(p)
print(f'PASS: Phase 7: {len(required_props)} environment props ({pv}v/{pf}f), {len(required_damage)} fortress-damage meshes ({dv}v/{df}f), 3 music roles, {len(effect_keys)} battle/stinger effects, 9 death voices, signature animation/contact/VFX contracts')
