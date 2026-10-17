# Replaced 2026-10-17: title_bg_wide_1440x900.png

The title screen now draws `assets_extra/title/title_bg_wide_1440x960.png` 1:1, centred. The 960x540 centre of that painting (crop at (240, 210)) is byte-identical to `title_bg_960x540.png`.

- **Moved here (byte-identical, with `.import`):** `title_bg_wide_1440x900.png`.
- **From:** `assets_extra/title/`.
- **Why:** a 1280x960 view is taller than 900, so the 900 plate left a clear strip. The 960-tall plate covers it. Nothing in the game still loads the 900 file.
- **Swap back:** `git mv` the png and its `.import` back to `assets_extra/title/`.
