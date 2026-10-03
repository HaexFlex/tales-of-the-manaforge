# Imagine prompt: Echo portal (hub), 2.5x larger regen

Refs to attach (both on flat magenta #FF00FF):
1. `/workspace/playtest_batch/imagine/portal_ref_current_x5_magenta.png`: current portal design (64x95 art, shown x5). Keep this design.
2. `/workspace/playtest_batch/imagine/portal_ref_scale_keeper_x4_magenta.png`: scale guide at x4. The white box is the target 160x200 canvas, with the current portal blown up 2.5x inside it. The Keeper (128px canvas, ~118 px tall) stands next to it at the same scale.

## Paste-ready prompt
Pixel art game prop, 3/4 top-down view: an ancient stone portal arch for a cozy forest RPG hub. Same design as the reference: a rounded arch of chunky grey-blue stone blocks with glowing teal rune carvings, a stepped stone base of 2–3 rows of blocks, and a swirling bright blue / cyan vortex filling the opening. Redraw it at a higher native resolution: about 160 px wide and 195 px tall, so it is roughly 1.6x the height of the green-haired Keeper in the scale reference. Crisp 1-pixel detail, NOT a blurry upscale. Muted hub palette: neutral grey stone #282b31 / #4b4c50 / #676868 / #787776, teal runes, vortex #03519f / #097bc2 / #0997d4 with light-cyan highlights (colours sampled from the current portal). Dark 1-px outer edge, soft top-left light, no drop shadow. Centred, standing on the canvas bottom edge, on a flat solid magenta #FF00FF background with no gradient, no ground and no text. One single object.

Negative: no blur, no anti-aliased soft edges, no glow halo bleeding onto the background, no characters, no frame or border.

## After generation (Art)
Key out the magenta (hub v3 `key_sampled` + `clean_magenta`), then `C.pixelize` to a 160 px-wide bbox (bottom anchor, about 32 colours, outer outline). Canvas 160x200, hard alpha. Deliver as `assets/art/props/echo_portal_hub_v2.png`. Optionally add a 6–8 frame vortex-swirl strip later.
## Code wiring (when it lands)
`scripts/echo_portal.gd` scales the texture into `PORTAL_BOX=96`. Either set `PORTAL_BOX` to 200, or better, draw it at native size at scale 1 with offset (-80,-200) for a bottom-centre anchor. Then resize the CollisionShape2D (for example 120x60 at the base, or 160x200 at (0,-100)) and move the Label up to about offset_top -228.
