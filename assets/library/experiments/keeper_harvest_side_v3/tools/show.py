import sys, numpy as np
from PIL import Image, ImageDraw
sys.path.insert(0,'/workspace/keeper_idle/harv'); from analyse_harvest import isolate
a=sys.argv[1]; idx=[int(x) for x in sys.argv[2].split(',')]; out=sys.argv[3]; sc=float(sys.argv[4]); cols=int(sys.argv[5])
cells=[]
for i in idx:
    f,al,bg,keep=isolate(np.array(Image.open(f'/workspace/keeper_idle/harv/frames/{a}/f_{i:03d}.png').convert('RGB')))
    im=Image.fromarray(np.dstack([f,al*255]).astype(np.uint8)).crop((190,10,560,400))
    b=Image.new('RGBA',im.size,(78,128,52,255)); b.alpha_composite(im); cells.append(b.resize((int(im.width*sc),int(im.height*sc)),Image.LANCZOS))
w,h=cells[0].size; rows=(len(cells)+cols-1)//cols; c=Image.new('RGB',(w*cols,(h+12)*rows),(20,20,20)); dr=ImageDraw.Draw(c)
for k,cl in enumerate(cells): x,y=(k%cols)*w,(k//cols)*(h+12); c.paste(cl,(x,y+12)); dr.text((x+3,y),f'f{idx[k]}',fill=(255,255,255))
c.save(out); print(c.size)
