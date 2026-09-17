# Assets Upload Handoff — v0.1.13-assets-upload

Processed from `/workspace/uploads/assets_upload_inbox/` (PNG sheets preferred; JPG duplicates left unused). Originals remain in inbox. Cleaned frames written to **both**:

| Mirror | Path |
|--------|------|
| Art Direction | `/home/box/manaforge/art_restart/{trees,bushes,keeper}/` |
| Code staging | `/home/box/manaforge/assets_art_staging/{trees,bushes,keeper}/` → copy into repo `assets/art/` |

Filter: **nearest**. Background key: RGB all channels `< 18` → alpha 0. Crop to opaque bbox + 2px pad (trees/bushes). No forced 64px downscale; NN downscale only if side > 512 (none needed).

---

## Trees (`assets/art/trees/`)

| Sheet | Grid | Frames | Naming |
|-------|------|--------|--------|
| `Big Trees.png` (1168×784) | **2×2** | 4 | `tree_big_01.png` … `tree_big_04.png` |
| `Small Trees.png` (1168×784) | **2×2** | 4 | `tree_small_01.png` … `tree_small_04.png` |

**Example sizes (post crop):**
- big: ~398–432 × 355–366 (e.g. `tree_big_01` = 432×364)
- small: ~166–451 × 356–373 (e.g. `tree_small_03` = 166×359 thin variant)

Meta: `trees/trees_meta.json` (merged; version `v0.1.13-assets-upload`). Anchor: `base_center`.

---

## Bushes (`assets/art/bushes/`) — **new dir**

### Big Bushes — grid decision
`Big Bushes.png` (1168×784): description conflict (2×2 vs 3×4).

**Chose 3×4 (12 frames)** — empty gutters at rows ~261/498 and cols ~294/579/868 cleanly separate sprites. A 2×2 grid would merge three bushes per cell.

| Naming | Count | Typical size |
|--------|-------|--------------|
| `bush_big_01.png` … `bush_big_12.png` | 12 | ~224×195 |

### Small bushes — connected components
`small bushes.png` (1168×784): irregular ~7×8 layout.

- Method: key → 4-connected components, min area 80px
- Sort: top→bottom, left→right (row-banded)
- Cap 64; exported **57** (row groups 8+8+8+8+8+8+9 — last row has one extra split fragment kept as its own frame)
- Naming: `bush_small_01.png` … `bush_small_57.png`
- Typical size: ~93×79

Meta: `bushes/bushes_meta.json` (new). Includes `grid_decisions` and per-item sizes.

---

## Keeper (`assets/art/keeper/`)

Source: `keeper/idle_south.png` + `walk_south_01`…`09` each **170×256** RGBA.

| Output | Size | Notes |
|--------|------|-------|
| `keeper_idle_south.png` + `_0000` | **128×128** | Primary for Code (bible lock) |
| `keeper_walk_south_0001`…`0009` | **128×128** | Individual frames |
| `keeper_walk_south.png` | **1152×128** | Horizontal strip of 9 |
| `keeper/native/*_256.png` (+ strip) | **170×256** | Native canvas retained |

Fit: uniform NN scale to fit 128², **bottom-center feet anchor** (character sits on bottom of canvas).

Meta: `keeper/keeper_meta.json` (merged):
- clips `idle_south` (1 frame, hold_ms 140)
- clips `walk_south` (9 frames, hold_ms **100**, strip + files, filter nearest)
- canvas `[128, 128]`, anchor `feet_center`

---

## Manifest

`/home/box/manaforge/art_restart/MANIFEST.json` → **`v0.1.13-assets-upload`**
- lists `trees/`, **`bushes/`** (new), `keeper/`
- notes staging mirror path

---

## File counts (this upload)

| Location | New PNGs (approx) |
|----------|-------------------|
| trees | 8 (`tree_big_*` + `tree_small_*`) |
| bushes | 69 (12 big + 57 small) |
| keeper primary | 12 (idle×2 names + walk×9 + strip) |
| keeper native | 11 (idle + walk×9 + strip) |
| **staging total** | ~100 files + metas |

Inbox originals **not deleted**.

---

## Notes for Code

1. Copy from staging into repo:
   - `assets_art_staging/trees/` → `assets/art/trees/`
   - `assets_art_staging/bushes/` → `assets/art/bushes/` (create)
   - `assets_art_staging/keeper/` → `assets/art/keeper/` (merge; keep existing front/back clips)
2. Prefer **128²** keeper frames; use `native/` only if you need source-res.
3. Trees/bushes are **variable size** (bbox-cropped) — y-sort on base_center; do not assume square atlases.
4. Walk south: 9 frames @ ~100ms; use strip or numbered frames.
