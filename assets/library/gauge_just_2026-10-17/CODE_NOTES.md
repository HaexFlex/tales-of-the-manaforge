# Pressure label fix (folder name kept from the request: gauge_just)
**Correction:** the baked "Pressure" label is NOT in `gauge_just.png` (62x240 bark tube, Just Enough; untouched, no text). It is in `assets/ui/minigames/press_dial.png` (Steady Press, `steady_press.gd:75`), so that file was redone.
- Same path, same canvas **124x150** (no size change; nothing for Code to change: sprite is centred at DIAL_TL+(62,75), dial art unchanged pixel-for-pixel above y=124).
- Label: Silver.ttf size 19, hard (no AA), glyph 47x9 px (cap 9, was 8 rows), cream (250,238,204) with 1 px dark outline (26,15,8), centred at x=38..84, y=130..138 (outline 129..139). Hard alpha, native scale 1.
- The extra 10 px of room was not needed: the word is 47 px wide in a 124 px sprite and the dial leaves rows 119-127 empty.
- No .import change. Original in `assets/library/legacy/gauge_just_2026-10-17/press_dial.png`.
- Previews: `press_dial_before_after_x1.png`, `_x2.png` (before left, after right, on a flat plate colour; not the full window).
