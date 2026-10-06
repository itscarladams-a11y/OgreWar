from pathlib import Path
import math

OUT=Path('/mnt/data/ogre_phase5/assets/ogre_modern/fortress_modules')
OUT.mkdir(parents=True, exist_ok=True)

class Obj:
    def __init__(self,name): self.name=name; self.v=[]; self.f=[]
    def vert(self,p): self.v.append(tuple(p)); return len(self.v)
    def quad(self,a,b,c,d): self.f.append((a,b,c,d))
    def tri(self,a,b,c): self.f.append((a,b,c))
    def box(self,c,s,rx=0,ry=0,rz=0):
        cx,cy,cz=c; sx,sy,sz=[x/2 for x in s]
        pts=[(-sx,-sy,-sz),(sx,-sy,-sz),(sx,sy,-sz),(-sx,sy,-sz),(-sx,-sy,sz),(sx,-sy,sz),(sx,sy,sz),(-sx,sy,sz)]
        def rot(p):
            x,y,z=p
            if rx: y,z=y*math.cos(rx)-z*math.sin(rx),y*math.sin(rx)+z*math.cos(rx)
            if ry: x,z=x*math.cos(ry)+z*math.sin(ry),-x*math.sin(ry)+z*math.cos(ry)
            if rz: x,y=x*math.cos(rz)-y*math.sin(rz),x*math.sin(rz)+y*math.cos(rz)
            return (x+cx,y+cy,z+cz)
        ids=[self.vert(rot(p)) for p in pts]
        for q in [(0,1,2,3),(5,4,7,6),(4,0,3,7),(1,5,6,2),(3,2,6,7),(4,5,1,0)]: self.quad(*[ids[i] for i in q])
    def prism(self,c,r0,r1,h,sides=10,phase=0):
        cx,cy,cz=c; bot=[]; top=[]
        for i in range(sides):
            a=phase+2*math.pi*i/sides
            bot.append(self.vert((cx+r0*math.cos(a),cy-h/2,cz+r0*math.sin(a))))
            top.append(self.vert((cx+r1*math.cos(a),cy+h/2,cz+r1*math.sin(a))))
        for i in range(sides):
            j=(i+1)%sides; self.quad(bot[i],bot[j],top[j],top[i])
        self.f.append(tuple(reversed(bot))); self.f.append(tuple(top))
    def spike(self,c,r,h,sides=7,tilt=0,az=0):
        cx,cy,cz=c; base=[]
        for i in range(sides):
            a=2*math.pi*i/sides; base.append(self.vert((cx+r*math.cos(a),cy,cz+r*math.sin(a))))
        tip=self.vert((cx+math.cos(az)*math.sin(tilt)*h,cy+math.cos(tilt)*h,cz+math.sin(az)*math.sin(tilt)*h))
        for i in range(sides): self.tri(base[i],base[(i+1)%sides],tip)
        self.f.append(tuple(reversed(base)))
    def wedge_roof(self,c,w,d,h):
        cx,cy,cz=c; x=w/2; z=d/2
        ids=[self.vert((cx-x,cy,cz-z)),self.vert((cx+x,cy,cz-z)),self.vert((cx+x,cy,cz+z)),self.vert((cx-x,cy,cz+z)),self.vert((cx-x,cy+h,cz)),self.vert((cx+x,cy+h,cz))]
        for face in [(0,1,5,4),(3,4,5,2),(0,4,3),(1,2,5),(0,3,2,1)]: self.f.append(tuple(ids[i] for i in face))
    def arch_blocks(self,x,y,z,r,blocks=11,depth=1.7,thick=.62):
        for i in range(blocks):
            a=math.pi*i/(blocks-1)
            zz=z+r*math.cos(a); yy=y+r*math.sin(a)
            self.box((x,yy,zz),(depth,thick,.74),rx=a-math.pi/2)
    def write(self,path):
        with open(path,'w') as f:
            f.write(f'o {self.name}\ns off\n')
            for x,y,z in self.v: f.write(f'v {x:.5f} {y:.5f} {z:.5f}\n')
            for face in self.f: f.write('f '+' '.join(map(str,reversed(face)))+'\n')

