# cleanup_r1 — Puff harvest berries (step 3)

Date: 2026-11-03 (Europe/Zurich). Shipped as step 3 (`art(cleanup-r1): Puff harvest_berries east/west 8f`).

## Deliverables

`assets/art/companions/puff/harvest_berries_{east,west}/frame_0000..0007.png`

- Canvas 128×128, sole y=123, height 77 (= walk/idle_e/w)
- Timing BERRY_MS = [160, 90, 90, 100, 160, 100, 90, 110] (matches Keeper/Elaia)
- Hard alpha, 22-colour walk palette per facing, holes=0, single component (no floating specks)

## Source picks (1-based ffmpeg frames from berry_{east,west}.mp4 @ 24fps)

| out | ms | role | east src | west src |
|---|---|---|---|---|
| 0 | 160 | rest hold | 76 | 76 |
| 1 | 90 | reach start | 79 | 85 |
| 2 | 90 | mid reach | 82 | 92 |
| 3 | 100 | near peak | 84 | 97 |
| 4 | 160 | reach-peak hold | 85 | 100 |
| 5 | 100 | retract | 87 | 104 |
| 6 | 90 | drop to basket | 90 | 108 |
| 7 | 110 | settle → loop | 93 | 112 |

East cycle mid-clip (rest→peak→rest around f76–93). West around the clear left-reach peak at f100 (f76–112).

## Pipeline

1. Corner magenta key + keep **largest CC only** (drop disconnected berries/specks).
2. ONE scale per clip: target_h 77 / median source height; BOX stepwise + NEAREST.
3. Place sole=123, feet_cx locked (span ≤0.5 px across frames; Δ≤1).
4. Lab snap to that facing’s walk 22-colour palette → despeck → fill all interior holes → kill magenta.

## Gates

East clip_pass=True sole_span=0 feet_span=0.5
West clip_pass=True sole_span=0 feet_span=0.5

All 16 frames: semi=0, magenta=0, holes=0, colours=22, sole=123, h=77, comps=1.

Keeper/Elaia berry clips are 192×136 sole 131 (hero canvas). Puff uses companion 128×128 sole 123 like walk/idle.

## Contacts / GIFs

`puff_harvest_berries_contact_{1x,4x}_{midgreen,uibrown}.png` — idle + 8 frames + Keeper berry clip.
`puff_harvest_berries_{east,west}_{1x,4x}.gif` — real BERRY_MS.
