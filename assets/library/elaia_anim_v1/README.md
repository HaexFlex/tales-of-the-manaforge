# Elaia anim v1 — notes

Runtime frames live under `assets/art/elaia/anim/` (exported). These notes are the Art Direction handoff copied from `experiments/keeper-idle-4dir` (`d23aff5` stills, `b53d94c` walk, `4beb66f` harvest + station). The experiment branch is not merged.

| clip | canvas | code offset | art feet | sole row |
|---|---|---|---|---|
| idle / walk | 128×128 | (-64, -128) | x 64, sole row 123 | 123 |
| axe / pickaxe / berries | 192×136 | (-96, -136) | (96, 132) | 131 |
| water | 208×136 | (-104, -136) | (104, 132) | 131 |
| station north | 128×128 | (-64, -128) | (64, 124) | 123 |

The offsets are the ones Art Direction specified (same numbers as the Keeper). Soles sit a few pixels above the node origin because the sole row is above the canvas bottom. That gap is listed, not corrected.

No run cycle. No golden key in any frame.

Measured contact (right edge of the impact / pour pixels, minus the feet x):

- Axe impact frame 3: 41 px
- Pickaxe impact frame 7: 41 px
- Berries pluck frame 4: 43 px
- Water held pour frames 5–6: 82 px (stream end, 5 px above the feet)
- Station: no impact frame; hands stay hidden. She uses the Keeper station stand.

Keeper water held pour frames 4–6: stream end is 102 px ahead of the feet and 5 px above them. Manatree `side_px` / `contact_px` match that reach (Keeper 102, Elaia 82). `y_px` 35 drops the end 30 px south of the door sill, on the soil in front of the trunk. One stand for every growth stage.
