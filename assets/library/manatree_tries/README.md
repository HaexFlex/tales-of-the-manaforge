# Manatree progression tries A / B / C / A2

Alternative Manatree art sets. A, B and C are proposals and are not used by the game.
**A2 (Haex's pick) is wired live** in `assets/art/manatree/` (see below). The previous live files are in
`assets/library/legacy/manatree_refresh_2026-09-29/`.

| set | design |
|---|---|
| **A** | Evolved current design: teal-veined oak with the mana gem, orange leaves at Ancient |
| **B** | Broad oak: clumped teal-veined canopy, buttress roots, hanging vines with drops, crystals at Ancient |
| **C** | Spiral willow: double-helix trunk under a weeping willow canopy |
| **A2** | Set A with changes (**live**): see the A2 section |

Sheets: `contact_ABC.png` (all three), `<S>/contact_<S>.png` (per set: frame 0 at in-game display
size standing on the door_floor ground line, the stills, and 1:1 in-game close-ups of the doors).

## A2 (Haex's pick, wired live, `v0.1.8-A2`)
Set A with changes. Files: `A2/` (stills, `anim/`, `contact_A2.png`, `manatree_meta.proposed.json`
with `haex_approved: true`). The same files are live in `assets/art/manatree/` under the live names.

| stage | art | placement (raw base row on the kept `door_floor`) |
|---|---|---|
| sapling | same as A | anchor, base row 1180 (as A) |
| young | same as A | old bbox (as A) |
| mature | A's Elder art with the door replaced by a thick teal arch **outline** (bark inside). Leftover strokes from an erased old arc above the arch are painted over with nearby bark | anchor, base row 1317 = bottom of the outline. Scaled down into the unchanged 184 px mature frame |
| elder | A's Ancient art without the orange blossoms: green canopy, real door | anchor, base row 1390 = bottom of the door sill |
| ancient | Withered version of the new Elder: same silhouette and door, grey bark, dry sparse leaves, bright teal veins | anchor, base row 1392 = bottom of the door sill |

The Ancient's gaps between its sparse leaves are real see-through gaps and are keyed transparent. No
canopy pockets were filled in A2. Anchors, sizes, frame counts and `display_scale` are identical to the
previous live meta; only `version` and `source` changed.

## Rules the sets follow
- Stage to stage it is visibly the same tree growing.
- **Mature** shows only a door *outline* (arch) on the trunk; **Elder** and **Ancient** have a real,
  readable door (the Forge entrance).
- **Anchors unchanged:** every `door_floor`, frame size, frame count and `display_scale` is identical
  to the live `assets/art/manatree/manatree_meta.json`. Each tree is placed so its base
  (door sill / where the trunk meets the roots) sits on the existing `door_floor` anchor.
- Same file names, sizes and layout as the live files: `manatree_<stage>.png` stills
  (128×192, 192×288, 256×384, 384×512, 512×640) and 8-frame strips
  `anim/manatree_<stage>_strip.png` (512×64, 768×96, 1472×184, 2048×256, 2048×256), RGBA with 1-bit alpha.
- `<S>/manatree_meta.proposed.json`: proposal only (`haex_approved: false`). Its stage data equals the
  live meta, so the live meta can simply stay.

## Wiring a chosen set in (e.g. B)
1. Move the current live files out of the way, **into a sub-folder** of `assets/library/legacy/`
   (e.g. `assets/library/legacy/manatree_refresh_2026-09-29/`, keeping `anim/`).
   Do not drop them straight into `legacy/`: it already holds the pre-refresh `manatree_*.png`
   originals under the same names.
   ```sh
   L=assets/library/legacy/manatree_refresh_2026-09-29
   mkdir -p $L/anim
   git mv assets/art/manatree/manatree_*.png $L/
   git mv assets/art/manatree/anim/manatree_*_strip.png $L/anim/
   ```
2. Copy the set over: `cp assets/library/manatree_tries/B/manatree_*.png assets/art/manatree/` and
   `cp assets/library/manatree_tries/B/anim/*.png assets/art/manatree/anim/`.
   Leave `manatree_meta.json` as is. Anchors are unchanged, and the proposed meta only differs in `version`/`source`.
3. Open the editor once so Godot re-imports the textures (the `.import` files are git-ignored), then run the
   headless checks.

Built locally with the art-refresh pipeline (`build_manatree.py`: magenta key, pixelize, glow pulse 0.28,
≤1 px canopy sway). The raws are not in the repo.
