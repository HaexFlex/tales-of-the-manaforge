# Legacy move: hub v3 (2026-09-30)

Moved after Code's hub v3 swap landed (Pass H, `0f821e6`). Files keep their subpath under `assets/art/`, mirrored under this folder.
The rule: move only files with **zero live references**. The search covered scripts, scenes, `.tres`, data and meta JSON (including
`assets/art/MANIFEST.json`), `verify_headless.gd`, `scene_sanity.gd`, `polish_smoke.gd`, `playtest_ship.gd` and the tools. `docs/`, `*.md` and
`assets/library/` were excluded. A reference inside the never-run bake path, or inside a still-referenced meta, counts as a reference.

## Moved

| old path | new path | reason |
|---|---|---|
| `assets/art/manatree/manatree_sapling.png` | `assets/art/manatree/native/manatree_sapling.png` | Old v0.1.8-A2 fallback still. `manatree.gd` `STAGE_TEXTURES` and VERIFY 108-112 now use the native still (Pass H, 0f821e6). No live reference left. |
| `assets/art/manatree/manatree_young.png` | `assets/art/manatree/native/manatree_young.png` | Old v0.1.8-A2 fallback still. `manatree.gd` `STAGE_TEXTURES` and VERIFY 108-112 now use the native still (Pass H, 0f821e6). No live reference left. |
| `assets/art/manatree/manatree_mature.png` | `assets/art/manatree/native/manatree_mature.png` | Old v0.1.8-A2 fallback still. `manatree.gd` `STAGE_TEXTURES` and VERIFY 108-112 now use the native still (Pass H, 0f821e6). No live reference left. |
| `assets/art/manatree/manatree_elder.png` | `assets/art/manatree/native/manatree_elder.png` | Old v0.1.8-A2 fallback still. `manatree.gd` `STAGE_TEXTURES` and VERIFY 108-112 now use the native still (Pass H, 0f821e6). No live reference left. |
| `assets/art/manatree/manatree_ancient.png` | `assets/art/manatree/native/manatree_ancient.png` | Old v0.1.8-A2 fallback still. `manatree.gd` `STAGE_TEXTURES` and VERIFY 108-112 now use the native still (Pass H, 0f821e6). No live reference left. |

Hits that don't count as references to these files: `native/manatree_<stage>.png` paths (`manatree.gd` 31-35, `verify_headless.gd` 108-112,
`native/manatree_meta.json` `still_file`), and `scripts/capture_art_ship.gd` 64/68/120 `_shot("manatree_<stage>.png")`, which are screenshot
output filenames.

## Swap back

1. `git mv assets/library/legacy/hub_v3_2026-09-30/manatree/manatree_<stage>.png assets/art/manatree/manatree_<stage>.png` for each stage.
2. Point `scripts/manatree.gd` `STAGE_TEXTURES` (lines 30-36) back to `res://assets/art/manatree/manatree_<stage>.png`, along with
   `META_PATH` (line 29) -> `res://assets/art/manatree/manatree_meta.json`. The old meta and strips were never moved, see below.
   Also point `verify_headless.gd` 108-114 (plus the version and ancient-frame checks right after) back at the old files.
3. Run the Godot import (`godot --headless --path . --import`), then VERIFY and SANITY.
Or simply `git revert` the legacy-move commit.

## Kept: replaced or unused, but still referenced

These are no longer drawn in the clearing. Pass H retextured every baked node to `assets/art/hub/**`, and the Manatree and berry now use the
native files. They stay because something live-ish still names them. Once Code repoints or drops the references below, they can move in a
follow-up (`assets/library/legacy/hub_v3_2026-09-30/<same subpath>`).

Root references to repoint or remove:
- `assets/art/trees/trees_meta.json`: `scripts/main.gd:17` (`TREES_META_PATH`, loaded at `:427` in the `MANAFORGE_BAKE` path;
  file paths are built at `:433`), `assets/art/MANIFEST.json:69`, `tools/slice_haex_inbox.py:266,384`.
  The meta lists every old tree file, including the unused ones (`tree_oak_a/b`, `tree_autumn_a`, `tree_pine_a`, `tree_forest_imagine`, `bush_a`, `stump_a`),
  and also `tree_mana_*`, which is live and stays either way.
