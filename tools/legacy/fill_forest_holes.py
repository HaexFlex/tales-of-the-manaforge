#!/usr/bin/env python3
"""One-off: close camera holes the forest seal still reports.

Edits scenes/main.tscn and exits. Not a runtime bake. Refuses MANAFORGE_BAKE.
"""

from __future__ import annotations

import math
import os
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SCENE = ROOT / "scenes" / "main.tscn"
TREE_DIR = ROOT / "assets" / "art" / "hub" / "trees"
BUSH_DIR = ROOT / "assets" / "art" / "hub" / "bushes"
CX, CY, RX, RY = 2160.0, 2025.0, 1620.0, 1323.0
CELL = 32.0
SOLID = "13_vxglm"
SCRIPT = "14_2f3dj"


def refuse_bake() -> None:
    if os.environ.get("MANAFORGE_BAKE") == "1":
        sys.exit("refusing: MANAFORGE_BAKE is set. This writer is not the hub bake.")


def png_size(path: Path) -> tuple[int, int]:
    data = path.read_bytes()
    return int.from_bytes(data[16:20], "big"), int.from_bytes(data[20:24], "big")


def ellipse_norm(x: float, y: float) -> float:
    dx = (x - CX) / RX
    dy = (y - CY) / RY
    ang = math.atan2(dy, dx)
    wobble = (
        0.075 * math.sin(ang * 3.0 + 0.55)
        + 0.055 * math.sin(ang * 5.0 + 2.15)
        + 0.040 * math.cos(ang * 2.0 + 0.35)
        + 0.028 * math.sin(ang * 7.0 + 1.15)
    )
    limit = max(0.72, 1.0 + wobble)
    return math.hypot(dx, dy) / limit


def sprite_rect(x: float, y: float, w: int, h: int, scale: float) -> tuple[float, float, float, float]:
    sw = w * scale
    sh = h * scale
    return (x - sw * 0.5, y - sh, x + sw * 0.5, y)


def corners_ok(x: float, y: float, w: int, h: int, scale: float) -> bool:
    left, top, right, bot = sprite_rect(x, y, w, h, scale)
    for px, py in ((left, top), (right, top), (left, bot), (right, bot)):
        if ellipse_norm(px, py) < 0.90:
            return False
    return True


def load_art() -> list[tuple[str, str, int, int, str]]:
    out: list[tuple[str, str, int, int, str]] = []
    for path in sorted(TREE_DIR.glob("ring_tree_*.png")):
        w, h = png_size(path)
        kind = "slim" if "slim" in path.name else "medium" if "medium" in path.name else "large"
        out.append(("tree", f"res://assets/art/hub/trees/{path.name}", w, h, kind))
    for path in sorted(BUSH_DIR.glob("ring_bush_*.png")):
        w, h = png_size(path)
        out.append(("bush", f"res://assets/art/hub/bushes/{path.name}", w, h, "bush"))
    return out


def parse_props(text: str) -> list[dict]:
    props: list[dict] = []
    chunks = text.split("\n[node ")
    for chunk in chunks[1:]:
        head = chunk.split("\n", 1)[0]
        if 'name="EdgeTree_' not in head and 'name="EdgeBush_' not in head:
            continue
        if 'parent="World"' not in head:
            continue
        name = re.search(r'name="([^"]+)"', head).group(1)
        pos = re.search(r"position = Vector2\(([-\d.]+), ([-\d.]+)\)", chunk)
        tex = re.search(r'texture_path = "([^"]+)"', chunk)
        scale = re.search(r"sprite_scale = ([-\d.]+)", chunk)
        if not pos or not tex or not scale:
            continue
        rel = tex.group(1).replace("res://", "")
        w, h = png_size(ROOT / rel)
        props.append(
            {
                "name": name,
                "x": float(pos.group(1)),
                "y": float(pos.group(2)),
                "tex": tex.group(1),
                "w": w,
                "h": h,
                "scale": float(scale.group(1)),
                "kind": "bush" if name.startswith("EdgeBush_") else "tree",
            }
        )
    return props


def holes(props: list[dict]) -> list[tuple[float, float]]:
    covered: set[tuple[int, int]] = set()
    for prop in props:
        left, top, right, bot = sprite_rect(prop["x"], prop["y"], prop["w"], prop["h"], prop["scale"])
        x0, y0 = int(math.floor(left / CELL)), int(math.floor(top / CELL))
        x1, y1 = int(math.floor(right / CELL)), int(math.floor(bot / CELL))
        for gx in range(x0, x1 + 1):
            for gy in range(y0, y1 + 1):
                cx = (gx + 0.5) * CELL
                cy = (gy + 0.5) * CELL
                if left <= cx <= right and top <= cy <= bot:
                    covered.add((gx, gy))
    found: list[tuple[float, float]] = []
    sx = 180.0
    while sx <= 4140.0:
        sy = 180.0
        while sy <= 3600.0:
            if ellipse_norm(sx, sy) >= 0.97:
                key = (int(math.floor(sx / CELL)), int(math.floor(sy / CELL)))
                if key not in covered:
                    found.append(((key[0] + 0.5) * CELL, (key[1] + 0.5) * CELL))
            sy += 32.0
        sx += 32.0
    return found


