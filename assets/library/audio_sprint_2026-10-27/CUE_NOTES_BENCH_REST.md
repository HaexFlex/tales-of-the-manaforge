# Cue notes: bench rest

Status: SPRINT, Haex go 2026-10-27

File: `sfx_bench_rest.ogg`. A warm soft FM pad breath swell, 2.5 s: fades in over 0.8 s, gentle bloom, soft fade out. Cm(add9) voicing (C-G-D-Eb-G-Bb), in tune with the C dorian hub. OGG Vorbis 44.1 kHz mono, low-passed, no click. Measured file peak -14.25 dBFS.

- Bus: SFX_World. `base_db` 0.0, `play_offset_db` 0. `pitch_scale` 1.0.
- Trigger: fires once when the Keeper finishes the `sit_down` clip on the Bench.
- Bed lift: while seated, the Music_HubBed bus (or Music, if there is no HubBed bus) gets +2 dB, tweened over 1.5 s.
- On `stand_up`, tween it back to its previous level over 1.5 s.
- No retrigger: if the Keeper sits again within 10 s of the last play, skip the sound. The bed lift still follows sit/stand.
