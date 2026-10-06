from pathlib import Path
import math

ROOT = Path(__file__).resolve().parents[1]
FORT = ROOT/'assets'/'ogre_modern'/'phase9'/'fortress_hero'
PROPS = ROOT/'assets'/'ogre_modern'/'phase9'/'props'
GEAR = ROOT/'assets'/'ogre_modern'/'phase9'/'gear'
UI = ROOT/'assets'/'ogre_modern'/'ui'/'phase9'
for p in (FORT, PROPS, GEAR, UI): p.mkdir(parents=True, exist_ok=True)

class Obj:
    def __init__(self,name): self.name=name; self.v=[]; self.f=[]
    def vert(self,p): self.v.append(tuple(float(x) for x in p)); return len(self.v)
    def face(self,*ids): self.f.append(tuple(ids))
    def quad(self,a,b,c,d): self.f.append((a,b,c,d))
    def box(self,c,s,rx=0.0,ry=0.0,rz=0.0,taper=(1.0,1.0)):
        cx,cy,cz=c; sx,sy,sz=[x/2 for x in s]; bx,bz=taper
        pts=[(-sx*bx,-sy,-sz*bz),(sx*bx,-sy,-sz*bz),(sx,sy,-sz),(-sx,sy,-sz),(-sx*bx,-sy,sz*bz),(sx*bx,-sy,sz*bz),(sx,sy,sz),(-sx,sy,sz)]
        def rot(p):
            x,y,z=p
            if rx: y,z=y*math.cos(rx)-z*math.sin(rx),y*math.sin(rx)+z*math.cos(rx)
            if ry: x,z=x*math.cos(ry)+z*math.sin(ry),-x*math.sin(ry)+z*math.cos(ry)
            if rz: x,y=x*math.cos(rz)-y*math.sin(rz),x*math.sin(rz)+y*math.cos(rz)
            return x+cx,y+cy,z+cz
        ids=[self.vert(rot(p)) for p in pts]
        for q in [(0,1,2,3),(4,7,6,5),(0,4,5,1),(1,5,6,2),(2,6,7,3),(4,0,3,7)]: self.quad(*(ids[i] for i in q))
    def prism(self,c,r0,r1,h,sides=10,phase=0.0,oval=(1.0,1.0)):
        cx,cy,cz=c; bot=[]; top=[]
        for i in range(sides):
            a=phase+2*math.pi*i/sides
            bot.append(self.vert((cx+r0*math.cos(a)*oval[0],cy-h/2,cz+r0*math.sin(a)*oval[1])))
            top.append(self.vert((cx+r1*math.cos(a)*oval[0],cy+h/2,cz+r1*math.sin(a)*oval[1])))
        self.face(*reversed(bot)); self.face(*top)
        for i in range(sides): self.quad(bot[i],bot[(i+1)%sides],top[(i+1)%sides],top[i])
    def spike(self,c,r,h,sides=7,tilt=0.0,az=0.0):
        cx,cy,cz=c; base=[]
        for i in range(sides):
            a=2*math.pi*i/sides; base.append(self.vert((cx+r*math.cos(a),cy,cz+r*math.sin(a))))
        tip=self.vert((cx+math.cos(az)*math.sin(tilt)*h,cy+math.cos(tilt)*h,cz+math.sin(az)*math.sin(tilt)*h))
        for i in range(sides): self.face(base[i],base[(i+1)%sides],tip)
        self.face(*reversed(base))
    def arch_blocks(self,c,r,depth,thick,blocks=11):
        cx,cy,cz=c
        for i in range(blocks):
            a=math.pi*i/(blocks-1)
            y=cy+r*math.sin(a); z=cz+r*math.cos(a)
            self.box((cx,y,z),(depth,thick,.52),rx=a-math.pi/2)
    def write(self,path):
        lines=[f'o {self.name}','s off']
        lines += [f'v {x:.6f} {y:.6f} {z:.6f}' for x,y,z in self.v]
        lines += ['f '+' '.join(map(str,reversed(face))) for face in self.f]
        path.write_text('\n'.join(lines)+'\n')

