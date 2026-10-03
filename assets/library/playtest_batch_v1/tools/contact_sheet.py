from PIL import Image, ImageDraw, ImageFont; import numpy as np, sys
R='/workspace/wp_tree/assets/art/'; BG=(58,92,44,255)
F=ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf',18); f2=ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf',13)
W=1800; cv=Image.new('RGBA',(W,1500),BG); d=ImageDraw.Draw(cv)
def up(im,s): return im.resize((im.width*s,im.height*s),Image.NEAREST)
def lab(x,y,t,small=False): d.text((x,y),t,fill=(240,240,220,255),font=f2 if small else F)
y=10; lab(10,y,'1) Portal (current, in-game size 64x95, shown x2) next to the Keeper; dashed box = 160x200 target for the Imagine regen'); y+=34
portal=Image.open('work/portal_native_64x95.png'); keeper=Image.open('/workspace/keeper_idle/repo/assets/library/experiments/keeper_idle_4dir/v3_stills_8dir/option_a/keeper_still_s.png').convert('RGBA')
base=y+200*2+10
cv.alpha_composite(up(portal,2),(40,base-95*2)); cv.alpha_composite(up(keeper,2),(40+64*2+10,base-123*2-2))
bx=520; 
for i in range(0,400,12): d.line((bx,base-i,bx,base-i-6),fill=(255,255,255,255),width=2); d.line((bx+320,base-i,bx+320,base-i-6),fill=(255,255,255,255),width=2)
for i in range(0,320,12): d.line((bx+i,base,bx+i+6,base),fill=(255,255,255,255),width=2); d.line((bx+i,base-400,bx+i+6,base-400),fill=(255,255,255,255),width=2)
vis=portal.crop(portal.getbbox()).resize((320,390),Image.NEAREST); cv.alpha_composite(vis,(bx,base-390))
cv.alpha_composite(up(keeper,2),(bx+330,base-123*2-2)); lab(bx,base+4,'target 160x200 (x2), current art blown up 2.5x as a guide only, vs Keeper',True); lab(40,base+4,'current 64x95 vs Keeper',True)
y=base+30; lab(10,y,'2) Echo battle sprites 128x128 (x2): keeper S, keeper E, elaia S, elaia W, elaia S + key'); y+=30
for i,n in enumerate(['battle_keeper_idle_s','battle_keeper_idle_e','battle_elaia_idle_s','battle_elaia_idle_w','battle_elaia_key_s']):
    cv.alpha_composite(up(Image.open(R+f'echo/{n}.png'),2),(40+i*270,y)); lab(40+i*270,y+258,n+'.png',True)
y+=285; lab(10,y,'3) HUD scene icons, speed buttons (normal/hover/pressed), baked 1x-16x, glyphs (x4)'); y+=30
x=40
for n in ['icons/hud_scene_clearing','icons/hud_scene_forge']: cv.alpha_composite(up(Image.open(R+f'ui/{n}.png'),4),(x,y)); x+=140
for n in ['speed_play_normal','speed_play_hover','speed_play_pressed','speed_1x_normal','speed_2x_normal','speed_4x_normal','speed_8x_normal','speed_16x_normal','speed_16x_pressed']:
    cv.alpha_composite(up(Image.open(R+f'ui/buttons/{n}.png'),4),(x,y)); x+=136
y+=136
for i,c in enumerate('0123456789x'): cv.alpha_composite(up(Image.open(R+f'ui/glyphs/glyph_{c}.png'),4),(40+i*26,y))
lab(340,y+6,'glyph_0..9, glyph_x (5x7)',True)
y+=50; lab(10,y,'4) Manatree glow-only strips (frames 0/2/4/6, x1 young / x2 sapling) + vein mote strip (x8): no sway, only veins pulse'); y+=30
yg=Image.open(R+'manatree/native/anim/glow/manatree_young_strip_glow.png'); sp=Image.open(R+'manatree/native/anim/glow/manatree_sapling_strip_glow.png')
for k,i in enumerate([0,2,4,6]):
    cv.alpha_composite(yg.crop((i*288,0,i*288+288,288)),(20+k*230,y)); cv.alpha_composite(up(sp.crop((i*128,0,i*128+128,128)),2),(960+k*170,y+30))
cv.alpha_composite(up(Image.open(R+'fx/fx_vein_mote_strip.png'),8),(960,y+300)); lab(1100,y+310,'fx_vein_mote_strip.png 15x5, 3 frames',True)
y+=360; cv=cv.crop((0,0,W,y)); cv.convert('RGB').save(sys.argv[1]); print(cv.size)
