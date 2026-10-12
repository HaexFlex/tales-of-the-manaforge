# Mossmites v2 – gnat/midge (Mücken) swarm battle sprites (draft, box only, not pushed)

Previous beetle set kept in legacy/beetles_v1/ (PNGs, previews, script, old README).

30 PNGs in `final/`: `battle_mossmite_<n>_{idle,attack,hurt}.png`, n = 1..10 bugs visible.

## Layout (matches v7 beasts)
- One 128x128 RGBA frame per file (no strip; same as every `battle/beasts/*` file, which are single-frame idle + hurt).
- Facing west (toward the party), like the beasts (`battle_view.gd`: "West-facing beast idle + hurt frames (128×128, soles on row 123)").
- Feet anchor: soles on row 123, cluster centred on x 63.5 (`FIGHTER_SOLE = (64, 123)`). Every idle/hurt file's bottom opaque row is 123; attack is shifted ~14 px west as a lunge.
- Anchor: each gnat has a 3 px dark ground shadow on row 123 (+1 px on row 122 for low flyers); gnats float 10–38 px above it.
- Gnat: 13x10 px, west-facing: pale opaque wings, dark head, mossy-green abdomen, proboscis/stinger forward, long dangling legs.
- Size: 10-gnat idle bbox 46x49 (x 40–85, y 75–123) vs Acorn Imp idle 32x52: about one imp footprint.
- Palette: 10 colours plus a pale hurt swap; dark warm-brown outline; no cyan, magenta or chroma green; hard alpha.
- Poses: idle = loose hovering cloud; attack = cloud darts about 16 px west with a longer stinger; hurt = scatter with a pale flash, some gnats flipped.
- The repo has no beast attack art (beasts ship only idle + hurt), so attack follows the same frame/anchor rules.
- Idle GIF: 3 seeded jitter frames (±1 px per gnat) at 110 ms; the PNG is frame 0.

## Tools
- `tools/draw_mossmites.py [outdir]` – seeded (Random(2000+n), jitter Random(100n+frame)), reproducible.
- `tools/previews.py` – contact_1x, contact_3x (idle/attack/hurt rows, Acorn Imp in column 1), idle_preview.gif (3 jitter frames, 2x).
- `tools/check_alpha.py` – checks alpha ∈ {0,255}, no magenta/green/cyan leftovers, 128x128, soles row 123.

## References
- /workspace/pr33_local/assets/art/battle/beasts/battle_acorn_imp_idle.png, _hurt.png (and other beasts there)
- /workspace/pr33_local/scripts/battle/battle_view.gd (FIGHTER_FRAME, FIGHTER_SOLE, v7 SLOT_SOLES)
- v7 mockups: /workspace/review_scratch/battle_ui_v7_6v6.png, final_6v6_v7.png

## v4 (current final/) – full set from approved v3 gnat
- final/ = 30 files from tools/draw_mossmites_v4.py; the 1/5/10 idles are pixel-identical to v3_stills/.
- Swarms 2–4 and 6–9: lerp between the approved 1→5 and 5→10 layouts (nearest-point matching, extra gnats grow out from the cloud centre), recentred on x 63.5.
- Attack = idle formation shifted 14 px west, 1–3 gnats flipped vertically (n=1: none). Hurt = shifted 10 px east, 1–3 flipped (n=1: the gnat). Palette identical to idle.
- Previous gnat set: legacy/gnats_v2/. Check: tools/check_alpha_v4.py. Previews: tools/previews_v4.py.
