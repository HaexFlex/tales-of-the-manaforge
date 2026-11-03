# Stage-up bloom (2026-10-27)
- bloom_petal_strip_5x5x6.png (30x5): cream/amber petal tumbling through 6 frames.
- bloom_glint_strip_5x5x4.png (20x5): cyan mana glint, star -> fade.
- bloom_ring_<size>_{0,1,2}.png: ground ring flash, solid -> 60% dither -> 25% dither. Sizes from manatree_meta.json root spread:
  sapling 72x20, young 120x32, mature 440x110, ancient 600x150 (use ancient for elder too).
Particle settings (one-shot on stage-up, child of the Manatree, local_coords=false):
- Petals: CPUParticles2D one_shot, explosiveness 0.85, amount sapling 8 / young 12 / mature 24 / elder+ancient 32,
  lifetime 2.2 s, emission rect = (stage root width/2, crown height*0.3) centred at -crown_h*0.6,
  direction (0,-1), spread 70, velocity 30-60, gravity (0,22), damping 8, CanvasItemMaterial particles_animation
  h_frames 6, anim_speed 1.5-2.5, anim_offset_max 1, angle 0 (keep pixel art unrotated), scale 1.
- Glints: amount 6/8/12/16, lifetime 0.6 s, explosiveness 0.6, same rect, velocity 0-8, gravity 0, h_frames 4, loop off.
- Ring: Sprite2D centred on door_floor (y +2), frames 0,1,2 at 90 ms then hide; draw under the tree (lower z).
