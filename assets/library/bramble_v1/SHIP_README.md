# Bramble companion set v1 (Haex approved 2026-10-06)

Locked look: V4 at 120 px (V3A body + V3B root whips, no staff).
Wire: HOLD until Code's later PR (art-only branch).

## Contents
- `walk/<dir>/frame_0000..0007.png` — 8-frame Keeper timing (120/125/130/125 ms). South/north from ortho v3; east/west from walk_v2. Game never flips; east is pixel mirror of west.
- `idle/<dir>/bramble_idle_<dir>_0001..0012.png` — 12 × 160 ms planted breathe. South/north from ortho stills; east/west kept.
- `battle/battle_bramble_idle.png` — west-facing party battle idle, 128×128.
- `portraits/bramble_portrait.png` (52) + `bramble_portrait_sheet.png` (160) — closer v1 Elaia framing.
- `library/` — contact sheet, walk GIF, ortho stills, palette (refs only).

## Canvas
128×128, soles on row 123, hard alpha, no magenta, ≤48 colours, one shared palette.

## Suggested game paths (Code decides)
- `assets/art/bramble/anim/walk/<dir>/frame_0000.png`
- `assets/art/bramble/anim/idle/<dir>/...`
- `assets/art/bramble/battle_bramble_idle.png`
- `assets/art/bramble/bramble_portrait.png` (+ sheet)
- Keep a copy under `assets/library/bramble_v1/` for the pack + README.

Working/harvesting animations: later (full companion set).
