#!/usr/bin/env python3
"""One-off writer: replace the hub forest ring in scenes/main.tscn.

Run by hand. It edits the scene file and exits. It is not a runtime bake,
and it refuses MANAFORGE_BAKE. Do not call it from the game.
"""

from __future__ import annotations

import json
import math
import os
import random
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SCENE = ROOT / "scenes" / "main.tscn"
HUB = ROOT / "data" / "hub_map.json"
TREE_DIR = ROOT / "assets" / "art" / "hub" / "trees"
BUSH_DIR = ROOT / "assets" / "art" / "hub" / "bushes"

CX, CY = 2160.0, 2025.0
RX, RY = 1620.0, 1323.0
CAM_L, CAM_T, CAM_R, CAM_B = 180.0, 180.0, 4140.0, 3600.0
DROP_PREFIXES = ("Tree_", "Bush_", "Hem_", "Canopy_", "RingBush_", "RingTree_")
SOLID = "13_vxglm"
SCRIPT = "14_2f3dj"
NODE_HEAD = re.compile(r'^\[node name="([^"]+)"(?: type="[^"]+")?(?: parent="([^"]+)")?')
POS_RE = re.compile(r"position = Vector2\(([-\d.]+), ([-\d.]+)\)")
UID_RE = re.compile(r"unique_id=(\d+)")


def refuse_bake() -> None:
    if os.environ.get("MANAFORGE_BAKE") == "1":
        sys.exit("refusing: MANAFORGE_BAKE is set. This writer is not the hub bake.")


def png_size(path: Path) -> tuple[int, int]:
    data = path.read_bytes()
    if data[:8] != b"\x89PNG\r\n\x1a\n":
        raise SystemExit(f"not a png: {path}")
    return int.from_bytes(data[16:20], "big"), int.from_bytes(data[20:24], "big")


def limit_at(ang: float) -> float:
    wobble = (
        0.075 * math.sin(ang * 3.0 + 0.55)
        + 0.055 * math.sin(ang * 5.0 + 2.15)
        + 0.040 * math.cos(ang * 2.0 + 0.35)
        + 0.028 * math.sin(ang * 7.0 + 1.15)
    )
    return max(0.72, 1.0 + wobble)


def ellipse_norm(x: float, y: float) -> float:
    dx = (x - CX) / RX
    dy = (y - CY) / RY
    ang = math.atan2(dy, dx)
    radius = math.hypot(dx, dy)
    return radius / limit_at(ang)


def point_at(ang: float, norm: float) -> tuple[float, float]:
    radius = norm * limit_at(ang)
    return CX + math.cos(ang) * radius * RX, CY + math.sin(ang) * radius * RY


def load_art() -> tuple[dict, dict]:
    trees: dict[str, list] = {"large": [], "medium": [], "slim": []}
    bushes: dict[str, list] = {"big": [], "small": []}
    for path in sorted(TREE_DIR.glob("ring_tree_*.png")):
        w, h = png_size(path)
        rel = "res://assets/art/hub/trees/" + path.name
        if "large" in path.name:
            trees["large"].append((rel, w, h))
        elif "medium" in path.name:
            trees["medium"].append((rel, w, h))
        else:
            trees["slim"].append((rel, w, h))
    for path in sorted(BUSH_DIR.glob("ring_bush_*.png")):
        w, h = png_size(path)
        rel = "res://assets/art/hub/bushes/" + path.name
        key = "big" if "big" in path.name else "small"
        bushes[key].append((rel, w, h))
    for key, items in list(trees.items()) + list(bushes.items()):
        if not items:
            raise SystemExit(f"missing ring art for {key}")
    return trees, bushes


