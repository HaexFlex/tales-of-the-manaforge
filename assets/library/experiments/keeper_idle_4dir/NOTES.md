# Keeper idle, 4 directions (S, N, E, W): phase 1 experiment

> **v2 is in `v2/`** (live Keeper hair on all 4 directions, back rune at 70 %), see `v2/NOTES.md`. This page describes v1 (e3dff07); its files are unchanged.

**Status:** experiment only. Not wired into the game; the live Keeper art in `assets/art/keeper/` is untouched.
Branch `experiments/keeper-idle-4dir`, based on origin/main `25047b26ca3e75c9b934af7bce8db1b0699bf83f`.

## What is here
| path | content |
|---|---|
| `idle_south/`, `idle_north/`, `idle_east/`, `idle_west/` | 12 frames each (`keeper_idle_<dir>_0001..0012.png`, 128x128 RGBA), horizontal strip `keeper_idle_<dir>.png`, meta `keeper_idle_<dir>.json`, preview `keeper_idle_<dir>.gif` (x1) and `_x2.gif` |
| `keeper_idle_4dir.gif` / `keeper_idle_4dir_x2.gif` | live `idle_south` (reference) + S, N, E, W idles side by side, in sync (x2 has labels and frame numbers) |
| `contact_sheet.png` / `contact_sheet_x2.png` | rows S, N, E, W; column 1 = live idle_south, then frames 1-12 (x2 labelled, blink frame marked) |
| `candidates_overview_x2.png` | all 5 Imagine turnaround candidates after keying/scaling, next to the live idle |
| `palette.json` / `palette.png` | the single shared 48-colour palette every frame uses |
| `alpha_check.md` / `alpha_check.json` | per-frame check report (`tools/check_frames.py`) |
| `build_info.json` | regions, eye boxes, defringe counts, provenance per direction |
| `source/sheets/` | the 5 raw Grok Imagine sheets + their consistency scores |
| `source/keys_cand_A3/` | the 4 keyed and scaled keys of the chosen sheet, before palette and animation; `source/eyes_A3.json` = hand-set eye boxes |
| `prompts/` | the exact prompts, the attached reference images, and the run brief |
| `tools/` | `ingest_turnaround.py` (key/split/scale/score), `build_idles.py` (palette + derivation + previews), `check_frames.py`, `ingest_all.sh`, `cmp_view.py`. Paths inside point at the box workspace `/workspace/keeper_idle`. |

## Clip spec (all 4 directions)
- **Frames and timing:** 12 frames x 150 ms = 1.8 s seamless loop (`hold_ms` 150).
  - Why: a calm standing breath is roughly 1.5-2.5 s, so 1.8 s reads as relaxed breathing rather than panting.
  - At 150 ms per step the 1 px moves read as soft drift, not jitter. The live walk's 9 x 100 ms (0.9 s) felt fidgety for an idle.
  - 12 frames (>= 9) lets every motion channel ease in and out one pixel at a time.
- **Canvas:** 128x128, anchor `feet_center` (64,128), `sprite.offset (-64,-128)`, filter nearest. Same as the live clips, so it is a drop-in.
- **Placement:** the sole sits on row 123 exactly like the live walk/idle frames. Feet are centred at x 63.0-63.5 (live 63.5).
- **Visible height:** 121-123 px (live 122).
- **Scale:** ONE shared scale for all 4 views (the S view is fitted to 122 px; N/E/W get the same factor), so the views are the same size by construction.

## Method
1. **Turnaround generation:** one Grok Imagine image per run, with all 4 views on one sheet.
   - Chat: "Tales of Manaforge Pixel Art", run via a computerUse subagent.
   - Attached refs: `prompts/attach/ref_keeper_front_back_pair_magenta.png` (live front + back on magenta, same baseline), plus `ref_keeper_front_x3_magenta.png` and `ref_keeper_back_x3_magenta.png`.
   - Prompts: `prompts/turnaround_A.prompt.txt` (A1-A3) and `prompts/turnaround_B.prompt.txt` (B1, B2). Both are quoted at the end.
2. **Ingest** (`tools/ingest_turnaround.py`):
   - Key: soft key on the sampled corner colour (flat magenta), then magenta despill.
   - Split: the 4 largest blobs, left to right = S, N, E, W.
   - Scale: one shared factor. Downscale is premultiplied LANCZOS to 2x, then nearest x0.5, with hard alpha (>= 128).
   - Place: sole on row 123, feet centre at x 64.
   - Score: colour overlap between views, S vs live idle, height spread, facing heuristics.
