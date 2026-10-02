#!/usr/bin/env python3
"""Repoint hub ForestProps to native-size variants so every ring tree / bush runs at sprite_scale 1.0.

  python3 tools/apply_hub_native_sizes.py [scenes/main.tscn] [--map PATH] [--write]

Reads assets/library/fix_pass_2026-10-02/hub_native_size_map.json ("rules": texture_path -> {old sprite_scale
string -> new texture_path}). For every node block in the scene whose texture_path + sprite_scale match a rule,
texture_path becomes the new file and sprite_scale becomes 1.0. Nothing else in the file changes (positions,
colliders, modulate, unique_ids, ext_resources). Without --write it only prints what it would do (dry run).
An unmatched non-1.0 scale on a mapped texture falls back to the nearest bucket file that exists on disk and is
reported. Pure Python 3 stdlib; run from the repo root.
"""
import argparse, json, os, re, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DEFAULT_MAP = os.path.join(ROOT, "assets/library/fix_pass_2026-10-02/hub_native_size_map.json")


def res_to_fs(p):
    return os.path.join(ROOT, p[len("res://"):]) if p.startswith("res://") else p


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("scene", nargs="?", default=os.path.join(ROOT, "scenes/main.tscn"))
    ap.add_argument("--map", default=DEFAULT_MAP)
    ap.add_argument("--write", action="store_true", help="rewrite the scene in place (default: dry run)")
    a = ap.parse_args()
    m = json.load(open(a.map))
    rules, buckets = m["rules"], m["buckets"]
    text = open(a.scene, encoding="utf-8").read()
    # split before every "[" section header that starts a line, keep separators intact
    parts = re.split(r"(?m)^(?=\[)", text)
    changed = fallback = missing = 0
    out = []
    for blk in parts:
        tm = re.search(r'(?m)^texture_path = "([^"]+)"$', blk)
        sm = re.search(r"(?m)^sprite_scale = ([0-9.]+)$", blk)
        if tm and sm and tm.group(1) in rules and abs(float(sm.group(1)) - 1.0) > 1e-9:
            tex, raw = tm.group(1), sm.group(1)
            new = rules[tex].get(raw)
            if new is None:                       # scale edited after the map was made: nearest bucket on disk
                sc = float(raw)
                for b in sorted(buckets, key=lambda c: abs(c / sc - 1)):
                    d, f = tex.rsplit("/", 1)
                    cand = tex if abs(b - 1.0) < 1e-9 else f"{d}/sized/{f[:-4]}_s{int(round(b * 100)):03d}.png"
                    if os.path.exists(res_to_fs(cand)):
                        new = cand; fallback += 1
                        print(f"fallback {tex} @ {raw} -> {cand} ({(b / sc - 1) * 100:+.1f}%)")
                        break
            if new is None or not os.path.exists(res_to_fs(new)):
                missing += 1
                print(f"MISSING file for {tex} @ {raw}: {new}", file=sys.stderr)
            else:
                blk = blk[:tm.start(1)] + new + blk[tm.end(1):]
                sm = re.search(r"(?m)^sprite_scale = ([0-9.]+)$", blk)
                blk = blk[:sm.start(1)] + "1.0" + blk[sm.end(1):]
                changed += 1
        out.append(blk)
    new_text = "".join(out)
    print(f"{changed} props repointed to scale 1.0 ({fallback} via fallback, {missing} missing) in {a.scene}")
    if missing:
        sys.exit(1)
    if a.write:
        open(a.scene, "w", encoding="utf-8").write(new_text)
        print("written")
    else:
        print("dry run (add --write to save)")


if __name__ == "__main__":
    main()
