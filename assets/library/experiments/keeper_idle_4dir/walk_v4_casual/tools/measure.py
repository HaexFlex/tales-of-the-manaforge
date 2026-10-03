#!/usr/bin/env python3
"""Measure Haex's casual-walk spec on 128x128 south walk frames (and the march walk_v3 / the S still for comparison).
Arms: glove (brown) blob beside the coat per side, rows 66-100, x<=53 (his left arm on screen-left? no: screen-left = his RIGHT) / x>=74.
  -> hand centroid x/y per frame; lateral swing = range of hand centroid x; vertical swing = range of y; max outward distance of the
     hand's outer edge from the body centre line (x 63.5) vs the still.
Legs: per screen half (split at x 63.5), lowest opaque boot row in rows 104-123 -> foot lift = 123 - lowest row.
  Leg length L = sole row - hip row (hip = 3 rows below the belt centre). Angle estimates for the lift:
  straight-leg pendulum acos(1 - lift/L) and single-segment (thigh OR shin, the other vertical) acos(1 - lift/(L/2)) = upper bound."""
import json, sys, math
from pathlib import Path
import numpy as np
from PIL import Image
from scipy import ndimage
R = Path('/workspace/keeper_idle'); REPO = R / 'repo/assets/library/experiments/keeper_idle_4dir'
BROWN = {(116, 64, 28), (54, 26, 12), (71, 36, 16), (96, 51, 24), (15, 6, 4), (37, 16, 8), (139, 79, 36)}
def brown(f): return np.isin(f[..., 0].astype(int) * 65536 + f[..., 1].astype(int) * 256 + f[..., 2], [r * 65536 + g * 256 + b for r, g, b in BROWN]) & (f[..., 3] > 0)
def hands(f):
    m = brown(f); out = {}
    for side, xs in (('screen_left', slice(0, 54)), ('screen_right', slice(74, 128))):
        mm = np.zeros_like(m); mm[66:101, xs] = m[66:101, xs]
        lab, n = ndimage.label(mm, np.ones((3, 3)))
        if n == 0: out[side] = None; continue
        area = ndimage.sum(mm, lab, range(1, n + 1)); k = 1 + int(np.argmax(area)); ys, xx = np.nonzero(lab == k)
        out[side] = {'cx': float(xx.mean()), 'cy': float(ys.mean()), 'outer': int(xx.min() if side == 'screen_left' else xx.max()), 'low': int(ys.max()), 'px': int(len(ys))}
    return out
def belt_row(f):
    """centre of the belt strip: first run of rows (62-82) with >=10 brown px in the centre columns 56-71"""
    m = brown(f)[62:83, 56:72].sum(1) >= 10; r = np.nonzero(m)[0]; run = [r[0]]
    for v in r[1:]:
        if v == run[-1] + 1: run.append(v)
        else: break
    return 62 + float(np.mean(run))
def hem_row(f):
    """lowest coat-blue row (b > r+20, b > g, b > 60) in x 40-87, rows 90-112 (excludes hands and dark boot shading)"""
    r, g, b = [f[..., i].astype(int) for i in range(3)]; m = (b > r + 20) & (b > g) & (b > 60) & (f[..., 3] > 0)
    return int(90 + np.nonzero(m[90:113, 40:88].any(1))[0].max())
def feet(f):
    op = f[..., 3] > 0; res = {}
    for side, xs in (('screen_left', slice(44, 64)), ('screen_right', slice(64, 84))):
        r = np.nonzero(op[104:124, xs].any(1))[0]; res[side] = 123 - (104 + int(r.max())) if len(r) else None
    return res
