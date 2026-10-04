"""Game-speed buttons from pause_{state}.png: white bars -> play triangle / baked 'Nx' labels; plus glyph set."""
from PIL import Image; import numpy as np, sys, os
SRC='/workspace/wp_tree/assets/art/ui/buttons/'; OUT=sys.argv[1]; os.makedirs(OUT,exist_ok=True)
WHITE=np.array([0xf7,0xf9,0xf7,255],np.uint8); DARK=np.array([0x01,0x0a,0x01,255],np.uint8); FACE=np.array([0x2a,0x64,0x2a,255],np.uint8)
D={'0':["111","101","101","101","111"],'1':["010","110","010","010","111"],'2':["111","001","111","100","111"],
   '3':["111","001","011","001","111"],'4':["101","101","111","001","001"],'5':["111","100","111","001","111"],
   '6':["111","100","111","101","111"],'7':["111","001","010","010","010"],'8':["111","101","111","101","111"],
   '9':["111","101","111","001","111"],'x':["000","101","010","101","000"]}
def blank(state):
    a=np.array(Image.open(SRC+f'pause_{state}.png').convert('RGBA'))
    w=(a[...,:3].astype(int).min(-1)>200)&(a[...,3]>0); ys,xs=np.nonzero(w)
    a[w]=FACE; return a,(xs.min(),ys.min(),xs.max(),ys.max())
def tri(a,x0,y0,h):
    for r in range(h):
        wd=min(r,h-1-r)+1
        a[y0+r,x0:x0+wd]=WHITE
def text(a,s,cx,y0,outline=False):
    wtot=len(s)*3+(len(s)-1); x=cx-wtot//2
    for ch in s:
        g=D[ch]
        for yy in range(5):
            for xx in range(3):
                if g[yy][xx]=='1': a[y0+yy,x+xx]=WHITE
        x+=4
for st in ['normal','hover','pressed']:
    a,(x0,y0,x1,y1)=blank(st); h=y1-y0+1
    p=a.copy(); tri(p,x0+2,y0,h); Image.fromarray(p,'RGBA').save(f'{OUT}/speed_play_{st}.png')
    cx=16  # face interior x7..25
    for n in ['1','2','4','8','16']:
        b=a.copy(); dy=1 if st=='pressed' else 0
        tri(b,cx-1,7+dy,5)              # small play mark, 5 tall
        text(b,n+'x',cx,14+dy)          # 3x5 digits
        Image.fromarray(b,'RGBA').save(f'{OUT}/speed_{n}x_{st}.png')
# standalone glyphs: white 3x5 with 1px dark outline (8-neighbour) -> 5x7 cells
for ch,g in D.items():
    m=np.zeros((7,5),bool)
    for yy in range(5):
        for xx in range(3): m[yy+1,xx+1]=g[yy][xx]=='1'
    o=np.zeros((7,5,4),np.uint8)
    dil=np.zeros_like(m)
    for dy in (-1,0,1):
        for dx in (-1,0,1): dil|=np.roll(np.roll(m,dy,0),dx,1)
    o[dil]=DARK; o[m]=WHITE
    Image.fromarray(o,'RGBA').save(f'{OUT}/glyph_{ch}.png')
