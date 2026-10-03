import numpy as np, json
from PIL import Image
B='/workspace/forest_variants/build/'
pairs=[('ring_tree_conifer_01','ring_tree_conifer_03'),('ring_tree_conifer_02','ring_tree_conifer_04'),('ring_tree_tall_01','ring_tree_tall_02'),
       ('ring_tree_old_01','ring_tree_old_03'),('ring_tree_old_02','ring_tree_old_04'),('ring_tree_wide_01','ring_tree_wide_02'),
       ('ring_tree_conifer_01','ring_tree_conifer_02'),('ring_tree_conifer_03','ring_tree_conifer_04'),
       ]+[(f'ring_bush_{k}_{a:02d}',f'ring_bush_{k}_{a+2:02d}') for k in ('round','low','spiky','bloom') for a in (1,2)]
def sil(n,H=200):
    a=np.array(Image.open(B+n+'.png'))[...,3]>0; ys,xs=np.nonzero(a); a=a[ys.min():ys.max()+1]
    im=Image.fromarray(np.uint8(a)*255); w=max(1,round(im.width*H/im.height)); a=np.array(im.resize((w,H),Image.NEAREST))>0
    return a
def iou(a,b):
    W=max(a.shape[1],b.shape[1])+4
    def pad(x): o=np.zeros((x.shape[0],W),bool); s=(W-x.shape[1])//2; o[:,s:s+x.shape[1]]=x; return o
    A,Bb=pad(a),pad(b); return (A&Bb).sum()/(A|Bb).sum()
for p,q in pairs:
    a,b=sil(p),sil(q); v=max(iou(a,b),iou(a,b[:,::-1]))
    sa=Image.open(B+p+'.png').size; sb=Image.open(B+q+'.png').size
    print(f'{p:22s} {q:22s} IoU(best of flip) {v:.3f}  sizes {sa} {sb}')
