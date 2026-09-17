#!/usr/bin/env python3
"""Slice Haex inbox sheets into gameplay PNGs (NN, transparent BG).

Inbox stays at `Assets upload/`. This writes copies under assets/art/.
"""
from __future__ import annotations

import json
import os
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
INBOX = ROOT / "Assets upload"
TREES_DIR = ROOT / "assets" / "art" / "trees"
BUSHES_DIR = TREES_DIR / "bushes"
KEEPER_DIR = ROOT / "assets" / "art" / "keeper"

BG_THRESH = 18
PAD = 4


def flood_bg_mask(im: Image.Image, thresh: int = BG_THRESH) -> bytearray:
    rgb = im.convert("RGB")
    w, h = rgb.size
    px = rgb.load()

    def is_bg(x: int, y: int) -> bool:
        r, g, b = px[x, y]
        return r <= thresh and g <= thresh and b <= thresh

    vis = bytearray(w * h)
    stack: list[tuple[int, int]] = []
    for x in range(w):
        for y in (0, h - 1):
            if is_bg(x, y):
                stack.append((x, y))
    for y in range(h):
        for x in (0, w - 1):
            if is_bg(x, y):
                stack.append((x, y))
    while stack:
        x, y = stack.pop()
        i = y * w + x
        if vis[i] or not is_bg(x, y):
            continue
        vis[i] = 1
        if x > 0:
            stack.append((x - 1, y))
        if x < w - 1:
            stack.append((x + 1, y))
        if y > 0:
            stack.append((x, y - 1))
        if y < h - 1:
            stack.append((x, y + 1))
    return vis


def to_rgba_knockout(im: Image.Image, vis: bytearray) -> Image.Image:
    rgba = im.convert("RGBA")
    w, h = rgba.size
    pix = rgba.load()
    for y in range(h):
        row = y * w
        for x in range(w):
            if vis[row + x]:
                pix[x, y] = (0, 0, 0, 0)
    return rgba


def components(vis: bytearray, w: int, h: int, min_area: int) -> list[tuple[int, int, int, int, int]]:
    seen = bytearray(w * h)
    comps: list[tuple[int, int, int, int, int]] = []

    def is_fg(x: int, y: int) -> bool:
        return vis[y * w + x] == 0

    for y in range(h):
        for x in range(w):
            i = y * w + x
            if seen[i] or not is_fg(x, y):
                continue
            q = [(x, y)]
            seen[i] = 1
            minx = maxx = x
            miny = maxy = y
            area = 0
            qi = 0
            while qi < len(q):
                cx, cy = q[qi]
                qi += 1
                area += 1
                if cx < minx:
                    minx = cx
                if cx > maxx:
                    maxx = cx
                if cy < miny:
                    miny = cy
                if cy > maxy:
                    maxy = cy
                for nx, ny in ((cx - 1, cy), (cx + 1, cy), (cx, cy - 1), (cx, cy + 1)):
                    if 0 <= nx < w and 0 <= ny < h:
                        ni = ny * w + nx
                        if not seen[ni] and is_fg(nx, ny):
                            seen[ni] = 1
                            q.append((nx, ny))
            if area >= min_area:
                comps.append((minx, miny, maxx + 1, maxy + 1, area))
    return comps


