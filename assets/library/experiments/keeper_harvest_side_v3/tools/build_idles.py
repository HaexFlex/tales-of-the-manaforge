#!/usr/bin/env python3
"""Build the 4-direction Keeper idles from ONE ingested turnaround candidate (work/<cand>/key_{S,N,E,W}.png).
1. one shared ~48-colour palette from the 4 keys (median cut + nearest mapping), applied to the keys BEFORE deriving,
   so every frame uses exactly those colours (nothing can flicker colour-wise)
2. per direction 12 frames x 150 ms (1.8 s calm breath): upper body rises 1 px, head follows one frame later,
   hair tips and coat hem sway 1 px on later phases, one blink frame on S/E/W
3. frames / strip / meta / GIF x1 x2, combined GIF with the live idle_south, contact sheet, check_frames report."""
import argparse, colorsys, json, shutil, sys
from pathlib import Path
import numpy as np
from PIL import Image, ImageDraw
from scipy.spatial import cKDTree
from scipy import ndimage

ROOT = Path("/workspace/keeper_idle"); REPO = ROOT / "repo"; K = REPO / "assets/art/keeper"
DIRS = ["S", "N", "E", "W"]; NAMES = {"S": "south", "N": "north", "E": "east", "W": "west"}
NF, HOLD = 12, 150
# per-frame offsets. Chosen by a small search (see NOTES): every one of the 12 frames is a distinct pose and exactly ONE
# channel changes by 1 px between consecutive frames (incl. 12 -> 1), so the loop is seamless and never "pops".
UPPER = [0, 0, -1, -1, -1, -1, -1, -1, 0, 0, 0, 0]          # chest/shoulders/arms rise 1 px on the in-breath (6 frames = 0.9 s)
HEAD  = [0, 0, 0, -1, -1, -1, -1, -1, -1, 0, 0, 0]          # head follows one frame later
HAIR  = [1, 1, 1, 1, 0, 0, -1, -1, -1, -1, 0, 0]            # hair tips drift +-1 px (x), slow pendulum
HEM   = [0, 1, 1, 1, 1, 0, 0, -1, -1, -1, -1, 0]            # coat hem follows the hair one frame later
BLINK = 9                                                  # one closed-eye frame (S/E/W only)

def load(p): return np.array(Image.open(p).convert("RGBA"))

# ---------------------------------------------------------------- defringe
def magenta_tint(px):
    """hue 280-340 deg with some saturation = magenta key contamination (the design has no purple/pink)."""
    px = px.astype(float); mx = px.max(-1); mn = px.min(-1); c = mx - mn
    r, g, b = px[..., 0], px[..., 1], px[..., 2]
    with np.errstate(divide="ignore", invalid="ignore"):
        h = np.where(mx == r, ((g - b) / c) % 6, np.where(mx == g, (b - r) / c + 2, (r - g) / c + 4)) * 60
        sat = np.where(mx > 0, c / mx, 0)
    return (c > 10) & (sat > 0.15) & (h >= 280) & (h <= 340)

def defringe(k):
    """recolour magenta-tinted (key-contaminated) pixels: keep their brightness, take the hue of the
    median non-tinted opaque neighbours (5x5). Returns (new key, count)."""
    a = k.copy(); op = a[..., 3] > 0; bad = op & magenta_tint(a[..., :3]); n = int(bad.sum())
    good = op & ~bad
    for y, x in zip(*np.nonzero(bad)):
        y0, y1, x0, x1 = max(0, y - 2), min(128, y + 3), max(0, x - 2), min(128, x + 3)
        nb = a[y0:y1, x0:x1][good[y0:y1, x0:x1]][:, :3].astype(float)
        if not len(nb): a[y, x, :3] = a[y, x, :3].mean(); continue
        ref = np.median(nb, 0); lum = a[y, x, :3].astype(float).mean(); rl = max(ref.mean(), 1)
        a[y, x, :3] = np.clip(ref * min(lum / rl, 1.0), 0, 255).astype(np.uint8)
    return a, n

