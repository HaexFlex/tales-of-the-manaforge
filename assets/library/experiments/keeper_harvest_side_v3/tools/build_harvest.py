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
SPEC = {   # act: (source video frames 1-based, ms per frame, impact index, phase names)
 'axe':     ([35, 37, 38, 39, 41, 45, 49, 53, 55], [140, 70, 60, 180, 90, 90, 90, 90, 90], 3,
             ['raise (anticipation, axe behind head)', 'swing', 'swing (low)', 'IMPACT', 'recoil', 'recoil', 'lift', 'lift (axe up front)', 're-raise']),
 'pickaxe': ([40, 43, 47, 50, 54, 57, 59, 61, 64], [100, 90, 90, 150, 70, 60, 60, 180, 100], 7,
             ['settle (pick at ground)', 'lift', 'raise', 'wind-up peak (anticipation, pick behind head)', 'swing over head', 'swing', 'swing (low)', 'IMPACT (tip at ground)', 'recoil']),
 'berries': ([66, 71, 75, 79, 82, 86, 93, 99], [160, 90, 90, 100, 160, 100, 90, 110], 4,
             ['rest (hand at pouch)', 'reach start', 'reach', 'reach full (at bush)', 'PLUCK (berries in hand)', 'close hand / pull', 'retract', 'drop into hip pouch']),
}
LOCK = {'berries': (66, 40)}
POUCH = {'berries': (3, (76, 97, 82, 100), [1, 2, 4, 5, 6])}   # (ref frame index, rows y0:y1, cols x0:x1, frames)
SRC = {'axe': 'keeper_harvest_axe.mp4', 'pickaxe': 'keeper_harvest_pickaxe.mp4', 'berries': 'keeper_harvest_berries.mp4'}

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
            g, d = islands(load(act, i))
            if act != 'berries': g, d2 = ground_debris(g); d += d2
            g, nh = hair_edge(g); hfix.append(nh)
            fr.append(g); drop.append(d)
        if act in LOCK:
            ref_i, rows = LOCK[act]; ref = hair_edge(load(act, ref_i))[0]; r0 = top(ref); seg = ref[r0:r0 + rows]
            for f in fr: t = top(f); assert t == r0; f[t:t + rows] = seg
        if act in POUCH:   # pouch lock (berries frames where the hand is away from the pouch): removes berry-pixel shimmer
            ref_k, (y0, y1, x0, x1), ks = POUCH[act]; seg = fr[ref_k][y0:y1, x0:x1].copy()
            for k in ks: fr[k][y0:y1, x0:x1] = seg
        res[act] = fr; log[act] = {'dropped_island_px': drop, 'hair_edge_fixed_px': hfix}
    return res, log

