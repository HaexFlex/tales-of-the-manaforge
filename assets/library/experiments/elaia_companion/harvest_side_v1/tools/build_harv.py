#!/usr/bin/env python3
"""Elaia harvest side v1 + station north v1: assemble loops from converted frames (work/<clip>/g_###.png).
Ops per clip (see SPEC): sole snap (soles on the canvas sole row), object/debris clean-up, head/hair/leg locks,
water tail composites, bench removal (station). East = as converted; West = exact mirror (x -> W-1-x)."""
import json, sys
from pathlib import Path
import numpy as np
from PIL import Image
from scipy import ndimage
HV = Path('/workspace/elaia_anims/harv'); WK = HV / 'work'
WATER = np.array([[44, 118, 214], [64, 196, 240], [150, 240, 252]])
def load(c, i): return np.array(Image.open(WK / c / f'g_{i:03d}.png').convert('RGBA'))
def top(f): return int(np.nonzero(f[..., 3].any(1))[0].min())
def watermask(f):
    m = np.zeros(f.shape[:2], bool)
    for c in WATER: m |= (f[..., :3] == c).all(-1)
    return m & (f[..., 3] > 0)
def sole_snap(f, sole_row, fx0, fx1):
    """lowest opaque pixel in the feet columns -> sole_row (whole frame shift, |dy| <= 2)"""
    ys = np.nonzero(f[:, fx0:fx1, 3].any(1))[0]; dy = sole_row - int(ys.max())
    if dy == 0 or abs(dy) > 2: return f, 0
    g = np.zeros_like(f)
    if dy > 0: g[dy:] = f[:-dy]
    else: g[:dy] = f[-dy:]
    return g, dy
def clear_box(f, x0, y0, x1, y1, dark_only=False):
    g = f.copy(); sub = g[y0:y1, x0:x1]
    m = sub[..., 3] > 0
    if dark_only: m &= sub[..., :3].mean(-1) < 80
    sub[m] = 0; return g, int(m.sum())
def pick_tip(f):
    """f125 impact: rock cleared (rows >= 122, x >= 106) -> 4-row pointed tip continuing the blade down-left into the ground"""
    g, n = clear_box(f, 106, 122, f.shape[1], 136)
    D, M = (50, 67, 81, 255), (148, 154, 152, 255)
    for k, y in enumerate(range(122, 126)):
        xl, xr = 117 - k, 120 - k
        if xr - xl < 1: xr = xl + 1
        for x in range(xl, xr + 1): g[y, x] = D if x in (xl, xr) else M
        if k == 3: g[y, xl:xr + 1] = D
    return g, n
def lock_rows(fr, ref_k, r0, r1, x0, x1, rel=True):
    ref = fr[ref_k]; t0 = top(ref); n = []
    for k, f in enumerate(fr):
        t = top(f) if rel else 0; tr = t0 if rel else 0
        blk = ref[tr + r0:tr + r1, x0:x1]; cur = f[t + r0:t + r1, x0:x1]
        n.append(int((np.abs(blk.astype(int) - cur.astype(int)).sum(-1) > 0).sum())); f[t + r0:t + r1, x0:x1] = blk
    return n
def lock_aligned(fr, ref_k, r0, r1, x0, x1, search=9):
    """head lock with per-frame alignment: the ref block (rows top+r0..top+r1, x0..x1) is pasted at the (dx, dy) that best
    matches the frame's own head (opaque-mask IoU), so a leaning/turning body keeps its head position but not its shimmer"""
    ref = fr[ref_k]; t0 = top(ref); blk = ref[t0 + r0:t0 + r1, x0:x1].copy(); bm = blk[..., 3] > 0; info = []
    for k, f in enumerate(fr):
        t = top(f); best = None
        for dy in range(-3, 4):
            for dx in range(-search, search + 1):
                y = t + r0 + dy; cur = f[y:y + (r1 - r0), x0 + dx:x1 + dx]
                if cur.shape[:2] != bm.shape: continue
                cm = cur[..., 3] > 0; sc = (bm & cm).sum() / max(1, (bm | cm).sum())
                if best is None or sc > best[0]: best = (sc, dx, dy)
        sc, dx, dy = best; y = t + r0 + dy
        f[y:y + (r1 - r0), x0 + dx:x1 + dx] = blk; info.append([dx, dy, round(float(sc), 3)])
    return info
def bench_clear(f, r0=60, r1=76, cx=64):
    """remove the drawn bench ends beside the waist: in rows r0..r1 keep only the contiguous robe run through x=cx
    (blue-class pixels), clear everything else"""
    g = f.copy(); n = 0
    for y in range(r0, r1):
        row = g[y]; op = row[:, 3] > 0
        blue = op & (row[:, 2].astype(int) > row[:, 0].astype(int) + 20)
        if not blue[cx]: continue
        l = cx
        while l > 0 and blue[l - 1]: l -= 1
        r = cx
        while r < len(row) - 1 and blue[r + 1]: r += 1
        kill = op.copy(); kill[l:r + 1] = False; n += int(kill.sum()); row[kill] = 0
    return g, n
