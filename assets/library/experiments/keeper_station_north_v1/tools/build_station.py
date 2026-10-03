#!/usr/bin/env python3
"""Station work north v1: converted clip-b frames (convert_station.py) -> final 128x128 loop + strip / GIF / meta / contact sheet.
Clean-up passes per frame (all deterministic, documented in NOTES.md):
  1. head lock   rows 0..41, x 0..83 copied from one reference frame (the head is static in the source; this only removes the
                 5-17 px colour shimmer of the hair; no nod in the source, so none is faked)
  2. rune lock   Imagine redrew the coat rune as an 'F' glyph; its pixels (rune cyan + its 2 glow colours) inside the torso box are
                 refilled with the nearest coat blue, then the Option A N still's diamond rune (same 3 colours) is pasted at the
                 still's position shifted (RUNE_DX, RUNE_DY) to follow the 2 px lower torso of the working pose
  3. hammer tint green/teal blur-tinted components that are not hair / rune (8-connected, not touching x < 78): if mostly bordered
                 by coat blue (sleeve) -> nearest sleeve blue, else (hammer head) -> grey of the same lightness on the grey/iron ramp
  4. paper       low-saturation light px (leftover paper from the bench) under the raised arm (rows 63..76, x 80..94, right of the
                 torso) -> transparent; then despeck + keep main
  5. waist       the plank had overlapped the coat's left contour in rows 69..79 (1..3 px notch): contour re-run straight
                 between the clean rows 67 and 81 (edge px copied from row 80)
  6. body lock   (after 1-5) rows >= 70 and x < 75 above copied from the cleaned reference frame f118: the body does not move
                 in the source, this removes the colour shimmer; right shoulder / arm / hammer (x >= 75, rows < 70) stay live
usage: build_station.py"""
import sys, json, colorsys
from pathlib import Path
import numpy as np
from PIL import Image, ImageDraw
from scipy import ndimage
sys.path.insert(0, '/workspace/keeper_idle/station'); sys.path.insert(0, '/workspace/keeper_idle/harv'); sys.path.insert(0, '/workspace/keeper_idle/tools')
import convert_station as CS
import convert_harv as C
R = Path('/workspace/keeper_idle'); S_ = R / 'station'; OUT = S_ / 'final'
NAME = 'station_work_north'
# one hammer strike of clip b (period 9 video frames; f123 ~= f114, alpha diff 37 px) - phase: ms
SEQ = [(114, 'contact / rebound', 120), (115, 'lift', 100), (116, 'lift', 100), (117, 'raise', 100), (118, 'top', 120),
       (119, 'top / start down', 100), (120, 'down-swing', 70), (121, 'down-swing', 70), (122, 'impact', 130)]
HEAD_REF = 118; HEAD_ROWS = 42; HEAD_X = 84; TINT_X = 78; BACK_X = 75
RUNE = [(77, 219, 213), (17, 87, 122), (9, 30, 32)]; RUNE_BOX = (48, 78, 52, 76); RUNE_DX, RUNE_DY = 0, 1
IRON = [[100, 105, 108], [143, 151, 155], [187, 202, 205]]
GREYS = [(15, 6, 4), (75, 71, 75), (100, 105, 108), (143, 151, 155), (187, 202, 205), (232, 229, 220)]
PAL = [list(c) for c in C.BASE] + IRON
GREEN_BG = (78, 128, 52)

def hsv(c):
    c = c.astype(float) / 255; mx = c.max(-1); mn = c.min(-1); d = mx - mn
    s = np.where(mx > 0, d / np.maximum(mx, 1e-6), 0); r, g, b = c[..., 0], c[..., 1], c[..., 2]; dd = np.maximum(d, 1e-6)
    h = np.where(mx == r, ((g - b) / dd) % 6, np.where(mx == g, (b - r) / dd + 2, (r - g) / dd + 4)) * 60
    return np.where(d > 0, h, 0), s, mx * 255

def is_col(g, cols): return np.any([(g[..., :3] == c).all(-1) for c in cols], 0) & (g[..., 3] > 0)

def rune_lock(g, still):
    y0, y1, x0, x1 = RUNE_BOX; box = np.zeros(g.shape[:2], bool); box[y0:y1, x0:x1] = True
    rm = is_col(g, RUNE) & box; n_rm = int(rm.sum())
    h, s, v = hsv(g[..., :3]); coat = (g[..., 3] > 0) & (h > 200) & (h < 225) & (s > 0.8) & ~rm
    _, (iy, ix) = ndimage.distance_transform_edt(~coat, return_indices=True)
    g[rm, :3] = g[iy[rm], ix[rm], :3]
    sr = is_col(still, RUNE) & box; ys, xs = np.nonzero(sr)
    for y, x in zip(ys, xs):
        ty, tx = y + RUNE_DY, x + RUNE_DX
        if g[ty, tx, 3] > 0: g[ty, tx, :3] = still[y, x, :3]
    return n_rm, int(len(ys))

