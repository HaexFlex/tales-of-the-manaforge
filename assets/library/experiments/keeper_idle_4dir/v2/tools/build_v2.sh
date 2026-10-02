#!/usr/bin/env bash
# Keeper idle 4-dir v2: live hair on all 4 directions + north rune at 70 %. Reproduces work/cand_A3v2 keys and the frames.
set -e; cd /workspace/keeper_idle; PY=/workspace/art_refresh/tools/.venv/bin/python; OUT=${1:-v2/final48}
# 1. same sheet (cand A3), shared scale 5 % smaller (S body 116 px) so the new face = the live face size (eye spacing 11.4 vs live 11.5)
#    and the live hair fits 1:1 inside the 122 px height
$PY tools/ingest_turnaround.py raw/cand_A3.png --name cand_A3s --height 116
# 2. S: live hair transplanted pixel-exact (dx +1, dy -1 = eye alignment)
$PY v2/hair_s.py 1 -1 a
# 3. N: live S hair mirrored + back-of-head strands in the face opening; then the rune at 70 %
$PY v2/hair_n.py i
$PY v2/rune_n.py v2/work/N_i.png v2/work/N_i_rune_ax2.png axis
# 4. E: live S hair cut into a profile (axis at x 61, ear x 57); W = mirror of E at build time
$PY v2/hair_e.py d 61 0
mkdir -p work/cand_A3v2
cp v2/work/S_a.png work/cand_A3v2/key_S.png; cp v2/work/N_i_rune_ax2.png work/cand_A3v2/key_N.png; cp v2/work/E_d.png work/cand_A3v2/key_E.png
$PY v2/fill_holes.py work/cand_A3v2/key_S.png work/cand_A3v2/key_N.png work/cand_A3v2/key_E.png
$PY v2/clean_temple.py work/cand_A3v2/key_E.png
$PY v2/stray_green.py work/cand_A3v2/key_S.png work/cand_A3v2/key_E.png work/cand_A3v2/key_N.png
cp work/cand_A3v2/key_E.png work/cand_A3v2/key_W.png     # unused placeholder: W frames are mirrored E frames
# 5. frames (12 x 150 ms, shared 48-colour palette, same motion as v1), check
$PY tools/build_idles.py --cand cand_A3v2 --mirror-west --eyes work/eyes_A3v2.json --out "$OUT"
$PY tools/check_frames.py "$OUT"
