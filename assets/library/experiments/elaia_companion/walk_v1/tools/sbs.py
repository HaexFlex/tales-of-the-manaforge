import math
from PIL import Image, ImageDraw
import sys; sys.path.insert(0, '/workspace/keeper_idle/tools')
from build_idles import GRASS
def sbs(clips, out):
    Ls = [sum(d) for _, _, d in clips]; T = 1
    for L in Ls: T = T * L // math.gcd(T, L)
    def idx(t, d):
        t %= sum(d); acc = 0
        for k, v in enumerate(d):
            acc += v
            if t < acc: return k
    cuts = set()
    for (_, _, d), L in zip(clips, Ls):
        for n in range(T // L):
            for k in range(len(d)): cuts.add(n * L + sum(d[:k]))
    cuts = sorted(cuts) + [T]; fr, du, cache = [], [], {}
    for t0, t1 in zip(cuts, cuts[1:]):
        key = tuple(idx(t0, d) for _, _, d in clips)
        if key not in cache:
            c = Image.new('RGB', (len(clips) * 294, 128 * 3 + 18), (24, 24, 24)); dr = ImageDraw.Draw(c)
            for n, ((name, F, d), i) in enumerate(zip(clips, key)):
                bb = Image.new('RGB', (96, 128), GRASS[:3]); cr = F[i].crop((16, 0, 112, 128)); bb.paste(cr, (0, 0), cr)
                c.paste(bb.resize((288, 384), Image.NEAREST), (n * 294, 18)); dr.text((n * 294 + 4, 3), f'{name} {i} ({d[i]}ms)', fill=(255, 255, 255))
            cache[key] = c
        if fr and fr[-1] is cache[key]: du[-1] += t1 - t0
        else: fr.append(cache[key]); du.append(t1 - t0)
    fr[0].save(out, save_all=True, append_images=fr[1:], duration=du, loop=0, disposal=1); return T, len(fr)
