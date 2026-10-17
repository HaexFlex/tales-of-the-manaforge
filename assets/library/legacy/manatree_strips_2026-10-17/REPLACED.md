# Replaced art: wide Manatree strips

- **Replaced:** the live 8192-wide elder and ancient strips, and the 5888-wide mature strips (plain and glow).
- **By:** frame-aligned tiles under `assets/art/manatree/native/anim/tiles/` and `assets/art/manatree/native/anim/glow/tiles/`. Elder and ancient are four 2048×1024 tiles (2 frames each). Mature is four 1472×736 tiles (2 frames each). Nearest filtering and 1 art px = 1 screen px are unchanged. `manatree_meta.json` still says 8 frames at the original frame size.
- **Why:** Android playtest pass 1. A single strip wider than 4096 is not a safe mobile texture. Tiles stay at or under 2048 px wide.
- **Date:** 2026-10-17

Originals in this folder are the sources the tiles were cropped from. They are out of the export (`assets/library/*`). Young strips (2304×288) stayed live because they are already under 4096.
