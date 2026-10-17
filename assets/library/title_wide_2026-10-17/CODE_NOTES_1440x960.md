# Taller title master: assets_extra/title/title_bg_wide_1440x960.png (1440x960, RGB, no .import)
- Fixes the 30 px gray strips top/bottom at 1280x960 (viewport 1280x960 x1). Covers every expanded viewport at 1:1 centred: 1400x876, 1280x960, 1280x800, 1200x540, 960x720, 960x600, 960x540.
- 1200x540 painting at (120,210); 960x540 centre at (240,210): both asserted byte-identical to the legacy plates. Same procedural style as 1440x900 (sky/canopy top 210 px, forest floor bottom 210 px, forest sides 120 px, dithered vignette, hard pixels, no logo).
- Code: draw at `((vw-1440)/2, (vh-960)/2)`; logo/menu offset `((vw-960)/2, (vh-540)/2)` unchanged.

## Code must switch the reference (NOT done here)
- `scenes/title_screen.tscn:4`: `res://assets_extra/title/title_bg_wide_1440x900.png` -> `res://assets_extra/title/title_bg_wide_1440x960.png` (+ the size/position constants that assume 1440x900 in `scripts/title_screen.gd`, if any).
- `scripts/verify_headless.gd:22084` and `:22088` also name the 1440x900 file.
- Godot will create the new .import on first import.

## Legacy: PENDING until Code switches
`assets_extra/title/title_bg_wide_1440x900.png` (+ .import) stays in place because it is still referenced. After the switch: `git mv` both to `assets/library/legacy/title_wide_1440x900_2026-10-17/` with a REPLACED.md.
Preview: `title_wide960_preview_1280x960_x1.png` (no gray strip), `title_wide960_centre_check.png`.
