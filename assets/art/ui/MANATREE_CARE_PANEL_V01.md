# Manatree care panel layout v0.1 (SYSTEMS v0.3.3)

**Status:** LOCK — care chrome must never show Ascension Buy rows.

## Purpose
World-side Manatree interaction only: Water, stage Needs / Pay, and (at Ancient) Fruit CTA.

## Contents by stage

### Pre-Ancient
- Title: Manatree Care + current stage name
- Needs lines (`essence 12/20`, …)
- **Pay / Tend** (enabled when all met)
- **Water**
- Close / dismiss as Code prefers

### Ancient (pre-commit)
- Fruit ready copy + **Harvest Primordial Fruit…** (starts two-step confirm)
- **Water** still available (bank manashards)
- **Forbidden:** blessing list, Buy, Ascend, shop footer

### After Fruit commit
- Care panel **closes** (or locks); world paused
- **Ascension shop** opens as separate window — see `ASCENSION_SHOP_LAYOUT_V01.md`

## Geometry (guide)
- Preferred ~520×420 soft wood/leaf panel (not full shop width)
- No scrollable Buy list
- Primary actions in a single action band (not a shop footer)

## Refs
- Mock: `manatree_care_panel_v01.png`
- Shop: `ASCENSION_SHOP_LAYOUT_V01.md` / `ascension_shop_layout_v01.png`
