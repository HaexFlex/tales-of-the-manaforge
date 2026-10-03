import sys, json, numpy as np
from PIL import Image
sys.path.insert(0,'/workspace/keeper_idle/tools'); from ingest_turnaround import key
from scipy import ndimage
M={}; masks=[]
for i in range(1,146):
    rgb=np.array(Image.open(f'frames/g/f_{i:03d}.png').convert('RGB'))
    f,a,bg=key(rgb); m=a>0.5
    lab,n=ndimage.label(m); 
    if n>1:
        ar=ndimage.sum(m,lab,range(1,n+1)); 
    ys,xs=np.nonzero(m)
    r,g,b=[f[...,c].astype(int) for c in range(3)]
    skin=m&(r>170)&(g>120)&(b<170)&(r-b>50)&(r>=g)
    sy,sx=np.nonzero(skin)
    L=skin.copy(); L[:,336:]=False; R_=skin.copy(); R_[:,:336]=False
    def c(z):
        yy,xx=np.nonzero(z); return [round(float(yy.mean()),1),round(float(xx.mean()),1),int(len(yy))] if len(yy) else None
    hair=m&(g>r+25)&(g>b+25); hy,hx=np.nonzero(hair)
    M[i]=dict(top=int(ys.min()),bot=int(ys.max()),x0=int(xs.min()),x1=int(xs.max()),n=int(n),area=int(m.sum()),L=c(L),R=c(R_),hair_top=int(hy.min()),hair_cx=round(float(hx.mean()),1))
    masks.append(np.packbits(m))
json.dump(M,open('metrics.json','w'))
np.save('masks.npy',np.array(masks))
for i in range(1,146,2): print(i,M[i])