def hammer_tint(g):
    h, s, v = hsv(g[..., :3]); op = g[..., 3] > 0
    greenish = op & (h >= 60) & (h <= 205) & (s > 0.15)
    coat = op & (h > 200) & (h < 225) & (s > 0.8) & ~greenish
    lab, n = ndimage.label(greenish, np.ones((3, 3))); to_grey = np.zeros_like(op); to_coat = np.zeros_like(op)
    for k in range(1, n + 1):
        m = lab == k
        if np.nonzero(m)[1].min() < TINT_X: continue          # hair (and the rune box, x < 76) are never touched
        ring = ndimage.binary_dilation(m, np.ones((3, 3))) & op & ~m
        if ring.sum() and (coat & ring).sum() / ring.sum() > 0.5: to_coat |= m   # teal blur on the sleeve -> sleeve blue
        else: to_grey |= m                                                         # tinted hammer head -> iron grey
    lum = g[..., :3].astype(float).mean(-1); gl = np.array([np.mean(c) for c in GREYS])
    idx = np.abs(lum[to_grey][:, None] - gl[None]).argmin(1); g[to_grey, :3] = np.array(GREYS)[idx]
    if to_coat.any():
        _, (iy, ix) = ndimage.distance_transform_edt(~coat, return_indices=True); g[to_coat, :3] = g[iy[to_coat], ix[to_coat], :3]
    return int(to_grey.sum()), int(to_coat.sum())

def paper(g):
    h, s, v = hsv(g[..., :3]); lum = g[..., :3].astype(float).mean(-1)
    z = np.zeros(g.shape[:2], bool); z[63:77, 80:95] = True     # under the raised arm, right of the torso (torso ends x 79 here)
    m = z & (g[..., 3] > 0) & (s < 0.3) & (lum > 60)
    g[m] = 0; return int(m.sum())

def waist(g, y0=69, y1=80):
    """Imagine's plank overlapped the coat's left edge by ~10 video px in its rows (left waist notch of 1..3 px after the
    downscale). Re-run the left contour straight between the clean rows y0-2 and y1+1 (the new edge px t..c+1 copied from the clean
    row y1+1 below: outline + coat shading)."""
    op = g[..., 3] > 0; le = lambda y: int(np.nonzero(op[y])[0].min()); a, b = le(y0 - 2), le(y1 + 1); n = 0
    for y in range(y0, y1):
        t = int(round(a + (b - a) * (y - y0 + 2) / (y1 + 1 - y0 + 2))); c = le(y)
        if t < c:
            g[y, t:c + 2] = g[y1 + 1, t:c + 2]; n += c - t
    return n

