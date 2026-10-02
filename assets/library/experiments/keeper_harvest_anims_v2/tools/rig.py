"""v2 rig: the Keeper is cut from the LIVE walk frame 0001 (== idle) at NATIVE 170x256 resolution, re-posed there,
and brought to game size with exactly the walk pipeline (NN x0.5 + paste-with-mask, tools/slice_haex_inbox.py fit_keeper_128)."""
import math
from pathlib import Path
import numpy as np
from PIL import Image, ImageDraw

REPO = Path("/workspace/keeper_anims/repo")
K = REPO / "assets/art/keeper"
NATIVE = K / "native/keeper_walk_south_0001_256.png"

def load(p):
    return Image.open(p).convert("RGBA")

N = np.array(load(NATIVE))                      # 256 rows x 170 cols
NH, NW = N.shape[:2]

# ---- viewer-right sleeve + hand (native px) -------------------------------------------------
ARM_POLY = [(108, 114), (120, 114), (125, 115), (130, 124), (135, 138), (138, 150), (134, 158), (132, 168), (128, 175),
            (118, 175), (115, 163), (112, 152), (109, 136), (107, 120)]
SHOULDER = (115, 113)          # rotation pivot (just under the cape trim)
GRIP = (124, 164)              # hand centre
CAPE_TOP = 116                 # body pixels above this row (cape / collar) are drawn OVER the arm

def poly_mask(poly, shape=(NH, NW)):
    m = Image.new("L", (shape[1], shape[0]), 0); ImageDraw.Draw(m).polygon(poly, fill=255)
    return np.array(m) > 0

def is_blue(px):
    r, g, b = int(px[0]), int(px[1]), int(px[2])
    return px[3] == 255 and b > 90 and b > r + 40 and b > g + 30

def coat_span(row):
    """inner..outer x of the blue coat panel right of the tunic in a skirt row."""
    xs = [x for x in range(100, NW) if is_blue(row[x])]
    return (xs[0], xs[-1]) if xs else (110, 130)

def cut():
    arm_m = poly_mask(ARM_POLY) & (N[..., 3] > 0)
    arm = N.copy(); arm[~arm_m] = 0
    body = N.copy(); body[arm_m] = 0
    # rebuild the coat side the sleeve covered: straight coat edge from the cape corner to the skirt edge, filled by
    # re-mapping a skirt row (rows 180-199) across the hole so the fabric shading and the dark outer edge carry over
    top, bot = (121, 110), (127, 179)
    def edge_x(y):
        return int(round(top[0] + (bot[0] - top[0]) * (y - top[1]) / (bot[1] - top[1])))
    for y in range(top[1], bot[1] + 1):
        ex = edge_x(y)
        hole = [x for x in range(100, NW) if arm_m[y, x] or (body[y, x, 3] == 0 and x <= ex + 2)]
        for x in range(ex + 3, NW):
            body[y, x] = 0
        if not hole:
            continue
        # inner limit = first non-hole blue pixel left of the hole (the panel that is still there)
        x0 = min(hole); x1 = ex + 2
        sy = 180 + (y - top[1]) % 20
        s0, s1 = coat_span(N[sy])
        for x in range(x0, x1 + 1):
            if not (arm_m[y, x] or body[y, x, 3] == 0):
                continue
            if x == x1 - 1:
                body[y, x] = N[sy, s1 + 1]; continue                    # dark outline of the skirt edge
            if x == x1:
                body[y, x] = N[sy, s1 + 2]; continue                    # its soft outer pixel
            t = (x - x0) / max(1, x1 - 2 - x0)
            sx = int(round(s0 + (s1 - s0) * (0.35 + 0.65 * t)))          # skip the skirt's inner trim, keep its shading
            body[y, x] = N[sy, sx]
    return body, arm, arm_m

BODY, ARM, ARM_M = cut()
CAPE = BODY.copy(); CAPE[CAPE_TOP:] = 0; CAPE[:, :98] = 0       # only the right shoulder cape

def rot_nn(img, angle, pivot, up=8):
    """RotSprite-lite at native res: NN upscale, rotate about pivot, sample cell centres back down. angle CCW (deg)."""
    im = Image.fromarray(img) if isinstance(img, np.ndarray) else img
    w, h = im.size
    big = im.resize((w * up, h * up), Image.NEAREST)
    r = big.rotate(angle, resample=Image.NEAREST, center=(pivot[0] * up + up / 2, pivot[1] * up + up / 2))
    return np.array(r)[up // 2::up, up // 2::up]

def rot_pt(p, piv, ang):
    t = math.radians(ang); dx, dy = p[0] - piv[0], p[1] - piv[1]
    return (piv[0] + dx * math.cos(t) + dy * math.sin(t), piv[1] - dx * math.sin(t) + dy * math.cos(t))

def fit_game(native_canvas, cw):
    """walk pipeline: NN x0.5, paste-with-mask onto a transparent cw x 128 canvas, bottom-aligned, centred."""
    im = Image.fromarray(native_canvas)
    s = im.resize((im.width // 2, 128), Image.NEAREST)
    c = Image.new("RGBA", (cw, 128), (0, 0, 0, 0)); c.paste(s, ((cw - s.width) // 2, 128 - s.height), s)
    return c
