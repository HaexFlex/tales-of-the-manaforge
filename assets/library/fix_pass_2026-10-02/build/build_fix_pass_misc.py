"""Fix pass 2026-10-02: runestones native (2x of the 32 px source art) + HUD sheet cells -> single 32x32 icons."""
import sys, json
from pathlib import Path
import numpy as np
from PIL import Image
R = Path(sys.argv[1])
# --- runestones: the sheet is original 32 px pixel art (no HD raw exists) -> exact nearest x2
sheet = Image.open(R / "assets/art/props/runestones/runestones_sheet.png").convert("RGBA")
nd = R / "assets/art/props/runestones/native"; nd.mkdir(parents=True, exist_ok=True)
big = sheet.resize((sheet.width * 2, sheet.height * 2), Image.NEAREST)
big.save(nd / "runestones_sheet.png", optimize=True)
CELLS = {"might": (0, 0), "arcana": (2, 5), "resilience": (3, 3), "ward": (1, 3), "vitality": (3, 5), "swiftness": (0, 3), "fate": (2, 3)}
for k, (c, r) in CELLS.items():
    big.crop((c * 64, r * 64, c * 64 + 64, r * 64 + 64)).save(nd / f"runestone_{k}.png", optimize=True)


def scale2x(a):
    """EPX/Scale2x: pixel-art-aware 2x (no new colours). Review alternative only."""
    h, w = a.shape[:2]
    p = np.pad(a, ((1, 1), (1, 1), (0, 0)), mode="edge")
    P = p[1:-1, 1:-1]; A = p[:-2, 1:-1]; B = p[1:-1, 2:]; Cc = p[1:-1, :-2]; D = p[2:, 1:-1]
    eq = lambda x, y: (x == y).all(-1)
    out = np.zeros((h * 2, w * 2, 4), a.dtype)
    out[0::2, 0::2] = np.where((eq(Cc, A) & ~eq(Cc, D) & ~eq(A, B))[..., None], A, P)
    out[0::2, 1::2] = np.where((eq(A, B) & ~eq(A, Cc) & ~eq(B, D))[..., None], B, P)
    out[1::2, 0::2] = np.where((eq(D, Cc) & ~eq(D, B) & ~eq(Cc, A))[..., None], Cc, P)
    out[1::2, 1::2] = np.where((eq(B, D) & ~eq(B, A) & ~eq(D, Cc))[..., None], D, P)
    return out


arr = np.array(sheet)
s2 = np.zeros((512, 512, 4), np.uint8)
for r in range(8):          # per cell so neighbours never bleed across the cell lines
    for c in range(8):
        s2[r*64:(r+1)*64, c*64:(c+1)*64] = scale2x(arr[r*32:(r+1)*32, c*32:(c+1)*32])
lib = R / "assets/library/fix_pass_2026-10-02"; lib.mkdir(parents=True, exist_ok=True)
Image.fromarray(s2, "RGBA").save(lib / "runestones_sheet_scale2x_REVIEW_ONLY.png", optimize=True)
# --- HUD sheet: built from 32 px art nearest x8 -> every 8th pixel is the exact native 32x32 art
hs = np.array(Image.open(R / "assets/art/ui/manaforge_hud_icons_sheet.png").convert("RGBA"))
up = np.repeat(np.repeat(hs[::8, ::8], 8, 0), 8, 1)
assert np.array_equal(up, hs), "HUD sheet is not a clean x8 upscale"
small = hs[::8, ::8]
names = {0: "hud_character", 1: "hud_help", 2: "hud_ascension", 3: "hud_keep_tools", 4: "hud_wooden_basket",
         5: "hud_watering_can", 6: "hud_stone_sword_old", 8: "hud_equip_empty", 9: "hud_equip_locked"}
idir = R / "assets/art/ui/icons"
for i, nm in names.items():
    cell = small[(i // 5) * 32:(i // 5) * 32 + 32, (i % 5) * 32:(i % 5) * 32 + 32].copy()
    cell[cell[..., 3] == 0] = 0
    Image.fromarray(cell, "RGBA").save(idir / f"{nm}.png", optimize=True)
print("ok")
