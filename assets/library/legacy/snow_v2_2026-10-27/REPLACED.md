# Replaced: snow flake v2 (2026-10-27)

Moved out of `assets/art/fx/weather/` by Art Direction.

| Legacy file | Was | Replaced by |
|-------------|-----|-------------|
| `snow_flake_small_strip_4x4x4.png` | 4×4×4 strip (16×4), white + `#5a6e8c` | `assets/art/fx/weather/snow_flake_small_strip_6x6x4.png` |
| `snow_flake_large_strip_6x6x4.png` | 6×6×4 strip (24×6), white + `#5a6e8c` | `assets/art/fx/weather/snow_flake_large_strip_8x8x4.png` |

Reason: at 1× on bright grass only ~25–30 of ~150 in-view flakes read. Size was primary; outline too light. See `assets/library/snow_flake_v3_2026-10-27/CODE_NOTES.md`.

Do not delete. Code must point at the v3 paths before playable snow works again.
