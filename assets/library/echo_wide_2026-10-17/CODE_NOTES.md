# Echo wide plate: assets/ui/echo/echo_chamber_bg_inkwater_1440x960.png (1440x960, RGB, no .import)
- The live `echo_chamber_bg_inkwater_1280x720.png` sits **byte-identical at (+80,+120)** inside it (asserted in `build_echo_wide.py` and again for the previews).
- Extension (80 px left/right, 120 px top/bottom): reflect of plain edge bands only (top: first 60 rows of roots, bottom: last 60 rows of floor, sides: 80 columns of rock/fern; ping-pong, no portal/stones/figures), highlights clamped (no mirrored glows, runes or fireflies), then hard ordered-dither darkening towards the edge to the plate's own darkest colour. No blur, no new hues, native scale. Procedural, so the outer ring is just dark chamber texture.

## Code
`EchoTheme.PLATE` is the 1440×960 master. `ChamberArt` is `STRETCH_KEEP`, size 1440×960, at `((vw-1440)/2, (vh-960)/2)`. `DesignFrame` is the one offset: it sits at `center_shift`, and the plate is `DesignFrame.position - (240, 210)`. That (240, 210) is the old plate at +80,+120 plus the 960×540 crop at +160,+90. Overlays stay on the 960×540 design layout plus `center_shift`, so the locked positions are unchanged. The design area is (240..1200, 210..750) on the plate.

## Legacy
`echo_chamber_bg_inkwater_1280x720.png` and its `.import` live in `assets/library/legacy/echo_plate_1280x720_2026-10-17/`. See `REPLACED.md` there. Nothing in code, scenes, or tests loads it.

Previews (1:1, viewport crop of the master centred, magenta frame = unchanged plate): `echo_wide_preview_{1280x960,1280x800,1200x540,1400x876,960x600,960x540}.png`; `echo_wide_centre_check.png`.
