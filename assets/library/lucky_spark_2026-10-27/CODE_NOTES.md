# Lucky spark (2026-10-27)
- assets/art/fx/lucky_spark/lucky_spark_3x3.png: warm-gold recolour of wisp_spark_3x3 (colours: firefly warm #f0e68c, wisp gold #d4b84a/#8c6e28, #fff6c8 core).
- assets/art/fx/lucky_spark/lucky_burst_strip_7x7x4.png (28x7): flash -> 6-point burst -> spread -> fading tips.
Code (lucky_harvest over the harvest node):
- One Sprite2D/AnimatedSprite2D at node top (about the node's art top -8 px), burst strip h_frames 4 at 75 ms/frame = 0.3 s, one-shot, then free.
- Plus a CPUParticles2D one_shot, explosiveness 1.0, amount 5, lifetime 0.3 s, texture lucky_spark_3x3, velocity 20-40, spread 180, gravity (0,-10), NEAREST, scale 1.
