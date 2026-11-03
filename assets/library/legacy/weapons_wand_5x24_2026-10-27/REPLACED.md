# Replaced 2026-10-27: wand 5×24 natives

These were the v2 wands (5×24, grip family `(2, 7)`). GD size call for combat readability: redraw at **9×36** with grip `(4, 12)`.

Replaced by:
- `assets/art/battle/weapons/wpn_wand_t{0,1,2}.png` (9×36)
- `assets/art/battle/weapons/rot/wpn_wand_t*_r{0..7}.png` (tip-east = r0)
- updated wand entries in `rot/grip_offsets.json`

Body clip for wand cast (separate from sword `attack`):
- `assets/art/battle/modular/keeper/attack_wand/frame_0000..0007.png`
- anchors in `assets/library/combat_2026-10-27/hand_anchors.json` (`clip=attack_wand`, includes `tip_ox`/`tip_oy`)
- tip FX: `assets/art/battle/fx/wand_cast_spark_strip.png`