# ---------- Fortress hero overlays (2 factions x gate/keep x 3 ages = 12) ----------
def human_gate_overlay(age):
    ai=['stone','bronze','iron'].index(age); o=Obj(f'human_gate_hero_{age}')
    # forward-facing architectural punctuation, layered atop Phase 6 module
    for z in (-3.55,3.55):
        o.box((-1.02,3.4+ai*.36,z),(.28,5.4+ai*.55,.70),taper=(1.15,1.0))
        o.box((-1.18,5.85+ai*.52,z),(0.55,.40,2.20))
        for k in range(3+ai):
            zz=z-0.72+k*(1.44/max(1,2+ai)); o.box((-1.29,6.28+ai*.52,zz),(.44,.82,.42))
    o.arch_blocks((-1.20,2.4+ai*.10,0),2.65+ai*.10,.42,.36,11+ai*2)
    # murder-hole / crest bridge
    o.box((-1.25,5.75+ai*.62,0),(.52,.34,5.15))
    for z in (-2.15,-1.05,0,1.05,2.15): o.box((-1.46,5.30+ai*.62,z),(.42,.62,.26),rz=.06*(1 if z<0 else -1))
    if ai==0:
        for z in (-2.8,-1.4,0,1.4,2.8): o.box((-1.42,4.58,z),(.34,1.55,.18),rz=.04*(1 if z<0 else -1))
    elif ai==1:
        for z in (-2.7,-1.35,0,1.35,2.7): o.box((-1.52,4.40,z),(.18,2.0,.28))
    else:
        for z in (-2.75,-1.85,-.92,0,.92,1.85,2.75): o.box((-1.56,4.55,z),(.20,2.3,.33))
        for z in (-3.85,3.85): o.prism((-1.12,7.35,z),.62,.50,1.95,10,math.pi/10)
    o.write(FORT/f'human_gate_hero_{age}.obj')

def human_keep_overlay(age):
    ai=['stone','bronze','iron'].index(age); o=Obj(f'human_keep_hero_{age}')
    h=6.7+ai*1.12; w=6.5+ai*.45; d=9.4+ai*.55
    # buttress ribs and crown silhouette
    for z in (-d*.38,-d*.13,d*.13,d*.38):
        o.box((-w/2-.18,h*.43,z),(.55,h*.70,.52),taper=(1.35,1.12))
        o.box((w/2+.18,h*.43,z),(.55,h*.70,.52),taper=(1.35,1.12))
    for z in (-d*.34,0,d*.34):
        o.box((-w/2-.35,h*.64,z),(.28,1.15,.54))
        o.box((w/2+.35,h*.64,z),(.28,1.15,.54))
    top=h+.30
    if ai==0:
        for z in (-d*.40,-d*.20,0,d*.20,d*.40): o.box((0,top+.42,z),(w+.7,.78,.55))
        o.box((0,top+1.05,0),(.40,1.25,d*.68))
    elif ai==1:
        for x in (-w*.42,w*.42):
            for z in (-d*.38,-d*.19,0,d*.19,d*.38): o.box((x,top+.62,z),(.70,1.08,.58))
        o.box((0,top+1.28,0),(.62,2.0,.62))
    else:
        for x in (-w*.43,w*.43):
            for z in (-d*.40,-d*.27,-d*.13,0,d*.13,d*.27,d*.40): o.box((x,top+.68,z),(.76,1.25,.58))
        for x,z in ((-w*.34,-d*.34),(-w*.34,d*.34),(w*.34,-d*.34),(w*.34,d*.34)):
            o.prism((x,top+1.82,z),.70,.58,2.55,10,math.pi/10); o.spike((x,top+3.09,z),.12,.62,7,.06)
        o.box((0,top+1.18,0),(.35,1.85,d*.70))
    o.write(FORT/f'human_keep_hero_{age}.obj')

def ogre_gate_overlay(age):
    ai=['stone','bronze','iron'].index(age); o=Obj(f'ogre_gate_hero_{age}')
    # deliberately asymmetric crude frame
    for z,lean,height in [(-3.8,.10,5.7+ai*.7),(3.45,-.15,5.15+ai*.9)]:
        o.box((1.18,height/2,z),(.62,height,.72),rz=lean,taper=(1.30,1.20))
        o.spike((1.18,height-.05,z),.18,.95+ai*.15,7,.18,0 if z<0 else math.pi)
    o.box((1.32,5.1+ai*.75,-.25),(.72,.65,7.25),rz=.035)
    for z in (-2.8,-1.4,0,1.55,2.85):
        o.box((1.58,4.20+ai*.62,z),(.34,1.85+ai*.18,.32),rz=.10*(1 if z<0 else -1))
        if ai>=1: o.spike((1.58,5.05+ai*.62,z),.10,.48+ai*.15,6,.35,0 if z<0 else math.pi)
    if ai==2:
        for z in (-3.3,3.15):
            o.prism((1.06,7.15,z),.78,.62,2.25,9,.17); o.spike((1.06,8.28,z),.15,.85,7,.10)
    o.write(FORT/f'ogre_gate_hero_{age}.obj')

