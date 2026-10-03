from PIL import Image, ImageDraw, ImageFont; import numpy as np, sys
R='/workspace/wp_tree/assets/art/'; BG=(58,92,44,255)
F=ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf',18); f2=ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf',13)
W=1800; cv=Image.new('RGBA',(W,1500),BG); d=ImageDraw.Draw(cv)
def up(im,s): return im.resize((im.width*s,im.height*s),Image.NEAREST)
def lab(x,y,t,small=False): d.text((x,y),t,fill=(240,240,220,255),font=f2 if small else F)
y=10; lab(10,y,'1) Portal: old (in-game 64x95) | Keeper | NEW echo_portal_hub_v2 160x200 (visible 160x195). Left group at x2, right group at native x1'); y+=34
portal=Image.open('work/portal_native_64x95.png'); keeper=Image.open('/workspace/keeper_idle/repo/assets/library/experiments/keeper_idle_4dir/v3_stills_8dir/option_a/keeper_still_s.png').convert('RGBA')
newp=Image.open(R+'props/echo_portal_hub_v2.png')
base=y+200*2+10
x=40
cv.alpha_composite(up(portal,2),(x,base-95*2)); x+=64*2+10
cv.alpha_composite(up(keeper,2),(x,base-124*2)); x+=100*2
cv.alpha_composite(up(newp,2),(x,base-200*2)); x+=160*2+20
lab(40,base+4,'x2: old portal | Keeper | new portal (same scale)',True)
x1=x+60
cv.alpha_composite(portal,(x1,base-95)); cv.alpha_composite(keeper,(x1+70,base-124)); cv.alpha_composite(newp,(x1+170,base-200))
lab(x1,base+4,'x1 native: old | Keeper | new',True)
y=base+30; lab(10,y,'2) Echo battle sprites 128x128 (x2): keeper S, keeper E, elaia S, elaia W, elaia S + key, elaia W + key (new)'); y+=30
for i,n in enumerate(['battle_keeper_idle_s','battle_keeper_idle_e','battle_elaia_idle_s','battle_elaia_idle_w','battle_elaia_key_s','battle_elaia_key_w']):
    cv.alpha_composite(up(Image.open(R+f'echo/{n}.png'),2),(30+i*262,y)); lab(30+i*262,y+258,n+'.png',True)
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
