from pathlib import Path
import math

ROOT = Path(__file__).resolve().parents[1]
GEAR = ROOT/'assets'/'ogre_modern'/'phase6'/'gear'
PROPS = ROOT/'assets'/'ogre_modern'/'phase6'/'props'
FORT = ROOT/'assets'/'ogre_modern'/'fortress_modules'
GEAR.mkdir(parents=True, exist_ok=True)
PROPS.mkdir(parents=True, exist_ok=True)

class Obj:
    def __init__(self,name): self.name=name; self.v=[]; self.f=[]
    def vert(self,p): self.v.append(tuple(p)); return len(self.v)
    def face(self,*ids): self.f.append(tuple(ids))
    def quad(self,a,b,c,d): self.f.append((a,b,c,d))
    def tri(self,a,b,c): self.f.append((a,b,c))
    def box(self,c,s,rx=0,ry=0,rz=0,taper=(1,1)):
        cx,cy,cz=c; sx,sy,sz=[x/2 for x in s]; bx,bz=taper
        pts=[(-sx*bx,-sy,-sz*bz),(sx*bx,-sy,-sz*bz),(sx,sy,-sz),(-sx,sy,-sz),(-sx*bx,-sy,sz*bz),(sx*bx,-sy,sz*bz),(sx,sy,sz),(-sx,sy,sz)]
        def rot(p):
            x,y,z=p
            if rx: y,z=y*math.cos(rx)-z*math.sin(rx),y*math.sin(rx)+z*math.cos(rx)
            if ry: x,z=x*math.cos(ry)+z*math.sin(ry),-x*math.sin(ry)+z*math.cos(ry)
            if rz: x,y=x*math.cos(rz)-y*math.sin(rz),x*math.sin(rz)+y*math.cos(rz)
            return x+cx,y+cy,z+cz
        ids=[self.vert(rot(p)) for p in pts]
        for q in [(0,1,2,3),(5,4,7,6),(4,0,3,7),(1,5,6,2),(3,2,6,7),(4,5,1,0)]: self.quad(*[ids[i] for i in q])
    def prism(self,c,r0,r1,h,sides=12,phase=0,oval=(1,1)):
        cx,cy,cz=c; bot=[]; top=[]
        for i in range(sides):
            a=phase+2*math.pi*i/sides; ca,sa=math.cos(a),math.sin(a)
            bot.append(self.vert((cx+r0*ca*oval[0],cy-h/2,cz+r0*sa*oval[1])))
            top.append(self.vert((cx+r1*ca*oval[0],cy+h/2,cz+r1*sa*oval[1])))
        for i in range(sides):
            j=(i+1)%sides; self.quad(bot[i],bot[j],top[j],top[i])
        self.face(*reversed(bot)); self.face(*top)
    def spike(self,c,r,h,sides=8,tilt=0,az=0):
        cx,cy,cz=c; base=[]
        for i in range(sides):
            a=2*math.pi*i/sides; base.append(self.vert((cx+r*math.cos(a),cy,cz+r*math.sin(a))))
        tip=self.vert((cx+math.cos(az)*math.sin(tilt)*h,cy+math.cos(tilt)*h,cz+math.sin(az)*math.sin(tilt)*h))
        for i in range(sides): self.tri(base[i],base[(i+1)%sides],tip)
        self.face(*reversed(base))
    def dome(self,c,r,h,sides=16,rings=5,open_bottom=False,oval=(1,1)):
        cx,cy,cz=c; rows=[]
        for j in range(rings+1):
            t=(math.pi/2)*(j/rings)
            rr=r*math.cos(t); y=cy+h*math.sin(t)
            row=[]
            for i in range(sides):
                a=2*math.pi*i/sides; row.append(self.vert((cx+rr*math.cos(a)*oval[0],y,cz+rr*math.sin(a)*oval[1])))
            rows.append(row)
        for j in range(rings):
            for i in range(sides):
                k=(i+1)%sides; self.quad(rows[j][i],rows[j][k],rows[j+1][k],rows[j+1][i])
        if not open_bottom: self.face(*reversed(rows[0]))
    def curved_plate(self,w,h,d,curve=0.16,segments=6):
        # front-convex breast/shoulder plate, local origin centered
        rows=[]
        for yj in range(3):
            y=-h/2+h*yj/2
            row=[]
            for i in range(segments+1):
                x=-w/2+w*i/segments
                z=-d/2-curve*(1-(2*x/w)**2)
                row.append(self.vert((x,y,z)))
            rows.append(row)
        for j in range(2):
            for i in range(segments): self.quad(rows[j][i],rows[j][i+1],rows[j+1][i+1],rows[j+1][i])
        # back shell and perimeter thickness
        back=[]
        for idx,p in enumerate(self.v[:len(rows)*len(rows[0])]): back.append(self.vert((p[0],p[1],p[2]+d)))
        n=segments+1
        for j in range(2):
            for i in range(segments):
                a=back[j*n+i]; b=back[j*n+i+1]; c=back[(j+1)*n+i+1]; d2=back[(j+1)*n+i]; self.quad(a,d2,c,b)
        for i in range(segments):
            self.quad(rows[0][i],back[i],back[i+1],rows[0][i+1])
            a=2*n+i; self.quad(rows[2][i],rows[2][i+1],back[a+1],back[a])
        for j in range(2):
            self.quad(rows[j][0],rows[j+1][0],back[(j+1)*n],back[j*n])
            self.quad(rows[j+1][-1],rows[j][-1],back[j*n+n-1],back[(j+1)*n+n-1])
    def arch(self,x,y,z,r,depth=1.3,thick=.45,blocks=13):
        for i in range(blocks):
            a=math.pi*i/(blocks-1); zz=z+r*math.cos(a); yy=y+r*math.sin(a)
            self.box((x,yy,zz),(depth,thick,.55),rx=a-math.pi/2)
    def write(self,path):
        with open(path,'w') as f:
            f.write(f'o {self.name}\ns off\n')
            for x,y,z in self.v: f.write(f'v {x:.6f} {y:.6f} {z:.6f}\n')
            for face in self.f: f.write('f '+' '.join(map(str,reversed(face)))+'\n')