# ---------------------------------------------------------------- palette
def to_lab(rgb):
    c = rgb.astype(float) / 255; c = np.where(c > 0.04045, ((c + 0.055) / 1.055) ** 2.4, c / 12.92)
    M = np.array([[0.4124, 0.3576, 0.1805], [0.2126, 0.7152, 0.0722], [0.0193, 0.1192, 0.9505]])
    xyz = c @ M.T / np.array([0.9505, 1.0, 1.089])
    f = np.where(xyz > 0.008856, np.cbrt(xyz), 7.787 * xyz + 16 / 116)
    return np.stack([116 * f[:, 1] - 16, 500 * (f[:, 0] - f[:, 1]), 200 * (f[:, 1] - f[:, 2])], 1)

def hue_group(px):
    """material groups of the Keeper: 0 dark/outline, 1 hair+tunic green, 2 coat blue, 3 rune cyan, 4 skin, 5 gold trim, 6 brown leather/cloth, 7 light/neutral"""
    p = px.astype(float); mx = p.max(1); mn = p.min(1); c = mx - mn
    with np.errstate(divide="ignore", invalid="ignore"):
        r, g, b = p.T
        h = np.where(mx == r, ((g - b) / c) % 6, np.where(mx == g, (b - r) / c + 2, (r - g) / c + 4)) * 60
    h = np.nan_to_num(h); sat = np.where(mx > 0, c / np.maximum(mx, 1), 0)
    gr = np.full(len(p), 7)
    gr[(h >= 70) & (h < 165)] = 1; gr[(h >= 205) & (h < 280)] = 2; gr[(h >= 165) & (h < 205)] = 3
    warm = (h < 70) | (h >= 330)
    gr[warm & (mx >= 170) & (sat < 0.55)] = 4
    gr[warm & (mx >= 130) & (sat >= 0.55)] = 5
    gr[warm & ~np.isin(gr, [4, 5])] = 6
    gr[mx < 45] = 0; gr[(c < 18) & (mx >= 45)] = 7
    return gr

def shared_palette(keys, n=48):
    """material-aware palette: k-means in Lab per material group, colours allocated ~ sqrt(pixel count)
    (min 2), so small but important materials (eyes/skin/rune glow) keep their own ramps instead of being
    swallowed by the big coat/hair areas like plain median cut does."""
    from scipy.cluster.vq import kmeans2
    px = np.concatenate([k[k[..., 3] > 0][:, :3] for k in keys]).astype(np.int32)
    gr = hue_group(px); groups = [g for g in range(8) if (gr == g).sum() >= 4]
    w = np.array([np.sqrt((gr == g).sum()) for g in groups]); alloc = np.maximum(2, np.round(w / w.sum() * n)).astype(int)
    while alloc.sum() > n: alloc[np.argmax(alloc)] -= 1
    while alloc.sum() < n: alloc[np.argmax(w / alloc)] += 1
    pal = []
    rng = np.random.default_rng(7)
    for g, k in zip(groups, alloc):
        sub = px[gr == g]; uniq = np.unique(sub, axis=0); k = int(min(k, len(uniq)))
        lab = to_lab(sub)
        cent, lab_i = kmeans2(lab, k, minit="++", seed=rng, iter=30)
        for j in range(k):
            m = lab_i == j
            if m.any(): pal.append(np.median(sub[m], 0).round().astype(int))  # real-ish colour of the cluster
    pal = np.unique(np.array(pal, np.int32), axis=0)
    return pal

def apply_palette(img, pal):
    a = img.copy(); m = a[..., 3] > 0
    _, idx = cKDTree(to_lab(pal)).query(to_lab(a[m][:, :3].astype(np.int32))); a[m, :3] = pal[idx]; a[~m] = 0
    return a

# ---------------------------------------------------------------- regions
def is_blue(px):
    r, g, b = px[..., 0].astype(int), px[..., 1].astype(int), px[..., 2].astype(int)
    return (b > 80) & (b > r + 35) & (b > g + 20)

def is_trim(px):
    r, g, b = px[..., 0].astype(int), px[..., 1].astype(int), px[..., 2].astype(int)
    return (r > 150) & (g > 80) & (b < 90) & (r > g + 30)

def regions(k):
    a = k[..., 3] > 0
    rows = np.nonzero(a.any(1))[0]; top, sole = int(rows.min()), int(rows.max()); h = sole - top + 1
    coat = is_blue(k) & a
    crow = np.nonzero(coat.any(1))[0]
    hem_bot = int(crow.max()) if len(crow) else int(top + 0.85 * h)
    return {"top": top, "sole": sole, "h": h, "head": int(top + 0.34 * h), "chest": int(top + 0.58 * h),
            "tips": int(top + 0.07 * h), "hem0": hem_bot - 3, "hem1": hem_bot}

