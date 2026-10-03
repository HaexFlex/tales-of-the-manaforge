#!/usr/bin/env python3
"""Station work north v2 (generic busy loop, empty hands): converted frames (convert_station2.py) -> final 128x128 loop + strip /
GIF / meta / contact sheet.
Clean-up passes per frame (deterministic, documented in NOTES.md):
  0. hand tint   green / pale grey-green blur tints on the hands and cuffs (green components not connected to the hair)
                 -> skin/gold ramp colour of the same lightness
  1. head lock (sway kept)  the spiky hair is redrawn by Imagine every frame (60-70% of hair px change colour = boil), while the
                 head itself sways side to side (smooth +2..-5 px oscillation, two sways per loop). The hair of the reference
                 frame f42 is pasted at each frame's measured integer head shift (best alpha match of the hair mask, dx only;
                 dy is 0 in every frame) damped x0.5 (sampled at ~100 ms the source sway jumps up to 4 px per frame; damped
                 it is a slight 0..-2/+1 px sway): the sway stays, the boil goes. Hands/sleeves in front of the hair are never
                 overwritten; uncovered old hair over the collar is filled with the collar blue, elsewhere it becomes transparent.
  2. rune lock   rune px (cyan + its 2 glow colours) in the torso box are refilled with the nearest coat blue, then the Option A
                 N still's diamond is pasted centred on the frame's own rune centre (follows the torso twist, constant glyph)
  3. boots lock  rows >= 112 (boots, planted) copied from f42 (alpha identical within 0-4 px; removes colour shimmer)
     coat lock   rows 74..111 (lower coat, below the arms): ~30% of its px changed colour every frame with an unchanged silhouette
                 (fold-shading boil); where both the frame and f42 are opaque the f42 colour is used, the silhouette (hem sway,
                 2-18 px) stays live
  4. despeck + keep main (no object can survive as a separate component)
usage: build_station2.py"""
import sys, json
from pathlib import Path
import numpy as np
from PIL import Image, ImageDraw
from scipy import ndimage
sys.path.insert(0, '/workspace/keeper_idle/station2'); sys.path.insert(0, '/workspace/keeper_idle/harv'); sys.path.insert(0, '/workspace/keeper_idle/tools')
import convert_harv as C
R = Path('/workspace/keeper_idle'); S_ = R / 'station2'; OUT = S_ / 'final'
NAME = 'station_work_north'
STILL = np.array(Image.open(R / 'repo/assets/library/experiments/keeper_idle_4dir/v3_stills_8dir/option_a/keeper_still_n.png').convert('RGBA'))
# loop window f42..f63 (22 video frames = 917 ms; f64 ~= f42, upper-body alpha diff 655 video px = best seam in the clip)
SEQ = [(42, 'both hands up (rest)', 80), (44, 'left arm sweeps out', 70), (45, 'left arm extended', 90), (47, 'left hand back up high', 110),
       (50, 'left reaches out again', 80), (52, 'right arm sweeps out', 80), (54, 'right arm extended', 90), (56, 'right hand back up', 100),
       (59, 'right reaches half out', 90), (61, 'both up, settle', 110)]
COAT_ROWS = (74, 112); REF = 42; HEAD_DAMP = 0.5; HEAD_BOX = (0, 50, 34, 98); BOOTS_ROW = 112
RUNE = [(77, 219, 213), (17, 87, 122), (9, 30, 32)]; RUNE_BOX = (48, 78, 50, 80)
PAL = [[int(v) for v in c] for c in C.BASE]
GREEN_BG = (78, 128, 52)

def hsv(c):
    c = c.astype(float) / 255; mx = c.max(-1); mn = c.min(-1); d = mx - mn
    s = np.where(mx > 0, d / np.maximum(mx, 1e-6), 0); r, g, b = c[..., 0], c[..., 1], c[..., 2]; dd = np.maximum(d, 1e-6)
    h = np.where(mx == r, ((g - b) / dd) % 6, np.where(mx == g, (b - r) / dd + 2, (r - g) / dd + 4)) * 60
    return np.where(d > 0, h, 0), s, mx * 255

