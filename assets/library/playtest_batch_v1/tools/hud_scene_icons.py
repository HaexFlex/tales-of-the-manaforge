"""HUD scene icons (32x32, hub v3 HUD recipe: 20 colours, outer outline, sharpen 0.6)."""
import sys; sys.path.insert(0,'/workspace/art_refresh/tools')
import common as C, numpy as np, os
from PIL import Image, ImageDraw
OUT=sys.argv[1]; os.makedirs(OUT,exist_ok=True)
R='/workspace/wp_tree/assets/art/'
def frame0(path,n):
    a=C.load_rgba(path); w=a.shape[1]//n; return a[:,:w].copy()
# --- Clearing: mature Manatree (frame 0) on a grass mound
tree=C.trim(frame0(R+'manatree/native/anim/manatree_mature_strip.png',8)); tree[...,:3]=np.clip(tree[...,:3].astype(float)*1.22+6,0,255).astype(np.uint8)
S=640; cv=Image.new('RGBA',(S,S),(0,0,0,0)); d=ImageDraw.Draw(cv)
d.ellipse((20,S-150,S-20,S+90),fill=(47,90,42,255)); d.ellipse((60,S-140,S-60,S+40),fill=(77,138,58,255)); d.ellipse((130,S-132,S-170,S-60),fill=(120,176,74,255))
th=S-90; tw=int(tree.shape[1]*th/tree.shape[0]); t=Image.fromarray(tree).resize((tw,th),Image.LANCZOS)
cv.alpha_composite(t,((S-tw)//2,S-110-th+40))
a=np.array(cv); a[...,3]=np.where(a[...,3]>127,255,0).astype(np.uint8)
ic=C.pixelize(C.trim(a),(30,30),colors=20,outline='outer',sharpen=0.6)
C.save_rgba(C.place(ic,32,32,anchor='center'),OUT+'/hud_scene_clearing.png')
# --- Forge: anvil idle + spark
anv=C.trim(C.load_rgba(R+'forge/prop_anvil_idle.png'))
ic=C.pixelize(anv,(30,int(round(anv.shape[0]*30/anv.shape[1]))),colors=19,outline='outer',sharpen=0.6)
c=C.place(ic,32,32,box=(0,4,32,32),anchor='bottom')
Y,W,O=(255,214,107,255),(255,250,226,255),(255,150,60,255)
sx,sy=23,5   # spark star top-right above the anvil face
for (dx,dy),col in {(0,0):W,(1,0):Y,(-1,0):Y,(0,1):Y,(0,-1):Y,(2,0):O,(-2,0):O,(0,2):O,(0,-2):O,(-3,3):O,(3,-3):Y}.items():
    c[sy+dy,sx+dx]=col
C.save_rgba(c,OUT+'/hud_scene_forge.png')
