# Snow flake v3 — CODE_NOTES (Art Direction, 2026-10-27 Europe/Zurich)

## Verdict (why v2 fails to read on bright grass)

Primary: **size**. v2 small is 4×4 with a 2×2 white core; even with ~150 particles in view only ~25–30 read at 1× on bright grass (lum ≈ 153). Grass noise swallows the speck.

Secondary: **outline contrast**. v2 outline `#5a6e8c` (lum ≈ 108) is only ~45 value steps from grass; it melts into mid-greens. Density is **not** the problem (160 amount / ~150 in view is enough once flakes pop).

## New art paths (wire these; do not keep v2 paths)

| Role | Path | Frame | Strip |
|------|------|-------|-------|
| small / mid | `assets/art/fx/weather/snow_flake_small_strip_6x6x4.png` | **6×6** | 24×6 (4 frames h) |
| large | `assets/art/fx/weather/snow_flake_large_strip_8x8x4.png` | **8×8** | 32×8 (4 frames h) |

Legacy (replaced, do not load in game):
`assets/library/legacy/snow_v2_2026-10-27/snow_flake_small_strip_4x4x4.png`
`assets/library/legacy/snow_v2_2026-10-27/snow_flake_large_strip_6x6x4.png`

## Look

- Solid white core `#ffffff`
- 1 px cool outline `#3a4866` (harder than v2 `#5a6e8c`)
- Optional 1 px lighter halo `#6e7e9e` (still below grass luminance)
- Hard alpha only (0 or 255); nearest filter; scale_amount 1.0
- `h_frames=4`, `v_frames=1` (unchanged)

## Recommended mix

**30% 6×6 + 70% 8×8** (mostly-large).

Example amounts at total 160: small **48**, large **112**.
Mobile total 96: small **29**, large **67**.

Update `SNOW_SMALL_TEX` / `SNOW_LARGE_TEX` and the small/large amount split accordingly.

## Lower-third thinness (CODE — do not treat as art)

Observed in captures: cool-bright diff vs clear is ~99 px in y0–240, ~10 in y240–480, ~2 in y480–720.

Current (`scripts/hub/glade_weather_fx.gd` at 29562ba):

| Const | Value |
|-------|------:|
| `SNOW_VIEW_BOX_WIDTH_PX` | 1408 |
| `SNOW_VIEW_BOX_HEIGHT_PX` | 16 |
| `SNOW_VIEW_BOX_ABOVE_VIEW_PX` | 48 |
| `SNOW_LIFETIME_SEC` | 9.0 |
| `SNOW_LIFETIME_RANDOMNESS` | 0.2 |
| `SNOW_FALL_SPEED_MIN_PX_S` | 70 |
| `SNOW_FALL_SPEED_MAX_PX_S` | 100 |
| `SNOW_FADE_OUT_LIFE_FRAC` | 0.15 |
| `SNOW_PREPROCESS_SEC` | 9.0 |

Spawn center sits **40 px above the view top** (ABOVE 48 − half box 8). Travel to clear the bottom edge ≈ **48 + 720 = 768 px** from box top (or ~760 from emitter center + half box).

Math:

- min fall × life = 70 × 9 = **630 px** < 768 → slow flakes die before the bottom
- with randomness 0.2, short lives ≈ 7.2 s → 70 × 7.2 = **504 px**
- fade-out starts at life frac 0.85 → even a full-life slow flake is already fading by ~535 px of fall (~screen y 487), so the **lower third is emptied by lifetime + fade**, not by missing sprites

### Exact numbers for Code

**Option A (preferred — keep top strip emitter):**

- `SNOW_LIFETIME_SEC = 12.5` (covers 768 / 70 ≈ 11.0, plus margin so fade-out completes past y=720)
- keep `SNOW_FALL_SPEED_MIN_PX_S = 70`, max 100
- `SNOW_PREPROCESS_SEC = 12.5` (match lifetime so the fill is steady)
- optionally `SNOW_FADE_OUT_LIFE_FRAC = 0.08` so full alpha holds through most of the lower third
- check: 70 × 12.5 = 875 px > 768; at 0.92 life still ≥ 768 if fade shortened

**Option B (taller spawn — fill depth without only relying on long life):**

- Keep lifetime ≥ **11.0** s at vmin 70
- Expand emission to cover view depth, e.g. rect from screen **y = -40** through **y = 720** (world box height ≈ 760, extents.y ≈ 380), width still ~1408
- If using a tall box, cut amount or accept denser mid-screen; top-only strip + Option A is cleaner for “falling into view”

**Do not** raise amount further to fix the thin bottom — that stacks unread flakes up top.

## Contact sheets

- `assets/library/snow_flake_v3_2026-10-27/snow_flake_v3_contact_1x.png`
- `assets/library/snow_flake_v3_2026-10-27/snow_flake_v3_contact_2x.png`