def ogre_keep_overlay(age):
    ai=['stone','bronze','iron'].index(age); o=Obj(f'ogre_keep_hero_{age}')
    h=6.4+ai*1.25; w=6.8+ai*.55; d=9.6+ai*.60
    for x,z,lean in [(-w*.48,-d*.38,.15),(-w*.50,d*.31,-.11),(w*.47,-d*.30,-.10),(w*.49,d*.41,.14)]:
        o.box((x,h*.43,z),(.70,h*.78,.76),rz=lean,taper=(1.42,1.25))
        o.spike((x,h*.82,z),.16,.82+ai*.16,7,.24,math.pi if x<0 else 0)
    top=h+.25
    for i,z in enumerate((-d*.41,-d*.24,-d*.08,d*.11,d*.29,d*.43)):
        o.box((0,top+.35+(i%2)*.18,z),(w+.45,.68,.60),rz=.02*((i%3)-1))
    # brutal crown spikes grow with age
    for x in (-w*.36,-w*.12,w*.14,w*.39):
        o.spike((x,top+.72,(-.40 if x<0 else .44)*d),.20+ai*.03,1.05+ai*.35,7,.28,0 if x<0 else math.pi)
    if ai>=1:
        o.box((0,top+1.20,0),(.60,2.15,d*.70),rz=.04)
    if ai==2:
        o.prism((0,top+2.10,0),1.05,.72,2.4,9,.15,oval=(1.0,.82))
        for a in range(8):
            ang=2*math.pi*a/8; o.spike((math.cos(ang)*.82,top+3.20,math.sin(ang)*.82),.13,.72,6,.42,ang)
    o.write(FORT/f'ogre_keep_hero_{age}.obj')

for age in ('stone','bronze','iron'):
    human_gate_overlay(age); human_keep_overlay(age); ogre_gate_overlay(age); ogre_keep_overlay(age)

# ---------- Battlefield depth props (8) ----------
def distant_hamlet():
    o=Obj('distant_hamlet')
    for i,(x,z,w,h,d) in enumerate([(-1.6,-.4,1.4,1.3,1.1),(0,-.1,1.7,1.5,1.25),(1.7,.3,1.25,1.15,1.0),(.8,-1.4,1.1,1.0,.9)]):
        o.box((x,h/2,z),(w,h,d)); o.prism((x,h+.30,z),max(w,d)*.58,.06,.60,4,math.pi/4,oval=(1.0,.78))
    o.write(PROPS/'distant_hamlet.obj')
def chapel_ruin():
    o=Obj('chapel_ruin'); o.box((0,1.4,0),(2.6,2.8,3.8)); o.box((0,2.9,0),(2.9,.35,4.1));
    for x in (-1.32,1.32): o.box((x,2.25,0),(.28,4.5,.34),rz=.08*(-1 if x<0 else 1))
    o.box((0,4.25,-1.55),(.50,2.1,.55)); o.spike((0,5.25,-1.55),.14,1.05,7,.04)
    o.write(PROPS/'chapel_ruin.obj')
def siege_tower_wreck():
    o=Obj('siege_tower_wreck')
    for x,z,h,lean in [(-.75,-.5,4.7,.13),(.70,-.45,4.1,-.09),(-.62,.55,3.4,.20),(.62,.50,4.4,-.16)]: o.box((x,h/2,z),(.22,h,.22),rz=lean)
    for y in (1.1,2.3,3.5): o.box((0,y,0),(1.75,.18,1.35),rz=.05*(y-2.3))
    o.box((.95,.72,.05),(2.15,.18,.18),rz=-.72)
    o.write(PROPS/'siege_tower_wreck.obj')