def masonry_wall(name, age):
    o=Obj(name)
    if age==0:
        # low stone footing + timber palisade and walk
        for col in range(-5,6):
            z=col*.88; o.box((0,.38,z),(1.25,.72,.82),rz=.018*(-1 if col%2 else 1))
        o.box((0,1.02,0),(1.35,.22,9.5))
        for col in range(-10,11):
            z=col*.46; h=2.45+(col%3)*.10
            o.box((0,h/2+.9,z),(.30,h,.24),rz=.025*(-1 if col%2 else 1))
            if col%2==0: o.spike((0,h+2.10,z),.12,.55,6,.05)
        o.box((-.18,2.45,0),(.42,.26,9.2))
    else:
        rows=5 if age==1 else 6
        for row in range(rows):
            y=.42+row*.72; off=.48 if row%2 else 0
            for col in range(-5,6):
                z=col*.96+off
                if abs(z)>4.75: continue
                o.box((0,y,z),(1.22,.66,.88),rz=.010*((col+row)%3-1))
        topy=.42+(rows-1)*.72+.58
        o.box((0,topy,0),(1.34,.22,9.9))
        if age==1:
            for z in [-4.35,-3.15,-1.95,-.75,.75,1.95,3.15,4.35]: o.box((0,topy+.48,z),(1.38,.86,.62))
            for z in [-3.65,0,3.65]: o.box((-.12,1.65,z),(.24,2.7,.52))
        else:
            # machicolated lip + taller merlons
            for z in [-4.45,-3.55,-2.65,-1.75,-.85,.85,1.75,2.65,3.55,4.45]:
                o.box((-.12,topy+.20,z),(1.62,.36,.34))
            for z in [-4.25,-3.0,-1.75,-.5,.5,1.75,3.0,4.25]: o.box((0,topy+.75,z),(1.42,1.12,.66))
            for z in [-3.65,0,3.65]:
                o.box((-.18,1.95,z),(.38,3.8,.66)); o.box((-.24,.55,z),(.64,1.1,.98))
    return o

def human_tower(name, age):
    o=Obj(name)
    if age==0:
        o.box((0,2.35,0),(3.8,4.7,3.8)); o.box((0,.40,0),(4.25,.8,4.25)); o.wedge_roof((0,4.75,0),4.4,4.4,1.8)
        for x,z in [(-1.65,-1.65),(1.65,-1.65),(-1.65,1.65),(1.65,1.65)]: o.box((x,2.35,z),(.34,4.7,.34))
        for z in [-.9,0,.9]: o.box((-1.92,2.4,z),(.18,.75,.18))
    elif age==1:
        o.prism((0,2.75,0),2.22,2.0,5.5,10,math.pi/10); o.prism((0,.38,0),2.48,2.3,.76,10,math.pi/10)
        o.prism((0,5.58,0),2.35,2.35,.38,10,math.pi/10)
        for i in range(10):
            if i%2==0:
                a=2*math.pi*i/10; o.box((1.98*math.cos(a),6.05,1.98*math.sin(a)),(.76,.90,.62),ry=-a)
        for a in [0,math.pi/2,math.pi,3*math.pi/2]: o.box((2.02*math.cos(a),1.25,2.02*math.sin(a)),(.72,2.3,1.05),ry=-a)
    else:
        o.prism((0,3.25,0),2.42,2.12,6.5,14,math.pi/14); o.prism((0,.42,0),2.70,2.5,.84,14,math.pi/14)
        o.prism((0,6.60,0),2.48,2.48,.46,14,math.pi/14)
        for i in range(14):
            if i%2==0:
                a=2*math.pi*i/14; o.box((2.12*math.cos(a),7.14,2.12*math.sin(a)),(.72,1.04,.60),ry=-a)
        # buttresses + slit hoods
        for a in [0,math.pi/2,math.pi,3*math.pi/2]:
            o.box((2.18*math.cos(a),1.55,2.18*math.sin(a)),(.78,2.9,1.12),ry=-a)
        for a in [0,math.pi/2,math.pi,3*math.pi/2]:
            o.box((2.13*math.cos(a),3.75,2.13*math.sin(a)),(.22,1.08,.34),ry=-a)
    return o

