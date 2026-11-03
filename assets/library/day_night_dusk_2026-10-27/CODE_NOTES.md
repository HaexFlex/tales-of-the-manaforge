# Dusk ground variant (2026-10-27)
Every live hub ground texture has a `_dusk` twin next to it: same size, same layout, same atlas cells.
- assets/art/tiles/tileset_grass_64_dusk.png (256x128, 4x2 cells of 64) + grass_00..03/path_*_dusk.png
- assets/art/hub/ground/grass_tuft_01..09_dusk.png (64x48), fern_01..06_dusk.png (64x64)
Grade: moss darker + slightly bluer, bark/path warmer and more saturated, darks pulled toward cool blue,
the flower highlight and a sparse grid of top-light blades turned mana cyan (#3de7ca/#16caa4, sampled from fx_vein_mote).
Code: swap the path (or crossfade a second TileMap layer) when hub_day_night_cycle reaches dusk; the modulate tint can then be lighter.
