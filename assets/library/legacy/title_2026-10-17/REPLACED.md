# Replaced 2026-10-17: title plates (1200x540 and 960x540)

These two plates left the live title folder when the screen moved to `title_bg_wide_1440x900.png`. That 1440x900 file has since moved to `assets/library/legacy/title_wide_1440x900_2026-10-17/`. The live painting is `assets_extra/title/title_bg_wide_1440x960.png`. The 960x540 centre of this archived 960 file is byte-identical to the centre of the live painting (crop at (240, 210)).

- **Moved here (byte-identical, with `.import`):** `title_bg_1200x540.png`, `title_bg_960x540.png`.
- **From:** `assets_extra/title/`.
- **Why:** nothing in the game still loads those plates. The wide painting covers them.
- **Swap back:** `git mv` each file (and its `.import`) back to `assets_extra/title/`.