3. **Candidate choice:** made by eye at x1/x3 (`candidates_overview_x2.png`), not by scores alone. See below.
4. **Defringe:** the key left a dark *purple* outline on 82-150 edge pixels per view, because the JPEG-ish edges were mixed with magenta.
   - Every pixel with a magenta/purple hue (280-340 deg, saturation > 0.15) was recoloured with the median hue of its non-tinted neighbours, keeping its brightness.
   - The design has no purple or pink, so this only touches contamination.
5. **One shared palette, 48 colours** (`palette.json`):
   - Built from all 4 keys at once with material-aware k-means in Lab. Groups: outline, green hair/tunic, coat blue, rune cyan, skin, gold trim, brown leather, neutrals.
   - Colours are allocated per group by sqrt(pixel count), minimum 2.
   - The palette is applied to the keys BEFORE deriving, so every frame of every direction uses exactly these 48 colours and nothing can flicker.
   - A first try with plain median cut collapsed the coat highlights into the rune cyan (shoulders turned turquoise), so it was rejected.
6. **Derivation** (`tools/build_idles.py`): every frame is the same single key per direction, moved by whole pixels. No redraw, no resampling.
   - `UPPER` (chest, shoulders, arms, from the 34 % to the 58 % line) rises 1 px for 6 frames. The waist row is repeated so there is no gap.
   - `HEAD` (top 34 %) rises 1 px, one frame later than the chest.
   - `HAIR`: the top ~8 % (spike tips) sways -1/0/+1 px.
   - `HEM`: the bottom 4 rows of the coat (blue/trim/outline pixels only) sway -1/0/+1 px, one frame after the hair.
   - **Blink** on frame 10 (S, E, W). Eye boxes were set by hand (`source/eyes_A3.json`): the eye is filled with the skin colour sampled just below it, plus a dark lid line. N has no face, so no blink.
   - Legs and boots never move, so the feet stay locked on the anchor.
   - The offsets were picked by a small search. All 12 frames are distinct poses (12/12 unique per direction), and exactly ONE channel changes by 1 px between any two consecutive frames, including 12 -> 1. That is why the loop is seamless.

     | frame | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 | 12 |
     |---|---|---|---|---|---|---|---|---|---|---|---|---|
     | upper dy | 0 | 0 | -1 | -1 | -1 | -1 | -1 | -1 | 0 | 0 | 0 | 0 |
     | head dy | 0 | 0 | 0 | -1 | -1 | -1 | -1 | -1 | -1 | 0 | 0 | 0 |
     | hair dx | 1 | 1 | 1 | 1 | 0 | 0 | -1 | -1 | -1 | -1 | 0 | 0 |
     | hem dx | 0 | 1 | 1 | 1 | 1 | 0 | 0 | -1 | -1 | -1 | -1 | 0 |
     | blink (S/E/W) | | | | | | | | | | x | | |

7. **E / W:**
   - The chosen sheet has a correct right-facing (E) and left-facing (W) profile.
   - Side by side, the generated W has a visibly narrower coat and a different collar/back flare than E (silhouette IoU 0.94). Turning E <-> W in game would make the Keeper change shape.
   - The Keeper's profile has no meaningful left/right asymmetry: the belt, buckle and shoulder cape are symmetric, and the chest strap is hidden in profile. So **W = the derived E frames mirrored horizontally**, giving a pixel-identical silhouette and timing.
   - The generated W is kept in `source/keys_cand_A3/key_W.png` in case a non-mirrored W is wanted later.
   - Light comes from the top-right on W as a result. This is invisible at x1.
8. **Alpha / fringe check** (`tools/check_frames.py`, extended from the harvest v2 checker). For every frame it checks:
   - RGBA at 128x128, with the border fully transparent.
   - Alpha-0 pixels have RGB 0, semi-transparent pixels are counted, and none may sit off the edge.
   - No magenta on the edge (or anywhere), no purple-tint on the edge (new check), no light fringe.
   - Every colour is in the palette.
   - Sole row 123, feet centre within 2 px of 63.5, height 116-126.

