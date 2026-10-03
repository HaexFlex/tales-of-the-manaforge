import sys, json, numpy as np
from PIL import Image
sys.path.insert(0,'/workspace/keeper_idle/tools'); from ingest_turnaround import key
from scipy import ndimage
c=sys.argv[1]; M={}; masks=[]
for i in range(1,146):
    rgb=np.array(Image.open(f'frames/{c}/f_{i:03d}.png').convert('RGB'))
    f,a,bg=key(rgb); m=a>0.5
    lab,n=ndimage.label(m,np.ones((3,3))); ar=sorted(ndimage.sum(m,lab,range(1,n+1)),reverse=True) if n else []
    ys,xs=np.nonzero(m)
    r,g,b=[f[...,k].astype(int) for k in range(3)]
    skin=m&(r>170)&(g>110)&(b<170)&(r-b>50)&(r>=g)
    hair=m&(g>r+25)&(g>b+25); hy,hx=np.nonzero(hair)
    sy,sx=np.nonzero(skin)
    M[i]=dict(top=int(ys.min()),x0=int(xs.min()),x1=int(xs.max()),ncomp=int(n),small=[int(v) for v in ar[1:6]],
              skin_n=int(len(sy)),skin_top=int(sy.min()) if len(sy) else None,hair_top=int(hy.min()),hair_bot=int(hy.max()),hair_cx=round(float(hx.mean()),1))
    masks.append(np.packbits(m))
json.dump(M,open(f'metrics_{c}.json','w')); np.save(f'masks_{c}.npy',np.array(masks))
