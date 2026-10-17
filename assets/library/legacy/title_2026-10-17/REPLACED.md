# Replaced 2026-10-17: title plates (1200x540 and 960x540)

The title screen now draws `assets_extra/title/title_bg_wide_1440x900.png` 1:1, centred. The 960x540 centre of that painting (crop at (240, 180)) is byte-identical to `title_bg_960x540.png`.

- **Moved here (byte-identical, with `.import`):** `title_bg_1200x540.png`, `title_bg_960x540.png`.
- **From:** `assets_extra/title/`.
- **Why:** nothing in the game still loads those plates. The wide painting covers them.
- **Swap back:** `git mv` each file (and its `.import`) back to `assets_extra/title/`.