class FootGrid:
    def __init__(self, cell: float = 96.0) -> None:
        self.cell = cell
        self.bins: dict[tuple[int, int], list[tuple[float, float]]] = {}

    def add(self, x: float, y: float) -> None:
        key = (int(x // self.cell), int(y // self.cell))
        self.bins.setdefault(key, []).append((x, y))

    def near(self, x: float, y: float, dist: float) -> bool:
        reach = int(dist // self.cell) + 1
        ix, iy = int(x // self.cell), int(y // self.cell)
        dist2 = dist * dist
        for dx in range(-reach, reach + 1):
            for dy in range(-reach, reach + 1):
                for px, py in self.bins.get((ix + dx, iy + dy), ()):
                    if (px - x) ** 2 + (py - y) ** 2 < dist2:
                        return True
        return False


class Cover:
    def __init__(self, cell: float = 256.0) -> None:
        self.cell = cell
        self.bins: dict[tuple[int, int], list[tuple[float, float, float, float]]] = {}

    def add(self, rect: tuple[float, float, float, float]) -> None:
        left, top, right, bot = rect
        x0, x1 = int(left // self.cell), int(right // self.cell)
        y0, y1 = int(top // self.cell), int(bot // self.cell)
        for ix in range(x0, x1 + 1):
            for iy in range(y0, y1 + 1):
                self.bins.setdefault((ix, iy), []).append(rect)

    def covers(self, x: float, y: float) -> bool:
        for left, top, right, bot in self.bins.get((int(x // self.cell), int(y // self.cell)), ()):
            if left <= x <= right and top <= y <= bot:
                return True
        return False


def sprite_rect(x: float, y: float, w: int, h: int, scale: float) -> tuple[float, float, float, float]:
    sw = w * scale
    sh = h * scale
    return (x - sw * 0.5, y - sh, x + sw * 0.5, y)


def corners_ok(x: float, y: float, w: int, h: int, scale: float, min_norm: float = 0.90) -> bool:
    left, top, right, bot = sprite_rect(x, y, w, h, scale)
    for px, py in ((left, top), (right, top), (left, bot), (right, bot)):
        if ellipse_norm(px, py) < min_norm:
            return False
    return True


def dist_seg(px: float, py: float, ax: float, ay: float, bx: float, by: float) -> float:
    abx, aby = bx - ax, by - ay
    den = abx * abx + aby * aby
    if den <= 0.0001:
        return math.hypot(px - ax, py - ay)
    t = max(0.0, min(1.0, ((px - ax) * abx + (py - ay) * aby) / den))
    return math.hypot(px - (ax + abx * t), py - (ay + aby * t))


def load_keepouts() -> tuple[list, list, tuple]:
    hub = json.loads(HUB.read_text())
    marks = hub["landmarks"]
    order = ["manatree", "harvest_tree", "harvest_stone", "harvest_berry", "keeper"]
    radii = hub["clear_radii"]
    points = []
    for i, name in enumerate(order):
        pos = marks[name]
        rad = float(radii[i])
        if i == 0:
            rad = 200.0
        elif rad < 100.0:
            rad += 12.0
        points.append((float(pos[0]), float(pos[1]), rad))
    for extra in hub.get("extra_clear", []):
        pos = extra["pos"]
        points.append((float(pos[0]), float(pos[1]), float(extra["radius"])))
    stone_clear = float(hub.get("runestone_clear", 84.0))
    if stone_clear < 100.0:
        stone_clear += 12.0
    for stone in hub.get("runestones", []):
        pos = stone["pos"]
        points.append((float(pos[0]), float(pos[1]), stone_clear))
    segs = []
    for entry in hub.get("paths", []):
        pts = entry.get("points", [])
        for i in range(len(pts) - 1):
            segs.append((float(pts[i][0]), float(pts[i][1]), float(pts[i + 1][0]), float(pts[i + 1][1])))
    meta = json.loads((ROOT / "assets/art/manatree/native/manatree_meta.json").read_text())
    rects = []
    for stage in meta["stages"]:
        w, h = stage["size"]
        sc = float(stage.get("display_scale", 1.0))
        dx, dy = stage["door_floor"]
        rects.append((2160.0 - dx * sc, 2106.0 - dy * sc, w * sc, h * sc))
    left = min(r[0] for r in rects) - 96.0
    top = min(r[1] for r in rects) - 96.0
    right = max(r[0] + r[2] for r in rects) + 96.0
    bot = max(r[1] + r[3] for r in rects) + 96.0
    return points, segs, (left, top, right, bot)


def spot_ok(x: float, y: float, points, segs, exclusion) -> bool:
    for px, py, rad in points:
        if math.hypot(x - px, y - py) < rad:
            return False
    for ax, ay, bx, by in segs:
        if dist_seg(x, y, ax, ay, bx, by) < 36.0:
            return False
    left, top, right, bot = exclusion
    if left <= x <= right and top <= y <= bot:
        return False
    return True


def fmt(n: float) -> str:
    return f"{n:.4f}".rstrip("0").rstrip(".")


def prop_block(name: str, uid: int, x: float, y: float, tex: str, scale: float, kind: str, col: tuple[float, float], flip: bool) -> str:
    lines = [
        f'[node name="{name}" type="Node2D" parent="World" unique_id={uid} instance=ExtResource("{SOLID}")]',
        "y_sort_enabled = true",
        f"position = Vector2({fmt(x)}, {fmt(y)})",
        f'script = ExtResource("{SCRIPT}")',
        f'texture_path = "{tex}"',
        f"sprite_scale = {scale:.3f}",
        f'prop_kind = "{kind}"',
        f"collider_size = Vector2({fmt(col[0])}, {fmt(col[1])})",
        f'metadata/prop_kind = "{kind}"',
        f"metadata/collider_size = Vector2({fmt(col[0])}, {fmt(col[1])})",
        "",
    ]
    if flip:
        lines.extend(
            [
                f'[node name="Sprite" parent="World/{name}" index="0"]',
                "flip_h = true",
                "",
            ]
        )
    return "\n".join(lines)


def main() -> None:
    refuse_bake()
    rng = random.Random(8111)
    trees, bushes = load_art()
    points, segs, exclusion = load_keepouts()
    text = SCENE.read_text()
    max_uid = max(int(n) for n in UID_RE.findall(text))
    uid = max_uid + 1

    parts = text.split("\n[node ")
    header = parts[0]
    kept: list[str] = []
    dropped = 0
    nudged = 0
    for raw in parts[1:]:
        block = "[node " + raw
        if not block.endswith("\n"):
            block += "\n"
        match = NODE_HEAD.match(block)
        if match is None:
            kept.append(block)
            continue
        name, parent = match.group(1), match.group(2) or ""
        parent_hit = any(part.startswith(DROP_PREFIXES) for part in parent.split("/")) if parent else False
        if name.startswith(DROP_PREFIXES) or parent_hit:
            dropped += 1
            continue
        if name.startswith("GroundDeco_"):
            pos = POS_RE.search(block)
            if pos:
                x, y = float(pos.group(1)), float(pos.group(2))
                if ellipse_norm(x, y) >= 0.88:
                    ang = math.atan2((y - CY) / RY, (x - CX) / RX)
                    moved = False
                    candidates = []
                    for norm in (0.84, 0.82, 0.80, 0.78, 0.76, 0.74, 0.72, 0.70):
                        for dang in (0.0, 0.05, -0.05, 0.1, -0.1, 0.16, -0.16):
                            candidates.append(point_at(ang + dang, norm))
                    for radius in range(30, 420, 24):
                        for step in range(12):
                            a = step * math.tau / 12.0
                            candidates.append((x + math.cos(a) * radius, y + math.sin(a) * radius))
                    for nx, ny in candidates:
                        if ellipse_norm(nx, ny) > 0.86:
                            continue
                        if spot_ok(nx, ny, points, segs, exclusion):
                            block = POS_RE.sub(f"position = Vector2({fmt(nx)}, {fmt(ny)})", block, count=1)
                            nudged += 1
                            moved = True
                            break
                    if not moved:
                        print(f"WARN ground deco {name} stayed at norm {ellipse_norm(x, y):.3f}")
        kept.append(block)

    placed: list[dict] = []
    feet = FootGrid(80.0)

    def try_add(x: float, y: float, kind: str, art_key: str, min_dist: float, scale: float | None = None) -> bool:
        catalog = trees if kind == "tree" else bushes
        art = rng.choice(catalog[art_key])
        tex, w, h = art
        sc = scale if scale is not None else rng.uniform(0.94, 1.12)
        if feet.near(x, y, min_dist):
            return False
        if not corners_ok(x, y, w, h, sc):
            return False
        if ellipse_norm(x, y) < 1.03:
            return False
        feet.add(x, y)
        placed.append(
            {
                "x": x,
                "y": y,
                "kind": kind,
                "tex": tex,
                "w": w,
                "h": h,
                "scale": sc,
                "flip": rng.random() < 0.48,
                "col": (28.0, 16.0) if kind == "tree" else (16.0, 10.0),
            }
        )
        return True

    bands = [
        (1.06, 1.16, ("slim", "medium", "medium"), 128.0),
        (1.16, 1.32, ("medium", "large", "slim"), 150.0),
        (1.30, 1.50, ("large", "large", "medium"), 168.0),
        (1.48, 1.72, ("large", "medium", "large"), 188.0),
        (1.68, 2.05, ("large", "large"), 210.0),
    ]
    for lo, hi, kinds, spacing in bands:
        ang = rng.uniform(0.0, 0.15)
        guard = 0
        while ang < math.tau * 2 and guard < 4000:
            guard += 1
            if ang >= math.tau:
                break
            norm = rng.uniform(lo, hi)
            x, y = point_at(ang, norm)
            x += rng.uniform(-18.0, 18.0)
            y += rng.uniform(-14.0, 14.0)
            try_add(x, y, "tree", rng.choice(kinds), spacing * 0.62)
            radius = math.hypot(math.cos(ang) * RX, math.sin(ang) * RY) * norm
            ang += (spacing * rng.uniform(0.72, 1.28)) / max(radius, 200.0)

    def border_feet(px: float, py: float, along: str) -> None:
        art_key = rng.choice(("large", "large", "medium"))
        tex, w, h = rng.choice(trees[art_key])
        sc = rng.uniform(0.98, 1.14)
        sw, sh = w * sc, h * sc
        if along == "top":
            x, y = px + rng.uniform(-20, 20), 180.0 + sh - rng.uniform(8, 28)
        elif along == "bottom":
            x, y = px + rng.uniform(-20, 20), 3600.0 + rng.uniform(28, 90)
        elif along == "left":
            x, y = 180.0 + sw * 0.5 - rng.uniform(4, 18), py
        else:
            x, y = 4140.0 - sw * 0.5 + rng.uniform(4, 18), py
        try_add(x, y, "tree", art_key, 70.0, sc)

    x = CAM_L
    while x <= CAM_R:
        border_feet(x, 400.0, "top")
        border_feet(x, 3400.0, "bottom")
        x += rng.uniform(150.0, 210.0)
    y = CAM_T + 80.0
    while y <= CAM_B:
        border_feet(300.0, y, "left")
        border_feet(4000.0, y, "right")
        y += rng.uniform(150.0, 210.0)

    # Outer hem inside the camera limit, jittered so it is not a grid.
    gx = CAM_L + 40.0
    while gx < CAM_R:
        gy = CAM_T + 40.0
        while gy < CAM_B:
            jx = gx + rng.uniform(-70.0, 70.0)
            jy = gy + rng.uniform(-60.0, 60.0)
            if ellipse_norm(jx, jy) >= 1.22:
                try_add(jx, jy, "tree", rng.choice(("large", "large", "medium")), 96.0)
            gy += 210.0
        gx += 220.0

    tree_list = [p for p in placed if p["kind"] == "tree"]
    bush_target = max(40, int(len(tree_list) * 0.38))
    rng.shuffle(tree_list)
    for tree in tree_list:
        if sum(1 for p in placed if p["kind"] == "bush") >= bush_target:
            break
        ang = math.atan2((tree["y"] - CY) / RY, (tree["x"] - CX) / RX)
        for _ in range(4):
            dang = rng.uniform(-0.08, 0.08)
            norm = ellipse_norm(tree["x"], tree["y"]) + rng.uniform(-0.06, 0.08)
            bx, by = point_at(ang + dang, max(1.05, norm))
            bx += rng.uniform(-36, 36)
            by += rng.uniform(-24, 24)
            key = "small" if rng.random() < 0.55 else "big"
            if try_add(bx, by, "bush", key, 46.0):
                break

    cover = Cover()
    for prop in placed:
        cover.add(sprite_rect(prop["x"], prop["y"], prop["w"], prop["h"], prop["scale"]))

    def hole_points() -> list[tuple[float, float]]:
        holes = []
        samples = []
        x = CAM_L
        while x <= CAM_R + 0.1:
            y = CAM_T
            while y <= CAM_B + 0.1:
                samples.append((x, y))
                y += 28.0
            x += 28.0
        for edge_x in (CAM_L + 8, (CAM_L + CAM_R) * 0.5, CAM_R - 8):
            samples.append((edge_x, CAM_T + 8))
            samples.append((edge_x, CAM_B - 8))
        for edge_y in (CAM_T + 8, (CAM_T + CAM_B) * 0.5, CAM_B - 8):
            samples.append((CAM_L + 8, edge_y))
            samples.append((CAM_R - 8, edge_y))
        for sx, sy in samples:
            if ellipse_norm(sx, sy) < 0.97:
                continue
            if not cover.covers(sx, sy):
                holes.append((sx, sy))
        return holes

    def grow_to_cover(sx: float, sy: float) -> bool:
        ranked = []
        for prop in placed:
            if prop["kind"] != "tree":
                continue
            dist = math.hypot(prop["x"] - sx, prop["y"] - sy)
            if dist <= 480.0:
                ranked.append((dist, prop))
        ranked.sort(key=lambda item: item[0])
        for _dist, prop in ranked[:8]:
            w, h = prop["w"], prop["h"]
            for sc in (prop["scale"] + 0.08, prop["scale"] + 0.16, 1.22, 1.34):
                if sc > 1.36:
                    continue
                left, top, right, bot = sprite_rect(prop["x"], prop["y"], w, h, sc)
                if left <= sx <= right and top <= sy <= bot and corners_ok(prop["x"], prop["y"], w, h, sc):
                    prop["scale"] = sc
                    cover.add((left, top, right, bot))
                    return True
        return False

    for _pass in range(8):
        holes = hole_points()
        if not holes:
            break
        rng.shuffle(holes)
        added = 0
        for sx, sy in holes:
            if cover.covers(sx, sy):
                continue
            if grow_to_cover(sx, sy):
                added += 1
                continue
            placed_one = False
            options = [("tree", "slim"), ("tree", "medium"), ("tree", "large"), ("bush", "big"), ("bush", "small")]
            for kind, art_key in options:
                catalog = trees if kind == "tree" else bushes
                tex, w, h = rng.choice(catalog[art_key])
                for sc in (0.78, 0.86, 0.94, 1.02, 1.12):
                    sw, sh = w * sc, h * sc
                    for fy_t in (0.2, 0.45, 0.7, 0.9):
                        fy = sy + max(10.0, sh * fy_t)
                        if fy > sy + sh - 4:
                            fy = sy + sh - 4
                        for fx_t in (0.0, 0.22, -0.18, 0.4):
                            fx = sx + sw * fx_t
                            fx = min(max(fx, sx - sw * 0.5 + 4), sx + sw * 0.5 - 4)
                            if feet.near(fx, fy, 8.0):
                                continue
                            if not corners_ok(fx, fy, w, h, sc):
                                continue
                            if ellipse_norm(fx, fy) < 0.945:
                                continue
                            rect = sprite_rect(fx, fy, w, h, sc)
                            if not (rect[0] <= sx <= rect[2] and rect[1] <= sy <= rect[3]):
                                continue
                            feet.add(fx, fy)
                            prop = {
                                "x": fx,
                                "y": fy,
                                "kind": kind,
                                "tex": tex,
                                "w": w,
                                "h": h,
                                "scale": sc,
                                "flip": rng.random() < 0.5,
                                "col": (28.0, 16.0) if kind == "tree" else (16.0, 10.0),
                            }
                            placed.append(prop)
                            cover.add(rect)
                            added += 1
                            placed_one = True
                            break
                        if placed_one:
                            break
                    if placed_one:
                        break
                if placed_one:
                    break
        print(f"fill pass {_pass} holes {len(holes)} added {added}")
        if added == 0:
            break

    holes = hole_points()
    if holes:
        for sx, sy in holes[:12]:
            print(f"HOLE {sx:.1f} {sy:.1f} norm {ellipse_norm(sx, sy):.3f}")
        raise SystemExit(f"forest still has {len(holes)} camera holes")

    # Closed inner wall: overlapping rectangles, no slit.
    wall_norm = 0.962
    segments = []
    ang = 0.0
    samples = []
    while ang < math.tau:
        samples.append(point_at(ang, wall_norm))
        ang += 0.012
    pts = [samples[0]]
    for sx, sy in samples[1:]:
        if math.hypot(sx - pts[-1][0], sy - pts[-1][1]) >= 52.0:
            pts.append((sx, sy))
    if math.hypot(pts[0][0] - pts[-1][0], pts[0][1] - pts[-1][1]) < 30.0:
        pts.pop()
    for i, (x1, y1) in enumerate(pts):
        x2, y2 = pts[(i + 1) % len(pts)]
        length = math.hypot(x2 - x1, y2 - y1) * 1.62
        thick = 124.0
        mx, my = (x1 + x2) * 0.5, (y1 + y2) * 0.5
        rot = math.atan2(y2 - y1, x2 - x1)
        segments.append((mx, my, rot, length, thick))

    blocks = []
    blocks.append('[node name="ForestEdge" type="StaticBody2D" parent="World"]')
    blocks.append("collision_layer = 1")
    blocks.append("collision_mask = 0")
    blocks.append("")
    for i, (mx, my, rot, length, thick) in enumerate(segments):
        sid = f"RectangleShape2D_edge_{i:04d}"
        blocks.append(f'[sub_resource type="RectangleShape2D" id="{sid}"]')
        blocks.append(f"size = Vector2({fmt(length)}, {fmt(thick)})")
        blocks.append("")
        blocks.append(f'[node name="Seg{i:04d}" type="CollisionShape2D" parent="World/ForestEdge"]')
        blocks.append(f"position = Vector2({fmt(mx)}, {fmt(my)})")
        blocks.append(f"rotation = {rot:.6f}")
        blocks.append(f'shape = SubResource("{sid}")')
        blocks.append("")

    tree_i = 0
    bush_i = 0
    for prop in placed:
        if prop["kind"] == "tree":
            tree_i += 1
            name = f"EdgeTree_{tree_i:04d}"
        else:
            bush_i += 1
            name = f"EdgeBush_{bush_i:04d}"
        blocks.append(
            prop_block(name, uid, prop["x"], prop["y"], prop["tex"], prop["scale"], prop["kind"], prop["col"], prop["flip"])
        )
        uid += 1

    # Subresources must live before nodes. Split the edge body from the shapes.
    shape_chunks = []
    node_chunks = []
    chunk = []
    mode = "node"
    for line in "\n".join(blocks).split("\n"):
        if line.startswith("[sub_resource "):
            if chunk:
                (shape_chunks if mode == "sub" else node_chunks).append("\n".join(chunk).rstrip() + "\n")
            chunk = [line]
            mode = "sub"
        elif line.startswith("[node "):
            if chunk:
                (shape_chunks if mode == "sub" else node_chunks).append("\n".join(chunk).rstrip() + "\n")
            chunk = [line]
            mode = "node"
        else:
            chunk.append(line)
    if chunk:
        (shape_chunks if mode == "sub" else node_chunks).append("\n".join(chunk).rstrip() + "\n")

    if not header.endswith("\n"):
        header += "\n"
    header = header + "".join(shape_chunks)
    if not header.endswith("\n"):
        header += "\n"
    out = header + "".join(kept).rstrip() + "\n\n" + "\n".join(node_chunks)
    if not out.endswith("\n"):
        out += "\n"
    SCENE.write_text(out)
    print(f"DROPPED {dropped}")
    print(f"NUDGED {nudged}")
    print(f"TREES {tree_i}")
    print(f"BUSHES {bush_i}")
    print(f"WALL_SEGS {len(segments)}")
    print("FOREST_EDGE_OK")


if __name__ == "__main__":
    main()