SKIN = np.array([[253, 228, 204], [230, 192, 164], [196, 149, 129]]); ROBE_IN = np.array([[130, 181, 222], [108, 162, 206], [82, 135, 183]])
def unslit(f, min_bottom=105, min_span=6):
    """bare leg seen through the robe's front slit (off-model): skin components reaching row >= min_bottom and spanning
    >= min_span rows -> inner-robe blues (hands never reach that low; hem-trim highlights span < 6 rows)"""
    g = f.copy(); sk = np.zeros(g.shape[:2], bool)
    for s_ in SKIN: sk |= (g[..., :3] == s_).all(-1) & (g[..., 3] > 0)
    lab, n = ndimage.label(sk, np.ones((3, 3))); m = np.zeros_like(sk)
    for k in range(1, n + 1):
        ys = np.nonzero((lab == k).any(1))[0]
        if ys.max() >= min_bottom and ys.max() - ys.min() + 1 >= min_span: m |= lab == k
    for s_, r in zip(SKIN, ROBE_IN):
        mm = m & (g[..., :3] == s_).all(-1); g[mm, :3] = r
    return g, int(m.sum())
def drop_islands(f, min_px=10, keep_water=True):
    op = f[..., 3] > 0; lab, n = ndimage.label(op, np.ones((3, 3)))
    if n <= 1: return f, 0
    area = ndimage.sum(op, lab, np.arange(1, n + 1)); big = 1 + int(np.argmax(area)); wm = watermask(f); g = f.copy(); d = 0
    for k in range(1, n + 1):
        if k == big or area[k - 1] >= min_px: continue
        cm = lab == k
        if keep_water and (wm[cm].mean() > 0.6) and area[k - 1] >= 3: continue
        g[cm] = 0; d += int(area[k - 1])
    return g, d
