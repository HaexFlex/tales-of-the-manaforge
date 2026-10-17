# Replaced art: Android launcher icons (shipped android_pkg_clean -> android_pkg_v2)

- **Replaced (10 files, byte-identical originals moved here, same names):** `ic_launcher_{48,72,96,144,192}.png`, `ic_launcher_store_512.png`, `ic_launcher_round_192.png` (from `assets/ui/android/legacy/`) and `ic_launcher_{background,foreground,monochrome}_432.png` (from `assets/ui/android/adaptive/`).
- **By:** `android_pkg_v2` at the same paths and names (the `.import` files stayed where they were, so uids and the export preset keys are unchanged; Godot re-imports the pixels). The splash is untouched.
- **Why (PR #40 capture review, `ART_REVIEW.md`):** the 72 icon had a smaller Keeper (64% vs 94% of the height) and dark vignette corners; the adaptive foreground's coat corners were clipped by the circle mask (2366 px outside r 144); the monochrome layer was dithered with 201 art px of holes.
- **Swap back:** `git mv -f assets/library/legacy/android_icons_2026-10-17/<file> <old path>` (old paths above).
- **Date:** 2026-10-17. Contact sheet old vs new: `assets/library/android_icons_v2_2026-10-17/contact_shipped_vs_v2.png`.

Originals in this folder stay out of the export (`assets/library/*`).