def is_col(g, cols): return np.any([(g[..., :3] == c).all(-1) for c in cols], 0) & (g[..., 3] > 0)

SKIN_RAMP = [(54, 26, 12), (116, 64, 28), (152, 106, 52), (181, 144, 93), (213, 145, 79), (249, 183, 127)]

def greens(g):
    op = g[..., 3] > 0; c = g[..., :3].astype(int)
    return op & (c[..., 1] > c[..., 0] + 15) & (c[..., 1] > c[..., 2] + 15)

def split_green(g):
    """hair = the largest green component (the head) + green comps inside the head box (loose strands); every other green
    component is blur tint on a hand / cuff"""
    gr = greens(g); lab, n = ndimage.label(gr, np.ones((3, 3)))
    if n == 0: return gr, gr
    area = ndimage.sum(gr, lab, np.arange(1, n + 1)); hair = lab == 1 + int(np.argmax(area))
    y0, y1, x0, x1 = HEAD_BOX
    for k in range(1, n + 1):
        m = lab == k; ys, xs = np.nonzero(m)
        if ys.max() < y1 and xs.min() >= x0 and xs.max() < x1: hair |= m
    return hair, gr & ~hair

def hand_fix(g):
    """green / grey-green blur tints on hands and cuffs -> skin/gold ramp colour of the same lightness"""
    hair, tint = split_green(g); h, s, v = hsv(g[..., :3])
    c = g[..., :3].astype(int); pale = (g[..., 3] > 0) & (c == (165, 192, 156)).all(-1) & ~hair
    fix = tint | pale; lum = c.mean(-1); rl = np.array([np.mean(x) for x in SKIN_RAMP])
    idx = np.abs(lum[fix][:, None] - rl[None]).argmin(1); g[fix, :3] = np.array(SKIN_RAMP)[idx]
    return int(fix.sum())

def hair_mask(g):
    """hair = hair greens + dark outline px next to them + the small non-green bits (brown / maroon / grey strand tips and
    interior shading) that form tiny components (<= 16 px) of the non-green area inside the head box. Hands, sleeves and
    the collar are large components reaching outside it and are never included."""
    hair, _ = split_green(g); op = g[..., 3] > 0; c = g[..., :3].astype(int)
    dark = op & (c.max(-1) < 70)
    m = hair | (dark & ndimage.binary_dilation(hair, np.ones((3, 3))))
    rest = op & ~m; lab, n = ndimage.label(rest, np.ones((3, 3))); y0, y1, x0, x1 = HEAD_BOX
    near = ndimage.binary_dilation(hair, np.ones((5, 5)))
    for k in range(1, n + 1):
        q = lab == k; ys, xs = np.nonzero(q)
        if len(ys) <= 16 and ys.max() < y1 and xs.min() >= x0 and xs.max() < x1 and (q & near).any(): m |= q
    return m

def head_shift(g, ref_h):
    h = hair_mask(g); best = None
    for dx in range(-8, 9):
        d = int((np.roll(ref_h, dx, 1) != h).sum())
        if best is None or d < best[0]: best = (d, dx)
    return best[1], h