def charred_trees():
    o=Obj('charred_tree_cluster')
    for x,z,h,lean in [(-.9,-.2,3.4,.10),(0,.35,4.2,-.08),(.95,-.1,2.9,.16)]:
        o.prism((x,h/2,z),.16,.10,h,7,.12); o.box((x+.25,h*.68,z),(.12,1.15,.10),rz=.78+lean); o.box((x-.22,h*.52,z),(.10,.90,.10),rz=-.86+lean)
    o.write(PROPS/'charred_tree_cluster.obj')
def ridge_ruin():
    o=Obj('ridge_ruin')
    for x,z,h in [(-1.5,-.3,2.4),(-.8,.2,3.1),(0,.0,2.7),(.85,-.25,3.5),(1.55,.15,2.1)]: o.box((x,h/2,z),(.48,h,.55),rz=.04*x)
    o.box((0,.55,.05),(3.8,.45,1.1)); o.write(PROPS/'ridge_ruin.obj')
def wagon_barricade():
    o=Obj('wagon_barricade')
    o.box((0,.5,0),(3.2,.30,1.1),rz=.08); o.box((-1.15,1.05,0),(.20,1.4,1.0),rz=.12); o.box((1.15,.92,.1),(.20,1.15,.9),rz=-.09)
    for x in (-1.25,1.25): o.prism((x,.50,-.66),.48,.48,.20,12,.10)
    for x in (-1.6,-.7,.3,1.2): o.spike((x,.35,.62),.08,1.05,6,.65,math.pi/2)
    o.write(PROPS/'wagon_barricade.obj')
def banner_cluster():
    o=Obj('banner_cluster')
    for x,z,h,lean in [(-.55,-.2,3.3,.08),(0,.1,4.0,-.05),(.62,-.1,3.0,.11)]:
        o.box((x,h/2,z),(.10,h,.10),rz=lean); o.box((x+.18,h*.78,z+.35),(.06,.82,.70),rz=lean)
    o.write(PROPS/'banner_cluster.obj')
def rock_outcrop():
    o=Obj('rock_outcrop')
    for i,(x,z,sx,sy,sz) in enumerate([(-1.0,0,1.2,.8,1.0),(-.2,.2,1.4,1.1,1.2),(.8,-.1,1.1,.75,.9),(1.4,.25,.75,.55,.8)]):
        o.prism((x,sy/2,z),max(sx,sz)*.48,max(sx,sz)*.36,sy,7,.1*i,oval=(sx/max(sx,sz),sz/max(sx,sz)))
    o.write(PROPS/'rock_outcrop.obj')
for fn in (distant_hamlet,chapel_ruin,siege_tower_wreck,charred_trees,ridge_ruin,wagon_barricade,banner_cluster,rock_outcrop): fn()

# ---------- Hero-unit gear (10) ----------
def helm(name,r=.30,h=.30,crest=False,horns=False):
    o=Obj(name); o.prism((0,0,0),r,r*.95,h,14,math.pi/14)
    o.box((0,-.10,-r*.88),(.11,.34,.09),taper=(.65,1.0))
    if crest:
        for z in (-.18,-.06,.06,.18): o.box((0,.29,z),(.07,.38,.10),rz=.03*z)
    if horns:
        for x in (-r*.82,r*.82): o.spike((x,.10,0),.07,.48,7,.62,math.pi if x<0 else 0)
    o.write(GEAR/f'{name}.obj')
def shoulder(name,w=.72,h=.42,d=.44,spikes=0):
    o=Obj(name); o.box((0,0,0),(w,h,d),taper=(.78,.88))
    for i in range(spikes):
        x=(-.22 if i%2==0 else .22); o.spike((x,h*.45,-d*.45),.055,.32+0.05*i,7,.40,-math.pi/2)
    o.write(GEAR/f'{name}.obj')
def lance_guard():
    o=Obj('human_lancer_lanceguard'); o.prism((0,0,0),.16,.12,.12,12,.0,oval=(1,.7));
    for a in (0,math.pi/2,math.pi,math.pi*1.5): o.spike((math.cos(a)*.13,0,math.sin(a)*.13),.035,.18,6,.85,a)
    o.write(GEAR/'human_lancer_lanceguard.obj')
def quiver_guard():
    o=Obj('human_bowman_quiverguard'); o.box((0,0,0),(.36,.82,.16),taper=(.78,.9)); o.box((0,.40,0),(.42,.10,.20)); o.write(GEAR/'human_bowman_quiverguard.obj')
