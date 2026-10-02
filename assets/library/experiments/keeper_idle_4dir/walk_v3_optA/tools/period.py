import sys, numpy as np
from pathlib import Path
from PIL import Image
sys.path.insert(0,'/workspace/keeper_idle/walk3'); from analyse_video import figure
R=Path('/workspace/keeper_idle/walk3')
d=sys.argv[1]; files=sorted((R/'frames'/d).glob('f_*.png'))
M=[]
for p in files:
    f,a,bg=figure(np.array(Image.open(p).convert('RGB')))
    M.append(np.array(Image.fromarray((a*255).astype(np.uint8)).resize((168,112),Image.BILINEAR))/255.)
M=np.array(M); np.save(R/f'masks_{d}.npy',M)
n=len(M)
for lag in range(8,60):
    dd=[np.abs(M[i]-M[i+lag]).sum() for i in range(n-lag)]
    print(lag, round(np.mean(dd),1), round(np.min(dd),1)) if lag%1==0 else None
