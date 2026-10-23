from PIL import Image, ImageDraw
import numpy as np
M=Image.open('title_bg_wide_1440x900.png').convert('RGBA')
logo=Image.open('/workspace/ui_restyle/mockups/title540_final/layers/logo_cyan_jersey10.png').convert('RGBA')
menu=Image.open('/tmp/tl/menu.png'); ver=Image.open('/tmp/tl/ver.png').convert('RGBA')
c960=Image.open('/workspace/wt_android/assets_extra/title/title_bg_960x540.png').convert('RGB')
def view(vw,vh):
    x0=(1440-vw)//2; y0=(900-vh)//2; v=M.crop((x0,y0,x0+vw,y0+vh)); sx=(vw-960)//2; sy=(vh-540)//2
    v.alpha_composite(logo,(52+sx,24+sy)); v.alpha_composite(menu,(136+sx,146+sy)); v.alpha_composite(ver,(904+sx,503+sy)); return v,sx,sy
for vw,vh in [(1400,876),(1280,800),(1200,540)]:
    v,sx,sy=view(vw,vh); v.convert('RGB').resize((vw*2,vh*2),Image.NEAREST).save(f'title_wide_preview_{vw}x{vh}_x2.png')
# centre check: wide painting only, 960 box outlined; plus pixel identity
bgonly=M.convert('RGB'); a=np.array(bgonly.crop((240,180,1200,720))); b=np.array(c960); print('centre identical:',(a==b).all())
o=bgonly.copy(); d=ImageDraw.Draw(o); d.rectangle((240,180,1199,719),outline=(255,0,255)); d.rectangle((120,180,1319,719),outline=(0,255,255))
d.text((246,184),'960x540 centre (identical to title_bg_960x540)',fill=(255,0,255)); d.text((126,722),'1200x540 live painting, unchanged',fill=(0,255,255))
for vw,vh in [(1400,876),(1280,800),(1200,540)]:
    x0=(1440-vw)//2; y0=(900-vh)//2; d.rectangle((x0,y0,x0+vw-1,y0+vh-1),outline=(255,200,0))
d.text((8,8),'yellow: 1400x876 / 1280x800 / 1200x540 viewport crops (centred)',fill=(255,200,0))
o.save('title_wide_centre_check.png')
