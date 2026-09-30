# Tales of the Manaforge: Forge v2 Draft

Status: APPROVED for implementation (Haex go 2026-09-29). Numbers are placeholders in one tuning config.

## 1. Scope and delivery
- Builds on PR #16 (editor-visible scenes), or on main once #16 is merged. Everything is visible and adjustable in the Godot editor.
- PR #15 (first Forge) is not merged. We reuse its good parts (station logic, camera clamp, weapon recipes).
- Ships as one package: Forge room, stations, job system, relics, Keeper's Bench, backpack filters, offline tiers, save migration.
- Code works in two passes. Pass A covers the room, collision, stations, jobs, offline tiers, and save migration, using placeholder art. Pass B covers the bench, backpack filters, and final art.
- A dev-only speed multiplier lets us test 10-minute crafts quickly.

## 2. Access
- Enter Forge appears on the Elder and Ancient Manatree (the real door).
- The Forge Key only needs to be in the inventory, not equipped. You never get locked out by wearing a different relic.
- You enter and exit on the south side. The south door or Esc returns you to the clearing in front of the Manatree.

## 3. Room
- A round chamber in the hub's art style, with a wooden floor, dark brown bark walls, and the Manatree's magical swirls as wall decoration.
- The floor is mostly empty, so future stations have room.
- Art: one Grok Imagine plate of about 1600×1200, seen from above at a slight (3/4) angle, with a single south doorway about 160 px wide.
- The swirls are a separate transparent overlay that lines up exactly with the plate, so they can pulse later like the Manatree.
- Collision: Art delivers a floor mask. Code turns it into a wall polygon (CollisionPolygon2D) that follows the painted walls closely, and its points can be dragged by hand in the editor. An exit trigger area sits at the south door.
- Camera is clamped to the room. Controls match the hub: left click selects, right click walks or assigns.
- Audio: no separate Forge music. The hub music gets a soft low-pass filter, a small room reverb, and about −3 dB while you're inside. The door plays sfx_door_bark on enter and exit.

## 4. Stations
Every station is its own scene, with editor markers for where the Keeper stands and where Wisps orbit. Each has an idle frame and a busy frame.

| Station | Input | Output | Time |
|---|---|---|---|
| Crucible | 20 Stone | 1 Sapsteel | 60 s |
| Mill | 20 Wood | 1 Heartwood Bits | 60 s |
| Bramble Press (NEW) | 15 Food | 1 Amberbind | 45 s |
| Anvil | see §6 | tier-1 weapon | 600 s |
| Reliquary (NEW) | see §7 | relic (later also jewelry) | 600 s |

Amberbind is a berry resin that sets like amber. Every Forge recipe uses it.

## 5. Job rules
- Each station holds **1 queued job**.
- A station only progresses while someone is working it: the Keeper, a companion, or a Wisp. With nobody there, it pauses.
- Keeper: progress only while he stands at the station. When he walks away the job pauses, unless a Wisp is also working it. The Keeper's time is the cost you pay.
- Companions: same rule as the Keeper. For now only the Keeper tends; a hook is in place so Elaia can later.
- Wisps: they stack on a station and orbit it. Speed is additive. The Keeper counts 1, a companion counts 1, and each Wisp counts 0.1, up to 4 Wisps. A station with only one Wisp takes 10× the shown time. The Keeper plus four Wisps is 1.4. The row still shows the Keeper's base time. Every Wisp in the Forge is one fewer gathering in the hub.
- **Auto-repeat for upcycling (Crucible, Mill, Press):** when a job finishes, the next one starts automatically, as long as someone is still working the station and there's enough material to pay for it. Otherwise the station stops.
- Anvil and Reliquary do not auto-repeat. Each craft is started deliberately.
- Wisps are only visible in the scene where they work. Hub Wisps don't show in the Forge, and Forge Wisps don't show in the hub. The hub's Wisp counter still counts all of them.

## 6. Anvil: tier-1 weapons (600 s, 150 Essence each)
| Weapon | Path | Sapsteel | Heartwood Bits | Amberbind |
|---|---|---|---|---|
| Rootsteel Edge | fighter | 12 | 6 | 4 |
| Heartwand | caster | 6 | 12 | 4 |
| Switchshaft | ranger / hybrid | 9 | 9 | 4 |

A full weapon from raw materials comes out to about 35 minutes solo, or about 15 minutes with 4 Wisps. That's fine for now; it will grow with future recipes.

## 7. Reliquary: relics (600 s)
Cost per relic: 6 Sapsteel, 6 Heartwood Bits, 6 Amberbind, 100 Essence. No Manashards.

| Relic | Path | Stats |
|---|---|---|
| Oakheart Knot | fighter | +3 Might, +2 Resilience |
| Shardlens | caster | +3 Arcana, +2 Ward |
| Windthorn Bead | ranger | +2 Might, +2 Arcana, +1 Swiftness |

