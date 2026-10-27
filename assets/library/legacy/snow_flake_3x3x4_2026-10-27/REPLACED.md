# Replaced 2026-10-27: snow_flake_strip_3x3x4

Old 3×3×4 flake was pure white / light gray — invisible at 1× on bright glade grass and canopy
(`snow_debug.txt`: bright_px≈4, flake washed out).

Replaced by two new strips (near-white + soft cool-blue outline / darker core, hard alpha):
- `assets/art/fx/weather/snow_flake_small_strip_3x3x4.png` — 12×3 (4× 3×3), cozy twinkle
- `assets/art/fx/weather/snow_flake_large_strip_5x5x4.png` — 20×5 (4× 5×5), soft diamond + rotate

Code should point Snow particles at the new paths (mix small/large). Do **not** change Design amount/spread.
