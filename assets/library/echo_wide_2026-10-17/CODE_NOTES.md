# Echo wide plate: assets/ui/echo/echo_chamber_bg_inkwater_1440x960.png (1440x960, RGB, no .import)
- The live `echo_chamber_bg_inkwater_1280x720.png` sits **byte-identical at (+80,+120)** inside it (asserted in `build_echo_wide.py` and again for the previews).
- Extension (80 px left/right, 120 px top/bottom): reflect of plain edge bands only (top: first 60 rows of roots, bottom: last 60 rows of floor, sides: 80 columns of rock/fern; ping-pong, no portal/stones/figures), highlights clamped (no mirrored glows, runes or fireflies), then hard ordered-dither darkening towards the edge to the plate's own darkest colour. No blur, no new hues, native scale. Procedural, so the outer ring is just dark chamber texture.

## Code must (not done here)
1. Draw it **1:1 centred**: position `((vw-1440)/2, (vh-960)/2)`, size 1440x960, nearest. Replace the cropped-atlas stretch at `scripts/echo_battle_view.gd:904-923` (CROP_16/CROP_20 in `scripts/ui/echo_theme.gd:55-56`, `EchoTheme.PLATE` at `echo_theme.gd:9`) and `stretch_mode = 0`/`expand_mode = 1` on ChamberArt in `scenes/echo_battle.tscn` (no scaling; use a fixed-size TextureRect with `stretch_mode = KEEP`, not FULL_RECT stretch).
2. The plate's content is at **+80,+120** in the master; the 1280x720 plate's own coordinates need that offset. The UI stays on the 960x540 design layout plus `Ui540.center_shift`: the 960x540 design area is the master region (240..1200, 210..750).
3. Viewport coverage at 1:1 (all inside 1440x960): 1280x960, 1280x800, 1400x876, 1200x540, 960x600, 960x540.
4. Old `assets/ui/echo/echo_chamber_bg_inkwater_1280x720.png` (+ .import) stays in place. **PENDING:** once Code stops referencing it, `git mv` both to `assets/library/legacy/echo_plate_1280x720_2026-10-17/` with a REPLACED.md.

Previews (1:1, viewport crop of the master centred, magenta frame = unchanged plate): `echo_wide_preview_{1280x960,1280x800,1200x540,1400x876,960x600,960x540}.png`; `echo_wide_centre_check.png`.
