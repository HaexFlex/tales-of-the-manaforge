#!/usr/bin/env python3
"""Walk v2 (Option A): assemble 8-frame loops from walk2/work/<sheet>/g_##.png (frames_walk.py output).
FRONT/BACK: the v2 sheets really alternate feet -> real source frames only (no leg mirroring); upper body (rows above the coat
hem) locked to one reference frame; +1 px bob on the passing frames (legs under the body).
SIDE: neither side sheet has a passing (legs-together) pose. Upper body + coat are a fixed "shell" = reference frame with its
legs removed; each frame pastes only its own leg pixels behind the shell; the two passing frames use the Option A E still's
boots (feet together), stretched in the shaft to meet the walk's coat hem, +1 px bob. W = E mirrored."""
import json, sys, itertools
from pathlib import Path
import numpy as np
from PIL import Image
from scipy import ndimage
sys.path.insert(0, '/workspace/keeper_idle/tools')
from build_idles import hue_group
R = Path('/workspace/keeper_idle'); W = R / 'walk2/work'
STILL_E = np.array(Image.open(R / 'repo/assets/library/experiments/keeper_idle_4dir/v3_stills_8dir/option_a/keeper_still_e.png'))
def load(s, i): return np.array(Image.open(W / s / f'g_{i:02d}.png'))
def top(f): return int(np.nonzero(f[..., 3].any(1))[0].min())
def groups(f): return hue_group(f[..., :3].reshape(-1, 3).astype(int)).reshape(f.shape[:2])
def set_top(f, target, cut):
    dy = top(f) - target
    if dy == 0: return f.copy()
    up, lo = f[:cut], f[cut:]
    if dy > 0: up = np.concatenate([up[dy:], np.repeat(up[-1:], dy, 0)])
    else: up = np.concatenate([np.zeros((-dy,) + up.shape[1:], up.dtype), up[:cut + dy]])
    return np.concatenate([up, lo])
def raise_all(f, dy):
    return np.concatenate([f[dy:], np.zeros((dy,) + f.shape[1:], f.dtype)]) if dy > 0 else f.copy()

# ---------------------------------------------------------------- side helpers
Y_LEG = 82   # side: below this row, brown/dark/neutral pixels not hugging the coat or hands are "legs"
def leg_mask(f):
    """legs = brown cores (trousers/boots) below Y_LEG + their outline/cuff pixels, never anything hugging the coat."""
    op = f[..., 3] > 0; g = groups(f); row = np.arange(128)[:, None]
    blue = op & np.isin(g, [2, 3]); hands = op & (g == 4) & (row < 90)
    cand = op & (row >= Y_LEG) & ~blue & ~hands
    core = cand & (g == 6)
    lab, n = ndimage.label(core, np.ones((3, 3)))
    if n:
        area = ndimage.sum(core, lab, np.arange(1, n + 1)); core = np.isin(lab, 1 + np.nonzero(area >= 12)[0])
    near_core = ndimage.binary_dilation(core, np.ones((5, 5)))
    near_blue = ndimage.binary_dilation(blue, np.ones((5, 5)))
    return core | (cand & near_core & ~near_blue) | (cand & ndimage.binary_dilation(core, np.ones((3, 3))))
def shell_of(f):
    s = f.copy(); s[leg_mask(f)] = 0
    o = s[..., 3] > 0; lab, n = ndimage.label(o, np.ones((3, 3)))
    if n > 1:
        area = ndimage.sum(o, lab, np.arange(1, n + 1)); s[(lab != 1 + int(np.argmax(area))) & o] = 0
    return s
def paste_behind(shell, src, mask):
    out = shell.copy(); m = mask & (out[..., 3] == 0); out[m] = src[m]; return out
