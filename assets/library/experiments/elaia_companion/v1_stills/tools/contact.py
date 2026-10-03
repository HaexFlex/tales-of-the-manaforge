from PIL import Image, ImageDraw
A = '/workspace/keeper_idle/repo/assets/library/experiments/keeper_idle_4dir/v3_stills_8dir/option_a/keeper_still_s.png'
cells = [('Elaia S', 'stills/elaia_still_s.png'), ('Elaia N', 'stills/elaia_still_n.png'), ('Elaia E (mirror of W)', 'stills/elaia_still_e.png'),
         ('Elaia W (sheet1 profile L1)', 'stills/elaia_still_w.png'), ('Keeper S optA (scale)', A)]
S = 3; c = Image.new('RGB', (len(cells) * 128 * S, 128 * S + 18), (24, 24, 24)); d = ImageDraw.Draw(c)
for i, (t, p) in enumerate(cells):
    bg = Image.new('RGBA', (128, 128), (78, 128, 52, 255)); bg.alpha_composite(Image.open(p).convert('RGBA'))
    big = bg.convert('RGB').resize((128 * S, 128 * S), Image.NEAREST); dd = ImageDraw.Draw(big)
    dd.line([(0, 124 * S), (128 * S, 124 * S)], fill=(230, 220, 60))
    c.paste(big, (i * 128 * S, 18)); d.text((i * 128 * S + 4, 3), t, fill=(255, 255, 255))
c.save('stills/elaia_stills_contact_x3.png'); print(c.size)
