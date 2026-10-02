#!/usr/bin/env bash
# Ingest every Imagine download newer than prompts/attach (i.e. made for this task) as cand_1..n and print a score table.
set -e; cd /workspace/keeper_idle; PY=/workspace/art_refresh/tools/.venv/bin/python; k=0
for f in $(ls -tr /home/box/Downloads/*.jpg /home/box/Downloads/*.png 2>/dev/null); do
  [ "$f" -nt prompts/attach/ref_keeper_front_back_pair_magenta.png ] || continue
  k=$((k+1)); cp "$f" raw/cand_$k.$(echo "$f" | sed 's/.*\.//'); echo "cand_$k <- $f"
  $PY tools/ingest_turnaround.py "raw/cand_$k.${f##*.}" --name cand_$k || echo "  ingest failed for cand_$k"
done
for s in work/cand_*/score.json; do echo "== $s"; $PY -c "import json,sys;d=json.load(open('$s'));print({k:d[k] for k in d if k in ('src_heights','palette_overlap_mean','S_vs_live_idle_overlap','game_height_spread_px')})"; done
