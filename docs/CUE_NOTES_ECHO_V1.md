# Cue Notes — Echo Chamber v1

**Status:** Haex lock (GO). Aligns with SYSTEMS v0.6.0 §4f + CONTENT_STRINGS v0.6.0 §11.

## Hub bed

| Beat | Cue | Rule |
|------|-----|------|
| Battle enter | `mus_hub_forest` | **Stop / pause** the hub bed (no duck). |
| Return (Spare / Defeat / Flee / KO) | `mus_hub_forest` | **Resume** the looping bed. |

## Silence

- No battle music.
- No battle sting.
- No Fruit / Ascend sting on portal fee or Key grant.
- Soft `sfx_ui_*` only for menus, Forge popup, and portal confirm.

## Ownership

`GameAudio.suspend_hub_for_battle()` / `resume_hub_after_battle()`.