def warg_faceplate():
    o=Obj('warg_faceplate'); o.box((0,0,0),(.70,.34,.42),taper=(.72,.78));
    for x in (-.27,.27): o.spike((x,.10,-.20),.045,.28,7,.58,-math.pi/2)
    o.write(GEAR/'warg_faceplate.obj')
helm('human_swordsman_greathelm',.31,.34,crest=True); shoulder('human_swordsman_shoulderguard',.68,.38,.40,1)
helm('human_lancer_crest',.30,.32,crest=True); lance_guard(); quiver_guard()
helm('ogre_breaker_crown',.35,.38,crest=False,horns=True); shoulder('ogre_breaker_pauldron',.82,.48,.50,3)
helm('ogre_captain_crown',.40,.43,crest=True,horns=True); shoulder('ogre_captain_pauldron',.94,.54,.58,4); warg_faceplate()

# ---------- Recruit portrait SVGs (9) ----------
portrait_specs={
'hunter':('#315d79','#d9c7aa','SPEAR'), 'slinger':('#315d79','#caa56f','SLING'), 'hauler':('#5d5145','#b59569','MAUL'),
'shield':('#44728c','#a87943','SHIELD'), 'bowman':('#44728c','#8f6b3e','BOW'), 'ram':('#705238','#c49a62','RAM'),
'swordsman':('#294f6b','#9ba8ad','SWORD'), 'lancer':('#294f6b','#c3ccd0','LANCE'), 'torsion':('#566168','#c6ab72','BOLT')
}
for kind,(bg,metal,label) in portrait_specs.items():
    weapon={'hunter':'M24 51 L45 18 L49 22 L28 55 Z','slinger':'M22 23 C38 35 41 49 27 57','hauler':'M20 49 L49 20 M39 18 L52 31','shield':'M21 22 Q38 14 55 22 L52 46 Q38 61 24 46 Z','bowman':'M23 19 Q52 36 24 57 M23 19 L49 38 L24 57','ram':'M18 43 L54 30 M47 23 L58 31 L49 40','swordsman':'M27 57 L46 18 L50 22 L31 60 Z','lancer':'M19 55 L54 17 L57 20 L22 58 Z','torsion':'M18 46 L57 28 M49 22 L59 28 L51 35'}[kind]
    if 'M' in weapon and ('C' in weapon or 'Q' in weapon):
        weapon_el=f'<path d="{weapon}" fill="none" stroke="{metal}" stroke-width="5" stroke-linecap="round"/>'
    elif ' M' in weapon:
        weapon_el=f'<path d="{weapon}" fill="none" stroke="{metal}" stroke-width="5" stroke-linecap="round"/>'
    else:
        weapon_el=f'<path d="{weapon}" fill="{metal}" stroke="#161b1c" stroke-width="2"/>'
    svg=f'''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 76 76">
<defs><linearGradient id="g" x1="0" y1="0" x2="1" y2="1"><stop stop-color="{bg}"/><stop offset="1" stop-color="#101719"/></linearGradient></defs>
<rect x="2" y="2" width="72" height="72" rx="12" fill="url(#g)" stroke="{metal}" stroke-width="3"/>
<circle cx="38" cy="29" r="11" fill="#332a25" stroke="{metal}" stroke-width="2"/>
<path d="M19 62 Q22 43 38 42 Q54 43 57 62 Z" fill="#20282a" stroke="{metal}" stroke-width="2"/>
{weapon_el}
<rect x="12" y="61" width="52" height="9" rx="3" fill="#0c1112" opacity=".86"/>
<text x="38" y="68" text-anchor="middle" font-family="sans-serif" font-size="6.5" font-weight="700" fill="#f3ead8">{label}</text>
</svg>'''
    (UI/f'{kind}.svg').write_text(svg)

# report
for folder,label in ((FORT,'fortress'),(PROPS,'props'),(GEAR,'gear')):
    tv=tf=0; files=list(sorted(folder.glob('*.obj')))
    for p in files:
        v=sum(1 for line in p.read_text().splitlines() if line.startswith('v ')); f=sum(1 for line in p.read_text().splitlines() if line.startswith('f ')); tv+=v; tf+=f
    print(label,len(files),'files',tv,'verts',tf,'faces')
print('ui',len(list(UI.glob('*.svg'))),'portrait SVGs')
