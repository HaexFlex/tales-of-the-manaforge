import re, json, collections
B = [round(0.80 + 0.05*i, 2) for i in range(16)]
txt = open('repo/scenes/main.tscn').read()
blocks = re.split(r'\n(?=\[)', txt)
rules = collections.defaultdict(dict); placements = []
for b in blocks:
    m = re.search(r'^texture_path = "([^"]+)"', b, re.M)
    s = re.search(r'^sprite_scale = ([0-9.]+)$', b, re.M)
    if not m or not s: continue
    t, raw = m.group(1), s.group(1); sc = float(raw)
    if abs(sc-1.0) < 1e-9: continue
    bk = min(c for c in B if c >= sc - 1e-9)   # round UP: never smaller than today (forest coverage)
    nm = t.rsplit('/',1)[1][:-4]; d = t.rsplit('/',1)[0]
    new = t if bk == 1.0 else f"{d}/sized/{nm}_s{int(round(bk*100)):03d}.png"
    rules[t][raw] = new
    node = re.search(r'name="([^"]+)"', b).group(1)
    placements.append({"node": node, "old_texture": t, "old_scale": sc, "bucket": bk, "new_texture": new, "new_scale": 1.0,
                       "size_error_pct": round((bk/sc-1)*100, 2)})
info = json.load(open('work/sized_info.json'))
out = {"version": "fix-pass-native-2026-10-02",
  "scene": "res://scenes/main.tscn",
  "what": "Per ForestProp in main.tscn: (texture_path, sprite_scale) -> new texture_path at sprite_scale 1.0. Variants are re-rendered from the hub v3 HD raws at the bucket size (not an upscale of the 1x PNG). Bucket 1.00 keeps the original file.",
  "buckets": B, "max_size_error_pct": round(max(abs(p['size_error_pct']) for p in placements), 2),
  "anchor": "base_centre; forest_prop.gd offset = (-w/2, -h) works unchanged for every variant",
  "untouched": "placements with sprite_scale 1.0 or no sprite_scale (all ground deco, flowers, rocks, mushrooms) need nothing",
  "apply_with": "python3 tools/apply_hub_native_sizes.py scenes/main.tscn --write   (dry run without --write)",
  "rules": {t: dict(sorted(v.items(), key=lambda kv: float(kv[0]))) for t, v in sorted(rules.items())},
  "files": {"res://"+k: v["size"] for k, v in sorted(info.items())},
  "placements": placements}
json.dump(out, open('repo/assets/library/fix_pass_2026-10-02/hub_native_size_map.json','w'), indent=1)
print(len(placements), out["max_size_error_pct"])
