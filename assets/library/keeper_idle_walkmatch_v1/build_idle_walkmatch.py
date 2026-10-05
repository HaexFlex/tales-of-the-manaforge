#!/usr/bin/env python3
"""Build keeper idle (12 frames) from live walk plant frames — walk_v5 match."""
import sys, os, json, shutil
sys.path.insert(0, '/workspace/art_refresh/tools')
import common as C
import numpy as np
from PIL import Image, ImageDraw, ImageFont
from scipy import ndimage

TREE = '/workspace/adv_p0_tree'
WALK = f'{TREE}/assets/art/keeper/anim/walk'
PLANT = {'south': 5, 'north': 3, 'east': 3, 'west': 3}
HEM = 84  # coat hem / upper-body split (walk_v5 notes: legs below ~84)
OUT_LIB = f'{TREE}/assets/library/keeper_idle_walkmatch_v1'
OUT_RT = f'{TREE}/assets/art/keeper/idle_walkmatch'
OUT_BOX = '/workspace/keeper_idle_rebuild/out'
HAND = '/workspace/art-handoff/keeper-idle-walkmatch'
OLD_IDLE = f'{TREE}/assets/art/keeper/idle'


def cyan_count(a):
    v = a[a[..., 3] > 0][:, :3].astype(int)
    return int(((v[:, 1] > v[:, 0] + 40) & (v[:, 2] > v[:, 0] + 30) & (v[:, 1] > 100)).sum())


def cyan_back_panel(a):
    region = a[20:70, 40:90]
    v = region[region[..., 3] > 0][:, :3].astype(int)
    if len(v) == 0:
        return 0
    return int(((v[:, 1] > v[:, 0] + 30) & (v[:, 2] > v[:, 0] + 20) & (v[:, 1] > 90)).sum())


def load_walk(d, i):
    return np.array(Image.open(f'{WALK}/{d}/frame_{i:04d}.png').convert('RGBA'))


def verify_plant(d, claimed):
    """Re-measure max sole contact; return best index."""
    best = (-1, claimed)
    for i in range(8):
        a = load_walk(d, i)
        c = int((a[123, ..., 3] > 0).sum())
        if c > best[0]:
            best = (c, i)
    return best[1], best[0]


def bob_upper(base, dy, hem=HEM):
    """Shift rows [0, hem) by dy pixels vertically; legs [hem, H) stay fixed. Sole stays on 123."""
    if dy == 0:
        return base.copy()
    out = base.copy()
    upper = base[:hem].copy()
    blank = np.zeros_like(upper)
    H = hem
    if dy > 0:
        # shift down: top dy rows clear (transparent), upper content moves down
        blank[dy:] = upper[: H - dy]
        # fill seam: duplicate last moved row into gap above hem is already legs
    else:
        # shift up
        ady = -dy
        blank[: H - ady] = upper[ady:]
        # bottom of upper band: pull from just below hem to avoid hole (coat fringe)
        blank[H - ady :] = base[hem : hem + ady]
    out[:hem] = blank
    # ensure legs untouched
    out[hem:] = base[hem:]
    # harden: any semi shouldn't exist
    out[out[..., 3] < 128] = 0
    out[out[..., 3] >= 128, 3] = 255
    return out


def bob_schedule_12():
    """Map walk bob [0,2,1,1,0,2,1,1] into gentle ±1 over 12 frames (breath)."""
    # sine ±1 for calm breath
    return [int(round(np.sin(2 * np.pi * i / 12.0))) for i in range(12)]  # 0,1,1,1,0,-1,-1,-1,0,1,1,1-ish


def build_dir(d, use_bob=True):
    plant_i, contact = verify_plant(d, PLANT[d])
    base = load_walk(d, plant_i)
    # safety: sole on 123
    assert base.shape[0] == 128 and base.shape[1] == 128
    sched = bob_schedule_12() if use_bob else [0] * 12
    frames = []
    for i, dy in enumerate(sched):
        # clamp bob to ±1 for subtlety (sine already ±1)
        dy = int(np.clip(dy, -1, 1))
        fr = bob_upper(base, dy) if use_bob else base.copy()
        frames.append(fr)
    # evaluate bob quality vs hold: if bob creates holes near hem or changes cyan a lot, fall back
    cyan0 = cyan_count(base)
    bad = False
    for fr in frames:
        if cyan_count(fr) != cyan0 and d == 'north':
            # allow tiny variance
            if abs(cyan_count(fr) - cyan0) > 5:
                bad = True
        # hem seam: many new transparent holes in coat?
        hem_band = fr[HEM - 3 : HEM + 3]
        base_band = base[HEM - 3 : HEM + 3]
        # new empty where base was opaque
        loss = ((base_band[..., 3] > 0) & (hem_band[..., 3] == 0)).sum()
        if loss > 20:
            bad = True
    mode = 'bob'
    if bad or not use_bob:
        frames = [base.copy() for _ in range(12)]
        mode = 'hold'
        sched = [0] * 12
    return {
        'dir': d,
        'plant': plant_i,
        'contact': contact,
        'mode': mode,
        'sched': sched,
        'frames': frames,
        'cyan': cyan_count(base),
        'cyan_panel': cyan_back_panel(base),
        'cols': len({tuple(map(int, p)) for p in base[base[..., 3] > 0][:, :3]}),
    }


