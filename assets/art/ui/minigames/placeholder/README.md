# Minigame placeholders (NOT APPROVED, look-and-feel only)

Feel-test placeholders for the "Lend a hand" minigames (branch `feat/minigames-feel-test`, debug only, no payout).

- `kit/`: frame 720×448 (rim 20), title plate 312×46 (288×40 plank + sprigs), Stop button 104×28 (normal/hover/pressed/disabled), Esc keycap, pips 12×12 (empty/good/perfect/miss), pace track 136×18. Rendered with Art's procedural placeholder kit (`/workspace/minigames_art/tools/kit.py`, Oct 11).
- `play/<game>_play_ref.png`: 640×320 crop of the play area from Art's `<game>_scaffold_clean.png`. The game elements are baked in; use it as a dimmed backdrop only.
- `overlay_geometry.json`: Art's screen rects (1280×720, 1 art px = 1 screen px). Same numbers as `data/minigames.json` `frame`.
- `palette.json`: Art's reserved colours (gold = active/perfect/target band, leaf green = good, warm grey-brown = miss, no red fail).
- The full 1280×720 scaffolds are in `assets/refs/minigames_scaffolds/` (Godot-ignored).

Replace with Art's approved sprites when they land. Titles are drawn with the font, never baked.
