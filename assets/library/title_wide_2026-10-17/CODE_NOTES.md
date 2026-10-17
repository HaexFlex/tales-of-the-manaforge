# Wide title painting master (assets only)

`assets_extra/title/title_bg_wide_1440x900.png` — **1440x900**, RGB, hard pixels, no blur.
- The live 1200x540 painting sits **unchanged at (120,180)**; the 960x540 centre at (240,180) is byte-identical to `title_bg_960x540.png` (asserted).
- Extended 120 px left/right and 180 px top/bottom with mirrored sky/canopy/forest/forest-floor, then an ordered-dither (Bayer) vignette towards the edges (palette-style darkening, no gradients/blur). Procedural, not repainted: mirror motifs are faintly visible in the darkest outer strips.
- Logo and menu are NOT baked in (logo stays `logo_cyan_jersey10.png`).
- No `.import` shipped with the painting: Godot generated `title_bg_wide_1440x900.png.import` on first import.

## Code must (not done here, assets only)
1. Point `scenes/title_screen.tscn` Background at `res://assets_extra/title/title_bg_wide_1440x900.png`.
2. Draw it **1:1 centred** on the logical viewport (no KEEP_ASPECT_COVERED, no non-integer scale): `position = ((vw-1440)/2, (vh-900)/2)`; viewport max 1440x900 (covers 1400x876, 1280x800, 1200x540, 960x540, 960x720 at integer x2 / x1).
3. Offset logo and menu by `((vw-960)/2, (vh-540)/2)` so they stay on the painted tree/path (see previews: logo (52,24), menu (136,146), version (904,503) in 960x540 coordinates).

Previews (x2): `title_wide_preview_1400x876_x2.png` (2800x1752), `..._1280x800_x2.png` (2560x1600), `..._1200x540_x2.png`; `title_wide_centre_check.png` (960 centre outlined magenta, viewport crops yellow).
Rebuild: `build_title_wide.py`, `build_previews.py` (paths inside point at the build box).

## Legacy
`title_bg_1200x540.png` and `title_bg_960x540.png` (with their `.import`) now live in `assets/library/legacy/title_2026-10-17/`. See `REPLACED.md` there. The title scene loads the wide painting only.