def main():
    res, log = build(); OUT.mkdir(parents=True, exist_ok=True); PV = OUT / 'preview'; PV.mkdir(exist_ok=True)
    base = json.loads((A / 'palette.json').read_text())['colors']; ex = json.loads((R / 'harv/extra_colors.json').read_text())
    pals = {'iron': [list(c[:3]) for c in base] + ex['colors'][0:3], 'berry': [list(c[:3]) for c in base] + ex['colors'][3:5]}
    for k, p in pals.items(): (OUT / f'palette_{k}.json').write_text(json.dumps({'colors': p, 'base': 'Option A 48 (v3_stills_8dir/option_a/palette.json)',
                                                                                 'extra': ex['colors'][0:3] if k == 'iron' else ex['colors'][3:5]}))
    (OUT / 'palette_harvest_all.json').write_text(json.dumps({'colors': [list(c[:3]) for c in base] + ex['colors'], 'extra': dict(zip(ex['names'], ex['colors'])), 'how': ex['how']}, indent=0))
    still = np.array(Image.open(A / 'keeper_still_e.png'))
    for act, fr in res.items():
        seq, ms, imp, names = SPEC[act]
        for d, frames in (('east', fr), ('west', [f[:, ::-1].copy() for f in fr])):
            clip = f'harvest_{act}_{d}'; cd = OUT / clip; cd.mkdir(exist_ok=True); files = []
            for k, f in enumerate(frames):
                assert f.shape == (H, W, 4); Image.fromarray(f, 'RGBA').save(cd / f'{clip}_{k:04d}.png'); files.append(f'{clip}_{k:04d}.png')
            meta = {'clip': clip, 'files': files, 'frame_size': [W, H], 'feet_anchor': list(FEET),
                    'feet_anchor_note': f'bottom-centre of the planted feet = pixel edge x {FEET[0]}, y {FEET[1]}; soles on row {H - 5}; same 4 px bottom margin as the 192x128 / 128x128 conventions (canvas is 136 tall because the overhead swings reach ~row 2 when the body is 119 px)',
                    'durations_ms': ms, 'loop_ms': sum(ms), 'fps_equivalent': round(1000 * len(ms) / sum(ms), 2), 'loop': True,
                    'impact_frame': imp, 'impact_note': 'index into files (0-based); its duration is the held impact/key pose',
                    'phases': names, 'source_video': SRC[act], 'source_fps': FPS_SRC, 'source_frames_1based': seq,
                    'source_time_s': [round((i - 1) / FPS_SRC, 3) for i in seq],
                    'mirrored_from': f'harvest_{act}_east (x -> {W - 1} - x)' if d == 'west' else None,
                    'palette': 'palette_berry.json' if act == 'berries' else 'palette_iron.json', 'anchor': 'planted',
                    'scale': 'video px * 119/344 (standing body 344 video px = Option A E still 119 px)'}
            (cd / f'{clip}.json').write_text(json.dumps(meta, indent=1))
            # strip + x3 gif on green
            strip = Image.new('RGBA', (W * len(frames), H)); [strip.paste(on_green(f), (W * k, 0)) for k, f in enumerate(frames)]
            strip.save(PV / f'{clip}_strip.png')
            gif([on_green(f, 3) for f in frames], PV / f'{clip}_x3.gif', 1, ms) if False else \
                [on_green(f, 3) for f in frames][0].save(PV / f'{clip}_x3.gif', save_all=True, append_images=[on_green(f, 3) for f in frames][1:], duration=ms, loop=0, disposal=1)
            log[act][d] = meta
    # combined x2 (east, side by side): all loops are 900 ms; sampled on a 20 ms grid (browsers clamp GIF delays < 20 ms to 100 ms),
    # identical consecutive ticks merged -> each clip's timing is exact to +-10 ms
    assert all(sum(SPEC[a][1]) == 900 for a in SPEC)
    cells, durs, last = [], [], None
    for t in range(0, 900, 20):
        ks = tuple(int(np.searchsorted(np.cumsum([0] + SPEC[a][1]), t + 10, side='right') - 1) for a in SPEC)
        if ks == last: durs[-1] += 20; continue
        row = Image.new('RGBA', (W * 3, H), GREEN)
        for j, (act, k) in enumerate(zip(SPEC, ks)): row.paste(on_green(res[act][k]), (W * j, 0))
        cells.append(row.resize((W * 6, H * 2), Image.NEAREST)); durs.append(20); last = ks
    cells[0].save(PV / 'harvest_side_combined_east_x2.gif', save_all=True, append_images=cells[1:], duration=durs, loop=0, disposal=1)
    # contact sheet: per action east row + west row, frames x2 on green, labels (index, src frame, ms, IMPACT); E still for reference
    sc = 2; cw, ch = W * sc, H * sc; ncol = 1 + max(len(v[0]) for v in SPEC.values()); rows = 6
    sheet = Image.new('RGB', (cw * ncol, (ch + 14) * rows + 18), (24, 24, 24)); dr = ImageDraw.Draw(sheet)
    dr.text((4, 3), 'Keeper harvest side v3 (video route) - 192x136 RGBA frames on green preview backdrop; col 0 = Option A E still (ref, placed at feet x96 / soles row 131)', fill=(255, 255, 255))
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
            sheet.paste(on_green(ref.copy(), sc).convert('RGB'), (0, y + 14)); dr.text((3, y + 1), f'{act} {d} | E still', fill=(200, 200, 200))
            for k, f in enumerate(frames):
                x = cw * (k + 1); sheet.paste(on_green(f.copy(), sc).convert('RGB'), (x, y + 14))
                dr.text((x + 3, y + 1), f'{k} f{seq[k]} {ms[k]}ms' + (' IMPACT' if k == imp else ''), fill=(255, 220, 80) if k == imp else (255, 255, 255))
            r += 1
    sheet.save(PV / 'harvest_side_contact.png')
    (OUT / 'assembly.json').write_text(json.dumps(log, indent=1, default=str))
    print({a: (log[a]['dropped_island_px'], log[a]['hair_edge_fixed_px']) for a in SPEC})

if __name__ == '__main__':
    main()
