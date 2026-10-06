from pathlib import Path
import math

ROOT = Path(__file__).resolve().parents[1]
PROPS = ROOT/'assets'/'ogre_modern'/'phase7'/'props'
DAMAGE = ROOT/'assets'/'ogre_modern'/'phase7'/'damage'
PROPS.mkdir(parents=True, exist_ok=True)
DAMAGE.mkdir(parents=True, exist_ok=True)

class Obj:
    def __init__(self, name):
        self.name=name; self.v=[]; self.f=[]
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
            return (x+cx,y+cy,z+cz)
        ids=[self.vert(rot(p)) for p in pts]
        for q in [(0,1,2,3),(4,7,6,5),(0,4,5,1),(1,5,6,2),(2,6,7,3),(4,0,3,7)]: self.quad(*(ids[i] for i in q))
    def prism(self,c,r,h,sides=10,rx=0.0,ry=0.0,rz=0.0):
        cx,cy,cz=c
        bot=[]; top=[]
        def rot(p):
            x,y,z=p
            if rx: y,z=y*math.cos(rx)-z*math.sin(rx),y*math.sin(rx)+z*math.cos(rx)
            if ry: x,z=x*math.cos(ry)+z*math.sin(ry),-x*math.sin(ry)+z*math.cos(ry)
            if rz: x,y=x*math.cos(rz)-y*math.sin(rz),x*math.sin(rz)+y*math.cos(rz)
            return (x+cx,y+cy,z+cz)
        for i in range(sides):
            a=2*math.pi*i/sides
            bot.append(self.vert(rot((math.cos(a)*r,-h/2,math.sin(a)*r))))
            top.append(self.vert(rot((math.cos(a)*r,h/2,math.sin(a)*r))))
        self.face(*reversed(bot)); self.face(*top)
        for i in range(sides): self.quad(bot[i],bot[(i+1)%sides],top[(i+1)%sides],top[i])
    def wedge(self,c,s,tilt=0.0):
        cx,cy,cz=c; sx,sy,sz=[x/2 for x in s]
        pts=[(-sx,-sy,-sz),(sx,-sy,-sz),(sx,-sy,sz),(-sx,-sy,sz),(-sx,sy,-sz),(sx,sy*0.55,-sz),(sx,sy*0.55,sz),(-sx,sy,sz)]
        if tilt:
            ct,st=math.cos(tilt),math.sin(tilt); pts=[(x, y*ct-z*st, y*st+z*ct) for x,y,z in pts]
        ids=[self.vert((x+cx,y+cy,z+cz)) for x,y,z in pts]
        for q in [(0,1,2,3),(4,7,6,5),(0,4,5,1),(1,5,6,2),(2,6,7,3),(3,7,4,0)]: self.quad(*(ids[i] for i in q))
    def write(self,path):
        lines=[f'o {self.name}']
        lines += [f'v {x:.6f} {y:.6f} {z:.6f}' for x,y,z in self.v]
        lines += ['f '+' '.join(map(str,f)) for f in self.f]
        path.write_text('\n'.join(lines)+'\n')


def fallen_banner():
    o=Obj('fallen_banner')
    o.prism((0.0,0.16,0),0.055,3.5,8,rz=math.radians(82))
    # folded cloth in three overlapping pieces
    for i,(c,s,rz) in enumerate([((0.25,0.10,0.20),(1.65,0.07,0.72),0.10),((0.62,0.075,0.44),(1.12,0.06,0.62),-0.07),((-0.32,0.07,-0.24),(0.78,0.05,0.48),0.18)]):
        o.box(c,s,rz=rz)
    o.write(PROPS/'fallen_banner.obj')