def save_pack(results):
    for out_root in (OUT_LIB, OUT_RT):
        for r in results:
            d = r['dir']
            dest = f'{out_root}/{d}'
            os.makedirs(dest, exist_ok=True)
            for i, fr in enumerate(r['frames'], start=1):
                path = f'{dest}/keeper_idle_{d}_{i:04d}.png'
                C.save_rgba(fr, path)
    # also strip previews
    os.makedirs(f'{OUT_LIB}/previews', exist_ok=True)


def contact(results):
    BG = (58, 92, 44, 255)
    try:
        font = ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf', 13)
    except Exception:
        font = ImageFont.load_default()
    dirs = ['south', 'north', 'east', 'west']
    # rows: walk plant | new idle f1 | old idle f1 | new idle cyan-overlay (N focus)
    rows = 4
    cv = Image.new('RGBA', (128 * 4 + 48, 128 * rows + 80), BG)
    d = ImageDraw.Draw(cv)
    d.text((8, 6), 'Keeper idle walkmatch: walk plant | NEW idle f1 | OLD Imagine idle f1 | NEW idle f1 cyan (north emblem check)', fill=(240, 240, 220), font=font)
    y = 28
    labels = ['WALK plant', 'NEW idle', 'OLD idle', 'NEW cyan']
    for ri, lab in enumerate(labels):
        x = 10
        for di, dirn in enumerate(dirs):
            if lab == 'WALK plant':
                im = Image.fromarray(load_walk(dirn, results[di]['plant']))
            elif lab == 'NEW idle':
                im = Image.fromarray(results[di]['frames'][0])
            elif lab == 'OLD idle':
                im = Image.open(f'{OLD_IDLE}/{dirn}/keeper_idle_{dirn}_0001.png').convert('RGBA')
            else:
                a = results[di]['frames'][0].copy()
                v = a[..., :3].astype(int)
                m = (a[..., 3] > 0) & (v[..., 1] > v[..., 0] + 40) & (v[..., 2] > v[..., 0] + 30) & (v[..., 1] > 100)
                a[m] = (0, 255, 180, 255)
                im = Image.fromarray(a)
            cv.alpha_composite(im, (x, y))
            d.text((x + 2, y + 112), f'{dirn[0].upper()}', fill=(255, 255, 200), font=font)
            x += 128 + 8
        d.text((10, y - 14), lab, fill=(220, 220, 200), font=font)
        y += 128 + 10
    # mode line
    modes = ', '.join(f"{r['dir']}={r['mode']} plant=f{r['plant']} cyan={r['cyan']}" for r in results)
    d.text((8, y + 4), modes, fill=(230, 230, 210), font=font)
    path = f'{OUT_BOX}/idle_walkmatch_contact.png'
    cv.convert('RGB').save(path)
    C.save_rgba(np.array(cv.convert('RGBA')), f'{OUT_LIB}/previews/idle_walkmatch_contact.png')
    return path


def main():
    results = []
    for d in ['south', 'north', 'east', 'west']:
        # try bob first
        r = build_dir(d, use_bob=True)
        results.append(r)
        print(json.dumps({k: v for k, v in r.items() if k != 'frames'}))
    # if ANY dir fell back inconsistently, unify: if 2+ are hold, all hold for consistency
    hold_n = sum(1 for r in results if r['mode'] == 'hold')
    if hold_n >= 2:
        print('Unifying to HOLD for all dirs (bob looked worse on multiple facings)')
        results = [build_dir(d, use_bob=False) for d in ['south', 'north', 'east', 'west']]
        for r in results:
            print('hold', r['dir'], 'plant', r['plant'], 'cyan', r['cyan'])
    save_pack(results)
    cpath = contact(results)
    # compare walk vs new shared palette
    report = []
    for r in results:
        w = load_walk(r['dir'], r['plant'])
        n = r['frames'][0]
        wp = {tuple(map(int, p)) for p in w[w[..., 3] > 0][:, :3]}
        npal = {tuple(map(int, p)) for p in n[n[..., 3] > 0][:, :3]}
        old = np.array(Image.open(f'{OLD_IDLE}/{r["dir"]}/keeper_idle_{r["dir"]}_0001.png').convert('RGBA'))
        report.append({
            'dir': r['dir'], 'mode': r['mode'], 'plant': r['plant'], 'sole_contact': r['contact'],
            'cyan_walk': cyan_count(w), 'cyan_new': cyan_count(n), 'cyan_old': cyan_count(old),
            'cyan_panel_walk': cyan_back_panel(w), 'cyan_panel_new': cyan_back_panel(n), 'cyan_panel_old': cyan_back_panel(old),
            'cols': r['cols'], 'shared_with_walk': len(wp & npal), 'new_only': len(npal - wp),
            'feet_x': float(np.nonzero(n[..., 3] > 0)[1][np.nonzero(n[..., 3] > 0)[0] >= 121].mean()) if (n[..., 3] > 0).any() else None,
            'sole_y': int(np.nonzero(n[..., 3] > 0)[0].max()),
            'hard_alpha': sorted({int(x) for x in n[..., 3].ravel()}) == [0, 255],
        })
    json.dump(report, open(f'{OUT_LIB}/report.json', 'w'), indent=2)
    json.dump(report, open(f'{OUT_BOX}/report.json', 'w'), indent=2)
    print('contact', cpath)
    print(json.dumps(report, indent=2))
    return results, report


if __name__ == '__main__':
    main()
