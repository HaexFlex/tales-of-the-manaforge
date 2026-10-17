# Replaced 2026-10-17: echo_chamber_bg_inkwater_1280x720.png

The Echo chamber now draws `assets/ui/echo/echo_chamber_bg_inkwater_1440x960.png` 1:1, centred. This 1280×720 plate sits byte-identical at (+80, +120) inside that master.

- **Moved here (byte-identical, with `.import`):** `echo_chamber_bg_inkwater_1280x720.png`.
- **From:** `assets/ui/echo/`.
- **Why:** the chamber no longer crops and stretches this plate. Nothing in code, scenes, or tests loads it.
- **Swap back:** `git mv` the png and its `.import` back to `assets/ui/echo/`.
