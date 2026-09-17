#!/usr/bin/env python3
"""Build Art Direction v0.1.13-assets-upload frames from Haex inbox PNGs.

Matches ASSETS_UPLOAD_HANDOFF.md:
- key RGB < 18 → alpha 0
- trees/bushes: crop opaque bbox + 2px pad; no downscale unless side > 512
- trees 2×2 grid; big bushes 3×4 gutters; small bushes 4-connected
- keeper 128×128 NN fit + optional native 170×256
"""
from __future__ import annotations

import json
import shutil
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
INBOX = ROOT / "Assets upload"
TREES_DIR = ROOT / "assets" / "art" / "trees"
BUSHES_DIR = ROOT / "assets" / "art" / "bushes"
KEEPER_DIR = ROOT / "assets" / "art" / "keeper"
NATIVE_DIR = KEEPER_DIR / "native"
BG_THRESH = 18
PAD = 2
MAX_SIDE = 512


def key_alpha(im: Image.Image) -> Image.Image:
    rgba = im.convert("RGBA")
    px = rgba.load()
    w, h = rgba.size
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            if r < BG_THRESH and g < BG_THRESH and b < BG_THRESH:
                px[x, y] = (0, 0, 0, 0)
    return rgba


def opaque_bbox(im: Image.Image) -> tuple[int, int, int, int] | None:
    return im.getbbox()


def crop_pad(im: Image.Image, box: tuple[int, int, int, int], pad: int = PAD) -> Image.Image:
    x0, y0, x1, y1 = box
    x0 = max(0, x0 - pad)
    y0 = max(0, y0 - pad)
    x1 = min(im.size[0], x1 + pad)
    y1 = min(im.size[1], y1 + pad)
    return im.crop((x0, y0, x1, y1))


def maybe_nn_cap(im: Image.Image) -> Image.Image:
    w, h = im.size
    if w <= MAX_SIDE and h <= MAX_SIDE:
        return im
    scale = min(MAX_SIDE / w, MAX_SIDE / h)
    nw = max(1, int(round(w * scale)))
    nh = max(1, int(round(h * scale)))
    return im.resize((nw, nh), Image.Resampling.NEAREST)


def save_png(im: Image.Image, dest: Path) -> None:
    dest.parent.mkdir(parents=True, exist_ok=True)
    im.save(dest, format="PNG", optimize=True)


def slice_grid(rgba: Image.Image, cols: int, rows: int, col_splits: list[int] | None = None, row_splits: list[int] | None = None) -> list[Image.Image]:
    w, h = rgba.size
    if col_splits is None:
        col_splits = [int(round(i * w / cols)) for i in range(cols + 1)]
    if row_splits is None:
        row_splits = [int(round(i * h / rows)) for i in range(rows + 1)]
    frames: list[Image.Image] = []
    for ry in range(rows):
        for cx in range(cols):
            cell = rgba.crop((col_splits[cx], row_splits[ry], col_splits[cx + 1], row_splits[ry + 1]))
            bb = opaque_bbox(cell)
            if bb is None:
                continue
            # pad in cell space, then crop from full image so pad can use gutters
            gx0 = col_splits[cx] + bb[0]
            gy0 = row_splits[ry] + bb[1]
            gx1 = col_splits[cx] + bb[2]
            gy1 = row_splits[ry] + bb[3]
            frames.append(maybe_nn_cap(crop_pad(rgba, (gx0, gy0, gx1, gy1))))
    return frames


