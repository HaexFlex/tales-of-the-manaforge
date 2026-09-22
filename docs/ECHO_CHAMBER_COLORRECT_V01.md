# Echo Chamber v1 — ColorRect / placeholder art specs

**Status:** GO (Haex) v0.6.1/0.6.2 polish — **no new paints**. Code uses ColorRects / solid placeholders matching these sizes.

**Battle:** separate scene. Filter nearest. Keeper uses sheet `keeper_idle_south.png` (128²) drawn large.

## World / hub

| Placeholder | Size (px) | Notes |
|-------------|-----------|--------|
| Echo portal | **96×96** | Landmark after first Ascend; cyan/mana tint ColorRect OK; clickable |
| Enter Forge | **UI button only** on Manatree care panel | **Elder + Ancient only**; grayed vs enabled — **no world door** |

## Battle scene (1280×720)

| Region | Size / layout | Notes |
|--------|---------------|--------|
| Flavour dialogue | **TOP** band | Full `echo_01_*` lines (`intro` + `intro_2`, mercy, spare, defeat, flee, return) |
| Enemy portrait (Elaia) | **~384×384** ColorRect | Right; cooler/ghost slate+cyan |
| Player portrait (Keeper) | **~384×384** TextureRect | Left; sheet `keeper_idle_south.png` scaled large |
| HP bars | full width under each portrait | solid fill |
| Battle log | **LOWER** under portraits | `battle_log_*` lines |
| Command bar | bottom safe band | Strike / Flee (normal); Spare window = Spare + Strike only |
| Mercy banner | optional thin top strip | when Elaia &lt;10% HP |

## Care menu (existing chrome)

| Control | Spec |
|---------|------|
| Enter Forge | Visible only on **Elder** and **Ancient**; hidden on Sapling / Young / Mature. Soft wood/leaf button language; **grayed** without Key; enabled with Key → “Not built yet! Stay tuned.” |

## Icons (optional ColorRect chips)

| Item | Size |
|------|------|
| Stone Sword (already sheet) | 32×32 if shown in battle |
| Forge Key grant toast | 32×32 chip OK |

## Explicitly out this ship
Real portal art, Elaia sprite, Forge interior, companion body, battle music art frames.
