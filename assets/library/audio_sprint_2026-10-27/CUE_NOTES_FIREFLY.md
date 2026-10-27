# Cue notes: firefly twinkle

Status: SPRINT, Haex go 2026-10-27

Files: `sfx_firefly_twinkle_1.ogg` (G5), `sfx_firefly_twinkle_2.ogg` (C6), `sfx_firefly_twinkle_3.ogg` (Eb6), the mana motif notes.
Each is a tiny soft FM bell, 0.42 s, OGG Vorbis 44.1 kHz mono, low-passed at 4.5 kHz, soft attack (no click). Measured file peaks are about -18 dBFS (-18.29 / -18.17 / -18.17), so all three are equally loud.

- Bus: SFX_World. `base_db` 0.0, `play_offset_db` -6, so it lands around -24 dBFS in game.
- Trigger: fires randomly from visible fireflies at night only. Fires only when at least one firefly is visible.
- Rate limit: at most 1 every 4 s globally (shared cooldown across all fireflies).
- Variation: pick a random variant (1-3). `pitch_scale` 1.0 fixed, no pitch randomization.
