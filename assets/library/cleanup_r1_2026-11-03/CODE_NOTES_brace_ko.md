# cleanup_r1 — Puff / Mossback brace + KO (step 6)

Date: 2026-11-03 (Europe/Zurich). Worktree: `sprint/cleanup-r1` from `/workspace/cleanup_art_fix/repo_push`.

## Shipped

| Path | Source (1-based ffmpeg) | colours | h | sole |
|---|---|---:|---:|---:|
| `assets/art/battle/party/battle_puff_brace.png` | `videos/puff_brace.mp4` f**140** (held guard) | 21 | 77 | 123 |
| `assets/art/battle/party/battle_puff_ko.png` | `videos/puff_ko.mp4` f**145** (settled sit, eyes closed) | 20 | 68 | 123 |

Canvas 128×128, east-facing, sole y=123, feet_cx≈63.5. Hard alpha 0/255. Palette = live Puff walk/idle (22) Lab-snapped.

## Pipeline

1. Corner 12×12 median magenta → `animlib.key_magenta` + largest figure mask → hard α.
2. ONE scale from brace source height → live standing height (**Puff 77** from `idle_e` / `battle_idle`). KO reuses brace scale (not forced to 77).
3. BOX stepwise (halve while ≥2×) + NEAREST → place sole=123.
4. Lab snap to live palette → majority paint-over of singleton noise → despeck → fill enclosed holes ≤40 → kill magenta.

## Mossback — HELD (design drift)

Imagine brace/ko videos were processed to the same gate (48-colour live still palette snap → 36 colours, h=90/77, sole=123, hard α) but **not** copied into `assets/art/battle/party/`.

Contact review (`mossback_drift_check_4x.png`): live Mossback is a **dark olive** tortoise with a thatched moss shell and **sharp cyan crystal spikes**; the Imagine takes are a brighter **lime** body, flatter rocky moss clumps, and cyan as soft blotches rather than gem spikes. Palette-snapping alone does not restore the live design.

Held candidates (for a re-gen pass): `assets/library/cleanup_r1_2026-11-03/mossback_brace_ko_held/battle_mossback_{brace,ko}.png`.

Re-gen tip: use live `idle_e` / `battle_idle` (and `ref_mossback_fixed_e` only if it matches crystals) as Imagine refs; prompt for olive skin + cyan crystal spikes on a mossy shell, east profile.

## Contacts

- `puff_mossback_brace_ko_contact_{1x,4x}_{midgreen,uibrown}.png` — live idle/battle (battle flipped E) + new brace/ko + Elaia pose refs
- `mossback_drift_check_4x.png` — Mossback-only live vs held

## Wire (Code follow-up, not this ship)

`data/companions.json` → `art.battle.brace` / `art.battle.ko` via `CompanionRoster.battle_pose`. Puff paths ready; Mossback still empty until a matching re-gen ships.
