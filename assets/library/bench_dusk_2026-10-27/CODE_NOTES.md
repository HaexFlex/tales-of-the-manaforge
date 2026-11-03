# Bench dusk props (2026-10-27)
- assets/art/hub/bench_props/teacup_8x8.png (8x8), teacup_steam_strip_5x7x4.png (20x7, 4 frames, loop 150 ms/frame).
- assets/art/hub/bench_props/blanket_draped_30x20.png (30x20): dusk moss blanket, cream stripes, cyan thread, draped over the front edge.
Colours: bench browns (#2a180b #734929 #ad7141), cream #e9da8d, dusk-tile greens #143529/#1f4b35/#35703b, cyan #3de7ca.
Placement (Sprite2D children of KeepersBench, centered=false, offsets from the node origin = bench feet, sprite drawn at (-96,-192)):
- Teacup top-left at (46,-100): on the tabletop just left of the lantern. Steam top-left at (48,-107), directly above the cup.
- Blanket top-left at (-74,-96): folded over the front-left edge of the table, right of the vise.
- z_index +1 over the bench sprite. Show both on keeper_bench_sat when the hub phase is dusk/night; hide on keeper_bench_stood.
Note: the live Bench (forge/bench_idle.png) is a 192 px workbench; the Keeper's seat spot is Code's (seat ~23 px above feet line, facing south).
If the seat is in front of the table, the cup still reads as "set down on the bench" behind him.