def find_eyes(k, R):
    """eye candidates: small dark/iris blobs inside the skin of the face (rows 18-34% of the height)."""
    y0, y1 = R["top"] + int(0.17 * R["h"]), R["top"] + int(0.34 * R["h"])
    sub = k[y0:y1].astype(int)
    hsv = np.zeros(sub.shape[:2] + (3,))
    for y in range(sub.shape[0]):
        for x in range(sub.shape[1]):
            if sub[y, x, 3]: hsv[y, x] = colorsys.rgb_to_hsv(*(sub[y, x, :3] / 255))
    skin = (sub[..., 3] > 0) & (hsv[..., 0] > 0.02) & (hsv[..., 0] < 0.12) & (hsv[..., 1] > 0.15) & (hsv[..., 1] < 0.65) & (hsv[..., 2] > 0.6)
    skin_rows = skin.any(1)
    dark = (sub[..., 3] > 0) & ~skin & (hsv[..., 2] < 0.75)
    # must be enclosed by skin left/right within 4 px (inside the face)
    cand = np.zeros_like(dark)
    for y in range(dark.shape[0]):
        xs = np.nonzero(skin[y])[0]
        if len(xs) < 3: continue
        cand[y, xs.min():xs.max() + 1] = dark[y, xs.min():xs.max() + 1]
    lab, n = ndimage.label(cand)
    eyes = []
    for i, s in enumerate(ndimage.find_objects(lab), 1):
        hh, ww = s[0].stop - s[0].start, s[1].stop - s[1].start
        size = (lab[s] == i).sum()
        if 2 <= size <= 16 and hh <= 5 and ww <= 5:
            eyes.append([s[1].start, s[0].start + y0, s[1].stop - 1, s[0].stop - 1 + y0, int(size)])
    eyes.sort(key=lambda e: -e[4])
    return [e[:4] for e in eyes[:2]]

# ---------------------------------------------------------------- frame derivation
def shift_rows(k, R, ub, hd):
    out = np.zeros_like(k)
    c0, h0 = R["chest"], R["head"]
    out[c0:] = k[c0:]                                       # legs/boots/lower coat never move
    for r in range(h0, c0):                                 # chest segment
        if 0 <= r + ub < 128: out[r + ub] = k[r]
    if ub < 0: out[c0 - 1] = k[c0 - 1]                      # stretch: repeat the waist row
    for r in range(0, h0):                                  # head segment (on top)
        if 0 <= r + hd < 128: out[r + hd] = k[r]
    if hd < ub: out[h0 + hd: h0 + ub] = k[h0 - 1]           # neck stretch when the head leads
    return out

def sway_rows(f, y0, y1, dx, mask_fn=None):
    if dx == 0: return f
    out = f.copy()
    for y in range(max(0, y0), min(128, y1 + 1)):
        row = f[y]; m = row[:, 3] > 0 if mask_fn is None else (mask_fn(row) & (row[:, 3] > 0))
        xs = np.nonzero(m)[0]
        if not len(xs): continue
        runs = np.split(xs, np.nonzero(np.diff(xs) > 1)[0] + 1)
        for run in runs:
            a, b = run[0], run[-1]
            seg = row[a:b + 1].copy()
            if dx > 0:
                out[y, a + 1:b + 2] = seg[: len(seg) - 0][:min(len(seg), 128 - a - 1)]
                out[y, a] = row[a - 1] if a > 0 and row[a - 1, 3] > 0 and not m[a - 1] else 0
            else:
                out[y, max(0, a - 1):b] = seg[max(0, 1 - a):]
                out[y, b] = row[b + 1] if b < 127 and row[b + 1, 3] > 0 and not m[b + 1] else 0
    return out

def coat_mask(row):
    return is_blue(row) | is_trim(row) | ((row[:, :3].max(1) < 70) & (row[:, 3] > 0))

def blink(f, eyes, pal, dy):
    out = f.copy()
    darkest = pal[np.argmin(pal.sum(1))]
    for e in eyes:
        x0, y0, x1, y1 = e[:4]; lid = (e[4] if len(e) > 4 else y1 - 1) + dy
        y0 += dy; y1 += dy
        below = out[min(127, y1 + 1), x0:x1 + 1]
        skin = below[below[:, 3] > 0][:, :3]
        sk = np.median(skin, 0).astype(int) if len(skin) else pal[np.argmax(pal.sum(1))]
        _, i = cKDTree(pal).query(sk); sk = pal[i]
        out[y0:y1 + 1, x0:x1 + 1, :3] = sk
        out[lid, x0:x1 + 1, :3] = darkest                    # closed lid line
    return out

