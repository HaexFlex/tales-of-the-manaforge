# Manaforge Audio Restart v0.1

Placeholder-quality but intentional cozy SoM-leaning cues for **Tales of the Manaforge (Restart Edition)**.

Source brief: `../AUDIO_RESTART_V01.md`

## Layout

Flat files: each `cue_id.ogg` sits directly in this folder. See `MANIFEST.json` for bus / loop metadata.

## For @Code

1. Copy all `*.ogg` into the Godot project at `assets/audio/` (same filenames).
2. Fill `data/audio_cues.json` (or equivalent) with paths like:
   ```json
   "mus_hub_forest": "res://assets/audio/mus_hub_forest.wav"
   ```
   Or use `MANIFEST.json` `cues.*.file` → `res://assets/audio/<file>`.
3. Buses: `Music`, `SFX_UI`, `SFX_World`, `SFX_Progress`. Duck Music ~4–6 dB under Progress stings.
4. `mus_hub_forest` is a 16.0s @ 44100 / 80 BPM seamless loop (`loop: true`); load `.wav` for click-free loop (`.ogg` kept alongside).

## Motif

Shared 4-note **mana sigil**: C–Eb–F–G (rising minor → hopeful). Quiet in hub, brighter in stage-up, fullest in fruit sting/harvest.

## Regenerating

```bash
python3 /workspace/manaforge_audio_gen/synthesize_v01.py
```

Do not commit battle/idle leftovers into the Godot tree.
