# Tales of the Manaforge — Audio Brief v0.1 (Restart Edition)

**Owner:** Audio  
**Status:** Day-1 deliverable — NEW cozy SoM cue brief (not a battle/idle-combat patch)  
**Source of truth:** `VISION_RESTART.md` + `refs/` + `SYSTEMS_V01.md` + `VISUAL_BIBLE_RESTART_V01.md` + `CONTENT_STRINGS_V01.md`  
**Non-canon:** `/workspace/manaforge-audio/AUDIO_V0.md` (battle/idle-combat pack)  
**Audience:** Code wires cue IDs + buses; Art stage-up flash syncs to stage sting  
**Last updated:** 2026-09-14

---

## 1. Sonic identity

| Pillar | Lock |
|--------|------|
| Era feel | Secret of Mana–leaning chip-orchestral / soft FM + warm pads — **not** forge-heroic, not pure meme 8-bit |
| Mood | Cozy, magical, contemplative, **lightly melancholic** (match vision + Content boot line). Hopeful on Fruit/Ascend, never stressful |
| Palette from refs | Warm bark/canopy (earth, soft strings) vs **cyan mana** (bells, airy leads, quiet sparkle) |
| Mix | Mid-forward laptop speakers; music ducks ~4–6 dB under Fruit/Ascend/stage-up SFX |
| Density | Sparse caretaker feedback — gather + tend readable, never spam on walk |

Shared motif: **4-note mana sigil** (rising, soft resolve) — appears in hub bed (quiet), stage-up (brighter), Fruit harvest (fullest). Same DNA as cyan glow in `manatree_ancient_final.jpg`.

---

## 2. Music (v0.1 only)

| cue_id | When | Mood brief | BPM | Loop / length | Priority |
|--------|------|------------|-----|---------------|----------|
| `mus_hub_forest` | Boot → playfield (always-on bed while in fragment) | Soft arpeggio + warm pad; cyan sparkle sparse in high register. Contemplative, not sleepy. Leaves headroom for SFX. | 76–84 | Seamless 16–32 bars; no hard cadence at loop | P0 |
| `mus_fruit_sting` | Primordial Fruit harvest confirm → toast | Warm swell + sigil motif; hopeful, lightly melancholic — **not** victory fanfare | — | One-shot 4–7s; crossfade back to hub | P0 |
| `mus_ascend_sting` | Ascend confirm → sapling | Gentler than Fruit; resolve into hub (new cycle). Soft choir-pad optional | — | One-shot 3–5s → hub | P0 |
| `mus_title` | Title / boot (optional if time) | Hub motif, thinner | 76–84 | Soft loop or 8-bar bed | P1 |

**Out:** battle themes, boss, zone suite, Forge interior, Echo Chamber.

**Playback:** Music stays on through gather/walk/tend. Duck only for stage-up / Fruit / Ascend stings (and those SFX). No combat crossfade.

---

## 3. SFX pack (MVP)

### UI
| cue_id | Trigger (Content / UI) | Notes |
|--------|------------------------|-------|
| `sfx_ui_confirm` | Menu / Bless / Harvest yes | Soft wood-click + tiny mana tick |
| `sfx_ui_cancel` | Not yet / Stay / Close | Lower, shorter |
| `sfx_ui_open` / `sfx_ui_close` | Panels (Fruit blessings) | Quiet whoosh |
| `sfx_ui_hover` | Optional | Very quiet; skip if noisy |

### Gather (pair Content `gather_*`)
| cue_id | Trigger | Notes |
|--------|---------|-------|
| `sfx_gather_wood` | `node_wood` success | Soft timber lift |
| `sfx_gather_stone` | `node_stone` | Stone from moss — muted thud |
| `sfx_gather_food` | `node_food` | Berry/leaf forage — light rustle |
| `sfx_gather_manashards` | `node_manashards` | Cyan chime (sigil fragment) |
| `sfx_gather_cooldown` | Node on cooldown (optional) | Barely there tick — or silence |

### Manatree care (pair Content water / stage)
| cue_id | Trigger | Notes |
|--------|---------|-------|
| `sfx_tree_water` | `tree_water_ok` | Soft drink / root soak — warm, not splashy arcade |
| `sfx_tree_deny` | No food / mats blocked / cooldown | Soft negative (not harsh buzz) |
| `sfx_stage_up` | Stage advance toast (young→ancient) | Leaf burst + sigil chime; **sync with Art 1-frame flash** |
| `sfx_fruit_ready` | Enter ancient / Fruit available (once per cycle) | Soft canopy pulse — rare, not looping spam |

### Prestige
| cue_id | Trigger | Notes |
|--------|---------|-------|
| `sfx_fruit_harvest` | With / under `mus_fruit_sting` | Crystal bloom + warm low resolve |
| `sfx_upgrade_buy` | Bless purchase | Short blessing chime |
| `sfx_ascend` | With / under `mus_ascend_sting` | Soft reset whoosh → sapling hush |

### Keeper (minimal)
| cue_id | Trigger | Notes |
|--------|---------|-------|
| `sfx_footstep` | Walk (optional) | Grass/soft earth; very quiet, every 2nd step max |
| `sfx_interact_arrive` | Reach click target (optional) | Tiny settle |

---

## 4. Implementation notes (@Code / Engine)

1. **Buses:** `Music`, `SFX_UI`, `SFX_World`, `SFX_Progress` (stage / Fruit / Ascend). Duck `Music` from `SFX_Progress` (~4–6 dB, 100–200 ms attack, 0.8–1.5 s release).
2. **IDs stable:** `mus_*` / `sfx_*` snake_case above — wire from string/event table, not filenames only.
3. **Formats:** `.ogg` preferred; document `loop_start` / `loop_end` for `mus_hub_forest` in `audio_manifest.json` when assets exist.
4. **Stage-up:** fire `sfx_stage_up` (+ optional Art flash) on stage_id change; do not also spam water SFX on the same frame if water caused the advance (prefer stage sting).
5. **Fruit ready:** play `sfx_fruit_ready` once when becoming `ancient`, not every frame of glow.
6. **Stub OK:** silence / placeholder beeps until real assets; keep IDs.

---

## 5. Sync with teammates

| Partner | Need |
|---------|------|
| @Art Direction | Forest mood/palette (cyan vs warm) → reverb/color; stage-up flash ↔ `sfx_stage_up`; ancient Fruit glow ↔ `sfx_fruit_ready` |
| @Game Design | Event order: water → stage-up → Fruit → Ascend (no combat events) |
| @Content & Lore | Cue pairing table in their §9; tone warmer vs melancholic — Haex may veto; Audio follows Content lock |
| @Code / Engine | Buses + cue IDs; hub always-on; duck Progress |

---

## 6. Out of v0.1

Combat / hit / battle music, whisps, Forge door interact, Echo Chamber, per-zone OST, VO, dynamic combat stems.

---

## 7. Open for Haex

1. Boot tone: warmer vs more melancholic (align Content)?  
2. Footsteps on/off for v0.1?  
3. Music through gather (recommended **on**) OK?

---

## 8. Asset path (when generating)

Park exports under `manaforge/audio_restart/` (mirrors Art `art_restart/`). Do not put battle leftovers in the Godot project.