def measure(frames, label):
    H = [hands(f) for f in frames]; Fe = [feet(f) for f in frames]
    belts = [belt_row(f) for f in frames]; hems = [hem_row(f) for f in frames]
    hip = round(float(np.mean(belts)) + 6, 1); L = round(123 - hip, 1)
    out = {'label': label, 'hip_row': hip, 'leg_len_px': L, 'per_frame': []}
    for k, (h, fe) in enumerate(zip(H, Fe)): out['per_frame'].append({'k': k, 'hands': h, 'foot_lift': fe, 'belt_row': belts[k], 'hem_row': hems[k], 'hem_minus_belt': round(hems[k] - belts[k], 1)})
    out['hem_minus_belt_range'] = [min(p['hem_minus_belt'] for p in out['per_frame']), max(p['hem_minus_belt'] for p in out['per_frame'])]
    for side in ('screen_left', 'screen_right'):
        hs = [h[side] for h in H if h[side]]
        out[f'hand_{side}'] = {'x_range_px': round(max(x['cx'] for x in hs) - min(x['cx'] for x in hs), 1), 'y_range_px': round(max(x['cy'] for x in hs) - min(x['cy'] for x in hs), 1),
                               'max_out_from_centre_px': round(max(abs(x['outer'] - 63.5) for x in hs), 1), 'min_out_from_centre_px': round(min(abs(x['outer'] - 63.5) for x in hs), 1)}
    lift = max(v for fe in Fe for v in fe.values() if v is not None); out['max_foot_lift_px'] = lift
    out['angle_straight_leg_deg'] = round(math.degrees(math.acos(max(-1, 1 - lift / L))), 1)
    out['angle_single_segment_deg'] = round(math.degrees(math.acos(max(-1, 1 - lift / (L / 2)))), 1)
    out['lift_at_45deg_px'] = {'straight_leg': round(L * (1 - math.cos(math.pi / 4)), 1), 'single_segment': round(L / 2 * (1 - math.cos(math.pi / 4)), 1)}
    out['note'] = ('foot lift = how far a foot leaves the ground line (rear heel/foot lifts are visible from the front). '
                   'angle_straight_leg = hip-to-foot line angle for that lift = UPPER bound for a bent knee too. '
                   'angle_single_segment = the angle if only the shin (or only the thigh) rotated = knee-bend estimate, not leg lift.')
    return out
def knee_proxy(res):
    """forward knee lift is hidden under the coat in a front view; the knee sits at the coat hem, so a raised knee lifts the hem.
    knee rise ~= still(hem - belt) - min over frames(hem - belt); thigh angle ~= acos(1 - rise / (L/2))."""
    rest = res['still_s']['hem_minus_belt_range'][0]
    for k in ('v4_casual', 'v3_march'):
        v = res[k]; rise = max(0.0, rest - v['hem_minus_belt_range'][0]); T = v['leg_len_px'] / 2
        v['knee_rise_proxy_px'] = round(rise, 1); v['thigh_angle_est_deg'] = round(math.degrees(math.acos(max(-1, 1 - rise / T))), 1)
        v['knee_rise_at_45deg_px'] = round(T * (1 - math.cos(math.pi / 4)), 1)
def load_dir(d, n=8): return [np.array(Image.open(d / f'walk_south_{k:04d}.png')) for k in range(n)]
if __name__ == '__main__':
    v4 = Path(sys.argv[1]) if len(sys.argv) > 1 else R / 'walk4/assembled'
    res = {'v4_casual': measure(load_dir(v4), 'walk_v4 casual'), 'v3_march': measure(load_dir(REPO / 'walk_v3_optA/walk_south'), 'walk_v3 march'),
           'still_s': measure([np.array(Image.open(REPO / 'v3_stills_8dir/option_a/keeper_still_s.png'))], 'Option A S still')}
    knee_proxy(res)
    (Path(sys.argv[2]) if len(sys.argv) > 2 else R / 'walk4/measurements.json').write_text(json.dumps(res, indent=1))
    for k, v in res.items():
        print(k, 'L', v['leg_len_px'], 'lift', v['max_foot_lift_px'], 'deg', v['angle_straight_leg_deg'], v['angle_single_segment_deg'], 'lift@45', v['lift_at_45deg_px'],
              {s: v[f'hand_{s}'] for s in ('screen_left', 'screen_right')})
        if k != 'still_s': print('   knee proxy', v['knee_rise_proxy_px'], 'thigh deg', v['thigh_angle_est_deg'], 'knee@45', v['knee_rise_at_45deg_px'], 'hem-belt', v['hem_minus_belt_range'])
        if k != 'still_s': print('   lifts', [tuple(p['foot_lift'].values()) for p in v['per_frame']], 'hand outer', [tuple(h['outer'] if h else None for h in p['hands'].values()) for p in v['per_frame']])
