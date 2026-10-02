"""Keeper harvest clips v2: derived from the live walk frame 0001 (native 170x256), re-posed with a cut-and-rotate rig,
brought to game size with the walk's own NN x0.5 pipeline, then palette-mapped to colours that exist in the walk frames.
9 frames x 100 ms per clip (= walk_south)."""
import json, math, random, sys
from pathlib import Path
import numpy as np
from PIL import Image, ImageDraw
sys.path.insert(0, "/workspace/keeper_anims/v2/tools")
from rig import N, NW, NH, BODY, ARM, CAPE, SHOULDER, GRIP, K, load, rot_nn, rot_pt, fit_game
from tools_v2 import AXE, PICK

V2 = Path("/workspace/keeper_anims/v2")
WAIST = 150                 # native row: everything above shifts for the body bob / squash (belt is ~134-140)
HOLD = 100

# ---------------------------------------------------------------- walk palette
def walk_palette():
    cols = set()
    for i in range(1, 10):
        a = np.array(load(K / f"keeper_walk_south_{i:04d}.png")); m = a[..., 3] > 0
        cols |= set(map(tuple, a[m][:, :3].tolist()))
    return np.array(sorted(cols), dtype=np.int32)
PAL = walk_palette()
PAL_SET = set(map(tuple, PAL.tolist()))
from scipy.spatial import cKDTree
_TREE = cKDTree(PAL)

def palette_map(img):
    a = np.array(img).copy()
    m = a[..., 3] > 0
    px = a[m][:, :3].astype(np.int32)
    _, idx = _TREE.query(px)
    a[m, :3] = PAL[idx].astype(np.uint8)
    a[~m] = 0                                   # fully transparent = (0,0,0,0): no hidden matte colour
    # semi-transparent pixels buried inside the silhouette (> 2 px from any transparent pixel; inherited from the native
    # painting, the walk has 0-6 per frame) are made opaque so semi alpha only exists on the soft outer edge
    al = a[..., 3]; h, w = al.shape
    pad = np.pad(al == 0, 2, constant_values=True); near = np.zeros((h, w), bool)
    for dy in range(-2, 3):
        for dx in range(-2, 3):
            near |= pad[2 + dy:2 + dy + h, 2 + dx:2 + dx + w]
    a[(al > 0) & (al < 255) & ~near, 3] = 255
    return Image.fromarray(a)

# ---------------------------------------------------------------- composition at native res
def shift_upper(a, dy):
    """body bob: rows above WAIST move by dy native px (dy>0 = squash down, rows at the waist are dropped/duplicated)."""
    if dy == 0: return a.copy()
    out = a.copy()
    up = a[:WAIST]
    if dy > 0:
        out[dy:WAIST] = up[:WAIST - dy]; out[:dy] = 0
    else:
        out[:WAIST + dy] = up[-dy:]; out[WAIST + dy:WAIST] = up[WAIST - 1]   # stretch: repeat the waist row
    return out

def on_canvas(arr, W, ox):
    c = np.zeros((NH, W, 4), np.uint8); c[:, ox:ox + arr.shape[1]] = arr; return c

def paste(dst, src, src_pt, dst_pt):
    """alpha-composite src (RGBA array) into dst so src_pt lands on dst_pt."""
    ox, oy = int(round(dst_pt[0] - src_pt[0])), int(round(dst_pt[1] - src_pt[1]))
    d = Image.fromarray(dst); tmp = Image.new("RGBA", d.size, (0, 0, 0, 0)); tmp.paste(Image.fromarray(src), (ox, oy), Image.fromarray(src))
    d.alpha_composite(tmp); return np.array(d)

def over(dst, src):
    d = Image.fromarray(dst); d.alpha_composite(Image.fromarray(src)); return np.array(d)

def rotated_tool(tool, ang):
    img, piv = tool
    pad = 80
    c = np.zeros((img.shape[0] + 2 * pad, img.shape[1] + 2 * pad, 4), np.uint8); c[pad:pad + img.shape[0], pad:pad + img.shape[1]] = img
    p = (piv[0] + pad, piv[1] + pad)
    return rot_nn(c, ang, p, up=4), p

