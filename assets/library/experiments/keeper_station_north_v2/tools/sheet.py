import sys
from PIL import Image, ImageDraw
d=sys.argv[1]; idx=[int(x) for x in sys.argv[2].split(',')]; out=sys.argv[3]; sc=int(sys.argv[4]); cols=int(sys.argv[5])
crop=tuple(int(v) for v in sys.argv[6].split(',')) if len(sys.argv)>6 else None
cells=[]
for i in idx:
    im=Image.open(f'/workspace/keeper_idle/station2/work/g_{i:03d}.png')
    if crop: im=im.crop(crop)
    b=Image.new('RGBA',im.size,(78,128,52,255)); b.alpha_composite(im); cells.append(b.resize((im.width*sc,im.height*sc),Image.NEAREST))
w,h=cells[0].size; rows=(len(cells)+cols-1)//cols; c=Image.new('RGB',(w*cols,(h+12)*rows),(20,20,20)); dr=ImageDraw.Draw(c)
for k,cl in enumerate(cells): x,y=(k%cols)*w,(k//cols)*(h+12); c.paste(cl,(x,y+12)); dr.text((x+3,y),f'f{idx[k]}',fill=(255,255,255))
c.save(out); print(c.size)
