from PIL import Image; import numpy as np, sys
H=lambda s: tuple(int(s[i:i+2],16) for i in (1,3,5))+(255,)
C0,C1,C2,C3=H('#6dedd7'),H('#3de7ca'),H('#2ecfae'),H('#16caa4')
f=np.zeros((5,15,4),np.uint8)
# frame0: diamond r2
for y in range(5):
    for x in range(5):
        d=abs(x-2)+abs(y-2)
        if d==0: f[y,x]=C0
        elif d==1: f[y,x]=C1
        elif d==2 and (x==2 or y==2): f[y,x]=C3
# frame1: plus r1
f[2,7]=C0; 
for dx,dy in((1,0),(-1,0),(0,1),(0,-1)): f[2+dy,7+dx]=C2
# frame2: single
f[2,12]=C1
Image.fromarray(f,'RGBA').save(sys.argv[1]+'/fx_vein_mote_strip.png')
Image.fromarray(f[:,0:5].copy(),'RGBA').save(sys.argv[1]+'/fx_vein_mote.png')
