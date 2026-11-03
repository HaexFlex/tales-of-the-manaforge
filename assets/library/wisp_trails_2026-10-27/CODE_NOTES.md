# Wisp mana trail (2026-10-27)
- assets/art/fx/wisp_trail/wisp_trail_strip_5x5x3.png (15x5): 3 frames, white/cyan core -> dithered pale cyan -> sparse fade.
- assets/art/fx/wisp_trail/wisp_spark_3x3.png: tiny plus spark for occasional pops.
- Colours from wisp_orbit/wisp_fly (#ffffff #c8f5ff #7ec8e8 #4b6cc8) + vein cyan #3de7ca. Hard alpha, scale 1.
Code suggestion (scripts/wisp.gd, read-only look): add a CPUParticles2D "Trail" as a child of the Wisp root
(sibling of $Sprite, z_index = sprite.z - 1, local_coords = false so it stays behind as the Wisp moves).
- texture = strip, CanvasItemMaterial particles_animation, h_frames 3, v_frames 1, loop off,
  anim_speed so the 3 frames span the lifetime (anim_speed_min/max = 1.0 with lifetime 0.45 s).
- amount 6, lifetime 0.45 s (~13 emits/s), gravity 0, initial_velocity 0-4, spread 180, NEAREST, scale 1.
- emitting only while moving (velocity > ~8 px/s); idle orbit can use amount 2 or off.
- Spark: second emitter amount 1, lifetime 0.3 s, randomness 1.0 (~1 pop per few frames), or skip.