def human_gate(name, age):
    o=Obj(name)
    if age==0:
        for z in [-3.4,3.4]: o.box((0,2.15,z),(1.55,4.3,1.4)); o.box((0,4.35,0),(1.7,.55,7.8)); o.wedge_roof((0,4.65,0),2.0,8.2,1.35)
        for z in [-2.8,-1.8,-.9,0,.9,1.8,2.8]: o.box((-.18,1.8,z),(.24,3.35,.18))
    else:
        for z in [-3.65,3.65]:
            o.box((0,2.6,z),(1.85,5.2,1.5)); o.box((-.1,.55,z),(2.1,1.1,1.8))
        o.arch_blocks(0,2.8,0,3.1,11,1.92,.68)
        crown=6.0 if age==1 else 6.55
        o.box((0,crown,0),(2.0,.60,8.35))
        step=1.1 if age==1 else .92
        z=-3.6
        while z<=3.61:
            o.box((0,crown+.56,z),(2.0,1.0,.56)); z+=step
        if age==2:
            for z in [-3.15,-2.25,-1.35,-.45,.45,1.35,2.25,3.15]: o.box((-.18,crown-.38,z),(2.28,.42,.30))
            # side watch turrets
            for z in [-4.25,4.25]: o.prism((0,4.0,z),1.15,1.02,4.8,10,math.pi/10)
    return o

def human_keep(name, age):
    o=Obj(name)
    if age==0:
        o.box((0,2.9,0),(5.8,5.8,8.7)); o.box((0,.45,0),(6.2,.9,9.1)); o.wedge_roof((0,5.75,0),6.3,9.3,2.1)
        for z in [-3.8,0,3.8]: o.box((2.92,3.0,z),(.28,4.9,.48))
    elif age==1:
        o.box((0,3.6,0),(6.3,7.2,9.4)); o.box((0,.48,0),(6.8,.96,9.9))
        for y in [1.25,3.1,5.2]: o.box((0,y,0),(6.55,.20,9.65))
        for x in [-2.95,2.95]:
            for z in [-4.45,4.45]: o.box((x,2.7,z),(.76,5.4,.76))
        o.wedge_roof((0,7.2,0),6.8,9.8,1.6)
    else:
        o.box((0,4.25,0),(6.8,8.5,10.0)); o.box((0,.50,0),(7.3,1.0,10.5))
        for y in [1.35,3.15,5.2,7.1]: o.box((0,y,0),(7.05,.22,10.25))
        for x in [-3.15,3.15]:
            for z in [-4.75,4.75]: o.box((x,3.2,z),(.86,6.4,.86))
        o.box((0,8.72,0),(7.35,.44,10.6))
        for z in [-4.75,-3.2,-1.6,0,1.6,3.2,4.75]: o.box((0,9.30,z),(7.4,.86,.66))
        for x in [-2.95,2.95]:
            for z in [-4.4,4.4]: o.prism((x,9.5,z),.78,.70,2.2,8,math.pi/8)
    return o

def ogre_wall(name, age):
    o=Obj(name); count=7+age
    for i in range(count):
        z=-4.3+i*(8.6/(count-1)); y=1.05+(i%3)*.18+age*.16; h=1.9+(i%4)*.42+age*.35; w=1.30+(i%2)*.28
        o.box((0,y,z),(1.55+age*.12,h,w),rx=.04*(i%3-1),rz=.055*(-1 if i%2 else 1))
    o.box((0,3.25+age*.48,0),(1.70+age*.12,.62,9.5),rz=.03)
    spikes=6+age*2
    for i in range(spikes):
        z=-4.2+i*(8.4/(spikes-1)); o.spike((-.08,3.52+age*.5+(i%2)*.18,z),.17+age*.025,1.05+age*.25,7,.14*(-1 if z<0 else 1))
    if age>=1:
        for z in [-3.4,-1.15,1.4,3.55]: o.box((-.18,1.95,z),(.40,2.5+age*.55,1.02),rz=.07*(-1 if z<0 else 1))
    return o

