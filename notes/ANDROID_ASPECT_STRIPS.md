# Android aspect: where the picture does not fill

Playtest device is a Samsung Galaxy tablet, about 16:10 or 4:3. The project stays 960×540, stretch `canvas_items`, aspect `expand`, scale mode `integer` on desktop and on mobile. Those three windows divide evenly, so integer scale does not letterbox:

| Device | Scale | Logical viewport |
| --- | --- | --- |
| 2400×1080 (20:9) | 2 | 1200×540 |
| 1920×1200 (16:10) | 2 | 960×600 |
| 1280×960 (4:3) | 1 | 1280×960 |

A fractional mobile override would blur nearest-neighbour art. It was not added.

## Extra area at 16:10 and 4:3

Expand gives extra height (16:10, 4:3) or extra width (20:9). HUD, title chrome, Pause, the away screen, and the minigame window stay inside the 24 px margin plus any display safe-area inset.

The world does not leave an empty band at zoom 1 on these three views:

- **Hub forest** is 4320×3780 with a 120 px camera inset. All three logical views fit inside the map, so the extra height shows more forest.
- **Forge room** is 1600×1200. All three logical views fit at zoom 1.
- **Title background** `assets_extra/title/title_bg_1200x540.png` uses keep-aspect covered. 16:10 and 4:3 crop the left and right of that 20:9 plate. There is no empty bar. The sides of the painting are what get cut.
- **Battle** and the **pause backdrop** are full-rect colour fills.

## Where Art would supply strips

Empty clear colour shows up only when a view is larger than the painted map:

- Forge zoom-out past 1600×1200 (sides and top/bottom outside the room).
- Hub zoom-out past 4320×3780 (the camera limits release and the clear colour shows on that axis).

If the title should show the full 20:9 composition on a 4:3 or 16:10 tablet instead of cropping the sides, the plate needs to be taller than 540.