- `assets/art/bushes/bushes_meta.json`: `scripts/main.gd:18` (`BUSHES_META_PATH`, loaded at `:428`, paths built at `:441-442`),
  `assets/art/MANIFEST.json:81`, `tools/slice_haex_inbox.py:306,391`. It lists all 113 old bush files (big, small, native).
- `assets/art/decor/decor_meta.json`: `scripts/main.gd:44` (`DECOR_META_PATH`, loaded at `:741` in `_spawn_ground_decor`, paths built at `:754`),
  `assets/art/MANIFEST.json:28`. It lists `grass_01-16`, `misc_01-16` and `stone_01-03`.
- `assets/art/manatree/manatree_meta.json` (v0.1.8-A2): `scripts/pass_f_playthrough.gd:336` (reads size, door and display_scale for the exclusion;
  the native meta gives the same display footprint) and `assets/art/MANIFEST.json:18` (plus `:20` `"anim": "manatree/anim/"`). The old meta's
  `file` entries keep the five old strips.
- `assets/art/props/berry_harvest_node.png` / `harvest_berry_spent.png`: `assets/art/props/props_meta.json:10,38,39` and
  `assets/art/props/harvest_nodes_meta.json:28,29`. These name the files relative to `props/`; no script reads either meta.

Not counted as references: `verify_headless.gd:2048` and `scene_sanity.gd:223-224` (these `ends_with(basename)` checks now match the native
files), `verify_headless.gd:115` (assert label), `native/manatree_meta.json:140` (descriptive `replaces` note), `tiles/tiles_meta.json`
(`tiles/grass_0N.png` is a different file), and comments in `manatree.gd`.

Every kept file with the exact reference lines:

