# Corvane portrait — CUTE redo (Imagine)

Haex rejected grit Corvane. Battle cute is locked at:
`assets/art/echo/battle_corvane_idle_cute.png` (also `/workspace/corvane_cute_tree/assets/library/corvane_cute_v1/battle_corvane_idle_cute.png`).

## Goal
Front bust portrait matching the **cute battle** face/hair/outfit — soft youthful look, warm brown hair, cyan mana-gem accent, forest-warden browns. NOT the grit bruiser face.

## Attach
1. `/workspace/corvane_cute_tree/assets/library/corvane_cute_v1/imagine/corvane_cute_battle_x4_magenta.png` — cute battle idle ×4 on magenta (face + outfit lock)
2. Existing portrait framing refs (Keeper/Elaia 52 & sheet style):
   - `assets/art/portraits/keeper_portrait.png` / `elaia_portrait.png` (and sheets) OR
   - `/workspace/adventure_p0_art/refs/` portrait composites if present
3. Optional: grit portrait only as "DO NOT match this face" negative ref

## Output
Save Imagine result as:
`/workspace/adventure_p0_art/imagine/out/corvane_portrait_cute_v1_a.png`
(flat magenta #FF00FF background, bust frontal, head+shoulders)

## After generation (art agent)
Process to:
- `assets/art/portraits/corvane_portrait.png` — 52×52, eye line ~row 24, chin ~36–38
- `assets/art/portraits/corvane_portrait_sheet.png` — 160×160
Also copy into `assets/library/corvane_cute_v1/drop_in/` for Code swap with battle.

## Paste-ready prompt
Pixel-art FRONT BUST portrait of the same young male as the attached left-facing battle sprite (cute Corvane). Soft youthful face, small smile, warm messy brown hair, light blush optional, cyan teardrop mana-gem on brown quilted forest tunic with brass buckle. Match the battle sprite's face and hair exactly — cute / approachable, NOT gritty scarred bruiser. Bust framing like Keeper/Elaia portraits (head and shoulders). Flat magenta #FF00FF background. Clean hard pixels, limited palette (~40 colours), dark outer outline.

Negative: grit face, scars, heavy stubble, wide jaw bruiser, magenta fringe, soft blur, photo, 3D, text, watermark.
