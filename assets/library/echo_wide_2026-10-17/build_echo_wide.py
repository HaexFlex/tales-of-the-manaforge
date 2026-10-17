"""echo_chamber_bg_inkwater_1440x960: the live 1280x720 Ink-Water plate, UNCHANGED at (80,120), extended procedurally.
Extension = reflect of plain edge bands only (top: first 60 rows = roots, bottom: last 60 rows = floor, sides: 80 cols = rock/fern),
highlights clamped so no mirrored glows/runes/fireflies appear, then hard ordered-dither (Bayer) darkening outward. No blur, no new hues."""
import numpy as np, os, sys
from PIL import Image
REPO = sys.argv[1] if len(sys.argv) > 1 else '/workspace/wt_android'
SRC = f'{REPO}/assets/ui/echo/echo_chamber_bg_inkwater_1280x720.png'
OUT = sys.argv[2] if len(sys.argv) > 2 else os.path.dirname(os.path.abspath(__file__))
W, H, OX, OY = 1440, 960, 80, 120
src = np.array(Image.open(SRC).convert('RGB')).astype(np.int32); h, w = src.shape[:2]; assert (w, h) == (1280, 720)
BAY = np.array([[0, 8, 2, 10], [12, 4, 14, 6], [3, 11, 1, 9], [15, 7, 13, 5]]) / 16.0
def pingpong(i, n): p = i % (2 * n); return np.where(p < n, p, 2 * n - 1 - p)
ys = np.arange(-OY, h + OY); rows = np.empty(len(ys), np.int32)
for i, y in enumerate(ys):
    rows[i] = pingpong(-y - 1, 60) if y < 0 else (h - 1 - pingpong(y - h, 60) if y >= h else y)
ext = src[rows]
xs = np.arange(-OX, w + OX); cols = np.where(xs < 0, -xs - 1, np.where(xs >= w, 2 * w - 1 - xs, xs)); ext = ext[:, np.clip(cols, 0, w - 1)]
# highlight clamp (extension only): nothing brighter than the plate's 88th-percentile luminance
lum = lambda a: a[..., 0] * .3 + a[..., 1] * .59 + a[..., 2] * .11
T = np.percentile(lum(src), 88); L = lum(ext)
ext = (ext * np.minimum(1.0, T / np.maximum(L, 1))[..., None]).astype(np.int32)
yy, xx = np.mgrid[0:H, 0:W]
dx = np.maximum(np.maximum(OX - xx, xx - (OX + w - 1)), 0) / float(OX)
dy = np.maximum(np.maximum(OY - yy, yy - (OY + h - 1)), 0) / float(OY)
f = np.clip(np.maximum(dx, dy), 0, 1) ** 0.55
v = f + (BAY[yy % 4, xx % 4] - 0.5) * 0.22
k = np.where(f <= 0, 1.0, np.where(v < 0.16, 1.0, np.where(v < 0.36, 0.78, np.where(v < 0.56, 0.56, np.where(v < 0.76, 0.36, 0.2)))))
tint = np.array(src[:40].reshape(-1, 3).min(0)) // 1  # darkest plate colour, no new hues
out = (ext * k[..., None] + tint * (1 - k[..., None])).astype(np.int32)
out[OY:OY + h, OX:OX + w] = src
assert (out[OY:OY + h, OX:OX + w] == src).all()
im = Image.fromarray(out.astype(np.uint8), 'RGB'); im.save(f'{OUT}/echo_chamber_bg_inkwater_1440x960.png'); print(im.size, 'T', T, 'tint', tint)
