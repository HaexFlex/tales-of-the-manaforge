# Taller title master: assets_extra/title/title_bg_wide_1440x960.png (1440x960, RGB, no .import)
- Fixes the 30 px gray strips top/bottom at 1280x960 (viewport 1280x960 x1). Covers every expanded viewport at 1:1 centred: 1400x876, 1280x960, 1280x800, 1200x540, 960x720, 960x600, 960x540.
- 1200x540 painting at (120,210); 960x540 centre at (240,210): both asserted byte-identical to the legacy plates. Same procedural style as 1440x900 (sky/canopy top 210 px, forest floor bottom 210 px, forest sides 120 px, dithered vignette, hard pixels, no logo).
- Code: draw at `((vw-1440)/2, (vh-960)/2)`; logo/menu offset `((vw-960)/2, (vh-540)/2)` unchanged.

## Code
`scenes/title_screen.tscn` Background loads `res://assets_extra/title/title_bg_wide_1440x960.png`. It is drawn 1:1 (`STRETCH_KEEP`) at `((vw-1440)/2, (vh-960)/2)`. Logo (52, 24), menu (136, 146) and version (904, 503) still add `((vw-960)/2, (vh-540)/2)`. Godot generated `title_bg_wide_1440x960.png.import` on first import.

## Legacy
`title_bg_wide_1440x900.png` and its `.import` live in `assets/library/legacy/title_wide_1440x900_2026-10-17/`. See `REPLACED.md` there. Nothing in the game loads that plate.
Preview: `title_wide960_preview_1280x960_x1.png` (no gray strip), `title_wide960_centre_check.png`.
