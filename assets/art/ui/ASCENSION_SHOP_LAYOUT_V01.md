# Ascension shop layout v0.1 (Haex bugfix)

**Status:** LOCK for Code — playtest collision fix (Harvest overlapping Buy / footer unclear).

## Flow (two windows)

1. **Fruit confirm modal** (only while committing Fruit)  
   - Title + body + **Harvest** / **Cancel**  
   - **No** blessing list, **no** Ascend, **no** Buy

2. On Harvest confirm → **close modal**, **open Ascension shop** (separate centered window)

3. Shop → buy 0+ ranks → **Ascend** or **Close**

## Shop panel geometry (1280×720 hub)

| Region | Height | Contents |
|--------|--------|----------|
| Header | 64px | Title, subtitle, ◆ manashards chip (top-right) |
| Scroll list | flex | Blessing rows only; clips; scrollbar |
| Footer | 72px | **Close** (left) · **Ascend** (right) — clear of rows |

Preferred panel: **720×500** (min **640×420**), screen center.

### Row (48px)
- Left: blessing name + `Rank cur/max`
- Right: **Buy {cost}** button (afford / can’t-afford tint)
- Buy hitboxes live **only** inside the list clip rect — never in the footer band

### Forbidden (Haex)
- Harvest button on the shop panel
- Non-scrolling list that covers Ascend/Close
- Footer controls under overlapping Buy rows

## Chrome
Soft wood/leaf panels, gold edge, cyan shard chip — matches Restart visual bible. Resource icons 32×32 NN if shown.

## Refs
- `ascension_shop_layout_v01.png` — annotated mock
- `ascension_shop_regions_v01.png` — region wire
- Blessings: SYSTEMS_V01 §5 + Content strings (Deep Roots … Extra Wisp)
