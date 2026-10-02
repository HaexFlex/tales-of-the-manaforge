import sys, numpy as np
from PIL import Image, ImageDraw
from scipy import ndimage
sys.path.insert(0,'/workspace/keeper_idle/tools')
from build_idles import hue_group
A='/workspace/keeper_idle/repo/assets/library/experiments/keeper_idle_4dir/v3_stills_8dir/option_a/'
def groups(f):
    return hue_group(f[...,:3].reshape(-1,3).astype(int)).reshape(f.shape[:2])
def passing(walk, still, y_leg=82, bob=1):
    w=walk.copy(); op=w[...,3]>0; g=groups(w)
    coat=op&np.isin(g,[2,5,3]); skin=op&(g==4)
    keep_near=ndimage.binary_dilation(coat|skin, np.ones((3,3)))
    legpx=op&np.isin(g,[6,0,7])&~(keep_near&(g==0))
    legpx[:y_leg]=False
    # green tunic below y_leg that's visible between legs also goes
    legpx|= op&(g==1)&(np.arange(128)[:,None]>=y_leg+8)
    w[legpx]=0
    # drop leftovers (boot cuffs etc.) that are no longer connected to the body
    o=w[...,3]>0; lab,n=ndimage.label(o,np.ones((3,3)))
    if n>1:
        area=ndimage.sum(o,lab,np.arange(1,n+1)); w[(lab!=1+int(np.argmax(area)))&o]=0
    # bob: raise the whole remaining figure by `bob`
    if bob: w=np.concatenate([w[bob:],np.zeros((bob,128,4),np.uint8)])
    # still boots: rows >= 104 brown/dark pixels
    s=still; so=s[...,3]>0; sg=groups(s)
    boots=so.copy(); boots[:104]=False
    # horizontal align: coat centre at row 98 in walk vs still coat centre at row 100
    def cx(mask,row): xs=np.nonzero(mask[row])[0]; return (xs.min()+xs.max())/2
    wc=cx((w[...,3]>0)&np.isin(groups(w),[2,5]),96); sc=cx(so&np.isin(sg,[2,5]),100)
    dx=int(round(wc-sc))
    out=w.copy()
    ys,xs=np.nonzero(boots)
    for y,x in zip(ys,xs):
        X=x+dx
        if 0<=X<128 and out[y,X,3]==0: out[y,X]=s[y,x]
    # fill gap between coat hem and boot top: extend boot top row upward into transparent cells
    bt=104
    cols=[x+dx for x in np.nonzero(boots[bt])[0] if 0<=x+dx<128]
    for X in cols:
        y=bt-1
        while y>80 and out[y,X,3]==0: out[y,X]=out[bt,X]; y-=1
    return out
if __name__=='__main__':
    still=np.array(Image.open(A+'keeper_still_e.png'))
    G=(78,128,52,255); res=[]
    for name,i in [('side_b',1),('side_b',5),('side_a',1),('side_b',0)]:
        wk=np.array(Image.open(f'walk2/work/{name}/g_{i:02d}.png')); res+= [wk, passing(wk,still)]
    c=Image.new('RGBA',(len(res)*96,128),G)
    for k,f in enumerate(res): c.alpha_composite(Image.fromarray(f).crop((16,0,112,128)),(k*96,0))
    c.resize((c.width*2,c.height*2),Image.NEAREST).save('walk2/check/passing_proto.png')
    z=Image.new('RGBA',(2*80,128),G)
    for k,f in enumerate(res[:2]): z.alpha_composite(Image.fromarray(f).crop((24,0,104,128)),(k*80,0))
    z.resize((z.width*4,z.height*4),Image.NEAREST).save('walk2/check/passing_zoom.png')
