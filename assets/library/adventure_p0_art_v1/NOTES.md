# Adventure Phase 0 art v1 (2026-10-05)

Branch `cursor/adventure-phase-0-0148`. Replaces opaque brown/cream placeholders with game-ready hub-v3 / Echo-battle art. Hard alpha (0/255), transparent RGB = 0, no magenta fringe. Contact sheet: `assets/library/adventure_p0_art_v1/phase0_art_contact.png` (also `/workspace/adventure_p0_art/out/phase0_art_contact.png`).

Imagine sources and prompts: `/workspace/adventure_p0_art/imagine/` (QUEUE.md, prompt md files, `out/*_v1_a.png`). Prep brief: `/workspace/adventure_p0_art/PREP.md`.

## Corvane (Echo 2 + companion)

| Path | Size | Anchor / framing | Notes |
|---|---|---|---|
| `assets/art/echo/battle_corvane_idle.png` | 128×128 | Face **LEFT (west)**; feet x≈64; sole y=123; bbox ~28,6–76,123 (49×118) | Leather warden, short dark/ash hair, cyan mana-scar on forearm. ~40 colours |
| `assets/art/portraits/corvane_portrait.png` | 52×52 | Eye line ≈ row 24; chin ~36–38; shoulders at bottom | Same face as battle; cheek scar + cyan gem at collar |
| `assets/art/portraits/corvane_portrait_sheet.png` | 160×160 | Same framing ×(160/52) | Palette shares ~37 colours with battle |

Code already points here (`Adventure.ART_CORVANE_*`, `companions.json`, `echo_corvane.json`). Character sheet UI still Keeper/Elaia-only — sheet art is ready when Code wires Corvane.

## Brewing stand

| Path | Size | Anchor |
|---|---|---|
| `assets/art/props/brewing_stand.png` | **64×80** | Bottom-centre; base on bottom edge (sole y=79). `STAND_SIZE` locked |

Stump table, teal cauldron glow, vials, mortar, herb bunch. ~29 colours. Unlocks when Corvane joins (`brewing_stand.gd`).

## Herbs & potions (32×32 HUD icons)

| Path | Subject | Cols |
|---|---|---|
| `assets/art/ui/icon_glowcap.png` | Cyan-spotted mushroom | 21 |
| `assets/art/ui/icon_bitterroot.png` | Knobbly dark root | 19 |
| `assets/art/ui/icon_heart_salve.png` | **Burlap pouch with pink heart** (Imagine; not a ceramic jar) | 18 |
| `assets/art/ui/icon_bile_vial.png` | Corked greenish glass vial | 21 |

Dark outer outline, ~17–22 colours, match `icon_food` / `icon_essence` family. `Adventure.ART_*` constants exist; adventure panel is still text-only until Code binds textures.

## Reach foes (NEW — Code must wire paths)

Suggested folder: `assets/art/echo/`. All 128×128, hard alpha, dark outline. Draft IDs from PREP:

| File | Display | Facing | Size notes |
|---|---|---|---|
| `battle_briar_warden_idle.png` | Briar Warden | **West (left)** — three-quarter | ~45×114; feet x≈65, sole y=123. Maps to current `reach_foe` |
| `battle_wilt_wisp_idle.png` | Wilt Wisp | Front / symmetric | **Small** ~32×77; floats (sole ≈ y=118). Soft early foe |
| `battle_root_snapper_idle.png` | Root Snapper | **Front** (viewer) | Low wide ~109×79; bbox mid x≈64, sole y=123. Purple ground shadow removed. Do not mirror — already front |
| `battle_moss_brute_idle.png` | Moss Brute | **Front** (viewer) | Stocky ~110×114; mid x≈64, sole y=123 |

Phase 0 data today has a single `reach_foe` (“Briar Warden”) with no `battle_art_path`. Wire Briar first; Wisp / Snapper / Brute are Phase 1 roster art.

## Face / style notes

- Corvane battle (profile) ↔ portraits (front): same leather / hair / cyan accent language; scar clearer on portrait.
- Root Snapper & Moss Brute are **front-facing** by Imagine design — fine for Echo portrait boxes (stretch keep-aspect). Not forced to west.
- Heart Salve icon is a **pouch + heart**, not a jar.
- Corvane / foes are slightly gritier than hand-pixelled Keeper/Elaia (Imagine downscale); still readable at battle 3× (384 rects).

## Checks

All shipped PNGs: RGBA, hard alpha, clear RGB 0, 0 magenta / pink fringe. `.import` files use project 4.7 `[params]` (lossless, no mipmaps, `fix_alpha_border`).