def head_lock(g, ref):
    ref_h = hair_mask(ref); dx_src, cur_h = head_shift(g, ref_h)
    dx = int(np.sign(dx_src) * np.floor(abs(dx_src) * HEAD_DAMP + 0.5))   # damped sway (source steps of up to 4 px at ~100 ms)
    sh = np.roll(ref_h, dx, 1); shc = np.roll(ref, dx, 1)
    op = g[..., 3] > 0; h, s, v = hsv(g[..., :3]); coat = op & (h > 195) & (h < 230) & (s > 0.5) & ~cur_h
    other = op & ~cur_h                                     # hands, sleeves, coat, trim
    out = g.copy()
    gone = cur_h & ~sh                                      # current hair px not covered by the reference hair
    if gone.any():
        dist, (iy, ix) = ndimage.distance_transform_edt(~other, return_indices=True)
        fill = gone & (dist <= 1.5) & coat[iy, ix]           # hair that overlapped the collar -> collar coat behind it
        out[fill] = g[iy[fill], ix[fill]]; out[gone & ~fill] = 0
    put = sh & ~(other & ~coat)                             # never paint hair over a hand / sleeve / trim in front of it
    out[put] = shc[put]
    return out, (dx_src, dx), int(gone.sum()), int(put.sum())

def rune_lock(g):
    y0, y1, x0, x1 = RUNE_BOX; box = np.zeros(g.shape[:2], bool); box[y0:y1, x0:x1] = True
    cy = is_col(g, [RUNE[0]]) & box; ys, xs = np.nonzero(cy)
    fcy, fcx = (ys.min() + ys.max()) / 2, (xs.min() + xs.max()) / 2
    sr = is_col(STILL, RUNE) & box; sy, sx = np.nonzero(is_col(STILL, [RUNE[0]]) & box)
    scy, scx = (sy.min() + sy.max()) / 2, (sx.min() + sx.max()) / 2
    dy, dx = int(round(fcy - scy)), int(round(fcx - scx))
    rm = is_col(g, RUNE) & box; n_rm = int(rm.sum())
    h, s, v = hsv(g[..., :3]); coat = (g[..., 3] > 0) & (h > 200) & (h < 225) & (s > 0.8) & ~rm
    _, (iy, ix) = ndimage.distance_transform_edt(~coat, return_indices=True); g[rm, :3] = g[iy[rm], ix[rm], :3]
    ys, xs = np.nonzero(sr); n = 0
    for y, x in zip(ys, xs):
        if g[y + dy, x + dx, 3] > 0: g[y + dy, x + dx, :3] = STILL[y, x, :3]; n += 1
    return n_rm, n, dx, dy