def components(rgba: Image.Image, min_area: int) -> list[tuple[int, int, int, int, int]]:
    w, h = rgba.size
    px = rgba.load()
    seen = bytearray(w * h)
    comps: list[tuple[int, int, int, int, int]] = []

    def is_fg(x: int, y: int) -> bool:
        return px[x, y][3] > 0

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
    if not comps:
        return comps
    heights = [c[3] - c[1] for c in comps]
    row_h = max(40, int(sum(heights) / len(heights) * 0.55))
    return sorted(comps, key=lambda c: (((c[1] + c[3]) // 2) // row_h, c[0]))


def classify_small(size: tuple[int, int]) -> str:
    w, h = size
    if h <= 55 or w <= 50:
        return "tuft"
    if h >= w * 1.35 and w <= 80:
        return "tuft"
    return "bush"


def process_trees_bushes() -> tuple[dict, dict]:
    tree_items: dict = {}
    bush_items: dict = {}
    spawn = {"tree": [], "bush": [], "tuft": []}

    big_src = INBOX / "Big Trees.png"
    small_src = INBOX / "Small Trees.png"
    big_frames = slice_grid(key_alpha(Image.open(big_src)), 2, 2)
    small_frames = slice_grid(key_alpha(Image.open(small_src)), 2, 2)
    print(f"Big Trees {len(big_frames)}  Small Trees {len(small_frames)}")
    for i, fr in enumerate(big_frames, start=1):
        name = f"tree_big_{i:02d}"
        save_png(fr, TREES_DIR / f"{name}.png")
        tree_items[name] = {
            "file": f"{name}.png",
            "size": [fr.size[0], fr.size[1]],
            "role": "tree",
            "source": "Assets upload/Big Trees.png",
        }
        spawn["tree"].append(name)
        print(f"  {name} {fr.size[0]}x{fr.size[1]}")
    for i, fr in enumerate(small_frames, start=1):
        name = f"tree_small_{i:02d}"
        save_png(fr, TREES_DIR / f"{name}.png")
        tree_items[name] = {
            "file": f"{name}.png",
            "size": [fr.size[0], fr.size[1]],
            "role": "tree",
            "source": "Assets upload/Small Trees.png",
        }
        spawn["tree"].append(name)
        print(f"  {name} {fr.size[0]}x{fr.size[1]}")

    bush_rgba = key_alpha(Image.open(INBOX / "Big Bushes.png"))
    # Handoff gutters: rows ~261/498, cols ~294/579/868
    big_bush_frames = slice_grid(
        bush_rgba,
        4,
        3,
        col_splits=[0, 294, 579, 868, bush_rgba.size[0]],
        row_splits=[0, 261, 498, bush_rgba.size[1]],
    )
    print(f"Big Bushes {len(big_bush_frames)}")
    for i, fr in enumerate(big_bush_frames, start=1):
        name = f"bush_big_{i:02d}"
        save_png(fr, BUSHES_DIR / f"{name}.png")
        bush_items[name] = {
            "file": f"{name}.png",
            "size": [fr.size[0], fr.size[1]],
            "role": "bush",
            "source": "Assets upload/Big Bushes.png",
        }
        spawn["bush"].append(name)
        print(f"  {name} {fr.size[0]}x{fr.size[1]}")

    small_rgba = key_alpha(Image.open(INBOX / "small bushes.png"))
    comps = components(small_rgba, 80)[:64]
    print(f"small bushes {len(comps)}")
    for i, (x0, y0, x1, y1, _area) in enumerate(comps, start=1):
        fr = maybe_nn_cap(crop_pad(small_rgba, (x0, y0, x1, y1)))
        name = f"bush_small_{i:02d}"
        save_png(fr, BUSHES_DIR / f"{name}.png")
        role = classify_small(fr.size)
        bush_items[name] = {
            "file": f"{name}.png",
            "size": [fr.size[0], fr.size[1]],
            "role": role,
            "source": "Assets upload/small bushes.png",
        }
        spawn[role].append(name)

    return {"trees": tree_items, "bushes": bush_items, "spawn": spawn}


def fit_keeper_128(src: Path) -> Image.Image:
    im = Image.open(src).convert("RGBA")
    scale = min(128 / im.size[0], 128 / im.size[1])
    nw = max(1, int(round(im.size[0] * scale)))
    nh = max(1, int(round(im.size[1] * scale)))
    scaled = im.resize((nw, nh), Image.Resampling.NEAREST)
    canvas = Image.new("RGBA", (128, 128), (0, 0, 0, 0))
    x = (128 - scaled.size[0]) // 2
    y = 128 - scaled.size[1]
    canvas.paste(scaled, (x, y), scaled)
    return canvas


def process_keeper() -> None:
    idle_src = INBOX / "keeper" / "idle_south.png"
    idle = fit_keeper_128(idle_src)
    save_png(idle, KEEPER_DIR / "keeper_idle_south.png")
    save_png(idle, KEEPER_DIR / "keeper_idle_south_0000.png")
    shutil.copy2(idle_src, NATIVE_DIR / "keeper_idle_south_256.png")

    frames_128 = []
    frames_native = []
    for i in range(1, 10):
        src = INBOX / "keeper" / f"walk_south_{i:02d}.png"
        fr = fit_keeper_128(src)
        save_png(fr, KEEPER_DIR / f"keeper_walk_south_{i:04d}.png")
        shutil.copy2(src, NATIVE_DIR / f"keeper_walk_south_{i:04d}_256.png")
        frames_128.append(fr)
        frames_native.append(Image.open(src).convert("RGBA"))

    strip = Image.new("RGBA", (128 * 9, 128), (0, 0, 0, 0))
    for i, fr in enumerate(frames_128):
        strip.paste(fr, (i * 128, 0), fr)
    save_png(strip, KEEPER_DIR / "keeper_walk_south.png")

    nw, nh = frames_native[0].size
    nstrip = Image.new("RGBA", (nw * 9, nh), (0, 0, 0, 0))
    for i, fr in enumerate(frames_native):
        nstrip.paste(fr, (i * nw, 0), fr)
    save_png(nstrip, NATIVE_DIR / "keeper_walk_south_256_strip.png")


def write_trees_meta(tree_items: dict, spawn: dict) -> None:
    meta_path = TREES_DIR / "trees_meta.json"
    old = json.loads(meta_path.read_text()) if meta_path.exists() else {}
    items = {}
    for k, v in (old.get("items") or {}).items():
        if str(k).startswith("tree_haex") or str(k).startswith("bush_haex"):
            continue
        items[k] = v
    items.update(tree_items)
    meta = {
        "filter": "nearest",
        "anchor": "base_center",
        "version": "v0.1.13-assets-upload",
        "inbox": "Assets upload/",
        "notes": (
            "v0.1.13 cleaned frames (bbox+2px, no downscale). "
            "Decorative only — harvest nodes stay in props/. "
            "Bushes live in assets/art/bushes/. Originals remain in Assets upload/."
        ),
        "items": items,
        "spawn_catalog": {"tree": spawn["tree"]},
    }
    meta_path.write_text(json.dumps(meta, indent=2) + "\n")


def write_bushes_meta(bush_items: dict, spawn: dict) -> None:
    meta = {
        "filter": "nearest",
        "anchor": "base_center",
        "version": "v0.1.13-assets-upload",
        "dir": "bushes/",
        "inbox": "Assets upload/",
        "grid_decisions": {
            "Big Bushes.png": "3x4 (gutters rows 261/498, cols 294/579/868) — not 2x2",
            "small bushes.png": "4-connected components, min_area 80, row-banded, 57 frames",
        },
        "notes": "Decorative undergrowth. Variable bbox sizes. y-sort on base_center.",
        "items": bush_items,
        "spawn_catalog": {"bush": spawn["bush"], "tuft": spawn["tuft"]},
    }
    BUSHES_DIR.mkdir(parents=True, exist_ok=True)
    (BUSHES_DIR / "bushes_meta.json").write_text(json.dumps(meta, indent=2) + "\n")


def write_keeper_meta() -> None:
    meta_path = KEEPER_DIR / "keeper_meta.json"
    meta = json.loads(meta_path.read_text())
    clips = {
        "idle_front": {
            "frames": 4,
            "hold_ms": 140,
            "strip": "keeper_idle_front.png",
            "layout": "horizontal",
        },
        "idle_back": meta.get("clips", {}).get("idle_back", {
            "frames": 1,
            "hold_ms": 140,
            "files": ["keeper_idle_back_0000.png"],
        }),
        "walk_back": meta.get("clips", {}).get("walk_back", {
            "frames": 6,
            "hold_ms": 90,
            "strip": "keeper_walk_back.png",
            "layout": "horizontal",
        }),
        "idle_south": {
            "frames": 1,
            "hold_ms": 140,
            "files": ["keeper_idle_south_0000.png"],
            "file": "keeper_idle_south.png",
            "native": "native/keeper_idle_south_256.png",
            "source_size": [170, 256],
        },
        "walk_south": {
            "frames": 9,
            "hold_ms": 100,
            "strip": "keeper_walk_south.png",
            "layout": "horizontal",
            "files": [f"keeper_walk_south_{i:04d}.png" for i in range(1, 10)],
            "native_strip": "native/keeper_walk_south_256_strip.png",
            "source_size": [170, 256],
            "filter": "nearest",
        },
        "walk_front": {
            "alias": "walk_south",
            "frames": 9,
            "hold_ms": 100,
        },
    }
    meta["clips"] = clips
    meta["canvas"] = [128, 128]
    meta["anchor"] = "feet_center"
    meta["anchor_px"] = [64, 128]
    meta["filter"] = "nearest"
    meta["version"] = "v0.1.13-assets-upload"
    meta["notes"] = (
        "South idle+walk from Art v0.1.13 pack. Primary canvas 128x128 NN fit, "
        "feet bottom-center, walk hold_ms 100. Native 170x256 under keeper/native/. "
        "Back clips unchanged."
    )
    meta["inbox"] = "Assets upload/keeper/"
    meta_path.write_text(json.dumps(meta, indent=2) + "\n")


def write_manifest() -> None:
    path = ROOT / "assets" / "art" / "MANIFEST.json"
    man = json.loads(path.read_text())
    man["version"] = "v0.1.13-assets-upload"
    man["filter"] = "nearest"
    man["keeper"] = {
        "dir": "keeper/",
        "canvas": [128, 128],
        "meta": "keeper/keeper_meta.json",
        "version": "v0.1.13-assets-upload",
        "inbox": "Assets upload/keeper/",
        "native": "keeper/native/",
    }
    man["trees"] = {
        "dir": "trees/",
        "meta": "trees/trees_meta.json",
        "inbox": "Assets upload/",
        "version": "v0.1.13-assets-upload",
        "anchor": "base_center",
    }
    man["bushes"] = {
        "dir": "bushes/",
        "meta": "bushes/bushes_meta.json",
        "version": "v0.1.13-assets-upload",
        "anchor": "base_center",
    }
    path.write_text(json.dumps(man, indent=2) + "\n")


def write_inbox_note() -> None:
    (INBOX / "README.md").write_text(
        "# Assets upload (Haex inbox)\n\n"
        "Original sheets and Keeper frames. **Do not delete.**\n\n"
        "Gameplay copies follow Art Direction **v0.1.13-assets-upload**:\n\n"
        "- Trees → `assets/art/trees/tree_big_01–04`, `tree_small_01–04`\n"
        "- Bushes → `assets/art/bushes/bush_big_01–12`, `bush_small_01–57`\n"
        "- Keeper south → `assets/art/keeper/keeper_idle_south.png`, "
        "`keeper_walk_south_0001.png`–`0009.png` (128×128); native 170×256 in `keeper/native/`\n\n"
        "Prefer PNG over JPG. Rebuild: `python3 tools/slice_haex_inbox.py`.\n"
    )


def cleanup_old() -> None:
    for p in TREES_DIR.glob("tree_haex_*.png"):
        p.unlink()
    old_bushes = TREES_DIR / "bushes"
    if old_bushes.exists():
        shutil.rmtree(old_bushes)
    for p in KEEPER_DIR.glob("keeper_walk_south_0000.png"):
        p.unlink()


def main() -> None:
    BUSHES_DIR.mkdir(parents=True, exist_ok=True)
    NATIVE_DIR.mkdir(parents=True, exist_ok=True)
    sliced = process_trees_bushes()
    process_keeper()
    write_trees_meta(sliced["trees"], sliced["spawn"])
    write_bushes_meta(sliced["bushes"], sliced["spawn"])
    write_keeper_meta()
    write_manifest()
    write_inbox_note()
    cleanup_old()
    print(
        "done trees=%d bushes=%d tufts=%d"
        % (
            len(sliced["spawn"]["tree"]),
            len(sliced["spawn"]["bush"]),
            len(sliced["spawn"]["tuft"]),
        )
    )


if __name__ == "__main__":
    main()