def build():
    OUT.mkdir(parents=True, exist_ok=True)
    for p in OUT.glob(f'{NAME}_*.png'): p.unlink()
    still = CS.STILL.copy()
    ref = np.array(Image.open(S_ / f'work/b/g_{HEAD_REF:03d}.png'))
    frames, log = [], []
    for k, (i, ph, ms) in enumerate(SEQ):
        g = np.array(Image.open(S_ / f'work/b/g_{i:03d}.png')).copy()
        g[:HEAD_ROWS, :HEAD_X] = ref[:HEAD_ROWS, :HEAD_X]
        nr, ns = rune_lock(g, still); nt, nc = hammer_tint(g); npp = paper(g); nw = waist(g)
        g[g[..., 3] == 0] = 0; g = C.despeck(g); g, nd = C.keep_main(g)
        frames.append(g)
        log.append({'index': k, 'file': f'{NAME}_{k:04d}.png', 'source_clip': 'keeper_station_north_b.mp4', 'source_frame': i,
                    'source_time_s': round((i - 1) / 24, 4), 'phase': ph, 'ms': ms,
                    'cleanup': {'rune_px_refilled': nr, 'still_rune_px_pasted': ns, 'hammer_tint_px_to_grey': nt, 'sleeve_teal_px_to_blue': nc, 'paper_px_removed': npp, 'waist_px_added': nw, 'dropped': nd}})
    # body lock: the torso/legs/back do not move in the source (alpha diff <= 3 px) but their colours shimmer (20-130 px/frame);
    # lock them to the cleaned reference frame - only the right shoulder / arm / hammer (x >= 75 above row 70) stay live
    refc = frames[[i for i, _, _ in SEQ].index(HEAD_REF)].copy(); lock = np.zeros((128, 128), bool); lock[70:] = True; lock[:70, :BACK_X] = True
    for k, g in enumerate(frames):
        log[k]['cleanup']['body_lock_px_changed'] = int((g[lock] != refc[lock]).any(-1).sum()); g[lock] = refc[lock]
        g, nd2 = C.keep_main(C.despeck(g)); frames[k] = g; Image.fromarray(g).save(OUT / f'{NAME}_{k:04d}.png')
    used = set()
    for g in frames: used |= set(map(tuple, g[g[..., 3] > 0][:, :3].tolist()))
    iron_used = [c for c in IRON if tuple(c) in used]
    pal = [[int(v) for v in c] for c in C.BASE] + iron_used
    (OUT / 'palette.json').write_text(json.dumps({'name': 'Option A 48 + iron greys for the held hammer head', 'colors': pal}, indent=0))
    W = H = 128
    meta = {'clip': NAME, 'facing': 'north (seen from behind)', 'use': 'generic working-at-a-station loop for all crafting stations',
            'frame_size': [W, H], 'feet_anchor': [64, 124], 'soles_row': 123, 'anchor': 'planted', 'loop': True,
            'frame_count': len(SEQ), 'durations_ms': [ms for _, _, ms in SEQ], 'loop_ms': sum(ms for _, _, ms in SEQ),
            'files': [x['file'] for x in log], 'palette': 'palette.json', 'extra_colors': iron_used,
            'source': {'clip': 'source/keeper_station_north_b.mp4', 'fps': 24, 'frames_used': [i for i, _, _ in SEQ],
                       'time_window_s': [round((SEQ[0][0] - 1) / 24, 4), round(SEQ[-1][0] / 24, 4)], 'loop_seam': 'f122 -> f114 (f123 ~= f114, alpha diff 37 px)'},
            'scale': '120/348 video px (fixed, = Option A N still height)', 'held_tool': 'hammer (right hand) kept; bench, paper, items removed',
            'frames': log}
    (OUT / f'{NAME}.json').write_text(json.dumps(meta, indent=1))
    strip = Image.new('RGBA', (W * len(frames), H), (0, 0, 0, 0))
    for k, g in enumerate(frames): strip.paste(Image.fromarray(g), (k * W, 0))
    strip.save(OUT / f'{NAME}_strip.png')
    gif = []
    for g in frames:
        b = Image.new('RGB', (W, H), GREEN_BG); b.paste(Image.fromarray(g), (0, 0), Image.fromarray(g)); gif.append(b.resize((W * 3, H * 3), Image.NEAREST))
    gif[0].save(OUT / f'{NAME}_x3.gif', save_all=True, append_images=gif[1:], duration=[ms for _, _, ms in SEQ], loop=0, disposal=1)
    # contact sheet: N still + frames, x3 on green, labels
    sc = 3; cells = [('Option A N still', still)] + [(f"{x['index']}: f{x['source_frame']} {x['phase']} {x['ms']}ms", g) for x, g in zip(log, frames)]
    cols = 5; rows = (len(cells) + cols - 1) // cols; cw, chh = W * sc, H * sc + 16
    sheet = Image.new('RGB', (cw * cols, chh * rows), (24, 24, 24)); dr = ImageDraw.Draw(sheet)
    for k, (lab, g) in enumerate(cells):
        x, y = (k % cols) * cw, (k // cols) * chh; b = Image.new('RGB', (W, H), GREEN_BG); im = Image.fromarray(g); b.paste(im, (0, 0), im)
        b = b.resize((cw, H * sc), Image.NEAREST); d2 = ImageDraw.Draw(b); d2.line([(0, 124 * sc - 1), (cw, 124 * sc - 1)], fill=(255, 255, 0)); d2.line([(64 * sc, 0), (64 * sc, H * sc)], fill=(255, 255, 0))
        sheet.paste(b, (x, y + 16)); dr.text((x + 4, y + 2), lab, fill=(255, 255, 255))
    sheet.save(OUT / f'{NAME}_contact.png')
    print(json.dumps([{k: v for k, v in x.items() if k in ('source_frame', 'ms', 'cleanup')} for x in log]))
    print('loop ms', meta['loop_ms'], 'iron used', iron_used)

if __name__ == '__main__':
    build()
