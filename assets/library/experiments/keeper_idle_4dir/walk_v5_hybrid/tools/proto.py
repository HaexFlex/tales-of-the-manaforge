import numpy as np, json, sys
from pathlib import Path
from PIL import Image
from scipy import ndimage
B = Path('/workspace/keeper_idle/repo/assets/library/experiments/keeper_idle_4dir')
V3 = B / 'walk_v3_optA/walk_south'; V4 = B / 'walk_v4_casual/walk_south'
LEG = [(54,26,12),(71,36,16),(37,16,8),(96,51,24),(116,64,28),(15,6,4),(139,79,36)]
def load(d, k): return np.array(Image.open(d / f'walk_south_{k:04d}.png'))
def isin(f, cols): return np.isin(f[...,0].astype(int)*65536+f[...,1].astype(int)*256+f[...,2], [r*65536+g*256+b for r,g,b in cols]) & (f[...,3] > 0)
def legmask(f, r0=78, x0=44, x1=84):
    m = isin(f, LEG); m[:r0] = False; m[:, :x0] = False; m[:, x1:] = False
    lab, n = ndimage.label(m, [[0,1,0],[1,1,1],[0,1,0]])
    keep = np.zeros_like(m)
    for i, s in enumerate(ndimage.find_objects(lab)):
        if s[0].stop - 1 >= 108 and (lab[s] == i + 1).sum() >= 15: keep |= lab == i + 1
    return keep
if __name__ == '__main__':
    out = []
    for name, d in (('v3', V3), ('v4', V4)):
        row = []
        for k in range(8):
            f = load(d, k); m = legmask(f); v = np.zeros((128,128,3),np.uint8); v[:] = (78,128,52)
            v[f[...,3]>0] = (f[f[...,3]>0,:3]*0.35).astype(np.uint8); v[m] = f[m,:3]; v[m] = np.clip(v[m].astype(int)+(60,0,60),0,255)
            row.append(v[60:128, 30:98])
        out.append(np.concatenate(row, 1))
    Image.fromarray(np.concatenate(out, 0)).resize((8*68*3, 2*68*3), Image.NEAREST).save('check/legmasks.png')