def sort_reading_order(comps: list[tuple[int, int, int, int, int]]) -> list[tuple[int, int, int, int, int]]:
    if not comps:
        return comps
    heights = [c[3] - c[1] for c in comps]
    row_h = max(40, int(sum(heights) / len(heights) * 0.55))
    return sorted(comps, key=lambda c: (((c[1] + c[3]) // 2) // row_h, c[0]))


def nn_half(im: Image.Image) -> Image.Image:
    w, h = im.size
    nw = max(1, w // 2)
    nh = max(1, h // 2)
    return im.resize((nw, nh), Image.Resampling.NEAREST)


def crop_pad(im: Image.Image, box: tuple[int, int, int, int], pad: int = PAD) -> Image.Image:
    x0, y0, x1, y1 = box
    x0 = max(0, x0 - pad)
    y0 = max(0, y0 - pad)
    x1 = min(im.size[0], x1 + pad)
    y1 = min(im.size[1], y1 + pad)
    return im.crop((x0, y0, x1, y1))


def classify_small(size: tuple[int, int], area: int) -> str:
    w, h = size
    if h <= 36 or w <= 34 or area < 900:
        return "tuft"
    if h >= w * 1.35 and w <= 52:
        return "tuft"
    return "bush"


def slice_sheet(path: Path, min_area: int) -> tuple[Image.Image, list[tuple[int, int, int, int, int]]]:
    im = Image.open(path)
    vis = flood_bg_mask(im)
    rgba = to_rgba_knockout(im, vis)
    comps = sort_reading_order(components(vis, im.size[0], im.size[1], min_area))
    return rgba, comps


def save_png(im: Image.Image, dest: Path) -> None:
    dest.parent.mkdir(parents=True, exist_ok=True)
    im.save(dest, format="PNG", optimize=True)


def process_trees() -> dict:
    items: dict = {}
    spawn: dict[str, list[str]] = {"tree": [], "bush": [], "tuft": []}

    sheets = [
        ("Big Trees.png", "tree_haex_big", TREES_DIR, "tree", 2000),
        ("Small Trees.png", "tree_haex_small", TREES_DIR, "tree", 2000),
        ("Big Bushes.png", "bush_haex_big", BUSHES_DIR, "bush", 800),
        ("small bushes.png", "bush_haex_small", BUSHES_DIR, "small", 80),
    ]
    for fname, prefix, out_dir, role, min_area in sheets:
        src = INBOX / fname
        rgba, comps = slice_sheet(src, min_area)
        print(f"{fname}: {len(comps)} sprites")
        for i, (x0, y0, x1, y1, area) in enumerate(comps):
            crop = crop_pad(rgba, (x0, y0, x1, y1))
            half = nn_half(crop)
            name = f"{prefix}_{i:02d}.png"
            rel_dir = "bushes/" if out_dir == BUSHES_DIR else ""
            rel = f"{rel_dir}{name}"
            save_png(half, out_dir / name)
            kind = role
            if role == "small":
                kind = classify_small(half.size, (half.size[0] * half.size[1]))
            items[name[:-4]] = {
                "file": rel,
                "size": [half.size[0], half.size[1]],
                "role": kind,
                "source": f"Assets upload/{fname}",
                "native_box": [x0, y0, x1, y1],
            }
            spawn[kind if kind in spawn else "bush"].append(name[:-4])
    return {"items": items, "spawn": spawn}


def fit_keeper_128(src: Path) -> Image.Image:
    """NN 50% of 170×256 canvas → 85×128, pad to 128×128, feet at bottom-center."""
    im = Image.open(src).convert("RGBA")
    if im.size != (170, 256):
        # Still map onto 128×128 with NN, preserving aspect, feet bottom-center.
        scale = min(128 / im.size[0], 128 / im.size[1])
        nw = max(1, int(round(im.size[0] * scale)))
        nh = max(1, int(round(im.size[1] * scale)))
        scaled = im.resize((nw, nh), Image.Resampling.NEAREST)
    else:
        scaled = im.resize((85, 128), Image.Resampling.NEAREST)
    canvas = Image.new("RGBA", (128, 128), (0, 0, 0, 0))
    x = (128 - scaled.size[0]) // 2
    y = 128 - scaled.size[1]
    canvas.paste(scaled, (x, y), scaled)
    return canvas


def process_keeper() -> dict:
    idle_src = INBOX / "keeper" / "idle_south.png"
    idle = fit_keeper_128(idle_src)
    save_png(idle, KEEPER_DIR / "keeper_idle_south.png")

    walk_files = []
    frames = []
    for i in range(1, 10):
        src = INBOX / "keeper" / f"walk_south_{i:02d}.png"
        fr = fit_keeper_128(src)
        name = f"keeper_walk_south_{i - 1:04d}.png"
        save_png(fr, KEEPER_DIR / name)
        walk_files.append(name)
        frames.append(fr)

    strip = Image.new("RGBA", (128 * len(frames), 128), (0, 0, 0, 0))
    for i, fr in enumerate(frames):
        strip.paste(fr, (i * 128, 0), fr)
    save_png(strip, KEEPER_DIR / "keeper_walk_south.png")
    return {
        "idle_file": "keeper_idle_south.png",
        "walk_files": walk_files,
        "walk_strip": "keeper_walk_south.png",
        "source": "Assets upload/keeper/",
        "process": "NN 50% of 170x256 then pad to 128x128, feet bottom-center",
    }


def merge_trees_meta(sliced: dict) -> None:
    meta_path = TREES_DIR / "trees_meta.json"
    old = json.loads(meta_path.read_text())
    items = dict(old.get("items", {}))
    items.update(sliced["items"])
    old["items"] = items
    old["spawn_catalog"] = sliced["spawn"]
    old["filter"] = "nearest"
    old["anchor"] = "base_center"
    old["version"] = "haex_inbox_v1"
    old["inbox"] = "Assets upload/"
    old["notes"] = (
        "Haex inbox sheets sliced (PNG, black knockout, NN 50%). "
        "Decorative only — harvest nodes stay in props/. "
        "Originals remain in Assets upload/."
    )
    old["scale"] = "nearest_neighbor_50_percent"
    meta_path.write_text(json.dumps(old, indent=2) + "\n")


def merge_keeper_meta(info: dict) -> None:
    meta_path = KEEPER_DIR / "keeper_meta.json"
    meta = json.loads(meta_path.read_text())
    clips = dict(meta.get("clips", {}))
    clips["idle_front"] = {
        "alias": "idle_south",
        "frames": 1,
        "hold_ms": 140,
        "files": ["keeper_idle_south.png"],
        "source": "Assets upload/keeper/idle_south.png",
    }
    clips["idle_south"] = clips["idle_front"]
    clips["walk_front"] = {
        "alias": "walk_south",
        "frames": 9,
        "hold_ms": 90,
        "strip": "keeper_walk_south.png",
        "files": info["walk_files"],
        "layout": "horizontal",
        "source": "Assets upload/keeper/walk_south_01.png … walk_south_09.png",
    }
    clips["walk_south"] = clips["walk_front"]
    meta["clips"] = clips
    meta["canvas"] = [128, 128]
    meta["anchor"] = "feet_center"
    meta["anchor_px"] = [64, 128]
    meta["filter"] = "nearest"
    meta["version"] = "haex_south_walk_v1"
    meta["notes"] = (
        "South idle/walk from Haex inbox, NN-fit to 128×128. "
        "Back clips unchanged. Filter nearest."
    )
    meta["inbox"] = "Assets upload/keeper/"
    meta_path.write_text(json.dumps(meta, indent=2) + "\n")


def merge_art_manifest() -> None:
    path = ROOT / "assets" / "art" / "MANIFEST.json"
    man = json.loads(path.read_text())
    man["version"] = "v0.1.13-haex-forest-keeper-south"
    man["trees"] = {
        "dir": "trees/",
        "meta": "trees/trees_meta.json",
        "inbox": "Assets upload/",
        "version": "haex_inbox_v1",
    }
    man["keeper"] = {
        "dir": "keeper/",
        "canvas": [128, 128],
        "meta": "keeper/keeper_meta.json",
        "version": "haex_south_walk_v1",
        "inbox": "Assets upload/keeper/",
    }
    path.write_text(json.dumps(man, indent=2) + "\n")


def write_inbox_note() -> None:
    note = INBOX / "README.md"
    text = (
        "# Assets upload (Haex inbox)\n\n"
        "Original sheets and Keeper frames. **Do not delete.**\n\n"
        "Gameplay copies (sliced, NN 50%, transparent):\n\n"
        "- Trees/bushes → `assets/art/trees/` and `assets/art/trees/bushes/`\n"
        "- Keeper south idle/walk → `assets/art/keeper/keeper_idle_south.png`, "
        "`keeper_walk_south_0000.png`–`0008.png`\n\n"
        "Prefer PNG over JPG. Re-slice with `python3 tools/slice_haex_inbox.py`.\n"
    )
    note.write_text(text)


def main() -> None:
    os.chdir(ROOT)
    sliced = process_trees()
    keeper = process_keeper()
    merge_trees_meta(sliced)
    merge_keeper_meta(keeper)
    merge_art_manifest()
    write_inbox_note()
    n_items = len(sliced["items"])
    print(
        f"done: {n_items} forest frames, "
        f"trees={len(sliced['spawn']['tree'])} "
        f"bushes={len(sliced['spawn']['bush'])} "
        f"tufts={len(sliced['spawn']['tuft'])}, "
        f"keeper walk={len(keeper['walk_files'])}"
    )


if __name__ == "__main__":
    main()