## Candidates (all 5 generations; see `candidates_overview_x2.png`)
| cand | file | prompt | verdict |
|---|---|---|---|
| A1 | 2VGlI.png | A | Side views duplicated (both profiles face the same way). Rejected. |
| A2 | WtPIU.png | A | Correct row and consistent. Slightly softer/blurrier at 1168x784; small rune; Imagine drew W as an almost exact mirror of E. Runner-up. |
| **A3** | **FH8sM.png** | **A** | **Chosen.** Correct row, and 1728x1152, the highest source resolution (756 px tall figures → crisper detail after the 6.2x downscale). Hair, coat, trim and boots match closely across all 4 views (same spike pattern, same coat length, hems on the same line). Best S-vs-live colour match (0.55 vs 0.43-0.51). Clear cyan back rune like the live back reference. |
| B1 | JF40L.png | B | Correct and consistent; spikier hair (closer to live), but a V-neck tunic that is not in the live design, and E/W heights 120 vs S 122. Close second. |
| B2 | 6YptM.png | B | Side views duplicated. Rejected. |

Scores (colour overlap between views, mean / S vs live idle / height spread px): A1 0.75/0.43/1, A2 0.76/0.49/1, A3 0.75/0.55/1, B1 0.78/0.51/2, B2 0.79/0.47/1. The scores are all close, so the choice came from looking at the images.

## Palette (48 colours, from the 4 keys of cand A3)
`#023075 #035c8b #042762 #04427d #050d24 #051635 #051b48 #060b19 #069abf #073e8d #0a4c16 #0c2209 #0c4fa9 #0e3914 #0f0904 #10661b #1a65bc #1b821d #1c0e07 #271308 #27dfea #341a0c #368add #3a4e6d #411e0c #413d3f #41931b #4d3422 #51260e #5bad1b #65371d #753818 #7a695e #7cc21f #846041 #904b1e #90a05d #a9dc3a #b06f3c #b56020 #b6f9f6 #b9875b #d68c4f #db832f #ee9e4c #f6b27a #f6fbf8 #f9c38d`

## Alpha / frame check results
**48/48 frames PASS** (12 per direction; full per-frame table in `alpha_check.md`).

| clip | pass | semi px | alpha-0 with RGB | magenta (edge/any) | purple tint edge | light fringe | non-palette | sole row | feet x | height |
|---|---|---|---|---|---|---|---|---|---|---|
| idle_south | 12/12 | 0 | 0 | 0/0 | 0 | 0 | 0 | 123 | 63.0 | 122-123 |
| idle_north | 12/12 | 0 | 0 | 0/0 | 0 | 0 | 0 | 123 | 63.5 | 121-122 |
| idle_east | 12/12 | 0 | 0 | 0/0 | 0 | 0 | 0 | 123 | 63.5 | 121-122 |
| idle_west | 12/12 | 0 | 0 | 0/0 | 0 | 0 | 0 | 123 | 63.5 | 121-122 |

- Alpha is hard 0/255: real transparency, no baked background, no semi-transparent halo.
- Note: the live frames have soft semi-transparent dark edges (~230-270 px). These new frames are crisper at the edge as a result.

## Self-review (x1 and x2, against the live idle_south)
- **Consistency between the 4 directions: good.** This is the main improvement over v1/v2.
  - Same height, scale, palette and outline weight. The coat hem and the boot tops sit on the same rows in S, N, E and W.
  - The hair mass and spike style read as the same head from every side.
  - E and W are identical by construction.
- **Versus the live Keeper, this is a reimagined front, not the same drawing.**
  - The new Keeper is slimmer: the coat flares less (45 px wide at the hem vs 51 px live), the head and hair are narrower (37 px vs 42 px), and the legs are a bit longer.
  - The shading is brighter and a little less contrasty than the live painting.
  - Same character, colours and style, but next to the live idle_south it is visibly a different drawing (younger/leaner proportions).
  - If these idles are adopted, `walk_south` etc. must come from this design too (phase 2). Mixing them with the live walk would pop when he starts walking.
- **Animation:** subtle and calm at x1. At x2 you can see the 1 px chest/head rise, the hair-tip drift and the hem drift. No seams at the waist/neck stretch rows, no tearing at the sway rows. The blink reads at x2; at x1 it is a quick flicker of the eyes, which is intended.