def build():
    OUT.mkdir(parents=True, exist_ok=True)
    for p in OUT.glob(f'{NAME}_*.png'): p.unlink()
    ref = np.array(Image.open(S_ / f'work/g_{REF:03d}.png')).copy(); hand_fix(ref)
    frames, log = [], []
    for k, (i, ph, ms) in enumerate(SEQ):
        g = np.array(Image.open(S_ / f'work/g_{i:03d}.png')).copy()
        nh = hand_fix(g)
        g, hdx, hg, hp = head_lock(g, ref)
        nr, ns, rdx, rdy = rune_lock(g)
        bl = int((g[BOOTS_ROW:] != ref[BOOTS_ROW:]).any(-1).sum()); g[BOOTS_ROW:] = ref[BOOTS_ROW:]
        # lower coat (rows 74..111, below the arms): silhouette stays live (hem sway), shading colours from the reference
        z = np.zeros((128, 128), bool); z[COAT_ROWS[0]:COAT_ROWS[1]] = True; both = z & (g[..., 3] > 0) & (ref[..., 3] > 0)
        cl = int((g[both, :3] != ref[both, :3]).any(-1).sum()); g[both, :3] = ref[both, :3]
        g[g[..., 3] == 0] = 0; g = C.despeck(g); g, nd = C.keep_main(g)
        frames.append(g); Image.fromarray(g).save(OUT / f'{NAME}_{k:04d}.png')
        log.append({'index': k, 'file': f'{NAME}_{k:04d}.png', 'source_clip': 'keeper_station_generic.mp4', 'source_frame': i,
                    'source_time_s': round((i - 1) / 24, 4), 'phase': ph, 'ms': ms,
                    'cleanup': {'hand_tint_px': nh, 'head_shift_dx_source': hdx[0], 'head_shift_dx_used': hdx[1], 'hair_px_removed': hg, 'ref_hair_px_pasted': hp, 'rune_px_refilled': nr,
                                'still_rune_px_pasted': ns, 'rune_offset': [rdx, rdy], 'boots_px_locked': bl, 'lower_coat_px_recoloured': cl, 'dropped': nd}})
    (OUT / 'palette.json').write_text(json.dumps({'name': 'Option A 48 (no extras)', 'colors': PAL}, indent=0))
    W = H = 128
    meta = {'clip': NAME, 'version': 'v2', 'facing': 'north (seen from behind)',
            'use': 'generic busy working-at-a-station loop for all forge stations (anvil, press, reliquiary, ...); empty hands, no tool/object',
            'frame_size': [W, H], 'feet_anchor': [64, 124], 'soles_row': 123, 'anchor': 'planted', 'loop': True,
            'frame_count': len(SEQ), 'durations_ms': [ms for _, _, ms in SEQ], 'loop_ms': sum(ms for _, _, ms in SEQ),
            'files': [x['file'] for x in log], 'palette': 'palette.json', 'extra_colors': [],
            'source': {'clip': 'source/keeper_station_generic.mp4', 'fps': 24, 'frames_used': [i for i, _, _ in SEQ],
                       'loop_window_frames': [42, 63], 'time_window_s': [round(41 / 24, 4), round(63 / 24, 4)],
                       'loop_seam': 'f61 -> f42 (f64 ~= f42: upper-body alpha diff 655 video px, the best seam in the clip)'},
            'scale': '120/348 video px (fixed, = Option A N still height; same transform as station v1)', 'held_tool': None,
            'frames': log}
    (OUT / f'{NAME}.json').write_text(json.dumps(meta, indent=1))
    strip = Image.new('RGBA', (W * len(frames), H), (0, 0, 0, 0))
    for k, g in enumerate(frames): strip.paste(Image.fromarray(g), (k * W, 0))
    strip.save(OUT / f'{NAME}_strip.png')
    gif = []
    for g in frames:
        b = Image.new('RGB', (W, H), GREEN_BG); b.paste(Image.fromarray(g), (0, 0), Image.fromarray(g)); gif.append(b.resize((W * 3, H * 3), Image.NEAREST))
    gif[0].save(OUT / f'{NAME}_x3.gif', save_all=True, append_images=gif[1:], duration=[ms for _, _, ms in SEQ], loop=0, disposal=1)
    sc = 3; cells = [('Option A N still', STILL)] + [(f"{x['index']}: f{x['source_frame']} {x['phase']} {x['ms']}ms", g) for x, g in zip(log, frames)]
    cols = 6; rows = (len(cells) + cols - 1) // cols; cw, chh = W * sc, H * sc + 16
    sheet = Image.new('RGB', (cw * cols, chh * rows), (24, 24, 24)); dr = ImageDraw.Draw(sheet)
    for k, (lab, g) in enumerate(cells):
        x, y = (k % cols) * cw, (k // cols) * chh; b = Image.new('RGB', (W, H), GREEN_BG); im = Image.fromarray(g); b.paste(im, (0, 0), im)
        b = b.resize((cw, H * sc), Image.NEAREST); d2 = ImageDraw.Draw(b); d2.line([(0, 124 * sc - 1), (cw, 124 * sc - 1)], fill=(255, 255, 0)); d2.line([(64 * sc, 0), (64 * sc, H * sc)], fill=(255, 255, 0))
        sheet.paste(b, (x, y + 16)); dr.text((x + 4, y + 2), lab, fill=(255, 255, 255))
    sheet.save(OUT / f'{NAME}_contact.png')
    for x in log: print(x['source_frame'], x['ms'], x['cleanup'])
    print('loop ms', meta['loop_ms'])

if __name__ == '__main__':
    build()
