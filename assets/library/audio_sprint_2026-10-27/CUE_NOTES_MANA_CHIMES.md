# CUE NOTES: Mana Chimes (harvest pop, Manatree-stage variants)

**Status: SPRINT, Haex go 2026-10-27, pushed to sprint branch**

## Cue ids
| cue id | file | note | Manatree stage |
|---|---|---|---|
| sfx_mana_chime_1 | sfx_mana_chime_1.ogg | C5 | 1 |
| sfx_mana_chime_2 | sfx_mana_chime_2.ogg | Eb5 | 2 |
| sfx_mana_chime_3 | sfx_mana_chime_3.ogg | F5 | 3 |
| sfx_mana_chime_4 | sfx_mana_chime_4.ogg | G5 | 4 and 5 |

Motif: mana sigil C-Eb-F-G. Preview: `preview_mana_chimes_sequence.ogg` (all 4 in order).

- **Bus:** SFX_World (never ducks)
- **Fires on:** harvest cue: layer on the `keeper_harvested` event alongside `sfx_gather_*`, not `sfx_fruit_harvest`; variant picked by current Manatree stage (1=C, 2=Eb, 3=F, 4-5=G).
- **play_offset_db:** 0 (base_db 0.0; pitch_scale 1.0, no jitter, so the motif stays in tune)
- **Throttle:** match the gather cue gap of 0.9 s; the 80 ms note is superseded.
- Follows the freeze ruling: silent during Post-Ancient freeze / Fruit-commit hold (it's SFX_World).

## Current harvest cue (from MANIFEST.json v0.3.0-battle)
MANIFEST has no cue literally called "harvest pop". The repeating harvest event is `keeper_harvested`, which plays
**sfx_gather_wood / sfx_gather_stone / sfx_gather_food** (SFX_World, pitch 0.96-1.04, global 0.9 s gap).
The only cue with "harvest" in its name is **sfx_fruit_harvest** (SFX_Progress, ducks the bed, Fruit commit / Ancient timeout, plays with mus_fruit_sting).
That's a rare milestone, so it doesn't fit an SFX_World cue throttled to 80 ms. **Confirm which event is meant** before wiring.
Note: the existing 0.9 s gather gap is much longer than the 80 ms throttle here.

## Specs (measured after encoding; LUFS measured on a copy padded to 1 s)
OGG Vorbis q6, 44.1 kHz mono, 0.50 s, 8 ms attack, FM bell, 4.5 kHz LPF.
| file | peak dBFS | LUFS-I | energy >6 kHz |
|---|---|---|---|
| chime_1 C5 | -12.0 | -28.6 | 0.002 % (-47 dB) |
| chime_2 Eb5 | -12.0 | -28.7 | 0.0005 % (-53 dB) |
| chime_3 F5 | -12.0 | -28.8 | 0.001 % (-50 dB) |
| chime_4 G5 | -12.1 | -28.9 | 0.046 % (-33 dB) |
Generator: `gen_mana_chimes.py` (numpy + scipy + ffmpeg).
