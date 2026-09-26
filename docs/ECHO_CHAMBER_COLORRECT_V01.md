# Echo Chamber — ColorRect / placeholder art specs (v0.6.1 polish)

**Status:** Elaia portrait is Haex’s `assets/art/echo/elaia_front.png` (byte copy of the inbox archive). Keeper still uses **sheet idle**. No new paints.

**Battle:** separate scene, 1280×720, nearest.

## Battle layout (locked polish)

| Region | Spec |
|--------|------|
| **Keeper** | **Left** — `assets/art/keeper/keeper_idle_south.png` (128² source). Display **large** (same idea as sheet ×3; target draw ~**384×384** or fill left third). Warm. |
| **Elaia** | **Right** — `assets/art/echo/elaia_front.png`. Display **384×384**, nearest, keep-aspect centered (same box as the Keeper). |
| **Flavour dialogue** | **Top** band (~full width × 80–100px) — Content brief lines |
| **Battle log** | **Lower** band above commands (~full width × 100–140px) |
| **Commands** | Bottom safe ~120px — Strike/Flee; mercy = Spare+Strike only |
| HP | Under each portrait |

## Hub / care

| Item | Spec |
|------|------|
| Portal | ColorRect **96×96** (unchanged) |
| Enter Forge | Care-menu button; **Elder + Ancient only** (hidden earlier stages) |

## Assets upload (standing)

After each ship: sort drops into `assets/` or `assets/library/`, leave `Assets upload/` **empty**. Current inbox still has prior tree/bush/keeper sheets already sliced into `art_restart` / `assets/art` — CA should archive/clear leftovers, not re-slice.

## Out this ship
Forge interior, companion body. Elaia’s battle portrait uses the existing front art (see status above).
