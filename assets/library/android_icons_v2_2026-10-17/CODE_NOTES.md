# Android icons v2 (2026-10-17), notes for Code. No code or scene change needed.

Files were replaced in place (same paths, same names), so `export_presets.cfg` 139-142 (`launcher_icons/main_192x192`, `adaptive_foreground_432x432`, `adaptive_background_432x432`, `adaptive_monochrome_432x432`) still point at the right files. `.import` files are unchanged; let Godot re-import (the uids stay).

| File (assets/ui/android/...) | Size | Change |
|---|---|---|
| `legacy/ic_launcher_48 / 96 / 144 / 192.png` | 48, 96, 144, 192 | one shared master at x1..x4 (byte-exact multiples), flat square corners, Keeper 90% of height |
| `legacy/ic_launcher_72.png` | 72 | same master at x1.5 nearest (72 is no multiple of 48: the only non-integer file; used by Android 7.x hdpi only) |
| `legacy/ic_launcher_store_512.png` | 512 | same framing (47-grid x11) |
| `legacy/ic_launcher_round_192.png` | 192 | whole bust inside the circle |
| `adaptive/ic_launcher_background_432.png` | 432 | flat bark/moss bands, no dark vignette corners |
| `adaptive/ic_launcher_foreground_432.png` | 432 | bust x5 at (118,77); farthest pixel 140 px from the centre, inside the 72 dp launcher circle (r 144) |
| `adaptive/ic_launcher_monochrome_432.png` | 432 | solid silhouette, 0 enclosed holes |

All hard alpha (`verify.txt`: PASS). Splash (`assets/ui/android/splash/`) is untouched. Contact sheets: `android_pkg_v2_contact.png` (masks at 48/72/96/192, mono) and `contact_shipped_vs_v2.png`. Old files: `assets/library/legacy/android_icons_2026-10-17/` (see its REPLACED.md).
Check the Android preset still lists the same keys; if you set `compress/mode` etc. on these imports, nothing changes.
