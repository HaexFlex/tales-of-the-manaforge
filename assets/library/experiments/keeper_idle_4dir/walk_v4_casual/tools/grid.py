import sys
from PIL import Image, ImageDraw
d=sys.argv[1]; idx=[int(x) for x in sys.argv[2].split(',')]; out=sys.argv[3]; y0=int(sys.argv[4]) if len(sys.argv)>4 else 0
x0,x1=(26,102) if d=='side' else (34,94); cols=int(sys.argv[5]) if len(sys.argv)>5 else 6
G=(78,128,52,255); w=x1-x0; h=128-y0; rows=(len(idx)+cols-1)//cols
c=Image.new('RGBA',(cols*(w+2),rows*(h+2)),(20,20,20,255))
for k,i in enumerate(idx):
    im=Image.open(f'/workspace/keeper_idle/walk4/work/{d}/g_{i:03d}.png').crop((x0,y0,x1,128)); b=Image.new('RGBA',im.size,G); b.alpha_composite(im); c.paste(b,((k%cols)*(w+2),(k//cols)*(h+2)))
s=3 if y0>40 else 2
c=c.resize((c.width*s,c.height*s),Image.NEAREST); dr=ImageDraw.Draw(c)
for k,i in enumerate(idx): dr.text(((k%cols)*(w+2)*s+3,(k//cols)*(h+2)*s+2),str(i),fill=(255,255,255,255))
c.save(out); print(c.size)
