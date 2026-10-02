"""combined preview: live idle_south | v1 S | v2 S N E W, 12 frames x 150 ms, x1 and x2 (x2 labelled)."""
import sys
from pathlib import Path
from PIL import Image, ImageDraw
R = Path('/workspace/keeper_idle'); V1 = R / 'repo/assets/library/experiments/keeper_idle_4dir'
F = Path(sys.argv[1]); GR = (78, 128, 52, 255)
live = Image.open(R / 'repo/assets/art/keeper/keeper_idle_south_0000.png').convert('RGBA')
cols = [('live idle_south', lambda i: live), ('v1 S', lambda i: Image.open(V1 / f'idle_south/keeper_idle_south_{i:04d}.png'))]
for d, n in [('S', 'south'), ('N', 'north'), ('E', 'east'), ('W', 'west')]:
    cols.append((f'v2 {d}', (lambda n: lambda i: Image.open(F / f'idle_{n}/keeper_idle_{n}_{i:04d}.png'))(n)))
def frames(scale, labels):
    out = []
    for i in range(1, 13):
        c = Image.new('RGBA', (128 * len(cols), 140), GR)
        for j, (_, fn) in enumerate(cols): c.alpha_composite(fn(i).convert('RGBA'), (j * 128, 10))
        if scale != 1: c = c.resize((c.width * scale, c.height * scale), Image.NEAREST)
        if labels:
            d = ImageDraw.Draw(c)
            for j, (t, _) in enumerate(cols):
                t = f'{t}  f{i}'; x = j * 128 * scale + 4; d.rectangle([x, 2, x + 6 * len(t) + 4, 14], fill=(0, 0, 0, 170)); d.text((x + 2, 3), t, fill=(255, 255, 255, 255))
        out.append(c.convert('RGB').convert('P', palette=Image.ADAPTIVE, colors=255))
    return out
for sc, lab, name in [(1, False, 'keeper_idle_4dir_v2_compare.gif'), (2, True, 'keeper_idle_4dir_v2_compare_x2.gif')]:
    fr = frames(sc, lab); fr[0].save(F / name, save_all=True, append_images=fr[1:], duration=150, loop=0, disposal=2)
    print(name, fr[0].size)
