"""v2 E (profile, facing right). The live hair has no side view, so the profile is cut from the live hair itself:
the transplanted live S hair layer, placed with its head axis a few px in front of the profile's ear. Its left half
(spikes pointing sideways) becomes the back of the head, its right half (side spikes + bangs) the front/top.
The part of its face opening that lies behind the ear is filled with back-of-head strands (same method and colours as N);
hair that would cover the profile face (below the brow, in front of the face line) is cut away. W = mirror of E."""
import sys
from pathlib import Path
import numpy as np
from PIL import Image
from scipy import ndimage
sys.path.insert(0, '/workspace/keeper_idle/tools'); sys.path.insert(0, '/workspace/keeper_idle/v2')
from build_idles import defringe
from hair_s import skin_mask, face_fill
from hair_n import build_n
R = Path('/workspace/keeper_idle')

def shift(a, dx, dy):
    out = np.zeros_like(a)
    ys, xs = np.nonzero(a[..., 3] > 0); ys2, xs2 = ys + dy, xs + dx
    ok = (ys2 >= 0) & (ys2 < 128) & (xs2 >= 0) & (xs2 < 128)
    out[ys2[ok], xs2[ok]] = a[ys[ok], xs[ok]]; return out

def build_e(new_e, s_layer, axis_x, ear_x, brow_y, face_x0, eye_box, dy=0, nape_y=38):
    S = shift(s_layer, int(round(axis_x - 63.5)), dy)
    xx = np.arange(128)[None, :].repeat(128, 0); yy = np.arange(128)[:, None].repeat(128, 1)
    cut = (xx >= face_x0) & (yy >= brow_y)
    x0, y0, x1, y1 = eye_box; cut[y0 - 1:y1 + 2, x0 - 1:x1 + 2] = True
    S[cut] = 0
    out, n = build_n(new_e, S, nape_y=nape_y, mirror=False, o_limit=(xx < ear_x), clear='hair', eye_boxes=[eye_box])
    return out, build_n.layer, n

if __name__ == '__main__':
    tag = sys.argv[1]; axis_x = float(sys.argv[2]); dy = int(sys.argv[3])
    new = np.array(Image.open(R / 'work/cand_A3s/key_E.png').convert('RGBA')); new, nfr = defringe(new)
    s_layer = np.array(Image.open(R / 'v2/work/S_a_hair.png').convert('RGBA'))
    out, layer, n = build_e(new, s_layer, axis_x, ear_x=57, brow_y=27, face_x0=62, eye_box=[66, 27, 70, 31], dy=dy)
    Image.fromarray(out).save(R / f'v2/work/E_{tag}.png'); Image.fromarray(layer).save(R / f'v2/work/E_{tag}_hair.png')
    print('back-of-head fill px', n, 'defringed', nfr)
