"""Write the v2 deliverables: per-clip frames / strip / meta / GIFs, comparison GIFs (walk vs clip, same scale + timing,
1x and 2x), a contact sheet."""
import json, sys, shutil
from pathlib import Path
import numpy as np
from PIL import Image, ImageDraw
sys.path.insert(0, "/workspace/keeper_anims/v2/tools"); sys.path.insert(0, "/workspace/keeper_anims/tools")
import build_v2 as B
from kparts import grass_bg, save_gif

FINAL = B.V2 / "final"
PROPS = B.REPO if hasattr(B, "REPO") else None
PROPS = Path("/workspace/keeper_anims/repo/assets/art/props")
K = B.K
GRASS = (78, 128, 52, 255)
WALK = [B.load(K / f"keeper_walk_south_{i:04d}.png") for i in range(1, 10)]

def label(img, items, scale):
    d = ImageDraw.Draw(img)
    for x, y, t in items:
        d.rectangle([x * scale + 2, y * scale + 2, x * scale + 6 + 6 * len(t), y * scale + 14], fill=(0, 0, 0, 170))
        d.text((x * scale + 4, y * scale + 3), t, fill=(255, 255, 255, 255))
    return img

def cell(f, cw):
    """put a frame into a cw-wide cell with the feet centred (walk 128 -> offset (cw-128)/2)."""
    c = Image.new("RGBA", (cw, 128), (0, 0, 0, 0)); c.alpha_composite(f, ((cw - f.width) // 2, 0)); return c

def target(kind):
    if kind == "tree":
        return B.load(PROPS / "harvest_tree.png").crop((95, 200, 200, 384))
    if kind == "bush":
        t = B.load(PROPS / "native/berry_harvest_node.png"); return t.crop(t.getbbox())
    t = B.load(PROPS / "harvest_stone.png"); t = t.crop(t.getbbox()); return t.resize((t.width * 30 // t.height, 30), Image.NEAREST)

def preview(name, frames, cw, kind, impact):
    t = target(kind)
    W = cw + 60; H = 140; ox, oy = 4, 8
    if kind == "tree":   tx, ty = impact[0] - 4, oy + 132 - t.height
    elif kind == "bush": tx, ty = impact[0] - 14, oy + 130 - t.height
    else:                tx, ty = impact[0] - t.width // 2 + 2, oy + impact[1] - 8
    bg = grass_bg(W, H, seed=5)
    comp = []
    for f in frames:
        sc = bg.copy(); sc.alpha_composite(t, (ox + tx, ty)); sc.alpha_composite(f, (ox, oy)); comp.append(sc)
    return comp

def main():
    if FINAL.exists(): shutil.rmtree(FINAL)
    FINAL.mkdir(parents=True)
    built = {}
    for name, c in B.CLIPS.items():
        frames, info = B.build_frames(name)
        cw = c["cw"]; d = FINAL / name; d.mkdir()
        for i, f in enumerate(frames, 1): f.save(d / f"keeper_{name}_{i:04d}.png")
        strip = Image.new("RGBA", (cw * 9, 128), (0, 0, 0, 0))
        for i, f in enumerate(frames): strip.paste(f, (i * cw, 0))
        strip.save(d / f"keeper_{name}.png")
        st = c["strike"]; imp = info[st - 1]["impact_game"]
        comp = preview(name, frames, cw, c["target"], imp)
        save_gif(comp, [B.HOLD] * 9, d / f"keeper_{name}.gif", scale=1)
        save_gif(comp, [B.HOLD] * 9, d / f"keeper_{name}_x2.gif", scale=2)
        meta = {"clip": name, "status": "experiment - not wired into the game",
                "canvas": [cw, 128], "anchor": "feet_center", "anchor_px": [cw // 2, 128], "sprite_offset": [-(cw // 2), -128],
                "keeper_scale": "pixel-identical to keeper_walk_south_0001 (same NN x0.5 of the native 170x256 frame); in a 192 canvas the 128 walk frame sits at x+32",
                "filter": "nearest", "frames": 9, "hold_ms": B.HOLD, "loop_ms": 9 * B.HOLD, "loop": True,
                "strip": f"keeper_{name}.png", "layout": "horizontal",
                "files": [f"keeper_{name}_{i:04d}.png" for i in range(1, 10)],
                "strike_frame": st, "strike_frame_index0": st - 1, "strike_at_ms": (st - 1) * B.HOLD,
                "pulse_sync": f"walk timing (9 x 100 ms = 900 ms). The tool harvest pulse is 1000 ms: either restart the clip on each pulse {(st - 1) * B.HOLD} ms early (frame 9 then holds ~100 ms longer), or play at speed_scale 0.9 so one loop = 1000 ms.",
                "tool": c["tool"], "poses": [i["pose"] for i in info],
                "source": "keeper_walk_south_0001 native (assets/art/keeper/native/keeper_walk_south_0001_256.png), cut-and-rotate rig (v2/tools/rig.py, build_v2.py)",
                "palette": "every visible pixel RGB is a colour that occurs in keeper_walk_south_0001..0009"}
        (d / f"keeper_{name}.json").write_text(json.dumps(meta, indent=2))
        built[name] = (frames, cw)
        print(name, "impact", imp)
    # ---- comparison GIFs: walk | clip, same scale, same 100 ms timing (9 frames each, frame-locked)
    cmp = FINAL / "compare"; cmp.mkdir()
    def compare(names, fname):
        cws = [max(built[n][1] for n in names)] + [built[n][1] for n in names]
        W = sum(cws); H = 136
        out = []
        for i in range(9):
            sc = Image.new("RGBA", (W, H), GRASS); x = 0
            sc.alpha_composite(cell(WALK[i], cws[0]), (x, 8)); x += cws[0]
            for n, cw in zip(names, cws[1:]):
                sc.alpha_composite(built[n][0][i], (x, 8)); x += cw
            out.append(sc)
        labels = [("walk_south (live)", 0)] + [(n, sum(cws[:k + 1])) for k, n in enumerate(names)]
        for sc_, s in ((1, ""), (2, "_x2")):
            fr = []
            for i, f in enumerate(out):
                g = f.resize((W * sc_, H * sc_), Image.NEAREST) if sc_ != 1 else f.copy()
                if sc_ == 2: label(g, [(x, 0, t + f"  f{i + 1}") for t, x in labels], 2)
                fr.append(g)
            save_gif(fr, [B.HOLD] * 9, cmp / f"{fname}{s}.gif", scale=1)
    for n in B.CLIPS: compare([n], f"compare_walk_vs_{n}")
    compare(list(B.CLIPS), "compare_walk_vs_all")
    # ---- contact sheet (x2): walk row + one row per clip, 9 columns, cell 192 wide, feet aligned
    CWc = 192; rows = [("walk_south (live)", [cell(w, CWc) for w in WALK], None)] + \
        [(n, [cell(f, CWc) for f in built[n][0]], B.CLIPS[n]["strike"]) for n in B.CLIPS]
    sheet = Image.new("RGBA", (CWc * 9, 128 * len(rows)), GRASS)
    for r, (n, fr, st) in enumerate(rows):
        for i, f in enumerate(fr):
            if st and i + 1 == st:
                ImageDraw.Draw(sheet).rectangle([i * CWc, r * 128, (i + 1) * CWc - 1, (r + 1) * 128 - 1], fill=(98, 146, 62, 255))
            sheet.alpha_composite(f, (i * CWc, r * 128))
    big = sheet.resize((sheet.width * 2, sheet.height * 2), Image.NEAREST); d = ImageDraw.Draw(big)
    for r, (n, fr, st) in enumerate(rows):
        for i in range(9):
            t = f"{n} f{i + 1}" + ("  STRIKE" if st and i + 1 == st else "") if i == 0 or (st and i + 1 == st) else f"f{i + 1}"
            label(big, [(i * CWc, r * 128, t)], 2)
        d.line([(0, r * 256), (big.width, r * 256)], fill=(20, 20, 20, 255), width=2)
    for i in range(1, 9): d.line([(i * CWc * 2, 0), (i * CWc * 2, big.height)], fill=(40, 60, 30, 255), width=1)
    big.save(FINAL / "contact_sheet_x2.png")
    sheet.save(FINAL / "contact_sheet.png")

if __name__ == "__main__":
    main()