FEET_CX = 63.5
def still_boots(shell, ref):
    """Passing legs: the Option A E still's boots (rows >= 104, feet together) centred under the hips (the loop's feet centre),
    plus straight trouser legs from the coat down to the boot tops (ramp sampled from the walk frame's own trousers)."""
    s = STILL_E; so = s[..., 3] > 0; bt = 104
    xs = np.nonzero(so[bt:124].any(0))[0]; dx = int(round(FEET_X_TARGET - (xs.min() + xs.max()) / 2))
    B = np.zeros((128, 128, 4), np.uint8)
    for y in range(bt, 124):
        for x in xs:
            if so[y, x] and 0 <= x + dx < 128: B[y, x + dx] = s[y, x]
    # trousers: ramp = the walk ref's trouser colours (group 6 in its leg pixels rows 84-100), sorted dark -> light
    lm = leg_mask(ref); g = groups(ref); tp = ref[lm & (g == 6)][:, :3]; tp = tp[np.argsort(tp.astype(int).sum(1))]
    dark, mid, light = tp[int(0.1 * len(tp))], tp[int(0.5 * len(tp))], tp[int(0.85 * len(tp))]
    ol = ref[lm & (g == 0)][:, :3]; ol = ol[np.argsort(ol.astype(int).sum(1))][len(ol) // 2] if len(ol) else dark // 2
    cols = [x + dx for x in xs if so[bt, x] or so[bt + 1, x]]
    x0, x1 = min(cols), max(cols); w = x1 - x0 + 1; filled = 0
    for x in range(x0, x1 + 1):
        t = (x - x0) / max(1, w - 1)
        c = ol if x in (x0, x1) else (light if 0.55 < t < 0.8 else (dark if t < 0.25 else mid))
        y = bt - 1
        while y > 60 and shell[y, x, 3] == 0 and B[y, x, 3] == 0:
            B[y, x, :3] = c; B[y, x, 3] = 255; y -= 1; filled += 1
    return B, {'dx': dx, 'boots_x': [int(x0), int(x1)], 'trouser_px': filled}
FEET_X_TARGET = 63.5
def legdiff(a, b):
    a = a[92:124].astype(int); b = b[92:124].astype(int); oa = a[..., 3] > 0; ob = b[..., 3] > 0
    return int((oa != ob).sum() + (np.abs(a[..., :3] - b[..., :3]).sum(-1)[oa & ob] > 60).sum())

# per direction: sheet, seq of (src frame, bob), lock ref, lock rows < ym, body cut row, base top row
SPEC = {
 'south': ('front', [(2, 1), (4, 0), (7, 0), (3, 0), (1, 1), (5, 0), (6, 0), (5, 0)], 2, 101, 106, 5),
 'north': ('back',  [(9, 1), (6, 0), (8, 0), (0, 0), (4, 1), (2, 0), (3, 0), (2, 0)], 9, 99, 104, 4),
}
# main side loop: legs only (no passing pose exists); 01 = narrowest stride (span 54 vs 62-66) gets the +1 px bob.
# Order found by exhaustive search over W,N,N*,N,W,N,N*,N (W in 0,2,3,4,7; N in 5,6; N* = 01) minimising loop leg change.
SIDE = {'sheet': 'side_b', 'ref': 0, 'seq': [2, 5, 1, 5, 7, 5, 1, 5], 'bob': {1}, 'base_top': 4, 'cut': 106}
# REJECTED experiment (preview only): passing frames from the Option A E-still boots + straight trousers.
SIDE_PASSING_ATTEMPT = [7, 5, 'P', 6, 0, 1, 'P', 5]

def build():
    out, log = {}, {}
    for d, (sheet, seq, ref_i, ym, cut, base) in SPEC.items():
        ref = load(sheet, ref_i); fr = []
        for i, bob in seq:
            f = load(sheet, i).copy(); f[:ym] = ref[:ym]; f = set_top(f, base - bob, cut); fr.append(f)
        out[d] = fr
        log[d] = {'sheet': sheet, 'frames': [f'{i:02d}' + (' +1px bob (passing)' if b else '') for i, b in seq],
                  'upper_body_locked_to': f'{ref_i:02d} (rows 0..{ym - 1})', 'body_cut_row': cut, 'base_top_row': base,
                  'loop_leg_diffs': [legdiff(fr[k], fr[(k + 1) % 8]) for k in range(8)]}
    S = SIDE; ref = load(S['sheet'], S['ref']); shell = shell_of(ref)
    dy0 = top(shell) - S['base_top']; shell = raise_all(shell, dy0) if dy0 > 0 else shell
    fr = []
    for k in S['seq']:
        f = load(S['sheet'], k); c = paste_behind(shell, f, leg_mask(f))
        fr.append(set_top(c, top(c) - 1, S['cut']) if k in S['bob'] else c)
    out['east'] = fr; out['west'] = [f[:, ::-1].copy() for f in fr]
    log['east'] = {'sheet': S['sheet'], 'frames': [f'{k:02d} legs' + (' +1px bob (narrowest stride)' if k in S['bob'] else '') for k in S['seq']],
                   'shell': f"{S['sheet']} frame {S['ref']:02d} with its legs removed (head, hair, torso, arms, coat fixed)",
                   'loop_leg_diffs': [legdiff(fr[k], fr[(k + 1) % 8]) for k in range(8)],
                   'note': 'neither side sheet has a passing (legs-together) pose; stride only narrows 66 -> 54 px. Not a real walk.'}
    log['west'] = {'frames': 'east mirrored (x -> 127 - x)'}
    fr = []; info = None
    for k in SIDE_PASSING_ATTEMPT:
        if k == 'P':
            sh = raise_all(shell, 1); B, info = still_boots(sh, ref)
            fr.append(paste_behind(sh, B, B[..., 3] > 0))
        else:
            f = load(S['sheet'], k); m = leg_mask(f)
            fr.append(paste_behind(shell, f, m))
    out['east_passing_attempt'] = fr
    log['east_passing_attempt'] = {'frames': [('P = shell + option_a E-still boots + straight trousers, +1px bob' if k == 'P' else f'{k:02d} legs') for k in SIDE_PASSING_ATTEMPT],
                                   'still_boots': info, 'verdict': 'REJECTED: seam visible (flat trouser block, boot-top line, different boot style)'}
    return out, log

if __name__ == '__main__':
    out, log = build()
    dst = R / 'walk2/assembled'; dst.mkdir(exist_ok=True)
    for d, fr in out.items():
        for k, f in enumerate(fr): Image.fromarray(f).save(dst / f'walk_{d}_{k:04d}.png')
    (dst / 'assembly.json').write_text(json.dumps(log, indent=1)); print(json.dumps({d: (v.get('frames'), v.get('loop_leg_diffs')) for d, v in log.items()}, indent=0))
