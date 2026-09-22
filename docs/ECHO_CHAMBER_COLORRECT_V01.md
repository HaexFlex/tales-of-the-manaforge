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
| Enemy portrait (Elaia) | **128×128** | Upper area; cooler/ghost ColorRect (e.g. slate + cyan) |
| Player portrait (Keeper) | **128×128** | Opposite side or below; warmer; can reuse sheet ×3 scale later |
| HP bars | full width under each portrait | segment or solid fill |
| Command bar | bottom **720×120** safe band | Strike / Flee (normal); Spare window = Spare + Strike only |
| Mercy banner | optional top strip | when Elaia &lt;10% HP |

## Care menu (existing chrome)

| Control | Spec |
|---------|------|
| Enter Forge | Same soft wood/leaf button language as Water / Fruit; **grayed** without Key; enabled with Key → “not built yet” popup (Content strings) |

## Icons (optional ColorRect chips)

| Item | Size |
|------|------|
| Stone Sword (already sheet) | 32×32 if shown in battle |
| Forge Key grant toast | 32×32 chip OK |

## Explicitly out this ship
Real portal art, Elaia sprite, Forge interior, companion body, battle music art frames.