SPEC = {
 'harvest_axe': dict(clip='axe', src='elaia_harvest_axe_retry.mp4', W=192, H=136, frames=[45, 55, 57, 61, 65, 67, 71, 75, 49],
     ms=[140, 70, 60, 180, 90, 90, 90, 90, 90], impact=3,
     phases=['raise (anticipation, axe behind head)', 'swing (axe up front)', 'swing', 'IMPACT (blade low, stump height)', 'recoil', 'recoil (axe pulled forward)', 'lift', 'lift (axe up front)', 're-raise (overhead)']),
 'harvest_pickaxe': dict(clip='pickaxe', src='elaia_harvest_pickaxe.mp4', W=192, H=136, frames=[89, 94, 101, 105, 110, 117, 121, 125, 133],
     ms=[100, 90, 90, 150, 70, 60, 60, 180, 100], impact=7,
     phases=['ready (pick in front)', 'raise', 'raise high', 'wind-up behind head (hold)', 'rise', 'swing over', 'swing forward', 'IMPACT (tip in the ground)', 'recover (pick lifted from the ground)']),
 'harvest_berries': dict(clip='berries', src='elaia_harvest_berries.mp4', W=192, H=136, frames=[65, 9, 33, 39, 43, 47, 51, 57],
     ms=[160, 90, 90, 100, 160, 100, 90, 110], impact=4,
     phases=['rest (hand at the pouch)', 'reach', 'reach out', 'reach / pinch', 'PLUCK (hand closes at the bush)', 'retract (wrist up)', 'retract to the chest', 'hand into the pouch']),
 'harvest_water': dict(clip='water', src='elaia_harvest_water.mp4', W=208, H=136, frames=[19, 20, 21, 23, 25, 45, 65, 79, 79, 79],
     ms=[170, 100, 90, 90, 110, 250, 250, 100, 90, 100], impact=5,
     phases=['tilt (no stream yet)', 'stream leaves the spout', 'stream arcs', 'stream arcs', 'stream reaches the ground', 'pour hold A', 'pour hold B', 'tilt back, stream detaches', 'tail falling', 'last drops land']),
 'station_work': dict(clip='station', src='elaia_station_generic.mp4', W=128, H=128, frames=[101, 103, 106, 58, 60, 63, 89, 91, 115, 118],
     ms=[80, 120, 85, 85, 120, 85, 85, 80, 120, 80], impact=None,
     phases=['work: elbows in', 'right elbow out', 'elbows working', 'left elbow out', 'both elbows out', 'elbows in', 'right elbow out', 'shoulders down', 'left elbow out', 'settle']),
}
def build(name):
    s = SPEC[name]; c = s['clip']; fr = [load(c, i) for i in s['frames']]; log = {'ops': []}
    sole = s['H'] - 5; cx = s['W'] // 2
    if c == 'axe':
        res = [sole_snap(f, sole, cx - 16, cx + 16) for f in fr]; fr = [r[0] for r in res]; log['sole_snap_dy'] = [r[1] for r in res]
    if c == 'pickaxe':
        fr[7], n = pick_tip(fr[7]); log['f125_rock_cleared_px'] = n
        fr[8], n = clear_box(fr[8], 106, 121, s['W'], s['H']); log['f133_rock_cleared_px'] = n
    if c == 'berries':
        fr[1], n1 = clear_box(fr[1], 116, 73, 127, 80); fr[1], n2 = clear_box(fr[1], 116, 72, 127, 73, dark_only=True)
        log['f9_berry_cleared_px'] = n1 + n2
        log['head_lock_dx_dy_iou'] = lock_aligned(fr, 0, 0, 36, 60, 104)
    if c == 'water':
        f79 = load('water', 79); body79 = f79.copy(); body79[watermask(f79) & (np.arange(s['W'])[None, :] >= 112)] = 0
        for k, ti in ((8, 83), (9, 87)):
            t = load('water', ti); wm = watermask(t); wm[:, :112] = False; g = body79.copy(); g[wm] = t[wm]; fr[k] = g
        fr[0] = fr[0].copy(); w0 = watermask(fr[0]); w0[:, :112] = False; fr[0][w0] = 0; log['k0_stream_removed_px'] = int(w0.sum())
        log['tail_composite'] = {'k8': 'f79 body + f83 stream tail', 'k9': 'f79 body + f87 last drops'}
        log['leg_lock_px'] = lock_rows(fr, 5, 113, 136, 0, 124, rel=False)    # boots + hem from f45 (pour stance)
        log['head_lock_px'] = lock_rows(fr, 5, 0, 34, 60, 112)
        W_, H_ = s['W'], s['H']; xs = np.arange(W_)[None, :]; ys = np.arange(H_)[:, None]; forced = []
        for k, f in enumerate(fr):
            # whole frame: down 1 (soles 130 -> 131, the f45 boots sit on 130) and left 1 (feet edge-centre 105 -> 104)
            g = np.zeros_like(f); g[1:, :-1] = f[:-1, 1:]; g[H_ - 4:] = 0 if False else g[H_ - 4:]
            g[132:] = 0                                   # stream clipped at the ground row 131
            # stream zone (right of the robe/can, below the spout): every opaque pixel -> nearest water tone by lightness
            z = (g[..., 3] > 0) & (((xs >= 125) & (ys >= 82)) | ((xs >= 140) & (ys >= 70))) & (g[..., 2].astype(int) > g[..., 0].astype(int) + 15)   # blue-class only (the wood/copper can stays)
            lum = g[..., :3].astype(float).mean(-1); wl = WATER.mean(1)
            idx = np.abs(lum[..., None] - wl[None, None, :]).argmin(-1); g[z, :3] = WATER[idx[z]]
            fr[k] = g; forced.append(int(z.sum()))
        log['shift_dx_dy'] = [-1, 1]; log['stream_zone_px'] = forced
    if c == 'station':
        res = [bench_clear(f) for f in fr]; fr = [r[0] for r in res]; log['bench_cleared_px'] = [r[1] for r in res]
        log['hair_lock_px'] = lock_rows(fr, 0, 0, 44, 48, 81)
        obj = []
        for k, f in enumerate(fr):   # raised-hand tool tip / fingers peeking over the right shoulder (rows < 47, x >= 81)
            fr[k], n = clear_box(f, 81, 0, s['W'], 47); m = (fr[k][..., :3] == (50, 30, 28)).all(-1) & (fr[k][..., 3] > 0); m[47:] = False
            fr[k][m, :3] = (50, 67, 81); obj.append(n + int(m.sum()))
        log['shoulder_object_cleared_px'] = obj
    if c != 'station':
        res = [unslit(f) for f in fr]; fr = [r[0] for r in res]; log['slit_skin_recoloured_px'] = [r[1] for r in res]
    res = [drop_islands(f) for f in fr]; fr = [r[0] for r in res]; log['islands_dropped_px'] = [r[1] for r in res]
    return fr, log
if __name__ == '__main__':
    out = HV / 'assembled'; allog = {}
    for name in (sys.argv[1:] or SPEC):
        fr, log = build(name); allog[name] = log; d = out / name; d.mkdir(parents=True, exist_ok=True)
        for k, f in enumerate(fr): Image.fromarray(f).save(d / f'{name}_{k:04d}.png')
    (out / 'assembly.json').write_text(json.dumps(allog, indent=1)); print(json.dumps(allog))