**Per-direction verdict:**
- **S:** good. Clean, on-style, consistent with N/E/W; the blink reads. Leaner than the live Keeper (see above). Breathing is very subtle, which is arguably right for an idle.
- **N:** good. Clean, with the strongest silhouette match to S. The cyan rune is bold and bright (as in the live back ref); it could be toned down if it competes with VFX. No blink (no face), so only breath and sway; the motion is the least visible of the four.
- **E:** good. Clean profile; the coat flare and boots read well; the blink works.
- **W:** good. A mirror of E, so it is exactly as good as E and perfectly consistent with it. The trade-off is that the light direction flips (not noticeable at game scale).
- **Weak points:**
  - The motion is pixel-shift only. The arms do not swing and the coat does not change shape, beyond the 1 px hem drift.
  - The new design differs from the live south walk.

## Phase 2 plan (walk, not built yet)
Derive the 4-direction walk from these same 4 keys (same palette, same scale, same anchor), so idle and walk share one model:
1. **Legs per direction:** cut each key at the hip line into upper body + coat / legs + boots.
   - S/N: redraw the two legs as a 6-8 phase cycle (contact, down, pass, up), moving each boot ±2-4 px vertically/horizontally.
   - E/W: a profile stride with front and back legs swapping. The legs are built from the key's own boot and trouser pixels, cloned and offset, with the occluded leg darkened from the palette.
2. **Body:** upper body bob 1-2 px (down on contact, up on passing), with a small opposite arm swing for E/W. For S/N, arms shift 1 px vertically.
3. **Coat:** the hem lags the bob by one frame and the coat flaps open 1-2 px on the side of the moving leg.
4. **Timing:** 8 frames x 100 ms (0.8 s step cycle, close to the live 9 x 100 ms). Frame 1 = contact pose, and the idle key works as the in-between "stand" pose for start/stop.
5. **Optional Imagine pass:** generate a single 8-pose E walk sheet from the A3 E key as reference. Keep it only if it passes the same consistency check (palette remap + height/anchor + side-by-side review); otherwise use the hand-rigged legs.
6. **Same tooling:** shared palette remap, `check_frames.py`, combined GIF next to these idles.

## Prompts used
**A** (A1, A2, A3), from `prompts/turnaround_A.prompt.txt`:
> Character turnaround sheet of the SAME character, "the Keeper", for a 2D top-down pixel-art game (Tales of the Manaforge). Exactly 4 full-body views in ONE horizontal row, left to right: FRONT (facing the viewer), BACK (facing away), facing RIGHT (side profile), facing LEFT (side profile). All 4 views: identical character, identical height and scale, feet standing on the same invisible baseline, evenly spaced with clear gaps, nothing overlapping, nothing cropped. Calm standing idle pose, arms relaxed at the sides, feet slightly apart, no weapon, no props. Design (match the attached reference exactly): young hero with bright green spiky hair, green eyes, long deep-blue coat to below the knees with orange-gold trim and a short shoulder cape, green tunic with a brown belt, brown trousers, brown leather boots. On the BACK view the coat shows the glowing cyan rune diamond like the attached back reference. Style: soft painted pixel art like the attached sprites, about 1 game pixel = 4-5 image pixels, soft dark outline, gentle top-left lighting, same lighting and same palette on all 4 views. Front view should look like the attached front sprite. Background: perfectly flat solid magenta #FF00FF everywhere, no gradient, no floor, no shadow, no text, no labels, no frame lines. Do not use any pink or magenta on the character.

**B** (B1, B2), from `prompts/turnaround_B.prompt.txt`:
> Pixel-art sprite turnaround of the attached character (the Keeper), 4 views side by side in a single row on a flat solid magenta #FF00FF background: front, back, right side, left side. Same character, same size, same proportions, same colours in every view; full body, standing still with arms down (idle), feet on one shared ground line, wide even gaps between views. Keep his look from the attached front sprite: spiky bright-green hair, long blue coat with gold trim and shoulder cape, green tunic, brown belt and trousers, brown boots; back view shows the cyan rune on the coat like the attached back sprite. Soft painterly pixel art, soft dark outlines, top-left light. No pink or magenta on the character, no shadow, no ground, no text.

Imagine-generated idle frames were not attempted. Deriving from the single key guarantees identical pixels between frames; independent Imagine frames are what broke v1.
