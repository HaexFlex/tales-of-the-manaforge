# Legacy move: library tidy (2026-10-02, fix pass)

Loose sheets and old inbox folders from the `assets/library/` root, moved with `git mv` (history kept). Nothing in the
game loads them. `.import` files are git-ignored in this repo (`.gitignore: *.import`), so there were no tracked
`.import` files to move; Godot regenerates them at the new path.

## Moved

| old path | new path | reason |
|---|---|---|
| `assets/library/Big Bushes.png` | `assets/library/legacy/library_tidy_2026-10-02/Big Bushes.png` | v0.1.13 assets-upload source sheet; its slices were replaced by hub v3 `assets/art/hub/bushes/`. Only `tools/slice_haex_inbox.py` (one-shot tool) names it. |
| `assets/library/Small Trees.png` | `assets/library/legacy/library_tidy_2026-10-02/Small Trees.png` | Same, slices replaced by hub v3 `assets/art/hub/trees/`. Only `tools/slice_haex_inbox.py`. |
| `assets/library/small bushes.png` | `assets/library/legacy/library_tidy_2026-10-02/small bushes.png` | Same, older 1168x784 small-bush sheet. Only `tools/slice_haex_inbox.py`. |
| `assets/library/art_drop_c9fda76/` (23 files incl. README.md) | `assets/library/legacy/library_tidy_2026-10-02/art_drop_c9fda76/` | Untouched originals of the c9fda76 art drop; every in-game use was re-imagined since (art refresh 09-29, hub v3 09-30). Named only as provenance strings in `assets/art/MANIFEST.json` (not read by game code). |

## Moved later (second batch, 2026-10-02, fix/waypoint-pass)

Both moved with `git mv`, after `rg` confirmed no live reference outside legacy/docs.

| old path | new path | reason |
|---|---|---|
| `assets/library/Big Trees.png` | `assets/library/legacy/library_tidy_2026-10-02/Big Trees.png` | Last loose assets-upload sheet (slices replaced by hub v3 `assets/art/hub/trees/`). Moved 2026-10-02 on fix/waypoint-pass after Code dropped the VERIFY assert (`verify_headless.gd:192-193` now only asserts `raw_refs/Big Trees.jpg`). `tools/slice_haex_inbox.py:155,167` already reads it from here. |
| `assets/library/keeper_inbox/` (10 PNGs: `idle_south.png`, `walk_south_01..09.png`) | `assets/library/legacy/library_tidy_2026-10-02/keeper_inbox/` | Original Keeper frame drops. Moved on fix/waypoint-pass. `tools/slice_haex_inbox.py:22` (`KEEPER_INBOX = LEGACY_TIDY / "keeper_inbox"`) and `:336,:350` already expect it here. |

Strings that still name the old `assets/library/keeper_inbox/` path:
- `assets/art/keeper/keeper_meta.json:76` and `assets/art/MANIFEST.json:13` (`"inbox"` provenance). Not loaded as paths. `verify_headless.gd:279` reads keeper_meta.json but not `inbox`. `slice_haex_inbox.py` rewrites both to the new path when it runs.
- `docs/ASSETS_UPLOAD.md:13` and `assets/art/ASSETS_UPLOAD_HANDOFF.md` (historical docs).

`assets/library/_art_refresh/` does not exist on main (the 09-29 refresh material already lives in `legacy/_art_refresh_2026-09-29/`).

## References Code / docs need to update

* `tools/slice_haex_inbox.py:154-216` reads `LIBRARY / "Big Trees.png" | "Small Trees.png" | "Big Bushes.png" | "small bushes.png"` and writes `"source": "assets/library/..."`; `:21` `KEEPER_INBOX`, `:335,:349` `"inbox"`. Point `LIBRARY` sheet paths at `assets/library/legacy/library_tidy_2026-10-02/` (or retire the tool; its outputs are superseded by hub v3).
* `docs/ASSETS_UPLOAD.md:13` lists `assets/library/keeper_inbox/` (fine until keeper_inbox moves).
* `assets/art/ASSETS_UPLOAD_HANDOFF.md:18-41` describes the four sheets (historical doc; path is now this folder).
* `assets/art/MANIFEST.json:24,87` provenance `art_drop_c9fda76` / `assets/library/art_drop_c9fda76/Elaia front.png` (string only).
* `assets/library/README.md` updated in this commit and again in the second batch.

## Swap back

`git mv "assets/library/legacy/library_tidy_2026-10-02/<name>" "assets/library/<name>"` for each row above.