def ogre_tower(name, age):
    o=Obj(name); sides=7 if age<2 else 8
    o.prism((0,3.0+age*.35,0),2.48+age*.16,1.78+age*.08,6.0+age*.7,sides,.16)
    o.prism((.18,5.78+age*.68,-.12),2.05+age*.20,2.42+age*.18,.68+age*.10,sides,.16)
    for z,rz in [(-1.5,.48),(1.55,-.44),(.2,.18)]: o.box((-.95,3.1+age*.28,z),(.34,4.8+age*.6,.34),rz=rz)
    n=7+age*2
    for i in range(n):
        a=2*math.pi*i/n+.16; o.spike((1.9*math.cos(a),6.12+age*.78,1.9*math.sin(a)),.18+age*.025,1.30+age*.22,7,.14, a)
    if age==2:
        for a in [0,math.pi/2,math.pi,3*math.pi/2]: o.box((2.2*math.cos(a),3.3,2.2*math.sin(a)),(.72,4.8,1.05),ry=-a,rz=.05)
    return o

def ogre_gate(name, age):
    o=Obj(name)
    for z,rz in [(-3.55,.10),(3.35,-.14)]:
        o.box((0,3.0+age*.32,z),(2.08+age*.14,6.0+age*.64,1.85),rz=rz)
        o.spike((-.15,5.7+age*.62,z*.97),.35+age*.03,2.35+age*.32,8,.40*(-1 if z<0 else 1))
    o.box((0,5.85+age*.64,-.1),(2.20+age*.12,1.05+age*.08,8.45),rz=.035)
    fang_count=5+age*2
    for i in range(fang_count):
        z=-2.9+i*(5.8/(fang_count-1)); o.spike((.62,5.25+age*.60,z),.16+age*.02,1.22+age*.20,7,.42)
    if age>=1:
        for z in [-3.8,-2.0,0,2.1,3.9]: o.box((-.35,3.5+age*.25,z),(.46,4.6+age*.45,.65),rz=.05*(-1 if z<0 else 1))
    return o

def ogre_keep(name, age):
    o=Obj(name); sides=8 if age<2 else 9
    o.prism((0,3.9+age*.42,0),5.0+age*.28,4.15+age*.18,7.8+age*.85,sides,.18)
    o.prism((-.3,7.45+age*.82,.25),4.32+age*.22,3.72+age*.18,1.85+age*.22,sides,.18)
    n=8+age*2
    for i in range(n):
        a=2*math.pi*i/n+.08; o.spike((3.65*math.cos(a),8.45+age*.92+(i%2)*.22,3.65*math.sin(a)),.22+age*.02,1.55+age*.22,7,.12,a)
    for z in [-3.35,-1.15,1.25,3.5]: o.box((3.9+age*.12,3.65+age*.3,z),(.60,5.5+age*.6,1.15),rz=.07*(-1 if z<0 else 1))
    if age==2:
        # giant iron-age crown towers
        for z in [-3.65,3.65]: o.prism((-.8,10.1,z),1.20,.90,4.0,7,.16)
        o.box((0,10.6,0),(8.6,.65,10.9),rz=.02)
    return o

ages=['stone','bronze','iron']
makers=[('human_wall',masonry_wall),('human_tower',human_tower),('human_gatehouse',human_gate),('human_keep',human_keep),('ogre_wall',ogre_wall),('ogre_tower',ogre_tower),('ogre_gatehouse',ogre_gate),('ogre_keep',ogre_keep)]
summary=[]
for age_i,age in enumerate(ages):
    for base,fn in makers:
        name=f'{base}_{age}'
        obj=fn(name,age_i); obj.write(OUT/f'{name}.obj'); summary.append((name,len(obj.v),len(obj.f)))
for row in summary: print(*row)
print('TOTAL',sum(v for _,v,_ in summary),sum(f for _,_,f in summary))
