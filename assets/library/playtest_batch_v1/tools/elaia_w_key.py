"""battle_elaia_key_w from Imagine elaia_w_key_v1_a.png: key magenta, snap to native grid, fit to idle-W height, palette-lock."""
import sys; sys.path.insert(0,'/workspace/art_refresh/tools')
import common as C, numpy as np, json
from PIL import Image
SRC='/workspace/playtest_batch/imagine/out/elaia_w_key_v1_a.png'; OUT='/workspace/playtest_batch/work/elaia/'
import os; os.makedirs(OUT,exist_ok=True)
a=np.array(Image.open(SRC).convert('RGB')).astype(int)
mag=(a[...,0]>170)&(a[...,2]>170)&(a[...,1]<100)
dx=np.abs(np.diff(a,axis=1)).sum(-1); dx[mag[:,1:]|mag[:,:-1]]=0
dy=np.abs(np.diff(a,axis=0)).sum(-1); dy[mag[1:]|mag[:-1]]=0
def grid(sig,lo=6,hi=20):
    s=sig-sig.mean(); best=None
    for p in np.arange(lo,hi,0.01):
        v=(s*np.exp(2j*np.pi*np.arange(len(s))/p)).sum()
        if best is None or abs(v)>best[0]: best=(abs(v),p,np.angle(v))
    _,p,ph=best; return p,((ph/(2*np.pi))*p)%p+1
px,ox=grid((dx>60).sum(0)); py,oy=grid((dy>60).sum(1)); print('grid',round(px,3),round(ox,2),round(py,3),round(oy,2))
nx=int((a.shape[1]-ox)//px); ny=int((a.shape[0]-oy)//py)
nat=np.zeros((ny,nx,4),np.uint8)
for j in range(ny):
    for i in range(nx):
        x0=int(round(ox+i*px)); y0=int(round(oy+j*py)); x1=int(round(ox+(i+1)*px)); y1=int(round(oy+(j+1)*py))
        cx0,cx1=x0+(x1-x0)//4,max(x0+(x1-x0)//4+1,x1-(x1-x0)//4); cy0,cy1=y0+(y1-y0)//4,max(y0+(y1-y0)//4+1,y1-(y1-y0)//4)
        blk=a[cy0:cy1,cx0:cx1].reshape(-1,3); m=mag[cy0:cy1,cx0:cx1].reshape(-1)
        if m.mean()>0.5: continue
        nat[j,i,:3]=np.median(blk[~m],axis=0).astype(np.uint8); nat[j,i,3]=255
nat=C.trim(nat); print('native',nat.shape[1],'x',nat.shape[0])
C.save_rgba(nat,OUT+'elaia_w_key_native.png')

# ---------------- lock to battle_elaia_idle_w: only the key + forward hand/forearm come from Imagine
from scipy import ndimage
import colorsys
W=np.array(Image.open('/workspace/playtest_batch/work/battle/battle_elaia_idle_w.png').convert('RGBA')).astype(int)
best=None
for ox in range(0,128-nat.shape[1]+1):
    for oy in range(0,128-nat.shape[0]+1):
        c=np.zeros((128,128,4),int); c[oy:oy+nat.shape[0],ox:ox+nat.shape[1]]=nat
        s=((c[:,50:,3]>0)^(W[:,50:,3]>0)).sum()
        if best is None or s<best[0]: best=(s,ox,oy)
_,ox,oy=best; print('offset',ox,oy)
c=np.zeros((128,128,4),int); c[oy:oy+nat.shape[0],ox:ox+nat.shape[1]]=nat
A=c[...,3]>0; B=W[...,3]>0; d=np.abs(c[...,:3]-W[...,:3]).sum(-1)
diff=ndimage.binary_opening((A^B)|(A&B&(d>90)),np.ones((2,2)))
lab,nl=ndimage.label(diff); sizes=ndimage.sum(diff,lab,range(1,nl+1)); keep=np.isin(lab,1+np.nonzero(sizes>=20)[0])
zone=ndimage.binary_dilation(keep,iterations=2)
pal=json.load(open('/workspace/elaia_anims/stills/palette.json'))['colors']; P=np.array([p[:3] for p in pal],float)
K=np.array(Image.open('/workspace/playtest_batch/work/battle/battle_elaia_key_s.png').convert('RGBA')).astype(int)
def isgold(rgb):
    r,g,b=rgb/255.0; h,s,v=colorsys.rgb_to_hsv(r,g,b); return 0.06<=h<=0.17 and s>0.35 and v>0.30
kg=K[:, :56][K[:, :56,3]>0][:,:3]; KG=np.array(sorted({tuple(x) for x in kg.tolist() if isgold(np.array(x))}),float)
print('front-key golds',len(KG))
out=W.copy(); wl=np.array([0.3,0.59,0.11])
for y,x in zip(*np.nonzero(zone)):
    if not A[y,x]:
        out[y,x]=0; continue
    col=c[y,x,:3].astype(float)
    if isgold(col) and x<56: tgt=KG[(((KG-col)**2)*wl).sum(1).argmin()]
    else: tgt=P[(((P-col)**2)*wl).sum(1).argmin()]
    out[y,x,:3]=tgt; out[y,x,3]=255
out[out[...,3]==0]=0
C.save_rgba(out.astype(np.uint8),OUT+'battle_elaia_key_w.png')
ys,xs=np.nonzero(out[...,3]); print('zone px',int(zone.sum()),'bbox',xs.min(),ys.min(),xs.max(),ys.max(),'h',ys.max()-ys.min()+1,'feet cx',round(xs[ys>=ys.max()-3].mean(),1),
  'cols',len({tuple(v) for v in out[out[...,3]>0][:,:3].tolist()}))