def supply_crates():
    o=Obj('supply_crates')
    for c,s,r in [((-0.55,0.37,0.1),(0.9,0.72,0.82),0.06),((0.42,0.31,-0.18),(0.75,0.60,0.70),-0.08),((0.18,0.80,0.12),(0.62,0.55,0.60),0.12)]:
        o.box(c,s,ry=r)
        # board straps
        o.box((c[0],c[1]+s[1]*0.08,c[2]-s[2]*0.48),(s[0]*0.92,0.10,0.07),ry=r)
        o.box((c[0]-s[0]*0.48,c[1],c[2]),(0.07,s[1]*0.90,s[2]*0.90),ry=r)
    o.write(PROPS/'supply_crates.obj')

def stump_cluster():
    o=Obj('stump_cluster')
    o.prism((-0.38,0.38,0.02),0.36,0.76,9,rz=0.03)
    o.prism((0.46,0.26,0.18),0.24,0.52,8,rz=-0.08)
    for c,r,h,rz in [((-0.12,0.10,-0.42),0.08,1.15,1.18),((0.15,0.09,0.46),0.07,0.94,-1.08),((-0.65,0.11,0.35),0.06,0.82,-0.72)]:
        o.prism(c,r,h,7,rz=rz)
    o.write(PROPS/'stump_cluster.obj')

def ruined_watchpost():
    o=Obj('ruined_watchpost')
    for x,z,h,lean in [(-0.75,-0.55,2.5,0.08),(0.72,-0.5,2.1,-0.06),(-0.68,0.54,1.65,0.16),(0.70,0.55,2.32,-0.10)]:
        o.box((x,h/2,z),(0.16,h,0.16),rz=lean)
    o.box((0,1.58,0),(1.8,0.16,1.55),rx=0.05,rz=-0.08)
    o.box((-0.35,2.15,-0.05),(1.20,0.14,1.25),rx=-0.12,rz=0.16)
    o.box((0.55,1.98,0.15),(0.74,0.12,1.05),rx=0.10,rz=-0.24)
    for x in (-0.45,0.0,0.45): o.box((x,1.28,-0.68),(0.10,0.75,0.10),rz=(x*0.15))
    o.write(PROPS/'ruined_watchpost.obj')

def abandoned_wheel():
    o=Obj('abandoned_wheel')
    # tire via 12 blocks around ring
    r=0.72
    for i in range(12):
        a=2*math.pi*i/12
        o.box((math.cos(a)*r,0.76+math.sin(a)*r,0),(0.28,0.14,0.22),rz=a+math.pi/2)
    o.prism((0,0.76,0),0.16,0.30,10,rx=math.pi/2)
    for i in range(8):
        a=2*math.pi*i/8
        o.box((math.cos(a)*r*0.36,0.76+math.sin(a)*r*0.36,0),(r*0.70,0.065,0.08),rz=a)
    o.box((1.18,0.24,0.08),(1.55,0.15,0.15),rz=-0.32)
    o.write(PROPS/'abandoned_wheel.obj')

def camp_bundle():
    o=Obj('camp_bundle')
    o.prism((-0.45,0.27,0.05),0.24,1.25,10,rz=math.pi/2)
    o.prism((0.20,0.24,-0.05),0.21,1.05,9,rz=math.pi/2+0.12)
    o.box((0.50,0.28,0.28),(0.64,0.46,0.42),rz=-0.12,taper=(0.82,0.88))
    o.box((-0.12,0.50,0.42),(0.88,0.18,0.52),rz=0.08,taper=(0.74,0.80))
    o.write(PROPS/'camp_bundle.obj')

def rubble_field():
    o=Obj('rubble_field')
    pieces=[(-0.85,0.17,-0.22,0.46,0.28,0.40,0.18),( -0.38,0.22,0.42,0.58,0.36,0.42,-0.10),(0.10,0.16,-0.45,0.42,0.26,0.34,0.12),(0.48,0.26,0.16,0.66,0.42,0.50,-0.16),(0.92,0.15,-0.28,0.36,0.24,0.38,0.24),(-0.05,0.36,0.06,0.52,0.58,0.46,-0.06)]
    for x,y,z,sx,sy,sz,r in pieces: o.wedge((x,y,z),(sx,sy,sz),r)
    o.write(PROPS/'rubble_field.obj')

