from pathlib import Path
import math

OUT=Path('/mnt/data/ogre_modern/assets/ogre_modern/fortress_modules')
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
            if rx:
                y,z=y*math.cos(rx)-z*math.sin(rx),y*math.sin(rx)+z*math.cos(rx)
            if ry:
                x,z=x*math.cos(ry)+z*math.sin(ry),-x*math.sin(ry)+z*math.cos(ry)
            if rz:
                x,y=x*math.cos(rz)-y*math.sin(rz),x*math.sin(rz)+y*math.cos(rz)
            return (x+cx,y+cy,z+cz)
        ids=[self.vert(rot(p)) for p in pts]
        for q in [(0,1,2,3),(5,4,7,6),(4,0,3,7),(1,5,6,2),(3,2,6,7),(4,5,1,0)]: self.quad(*[ids[i] for i in q])
    def prism(self,c,r0,r1,h,sides=8,phase=0):
        cx,cy,cz=c; bot=[]; top=[]
        for i in range(sides):
            a=phase+2*math.pi*i/sides
            bot.append(self.vert((cx+r0*math.cos(a),cy-h/2,cz+r0*math.sin(a))))
            top.append(self.vert((cx+r1*math.cos(a),cy+h/2,cz+r1*math.sin(a))))
        for i in range(sides):
            j=(i+1)%sides; self.quad(bot[i],bot[j],top[j],top[i])
        self.f.append(tuple(reversed(bot))); self.f.append(tuple(top))
    def spike(self,c,r,h,sides=7,tilt=0):
        cx,cy,cz=c; base=[]
        for i in range(sides):
            a=2*math.pi*i/sides; base.append(self.vert((cx+r*math.cos(a),cy,cz+r*math.sin(a))))
        tip=self.vert((cx+math.sin(tilt)*h,cy+math.cos(tilt)*h,cz))
        for i in range(sides): self.tri(base[i],base[(i+1)%sides],tip)
        self.f.append(tuple(reversed(base)))
    def write(self,path):
        with open(path,'w') as f:
            f.write(f'o {self.name}\ns off\n')
            for x,y,z in self.v: f.write(f'v {x:.5f} {y:.5f} {z:.5f}\n')
            for face in self.f: f.write('f '+' '.join(map(str,reversed(face)))+'\n')

def human_wall():
    o=Obj('human_wall')
    # dressed masonry courses with staggered joints
    for row in range(4):
        y=.48+row*.86
        offset=.55 if row%2 else 0
        for col in range(-4,5):
            z=col*1.08+offset
            if abs(z)>4.65: continue
            o.box((0,y,z),(1.15,.78,1.00),rz=(0.012 if (col+row)%2 else -0.012))
    # wall walk and crenels
    o.box((0,3.72,0),(1.28,.24,9.7))
    for z in [-4.35,-3.25,-2.15,-1.05,1.05,2.15,3.25,4.35]: o.box((0,4.16,z),(1.30,.86,.62))
    return o

def human_tower():
    o=Obj('human_tower'); o.prism((0,2.7,0),2.1,1.92,5.4,12,math.pi/12)
    # base plinth and upper crown
    o.prism((0,.35,0),2.35,2.2,.7,12,math.pi/12); o.prism((0,5.55,0),2.18,2.18,.36,12,math.pi/12)
    for i in range(12):
        if i%2==0:
            a=2*math.pi*i/12; o.box((1.82*math.cos(a),6.02,1.82*math.sin(a)),(.75,.78,.62),ry=-a)
    # buttress feet
    for a in [0,math.pi/2,math.pi,3*math.pi/2]:
        o.box((2.0*math.cos(a),1.05,2.0*math.sin(a)),(.72,2.0,1.0),ry=-a,rz=.06*math.sin(a))
    return o

def human_gate():
    o=Obj('human_gatehouse')
    # side piers
    for z in [-3.55,3.55]:
        o.box((0,2.35,z),(1.75,4.7,1.45)); o.box((.12,.45,z),(2.0,.9,1.75))
    # segmented round arch around 2.7m opening
    R=3.15
    for i in range(9):
        a=math.pi*i/8
        z=R*math.cos(a); y=2.7+R*math.sin(a)
        o.box((-.06,y,z),(1.92,.62,.88),rx=a-math.pi/2)
    # crown and murder-hole deck
    o.box((0,6.05,0),(1.9,.6,8.0))
    for z in [-3.35,-2.25,-1.15,0,1.15,2.25,3.35]: o.box((0,6.62,z),(1.92,.86,.58))
    return o

