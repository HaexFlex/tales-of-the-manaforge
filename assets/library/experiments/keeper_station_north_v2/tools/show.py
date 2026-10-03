import sys, numpy as np
from PIL import Image, ImageDraw
sys.path.insert(0,'/workspace/keeper_idle/tools'); from ingest_turnaround import key
c=sys.argv[1]; idx=[int(x) for x in sys.argv[2].split(',')]; out=sys.argv[3]; sc=float(sys.argv[4]); cols=int(sys.argv[5])
box=tuple(int(v) for v in sys.argv[6].split(',')) if len(sys.argv)>6 else (190,30,490,410)
cells=[]
for i in idx:
    f,a,bg=key(np.array(Image.open(f'/workspace/keeper_idle/station2/frames/{c}/f_{i:03d}.png').convert('RGB')))
    im=Image.fromarray(np.dstack([f,a*255]).astype(np.uint8)).crop(box)
    b=Image.new('RGBA',im.size,(78,128,52,255)); b.alpha_composite(im); cells.append(b.resize((int(im.width*sc),int(im.height*sc)),Image.LANCZOS))
w,h=cells[0].size; rows=(len(cells)+cols-1)//cols; cv=Image.new('RGB',(w*cols,(h+12)*rows),(20,20,20)); dr=ImageDraw.Draw(cv)
for k,cl in enumerate(cells): x,y=(k%cols)*w,(k//cols)*(h+12); cv.paste(cl,(x,y+12)); dr.text((x+3,y),f'f{idx[k]}',fill=(255,255,255))
cv.save(out); print(cv.size)