```
assets/art/bushes/bush_big_01.png <- assets/art/bushes/bushes_meta.json:13,14,1077
assets/art/bushes/bush_big_02.png <- assets/art/bushes/bushes_meta.json:22,23,1078
assets/art/bushes/bush_big_03.png <- assets/art/bushes/bushes_meta.json:31,32,1079
assets/art/bushes/bush_big_04.png <- assets/art/bushes/bushes_meta.json:40,41,1080
assets/art/bushes/bush_big_05.png <- assets/art/bushes/bushes_meta.json:49,50,1081
assets/art/bushes/bush_big_06.png <- assets/art/bushes/bushes_meta.json:58,59,1082
assets/art/bushes/bush_big_07.png <- assets/art/bushes/bushes_meta.json:67,68,1083
assets/art/bushes/bush_big_08.png <- assets/art/bushes/bushes_meta.json:76,77,1084
assets/art/bushes/bush_big_09.png <- assets/art/bushes/bushes_meta.json:85,86,1085
assets/art/bushes/bush_big_10.png <- assets/art/bushes/bushes_meta.json:94,95,1086
assets/art/bushes/bush_big_11.png <- assets/art/bushes/bushes_meta.json:103,104,1087
assets/art/bushes/bush_big_12.png <- assets/art/bushes/bushes_meta.json:112,113,1088
assets/art/bushes/bush_small_01.png <- assets/art/bushes/bushes_meta.json:121,122,1089
assets/art/bushes/bush_small_02.png <- assets/art/bushes/bushes_meta.json:130,131,1090
assets/art/bushes/bush_small_03.png <- assets/art/bushes/bushes_meta.json:139,140,1091
assets/art/bushes/bush_small_04.png <- assets/art/bushes/bushes_meta.json:148,149,1092
assets/art/bushes/bush_small_05.png <- assets/art/bushes/bushes_meta.json:157,158,1093
assets/art/bushes/bush_small_06.png <- assets/art/bushes/bushes_meta.json:166,167,1094
assets/art/bushes/bush_small_07.png <- assets/art/bushes/bushes_meta.json:175,176,1159
assets/art/bushes/bush_small_08.png <- assets/art/bushes/bushes_meta.json:184,185,1160
assets/art/bushes/bush_small_09.png <- assets/art/bushes/bushes_meta.json:193,194,1095
assets/art/bushes/bush_small_10.png <- assets/art/bushes/bushes_meta.json:202,203,1096
assets/art/bushes/bush_small_11.png <- assets/art/bushes/bushes_meta.json:211,212,1097
assets/art/bushes/bush_small_12.png <- assets/art/bushes/bushes_meta.json:220,221,1098
assets/art/bushes/bush_small_13.png <- assets/art/bushes/bushes_meta.json:229,230,1099
assets/art/bushes/bush_small_14.png <- assets/art/bushes/bushes_meta.json:238,239,1100
assets/art/bushes/bush_small_15.png <- assets/art/bushes/bushes_meta.json:247,248,1101
assets/art/bushes/bush_small_16.png <- assets/art/bushes/bushes_meta.json:256,257,1102
assets/art/bushes/bush_small_17.png <- assets/art/bushes/bushes_meta.json:265,266,1103
assets/art/bushes/bush_small_18.png <- assets/art/bushes/bushes_meta.json:274,275,1104
assets/art/bushes/bush_small_19.png <- assets/art/bushes/bushes_meta.json:283,284,1105
assets/art/bushes/bush_small_20.png <- assets/art/bushes/bushes_meta.json:292,293,1106
assets/art/bushes/bush_small_21.png <- assets/art/bushes/bushes_meta.json:301,302,1107
assets/art/bushes/bush_small_22.png <- assets/art/bushes/bushes_meta.json:310,311,1108
assets/art/bushes/bush_small_23.png <- assets/art/bushes/bushes_meta.json:319,320,1109
assets/art/bushes/bush_small_24.png <- assets/art/bushes/bushes_meta.json:328,329,1110
assets/art/bushes/bush_small_25.png <- assets/art/bushes/bushes_meta.json:337,338,1111
assets/art/bushes/bush_small_26.png <- assets/art/bushes/bushes_meta.json:346,347,1112
assets/art/bushes/bush_small_27.png <- assets/art/bushes/bushes_meta.json:355,356,1113
assets/art/bushes/bush_small_28.png <- assets/art/bushes/bushes_meta.json:364,365,1114
assets/art/bushes/bush_small_29.png <- assets/art/bushes/bushes_meta.json:373,374,1115
assets/art/bushes/bush_small_30.png <- assets/art/bushes/bushes_meta.json:382,383,1116
assets/art/bushes/bush_small_31.png <- assets/art/bushes/bushes_meta.json:391,392,1117
assets/art/bushes/bush_small_32.png <- assets/art/bushes/bushes_meta.json:400,401,1118
assets/art/bushes/bush_small_33.png <- assets/art/bushes/bushes_meta.json:409,410,1119
assets/art/bushes/bush_small_34.png <- assets/art/bushes/bushes_meta.json:418,419,1120
assets/art/bushes/bush_small_35.png <- assets/art/bushes/bushes_meta.json:427,428,1121
assets/art/bushes/bush_small_36.png <- assets/art/bushes/bushes_meta.json:436,437,1122
assets/art/bushes/bush_small_37.png <- assets/art/bushes/bushes_meta.json:445,446,1123
assets/art/bushes/bush_small_38.png <- assets/art/bushes/bushes_meta.json:454,455,1124
assets/art/bushes/bush_small_39.png <- assets/art/bushes/bushes_meta.json:463,464,1125
assets/art/bushes/bush_small_40.png <- assets/art/bushes/bushes_meta.json:472,473,1126
assets/art/bushes/bush_small_41.png <- assets/art/bushes/bushes_meta.json:481,482,1127
assets/art/bushes/bush_small_42.png <- assets/art/bushes/bushes_meta.json:490,491,1128
assets/art/bushes/bush_small_43.png <- assets/art/bushes/bushes_meta.json:499,500,1129
assets/art/bushes/bush_small_44.png <- assets/art/bushes/bushes_meta.json:508,509,1130
assets/art/bushes/bush_small_45.png <- assets/art/bushes/bushes_meta.json:517,518,1131
assets/art/bushes/bush_small_46.png <- assets/art/bushes/bushes_meta.json:526,527,1132
assets/art/bushes/bush_small_47.png <- assets/art/bushes/bushes_meta.json:535,536,1133
assets/art/bushes/bush_small_48.png <- assets/art/bushes/bushes_meta.json:544,545,1134
assets/art/bushes/bush_small_49.png <- assets/art/bushes/bushes_meta.json:553,554,1161
assets/art/bushes/bush_small_50.png <- assets/art/bushes/bushes_meta.json:562,563,1162
assets/art/bushes/bush_small_51.png <- assets/art/bushes/bushes_meta.json:571,572,1163
assets/art/bushes/bush_small_52.png <- assets/art/bushes/bushes_meta.json:580,581,1135
assets/art/bushes/bush_small_53.png <- assets/art/bushes/bushes_meta.json:589,590,1136
assets/art/bushes/bush_small_54.png <- assets/art/bushes/bushes_meta.json:598,599,1137
assets/art/bushes/bush_small_55.png <- assets/art/bushes/bushes_meta.json:607,608,1138
assets/art/bushes/bush_small_56.png <- assets/art/bushes/bushes_meta.json:616,617,1139
assets/art/bushes/bush_small_57.png <- assets/art/bushes/bushes_meta.json:625,626,1140
assets/art/bushes/bushes_meta.json <- assets/art/MANIFEST.json:81; scripts/main.gd:18,428; tools/slice_haex_inbox.py:306,391
assets/art/bushes/native/bush_native_01.png <- assets/art/bushes/bushes_meta.json:634,1141
assets/art/bushes/native/bush_native_02.png <- assets/art/bushes/bushes_meta.json:644
assets/art/bushes/native/bush_native_03.png <- assets/art/bushes/bushes_meta.json:654,1142
assets/art/bushes/native/bush_native_04.png <- assets/art/bushes/bushes_meta.json:664
assets/art/bushes/native/bush_native_05.png <- assets/art/bushes/bushes_meta.json:674,1143
assets/art/bushes/native/bush_native_06.png <- assets/art/bushes/bushes_meta.json:684
assets/art/bushes/native/bush_native_07.png <- assets/art/bushes/bushes_meta.json:694
assets/art/bushes/native/bush_native_08.png <- assets/art/bushes/bushes_meta.json:704
assets/art/bushes/native/bush_native_09.png <- assets/art/bushes/bushes_meta.json:714,1144
assets/art/bushes/native/bush_native_10.png <- assets/art/bushes/bushes_meta.json:724
assets/art/bushes/native/bush_native_11.png <- assets/art/bushes/bushes_meta.json:734,1145
assets/art/bushes/native/bush_native_12.png <- assets/art/bushes/bushes_meta.json:744
assets/art/bushes/native/bush_native_13.png <- assets/art/bushes/bushes_meta.json:754
assets/art/bushes/native/bush_native_14.png <- assets/art/bushes/bushes_meta.json:764
assets/art/bushes/native/bush_native_15.png <- assets/art/bushes/bushes_meta.json:774
assets/art/bushes/native/bush_native_16.png <- assets/art/bushes/bushes_meta.json:784
assets/art/bushes/native/bush_native_17.png <- assets/art/bushes/bushes_meta.json:794,1146
assets/art/bushes/native/bush_native_18.png <- assets/art/bushes/bushes_meta.json:804
assets/art/bushes/native/bush_native_19.png <- assets/art/bushes/bushes_meta.json:814,1147
assets/art/bushes/native/bush_native_20.png <- assets/art/bushes/bushes_meta.json:824
assets/art/bushes/native/bush_native_21.png <- assets/art/bushes/bushes_meta.json:834,1148
assets/art/bushes/native/bush_native_22.png <- assets/art/bushes/bushes_meta.json:844
assets/art/bushes/native/bush_native_23.png <- assets/art/bushes/bushes_meta.json:854,1149
assets/art/bushes/native/bush_native_24.png <- assets/art/bushes/bushes_meta.json:864
assets/art/bushes/native/bush_native_25.png <- assets/art/bushes/bushes_meta.json:874
assets/art/bushes/native/bush_native_26.png <- assets/art/bushes/bushes_meta.json:884,1150
assets/art/bushes/native/bush_native_27.png <- assets/art/bushes/bushes_meta.json:894
assets/art/bushes/native/bush_native_28.png <- assets/art/bushes/bushes_meta.json:904
assets/art/bushes/native/bush_native_29.png <- assets/art/bushes/bushes_meta.json:914
assets/art/bushes/native/bush_native_30.png <- assets/art/bushes/bushes_meta.json:924
assets/art/bushes/native/bush_native_31.png <- assets/art/bushes/bushes_meta.json:934,1151
assets/art/bushes/native/bush_native_32.png <- assets/art/bushes/bushes_meta.json:944
assets/art/bushes/native/bush_native_33.png <- assets/art/bushes/bushes_meta.json:954
assets/art/bushes/native/bush_native_34.png <- assets/art/bushes/bushes_meta.json:964,1152
assets/art/bushes/native/bush_native_35.png <- assets/art/bushes/bushes_meta.json:974
assets/art/bushes/native/bush_native_36.png <- assets/art/bushes/bushes_meta.json:984
assets/art/bushes/native/bush_native_37.png <- assets/art/bushes/bushes_meta.json:994
assets/art/bushes/native/bush_native_38.png <- assets/art/bushes/bushes_meta.json:1004
assets/art/bushes/native/bush_native_39.png <- assets/art/bushes/bushes_meta.json:1014,1153
assets/art/bushes/native/bush_native_40.png <- assets/art/bushes/bushes_meta.json:1024
assets/art/bushes/native/bush_native_41.png <- assets/art/bushes/bushes_meta.json:1034,1154
assets/art/bushes/native/bush_native_42.png <- assets/art/bushes/bushes_meta.json:1044
assets/art/bushes/native/bush_native_43.png <- assets/art/bushes/bushes_meta.json:1054,1155
assets/art/bushes/native/bush_native_44.png <- assets/art/bushes/bushes_meta.json:1064,1156
assets/art/decor/decor_meta.json <- assets/art/MANIFEST.json:28; scripts/main.gd:44
assets/art/decor/grass_01.png <- assets/art/decor/decor_meta.json:8,9
assets/art/decor/grass_02.png <- assets/art/decor/decor_meta.json:17,18
assets/art/decor/grass_03.png <- assets/art/decor/decor_meta.json:26,27
assets/art/decor/grass_04.png <- assets/art/decor/decor_meta.json:35,36
assets/art/decor/grass_05.png <- assets/art/decor/decor_meta.json:44,45
assets/art/decor/grass_06.png <- assets/art/decor/decor_meta.json:53,54
assets/art/decor/grass_07.png <- assets/art/decor/decor_meta.json:62,63
assets/art/decor/grass_08.png <- assets/art/decor/decor_meta.json:71,72
assets/art/decor/grass_09.png <- assets/art/decor/decor_meta.json:80,81
assets/art/decor/grass_10.png <- assets/art/decor/decor_meta.json:89,90
assets/art/decor/grass_11.png <- assets/art/decor/decor_meta.json:98,99
assets/art/decor/grass_12.png <- assets/art/decor/decor_meta.json:107,108
assets/art/decor/grass_13.png <- assets/art/decor/decor_meta.json:116,117
assets/art/decor/grass_14.png <- assets/art/decor/decor_meta.json:125,126
assets/art/decor/grass_15.png <- assets/art/decor/decor_meta.json:134,135
assets/art/decor/grass_16.png <- assets/art/decor/decor_meta.json:143,144
assets/art/decor/misc_01.png <- assets/art/decor/decor_meta.json:152,153
assets/art/decor/misc_02.png <- assets/art/decor/decor_meta.json:161,162
assets/art/decor/misc_03.png <- assets/art/decor/decor_meta.json:170,171
assets/art/decor/misc_04.png <- assets/art/decor/decor_meta.json:179,180
assets/art/decor/misc_05.png <- assets/art/decor/decor_meta.json:188,189
assets/art/decor/misc_06.png <- assets/art/decor/decor_meta.json:197,198
assets/art/decor/misc_07.png <- assets/art/decor/decor_meta.json:206,207
assets/art/decor/misc_08.png <- assets/art/decor/decor_meta.json:215,216
assets/art/decor/misc_09.png <- assets/art/decor/decor_meta.json:224,225
assets/art/decor/misc_10.png <- assets/art/decor/decor_meta.json:233,234
assets/art/decor/misc_11.png <- assets/art/decor/decor_meta.json:242,243
assets/art/decor/misc_12.png <- assets/art/decor/decor_meta.json:251,252
assets/art/decor/misc_13.png <- assets/art/decor/decor_meta.json:260,261
assets/art/decor/misc_14.png <- assets/art/decor/decor_meta.json:269,270
assets/art/decor/misc_15.png <- assets/art/decor/decor_meta.json:278,279
assets/art/decor/misc_16.png <- assets/art/decor/decor_meta.json:287,288
assets/art/decor/stone_01.png <- assets/art/decor/decor_meta.json:296,297
assets/art/decor/stone_02.png <- assets/art/decor/decor_meta.json:305,306
assets/art/decor/stone_03.png <- assets/art/decor/decor_meta.json:314,315
assets/art/manatree/anim/manatree_ancient_strip.png <- assets/art/manatree/manatree_meta.json:90; assets/art/MANIFEST.json:20
assets/art/manatree/anim/manatree_elder_strip.png <- assets/art/manatree/manatree_meta.json:70; assets/art/MANIFEST.json:20
assets/art/manatree/anim/manatree_mature_strip.png <- assets/art/manatree/manatree_meta.json:50; assets/art/MANIFEST.json:20
assets/art/manatree/anim/manatree_sapling_strip.png <- assets/art/manatree/manatree_meta.json:10; assets/art/MANIFEST.json:20
assets/art/manatree/anim/manatree_young_strip.png <- assets/art/manatree/manatree_meta.json:30; assets/art/MANIFEST.json:20
assets/art/manatree/manatree_meta.json <- assets/art/MANIFEST.json:18; scripts/pass_f_playthrough.gd:336
assets/art/props/berry_harvest_node.png <- assets/art/props/harvest_nodes_meta.json:28; assets/art/props/props_meta.json:10,38
assets/art/props/harvest_berry_spent.png <- assets/art/props/harvest_nodes_meta.json:29; assets/art/props/props_meta.json:39
assets/art/trees/bush_a.png <- assets/art/trees/trees_meta.json:37,38
assets/art/trees/stump_a.png <- assets/art/trees/trees_meta.json:44,45
assets/art/trees/tree_autumn_a.png <- assets/art/trees/trees_meta.json:23,24
assets/art/trees/tree_big_01.png <- assets/art/trees/trees_meta.json:59,60,204
assets/art/trees/tree_big_02.png <- assets/art/trees/trees_meta.json:68,69,205
assets/art/trees/tree_big_03.png <- assets/art/trees/trees_meta.json:77,78,206
assets/art/trees/tree_big_04.png <- assets/art/trees/trees_meta.json:86,87,207
assets/art/trees/tree_forest_imagine.png <- assets/art/trees/trees_meta.json:51,52
assets/art/trees/tree_native_01.png <- assets/art/trees/trees_meta.json:131,132,212
assets/art/trees/tree_native_02.png <- assets/art/trees/trees_meta.json:141,142,213
assets/art/trees/tree_native_03.png <- assets/art/trees/trees_meta.json:151,152,214
assets/art/trees/tree_native_04.png <- assets/art/trees/trees_meta.json:161,162,215
assets/art/trees/tree_oak_a.png <- assets/art/trees/trees_meta.json:8,9
assets/art/trees/tree_oak_b.png <- assets/art/trees/trees_meta.json:15,16
assets/art/trees/tree_pine_a.png <- assets/art/trees/trees_meta.json:30,31
assets/art/trees/tree_small_01.png <- assets/art/trees/trees_meta.json:95,96,208
assets/art/trees/tree_small_02.png <- assets/art/trees/trees_meta.json:104,105,209
assets/art/trees/tree_small_03.png <- assets/art/trees/trees_meta.json:113,114,210
assets/art/trees/tree_small_04.png <- assets/art/trees/trees_meta.json:122,123,211
assets/art/trees/trees_meta.json <- assets/art/MANIFEST.json:69; scripts/main.gd:17,427; tools/slice_haex_inbox.py:266,384
```
