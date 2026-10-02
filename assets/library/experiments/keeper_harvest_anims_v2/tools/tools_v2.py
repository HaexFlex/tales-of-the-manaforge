"""ONE fixed stone-axe and ONE fixed stone-pickaxe sprite, drawn at NATIVE scale (2x game) so they go through the same
NN x0.5 pipeline as the Keeper. Same haft length for both (head->grip 50 native = 25 game px; overall 42 game px,
about 1/3 of the 122 px Keeper). Colours are picked from the walk frames' own greys/browns (and are palette-mapped again
after the downscale)."""
import numpy as np
from PIL import Image, ImageDraw

OUT = (34, 30, 32); ST = [(89, 94, 87), (138, 136, 140), (175, 169, 157), (216, 221, 217)]      # dark, mid, light, edge
WD = [(82, 39, 17), (115, 61, 27), (153, 86, 44), (202, 136, 76)]                               # bind, dark, mid, light

def _mask(size, polys=(), rects=(), ellipses=()):
    m = Image.new("L", size, 0); d = ImageDraw.Draw(m)
    for p in polys: d.polygon(p, fill=255)
    for r in rects: d.rectangle(r, fill=255)
    for e in ellipses: d.ellipse(e, fill=255)
    return np.array(m) > 0

def _shift(m, dx, dy):
    p = np.pad(m, 4); h, w = m.shape
    return p[4 - dy:4 - dy + h, 4 - dx:4 - dx + w]

def _shade(a, m, cols, edge_mask=None):
    """mid fill, 2px light rim top-left, 2px dark rim bottom-right (= 1 game px each after NN x0.5)."""
    a[m] = (*cols[1], 255)
    tl = m & ~(_shift(m, 2, 2))
    br = m & ~(_shift(m, -2, -2))
    a[tl] = (*cols[2], 255); a[br] = (*cols[0], 255)
    if edge_mask is not None: a[m & edge_mask] = (*cols[3], 255)

def _outline(a, fill):
    ring = (_shift(fill, 2, 0) | _shift(fill, -2, 0) | _shift(fill, 0, 2) | _shift(fill, 0, -2) |
            _shift(fill, 1, 0) | _shift(fill, -1, 0) | _shift(fill, 0, 1) | _shift(fill, 0, -1)) & ~fill
    a[ring] = (*OUT, 255)

def axe():
    W, H = 56, 92
    a = np.zeros((H, W, 4), np.uint8)
    haft = _mask((W, H), rects=[(24, 10, 27, 87)])
    head = _mask((W, H), polys=[[(28, 8), (36, 5), (46, 2), (51, 6), (52, 20), (50, 32), (44, 30), (36, 24), (28, 22)]])
    poll = _mask((W, H), rects=[(16, 10, 23, 21)])
    edge = _mask((W, H), polys=[[(47, 3), (51, 6), (52, 20), (50, 31), (47, 30), (48, 18)]])
    a[haft] = (*WD[2], 255); a[haft & _mask((W, H), rects=[(26, 0, 27, H)])] = (*WD[1], 255); a[haft & _mask((W, H), rects=[(24, 0, 24, H)])] = (*WD[3], 255)
    a[haft & _mask((W, H), rects=[(0, 78, W, 87)])] = (*WD[1], 255)                    # worn grip
    _shade(a, head, ST, edge); _shade(a, poll, ST)
    for y in (11, 15, 19, 23): a[y:y + 2, 22:30][haft[y:y + 2, 22:30] | head[y:y + 2, 22:30] | poll[y:y + 2, 22:30]] = (*WD[0], 255)   # lashing
    _outline(a, haft | head | poll)
    return a, (26, 76)

def pick():
    W, H = 76, 92
    a = np.zeros((H, W, 4), np.uint8)
    haft = _mask((W, H), rects=[(36, 10, 39, 87)])
    head = _mask((W, H), polys=[[(4, 28), (12, 18), (24, 11), (38, 8), (52, 11), (64, 18), (72, 28), (66, 27), (56, 20), (46, 16), (38, 15), (30, 16), (20, 20), (10, 27)]])
    edge = _mask((W, H), polys=[[(4, 28), (8, 23), (11, 26)], [(72, 28), (68, 23), (65, 26)]])
    a[haft] = (*WD[2], 255); a[haft & _mask((W, H), rects=[(38, 0, 39, H)])] = (*WD[1], 255); a[haft & _mask((W, H), rects=[(36, 0, 36, H)])] = (*WD[3], 255)
    a[haft & _mask((W, H), rects=[(0, 78, W, 87)])] = (*WD[1], 255)
    _shade(a, head, ST, edge)
    for y in (12, 16): a[y:y + 2, 34:42][haft[y:y + 2, 34:42] | head[y:y + 2, 34:42]] = (*WD[0], 255)
    _outline(a, haft | head)
    return a, (38, 76)

AXE = axe()
PICK = pick()

if __name__ == "__main__":
    s = Image.new("RGBA", (140 * 4, 92 * 4), (96, 140, 70, 255))
    s.alpha_composite(Image.fromarray(AXE[0]).resize((56 * 4, 92 * 4), Image.NEAREST), (0, 0))
    s.alpha_composite(Image.fromarray(PICK[0]).resize((76 * 4, 92 * 4), Image.NEAREST), (60 * 4, 0))
    s.save("/workspace/keeper_anims/v2/check/tools_native_x4.png")
