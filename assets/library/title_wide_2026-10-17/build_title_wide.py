"""title_bg_wide_1440x900: the live 1200x540 title painting (centred at (120,180)) extended by procedural outpainting:
mirror-reflect of the nearest painted pixels (seam-continuous) + dithered vignette darkening towards the outer edge (hard 0/1 Bayer dither, no blur, 1:1 pixels).
Top: night sky / canopy, bottom: forest floor (ping-pong of the last 48 rows so the path keeps its width), sides: forest."""
import numpy as np, os
from PIL import Image
SRC = '/workspace/wt_android/assets_extra/title/title_bg_1200x540.png'; OUT = os.path.dirname(os.path.abspath(__file__))
W, H, OX, OY = 1440, 900, 120, 180
src = np.array(Image.open(SRC).convert('RGB')).astype(np.int32); h, w = src.shape[:2]
BAY = np.array([[0, 8, 2, 10], [12, 4, 14, 6], [3, 11, 1, 9], [15, 7, 13, 5]]) / 16.0
def pingpong(idx, n):   # index into 0..n-1 reflecting
    p = idx % (2 * n); return np.where(p < n, p, 2 * n - 1 - p)
# ---- vertical extension of the source first (rows), then columns
ys = np.arange(-OY, h + OY)
rows = np.empty(len(ys), np.int32)
for i, y in enumerate(ys):
    if y < 0: rows[i] = pingpong(-y - 1, 70)              # top: ping-pong of the first 70 rows (sky + canopy only, no trunk)
    elif y >= h: rows[i] = h - 1 - pingpong(y - h, 48)    # bottom: ping-pong of the last 48 rows
    else: rows[i] = y
ext = src[rows]                                          # (900, 1200, 3)
xs_ = np.arange(-OX, w + OX); cols = np.where(xs_ < 0, -xs_ - 1, np.where(xs_ >= w, 2 * w - 1 - xs_, xs_)); cols = np.clip(cols, 0, w - 1)
ext = ext[:, cols]                                       # (900, 1440, 3): mirrored sides
# ---- dithered vignette, distance outside the original rectangle (0 inside)
yy, xx = np.mgrid[0:H, 0:W]
dx = np.maximum(np.maximum(OX - xx, xx - (OX + w - 1)), 0) / 120.0; dy_t = np.maximum(OY - yy, 0) / 180.0; dy_b = np.maximum(yy - (OY + h - 1), 0) / 180.0
d = np.maximum(np.maximum(dx, dy_t), dy_b)
f = np.clip(d, 0, 1) ** 0.55
bay = BAY[yy % 4, xx % 4]; v = f + (bay - 0.5) * 0.22          # ordered dither between the bands (hard pixels, no blur)
k = np.where(f <= 0, 1.0, np.where(v < 0.16, 1.0, np.where(v < 0.36, 0.74, np.where(v < 0.56, 0.5, np.where(v < 0.76, 0.3, 0.16)))))
navy = np.array([4, 8, 22]); out = (ext * k[..., None] + navy * (1 - k[..., None]) * 0.3).astype(np.int32)
# centre stays EXACTLY the live painting
out[OY:OY + h, OX:OX + w] = src
im = Image.fromarray(out.astype(np.uint8), 'RGB'); im.save(f'{OUT}/title_bg_wide_1440x900.png'); print(im.size)
