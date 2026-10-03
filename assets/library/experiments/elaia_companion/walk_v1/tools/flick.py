from PIL import Image; import numpy as np, glob, sys
def top(f): return int(np.nonzero(f[...,3].any(1))[0].min())
root = sys.argv[1] if len(sys.argv) > 1 else 'assembled_v1'
for d in ('east','south','north'):
  F=[np.array(Image.open(p)) for p in sorted(glob.glob(f'{root}/{d}/walk_*_0*.png'))]
  for (a,b) in ((0,34),(34,48),(48,60),(60,80)):
    diffs=[]
    for k in range(8):
      f,g=F[k],F[(k+1)%8]; tf,tg=top(f),top(g)
      diffs.append(int((np.abs(f[tf+a:tf+b].astype(int)-g[tg+a:tg+b].astype(int)).sum(-1)>0).sum()))
    print(d,f'r{a}-{b}',diffs)
