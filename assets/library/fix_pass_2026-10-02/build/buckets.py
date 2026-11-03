import re, json, collections
B = [round(0.80 + 0.05*i, 2) for i in range(16)]   # 0.80 .. 1.55
txt = open('repo/scenes/main.tscn').read()
blocks = re.split(r'\n(?=\[)', txt)
use = collections.defaultdict(set); place = []
for b in blocks:
    m = re.search(r'^texture_path = "([^"]+)"', b, re.M)
    s = re.search(r'^sprite_scale = ([0-9.]+)', b, re.M)
    if not m or not s: continue
    t, sc = m.group(1), float(s.group(1))
    if abs(sc-1.0) < 1e-9: continue
    nm = re.search(r'name="([^"]+)"', b).group(1)
    bk = min(c for c in B if c >= sc - 1e-9)   # round UP: never smaller than today (forest coverage)
    use[t].add(bk); place.append((nm, t, sc, bk, round(c/sc-1 if (c:=bk) else 0, 4)))
buckets = {t.split('/')[-1][:-4]: sorted(v - {1.0}) for t, v in use.items()}
json.dump(buckets, open('work/buckets.json','w'), indent=1)
print(json.dumps(buckets)); print(len(place), 'placements; max err', max(abs(p[4]) for p in place))
print(sum(len(v) for v in buckets.values()), 'files')