def derive(key, R, d, pal, eyes):
    frames = []
    for t in range(NF):
        f = shift_rows(key, R, UPPER[t], HEAD[t])
        f = sway_rows(f, R["top"] + HEAD[t], R["tips"] + HEAD[t], HAIR[t] * (1 if d != "W" else -1))
        f = sway_rows(f, R["hem0"], R["hem1"], HEM[t] * (1 if d != "W" else -1), coat_mask)
        if t == BLINK and d != "N" and eyes: f = blink(f, eyes, pal, HEAD[t])
        f[f[..., 3] == 0] = 0
        frames.append(f)
    return frames

# ---------------------------------------------------------------- outputs
GRASS = (78, 128, 52, 255)
def gif(frames, path, scale=1, bg=GRASS, durations=None):
    out = []
    for f in frames:
        im = Image.fromarray(f) if isinstance(f, np.ndarray) else f
        b = Image.new("RGBA", im.size, bg); b.alpha_composite(im)
        if scale != 1: b = b.resize((b.width * scale, b.height * scale), Image.NEAREST)
        out.append(b.convert("RGB").convert("P", palette=Image.ADAPTIVE, colors=255))
    out[0].save(path, save_all=True, append_images=out[1:], duration=durations or HOLD, loop=0, disposal=2)