# ---------- bespoke character gear ----------
def human_bronze_helmet():
    o=Obj('human_bronze_helmet'); o.dome((0,0,0),.28,.25,18,6,True,(1.0,.92)); o.prism((0,-.015,0),.29,.29,.075,18)
    o.box((0,-.04,-.255),(.08,.28,.075),taper=(.72,1));
    for x in (-.24,.24): o.box((x,-.10,-.02),(.075,.28,.18),rz=.10*(-1 if x<0 else 1),taper=(1,.75))
    o.write(GEAR/'human_bronze_helmet.obj')
def human_iron_helmet():
    o=Obj('human_iron_helmet'); o.dome((0,0,0),.30,.28,20,7,True,(1.0,.94)); o.prism((0,-.015,0),.31,.30,.085,20)
    o.box((0,-.035,-.275),(.075,.32,.085),taper=(.62,1));
    for x in (-.255,.255): o.box((x,-.11,-.015),(.085,.34,.20),rz=.12*(-1 if x<0 else 1),taper=(1,.72))
    o.box((0,.32,.02),(.07,.34,.34),taper=(1,.45)); o.write(GEAR/'human_iron_helmet.obj')
def pauldron(name,w=.62,h=.34,d=.34,spikes=False):
    o=Obj(name); o.curved_plate(w,h,d,.13,7)
    if spikes:
        for x in (-w*.28,w*.28): o.spike((x,h*.34,-d*.58),.045,.24,7,.33,-math.pi/2)
    o.write(GEAR/f'{name}.obj')
def breast(name,w=.62,h=.64,d=.16,ridge=True):
    o=Obj(name); o.curved_plate(w,h,d,.12,8)
    if ridge: o.box((0,.03,-d*.92),(.065,h*.82,.06),taper=(.78,1))
    o.write(GEAR/f'{name}.obj')
