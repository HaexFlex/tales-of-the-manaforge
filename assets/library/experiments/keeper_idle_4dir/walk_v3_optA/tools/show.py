import sys, numpy as np
from PIL import Image, ImageDraw
sys.path.insert(0,'/workspace/keeper_idle/walk3'); from analyse_video import figure
d=sys.argv[1]; idx=[int(x) for x in sys.argv[2].split(',')]; out=sys.argv[3]; sc=float(sys.argv[4]) if len(sys.argv)>4 else 0.6
cells=[]
for i in idx:
    f,a,bg=figure(np.array(Image.open(f'/workspace/keeper_idle/walk3/frames/{d}/f_{i:03d}.png').convert('RGB')))
    im=Image.fromarray(np.dstack([f,a*255]).astype(np.uint8)).crop((200,30,480,420))
    b=Image.new('RGBA',im.size,(78,128,52,255)); b.alpha_composite(im); cells.append(b.resize((int(im.width*sc),int(im.height*sc)),Image.LANCZOS))
w,h=cells[0].size; c=Image.new('RGB',(w*len(cells),h+14),(20,20,20)); dr=ImageDraw.Draw(c)
for k,cl in enumerate(cells): c.paste(cl,(k*w,14)); dr.text((k*w+3,1),f'f{idx[k]}',fill=(255,255,255))
c.save(out); print(c.size)