def human_keep():
    o=Obj('human_keep')
    o.box((0,3.5,0),(5.4,7.0,8.7))
    # corner buttresses and string courses
    for z in [-4.15,4.15]:
        for x in [-2.55,2.55]: o.box((x,2.3,z),(.7,4.6,.7))
    for y in [1.25,3.2,5.15]: o.box((0,y,0),(5.62,.18,8.92))
    for z in [-3.8,-1.9,0,1.9,3.8]: o.box((2.78,7.45,z),(.62,.9,.62))
    return o

def ogre_wall():
    o=Obj('ogre_wall')
    # giant irregular slabs
    blocks=[(-3.9,1.0,1.45,1.9),(-2.6,1.5,1.25,2.8),(-1.3,1.2,1.55,2.2),(0,1.6,1.2,3.0),(1.45,1.05,1.6,2.0),(2.8,1.45,1.3,2.7),(4.15,1.15,1.45,2.2)]
    for i,(z,y,w,h) in enumerate(blocks): o.box((0,y,z),(1.5,h,w),rx=.05*(i%3-1),rz=.04*(-1 if i%2 else 1))
    o.box((0,3.45,0),(1.6,.55,9.5),rz=.025)
    for i,z in enumerate([-4.2,-2.8,-1.3,.4,2.1,3.8]): o.spike((0,3.7+(i%2)*.2,z),.18,1.15+(i%3)*.18,7,.16*(-1 if z<0 else 1))
    return o

def ogre_tower():
    o=Obj('ogre_tower')
    o.prism((0,2.8,0),2.45,1.75,5.6,7,.16)
    o.prism((.18,5.45,-.12),2.0,2.3,.55,7,.16)
    # timber braces
    for z,rz in [(-1.5,.48),(1.55,-.44),(.2,.18)]: o.box((-.85,3.0,z),(.32,4.5,.32),rz=rz)
    for i in range(7):
        a=2*math.pi*i/7+.16; o.spike((1.8*math.cos(a),5.72,1.8*math.sin(a)),.18,1.35,7,.12)
    return o

def ogre_gate():
    o=Obj('ogre_gatehouse')
    # brutal jaw piers and crossbar
    for z,rz in [(-3.55,.10),(3.35,-.14)]:
        o.box((0,2.8,z),(2.05,5.6,1.8),rz=rz)
        o.spike((-.15,5.45,z*.97),.34,2.4,8,.40*(-1 if z<0 else 1))
    o.box((0,5.5,-.1),(2.15,1.0,8.2),rz=.035)
    # lower fangs
    for z in [-2.7,-1.35,0,1.4,2.75]: o.spike((.55,4.95,z),.16,1.25,7,.42)
    return o

def ogre_keep():
    o=Obj('ogre_keep')
    o.prism((0,3.7,0),4.95,4.1,7.4,8,.18)
    o.prism((-.3,7.0,.25),4.25,3.65,1.7,8,.18)
    for i,a in enumerate([0,.8,1.6,2.4,3.2,4.0,4.8,5.6]):
        o.spike((3.55*math.cos(a),8.0+(i%2)*.25,3.55*math.sin(a)),.22,1.6+(i%3)*.2,7,.1)
    # crude plates / buttress ridges
    for z in [-3.2,-1.1,1.3,3.4]: o.box((3.8,3.4,z),(.55,5.2,1.1),rz=.06*(-1 if z<0 else 1))
    return o

for name,fn in [('human_wall',human_wall),('human_tower',human_tower),('human_gatehouse',human_gate),('human_keep',human_keep),('ogre_wall',ogre_wall),('ogre_tower',ogre_tower),('ogre_gatehouse',ogre_gate),('ogre_keep',ogre_keep)]:
    obj=fn(); obj.write(OUT/f'{name}.obj'); print(name,len(obj.v),len(obj.f))