def compose(pose, cw, tool=None, fx=None):
    """pose: dict(arm=deg CCW from hanging, tool=deg CCW from head-up, dy=native px, behind=bool, berry=bool)."""
    W = 2 * cw; ox = ((W - 170) // 2) & ~1
    dy = pose.get("dy", 0)
    body = on_canvas(shift_upper(BODY, dy), W, ox)
    cape = on_canvas(shift_upper(CAPE, dy), W, ox)
    sh = (SHOULDER[0] + ox, SHOULDER[1] + dy)
    arm = on_canvas(ARM, W, ox)
    arm = np.roll(arm, dy, axis=0) if dy else arm
    arm_r = rot_nn(arm, pose["arm"], sh, up=4)
    g = rot_pt((GRIP[0] + ox, GRIP[1] + dy), sh, pose["arm"])
    f = np.zeros((NH, W, 4), np.uint8)
    tr = None
    if tool is not None:
        tr, tp = rotated_tool(tool, pose["tool"])
        if pose.get("behind"): f = paste(f, tr, tp, g)
    f = over(f, body)
    if tool is not None and not pose.get("behind"): f = paste(f, tr, tp, g)
    f = over(f, arm_r)
    # cape over the shoulder joint only (the sleeve comes out from under the cape)
    yy, xx = np.mgrid[0:NH, 0:W]
    near = ((xx - sh[0]) ** 2 + (yy - sh[1]) ** 2) < 12 ** 2
    cj = cape.copy(); cj[~near] = 0
    f = over(f, cj)
    if pose.get("berry"): f = berry(f, g, pose["arm"])
    if fx: f = fx(f, pose, g, tool)
    return f, g

# ---------------------------------------------------------------- small FX at native res (2x2 native = 1 game px)
def blob(d, x, y, c, s=2):
    d.rectangle([x, y, x + s - 1, y + s - 1], fill=c)

def berry_pos(g, arm):
    t = math.radians(arm)                         # fingertips: a few px past the hand centre along the forearm
    return int(round(g[0] + 9 * math.sin(t))) & ~1, int(round(g[1] + 9 * math.cos(t))) & ~1

def berry(f, g, arm):
    im = Image.fromarray(f); d = ImageDraw.Draw(im)
    bx, by = berry_pos(g, arm)
    d.ellipse([bx - 6, by - 6, bx + 5, by + 5], fill=(28, 22, 94, 255))           # dark rim
    d.ellipse([bx - 4, by - 4, bx + 3, by + 3], fill=(69, 59, 130, 255))          # indigo berry (walk colour)
    blob(d, bx - 2, by - 4, (195, 220, 216, 255)); blob(d, bx, by - 8, (60, 120, 40, 255)); blob(d, bx + 2, by - 8, (90, 160, 60, 255))
    return np.array(im)

def burst(f, center, kind, phase, seed):
    im = Image.fromarray(f); d = ImageDraw.Draw(im); rnd = random.Random(seed)
    cx, cy = center
    if kind == "chips":
        cols = [(246, 214, 160, 255), (214, 150, 84, 255), (120, 66, 30, 255)]
        n, r0, r1, a0, a1 = (6, 6, 16, 70, 170) if phase == 0 else (6, 18, 34, 60, 175)
        if phase == 0:          # impact flash
            for k in range(-6, 7, 2): blob(d, cx + k, cy, (255, 246, 214, 255)); blob(d, cx, cy + k, (255, 246, 214, 255))
    elif kind == "sparks":
        cols = [(255, 240, 170, 255), (255, 190, 90, 255), (170, 166, 170, 255), (110, 106, 112, 255)]
        n, r0, r1, a0, a1 = (8, 6, 18, 25, 155) if phase == 0 else (7, 16, 34, 20, 160)
        if phase == 0:
            for k in range(-6, 7, 2): blob(d, cx + k, cy, (255, 246, 200, 255)); blob(d, cx, cy + k, (255, 246, 200, 255))
    else:  # pop
        cols = [(255, 252, 240, 255), (196, 210, 255, 255), (90, 160, 60, 255)]
        n, r0, r1, a0, a1 = (6, 8, 16, 0, 360) if phase == 0 else (5, 14, 24, 0, 360)
        if phase == 0:
            for k in range(-6, 7, 2): blob(d, cx + k, cy, cols[0]); blob(d, cx, cy + k, cols[0])
    for i in range(n):
        a = math.radians(rnd.uniform(a0, a1)); r = rnd.uniform(r0, r1)
        x = int(cx + r * math.cos(a)) & ~1; y = int(cy - r * math.sin(a) + (r * r / 60 if phase else 0)) & ~1
        c = cols[i % len(cols)]
        blob(d, x, y, c, 4 if (kind == "chips" and i % 2 == 0) else 2)
        if kind == "chips": blob(d, x, y + 2, cols[2], 2)
    return np.array(im)

def tool_head(g, tool, ang, reach=None):
    """native position of the striking edge: a point up the haft from the grip, rotated with the tool."""
    img, piv = tool
    L = reach if reach else piv[1] - 10
    return rot_pt((g[0], g[1] - L), g, ang)

# ---------------------------------------------------------------- clips (9 frames x 100 ms)
CLIPS = {
    "chop_south": dict(cw=192, tool="axe", target="tree", strike=7, fx="chips", poses=[
        dict(name="ready",    arm=10,  tool=-172, dy=0),
        dict(name="lift",     arm=55,  tool=-70,  dy=0),
        dict(name="raise",    arm=110, tool=-15,  dy=0),
        dict(name="windup",   arm=120, tool=28,   dy=0),
        dict(name="cocked",   arm=124, tool=50,   dy=-2),
        dict(name="swing",    arm=122, tool=-30,  dy=0),
        dict(name="impact",   arm=100, tool=-62,  dy=2, fx=0),
        dict(name="bite",     arm=96,  tool=-68,  dy=2, fx=1),
        dict(name="recover",  arm=40,  tool=-150, dy=0),
    ]),
    "mine_south": dict(cw=192, tool="pick", target="rock", strike=7, fx="sparks", poses=[
        dict(name="ready",    arm=10,  tool=-172, dy=0),
        dict(name="lift",     arm=65,  tool=-40,  dy=0),
        dict(name="raise",    arm=112, tool=-10,  dy=0),
        dict(name="windup",   arm=130, tool=22,   dy=0),
        dict(name="cocked",   arm=148, tool=48,   dy=-2, behind=True),
        dict(name="swing",    arm=115, tool=-75,  dy=0),
        dict(name="impact",   arm=48,  tool=-152, dy=2, fx=0),
        dict(name="rebound",  arm=56,  tool=-138, dy=2, fx=1),
        dict(name="recover",  arm=28,  tool=-165, dy=0),
    ]),
    "pluck_south": dict(cw=128, tool=None, target="bush", strike=6, fx="pop", poses=[
        dict(name="ready",    arm=6,   dy=0),
        dict(name="reach1",   arm=28,  dy=0),
        dict(name="reach2",   arm=52,  dy=0),
        dict(name="grab",     arm=68,  dy=0),
        dict(name="grip",     arm=70,  dy=2),
        dict(name="pluck",    arm=60,  dy=-2, berry=True, fx=0),
        dict(name="bring",    arm=38,  dy=0, berry=True, fx=1),
        dict(name="hold",     arm=16,  dy=0, berry=True),
        dict(name="stow",     arm=4,   dy=0),
    ]),
}
TOOLS = {"axe": AXE, "pick": PICK, None: None}

def build_frames(name):
    c = CLIPS[name]; tool = TOOLS[c["tool"]]; frames = []; info = []
    for p in c["poses"]:
        hit = {}
        def fx(f, pose, g, tool, _c=c, _hit=hit):
            if _c["fx"] == "pop":
                bx, by = berry_pos(g, pose["arm"]); _hit["p"] = (bx + 8, by - 6)
            elif tool is not None:
                _hit["p"] = tuple(int(v) for v in tool_head(g, tool, pose["tool"], reach=(56 if _c["tool"] == "axe" else 64)))
            if "fx" not in pose: return f
            if _c["fx"] == "pop":
                bx, by = berry_pos(g, pose["arm"]); return burst(f, (bx + 8, by - 6), "pop", pose["fx"], 5 + pose["fx"])
            ang = pose["tool"]
            hp = tool_head(g, tool, ang, reach=(56 if _c["tool"] == "axe" else 64))
            return burst(f, (int(hp[0]) & ~1, int(hp[1]) & ~1), _c["fx"], pose["fx"], 11 + pose["fx"])
        nat, g = compose(p, c["cw"], tool, fx)
        game = palette_map(fit_game(nat, c["cw"]))
        frames.append(game); hp = hit.get("p", g)
        info.append({"pose": p["name"], "grip_game": [round(g[0] / 2, 1), round(g[1] / 2, 1)], "impact_game": [int(hp[0] // 2), int(hp[1] // 2)]})
    return frames, info

if __name__ == "__main__":
    out = V2 / "work"; out.mkdir(exist_ok=True)
    for name in (sys.argv[1:] or CLIPS):
        fr, info = build_frames(name)
        cw = CLIPS[name]["cw"]
        s = Image.new("RGBA", (cw * 9, 128))
        for i, f in enumerate(fr): s.paste(f, (i * cw, 0))
        s.save(out / f"{name}_strip.png")
        bg = Image.new("RGBA", s.size, (96, 140, 70, 255)); bg.alpha_composite(s)
        bg.resize((s.width * 2, 256), Image.NEAREST).save(out / f"{name}_strip_x2_check.png")
        print(name, [i["pose"] + str(i["grip_game"]) for i in info])
