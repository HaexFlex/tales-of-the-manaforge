# Assets upload (Haex inbox)

**Drop new art here.** Coding ships must leave this folder **empty** (README-only) after sorting.

## Process (every ship)

1. Sort drops into permanent homes:
   - Gameplay / sliced frames → `assets/art/...`
   - Unsorted-but-kept PNG sheets → `assets/library/`
   - JPG duplicates / raw refs → `assets/library/raw_refs/`
2. Prefer PNG over JPG for anything used in-game.
3. Rebuild sliced forest/keeper frames when needed: `python3 tools/slice_haex_inbox.py` (reads `assets/library/`).
4. Before merge: confirm `Assets upload/` has **no loose art** — only this README.

See `docs/ASSETS_UPLOAD.md`.