def weapon_rack():
    o=Obj('weapon_rack')
    o.box((-0.72,0.86,0),(0.14,1.72,0.16),rz=0.06)
    o.box((0.72,0.86,0),(0.14,1.72,0.16),rz=-0.06)
    o.box((0,1.22,0),(1.54,0.12,0.14))
    o.box((0,0.44,0),(1.54,0.12,0.14))
    for i,x in enumerate((-0.52,-0.18,0.18,0.52)):
        o.prism((x,1.08,0.10),0.035,1.86,6,rz=(0.08 if i%2 else -0.08))
        o.wedge((x,1.98,0.10),(0.24,0.30,0.07),0.0)
    o.write(PROPS/'weapon_rack.obj')


def timber_splinters():
    o=Obj('timber_splinters')
    for i,(x,z,h,r) in enumerate([(-0.72,-0.15,1.45,-0.62),(-0.32,0.24,1.10,0.48),(0.08,-0.30,1.70,-0.28),(0.42,0.18,1.28,0.72),(0.78,-0.05,0.92,-0.84)]):
        o.wedge((x,h*0.32,z),(0.16,h,0.18),r)
    o.write(DAMAGE/'timber_splinters.obj')

def stone_rubble(name,scale=1.0,count=8):
    o=Obj(name)
    for i in range(count):
        a=2*math.pi*i/count; rad=(0.42+0.11*(i%3))*scale
        x=math.cos(a)*rad; z=math.sin(a)*rad
        sx=(0.34+0.07*(i%4))*scale; sy=(0.24+0.08*((i+1)%3))*scale; sz=(0.30+0.06*((i+2)%4))*scale
        o.wedge((x,sy*0.45,z),(sx,sy,sz),(i%5-2)*0.08)
    o.write(DAMAGE/f'{name}.obj')

def bent_iron():
    o=Obj('bent_iron')
    for i,x in enumerate((-0.72,-0.35,0.04,0.42,0.76)):
        o.box((x,0.72,0),(0.10,1.45,0.12),rz=(-0.18+0.09*i))
    o.box((0,0.30,0.03),(1.65,0.12,0.13),rz=0.12)
    o.box((0,1.12,-0.02),(1.58,0.11,0.12),rz=-0.10)
    o.write(DAMAGE/'bent_iron.obj')

def gate_shards():
    o=Obj('gate_shards')
    for i,(x,z,h,w,r) in enumerate([(-0.86,-0.22,1.05,0.20,-0.72),(-0.52,0.35,1.55,0.18,0.52),(-0.12,-0.30,0.86,0.22,-0.28),(0.28,0.22,1.42,0.19,0.78),(0.68,-0.12,1.18,0.16,-0.62),(0.92,0.36,0.72,0.22,0.34)]):
        o.wedge((x,h*0.25,z),(w,h,0.16),r)
    o.write(DAMAGE/'gate_shards.obj')

def keep_debris():
    o=Obj('keep_debris')
    for i in range(10):
        a=2*math.pi*i/10; rad=0.72+0.12*(i%3)
        x,z=math.cos(a)*rad,math.sin(a)*rad
        sx=0.42+0.08*(i%4); sy=0.26+0.10*((i+2)%3); sz=0.40+0.06*((i+1)%4)
        o.wedge((x,sy*0.45,z),(sx,sy,sz),(i%5-2)*0.09)
    for x in (-0.58,0.52): o.box((x,0.66,0.04),(0.18,1.25,0.20),rz=(0.52 if x<0 else -0.46))
    o.write(DAMAGE/'keep_debris.obj')

for fn in [fallen_banner,supply_crates,stump_cluster,ruined_watchpost,abandoned_wheel,camp_bundle,rubble_field,weapon_rack,timber_splinters,bent_iron,gate_shards,keep_debris]: fn()
stone_rubble('stone_rubble_small',0.78,7)
stone_rubble('stone_rubble_large',1.22,10)
print('Generated Phase 7 authored environment and fortress-damage meshes.')
