# Forest-ring leaf fall (2026-10-27)
assets/art/fx/leaf_fall/ (hard alpha, scale 1, colours sampled from hub/trees/ring_tree_* and hub/bushes/ring_bush_*):
- leaf_fall_moss_strip.png  12x6 = 3 frames of 4x6 (moss oval: face, edge-on, back)
- leaf_fall_amber_strip.png 20x5 = 4 frames of 5x5 (lobed amber leaf: face, edge, flipped, edge)
- leaf_fall_bark_strip.png  18x4 = 3 frames of 6x4 (dry bark-brown sliver: tilt, edge, tilt back)
No cyan; shapes differ from the Manatree leaf_drift 6x5 diagonal leaf.
CPUParticles2D (one emitter per strip, or one with v_frames if Code packs them; slow and sparse):
- amount: total 6-10 across the visible ring (e.g. moss 4, amber 3, bark 2). lifetime 6-9 s (7.5, randomness 0.2). preprocess 8 s so the hub opens mid-fall.
- gravity (0, 6); initial_velocity 1-4 px/s, direction (0,1), spread 40; damping 0.
- sway: hue/scale curves off; use orbit_velocity 0 and a small tangential... simplest: angular_velocity 0, rotation off (angle 0),
  and x wobble via `linear_accel` min -3 / max 3 with randomness 1, or a script that adds sin(t*0.5*TAU)*2 px to x.
- animation: CanvasItemMaterial particles_animation, h_frames = strip frame count, v_frames 1, loop on,
  anim_speed 0.25-0.5 (flutter about every 0.5-1 s), anim_offset_max 1.
- emission: EMISSION_SHAPE_POINTS, points sampled only along the ring band (the canopy edge of ring trees/bushes,
  e.g. the outer 10-15% of the clearing radius); never over the clearing centre. Rect emitters per side work too.
- whole-pixel positions: enable project setting rendering/2d/snap/snap_2d_transforms_to_pixel and snap_2d_vertices_to_pixel,
  or draw with a parent whose position is rounded each frame; keep scale 1 and texture_filter NEAREST.
- z order: above the ground layer and ground decals, below ring tree canopies (z_index between ground and ring props,
  or a non-Y-sorted layer under the ring trees' crowns so leaves appear from under the canopy edge).
