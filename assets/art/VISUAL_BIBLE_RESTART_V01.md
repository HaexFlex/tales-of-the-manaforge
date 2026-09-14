# Tales of the Manaforge — Visual Bible v0.1 (Restart Edition)
**Owner:** Art Direction  
**Status:** Day-1 deliverable — locks for Code; Haex may veto canvas choices  
**Source of truth:** `VISION_RESTART.md` + `refs/` + `SYSTEMS_V01.md` (5 stages)  
**Non-canon:** `art/` forge-hub kit, old `VISUAL_BIBLE_v0.md`, idle-combat combat layouts  

---

## 1. Style pillars

1. **Secret of Mana top-down** — cozy fairy-forest, glowing mana accents, never forge-heroic or combat-HUD.
2. **Readable caretaker fantasy** — Keeper, Manatree stage, and gather nodes read at a glance under point-and-click.
3. **Warm + lightly melancholic** — soft light, cyan mana glow vs warm bark/foliage (match `manatree_ancient_final.jpg`).
4. **HD pixel, hard edges** — nearest-neighbor only; no AA blur in engine.
5. **Refs are style gates** — `refs/keeper_front.png`, `keeper_back.png`, `manatree_ancient_final.jpg` define silhouette, palette, and mood. Door on ancient = **later Forge**, non-interactive art in v0.1.

---

## 2. Canvas locks (**PROPOSED — Haex may veto**)

| Layer | Lock | Notes |
|-------|------|-------|
| **Logical game view** | `1280 × 720` | Windows-first; camera shows ~20×11 tiles at 64px |
| **Tiles / props** | **`64 × 64`** | Ground, wood/stone/food/shard nodes |
| **Keeper (gameplay)** | **`128 × 128`** | Feet-anchored; top-down walk/idle. Portrait refs stay style-only |
| **Manatree landmark** | Multi-tile | See §4 — not a single 64 tile |
| **UI icons** | `32 × 32` | Resource HUD |
| **Filter** | Nearest-neighbor | Godot: `texture_filter = nearest` |

**Why 128 char / 64 tile:** Matches vision’s lower HD band; faster Imagine→NN loop; Keeper refs (~portrait proportions) guide *style*, not square canvas. Prefer **256×256 Keeper** only if Haex wants max fidelity and accepts slower art.

---

## 3. Imagine → ship pipeline (locked)

1. **Generate large** in Grok Imagine (SoM pixel, hard edges, limited palette, fairy-forest glow) at ~2–4× target.
2. **Crop / center** subject; transparent BG where needed.
3. **Nearest-neighbor downscale** to locked canvas.
4. **Quantize** to master / local palette (Keeper ≤32 colors; tiles ≤16; tree stages ≤48).
5. **Light Aseprite clean** — silhouette, feet pivot, outline continuity, kill muddy mid-tones.
6. Export PNG; Godot nearest; document anchor.

Do **not** ask Imagine for native tiny sprites.

---

## 4. Manatree stage set (5 — aligns Design `SYSTEMS_V01`)

Silhouette must grow clearly each stage. Cyan mana veins increase with stage.

| stage_id | Art name | Footprint (tiles @ 64) | Approx px | Notes |
|----------|----------|-------------------------|-----------|-------|
| `sapling` | Sapling | 1×2 | ~64×128 | Small stem, few leaves |
| `young` | Young | 2×3 | ~128×192 | Canopy starts |
| `mature` | Mature | 3×4 | ~192×256 | Clear trunk glow |
| `elder` | Elder | 4×5 | ~256×320 | Strong veins + roots |
| `ancient` | Ancient | 4×6 | ~256×384 | Match ref mood; **door visible, non-interactive** |

- Pivot: **base center** (root contact with ground).
- Stage-up: optional 1-frame flash / leaf burst (Audio sting sync).
- Fruit-ready (ancient): soft glow pulse on canopy / fruit cue — not UI spam.

---

## 5. Keeper

**From refs:** green spiky hair, green eyes/tunic, deep blue cloak with gold trim, brown boots; **back crystal** cyan diamond (mana emblem). Soft SoM face.

| Clip | Frames | Hold | Canvas |
|------|--------|------|--------|
| `idle` | 4 | 140 ms | 128×128 |
| `walk` | 6–8 | 90 ms | 128×128 (4-dir or 4-dir mirrored) |

- Anchor: **feet center** `(64, 128)`.
- Click target: ≥32×32 around body (Code).
- v0.1: front + back minimum; side can mirror/3⁄4 if time.

---

## 6. Gatherables (64×64 props)

| node | Read as | Palette accent |
|------|---------|----------------|
| Wood | Stump / log pile | Warm bark |
| Stone | Rock cluster | Cool grey |
| Food | Berry bush | Soft red/leaf green |
| Manashards | Crystal cluster | Cyan mana (rarer, brighter) |

Clear hover outline (1–2 px mana or cream). Cooldown: dim or “spent” frame.

---

## 7. Palette (master mood)

Extract / match refs:

| Ramp | Role | Guidance |
|------|------|----------|
| **Forest bark** | Trunks, wood nodes | Warm umbers → tan |
| **Canopy** | Manatree leaves | Burgundy → orange-red (ancient) |
| **Mana** | Veins, Keeper crystal, shards | Cyan / electric blue glow |
| **Keeper cloth** | Cloak / tunic | Royal blue + green + gold trim |
| **Ground** | Grass / path | Muted greens, soft dirt — never neon |
| **Outline** | All sprites | Dark warm `#1A1410`–`#0E1018` |

UI: soft wood/leaf panels, not metal forge chrome. Resource counters top or corner; Fruit confirm = warm modal, not alarming.

---

## 8. Minimal HUD / click chrome

- Resource row: icons 32×32 + counts (`wood` `stone` `food` `manashards` `essence` — labels from Content).
- No combat bars.
- Selection: soft SoM-style ring or outline on hoverable nodes / tree.
- Safe margin 24 px.
- Ascend / Fruit panel: readable, cozy; door art does not imply enterable Forge yet.

---

## 9. Camera & readability

- Top-down (slight SoM angle OK if consistent with Keeper sprites).
- Keeper never smaller than ~⅔ tile visually at default zoom.
- Manatree is map landmark — keep clear of dense prop clutter in v0.1 clearing.

---

## 10. Deliverable order (Art production)

1. Master palette swatch from refs  
2. Keeper idle + walk (back + front) @ 128×128  
3. Manatree 5-stage set (silhouette-first)  
4. Four gather node props + ground tileset starter  
5. Minimal HUD icons + panel  

Code stubs ColorRects to these sizes until PNGs land.

---

## 11. File layout (when exporting)

```
/home/box/manaforge/art_restart/   # new; do not mix with old art/
  VISUAL_BIBLE_RESTART_V01.md      # this doc (canonical copy also at manaforge root)
  palette_master_v01.png
  keeper/...
  manatree/...
  props/...
  ui/...
```

Old `/home/box/manaforge/art/` = **shelved non-canon**.

---

## 12. Open for Haex

| # | Question | Art recommendation |
|---|----------|-------------------|
| A1 | Keeper canvas 128 vs 256 | **128×128** gameplay |
| A2 | Tile 64 vs 128 | **64×64** |
| A3 | Mandatory Aseprite clean vs light-only | Light clean OK for v0.1 stubs; harden for ship |

Ping @Game Director when first palette + Keeper test export lands.