def try_grow(props: list[dict], hx: float, hy: float) -> bool:
    ranked = sorted(props, key=lambda p: (p["x"] - hx) ** 2 + (p["y"] - hy) ** 2)
    for prop in ranked[:8]:
        scale = prop["scale"]
        while scale < 1.56:
            scale = round(scale + 0.02, 3)
            if not corners_ok(prop["x"], prop["y"], prop["w"], prop["h"], scale):
                break
            left, top, right, bot = sprite_rect(prop["x"], prop["y"], prop["w"], prop["h"], scale)
            if left <= hx <= right and top <= hy <= bot:
                prop["scale"] = scale
                return True
    return False


def try_place(props: list[dict], art: list, hx: float, hy: float) -> dict | None:
    # Crowns grow upward, so the new feet sit on or below the hole.
    for kind, tex, w, h, _tag in art:
        for scale in (1.05, 0.92, 1.2, 0.8, 1.36):
            half = w * scale * 0.5
            height = h * scale
            y = hy + 8.0
            while y <= hy + height - 4.0:
                x = hx - half + 8.0
                while x <= hx + half - 8.0:
                    if ellipse_norm(x, y) < 0.955:
                        x += 14.0
                        continue
                    if not corners_ok(x, y, w, h, scale):
                        x += 14.0
                        continue
                    left, top, right, bot = sprite_rect(x, y, w, h, scale)
                    if not (left <= hx <= right and top <= hy <= bot):
                        x += 14.0
                        continue
                    if any((p["x"] - x) ** 2 + (p["y"] - y) ** 2 < 12.0 * 12.0 for p in props):
                        x += 14.0
                        continue
                    return {
                        "name": "",
                        "x": x,
                        "y": y,
                        "tex": tex,
                        "w": w,
                        "h": h,
                        "scale": scale,
                        "kind": kind,
                    }
                y += 16.0
    return None


def apply_scales(text: str, props: list[dict]) -> str:
    for prop in props:
        if prop["name"] == "":
            continue
        marker = f'[node name="{prop["name"]}"'
        start = text.find(marker)
        if start < 0:
            raise SystemExit(f"missing node {prop['name']}")
        end = text.find("\n[node ", start + 1)
        block = text[start:end]
        new_block, n = re.subn(
            r"sprite_scale = [0-9.]+",
            f"sprite_scale = {prop['scale']:.3f}",
            block,
            count=1,
        )
        if n != 1:
            raise SystemExit(f"scale line missing on {prop['name']}")
        text = text[:start] + new_block + text[end:]
    return text


def main() -> None:
    refuse_bake()
    text = SCENE.read_text()
    props = parse_props(text)
    art = load_art()
    before = holes(props)
    print(f"HOLES_BEFORE {len(before)}")
    grown = 0
    added: list[dict] = []
    pending = before
    guard = 0
    while pending and guard < 80:
        guard += 1
        hx, hy = pending[0]
        if try_grow(props, hx, hy):
            grown += 1
        else:
            placed = try_place(props, art, hx, hy)
            if placed is None:
                print(f"UNFILLED {hx:.1f} {hy:.1f}")
                pending = pending[1:]
                continue
            props.append(placed)
            added.append(placed)
        pending = holes(props)
    print(f"GROWN {grown} ADDED {len(added)} HOLES_AFTER {len(pending)}")
    if pending:
        raise SystemExit("forest holes remain")
    text = apply_scales(text, props)
    if added:
        uid = max(int(n) for n in re.findall(r"unique_id=(\d+)", text)) + 1
        tree_n = max(int(n) for n in re.findall(r'name="EdgeTree_(\d+)"', text))
        bush_n = max(int(n) for n in re.findall(r'name="EdgeBush_(\d+)"', text))
        extra = []
        if not text.endswith("\n"):
            extra.append("")
        for prop in added:
            if prop["kind"] == "tree":
                tree_n += 1
                name = f"EdgeTree_{tree_n:04d}"
                col = "Vector2(28, 16)"
            else:
                bush_n += 1
                name = f"EdgeBush_{bush_n:04d}"
                col = "Vector2(16, 10)"
            prop["name"] = name
            extra.append(
                "\n".join(
                    [
                        f'[node name="{name}" type="Node2D" parent="World" unique_id={uid} instance=ExtResource("{SOLID}")]',
                        "y_sort_enabled = true",
                        f"position = Vector2({prop['x']:.4f}, {prop['y']:.4f})",
                        f'script = ExtResource("{SCRIPT}")',
                        f'texture_path = "{prop["tex"]}"',
                        f"sprite_scale = {prop['scale']:.3f}",
                        f'prop_kind = "{prop["kind"]}"',
                        f"collider_size = {col}",
                        f'metadata/prop_kind = "{prop["kind"]}"',
                        f"metadata/collider_size = {col}",
                        "",
                    ]
                )
            )
            uid += 1
        text = text + "\n".join(extra)
        if not text.endswith("\n"):
            text += "\n"
    SCENE.write_text(text)
    trees = sum(1 for p in props if p["kind"] == "tree")
    bushes = sum(1 for p in props if p["kind"] == "bush")
    print(f"FOREST_FILL_OK trees={trees} bushes={bushes}")


if __name__ == "__main__":
    main()
