# Echo Chamber v1 — ColorRect / placeholder art specs

**Status:** GO (Haex) — **no real sprites this ship**. Code uses ColorRects / solid placeholders matching these sizes.

**Battle:** separate scene. Filter nearest when sprites arrive later.

## World / hub

| Placeholder | Size (px) | Notes |
|-------------|-----------|--------|
| Echo portal | **96×96** | Landmark after first Ascend; cyan/mana tint ColorRect OK; clickable |
| Enter Forge | **UI button only** on Manatree care panel | Grayed vs enabled states — **no world door** |

## Battle scene (1280×720)

| Region | Size / layout | Notes |
|--------|---------------|--------|
| Flavour dialogue | top band ~960×100 | Full `echo_01_*` lines |
| Enemy portrait (Elaia) | **320×320** ColorRect | Right; cooler/ghost slate+cyan |
| Player portrait (Keeper) | **320×320** TextureRect | Left; same idle south as Character sheet |
| HP bars | full width under each portrait | segment or solid fill |
| Battle log | lower band under portraits | combat lines / reward toast |
| Command bar | bottom **720×100** safe band | Strike / Flee (normal); Spare window = Spare + Strike only |
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
