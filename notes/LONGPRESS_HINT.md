# Long-press hint copy

`ui.longpress_hint` in `data/strings_v01.json` is a **placeholder**. Lore replaces that one key. The scroll panel is 200×78 (three lines). The first-session toast `touch_hold_hint` is a separate line and stays.

The 0.5 passed to `InputMap.add_action` is the action deadzone. The hold before the panel is `WorldHover.REST_SEC` (0.8 s). There is no 0.5 s recogniser.
