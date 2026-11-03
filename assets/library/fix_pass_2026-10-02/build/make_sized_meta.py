import json
base = json.load(open('repo/assets/art/hub/hub_deco_meta.json'))
info = json.load(open('work/sized_info.json'))
basefam = {}
for fam, lst in base["families"].items():
    for e in lst: basefam[e["file"].rsplit('/',1)[1][:-4]] = (fam, e)
fams = {}
for rel, inf in sorted(info.items()):
    nm = rel.rsplit('/',1)[1][:-4]; src, s = nm.rsplit('_s',1); s = int(s)/100
    fam, be = basefam[src]; w, h = inf["size"]
    e = {"file": rel.replace("assets/art/",""), "variant_of": be["file"], "display_scale": s, "size": [w, h], "content": inf["content"],
         "anchor": "base_centre", "offset": [-w//2, -h], "kind": be["kind"], "collider": be["collider"], "sprite_scale": 1,
         "raw_px_factor": inf["raw_factor"]}
    if inf["raw_upscaled"]:
        e["note"] = "HD raw slice upscaled %.1f%% at this size (largest fully raw-backed large-tree size is ~1.18)" % ((inf["raw_factor"]-1)*100)
    fams.setdefault(fam, []).append(e)
meta = {"version": "v0.3.1-hub-native-sizes", "base_meta": "hub/hub_deco_meta.json (v0.3.0-hub-v3, unchanged; VERIFY asserts its version and counts)",
  "filter": "nearest", "density": "1 art px = 1 display px at sprite_scale 1",
  "what": "Size variants of the hub v3 ring trees / bushes, re-rendered from the HD raw slices (/workspace/hub_v3/work/*/slices) with the v3 pipeline at factor x display_scale. They replace the sprite_scale jitter in main.tscn; mapping: assets/library/fix_pass_2026-10-02/hub_native_size_map.json. Buckets round UP to the next 0.05 so no tree gets smaller than today (scene_sanity forest-coverage check).",
  "offset_rule": "Sprite2D centered=false, offset = (-w//2, -h) (forest_prop.gd computes (-w*0.5, -h); all widths are even, so identical)",
  "collider_note": "colliders are the per-node collider_size in main.tscn and are not scaled by sprite_scale today, so they stay unchanged",
  "families": fams}
json.dump(meta, open('repo/assets/art/hub/hub_deco_sized_meta.json','w'), indent=1)
print(sum(len(v) for v in fams.values()))
