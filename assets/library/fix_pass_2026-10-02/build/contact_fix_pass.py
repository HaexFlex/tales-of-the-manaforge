import sys
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont
R = Path(sys.argv[1]); OUT = Path(sys.argv[2]); Z = 2
BG = (58, 84, 52, 255)
try:
    F = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", 12)
except Exception:
    F = ImageFont.load_default()
L = lambda p: Image.open(R / p).convert("RGBA")
ns = lambda im, s: im.resize((max(1, round(im.width * s)), max(1, round(im.height * s))), Image.NEAREST)
rows = []
T0 = "assets/art/hub/"
def row(title, items):        # items: (label, image at display scale)
    h = max(i.height for _, i in items) + 34; w = sum(i.width + 16 for _, i in items) + 8
    c = Image.new("RGBA", (max(w, 900), h), BG); d = ImageDraw.Draw(c)
    d.text((6, 2), title, fill=(255, 255, 210, 255), font=F)
    x = 8
    for lab, im in items:
        c.alpha_composite(im, (x, h - im.height - 2)); d.text((x, 16), lab, fill=(230, 230, 230, 255), font=F); x += im.width + 16
    rows.append(c)
row("1 STONE  (old = 46x48 drawn x2 | new = native 92x96 @1, same HD cutout; spent old 64x64 x2 (unused) | spent new 92x96)", [
    ("old x2", ns(L("assets/art/props/harvest_stone.png"), 2)), ("NEW native", L("assets/art/props/native/harvest_stone.png")),
    ("old spent x2", ns(L("assets/art/props/harvest_stone_spent.png"), 2)), ("NEW spent", L("assets/art/props/native/harvest_stone_spent.png"))])
old2 = ns(L("assets/art/props/harvest_stone.png"), 2); new1 = L("assets/art/props/native/harvest_stone.png")
o = ns(L(T0 + "trees/ring_tree_slim_01.png"), 1.22).crop((20, 60, 160, 200)); n = L(T0 + "trees/sized/ring_tree_slim_01_s125.png").crop((20, 60, 160, 200))
row("1b DETAIL x3: stone old vs new; slim_01 crown old@1.22 vs new s125", [("stone old", ns(old2, 3)), ("stone NEW", ns(new1, 3)), ("slim old@1.22 (crop)", ns(o, 2)), ("slim NEW s125 (crop)", ns(n, 2))])
sheet = L("assets/art/props/runestones/runestones_sheet.png"); alt = L("assets/library/fix_pass_2026-10-02/runestones_sheet_scale2x_REVIEW_ONLY.png")
CELLS = {"might": (0, 0), "arcana": (2, 5), "resilience": (3, 3), "ward": (1, 3), "vitality": (3, 5), "swiftness": (0, 3), "fate": (2, 3)}
items = []
for k, (c, r) in CELLS.items():
    items += [(k[:5] + " old", ns(sheet.crop((c*32, r*32, c*32+32, r*32+32)), 2)), ("NEW", L(f"assets/art/props/runestones/native/runestone_{k}.png"))]
row("2 RUNESTONES  old cell x2 vs NEW native 64x64 (no HD raw exists -> exact nearest 2x, identical on screen)", items)
row("2b runestones Scale2x (EPX) REVIEW-ONLY alternative, not wired", [(k[:5], alt.crop((c*64, r*64, c*64+64, r*64+64))) for k, (c, r) in CELLS.items()])
T = "assets/art/hub/"
row("3 TREES/BUSHES  old = 1x PNG at non-integer sprite_scale (nearest) vs NEW re-rendered from raw @1", [
    ("slim_01 @0.78", ns(L(T + "trees/ring_tree_slim_01.png"), 0.78)), ("NEW s080", L(T + "trees/sized/ring_tree_slim_01_s080.png")),
    ("slim_01 @1.22", ns(L(T + "trees/ring_tree_slim_01.png"), 1.22)), ("NEW s125", L(T + "trees/sized/ring_tree_slim_01_s125.png")),
    ("medium_02 @1.34", ns(L(T + "trees/ring_tree_medium_02.png"), 1.34)), ("NEW s135", L(T + "trees/sized/ring_tree_medium_02_s135.png"))])
row("3b", [("large_03 @1.216", ns(L(T + "trees/ring_tree_large_03.png"), 1.216)), ("NEW s125", L(T + "trees/sized/ring_tree_large_03_s125.png")),
    ("bush_big_01 @1.539", ns(L(T + "bushes/ring_bush_big_01.png"), 1.539)), ("NEW s155", L(T + "bushes/sized/ring_bush_big_01_s155.png")),
    ("bush_big_01 @0.78", ns(L(T + "bushes/ring_bush_big_01.png"), 0.78)), ("NEW s080", L(T + "bushes/sized/ring_bush_big_01_s080.png"))])
hs = L("assets/art/ui/manaforge_hud_icons_sheet.png")
ICONS = {0: "ui/icons/hud_character.png", 1: "ui/icons/hud_help.png", 2: "ui/icons/hud_ascension.png", 3: "ui/icons/hud_keep_tools.png",
         4: "ui/icons/hud_wooden_basket.png", 5: "ui/icons/hud_watering_can.png", 6: "ui/icons/hud_stone_sword_old.png",
         7: "ui/icons/icon_weapon_rod.png", 8: "ui/icons/hud_equip_empty.png", 9: "ui/icons/hud_equip_locked.png"}
items = []
for i, p in ICONS.items():
    cell = hs.crop(((i % 5) * 256, (i // 5) * 256, (i % 5) * 256 + 256, (i // 5) * 256 + 256))
    items += [(f"c{i} sheet", cell.resize((32, 32), Image.NEAREST)), ("NEW", L("assets/art/" + p))]
row("4 HUD ICONS  sheet cell (256 -> 32 in game) vs NEW single 32x32 (cell 7 -> existing icons/icon_weapon_rod.png)", items)
W = max(r.width for r in rows); H = sum(r.height + 4 for r in rows)
out = Image.new("RGBA", (W, H), (30, 30, 34, 255)); y = 0
for r in rows:
    out.alpha_composite(r, (0, y)); y += r.height + 4
out = out.resize((W * Z, H * Z), Image.NEAREST)
out.save(OUT); print(OUT, out.size)
