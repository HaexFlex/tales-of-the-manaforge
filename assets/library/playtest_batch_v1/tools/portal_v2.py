"""Portal v2 from Imagine portal_v1_a.png: grid-snap to Imagine's native cells, then build 160-wide candidates."""
import sys; sys.path.insert(0,'/workspace/art_refresh/tools')
import common as C, numpy as np
from PIL import Image
SRC='/workspace/playtest_batch/imagine/out/portal_v1_a.png'; OUT='/workspace/playtest_batch/work/portal/'
a=np.array(Image.open(SRC).convert('RGB')).astype(int)
mag=(a[...,0]>170)&(a[...,2]>170)&(a[...,1]<90)
dx=np.abs(np.diff(a,axis=1)).sum(-1); dx[mag[:,1:]|mag[:,:-1]]=0
dy=np.abs(np.diff(a,axis=0)).sum(-1); dy[mag[1:]|mag[:-1]]=0
def grid(sig,lo=15,hi=19):
    s=(sig>60).sum(0 if sig.ndim==2 else 0) if False else sig
    s=s-s.mean(); best=None
    for p in np.arange(lo,hi,0.01):
        v=(s*np.exp(2j*np.pi*np.arange(len(s))/p)).sum()
        if best is None or abs(v)>best[0]: best=(abs(v),p,np.angle(v))
    _,p,ph=best; o=(ph/(2*np.pi))*p   # boundary positions ~ o + k*p (edge between i and i+1 -> boundary at i+1)
    return p,(o%p)+1
px,ox=grid((dx>60).sum(0)); py,oy=grid((dy>60).sum(1))
print('grid',round(px,3),round(ox,2),round(py,3),round(oy,2))
nx=int((a.shape[1]-ox)//px); ny=int((a.shape[0]-oy)//py)
nat=np.zeros((ny,nx,4),np.uint8)
for j in range(ny):
    for i in range(nx):
        x0=int(round(ox+i*px)); y0=int(round(oy+j*py)); x1=int(round(ox+(i+1)*px)); y1=int(round(oy+(j+1)*py))
        cx0,cx1=x0+(x1-x0)//4,x1-(x1-x0)//4; cy0,cy1=y0+(y1-y0)//4,y1-(y1-y0)//4
        blk=a[cy0:cy1,cx0:cx1].reshape(-1,3); m=mag[cy0:cy1,cx0:cx1].reshape(-1)
        if m.mean()>0.5: continue
        nat[j,i,:3]=np.median(blk[~m],axis=0).astype(np.uint8); nat[j,i,3]=255
nat=C.trim(nat); print('native',nat.shape[1],'x',nat.shape[0])
C.save_rgba(nat,OUT+'portal_v1a_native.png')

# ---------------- candidates (target bbox ~158 wide inside outline -> 160 wide total)
from scipy import ndimage
def epx(im):
    h,w,_=im.shape; o=np.zeros((h*2,w*2,4),np.uint8)
    P=np.pad(im,((1,1),(1,1),(0,0)),mode='edge')
    eq=lambda u,v:(u==v).all(-1)
    Pc=P[1:-1,1:-1]; A=P[:-2,1:-1]; B=P[1:-1,2:]; Cc=P[1:-1,:-2]; D=P[2:,1:-1]
    o1=np.where((eq(Cc,A)&~eq(Cc,D)&~eq(A,B))[...,None],A,Pc)
    o2=np.where((eq(A,B)&~eq(A,Cc)&~eq(B,D))[...,None],B,Pc)
    o3=np.where((eq(D,Cc)&~eq(D,B)&~eq(Cc,A))[...,None],Cc,Pc)
    o4=np.where((eq(B,D)&~eq(B,A)&~eq(D,Cc))[...,None],D,Pc)
    o[0::2,0::2]=o1; o[0::2,1::2]=o2; o[1::2,0::2]=o3; o[1::2,1::2]=o4; return o
TW=158; TH=int(round(nat.shape[0]*TW/nat.shape[1]))
cands={}
# A: direct from HD cutout
hd=np.zeros((a.shape[0],a.shape[1],4),np.uint8); hd[...,:3]=a; hd[...,3]=np.where(mag,0,255)
hd[mag]=0; hd=C.trim(hd)
cands['A_direct']=C.pixelize(hd,(TW+2,TH+2),colors=32,method='mode',outline='outer',sharpen=0.0)
# B: EPX x2 x2 then mode downscale
e=epx(epx(nat)); cands['B_epx']=C.pixelize(e,(TW+2,TH+2),colors=32,method='mode',outline='outer')
# C: smooth upscale of native then quantize
up=np.array(Image.fromarray(nat).resize((TW*4,TH*4),Image.LANCZOS)); up[...,3]=np.where(up[...,3]>127,255,0)
cands['C_smooth']=C.pixelize(up,(TW+2,TH+2),colors=32,method='box',outline='outer',sharpen=0.5)
# D: native x2 integer
cands['D_x2']=C.pixelize(np.array(Image.fromarray(nat).resize((nat.shape[1]*2,nat.shape[0]*2),Image.NEAREST)),(nat.shape[1]*2+2,nat.shape[0]*2+2),colors=32,method='nearest',outline='outer')
for k,v in cands.items():
    c=C.place(v,160,200,anchor='bottom'); C.save_rgba(c,OUT+f'cand_{k}.png')
    print(k,v.shape[1],'x',v.shape[0],'cols',len(set(map(tuple,v[v[...,3]>0][:,:3].tolist()))))

# ---------------- final: candidate C (smooth resample of the snapped 64x78 grid -> crisp 1-px, no uneven 2/3-px doubling)
import colorsys
OLD_GREYS=[(0x37,0x39,0x3e),(0x3e,0x3f,0x44),(0x44,0x46,0x4b),(0x4b,0x4c,0x50),(0x51,0x53,0x55),(0x58,0x59,0x5b),
           (0x5d,0x61,0x62),(0x67,0x68,0x68),(0x78,0x77,0x76),(0x85,0x87,0x85),(0x9a,0x98,0x93)]  # current echo_portal_hub stone
G=np.array(OLD_GREYS,float)
fin=C.place(cands['C_smooth'],160,200,anchor='bottom').copy()
m=fin[...,3]>0; snapped=0
for col in np.unique(fin[m][:,:3],axis=0):
    r,g,b=col/255.0
    if colorsys.rgb_to_hsv(r,g,b)[1]<0.15 and col.astype(int).sum()>3*40:   # stone greys (not the outline)
        tgt=G[((G-col)**2).sum(1).argmin()].astype(np.uint8)
        sel=m&(fin[...,:3]==col).all(-1); fin[sel,:3]=tgt; snapped+=1
fin[~m]=0
C.save_rgba(fin,OUT+'echo_portal_hub_v2.png'); print('stone greys snapped to current portal palette:',snapped)
