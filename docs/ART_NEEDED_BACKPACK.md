# Art needed — Backpack, Handcraft, Grow

**Owner:** Haex (art)  
**Status:** placeholders shipped as **ColorRect** only (no generated PNGs)  
**Icon size:** **32×32** HUD / row icons, nearest-neighbor  
**Code:** `scripts/autoload/backpack.gd` colors + `scenes/hud.tscn` / `scripts/hud.gd`

Replace each ColorRect with a sprite of the suggested name. Keep IDs stable.

| Placeholder (where) | Suggested sprite | Size | Color now | Purpose |
|---------------------|------------------|------|-----------|---------|
| `HUD/Panel/BackpackButton/BackpackIcon` | `icon_backpack.png` | 32×32 | `#7a4e2d` satchel brown | HUD button glyph (left of Pause) |
| Care Grow: `CarePanel/CareGrowCosts/FertilizerIcon` | `icon_fertilizer.png` | 32×32 | `#6b5a24` soil | Grow cost — Fertilizer |
| Care Grow: `CarePanel/CareGrowCosts/EssenceIcon` | `icon_essence.png` | 32×32 | `#8e5aa8` violet | Grow cost — Essence |
| Inventory / craft row: Wooden Planks | `icon_wooden_planks.png` | 32×32 | `#c4a574` tan | Intermediate |
| Inventory / craft row: Stone Fragments | `icon_stone_fragments.png` | 32×32 | `#8a8e96` gray | Intermediate |
| Inventory / craft row: Wooden Tool Rod | `icon_wooden_tool_rod.png` | 32×32 | `#8b5a2b` brown | Intermediate |
| Inventory / craft row: Axe Head | `icon_axe_head.png` | 32×32 | `#6b7c8a` slate | Intermediate |
| Inventory / craft row: Pickaxe Head | `icon_pickaxe_head.png` | 32×32 | `#5c6b73` steel | Intermediate |
| Inventory / craft row: Stone Axe | `icon_stone_axe.png` | 32×32 | `#c46a2b` rust | Unique tool (2× wood channel) |
| Inventory / craft row: Stone Pickaxe | `icon_stone_pickaxe.png` | 32×32 | `#4a6d8c` iron blue | Unique tool (2× stone channel) |
| Inventory / craft row: Wooden Basket | `icon_wooden_basket.png` | 32×32 | `#d4b84a` straw | Unique tool (2× food channel) |
| Inventory / craft row: Stone Watering Can | `icon_stone_watering_can.png` | 32×32 | `#3d8b8b` teal | Unique tool (shard_roll ×2; Essence water unchanged) |
| Inventory / craft row: Fertilizer | `icon_fertilizer.png` | 32×32 | `#6b5a24` soil | Consumable Grow cost |
| Ascension shop row: Keep Tools | `icon_keep_tools.png` | 32×32 | `#b8860b` bronze | Blessing row glyph |

Suggested folder: `assets/art/ui/backpack/` (or existing `assets/art/ui/`).

Resource HUD already has wood/stone/food/manashard textures — do **not** replace those in this pass. Essence still has no dedicated HUD chip; Grow uses the violet placeholder above.

Do not generate battle-gear / Runestone / Echo Chamber icons here.
