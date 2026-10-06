from pathlib import Path
from PIL import Image
import numpy as np

SRC=Path('/mnt/data/ogre_phase5/assets/castlehold/materials')
OUT=Path('/mnt/data/ogre_phase5/assets/ogre_modern/materials')
OUT.mkdir(parents=True,exist_ok=True)
rng=np.random.default_rng(51273)

def blur_noise(size, scale=16):
    small=rng.normal(0,1,(max(2,size//scale),max(2,size//scale))).astype(np.float32)
    im=Image.fromarray(np.uint8(np.clip((small-small.min())/(small.max()-small.min()+1e-6)*255,0,255)))
    arr=np.asarray(im.resize((size,size),Image.Resampling.BICUBIC)).astype(np.float32)/255.0
    return arr*2-1

def albedo(name,strength=0.045):
    im=Image.open(SRC/f'{name}_albedo.png').convert('RGB').resize((512,512),Image.Resampling.LANCZOS)
    a=np.asarray(im).astype(np.float32)/255.0
    broad=blur_noise(512,24)[...,None]
    fine=blur_noise(512,6)[...,None]
    factor=1.0+broad*strength+fine*(strength*.35)
    out=np.clip(a*factor,0,1)
    Image.fromarray(np.uint8(out*255)).save(OUT/f'{name}_albedo_512.png',optimize=True)

def normal(name,detail=.10):
    im=Image.open(SRC/f'{name}_normal.png').convert('RGB').resize((512,512),Image.Resampling.LANCZOS)
    n=np.asarray(im).astype(np.float32)/255.0*2-1
    h=blur_noise(512,7)
    gy,gx=np.gradient(h)
    n[...,0]+=gx*detail
    n[...,1]-=gy*detail
    length=np.sqrt(np.sum(n*n,axis=2,keepdims=True))+1e-8
    n=n/length
    out=np.clip((n+1)*.5,0,1)
    Image.fromarray(np.uint8(out*255)).save(OUT/f'{name}_normal_512.png',optimize=True)

for name,astr,nd in [('sandstone',.055,.16),('oak',.045,.11),('slate',.035,.08)]:
    albedo(name,astr); normal(name,nd)
    print(name)
