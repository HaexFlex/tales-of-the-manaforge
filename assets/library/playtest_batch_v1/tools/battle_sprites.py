from PIL import Image; import numpy as np, json, shutil, colorsys, sys, os
OUT=sys.argv[1]; os.makedirs(OUT,exist_ok=True)
K='/workspace/keeper_idle/repo/assets/library/experiments/keeper_idle_4dir/v3_stills_8dir/option_a/'
E='/workspace/elaia_anims/stills/'
for src,dst in [(K+'keeper_still_s.png','battle_keeper_idle_s.png'),(K+'keeper_still_e.png','battle_keeper_idle_e.png'),
                (E+'elaia_still_s.png','battle_elaia_idle_s.png'),(E+'elaia_still_w.png','battle_elaia_idle_w.png')]:
    shutil.copyfile(src,os.path.join(OUT,dst))
# key sprite -> Elaia companion palette (golds kept)
pal=json.load(open(E+'palette.json'))
if isinstance(pal,dict): pal=pal.get('colors') or pal.get('palette') or list(pal.values())[0]
P=np.array([[int(c[i:i+2],16) for i in (1,3,5)] if isinstance(c,str) else c[:3] for c in pal],float)
a=np.array(Image.open('/workspace/elaia_anims/work/elaia_s_key_128.png').convert('RGBA'))
o=a.copy(); m=a[...,3]>0; kept=0
for y,x in zip(*np.nonzero(m)):
    r,g,b=a[y,x,:3]/255.0; h,s,v=colorsys.rgb_to_hsv(r,g,b)
    if 0.07<=h<=0.17 and s>0.35 and v>0.35 and x<56: kept+=1; continue  # the key (left of body)
    d=((P-a[y,x,:3].astype(float))**2*[0.3,0.59,0.11]).sum(1); o[y,x,:3]=P[d.argmin()].astype(np.uint8)
o[~m]=0
Image.fromarray(o,'RGBA').save(os.path.join(OUT,'battle_elaia_key_s.png'))
print('key px kept',kept,'colours',len(set(map(tuple,o[m][:,:3].tolist()))))
