# Fireflies sprite (2026-10-27)
- assets/art/fx/fireflies/firefly_warm_strip_8x8x4.png (32x8) and firefly_cyan_strip_8x8x4.png (32x8).
- 4 frames, 8x8: dim -> mid -> peak -> fade. Hard alpha. Warm = tileset greens/flower yellow; cyan = fx_vein_mote colours.
- Swap in scripts/hub/glade_fireflies.gd: replace `_glow_texture()` 2x2 Image with the strip; CanvasItemMaterial
  particles_animation=true, h_frames=4, v_frames=1, loop, anim_speed ~0.6-1.0 (about 100-150 ms/frame), anim_offset_max=1.0.
  Use the cyan strip for ~1 in 5 motes (second emitter). Keep NEAREST, scale 1.