def label(img, x, y, t):
    d = ImageDraw.Draw(img); d.rectangle([x, y, x + 6 * len(t) + 4, y + 12], fill=(0, 0, 0, 170)); d.text((x + 2, y + 1), t, fill=(255, 255, 255, 255))

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--cand", required=True); ap.add_argument("--mirror-west", action="store_true", help="W = mirror of E")
    ap.add_argument("--mirror-east", action="store_true", help="E = mirror of W")
    ap.add_argument("--colors", type=int, default=48); ap.add_argument("--out", default=str(ROOT / "final"))
    ap.add_argument("--eyes", default=None, help="json {dir: [[x0,y0,x1,y1],..]} overriding auto eye detection")
    a0 = ap.parse_args()
    W = ROOT / "work" / a0.cand
    keys = {d: load(W / f"key_{d}.png") for d in DIRS}
    made = {d: "from the sheet" for d in DIRS}
    if a0.mirror_west: made["W"] = "mirror of E (every derived E frame flipped horizontally)"
    if a0.mirror_east: made["E"] = "mirror of W (every derived W frame flipped horizontally)"
    src = {d: ("E" if (d == "W" and a0.mirror_west) else "W" if (d == "E" and a0.mirror_east) else d) for d in DIRS}
    if a0.mirror_west or a0.mirror_east: keys = {d: keys[d] for d in DIRS if src[d] == d}
    defr = {}
    for d in keys: keys[d], defr[d] = defringe(keys[d])
    pal = shared_palette(list(keys.values()), a0.colors)
    keys = {d: apply_palette(k, pal) for d, k in keys.items()}
    eyes_over = json.loads(Path(a0.eyes).read_text()) if a0.eyes else {}
    OUT = Path(a0.out)
    if OUT.exists(): shutil.rmtree(OUT)
    OUT.mkdir(parents=True)
    (OUT / "palette.json").write_text(json.dumps({"colors": pal.tolist(), "n": len(pal), "source": f"median cut of the 4 keys of {a0.cand}"}, indent=0))
    sw = Image.new("RGB", (len(pal) * 12, 12))
    for i, c in enumerate(pal): ImageDraw.Draw(sw).rectangle([i * 12, 0, i * 12 + 11, 11], fill=tuple(int(v) for v in c))
    sw.resize((sw.width * 2, 24), Image.NEAREST).save(OUT / "palette.png")
    allf = {}
    info = {}
    order = [d for d in DIRS if src[d] == d] + [d for d in DIRS if src[d] != d]
    for d in order:
        if src[d] == d:
            R = regions(keys[d]); eyes = eyes_over.get(d) if d in eyes_over else (find_eyes(keys[d], R) if d != "N" else [])
            fr = derive(keys[d], R, d, pal, eyes)
        else:
            s_ = src[d]; R = dict(info[s_]["regions"]); fr = [np.ascontiguousarray(f[:, ::-1]) for f in allf[s_]]
            eyes = [[127 - e[2], e[1], 127 - e[0], e[3]] + list(e[4:]) for e in info[s_]["eyes"]]
        allf[d] = fr
        nm = NAMES[d]; dd = OUT / f"idle_{nm}"; dd.mkdir()
        for i, f in enumerate(fr, 1): Image.fromarray(f).save(dd / f"keeper_idle_{nm}_{i:04d}.png")
        strip = Image.new("RGBA", (128 * NF, 128))
        for i, f in enumerate(fr): strip.paste(Image.fromarray(f), (i * 128, 0))
        strip.save(dd / f"keeper_idle_{nm}.png")
        meta = {"clip": f"idle_{nm}", "status": "experiment - not wired into the game", "canvas": [128, 128], "anchor": "feet_center",
                "anchor_px": [64, 128], "sprite_offset": [-64, -128], "filter": "nearest", "frames": NF, "hold_ms": HOLD, "loop_ms": NF * HOLD,
                "loop": True, "strip": f"keeper_idle_{nm}.png", "layout": "horizontal",
                "files": [f"keeper_idle_{nm}_{i:04d}.png" for i in range(1, NF + 1)],
                "palette": "../palette.json", "source": f"{a0.cand} key_{d} ({made[d]})",
                "motion": {"upper_dy": UPPER, "head_dy": HEAD, "hair_dx": HAIR, "hem_dx": HEM, "blink_frame": (BLINK + 1) if d != "N" and eyes else None},
                "regions": R, "eyes": eyes}
        (dd / f"keeper_idle_{nm}.json").write_text(json.dumps(meta, indent=2))
        gif(fr, dd / f"keeper_idle_{nm}.gif", 1); gif(fr, dd / f"keeper_idle_{nm}_x2.gif", 2)
        info[d] = {"regions": R, "eyes": eyes, "made": made[d], "defringed_px": defr.get(src[d])}
    # combined: live idle_south | S N E W  (+ live walk for scale)
    live = load(K / "keeper_idle_south_0000.png")
    cmb = []
    for t in range(NF):
        sc = Image.new("RGBA", (128 * 5, 140), GRASS)
        sc.alpha_composite(Image.fromarray(live), (0, 10))
        for j, d in enumerate(DIRS, 1): sc.alpha_composite(Image.fromarray(allf[d][t]), (j * 128, 10))
        cmb.append(sc)
    gif(cmb, OUT / "keeper_idle_4dir.gif", 1)
    big = []
    for t, sc in enumerate(cmb):
        b = sc.resize((sc.width * 2, sc.height * 2), Image.NEAREST)
        for j, t_ in enumerate(["live idle_south", "S", "N", "E", "W"]): label(b, j * 256 + 4, 2, t_ + f"  f{t + 1}")
        big.append(b)
    gif(big, OUT / "keeper_idle_4dir_x2.gif", 1)
    # contact sheet x2: rows S N E W, 12 columns, + live idle in front
    sheet = Image.new("RGBA", (128 * (NF + 1), 128 * 4), GRASS)
    for r, d in enumerate(DIRS):
        sheet.alpha_composite(Image.fromarray(live), (0, r * 128))
        for i, f in enumerate(allf[d]): sheet.alpha_composite(Image.fromarray(f), ((i + 1) * 128, r * 128))
    b = sheet.resize((sheet.width * 2, sheet.height * 2), Image.NEAREST)
    for r, d in enumerate(DIRS):
        label(b, 4, r * 256 + 2, "live idle_south")
        for i in range(NF): label(b, (i + 1) * 256 + 4, r * 256 + 2, f"{NAMES[d]} f{i + 1}" + ("  blink" if i == BLINK and d != "N" and info[d]["eyes"] else ""))
    b.save(OUT / "contact_sheet_x2.png"); sheet.save(OUT / "contact_sheet.png")
    (OUT / "build_info.json").write_text(json.dumps({"cand": a0.cand, "made": made, "defringed_px": defr, "dirs": info, "frames": NF, "hold_ms": HOLD}, indent=1))
    print(json.dumps({d: {"made": info[d]["made"], "eyes": info[d]["eyes"], "h": info[d]["regions"]["h"]} for d in DIRS}))

if __name__ == "__main__":
    main()
