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

## Not moved yet: "move after swap"

| path | why it stays | Code's change, then move to |
|---|---|---|
| `assets/library/Big Trees.png` | `scripts/verify_headless.gd:192` asserts it exists; `tools/slice_haex_inbox.py:154,166` | drop/repoint the VERIFY assert, then `git mv` to `assets/library/legacy/library_tidy_2026-10-02/Big Trees.png` |
| `assets/library/keeper_inbox/` | `scripts/verify_headless.gd:193` asserts `keeper_inbox/walk_south_09.png`; `tools/slice_haex_inbox.py:21,335,349`; `assets/art/keeper/keeper_meta.json:76` and `assets/art/MANIFEST.json:13` (`"inbox"` provenance) | drop/repoint the VERIFY assert, then `git mv` to `assets/library/legacy/library_tidy_2026-10-02/keeper_inbox/` |

`assets/library/_art_refresh/` does not exist on main (the 09-29 refresh material already lives in `legacy/_art_refresh_2026-09-29/`).

## References Code / docs need to update

* `tools/slice_haex_inbox.py:154-216` reads `LIBRARY / "Big Trees.png" | "Small Trees.png" | "Big Bushes.png" | "small bushes.png"` and writes `"source": "assets/library/..."`; `:21` `KEEPER_INBOX`, `:335,:349` `"inbox"`. Point `LIBRARY` sheet paths at `assets/library/legacy/library_tidy_2026-10-02/` (or retire the tool; its outputs are superseded by hub v3).
* `docs/ASSETS_UPLOAD.md:13` lists `assets/library/keeper_inbox/` (fine until keeper_inbox moves).
* `assets/art/ASSETS_UPLOAD_HANDOFF.md:18-41` describes the four sheets (historical doc; path is now this folder).
* `assets/art/MANIFEST.json:24,87` provenance `art_drop_c9fda76` / `assets/library/art_drop_c9fda76/Elaia front.png` (string only).
* `assets/library/README.md` updated in this commit.

## Swap back

`git mv "assets/library/legacy/library_tidy_2026-10-02/<name>" "assets/library/<name>"` for each row above.