def ogre_helmet(name,scale=1.0,horns=2,iron=False):
    o=Obj(name); o.dome((0,0,0),.33*scale,.26*scale,16,5,True,(1.08,.95)); o.prism((0,-.03*scale,0),.35*scale,.34*scale,.10*scale,14)
    o.box((0,-.09*scale,-.29*scale),(.11*scale,.33*scale,.11*scale),taper=(.72,1))
    for side in (-1,1):
        o.box((.27*side*scale,-.09*scale,-.02*scale),(.11*scale,.30*scale,.22*scale),rz=.14*side,taper=(1,.76))
        o.spike((.26*side*scale,.14*scale,.02),.075*scale,.43*scale,8,.62, math.pi if side<0 else 0)
    if horns>=4:
        for side in (-1,1): o.spike((.17*side*scale,.25*scale,.13*scale),.055*scale,.34*scale,7,.50, (math.pi*.75 if side<0 else math.pi*.25))
    if iron: o.box((0,.19*scale,-.20*scale),(.34*scale,.13*scale,.09*scale),taper=(.75,1))
    o.write(GEAR/f'{name}.obj')
def jaw_guard():
    o=Obj('ogre_captain_jaw'); o.box((0,-.01,-.05),(.54,.18,.18),taper=(.72,1));
    for x in (-.21,.21): o.spike((x,-.04,-.13),.055,.30,8,.70,-math.pi/2)
    o.write(GEAR/'ogre_captain_jaw.obj')
def barding():
    o=Obj('mount_iron_barding'); o.curved_plate(1.08,.48,.30,.15,8)
    for x in (-.43,0,.43): o.box((x,-.20,.07),(.17,.26,.26),rz=.06*(-1 if x<0 else 1))
    o.write(GEAR/'mount_iron_barding.obj')

human_bronze_helmet(); human_iron_helmet();
pauldron('human_bronze_pauldron',.58,.32,.30,False); pauldron('human_iron_pauldron',.66,.38,.34,False); breast('human_iron_breastplate',.66,.68,.18,True)
pauldron('ogre_spiked_pauldron',.72,.42,.42,True); breast('ogre_iron_breastplate',.76,.72,.22,True)
ogre_helmet('ogre_raider_helmet',.92,2,False); ogre_helmet('ogre_bronze_guard_helmet',1.0,2,False); ogre_helmet('ogre_iron_breaker_helmet',1.08,4,True); ogre_helmet('ogre_captain_helmet',1.22,4,True); jaw_guard(); barding()

# ---------- hero fortress gatehouses + keeps ----------
def human_gate(age):
    name=f'human_gatehouse_{age}'; o=Obj(name); ai={'stone':0,'bronze':1,'iron':2}[age]
    tower_h=4.8+ai*.9
    for z in (-3.55,3.55):
        o.box((0,tower_h/2,z),(1.9,tower_h,1.85)); o.box((0,.48,z),(2.25,.96,2.20))
        for y in (1.6,3.2+(ai*.25)):
            o.box((-.98,y,z),(0.12,.76,.22))
    o.arch(0,2.65+ai*.18,0,3.0+ai*.10,1.98,.58,15)
    crown=tower_h+.22
    o.box((0,crown,0),(2.05,.55,8.55))
    n=7+ai*2
    for i in range(n):
        z=-3.55+i*(7.1/(n-1)); o.box((0,crown+.52,z),(2.06,1.02,.54))
    # corbels / murder-hole underside
    if ai>=1:
        for z in (-3.0,-2.0,-1.0,0,1.0,2.0,3.0): o.box((-.33,crown-.42,z),(.54,.42,.30),rx=.08)
    if ai==0:
        # timber hoarding and roof
        o.box((-.62,crown+.08,0),(.50,.42,7.9))
        for z in (-3.2,-2.0,-.8,.8,2.0,3.2): o.box((-.78,crown-.50,z),(.20,1.10,.20),rz=.08*(-1 if z<0 else 1))
    elif ai==2:
        for z in (-4.35,4.35):
            o.prism((0,4.4,z),1.18,1.02,5.0,12,math.pi/12)
            for i in range(6):
                a=2*math.pi*i/6; o.box((.92*math.cos(a),7.10,.92*math.sin(a)+z),(.54,.72,.44),ry=-a)
    o.write(FORT/f'{name}.obj')