- Relics give pure stats only for now.
- There is one relic slot, so you choose which relic to wear (including the Forge Key).
- Jewelry comes to the Reliquary later.

## 8. Economy rules
- No Manashards in any Forge recipe.
- Only the end products (weapons and relics) cost Essence.
- Refined materials are Sapsteel, Heartwood Bits, and Amberbind.

## 9. Keeper's Bench and backpack
- The Keeper's Bench is a workbench in the hub. You walk up to it and open it, and it replaces the handcraft panel in the backpack. Handcraft recipes (Flintblade, Sapstaff, Thornbow, tools and so on) move there unchanged.
- The backpack becomes pure inventory and storage.
- Backpack filters: All, Raw, Refined (Sapsteel, Heartwood Bits, Amberbind, Fertilizer, Rod), Tools, Weapons, Relics. Each item gets a category field.

## 10. Offline and idle tiers (whole game loop)
These apply to the entire idle loop (harvesting, Manatree, Forge), not just the Forge.
- While the game is open, everything runs at full speed in any scene.
- While the game is closed:
  - 0 to 8 h: 1/20 speed
  - 8 to 24 h: 1/100 speed
  - after 24 h: 1/1000 speed
- A Forge station keeps working offline if someone is working it when the game closes (Keeper, companion, or Wisp) and there's material to pay.
- Offline speed is the station's normal online speed (whoever is working it, including Wisp bonuses) multiplied by the tier factor. Example: Keeper alone gives 1/20 of his pace for hours 0 to 8, 1/100 for hours 8 to 24, then 1/1000.
- This replaces the current simple 8-hour catch-up.
- LOCKED (Haex): Keeper watering offline gets an extra multiplier, OFFLINE_WATER_MULT = 0.2, on Manashards and Essence, on top of the tiers. Target: 24 h of idling yields about 2 basic Ascension upgrades, or about 1/4 of the 3,000 for keep basic tools (about 750 to 800 Manashards). Game Design tunes the exact numbers against that target.
- The save records the Keeper's current task on every autosave, so a crash still counts it.

## 11. Ascension
- On Ascend, all Forge jobs and all Forge materials reset, along with raw materials (same as today).
- Two new very expensive Ascension shop upgrades (Manashards, priced late):
  - Keep intermediate materials (Sapsteel, Heartwood Bits, Amberbind) through Ascend
  - Keep jobs running through Ascend

- The Ascend confirmation warns that Forge jobs and materials will be lost unless the keep upgrades are owned.

## 12. Audio
- Reused sounds: sfx_forge_craft_start plays when a job is queued. sfx_forge_craft_done plays when a processing job finishes. sfx_wisp_deny plays when the queue is full. sfx_upgrade_buy plays on a relic swap.
- New sounds: sfx_press_squeeze, sfx_forge_big_done (weapon or relic finished; small duck, below Fruit), sfx_bench_open, sfx_door_bark.
- Upcycle completions play only a barely audible tick inside the Forge and are silent elsewhere. sfx_forge_big_done is only for Anvil and Reliquary completions; it plays in any scene, rate-limited. Paused and busy states make no sound (badge only). Offline results show a toast only.
- Optional later: a faint positional hum on busy stations.

## 13. Content and copy (on go)
Copy needed: station busy (replaces queue full), Ascend warning, job done, jobs finished while away, station paused (no worker), not enough material, Wisp speed-up hint, relic swap confirm, and a short examine line for each station and for the Bench.

## 14. Art deliverables
- Round room plate, swirl overlay, floor mask
- Crucible, Mill, and Anvil restyled to match the refresh; Bramble Press, Reliquary, and Keeper's Bench new (idle and busy frames)
- 32 px icons: Amberbind, the 3 relics, and restyled Sapsteel and Heartwood Bits
- Paused badge and station-busy badge (a paused station shows its idle frame plus the badge)
- Empty relic slot frame for the character sheet
- Style references: Keeper, Elaia, decorative trees, leaves, runestones, title screen, Manatree A2

## 15. Technical notes
- Save goes from version 8 to 9. It adds per-station jobs, station workers, the new items and categories, the offline-tier timestamp, and the Ascension upgrade flags. Old saves migrate cleanly.
- One always-running job manager works across all scenes.
- The Forge Key becomes an owned item. Version 8 saves that have it equipped get it moved back to the inventory on load.
- Player-facing copy says only Keeper and Wisps until a companion exists in the game.
- Don't run tools/bake_hub_layout.gd, because it wipes editor moves.

## 16. Open or later
- Food sinks beyond Amberbind
- Second relic slot
- Companions (Elaia) tending stations
- Longer craft times for later recipes
- Forge music or ambient sound
- Animated room plate
