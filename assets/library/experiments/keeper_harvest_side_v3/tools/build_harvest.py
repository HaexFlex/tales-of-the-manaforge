#!/usr/bin/env python3
"""Harvest v3 (side): assemble the chosen video frames (harv/work/<act>/g_###.png from convert_harv.py) into loops,
clean, mirror to west, write frames + meta JSON + previews.
Per frame: drop opaque 8-connected islands < 10 px (chips / debris / stray pixels; the tool itself is one piece),
berries: head lock (rows top..top+40 from f66 pasted into every frame - the body is static in that clip, so this only removes
video shimmer of the hair). West = exact mirror x -> 191 - x (feet edge 96 stays at 96)."""
import json, sys
from pathlib import Path
import numpy as np
from PIL import Image, ImageDraw
from scipy import ndimage
sys.path.insert(0, '/workspace/keeper_idle/harv'); sys.path.insert(0, '/workspace/keeper_idle/tools')
import convert_harv as C
from build_idles import gif
R = Path('/workspace/keeper_idle'); WK = R / 'harv/work'; OUT = R / 'harv/final'
A = R / 'repo/assets/library/experiments/keeper_idle_4dir/v3_stills_8dir/option_a'
GREEN = (78, 128, 52, 255); FPS_SRC = 24; H = 136; W = 192; FEET = (96, H - 4)
WIDTH = {'water': 208}   # the water stream lands 102 px right of the feet -> 208 wide, feet centred at x 104 (mirror-safe)
def width(act): return WIDTH.get(act, W)
def feet(act): return (width(act) // 2, H - 4)
SPEC = {   # act: (source video frames 1-based, ms per frame, impact index, phase names)
 'axe':     ([35, 37, 38, 39, 41, 45, 49, 53, 55], [140, 70, 60, 180, 90, 90, 90, 90, 90], 3,
             ['raise (anticipation, axe behind head)', 'swing', 'swing (low)', 'IMPACT', 'recoil', 'recoil', 'lift', 'lift (axe up front)', 're-raise']),
 'pickaxe': ([40, 43, 47, 50, 54, 57, 59, 61, 64], [100, 90, 90, 150, 70, 60, 60, 180, 100], 7,
             ['settle (pick at ground)', 'lift', 'raise', 'wind-up peak (anticipation, pick behind head)', 'swing over head', 'swing', 'swing (low)', 'IMPACT (tip at ground)', 'recoil']),
 'berries': ([66, 71, 75, 79, 82, 86, 93, 99], [160, 90, 90, 100, 160, 100, 90, 110], 4,
             ['rest (hand at pouch)', 'reach start', 'reach', 'reach full (at bush)', 'PLUCK (hand closes at the bush; no berry pixels since v1b)', 'close hand / pull', 'retract', 'drop into hip pouch']),
 'water':   ([113, 123, 129, 133, 137, 59, 75, 91, 95, 101], [170, 100, 90, 90, 110, 250, 250, 100, 90, 100], 5,
             ['rest (can level, held out)', 'tilt start', 'tilt - stream leaves the spout (POUR START)', 'stream arcs down', 'stream reaches the ground',
              'POUR hold A', 'POUR hold B', 'tilt back - stream detaches (POUR END)', 'stream tail falling', 'last drops land, can levelling']),
}
WATER_POUR = {'pour_start': 2, 'stream_at_ground': [4, 5, 6], 'pour_end': 7, 'water_visible': [2, 3, 4, 5, 6, 7, 8, 9]}
LOCK = {'berries': (66, 40)}
POUCH = {'berries': (3, (76, 97, 82, 100), [1, 2, 4, 5, 6])}   # (ref frame index, rows y0:y1, cols x0:x1, frames)
SRC = {'axe': 'keeper_harvest_axe.mp4', 'pickaxe': 'keeper_harvest_pickaxe.mp4', 'berries': 'keeper_harvest_berries.mp4', 'water': 'keeper_harvest_water.mp4'}
WATER = [tuple(c) for c in json.loads((R / 'harv/water_colors.json').read_text())['water']]

def water_mask(f): return (f[..., 3] > 0) & np.any([(f[..., :3] == c).all(-1) for c in WATER], 0)

def water_clean(f):
    """watering clip: body islands < 10 px and water drops < 3 px dropped; stream clipped at the ground (rows > 131);
    ground splash: rows >= 127 keep only water within the stream's own column range at rows 117..126 (+-1 px)."""
    g = f.copy(); wm = water_mask(g); n0 = int((g[..., 3] > 0).sum())
    g[132:][wm[132:]] = 0; wm = water_mask(g)
    cols = np.nonzero(wm[117:127].any(0))[0]
    if len(cols):
        allow = np.zeros_like(wm); allow[:, max(0, cols.min() - 1):cols.max() + 2] = True; kill = wm & ~allow; kill[:127] = False; g[kill] = 0
    # lone water-coloured px embedded in the body/can (sleeve rim, can band glints mis-read as water): water components
    # of <= 2 px that touch non-water opaque px -> most common non-water neighbour colour
    wm = water_mask(g); op = g[..., 3] > 0; wl, wn = ndimage.label(wm, np.ones((3, 3)))
    for k in range(1, wn + 1):
        ys, xs = np.nonzero(wl == k)
        if len(ys) > 2: continue
        for y, x in zip(ys, xs):
            nb = [tuple(g[yy, xx, :3]) for yy in range(y - 1, y + 2) for xx in range(x - 1, x + 2)
                  if (yy, xx) != (y, x) and 0 <= yy < g.shape[0] and 0 <= xx < g.shape[1] and op[yy, xx] and not wm[yy, xx]]
            if nb:
                vals, cnt = np.unique(np.array(nb), axis=0, return_counts=True); g[y, x, :3] = vals[np.argmax(cnt)]
    op = g[..., 3] > 0; wm = water_mask(g); lab, n = ndimage.label(op, np.ones((3, 3)))
    for k in range(1, n + 1):
        comp = lab == k; sz = int(comp.sum()); isw = wm[comp].mean() > 0.5
        if (isw and sz < 3) or (not isw and sz < 10): g[comp] = 0
    return g, n0 - int((g[..., 3] > 0).sum())

def water_head_lock(fr, ref):
    """hair shimmer lock from the rest frame (f113), 208-wide canvas: rows 13..24 x <= 136 and rows 25..43 x <= 113
    (the can never enters this zone: when tilted it reaches x >= 114 from row 31 down)"""
    L = np.zeros(ref.shape[:2], bool); L[13:25, :137] = True; L[25:44, :114] = True; n = []
    for f in fr: n.append(int((f[L] != ref[L]).any(-1).sum())); f[L] = ref[L]
    return n

def load(act, i): return np.array(Image.open(WK / act / f'g_{i:03d}.png'))
def top(f): return int(np.nonzero(f[..., 3].any(1))[0].min())

def islands(f, min_px=10):
    op = f[..., 3] > 0; lab, n = ndimage.label(op, np.ones((3, 3)))
    if n <= 1: return f, 0
    area = ndimage.sum(op, lab, np.arange(1, n + 1)); keep = np.isin(lab, 1 + np.nonzero(area >= min_px)[0])
    g = f.copy(); d = int((op & ~keep).sum()); g[~keep] = 0; return g, d

STEEL = [(100, 105, 108), (143, 151, 155), (187, 202, 205), (75, 71, 75), (61, 78, 98)]   # iron extras + the 2 palette greys steel maps to
def ground_debris(f, x0=113, y0=119):
    """axe/pickaxe: in the ground zone right of the feet (x >= 113, rows >= 119; the feet end at x ~108) keep only the tool head:
    steel pixels + dark outline pixels (max RGB < 70) 8-adjacent to steel. Drops wood chips / grass / rock bits at impact."""
    g = f.copy(); rgb = g[..., :3]; op = g[..., 3] > 0
    steel = op & np.any([(rgb == c).all(-1) for c in STEEL], 0)
    near = ndimage.binary_dilation(steel, np.ones((3, 3))) & (rgb.max(-1) < 70) & op
    zone = np.zeros_like(op); zone[y0:, x0:] = True
    kill = zone & op & ~steel & ~near
    # per column: nothing more than 1 px below the lowest steel pixel (debris under the blade / tip)
    for x in range(x0, g.shape[1]):
        ys = np.nonzero(steel[y0:, x])[0]
        lo = y0 + (ys.max() + 1 if len(ys) else -1)
        kill[max(lo + 1, y0):, x] |= op[max(lo + 1, y0):, x]
    g[kill] = 0
    # small islands lying entirely in the ground zone (chips) < 25 px
    op = g[..., 3] > 0; lab, n = ndimage.label(op, np.ones((3, 3))); d = 0
    for k in range(1, n + 1):
        ys, xs = np.nonzero(lab == k)
        if len(ys) < 25 and ys.min() >= y0 and xs.min() >= x0: g[lab == k] = 0; d += len(ys)
    return g, int(kill.sum()) + d

HAIR_OUTLINE = (17, 25, 7)
def hair_edge(f):
    """key spill turns some hair-outline pixels navy/blue (Option A E still: 0 blue px on the hair edge, walk_v3 E: 2-7).
    Silhouette-edge pixels with a blue hue whose 8-neighbourhood is mostly hair green (>=2 green and more green than blue)
    -> the palette's dark hair outline (17,25,7)."""
    g = f.copy(); c = g[..., :3].astype(int); op = g[..., 3] > 0
    green = op & (c[..., 1] > c[..., 0] + 25) & (c[..., 1] > c[..., 2] + 25)
    blue = op & (c[..., 2] > c[..., 0] + 15) & (c[..., 2] >= c[..., 1])
    edge = op & ndimage.binary_dilation(~op, np.ones((3, 3)))
    k = np.ones((3, 3)); k[1, 1] = 0
    gn = ndimage.convolve(green.astype(int), k, mode='constant'); bn = ndimage.convolve(blue.astype(int), k, mode='constant')
    m = edge & blue & (gn >= 2) & (gn > bn); g[m, :3] = HAIR_OUTLINE; return g, int(m.sum())

BERRY = [(132, 10, 10), (186, 14, 12)]
# v1b (Haex 2026-10-03): the red berries read as putting berries ON the bush -> remove every berry pixel from the berries clip.
# Hanging berry clusters below the hand (berry + stem + its outline) are cleared by box -> transparent (nothing behind them):
BERRY_AIR = {4: [(62, 68, 133, 142)], 3: [(62, 63, 136, 138)]}   # frame index: [(y0, y1, x0, x1)] (f82 cluster on its stem, f79 berry tip)
def deberry(f, k):
    """remove berry pixels: berry colours + boxes in BERRY_AIR. Each berry pixel is then decided from its 8 neighbours
    (iteratively, so clusters fill from the outside in): more opaque than transparent known neighbours -> the most common
    opaque neighbour colour (hand / glove / pouch interior / coat), otherwise transparent (outside the body)."""
    g = f.copy(); op = g[..., 3] > 0
    bad = op & np.any([(g[..., :3] == c).all(-1) for c in BERRY], 0); n_col = int(bad.sum()); n_air = 0
    for (y0, y1, x0, x1) in BERRY_AIR.get(k, []):
        n_air += int((op[y0:y1, x0:x1] & ~bad[y0:y1, x0:x1]).sum()); g[y0:y1, x0:x1] = 0; bad[y0:y1, x0:x1] = False
    unknown = bad.copy(); H_, W_ = unknown.shape; filled = transp = 0
    while unknown.any():
        decided = []; cand = []
        for y, x in zip(*np.nonzero(unknown)):
            nb_op, nb_tr, cols = 0, 0, []
            for dy in (-1, 0, 1):
                for dx in (-1, 0, 1):
                    if (dy or dx) and 0 <= y + dy < H_ and 0 <= x + dx < W_ and not unknown[y + dy, x + dx]:
                        if g[y + dy, x + dx, 3] > 0: nb_op += 1; cols.append(tuple(g[y + dy, x + dx, :3]))
                        else: nb_tr += 1
            cand.append((nb_op + nb_tr, (y, x, nb_op, nb_tr, cols)))
        decided = [c for n, c in cand if n >= 3]
        if not decided:   # deep inside a cluster: decide the pixels with the most known neighbours first
            m = max(n for n, c in cand)
            if m == 0: break
            decided = [c for n, c in cand if n == m]
        for y, x, no, nt, cols in decided:
            if no > nt:
                vals, cnt = np.unique(np.array(cols), axis=0, return_counts=True); g[y, x, :3] = vals[np.argmax(cnt)]; g[y, x, 3] = 255; filled += 1
            else: g[y, x] = 0; transp += 1
            unknown[y, x] = False
    # pouch opening (rows 85-86, x 87-94): leftover light specks there are berry highlights quantised to browns ->
    # pouch-interior dark brown if >= 3 of their 4 neighbours are dark interior/outline browns (so the pouch reads empty)
    DARKS = [(54, 26, 12), (37, 16, 8), (71, 36, 16)]; spk = 0
    for _ in range(2):
        for y in range(85, 87):
            for x in range(87, 95):
                c = tuple(int(v) for v in g[y, x, :3])
                if g[y, x, 3] == 0 or c in DARKS: continue
                nd = sum(tuple(int(v) for v in g[y + dy, x + dx, :3]) in DARKS for dy, dx in ((-1, 0), (1, 0), (0, -1), (0, 1)))
                if nd >= 3: g[y, x, :3] = DARKS[0]; spk += 1
    g, d = islands(g, 4)    # anything left floating after a cluster was removed
    return g, {'berry_colour_px': n_col, 'filled_px': filled, 'to_transparent_px': transp, 'air_box_px_cleared': n_air, 'pouch_specks_darkened': spk, 'islands_dropped_px': d,
               'changed_px_total': int((g != f).any(-1).sum())}

def hair_top(f):
    g = f[..., :3].astype(int); m = (f[..., 3] > 0) & (g[..., 1] > g[..., 0] + 25) & (g[..., 1] > g[..., 2] + 25)
    return int(np.nonzero(m.any(1))[0].min())

def on_green(f, sc=1):
    b = Image.new('RGBA', (f.shape[1], f.shape[0]), GREEN); b.alpha_composite(Image.fromarray(f))
    return b.resize((f.shape[1] * sc, f.shape[0] * sc), Image.NEAREST)

def build():
    res, log = {}, {}
    for act, (seq, ms, imp, names) in SPEC.items():
        fr, drop, hfix = [], [], []
        for i in seq:
            if act == 'water': g, d = water_clean(load(act, i))
            else: g, d = islands(load(act, i))
            if act in ('axe', 'pickaxe'): g, d2 = ground_debris(g); d += d2
            g, nh = hair_edge(g); hfix.append(nh)
            fr.append(g); drop.append(d)
        if act == 'water':
            ref = hair_edge(water_clean(load('water', 113))[0])[0]; nlock = water_head_lock(fr, ref)
        if act in LOCK:
            ref_i, rows = LOCK[act]; ref = hair_edge(load(act, ref_i))[0]; r0 = top(ref); seg = ref[r0:r0 + rows]
            for f in fr: t = top(f); assert t == r0; f[t:t + rows] = seg
        if act in POUCH:   # pouch lock (berries frames where the hand is away from the pouch): removes berry-pixel shimmer
            ref_k, (y0, y1, x0, x1), ks = POUCH[act]; seg = fr[ref_k][y0:y1, x0:x1].copy()
            for k in ks: fr[k][y0:y1, x0:x1] = seg
        if act == 'berries':
            db = [deberry(f, k) for k, f in enumerate(fr)]; fr = [x[0] for x in db]
        res[act] = fr; log[act] = {'dropped_island_px': drop, 'hair_edge_fixed_px': hfix}
        if act == 'berries': log[act]['deberry_v1b'] = [x[1] for x in db]
        if act == 'water': log[act]['head_lock_px'] = nlock
    return res, log

def main():
    res, log = build(); OUT.mkdir(parents=True, exist_ok=True); PV = OUT / 'preview'; PV.mkdir(exist_ok=True)
    base = json.loads((A / 'palette.json').read_text())['colors']; ex = json.loads((R / 'harv/extra_colors.json').read_text())
    # v1b: berry colours dropped (berries clip = Option A 48 only)
    pals = {'iron': [list(c[:3]) for c in base] + ex['colors'][0:3], 'berries': [list(c[:3]) for c in base]}
    for k, p in pals.items(): (OUT / f'palette_{k}.json').write_text(json.dumps({'colors': p, 'base': 'Option A 48 (v3_stills_8dir/option_a/palette.json)',
                                                                                 'extra': ex['colors'][0:3] if k == 'iron' else []}))
    (OUT / 'palette_berry.json').unlink(missing_ok=True)
    wx = json.loads((R / 'harv/water_colors.json').read_text())
    (OUT / 'palette_water.json').write_text(json.dumps({'colors': [list(c[:3]) for c in base] + wx['water'] + wx['can'], 'base': 'Option A 48 (v3_stills_8dir/option_a/palette.json)',
        'extra': {'water': dict(zip(wx['water_names'], wx['water'])), 'can': wx['can'] or 'none - the wood/copper/iron-band can maps cleanly onto Option A browns, golds and greys'}}))
    (OUT / 'palette_harvest_all.json').write_text(json.dumps({'colors': [list(c[:3]) for c in base] + ex['colors'][0:3] + wx['water'] + wx['can'],
        'extra': {**dict(zip(ex['names'][0:3], ex['colors'][0:3])), **dict(zip(wx['water_names'], wx['water']))},
        'how': ex['how'], 'dropped_v1b': {'berry_dark': ex['colors'][3], 'berry_red': ex['colors'][4], 'why': 'Haex 2026-10-03: red berries read as putting berries on the bush; all berry pixels removed from the berries clip'}}, indent=0))
    still = np.array(Image.open(A / 'keeper_still_e.png'))
    for act, fr in res.items():
        seq, ms, imp, names = SPEC[act]
        for d, frames in (('east', fr), ('west', [f[:, ::-1].copy() for f in fr])):
            clip = f'harvest_{act}_{d}'; cd = OUT / clip; cd.mkdir(exist_ok=True); files = []
            Wa = width(act)
            for k, f in enumerate(frames):
                assert f.shape == (H, Wa, 4); Image.fromarray(f, 'RGBA').save(cd / f'{clip}_{k:04d}.png'); files.append(f'{clip}_{k:04d}.png')
            meta = {'clip': clip, 'files': files, 'frame_size': [Wa, H], 'feet_anchor': list(feet(act)),
                    'feet_anchor_note': f'bottom-centre of the planted feet = pixel edge x {feet(act)[0]}, y {feet(act)[1]}; soles on row {H - 5}; same 4 px bottom margin as the 192x128 / 128x128 conventions (canvas is 136 tall because the overhead swings reach ~row 2 when the body is 119 px)'
                                        + ('; 208 wide (not 192) because the stream lands 102 px right of the feet; feet stay horizontally centred, so a centred sprite lines up with the 192-wide clips' if act == 'water' else ''),
                    'durations_ms': ms, 'loop_ms': sum(ms), 'fps_equivalent': round(1000 * len(ms) / sum(ms), 2), 'loop': True,
                    'impact_frame': imp, 'impact_note': 'index into files (0-based); its duration is the held impact/key pose',
                    'phases': names, 'source_video': SRC[act], 'source_fps': FPS_SRC, 'source_frames_1based': seq,
                    'source_time_s': [round((i - 1) / FPS_SRC, 3) for i in seq],
                    'mirrored_from': f'harvest_{act}_east (x -> {Wa - 1} - x)' if d == 'west' else None,
                    'palette': {'berries': 'palette_berries.json', 'water': 'palette_water.json'}.get(act, 'palette_iron.json'), 'anchor': 'planted',
                    'scale': 'video px * 119/344 (standing body 344 video px = Option A E still 119 px)'}
            if act == 'water':
                meta.update(WATER_POUR); meta['impact_note'] = 'index (0-based) of the main held pour pose (key pose)'
                meta['pour_note'] = ('pour_start = first frame with the stream leaving the spout; stream_at_ground = frames where the stream reaches the ground '
                                     '(held: 110+250+250 ms); pour_end = frame where the stream detaches from the spout (tilt back); water_visible = frames with any water px')
                meta['loop_note'] = 'loop 1350 ms = 1.5 x the 900 ms harvest loops (keeps the combined preview short: LCM 2700 ms)'
            (cd / f'{clip}.json').write_text(json.dumps(meta, indent=1))
            # strip + x3 gif on green
            strip = Image.new('RGBA', (Wa * len(frames), H)); [strip.paste(on_green(f), (Wa * k, 0)) for k, f in enumerate(frames)]
            strip.save(PV / f'{clip}_strip.png')
            gif([on_green(f, 3) for f in frames], PV / f'{clip}_x3.gif', 1, ms) if False else \
                [on_green(f, 3) for f in frames][0].save(PV / f'{clip}_x3.gif', save_all=True, append_images=[on_green(f, 3) for f in frames][1:], duration=ms, loop=0, disposal=1)
            log[act][d] = meta
    # combined x2 (east, side by side, all actions): common timeline = LCM of the loop lengths (900 / 1350 ms -> 2700 ms),
    # sampled on a 20 ms grid (browsers clamp GIF delays < 20 ms to 100 ms), identical consecutive ticks merged
    from math import lcm
    L = 1
    for a in SPEC: L = lcm(L, sum(SPEC[a][1]))
    cells, durs, last = [], [], None
    for t in range(0, L, 20):
        ks = tuple(int(np.searchsorted(np.cumsum([0] + SPEC[a][1]), (t + 10) % sum(SPEC[a][1]), side='right') - 1) for a in SPEC)
        if ks == last: durs[-1] += 20; continue
        tw = sum(width(a) for a in SPEC); row = Image.new('RGBA', (tw, H), GREEN); x = 0
        for act, k in zip(SPEC, ks): row.paste(on_green(res[act][k]), (x, 0)); x += width(act)
        cells.append(row.resize((tw * 2, H * 2), Image.NEAREST)); durs.append(20); last = ks
    cells[0].save(PV / 'harvest_side_combined_east_x2.gif', save_all=True, append_images=cells[1:], duration=durs, loop=0, disposal=1)
    log['combined_gif'] = {'timeline_ms': L, 'frames': len(cells), 'order': list(SPEC)}
    # contact sheet: per action east row + west row, frames x2 on green, labels (index, src frame, ms, IMPACT); E still for reference
    sc = 2; cw, ch = max(width(a) for a in SPEC) * sc, H * sc; ncol = 1 + max(len(v[0]) for v in SPEC.values()); rows = 2 * len(SPEC)
    sheet = Image.new('RGB', (cw * ncol, (ch + 14) * rows + 18), (24, 24, 24)); dr = ImageDraw.Draw(sheet)
    dr.text((4, 3), 'Keeper harvest side v3 (video route): axe, pickaxe, berries (v1b, no berries), water - 192x136 RGBA frames on green preview backdrop; col 0 = Option A E still (ref, feet x96 / soles row 131)', fill=(255, 255, 255))
    st = np.zeros((H, W, 4), np.uint8); sr = np.nonzero(still[..., 3].any(1))[0]; sc_ = np.nonzero(still[..., 3].any(0))[0]
    # place still: its soles (row sr.max()) -> row H-5, its feet centre (bottom 10 rows) -> 95.5
    fb = np.nonzero(still[sr.max() - 9:sr.max() + 1, :, 3].any(0))[0]; fcx = (fb.min() + fb.max()) / 2
    oy = (H - 5) - sr.max(); ox = int(round(95.5 - fcx)); st[oy:oy + 128, ox:ox + 128] = still
    r = 0
    for act, fr in res.items():
        seq, ms, imp, names = SPEC[act]
        for d, frames in (('east', fr), ('west', [f[:, ::-1] for f in fr])):
            y = 18 + r * (ch + 14)
            ref = st if d == 'east' else st[:, ::-1]
            sheet.paste(on_green(ref.copy(), sc).convert('RGB'), ((cw - W * sc) // 2, y + 14)); dr.text((3, y + 1), f'{act} {d} | E still', fill=(200, 200, 200))
            for k, f in enumerate(frames):
                x = cw * (k + 1); sheet.paste(on_green(f.copy(), sc).convert('RGB'), (x + (cw - f.shape[1] * sc) // 2, y + 14))   # feet-centred in the cell
                tag = (' POUR' if k == imp else '') if act == 'water' else (' KEY' if (act == 'berries' and k == imp) else (' IMPACT' if k == imp else ''))
                dr.text((x + 3, y + 1), f'{k} f{seq[k]} {ms[k]}ms' + tag, fill=(255, 220, 80) if k == imp else (255, 255, 255))
            r += 1
    sheet.save(PV / 'harvest_side_contact.png')
    (OUT / 'assembly.json').write_text(json.dumps(log, indent=1, default=str))
    print({a: (log[a]['dropped_island_px'], log[a]['hair_edge_fixed_px']) for a in SPEC})

if __name__ == '__main__':
    main()
