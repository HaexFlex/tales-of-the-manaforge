# Art needed — Backpack, Handcraft, Grow

**Owner:** Haex (art)  
**Status:** art drop c9fda76 wired the 32px icons that exist (wood, stone, food = fish, Manashards, Essence, Fertilizer, planks, fragments, rods, axe/pick heads, stone axe, stone pickaxe, backpack, pause). Still **neutral placeholder squares** (tooltip, no label): Wooden Basket, Stone Watering Can, Stone Sword, Keep Tools, Character, Ascension reopen, equip-slot chrome, care action buttons (Water / Grow / Harvest keep their words).  
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
| Inventory / craft row: Stone Axe Head | `icon_axe_head.png` | 32×32 | `#6b7c8a` slate | Intermediate |
| Inventory / craft row: Stone Pickaxe Head | `icon_pickaxe_head.png` | 32×32 | `#5c6b73` steel | Intermediate |
| Inventory / craft row: Stone Axe | `icon_stone_axe.png` | 32×32 | `#c46a2b` rust | Unique tool (2× wood channel) |
| Inventory / craft row: Stone Pickaxe | `icon_stone_pickaxe.png` | 32×32 | `#4a6d8c` iron blue | Unique tool (2× stone channel) |
| Inventory / craft row: Wooden Basket | `icon_wooden_basket.png` | 32×32 | `#d4b84a` straw | Unique tool (2× food channel) |
| Inventory / craft row: Stone Watering Can | `icon_stone_watering_can.png` | 32×32 | `#3d8b8b` teal | Unique tool (shard_roll ×2; Essence water unchanged) |
| Inventory / craft row: Fertilizer | `icon_fertilizer.png` | 32×32 | `#6b5a24` soil | Consumable Grow cost |
| Ascension shop row: Keep Tools | `icon_keep_tools.png` | 32×32 | `#b8860b` bronze | Blessing row glyph |

Suggested folder: `assets/art/ui/backpack/` (or existing `assets/art/ui/`).

Resource HUD already has wood/stone/food/manashard textures — do **not** replace those in this pass. Essence still has no dedicated HUD chip; Grow uses the violet placeholder above.

Battle-gear, Runestone, and character-sheet icons are listed in the next section. Do not invent Echo Chamber combat art here.

## Art needed — Character sheet, Runestones, Stone Sword

**Owner:** Haex (art)
**Status:** placeholders shipped (ColorRect slot chrome, Polygon2D stones, Keeper idle frame for the portrait)
**Code:** `scripts/character_sheet.gd`, `scripts/runestone.gd`, `data/equipment.json`, `data/keeper_stats.json`

| Placeholder (where) | Suggested sprite | Size | Color now | Purpose |
|---------------------|------------------|------|-----------|---------|
| `HUD/Panel/CharacterButton/CharacterIcon` | `icon_character.png` | 32×32 | `#c4a24a` gold | HUD Character button (left of Backpack). Key **C** opens the sheet |
| Handcraft row / gear bag: Weapon Rod | `icon_weapon_rod.png` | 32×32 | `#6e4a32` dark wood | Gear-inventory intermediate. 10 Wooden Planks. Not the Wooden Tool Rod |
| Equipment inventory / weapon slot: Stone Sword | `icon_stone_sword.png` | 32×32 | `#b7b1a8` pale stone | Only battle weapon. Lives in the equipment inventory, not the backpack |
| Paper-doll empty slot | `icon_equip_slot.png` | 44×44 | half-transparent warm square, **no gold border** | Unlocked empty slot chrome (weapon, later armor) |
| Paper-doll locked slot | `icon_equip_lock.png` | 44×44 | translucent grey square | Caption **Locked** sits under the square only. Relic tooltip: “Relic locked — needs a Forge Key.” Other slots: “Not yet — the Forge still sleeps.” |
| Empty weapon slot | — | — | half-transparent square | Caption **Weapon** until a weapon is equipped; then the item name (Stone Sword) |
| Hub Runestone (one per stat) | `runestone.png` (or seven tinted) | ~32×48 | stat tint (Might rust, Arcana violet, Resilience olive, Ward blue, Vitality green, Swiftness gold, Fate rose) | Keeper selected + right-click walks in range, then spends Manashards. Polygon2D stand-in |
| Character portrait | existing `keeper_idle_south_0000.png` | 128×128 | — | Already in game. Do not replace in this pass |

Suggested folder: `assets/art/ui/character/` for icons, `assets/art/props/` for the Runestone.

Portrait slots already sit on the body (head above the head, chest on the chest, weapon at the right hand, and so on). Swap the ColorRect in each slot for the icon; keep the slot ids.