def human_keep(age):
    name=f'human_keep_{age}'; o=Obj(name); ai={'stone':0,'bronze':1,'iron':2}[age]
    w=6.1+ai*.45; h=6.2+ai*1.1; d=9.1+ai*.55
    o.box((0,h/2,0),(w,h,d)); o.box((0,.5,0),(w+.65,1.0,d+.65))
    # layered buttresses and window hoods
    for x in (-w/2+.25,w/2-.25):
        for z in (-d/2+.45,d/2-.45): o.box((x,h*.42,z),(.72,h*.78,.72),taper=(1.22,1.22))
    for y in (1.6,h*.47,h*.72): o.box((0,y,0),(w+.22,.18,d+.22))
    for z in (-d*.28,0,d*.28):
        o.box((-w/2-.07,h*.56,z),(.14,.92,.24)); o.box((w/2+.07,h*.56,z),(.14,.92,.24))
    top=h+.12; o.box((0,top,0),(w+.55,.45,d+.55))
    if ai==0:
        # parapet under a compact roof ridge
        for z in (-d*.42,-d*.20,0,d*.20,d*.42): o.box((0,top+.55,z),(w+.5,.78,.58))
    else:
        count=7+ai*2
        for i in range(count):
            z=-d*.43+i*(d*.86/(count-1)); o.box((-w*.44,top+.60,z),(.72,1.02,.58)); o.box((w*.44,top+.60,z),(.72,1.02,.58))
        if ai==2:
            for x in (-w*.35,w*.35):
                for z in (-d*.35,d*.35):
                    o.prism((x,top+1.65,z),.72,.64,2.9,10,math.pi/10)
                    o.spike((x,top+3.1,z),.16,1.0,8,.08)
    o.write(FORT/f'{name}.obj')
def ogre_gate(age):
    name=f'ogre_gatehouse_{age}'; o=Obj(name); ai={'stone':0,'bronze':1,'iron':2}[age]
    h=6.2+ai*.85
    for z,rz in ((-3.7,.10),(3.45,-.14)):
        o.box((0,h/2,z),(2.30+ai*.12,h,2.0),rz=rz,taper=(1.20,1.10)); o.box((-.18,.62,z),(2.75,1.24,2.45),rz=rz)
        for y in (1.8,3.6+ai*.25): o.box((1.12,y,z),(.22,1.0,.42),rz=rz)
        o.spike((-.20,h-.25,z),.38+ai*.04,2.25+ai*.30,9,.46*(-1 if z<0 else 1))
    o.box((0,h-.30,-.10),(2.55,1.18,8.85),rz=.035)
    # jaw-like hanging fangs over gate opening
    n=5+ai*2
    for i in range(n):
        z=-3.0+i*(6.0/(n-1)); o.spike((.73,h-.78,z),.17+ai*.02,1.35+ai*.18,8,.40)
    if ai>=1:
        for z in (-3.9,-2.25,0,2.15,3.95): o.box((-.58,h*.52,z),(.52,h*.63,.74),rz=.06*(-1 if z<0 else 1),taper=(1.18,1.0))
    if ai==2:
        # black-iron crown teeth
        for z in (-4.05,-3.0,-1.95,-.9,.2,1.3,2.4,3.5):
            o.box((-.15,h+.35,z),(.95,.78,.62),rz=.05*(-1 if z<0 else 1)); o.spike((-.22,h+.72,z),.16,1.1,7,.15)
    o.write(FORT/f'{name}.obj')
def ogre_keep(age):
    name=f'ogre_keep_{age}'; o=Obj(name); ai={'stone':0,'bronze':1,'iron':2}[age]
    sides=9 if ai<2 else 10; h=8.3+ai*1.05; r=4.8+ai*.28
    o.prism((0,h/2,0),r,r*.82,h,sides,.18)
    # asymmetrical buttresses
    for j,(a,lean) in enumerate(((0,.08),(1.35,-.06),(2.85,.10),(4.4,-.09),(5.55,.06))):
        x=math.cos(a)*(r*.88); z=math.sin(a)*(r*.88)
        o.box((x,h*.40,z),(.90,h*.72,1.28),ry=-a,rz=lean,taper=(1.28,1.15))
    crown=h+.22; o.prism((-.20,crown,0),r*.92,r*.84,.85,sides,.18)
    n=8+ai*2
    for i in range(n):
        a=2*math.pi*i/n+.08; x=math.cos(a)*r*.80; z=math.sin(a)*r*.80
        o.spike((x,crown+.22,z),.22+ai*.02,1.65+ai*.23,8,.14,a)
    # burning slit frames / trophy sockets
    for z in (-3.1,-1.05,1.10,3.20): o.box((r*.73,h*.55,z),(.44,1.18,.62),ry=-.06,rz=.05*(-1 if z<0 else 1))
    if ai==2:
        for z in (-3.65,3.65):
            o.prism((-.9,h+2.0,z),1.28,.94,4.2,8,.16); o.spike((-.9,h+4.15,z),.24,1.45,8,.20)
        o.box((0,h+1.18,0),(8.8,.72,11.2),rz=.02)
    o.write(FORT/f'{name}.obj')

