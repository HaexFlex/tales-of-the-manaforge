# Touch: hotkey-only actions

Pass 1 does not add buttons. This is the list of keyboard actions that have no on-screen control, so a later pass can add only these.

Launch touch-from-mouse without changing the desktop default:

```
godot --path . -- --emulate-touch
```

That sets `Input.emulate_touch_from_mouse` at runtime. The project setting `input_devices/pointing/emulate_touch_from_mouse` stays off.

## Needs an on-screen control

- **Arrow keys — pan the camera.** Hub (`scripts/main.gd`) and the Forge room (`scripts/forge_room.gd`). There is no d-pad. A finger does not pan the map.

## Already covered, no new button

- **Esc — Pause.** HUD pause button. Android back opens and closes Pause.
- **C — character sheet.** Character button.
- **I — backpack.** Backpack button.
- **G / right-click — command.** Long-press (the same 0.8 s as the hover tooltip, `WorldHover.REST_SEC`).
- **H — inspect the control under the pointer.** The same long-press shows that tooltip.
- **Mouse wheel — zoom the hub.** Not a key. There is no pinch yet. Listed so it is not mistaken for a missing hotkey button.
- **Title Up/Down/Enter, battle 1–6, Tab, Q, Esc, Space/Enter, minigame keys.** Each of those keys drives a control that a tap already hits (menu buttons, battle slots, speech page, minigame click or drag, Steeping replay, Woodsong tune and volume).
- **F8 / F9 — animation preview.** Debug only (`manaforge_debug`). Not a player button.

Walk keys, a map key, and quick save are not in the game. Options does not offer them, and this pass does not invent buttons for them.
