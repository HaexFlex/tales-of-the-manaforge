"""Build glow-only Manatree strips: static frame-0 silhouette/colours, only vein-glow pixels pulse.
Per frame: undo the crown shear (per-row horizontal shift, measured row by row), then copy only
pixels that are teal-glow (in base or that frame) and changed, onto frame 0."""
from PIL import Image; import numpy as np, json, sys, os
SRC='/workspace/wp_tree/assets/art/manatree/'
OUT=sys.argv[1]
m=json.load(open(SRC+'native/manatree_meta.json'))
def teal(f):
    f=f[...,:3].astype(int); return (f[...,1]>f[...,0]+40)&(f[...,2]>f[...,0]+30)
rep={}
for st in m['stages']:
    a=np.array(Image.open(SRC+st['file']).convert('RGBA')); n=st['frames']; W=a.shape[1]//n; H=a.shape[0]
    fr=[a[:,i*W:(i+1)*W] for i in range(n)]; base=fr[0]
    un=[]
    shifts=[]
    for i in range(n):
        u=np.zeros_like(base); ss=[]
        for y in range(H):
            best=(0,None)
            for s in sorted(range(-6,7),key=abs):
                d=(np.abs(np.roll(base[y],s,axis=0).astype(int)-fr[i][y].astype(int)).sum(-1)>0).sum()
                if best[1] is None or d<best[1]: best=(s,d)
            ss.append(best[0]); u[y]=np.roll(fr[i][y],-best[0],axis=0)
        un.append(u); shifts.append(max(ss,key=abs))
    ab=base[...,3]>0
    changed=np.zeros((H,W),bool); tealany=teal(base)
    for u in un:
        c=(np.abs(u.astype(int)-base.astype(int)).sum(-1)>0)&ab&(u[...,3]>0); changed|=c; tealany|=teal(u)&(u[...,3]>0)
    G=changed&tealany
    resid=int((changed&~tealany).sum())
    outf=[]
    for u in un:
        f=base.copy(); g=G&(u[...,3]>0); f[g]=u[g]; outf.append(f)
    strip=np.concatenate(outf,axis=1)
    pal0=set(map(tuple,a[a[...,3]>0][:,:3].tolist())); paln=set(map(tuple,strip[strip[...,3]>0][:,:3].tolist()))
    name=f"manatree_{st['stage_id']}_strip_glow.png"
    Image.fromarray(strip,'RGBA').save(os.path.join(OUT,name))
    rep[st['stage_id']]=dict(file=name,size=[strip.shape[1],H],frame=[W,H],frames=n,glow_px=int(G.sum()),non_glow_residual_px_dropped=resid,
        max_crown_shift_px=[int(s) for s in shifts],new_colours=len(paln-pal0),
        silhouette_identical=all(((f[...,3]>0)==ab).all() for f in outf),
        per_frame_glow_changed=[int(((np.abs(f.astype(int)-base.astype(int)).sum(-1))>0).sum()) for f in outf])
    print(st['stage_id'],rep[st['stage_id']])
json.dump(rep,open(os.path.join(OUT,'glow_only_report.json'),'w'),indent=1)