for age in ('stone','bronze','iron'):
    human_gate(age); human_keep(age); ogre_gate(age); ogre_keep(age)

# ---------- authored battlefield props ----------
def prop_broken_cart():
    o=Obj('broken_cart_wood'); o.box((0,.45,0),(2.4,.22,1.35));
    for x,z in ((-.85,-.58),(.85,.58)): o.prism((x,.28,z),.48,.48,.20,14,math.pi/14,oval=(1,1));
    o.box((-1.0,.84,0),(.16,.82,1.08),rz=.08); o.box((.92,.75,-.08),(.14,.62,.92),rz=-.12); o.box((1.55,.34,.12),(1.30,.12,.12),rz=-.25)
    o.write(PROPS/'broken_cart_wood.obj')
def prop_barricade():
    o=Obj('spike_barricade');
    for z in (-.72,0,.72):
        o.box((0,.34,z),(2.8,.22,.20),rz=.02*(-1 if z<0 else 1))
        for x in (-1.05,-.35,.35,1.05): o.spike((x,.42,z),.11,1.45,7,.52,0 if x>=0 else math.pi)
    for x in (-1.15,1.15): o.box((x,.55,0),(.18,1.1,1.8),rz=.12*(-1 if x<0 else 1))
    o.write(PROPS/'spike_barricade.obj')
def prop_weapon_pile():
    o=Obj('weapon_pile_iron');
    for i,(x,z,a) in enumerate(((-.45,-.2,.45),(.2,.0,-.35),(.50,.25,.72),(-.15,.35,-.75))):
        o.box((x,.18,z),(.08,1.65,.08),rz=a); o.box((x+.08*math.cos(a),.95,z),(.54,.08,.10),rz=a)
    o.prism((-.28,.17,.26),.32,.32,.12,14,math.pi/14,oval=(1.15,1)); o.write(PROPS/'weapon_pile_iron.obj')
def prop_palisade():
    o=Obj('ruined_palisade');
    for i,x in enumerate((-1.25,-.82,-.38,.08,.55,1.03,1.42)):
        h=1.55+(i%3)*.27; o.box((x,h/2,0),(.27,h,.30),rz=.06*((i%3)-1)); o.spike((x,h-.03,0),.13,.46,7,.08)
    o.box((.05,.68,.06),(3.0,.18,.18),rz=.04); o.write(PROPS/'ruined_palisade.obj')
def prop_boulders():
    o=Obj('boulder_cluster');
    for c,r,h,s in (((-.45,.30,0),.55,.70,9),((.35,.20,.18),.42,.54,8),((.18,.18,-.35),.32,.43,7)):
        o.prism(c,r*.95,r*.78,h,s,.17,oval=(1.25,.9))
    o.write(PROPS/'boulder_cluster.obj')
def prop_shield_stack():
    o=Obj('shield_stack');
    for i,(x,y,z,rz) in enumerate(((-.32,.34,0,.22),(.28,.30,.12,-.18),(.02,.22,-.30,.62))):
        o.prism((x,y,z),.38,.34,.10,16,math.pi/16,oval=(1,1.08)); o.box((x,y,z-.07),(.10,.10,.08),rz=rz)
    o.write(PROPS/'shield_stack.obj')

prop_broken_cart(); prop_barricade(); prop_weapon_pile(); prop_palisade(); prop_boulders(); prop_shield_stack()

# report
for folder,label in ((GEAR,'gear'),(PROPS,'props')):
    tv=tf=0
    for p in sorted(folder.glob('*.obj')):
        v=f=0
        for line in p.read_text().splitlines():
            if line.startswith('v '): v+=1
            elif line.startswith('f '): f+=1
        tv+=v; tf+=f; print(label,p.name,v,f)
    print(label,'TOTAL',tv,tf)
