# Visual inventory — non-sprite redraw list (1280×720 → 960×540)

Read-only inventory of `/workspace/pr33_local` on branch `feat/battle-bundle-2-data`. Excludes character, beast, and gather-node sprites plus animation frame sheets (Keeper, Elaia, Bramble, battle party/beasts/mossmite, wisps, harvest node props, manatree anim frames).

## Category counts

| Category | Count |
|---|---:|
| Full-screen images (title / splash) | 1 |
| Backgrounds & floor plates — Hub / clearing | 28 |
| Backgrounds & floor plates — Forest ring deco (trees, bushes, props) | 202 |
| Backgrounds & floor plates — Forge | 5 |
| Forge station props (anvil, mill, crucible, press, reliquary, bench) | 12 |
| Backgrounds & floor plates — Battle arenas | 8 |
| Backgrounds & floor plates — Echo chamber | 1 |
| UI textures (panels, frames, nine-patches, buttons, minigame kit) | 74 |
| Battle UI (panels, plates, bars, buttons, chrome) | 46 |
| Battle UI — intents / status / keycaps / sigils | 30 |
| HUD elements (buttons, scene toggles, equip slots) | 35 |
| Adventure / expedition board | 47 |
| Portraits & status windows | 4 |
| Icons (resources, rewards, items, HUD/ascension) | 57 |
| Manatree (hub centerpiece stills; anim sheets excluded) | 5 |
| World props (runestones, thorn, echo portal hub) | 18 |
| FX textures | 2 |
| **Total** | **575** |

Pixel sizes from Pillow (PIL). Paths are repo-relative under the project root. Usage lists primary scene/script (+ node or const when known).

## Full-screen images (title / splash)

| File | Size | Used by |
|---|---|---|
| `assets/art/title/titlescreen.png` | 1248×832 | scenes/title_screen.tscn; scenes/title_screen.tscn node `Background` (TextureRect); scripts/title_screen.gd |

## Backgrounds & floor plates — Hub / clearing

| File | Size | Used by |
|---|---|---|
| `assets/art/hub/ground/fern_01.png` | 64×64 | assets/art/hub/hub_deco_meta.json (hub deco family); scenes/main.tscn (ground Multimesh / deco texture_path); scenes/main.tscn node `GroundDeco_0068`; scenes/main.tscn node `GroundDeco_0071` |
| `assets/art/hub/ground/fern_02.png` | 64×64 | assets/art/hub/hub_deco_meta.json (hub deco family); scenes/main.tscn (ground Multimesh / deco texture_path); scenes/main.tscn node `GroundDeco_0063`; scenes/main.tscn node `GroundDeco_0073` |
| `assets/art/hub/ground/fern_03.png` | 64×64 | assets/art/hub/hub_deco_meta.json (hub deco family); scenes/main.tscn (ground Multimesh / deco texture_path); scenes/main.tscn node `GroundDeco_0075`; scenes/main.tscn node `GroundDeco_0077` |
| `assets/art/hub/ground/fern_04.png` | 64×64 | assets/art/hub/hub_deco_meta.json (hub deco family); scenes/main.tscn (ground Multimesh / deco texture_path); scenes/main.tscn node `GroundDeco_0064`; scenes/main.tscn node `GroundDeco_0066` |
| `assets/art/hub/ground/fern_05.png` | 64×64 | assets/art/hub/hub_deco_meta.json (hub deco family); scenes/main.tscn (ground Multimesh / deco texture_path); scenes/main.tscn node `GroundDeco_0070`; scenes/main.tscn node `GroundDeco_0082` |
| `assets/art/hub/ground/fern_06.png` | 64×64 | assets/art/hub/hub_deco_meta.json (hub deco family); scenes/main.tscn (ground Multimesh / deco texture_path); scenes/main.tscn node `GroundDeco_0065`; scenes/main.tscn node `GroundDeco_0069` |
| `assets/art/hub/ground/grass_tuft_01.png` | 64×48 | assets/art/hub/hub_deco_meta.json (hub deco family); scenes/main.tscn (ground Multimesh / deco texture_path); scenes/main.tscn node `Decor_1982`; scenes/main.tscn node `Decor_1991` |
| `assets/art/hub/ground/grass_tuft_02.png` | 64×48 | assets/art/hub/hub_deco_meta.json (hub deco family); scenes/main.tscn (ground Multimesh / deco texture_path); scenes/main.tscn node `Decor_1985`; scenes/main.tscn node `Decor_1992` |
| `assets/art/hub/ground/grass_tuft_03.png` | 64×48 | assets/art/hub/hub_deco_meta.json (hub deco family); scenes/main.tscn (ground Multimesh / deco texture_path); scenes/main.tscn node `Decor_1983`; scenes/main.tscn node `Decor_1986` |
| `assets/art/hub/ground/grass_tuft_04.png` | 64×48 | assets/art/hub/hub_deco_meta.json (hub deco family); scenes/main.tscn (ground Multimesh / deco texture_path); scenes/main.tscn node `Decor_1979`; scenes/main.tscn node `Decor_2009` |
| `assets/art/hub/ground/grass_tuft_05.png` | 64×48 | assets/art/hub/hub_deco_meta.json (hub deco family); scenes/main.tscn (ground Multimesh / deco texture_path); scenes/main.tscn node `Decor_1990`; scenes/main.tscn node `Decor_2003` |
| `assets/art/hub/ground/grass_tuft_06.png` | 64×48 | assets/art/hub/hub_deco_meta.json (hub deco family); scenes/main.tscn (ground Multimesh / deco texture_path); scenes/main.tscn node `Decor_1977`; scenes/main.tscn node `Decor_1981` |
| `assets/art/hub/ground/grass_tuft_07.png` | 64×48 | assets/art/hub/hub_deco_meta.json (hub deco family); scenes/main.tscn (ground Multimesh / deco texture_path); scenes/main.tscn node `Decor_1976`; scenes/main.tscn node `Decor_1980` |
| `assets/art/hub/ground/grass_tuft_08.png` | 64×48 | assets/art/hub/hub_deco_meta.json (hub deco family); scenes/main.tscn (ground Multimesh / deco texture_path); scenes/main.tscn node `Decor_1988`; scenes/main.tscn node `Decor_1999` |
| `assets/art/hub/ground/grass_tuft_09.png` | 64×48 | assets/art/hub/hub_deco_meta.json (hub deco family); scenes/main.tscn (ground Multimesh / deco texture_path); scenes/main.tscn node `Decor_1978`; scenes/main.tscn node `Decor_1989` |
| `assets/art/props/trample/trample_patch_01.png` | 96×64 | scenes/main.tscn |
| `assets/art/props/trample/trample_patch_02.png` | 96×64 | scenes/main.tscn |
| `assets/art/props/trample/trample_patch_03.png` | 96×64 | scenes/main.tscn |
| `assets/art/props/trample/trample_path_strip.png` | 128×48 | scenes/main.tscn |
| `assets/art/tiles/grass_00.png` | 64×64 | _not directly referenced (asset present; may be meta-only or unused)_ |
| `assets/art/tiles/grass_01.png` | 64×64 | _not directly referenced (asset present; may be meta-only or unused)_ |
| `assets/art/tiles/grass_02.png` | 64×64 | _not directly referenced (asset present; may be meta-only or unused)_ |
| `assets/art/tiles/grass_03.png` | 64×64 | _not directly referenced (asset present; may be meta-only or unused)_ |
| `assets/art/tiles/grass_path_cross.png` | 64×64 | _not directly referenced (asset present; may be meta-only or unused)_ |
| `assets/art/tiles/grass_path_h.png` | 64×64 | _not directly referenced (asset present; may be meta-only or unused)_ |
| `assets/art/tiles/grass_path_v.png` | 64×64 | _not directly referenced (asset present; may be meta-only or unused)_ |
| `assets/art/tiles/grass_source_nn.png` | 256×128 | _not directly referenced (asset present; may be meta-only or unused)_ |
| `assets/art/tiles/tileset_grass_64.png` | 256×128 | scenes/main.tscn; scripts/main.gd |

## Backgrounds & floor plates — Forest ring deco (trees, bushes, props)

| File | Size | Used by |
|---|---|---|
| `assets/art/hub/bushes/ring_bush_big_01.png` | 192×144 | assets/art/hub/hub_deco_meta.json (hub deco family); scenes/main.tscn ForestVisual props + assets/art/hub/hub_deco_meta.json; scenes/main.tscn node `ArtBush_0001`; scenes/main.tscn node `ArtBush_0008` |
| `assets/art/hub/bushes/ring_bush_big_02.png` | 192×144 | assets/art/hub/hub_deco_meta.json (hub deco family); scenes/main.tscn ForestVisual props + assets/art/hub/hub_deco_meta.json; scenes/main.tscn node `ArtBush_0012`; scenes/main.tscn node `ArtBush_0018` |
| `assets/art/hub/bushes/ring_bush_big_03.png` | 192×144 | assets/art/hub/hub_deco_meta.json (hub deco family); scenes/main.tscn ForestVisual props + assets/art/hub/hub_deco_meta.json; scenes/main.tscn node `ArtBush_0026`; scenes/main.tscn node `ArtBush_0044` |
| `assets/art/hub/bushes/ring_bush_bloom_01.png` | 112×96 | assets/art/hub/hub_deco_variants_meta.json (hub deco family); scenes/main.tscn ForestVisual props + assets/art/hub/hub_deco_meta.json; scenes/main.tscn node `ArtBush_0005`; scenes/main.tscn node `ArtBush_0019` |
| `assets/art/hub/bushes/ring_bush_bloom_02.png` | 80×64 | assets/art/hub/hub_deco_variants_meta.json (hub deco family); scenes/main.tscn ForestVisual props + assets/art/hub/hub_deco_meta.json; scenes/main.tscn node `ArtBush_0047`; scenes/main.tscn node `ArtBush_0049` |
| `assets/art/hub/bushes/ring_bush_low_01.png` | 136×96 | assets/art/hub/hub_deco_variants_meta.json (hub deco family); scenes/main.tscn ForestVisual props + assets/art/hub/hub_deco_meta.json; scenes/main.tscn node `ArtBush_0002`; scenes/main.tscn node `ArtBush_0023` |
| `assets/art/hub/bushes/ring_bush_low_02.png` | 96×64 | assets/art/hub/hub_deco_variants_meta.json (hub deco family); scenes/main.tscn ForestVisual props + assets/art/hub/hub_deco_meta.json; scenes/main.tscn node `ArtBush_0014`; scenes/main.tscn node `ArtBush_0027` |
| `assets/art/hub/bushes/ring_bush_round_01.png` | 120×120 | assets/art/hub/hub_deco_variants_meta.json (hub deco family); scenes/main.tscn ForestVisual props + assets/art/hub/hub_deco_meta.json; scenes/main.tscn node `ArtBush_0009`; scenes/main.tscn node `ArtBush_0016` |
| `assets/art/hub/bushes/ring_bush_round_02.png` | 88×80 | assets/art/hub/hub_deco_variants_meta.json (hub deco family); scenes/main.tscn ForestVisual props + assets/art/hub/hub_deco_meta.json; scenes/main.tscn node `ArtBush_0011`; scenes/main.tscn node `ArtBush_0069` |
| `assets/art/hub/bushes/ring_bush_small_01.png` | 120×72 | assets/art/hub/hub_deco_meta.json (hub deco family); scenes/main.tscn ForestVisual props + assets/art/hub/hub_deco_meta.json; scenes/main.tscn node `ArtBush_0045`; scenes/main.tscn node `ArtBush_0046` |
| `assets/art/hub/bushes/ring_bush_small_02.png` | 120×72 | assets/art/hub/hub_deco_meta.json (hub deco family); scenes/main.tscn ForestVisual props + assets/art/hub/hub_deco_meta.json; scenes/main.tscn node `ArtBush_0024`; scenes/main.tscn node `ArtBush_0058` |
| `assets/art/hub/bushes/ring_bush_small_03.png` | 120×72 | assets/art/hub/hub_deco_meta.json (hub deco family); scenes/main.tscn ForestVisual props + assets/art/hub/hub_deco_meta.json; scenes/main.tscn node `ArtBush_0015`; scenes/main.tscn node `ArtBush_0059` |
| `assets/art/hub/bushes/ring_bush_spiky_01.png` | 128×112 | assets/art/hub/hub_deco_variants_meta.json (hub deco family); scenes/main.tscn ForestVisual props + assets/art/hub/hub_deco_meta.json; scenes/main.tscn node `ArtBush_0004`; scenes/main.tscn node `ArtBush_0006` |
| `assets/art/hub/bushes/ring_bush_spiky_02.png` | 88×72 | assets/art/hub/hub_deco_variants_meta.json (hub deco family); scenes/main.tscn ForestVisual props + assets/art/hub/hub_deco_meta.json; scenes/main.tscn node `ArtBush_0007`; scenes/main.tscn node `ArtBush_0040` |
| `assets/art/hub/bushes/ring_bush_spiky_03.png` | 120×104 | assets/art/hub/hub_deco_variants_meta.json (hub deco family); scenes/main.tscn ForestVisual props + assets/art/hub/hub_deco_meta.json; scenes/main.tscn node `ArtBush_0033`; scenes/main.tscn node `ArtBush_0034` |
| `assets/art/hub/bushes/ring_bush_spiky_04.png` | 104×80 | assets/art/hub/hub_deco_variants_meta.json (hub deco family); scenes/main.tscn ForestVisual props + assets/art/hub/hub_deco_meta.json; scenes/main.tscn node `ArtBush_0003`; scenes/main.tscn node `ArtBush_0048` |
| `assets/art/hub/bushes/sized/ring_bush_big_01_s080.png` | 154×115 | assets/art/hub/hub_deco_sized_meta.json (hub deco family); scenes/main.tscn ForestVisual props + assets/art/hub/hub_deco_meta.json; scripts/forest_prop.gd; scripts/forest_prop.gd / scenes/main.tscn ForestVisual |
| `assets/art/hub/bushes/sized/ring_bush_big_01_s105.png` | 202×151 | assets/art/hub/hub_deco_sized_meta.json (hub deco family); scenes/main.tscn ForestVisual props + assets/art/hub/hub_deco_meta.json; scenes/main.tscn node `EdgeBush_0013`; scenes/main.tscn node `ThickBush_0010` |
| `assets/art/hub/bushes/sized/ring_bush_big_01_s110.png` | 212×158 | assets/art/hub/hub_deco_sized_meta.json (hub deco family); scenes/main.tscn ForestVisual props + assets/art/hub/hub_deco_meta.json; scenes/main.tscn node `EdgeBush_0024`; scenes/main.tscn node `EdgeBush_0084` |
| `assets/art/hub/bushes/sized/ring_bush_big_01_s115.png` | 220×166 | assets/art/hub/hub_deco_sized_meta.json (hub deco family); scenes/main.tscn ForestVisual props + assets/art/hub/hub_deco_meta.json; scenes/main.tscn node `ThickBush_0001`; scenes/main.tscn node `ThickBush_0030` |
| `assets/art/hub/bushes/sized/ring_bush_big_01_s155.png` | 298×223 | assets/art/hub/hub_deco_sized_meta.json (hub deco family); scenes/main.tscn ForestVisual props + assets/art/hub/hub_deco_meta.json; scripts/forest_prop.gd; scripts/forest_prop.gd / scenes/main.tscn ForestVisual |
| `assets/art/hub/bushes/sized/ring_bush_big_02_s095.png` | 182×137 | assets/art/hub/hub_deco_sized_meta.json (hub deco family); scenes/main.tscn ForestVisual props + assets/art/hub/hub_deco_meta.json; scenes/main.tscn node `EdgeBush_0073`; scripts/forest_prop.gd |
| `assets/art/hub/bushes/sized/ring_bush_big_02_s105.png` | 202×151 | assets/art/hub/hub_deco_sized_meta.json (hub deco family); scenes/main.tscn ForestVisual props + assets/art/hub/hub_deco_meta.json; scenes/main.tscn node `EdgeBush_0124`; scenes/main.tscn node `ThickBush_0100` |
| `assets/art/hub/bushes/sized/ring_bush_big_02_s110.png` | 212×158 | assets/art/hub/hub_deco_sized_meta.json (hub deco family); scenes/main.tscn ForestVisual props + assets/art/hub/hub_deco_meta.json; scenes/main.tscn node `EdgeBush_0065`; scenes/main.tscn node `EdgeBush_0154` |
| `assets/art/hub/bushes/sized/ring_bush_big_02_s115.png` | 220×166 | assets/art/hub/hub_deco_sized_meta.json (hub deco family); scenes/main.tscn ForestVisual props + assets/art/hub/hub_deco_meta.json; scenes/main.tscn node `ThickBush_0014`; scenes/main.tscn node `ThickBush_0194` |
| `assets/art/hub/bushes/sized/ring_bush_big_03_s095.png` | 182×137 | assets/art/hub/hub_deco_sized_meta.json (hub deco family); scenes/main.tscn ForestVisual props + assets/art/hub/hub_deco_meta.json; scenes/main.tscn node `EdgeBush_0100`; scenes/main.tscn node `ThickBush_0057` |
| `assets/art/hub/bushes/sized/ring_bush_big_03_s105.png` | 202×151 | assets/art/hub/hub_deco_sized_meta.json (hub deco family); scenes/main.tscn ForestVisual props + assets/art/hub/hub_deco_meta.json; scenes/main.tscn node `EdgeBush_0023`; scenes/main.tscn node `EdgeBush_0075` |
| `assets/art/hub/bushes/sized/ring_bush_big_03_s110.png` | 212×158 | assets/art/hub/hub_deco_sized_meta.json (hub deco family); scenes/main.tscn ForestVisual props + assets/art/hub/hub_deco_meta.json; scenes/main.tscn node `EdgeBush_0087`; scenes/main.tscn node `EdgeBush_0113` |
| `assets/art/hub/bushes/sized/ring_bush_big_03_s115.png` | 220×166 | assets/art/hub/hub_deco_sized_meta.json (hub deco family); scenes/main.tscn ForestVisual props + assets/art/hub/hub_deco_meta.json; scenes/main.tscn node `EdgeBush_0104`; scenes/main.tscn node `ThickBush_0037` |
| `assets/art/hub/bushes/sized/ring_bush_bloom_01_s095.png` | 104×88 | assets/art/hub/hub_deco_variants_meta.json (hub deco family); scenes/main.tscn ForestVisual props + assets/art/hub/hub_deco_meta.json; scenes/main.tscn node `ThickBush_0184`; scenes/main.tscn node `ThickBush_0305` |
| `assets/art/hub/bushes/sized/ring_bush_bloom_01_s105.png` | 112×96 | assets/art/hub/hub_deco_variants_meta.json (hub deco family); scenes/main.tscn ForestVisual props + assets/art/hub/hub_deco_meta.json; scenes/main.tscn node `ThickBush_0020`; scenes/main.tscn node `ThickBush_0089` |
| `assets/art/hub/bushes/sized/ring_bush_bloom_01_s110.png` | 120×104 | assets/art/hub/hub_deco_variants_meta.json (hub deco family); scenes/main.tscn ForestVisual props + assets/art/hub/hub_deco_meta.json; scenes/main.tscn node `EdgeBush_0064`; scenes/main.tscn node `EdgeBush_0068` |
| `assets/art/hub/bushes/sized/ring_bush_bloom_01_s115.png` | 128×104 | assets/art/hub/hub_deco_variants_meta.json (hub deco family); scenes/main.tscn ForestVisual props + assets/art/hub/hub_deco_meta.json; scenes/main.tscn node `EdgeBush_0153`; scenes/main.tscn node `ThickBush_0151` |
| `assets/art/hub/bushes/sized/ring_bush_bloom_02_s095.png` | 80×64 | assets/art/hub/hub_deco_variants_meta.json (hub deco family); scenes/main.tscn ForestVisual props + assets/art/hub/hub_deco_meta.json; scenes/main.tscn node `EdgeBush_0076`; scenes/main.tscn node `EdgeBush_0092` |
| `assets/art/hub/bushes/sized/ring_bush_bloom_02_s105.png` | 88×64 | assets/art/hub/hub_deco_variants_meta.json (hub deco family); scenes/main.tscn ForestVisual props + assets/art/hub/hub_deco_meta.json; scenes/main.tscn node `EdgeBush_0036`; scenes/main.tscn node `ThickBush_0156` |
| `assets/art/hub/bushes/sized/ring_bush_bloom_02_s110.png` | 88×72 | assets/art/hub/hub_deco_variants_meta.json (hub deco family); scenes/main.tscn ForestVisual props + assets/art/hub/hub_deco_meta.json; scenes/main.tscn node `ThickBush_0022`; scenes/main.tscn node `ThickBush_0087` |
| `assets/art/hub/bushes/sized/ring_bush_bloom_02_s115.png` | 88×72 | assets/art/hub/hub_deco_variants_meta.json (hub deco family); scenes/main.tscn ForestVisual props + assets/art/hub/hub_deco_meta.json; scenes/main.tscn node `ThickBush_0082`; scenes/main.tscn node `ThickBush_0153` |
| `assets/art/hub/bushes/sized/ring_bush_low_01_s095.png` | 136×88 | assets/art/hub/hub_deco_variants_meta.json (hub deco family); scenes/main.tscn ForestVisual props + assets/art/hub/hub_deco_meta.json; scenes/main.tscn node `ThickBush_0134`; scripts/forest_prop.gd |
| `assets/art/hub/bushes/sized/ring_bush_low_01_s105.png` | 144×96 | assets/art/hub/hub_deco_variants_meta.json (hub deco family); scenes/main.tscn ForestVisual props + assets/art/hub/hub_deco_meta.json; scenes/main.tscn node `EdgeBush_0047`; scenes/main.tscn node `EdgeBush_0089` |
| `assets/art/hub/bushes/sized/ring_bush_low_01_s110.png` | 152×104 | assets/art/hub/hub_deco_variants_meta.json (hub deco family); scenes/main.tscn ForestVisual props + assets/art/hub/hub_deco_meta.json; scenes/main.tscn node `EdgeBush_0088`; scenes/main.tscn node `EdgeBush_0122` |
| `assets/art/hub/bushes/sized/ring_bush_low_01_s115.png` | 160×104 | assets/art/hub/hub_deco_variants_meta.json (hub deco family); scenes/main.tscn ForestVisual props + assets/art/hub/hub_deco_meta.json; scenes/main.tscn node `ThickBush_0243`; scripts/forest_prop.gd |
| `assets/art/hub/bushes/sized/ring_bush_low_02_s095.png` | 88×56 | assets/art/hub/hub_deco_variants_meta.json (hub deco family); scenes/main.tscn ForestVisual props + assets/art/hub/hub_deco_meta.json; scenes/main.tscn node `EdgeBush_0086`; scenes/main.tscn node `ThickBush_0050` |
| `assets/art/hub/bushes/sized/ring_bush_low_02_s105.png` | 104×64 | assets/art/hub/hub_deco_variants_meta.json (hub deco family); scenes/main.tscn ForestVisual props + assets/art/hub/hub_deco_meta.json; scenes/main.tscn node `EdgeBush_0021`; scenes/main.tscn node `EdgeBush_0026` |
| `assets/art/hub/bushes/sized/ring_bush_low_02_s110.png` | 112×72 | assets/art/hub/hub_deco_variants_meta.json (hub deco family); scenes/main.tscn ForestVisual props + assets/art/hub/hub_deco_meta.json; scenes/main.tscn node `EdgeBush_0037`; scenes/main.tscn node `ThickBush_0086` |
| `assets/art/hub/bushes/sized/ring_bush_low_02_s115.png` | 112×72 | assets/art/hub/hub_deco_variants_meta.json (hub deco family); scenes/main.tscn ForestVisual props + assets/art/hub/hub_deco_meta.json; scenes/main.tscn node `ThickBush_0052`; scenes/main.tscn node `ThickBush_0230` |
| `assets/art/hub/bushes/sized/ring_bush_round_01_s095.png` | 120×120 | assets/art/hub/hub_deco_variants_meta.json (hub deco family); scenes/main.tscn ForestVisual props + assets/art/hub/hub_deco_meta.json; scenes/main.tscn node `EdgeBush_0155`; scenes/main.tscn node `ThickBush_0007` |
| `assets/art/hub/bushes/sized/ring_bush_round_01_s105.png` | 136×128 | assets/art/hub/hub_deco_variants_meta.json (hub deco family); scenes/main.tscn ForestVisual props + assets/art/hub/hub_deco_meta.json; scenes/main.tscn node `EdgeBush_0139`; scenes/main.tscn node `ThickBush_0065` |
| `assets/art/hub/bushes/sized/ring_bush_round_01_s110.png` | 144×136 | assets/art/hub/hub_deco_variants_meta.json (hub deco family); scenes/main.tscn ForestVisual props + assets/art/hub/hub_deco_meta.json; scripts/forest_prop.gd; scripts/forest_prop.gd / scenes/main.tscn ForestVisual |
| `assets/art/hub/bushes/sized/ring_bush_round_01_s115.png` | 144×144 | assets/art/hub/hub_deco_variants_meta.json (hub deco family); scenes/main.tscn ForestVisual props + assets/art/hub/hub_deco_meta.json; scenes/main.tscn node `ThickBush_0077`; scripts/forest_prop.gd |
| `assets/art/hub/bushes/sized/ring_bush_round_02_s095.png` | 80×72 | assets/art/hub/hub_deco_variants_meta.json (hub deco family); scenes/main.tscn ForestVisual props + assets/art/hub/hub_deco_meta.json; scenes/main.tscn node `EdgeBush_0102`; scenes/main.tscn node `ThickBush_0136` |
| `assets/art/hub/bushes/sized/ring_bush_round_02_s105.png` | 88×80 | assets/art/hub/hub_deco_variants_meta.json (hub deco family); scenes/main.tscn ForestVisual props + assets/art/hub/hub_deco_meta.json; scenes/main.tscn node `EdgeBush_0082`; scenes/main.tscn node `ThickBush_0038` |
| `assets/art/hub/bushes/sized/ring_bush_round_02_s110.png` | 88×80 | assets/art/hub/hub_deco_variants_meta.json (hub deco family); scenes/main.tscn ForestVisual props + assets/art/hub/hub_deco_meta.json; scenes/main.tscn node `EdgeBush_0151`; scenes/main.tscn node `ThickBush_0044` |
| `assets/art/hub/bushes/sized/ring_bush_round_02_s115.png` | 96×88 | assets/art/hub/hub_deco_variants_meta.json (hub deco family); scenes/main.tscn ForestVisual props + assets/art/hub/hub_deco_meta.json; scenes/main.tscn node `ThickBush_0215`; scripts/forest_prop.gd |
| `assets/art/hub/bushes/sized/ring_bush_small_01_s095.png` | 114×68 | assets/art/hub/hub_deco_sized_meta.json (hub deco family); scenes/main.tscn ForestVisual props + assets/art/hub/hub_deco_meta.json; scenes/main.tscn node `ThickBush_0137`; scenes/main.tscn node `ThickBush_0211` |
| `assets/art/hub/bushes/sized/ring_bush_small_01_s105.png` | 126×76 | assets/art/hub/hub_deco_sized_meta.json (hub deco family); scenes/main.tscn ForestVisual props + assets/art/hub/hub_deco_meta.json; scenes/main.tscn node `EdgeBush_0014`; scenes/main.tscn node `EdgeBush_0046` |
| `assets/art/hub/bushes/sized/ring_bush_small_01_s110.png` | 132×79 | assets/art/hub/hub_deco_sized_meta.json (hub deco family); scenes/main.tscn ForestVisual props + assets/art/hub/hub_deco_meta.json; scenes/main.tscn node `ThickBush_0032`; scenes/main.tscn node `ThickBush_0045` |
| `assets/art/hub/bushes/sized/ring_bush_small_01_s115.png` | 138×83 | assets/art/hub/hub_deco_sized_meta.json (hub deco family); scenes/main.tscn ForestVisual props + assets/art/hub/hub_deco_meta.json; scenes/main.tscn node `EdgeBush_0059`; scenes/main.tscn node `ThickBush_0181` |
| `assets/art/hub/bushes/sized/ring_bush_small_02_s095.png` | 114×68 | assets/art/hub/hub_deco_sized_meta.json (hub deco family); scenes/main.tscn ForestVisual props + assets/art/hub/hub_deco_meta.json; scripts/forest_prop.gd; scripts/forest_prop.gd / scenes/main.tscn ForestVisual |
| `assets/art/hub/bushes/sized/ring_bush_small_02_s105.png` | 126×76 | assets/art/hub/hub_deco_sized_meta.json (hub deco family); scenes/main.tscn ForestVisual props + assets/art/hub/hub_deco_meta.json; scenes/main.tscn node `ThickBush_0009`; scenes/main.tscn node `ThickBush_0097` |
| `assets/art/hub/bushes/sized/ring_bush_small_02_s110.png` | 132×79 | assets/art/hub/hub_deco_sized_meta.json (hub deco family); scenes/main.tscn ForestVisual props + assets/art/hub/hub_deco_meta.json; scenes/main.tscn node `EdgeBush_0058`; scenes/main.tscn node `EdgeBush_0141` |
| `assets/art/hub/bushes/sized/ring_bush_small_03_s095.png` | 114×68 | assets/art/hub/hub_deco_sized_meta.json (hub deco family); scenes/main.tscn ForestVisual props + assets/art/hub/hub_deco_meta.json; scenes/main.tscn node `ThickBush_0063`; scenes/main.tscn node `ThickBush_0283` |
| `assets/art/hub/bushes/sized/ring_bush_small_03_s105.png` | 126×76 | assets/art/hub/hub_deco_sized_meta.json (hub deco family); scenes/main.tscn ForestVisual props + assets/art/hub/hub_deco_meta.json; scenes/main.tscn node `EdgeBush_0003`; scenes/main.tscn node `EdgeBush_0032` |
| `assets/art/hub/bushes/sized/ring_bush_small_03_s110.png` | 132×79 | assets/art/hub/hub_deco_sized_meta.json (hub deco family); scenes/main.tscn ForestVisual props + assets/art/hub/hub_deco_meta.json; scenes/main.tscn node `ThickBush_0161`; scripts/forest_prop.gd |
| `assets/art/hub/bushes/sized/ring_bush_small_03_s115.png` | 138×83 | assets/art/hub/hub_deco_sized_meta.json (hub deco family); scenes/main.tscn ForestVisual props + assets/art/hub/hub_deco_meta.json; scenes/main.tscn node `EdgeBush_0057`; scenes/main.tscn node `ThickBush_0186` |
| `assets/art/hub/bushes/sized/ring_bush_spiky_01_s095.png` | 120×104 | assets/art/hub/hub_deco_variants_meta.json (hub deco family); scenes/main.tscn ForestVisual props + assets/art/hub/hub_deco_meta.json; scenes/main.tscn node `ThickBush_0026`; scripts/forest_prop.gd |
| `assets/art/hub/bushes/sized/ring_bush_spiky_01_s105.png` | 136×112 | assets/art/hub/hub_deco_variants_meta.json (hub deco family); scenes/main.tscn ForestVisual props + assets/art/hub/hub_deco_meta.json; scenes/main.tscn node `ThickBush_0016`; scenes/main.tscn node `ThickBush_0264` |
| `assets/art/hub/bushes/sized/ring_bush_spiky_01_s110.png` | 144×120 | assets/art/hub/hub_deco_variants_meta.json (hub deco family); scenes/main.tscn ForestVisual props + assets/art/hub/hub_deco_meta.json; scenes/main.tscn node `EdgeBush_0044`; scenes/main.tscn node `EdgeBush_0114` |
| `assets/art/hub/bushes/sized/ring_bush_spiky_01_s115.png` | 144×128 | assets/art/hub/hub_deco_variants_meta.json (hub deco family); scenes/main.tscn ForestVisual props + assets/art/hub/hub_deco_meta.json; scenes/main.tscn node `EdgeBush_0063`; scenes/main.tscn node `EdgeBush_0136` |
| `assets/art/hub/bushes/sized/ring_bush_spiky_02_s095.png` | 88×64 | assets/art/hub/hub_deco_variants_meta.json (hub deco family); scenes/main.tscn ForestVisual props + assets/art/hub/hub_deco_meta.json; scenes/main.tscn node `EdgeBush_0019`; scenes/main.tscn node `ThickBush_0092` |
| `assets/art/hub/bushes/sized/ring_bush_spiky_02_s105.png` | 96×72 | assets/art/hub/hub_deco_variants_meta.json (hub deco family); scenes/main.tscn ForestVisual props + assets/art/hub/hub_deco_meta.json; scenes/main.tscn node `ThickBush_0062`; scenes/main.tscn node `ThickBush_0182` |
| `assets/art/hub/bushes/sized/ring_bush_spiky_02_s110.png` | 96×80 | assets/art/hub/hub_deco_variants_meta.json (hub deco family); scenes/main.tscn ForestVisual props + assets/art/hub/hub_deco_meta.json; scenes/main.tscn node `EdgeBush_0108`; scenes/main.tscn node `EdgeBush_0127` |
| `assets/art/hub/bushes/sized/ring_bush_spiky_02_s115.png` | 104×80 | assets/art/hub/hub_deco_variants_meta.json (hub deco family); scenes/main.tscn ForestVisual props + assets/art/hub/hub_deco_meta.json; scenes/main.tscn node `ThickBush_0059`; scripts/forest_prop.gd |
| `assets/art/hub/bushes/sized/ring_bush_spiky_03_s095.png` | 120×104 | assets/art/hub/hub_deco_variants_meta.json (hub deco family); scenes/main.tscn ForestVisual props + assets/art/hub/hub_deco_meta.json; scenes/main.tscn node `ThickBush_0125`; scripts/forest_prop.gd |
| `assets/art/hub/bushes/sized/ring_bush_spiky_03_s105.png` | 128×112 | assets/art/hub/hub_deco_variants_meta.json (hub deco family); scenes/main.tscn ForestVisual props + assets/art/hub/hub_deco_meta.json; scenes/main.tscn node `ThickBush_0138`; scenes/main.tscn node `ThickBush_0275` |
| `assets/art/hub/bushes/sized/ring_bush_spiky_03_s110.png` | 136×120 | assets/art/hub/hub_deco_variants_meta.json (hub deco family); scenes/main.tscn ForestVisual props + assets/art/hub/hub_deco_meta.json; scenes/main.tscn node `ThickBush_0206`; scenes/main.tscn node `ThickBush_0229` |
| `assets/art/hub/bushes/sized/ring_bush_spiky_03_s115.png` | 136×120 | assets/art/hub/hub_deco_variants_meta.json (hub deco family); scenes/main.tscn ForestVisual props + assets/art/hub/hub_deco_meta.json; scenes/main.tscn node `EdgeBush_0101`; scenes/main.tscn node `ThickBush_0143` |
| `assets/art/hub/bushes/sized/ring_bush_spiky_04_s095.png` | 104×72 | assets/art/hub/hub_deco_variants_meta.json (hub deco family); scenes/main.tscn ForestVisual props + assets/art/hub/hub_deco_meta.json; scenes/main.tscn node `EdgeBush_0137`; scripts/forest_prop.gd |
| `assets/art/hub/bushes/sized/ring_bush_spiky_04_s105.png` | 112×80 | assets/art/hub/hub_deco_variants_meta.json (hub deco family); scenes/main.tscn ForestVisual props + assets/art/hub/hub_deco_meta.json; scenes/main.tscn node `EdgeBush_0007`; scenes/main.tscn node `EdgeBush_0105` |
| `assets/art/hub/bushes/sized/ring_bush_spiky_04_s110.png` | 120×88 | assets/art/hub/hub_deco_variants_meta.json (hub deco family); scenes/main.tscn ForestVisual props + assets/art/hub/hub_deco_meta.json; scenes/main.tscn node `ThickBush_0103`; scenes/main.tscn node `ThickBush_0108` |
| `assets/art/hub/bushes/sized/ring_bush_spiky_04_s115.png` | 120×88 | assets/art/hub/hub_deco_variants_meta.json (hub deco family); scenes/main.tscn ForestVisual props + assets/art/hub/hub_deco_meta.json; scenes/main.tscn node `ThickBush_0025`; scenes/main.tscn node `ThickBush_0064` |
| `assets/art/hub/props/flower_01.png` | 48×48 | assets/art/hub/hub_deco_meta.json (hub deco family); scenes/main.tscn ForestVisual + hub_deco_meta.json; scenes/main.tscn node `GroundDeco_0127`; scenes/main.tscn node `GroundDeco_0131` |
| `assets/art/hub/props/flower_02.png` | 48×48 | assets/art/hub/hub_deco_meta.json (hub deco family); scenes/main.tscn ForestVisual + hub_deco_meta.json; scenes/main.tscn node `GroundDeco_0132`; scenes/main.tscn node `GroundDeco_0134` |
| `assets/art/hub/props/flower_03.png` | 48×48 | assets/art/hub/hub_deco_meta.json (hub deco family); scenes/main.tscn ForestVisual + hub_deco_meta.json; scenes/main.tscn node `GroundDeco_0133`; scenes/main.tscn node `GroundDeco_0138` |
| `assets/art/hub/props/flower_04.png` | 48×48 | assets/art/hub/hub_deco_meta.json (hub deco family); scenes/main.tscn ForestVisual + hub_deco_meta.json; scenes/main.tscn node `GroundDeco_0130`; scenes/main.tscn node `GroundDeco_0140` |
| `assets/art/hub/props/flower_05.png` | 48×48 | assets/art/hub/hub_deco_meta.json (hub deco family); scenes/main.tscn ForestVisual + hub_deco_meta.json; scenes/main.tscn node `GroundDeco_0129`; scenes/main.tscn node `GroundDeco_0135` |
| `assets/art/hub/props/flower_06.png` | 48×48 | assets/art/hub/hub_deco_meta.json (hub deco family); scenes/main.tscn ForestVisual + hub_deco_meta.json; scenes/main.tscn node `GroundDeco_0128`; scenes/main.tscn node `GroundDeco_0141` |
| `assets/art/hub/props/mushroom_glow_01.png` | 48×48 | assets/art/hub/hub_deco_meta.json (hub deco family); scenes/main.tscn ForestVisual + hub_deco_meta.json; scenes/main.tscn node `GroundDeco_0001`; scenes/main.tscn node `GroundDeco_0104` |
| `assets/art/hub/props/mushroom_glow_01_glow.png` | 96×96 | scenes/main.tscn ForestVisual + hub_deco_meta.json |
| `assets/art/hub/props/mushroom_glow_02.png` | 48×48 | assets/art/hub/hub_deco_meta.json (hub deco family); scenes/main.tscn ForestVisual + hub_deco_meta.json; scenes/main.tscn node `GroundDeco_0002`; scenes/main.tscn node `GroundDeco_0105` |
| `assets/art/hub/props/mushroom_glow_02_glow.png` | 96×96 | scenes/main.tscn ForestVisual + hub_deco_meta.json |
| `assets/art/hub/props/mushroom_glow_03.png` | 48×48 | assets/art/hub/hub_deco_meta.json (hub deco family); scenes/main.tscn ForestVisual + hub_deco_meta.json; scenes/main.tscn node `GroundDeco_0103`; scenes/main.tscn node `GroundDeco_0106` |
| `assets/art/hub/props/mushroom_glow_03_glow.png` | 96×96 | scenes/main.tscn ForestVisual + hub_deco_meta.json |
| `assets/art/hub/props/mushroom_plain_01.png` | 48×48 | assets/art/hub/hub_deco_meta.json (hub deco family); scenes/main.tscn ForestVisual + hub_deco_meta.json; scenes/main.tscn node `GroundDeco_0097`; scenes/main.tscn node `GroundDeco_0098` |
| `assets/art/hub/props/mushroom_plain_02.png` | 48×48 | assets/art/hub/hub_deco_meta.json (hub deco family); scenes/main.tscn ForestVisual + hub_deco_meta.json; scenes/main.tscn node `GroundDeco_0093`; scenes/main.tscn node `GroundDeco_0094` |
| `assets/art/hub/props/mushroom_plain_03.png` | 48×48 | assets/art/hub/hub_deco_meta.json (hub deco family); scenes/main.tscn ForestVisual + hub_deco_meta.json; scenes/main.tscn node `GroundDeco_0096`; scenes/main.tscn node `GroundDeco_0101` |
| `assets/art/hub/props/rock_mossy_01.png` | 48×40 | assets/art/hub/hub_deco_meta.json (hub deco family); scenes/main.tscn ForestVisual + hub_deco_meta.json; scenes/main.tscn node `GroundDeco_0113`; scenes/main.tscn node `GroundDeco_0119` |
| `assets/art/hub/props/rock_mossy_02.png` | 48×40 | assets/art/hub/hub_deco_meta.json (hub deco family); scenes/main.tscn ForestVisual + hub_deco_meta.json; scenes/main.tscn node `GroundDeco_0109`; scenes/main.tscn node `GroundDeco_0112` |
| `assets/art/hub/props/rock_mossy_03.png` | 48×40 | assets/art/hub/hub_deco_meta.json (hub deco family); scenes/main.tscn ForestVisual + hub_deco_meta.json; scenes/main.tscn node `GroundDeco_0108`; scenes/main.tscn node `GroundDeco_0121` |
| `assets/art/hub/props/rock_mossy_04.png` | 48×40 | assets/art/hub/hub_deco_meta.json (hub deco family); scenes/main.tscn ForestVisual + hub_deco_meta.json; scenes/main.tscn node `GroundDeco_0110`; scenes/main.tscn node `GroundDeco_0120` |
| `assets/art/hub/props/rock_mossy_05.png` | 48×40 | assets/art/hub/hub_deco_meta.json (hub deco family); scenes/main.tscn ForestVisual + hub_deco_meta.json; scenes/main.tscn node `GroundDeco_0111`; scenes/main.tscn node `GroundDeco_0115` |
| `assets/art/hub/props/rock_mossy_06.png` | 48×40 | assets/art/hub/hub_deco_meta.json (hub deco family); scenes/main.tscn ForestVisual + hub_deco_meta.json; scenes/main.tscn node `GroundDeco_0107`; scenes/main.tscn node `GroundDeco_0117` |
| `assets/art/hub/trees/ring_tree_conifer_01.png` | 232×400 | assets/art/hub/hub_deco_variants_meta.json (hub deco family); scenes/main.tscn ForestVisual/ForestSolid + hub_deco_meta.json; scenes/main.tscn node `ArtTree_0032`; scenes/main.tscn node `ArtTree_0051` |
| `assets/art/hub/trees/ring_tree_conifer_02.png` | 224×352 | assets/art/hub/hub_deco_variants_meta.json (hub deco family); scenes/main.tscn ForestVisual/ForestSolid + hub_deco_meta.json; scenes/main.tscn node `ArtTree_0011`; scenes/main.tscn node `ArtTree_0031` |
| `assets/art/hub/trees/ring_tree_large_01.png` | 320×400 | assets/art/hub/hub_deco_meta.json (hub deco family); scenes/main.tscn ForestVisual/ForestSolid + hub_deco_meta.json; scenes/main.tscn node `ArtTree_0023`; scenes/main.tscn node `EdgeTree_0140` |
| `assets/art/hub/trees/ring_tree_large_02.png` | 320×400 | assets/art/hub/hub_deco_meta.json (hub deco family); scenes/main.tscn ForestVisual/ForestSolid + hub_deco_meta.json; scenes/main.tscn node `ArtTree_0018`; scenes/main.tscn node `ArtTree_0033` |
| `assets/art/hub/trees/ring_tree_large_03.png` | 320×400 | assets/art/hub/hub_deco_meta.json (hub deco family); scenes/main.tscn ForestVisual/ForestSolid + hub_deco_meta.json; scenes/main.tscn node `ArtTree_0034`; scenes/main.tscn node `ArtTree_0037` |
| `assets/art/hub/trees/ring_tree_medium_01.png` | 256×288 | assets/art/hub/hub_deco_meta.json (hub deco family); scenes/main.tscn ForestVisual/ForestSolid + hub_deco_meta.json; scenes/main.tscn node `EdgeTree_0003`; scenes/main.tscn node `EdgeTree_0015` |
| `assets/art/hub/trees/ring_tree_medium_02.png` | 256×288 | assets/art/hub/hub_deco_meta.json (hub deco family); scenes/main.tscn ForestVisual/ForestSolid + hub_deco_meta.json; scenes/main.tscn node `ArtTree_0045`; scenes/main.tscn node `EdgeTree_0006` |
| `assets/art/hub/trees/ring_tree_old_01.png` | 344×368 | assets/art/hub/hub_deco_variants_meta.json (hub deco family); scenes/main.tscn ForestVisual/ForestSolid + hub_deco_meta.json; scenes/main.tscn node `ArtTree_0002`; scenes/main.tscn node `ArtTree_0046` |
| `assets/art/hub/trees/ring_tree_old_02.png` | 296×336 | assets/art/hub/hub_deco_variants_meta.json (hub deco family); scenes/main.tscn ForestVisual/ForestSolid + hub_deco_meta.json; scenes/main.tscn node `ArtTree_0001`; scenes/main.tscn node `ArtTree_0017` |
| `assets/art/hub/trees/ring_tree_old_03.png` | 344×344 | assets/art/hub/hub_deco_variants_meta.json (hub deco family); scenes/main.tscn ForestVisual/ForestSolid + hub_deco_meta.json; scenes/main.tscn node `ArtTree_0016`; scenes/main.tscn node `ArtTree_0036` |
| `assets/art/hub/trees/ring_tree_old_04.png` | 272×312 | assets/art/hub/hub_deco_variants_meta.json (hub deco family); scenes/main.tscn ForestVisual/ForestSolid + hub_deco_meta.json; scenes/main.tscn node `ArtTree_0010`; scenes/main.tscn node `EdgeTree_0034` |
| `assets/art/hub/trees/ring_tree_slim_01.png` | 160×320 | assets/art/hub/hub_deco_meta.json (hub deco family); scenes/main.tscn ForestVisual/ForestSolid + hub_deco_meta.json; scenes/main.tscn node `ArtTree_0063`; scenes/main.tscn node `EdgeTree_0012` |
| `assets/art/hub/trees/ring_tree_tall_01.png` | 128×400 | assets/art/hub/hub_deco_variants_meta.json (hub deco family); scenes/main.tscn ForestVisual/ForestSolid + hub_deco_meta.json; scenes/main.tscn node `ArtTree_0030`; scenes/main.tscn node `ArtTree_0053` |
| `assets/art/hub/trees/ring_tree_tall_02.png` | 136×400 | assets/art/hub/hub_deco_variants_meta.json (hub deco family); scenes/main.tscn ForestVisual/ForestSolid + hub_deco_meta.json; scenes/main.tscn node `ArtTree_0003`; scenes/main.tscn node `EdgeTree_0037` |
| `assets/art/hub/trees/ring_tree_wide_01.png` | 368×280 | assets/art/hub/hub_deco_variants_meta.json (hub deco family); scenes/main.tscn ForestVisual/ForestSolid + hub_deco_meta.json; scenes/main.tscn node `EdgeTree_0090`; scenes/main.tscn node `EdgeTree_0095` |
| `assets/art/hub/trees/sized/ring_tree_conifer_01_s095.png` | 224×384 | assets/art/hub/hub_deco_variants_meta.json (hub deco family); scenes/main.tscn ForestVisual/ForestSolid + hub_deco_meta.json; scenes/main.tscn node `EdgeTree_0455`; scripts/forest_prop.gd |
| `assets/art/hub/trees/sized/ring_tree_conifer_01_s105.png` | 248×424 | assets/art/hub/hub_deco_variants_meta.json (hub deco family); scenes/main.tscn ForestVisual/ForestSolid + hub_deco_meta.json; scenes/main.tscn node `ArtTree_0007`; scenes/main.tscn node `ThickTree_0037` |
| `assets/art/hub/trees/sized/ring_tree_conifer_01_s110.png` | 256×440 | assets/art/hub/hub_deco_variants_meta.json (hub deco family); scenes/main.tscn ForestVisual/ForestSolid + hub_deco_meta.json; scenes/main.tscn node `ArtTree_0021`; scenes/main.tscn node `EdgeTree_0113` |
| `assets/art/hub/trees/sized/ring_tree_conifer_01_s115.png` | 264×464 | assets/art/hub/hub_deco_variants_meta.json (hub deco family); scenes/main.tscn ForestVisual/ForestSolid + hub_deco_meta.json; scenes/main.tscn node `ArtTree_0004`; scenes/main.tscn node `EdgeTree_0105` |
| `assets/art/hub/trees/sized/ring_tree_conifer_01_s125.png` | 288×504 | assets/art/hub/hub_deco_variants_meta.json (hub deco family); scenes/main.tscn ForestVisual/ForestSolid + hub_deco_meta.json; scenes/main.tscn node `EdgeTree_0070`; scenes/main.tscn node `EdgeTree_0434` |
| `assets/art/hub/trees/sized/ring_tree_conifer_02_s095.png` | 216×336 | assets/art/hub/hub_deco_variants_meta.json (hub deco family); scenes/main.tscn ForestVisual/ForestSolid + hub_deco_meta.json; scenes/main.tscn node `EdgeTree_0462`; scripts/forest_prop.gd |
| `assets/art/hub/trees/sized/ring_tree_conifer_02_s105.png` | 232×376 | assets/art/hub/hub_deco_variants_meta.json (hub deco family); scenes/main.tscn ForestVisual/ForestSolid + hub_deco_meta.json; scenes/main.tscn node `EdgeTree_0168`; scenes/main.tscn node `EdgeTree_0203` |
| `assets/art/hub/trees/sized/ring_tree_conifer_02_s110.png` | 248×392 | assets/art/hub/hub_deco_variants_meta.json (hub deco family); scenes/main.tscn ForestVisual/ForestSolid + hub_deco_meta.json; scenes/main.tscn node `ArtTree_0005`; scripts/forest_prop.gd |
| `assets/art/hub/trees/sized/ring_tree_conifer_02_s115.png` | 256×408 | assets/art/hub/hub_deco_variants_meta.json (hub deco family); scenes/main.tscn ForestVisual/ForestSolid + hub_deco_meta.json; scenes/main.tscn node `ArtTree_0047`; scenes/main.tscn node `EdgeTree_0424` |
| `assets/art/hub/trees/sized/ring_tree_conifer_02_s125.png` | 280×440 | assets/art/hub/hub_deco_variants_meta.json (hub deco family); scenes/main.tscn ForestVisual/ForestSolid + hub_deco_meta.json; scenes/main.tscn node `ArtTree_0059`; scenes/main.tscn node `EdgeTree_0441` |
| `assets/art/hub/trees/sized/ring_tree_large_01_s095.png` | 304×380 | assets/art/hub/hub_deco_sized_meta.json (hub deco family); scenes/main.tscn ForestVisual/ForestSolid + hub_deco_meta.json; scenes/main.tscn node `EdgeTree_0211`; scenes/main.tscn node `ThickTree_0033` |
| `assets/art/hub/trees/sized/ring_tree_large_01_s105.png` | 336×420 | assets/art/hub/hub_deco_sized_meta.json (hub deco family); scenes/main.tscn ForestVisual/ForestSolid + hub_deco_meta.json; scenes/main.tscn node `ArtTree_0029`; scenes/main.tscn node `ArtTree_0042` |
| `assets/art/hub/trees/sized/ring_tree_large_01_s110.png` | 352×440 | assets/art/hub/hub_deco_sized_meta.json (hub deco family); scenes/main.tscn ForestVisual/ForestSolid + hub_deco_meta.json; scenes/main.tscn node `EdgeTree_0136`; scenes/main.tscn node `EdgeTree_0161` |
| `assets/art/hub/trees/sized/ring_tree_large_01_s115.png` | 368×460 | assets/art/hub/hub_deco_sized_meta.json (hub deco family); scenes/main.tscn ForestVisual/ForestSolid + hub_deco_meta.json; scenes/main.tscn node `ArtTree_0026`; scenes/main.tscn node `ArtTree_0039` |
| `assets/art/hub/trees/sized/ring_tree_large_02_s095.png` | 304×380 | assets/art/hub/hub_deco_sized_meta.json (hub deco family); scenes/main.tscn ForestVisual/ForestSolid + hub_deco_meta.json; scripts/forest_prop.gd; scripts/forest_prop.gd / scenes/main.tscn ForestVisual |
| `assets/art/hub/trees/sized/ring_tree_large_02_s105.png` | 336×420 | assets/art/hub/hub_deco_sized_meta.json (hub deco family); scenes/main.tscn ForestVisual/ForestSolid + hub_deco_meta.json; scenes/main.tscn node `EdgeTree_0060`; scenes/main.tscn node `EdgeTree_0088` |
| `assets/art/hub/trees/sized/ring_tree_large_02_s110.png` | 352×440 | assets/art/hub/hub_deco_sized_meta.json (hub deco family); scenes/main.tscn ForestVisual/ForestSolid + hub_deco_meta.json; scenes/main.tscn node `ArtTree_0054`; scenes/main.tscn node `EdgeTree_0112` |
| `assets/art/hub/trees/sized/ring_tree_large_02_s115.png` | 368×460 | assets/art/hub/hub_deco_sized_meta.json (hub deco family); scenes/main.tscn ForestVisual/ForestSolid + hub_deco_meta.json; scenes/main.tscn node `EdgeTree_0132`; scenes/main.tscn node `EdgeTree_0185` |
| `assets/art/hub/trees/sized/ring_tree_large_02_s120.png` | 384×480 | assets/art/hub/hub_deco_sized_meta.json (hub deco family); scenes/main.tscn ForestVisual/ForestSolid + hub_deco_meta.json; scripts/forest_prop.gd; scripts/forest_prop.gd / scenes/main.tscn ForestVisual |
| `assets/art/hub/trees/sized/ring_tree_large_03_s095.png` | 304×380 | assets/art/hub/hub_deco_sized_meta.json (hub deco family); scenes/main.tscn ForestVisual/ForestSolid + hub_deco_meta.json; scripts/forest_prop.gd; scripts/forest_prop.gd / scenes/main.tscn ForestVisual |
| `assets/art/hub/trees/sized/ring_tree_large_03_s105.png` | 336×420 | assets/art/hub/hub_deco_sized_meta.json (hub deco family); scenes/main.tscn ForestVisual/ForestSolid + hub_deco_meta.json; scenes/main.tscn node `EdgeTree_0084`; scenes/main.tscn node `EdgeTree_0102` |
| `assets/art/hub/trees/sized/ring_tree_large_03_s110.png` | 352×440 | assets/art/hub/hub_deco_sized_meta.json (hub deco family); scenes/main.tscn ForestVisual/ForestSolid + hub_deco_meta.json; scenes/main.tscn node `EdgeTree_0117`; scenes/main.tscn node `EdgeTree_0144` |
| `assets/art/hub/trees/sized/ring_tree_large_03_s115.png` | 368×460 | assets/art/hub/hub_deco_sized_meta.json (hub deco family); scenes/main.tscn ForestVisual/ForestSolid + hub_deco_meta.json; scenes/main.tscn node `ArtTree_0028`; scenes/main.tscn node `ArtTree_0065` |
| `assets/art/hub/trees/sized/ring_tree_large_03_s125.png` | 400×500 | assets/art/hub/hub_deco_sized_meta.json (hub deco family); scenes/main.tscn ForestVisual/ForestSolid + hub_deco_meta.json; scenes/main.tscn node `ArtTree_0024`; scenes/main.tscn node `ArtTree_0057` |
| `assets/art/hub/trees/sized/ring_tree_medium_01_s095.png` | 244×274 | assets/art/hub/hub_deco_sized_meta.json (hub deco family); scenes/main.tscn ForestVisual/ForestSolid + hub_deco_meta.json; scenes/main.tscn node `EdgeTree_0143`; scripts/forest_prop.gd |
| `assets/art/hub/trees/sized/ring_tree_medium_01_s105.png` | 268×302 | assets/art/hub/hub_deco_sized_meta.json (hub deco family); scenes/main.tscn ForestVisual/ForestSolid + hub_deco_meta.json; scenes/main.tscn node `EdgeTree_0065`; scenes/main.tscn node `EdgeTree_0077` |
| `assets/art/hub/trees/sized/ring_tree_medium_01_s110.png` | 282×317 | assets/art/hub/hub_deco_sized_meta.json (hub deco family); scenes/main.tscn ForestVisual/ForestSolid + hub_deco_meta.json; scenes/main.tscn node `ArtTree_0060`; scenes/main.tscn node `EdgeTree_0025` |
| `assets/art/hub/trees/sized/ring_tree_medium_01_s115.png` | 294×331 | assets/art/hub/hub_deco_sized_meta.json (hub deco family); scenes/main.tscn ForestVisual/ForestSolid + hub_deco_meta.json; scenes/main.tscn node `ThickTree_0047`; scripts/forest_prop.gd |
| `assets/art/hub/trees/sized/ring_tree_medium_01_s125.png` | 320×360 | assets/art/hub/hub_deco_sized_meta.json (hub deco family); scenes/main.tscn ForestVisual/ForestSolid + hub_deco_meta.json; scenes/main.tscn node `EdgeTree_0009`; scripts/forest_prop.gd |
| `assets/art/hub/trees/sized/ring_tree_medium_01_s135.png` | 346×389 | assets/art/hub/hub_deco_sized_meta.json (hub deco family); scenes/main.tscn ForestVisual/ForestSolid + hub_deco_meta.json; scripts/forest_prop.gd; scripts/forest_prop.gd / scenes/main.tscn ForestVisual |
| `assets/art/hub/trees/sized/ring_tree_medium_02_s095.png` | 244×274 | assets/art/hub/hub_deco_sized_meta.json (hub deco family); scenes/main.tscn ForestVisual/ForestSolid + hub_deco_meta.json; scenes/main.tscn node `EdgeTree_0030`; scenes/main.tscn node `ThickTree_0095` |
| `assets/art/hub/trees/sized/ring_tree_medium_02_s105.png` | 268×302 | assets/art/hub/hub_deco_sized_meta.json (hub deco family); scenes/main.tscn ForestVisual/ForestSolid + hub_deco_meta.json; scenes/main.tscn node `EdgeTree_0005`; scenes/main.tscn node `EdgeTree_0013` |
| `assets/art/hub/trees/sized/ring_tree_medium_02_s110.png` | 282×317 | assets/art/hub/hub_deco_sized_meta.json (hub deco family); scenes/main.tscn ForestVisual/ForestSolid + hub_deco_meta.json; scenes/main.tscn node `EdgeTree_0020`; scenes/main.tscn node `EdgeTree_0035` |
| `assets/art/hub/trees/sized/ring_tree_medium_02_s115.png` | 294×331 | assets/art/hub/hub_deco_sized_meta.json (hub deco family); scenes/main.tscn ForestVisual/ForestSolid + hub_deco_meta.json; scenes/main.tscn node `EdgeTree_0061`; scenes/main.tscn node `EdgeTree_0082` |
| `assets/art/hub/trees/sized/ring_tree_medium_02_s120.png` | 308×346 | assets/art/hub/hub_deco_sized_meta.json (hub deco family); scenes/main.tscn ForestVisual/ForestSolid + hub_deco_meta.json; scripts/forest_prop.gd; scripts/forest_prop.gd / scenes/main.tscn ForestVisual |
| `assets/art/hub/trees/sized/ring_tree_medium_02_s125.png` | 320×360 | assets/art/hub/hub_deco_sized_meta.json (hub deco family); scenes/main.tscn ForestVisual/ForestSolid + hub_deco_meta.json; scenes/main.tscn node `EdgeTree_0076`; scenes/main.tscn node `EdgeTree_0135` |
| `assets/art/hub/trees/sized/ring_tree_medium_02_s135.png` | 346×389 | assets/art/hub/hub_deco_sized_meta.json (hub deco family); scenes/main.tscn ForestVisual/ForestSolid + hub_deco_meta.json; scenes/main.tscn node `EdgeTree_0063`; scenes/main.tscn node `EdgeTree_0080` |
| `assets/art/hub/trees/sized/ring_tree_old_01_s095.png` | 328×344 | assets/art/hub/hub_deco_variants_meta.json (hub deco family); scenes/main.tscn ForestVisual/ForestSolid + hub_deco_meta.json; scripts/forest_prop.gd; scripts/forest_prop.gd / scenes/main.tscn ForestVisual |
| `assets/art/hub/trees/sized/ring_tree_old_01_s105.png` | 360×384 | assets/art/hub/hub_deco_variants_meta.json (hub deco family); scenes/main.tscn ForestVisual/ForestSolid + hub_deco_meta.json; scenes/main.tscn node `EdgeTree_0120`; scripts/forest_prop.gd |
| `assets/art/hub/trees/sized/ring_tree_old_01_s110.png` | 376×400 | assets/art/hub/hub_deco_variants_meta.json (hub deco family); scenes/main.tscn ForestVisual/ForestSolid + hub_deco_meta.json; scenes/main.tscn node `EdgeTree_0133`; scenes/main.tscn node `EdgeTree_0407` |
| `assets/art/hub/trees/sized/ring_tree_old_01_s115.png` | 400×416 | assets/art/hub/hub_deco_variants_meta.json (hub deco family); scenes/main.tscn ForestVisual/ForestSolid + hub_deco_meta.json; scenes/main.tscn node `ThickTree_0043`; scenes/main.tscn node `ThickTree_0104` |
| `assets/art/hub/trees/sized/ring_tree_old_01_s125.png` | 432×456 | assets/art/hub/hub_deco_variants_meta.json (hub deco family); scenes/main.tscn ForestVisual/ForestSolid + hub_deco_meta.json; scenes/main.tscn node `ArtTree_0008`; scenes/main.tscn node `ArtTree_0012` |
| `assets/art/hub/trees/sized/ring_tree_old_02_s095.png` | 296×320 | assets/art/hub/hub_deco_variants_meta.json (hub deco family); scenes/main.tscn ForestVisual/ForestSolid + hub_deco_meta.json; scenes/main.tscn node `EdgeTree_0448`; scripts/forest_prop.gd |
| `assets/art/hub/trees/sized/ring_tree_old_02_s105.png` | 304×352 | assets/art/hub/hub_deco_variants_meta.json (hub deco family); scenes/main.tscn ForestVisual/ForestSolid + hub_deco_meta.json; scenes/main.tscn node `EdgeTree_0236`; scenes/main.tscn node `EdgeTree_0342` |
| `assets/art/hub/trees/sized/ring_tree_old_02_s110.png` | 344×368 | assets/art/hub/hub_deco_variants_meta.json (hub deco family); scenes/main.tscn ForestVisual/ForestSolid + hub_deco_meta.json; scenes/main.tscn node `ArtTree_0019`; scenes/main.tscn node `ArtTree_0050` |
| `assets/art/hub/trees/sized/ring_tree_old_02_s115.png` | 360×392 | assets/art/hub/hub_deco_variants_meta.json (hub deco family); scenes/main.tscn ForestVisual/ForestSolid + hub_deco_meta.json; scenes/main.tscn node `ArtTree_0035`; scenes/main.tscn node `EdgeTree_0368` |
| `assets/art/hub/trees/sized/ring_tree_old_02_s125.png` | 384×424 | assets/art/hub/hub_deco_variants_meta.json (hub deco family); scenes/main.tscn ForestVisual/ForestSolid + hub_deco_meta.json; scenes/main.tscn node `ArtTree_0025`; scripts/forest_prop.gd |
| `assets/art/hub/trees/sized/ring_tree_old_03_s095.png` | 328×328 | assets/art/hub/hub_deco_variants_meta.json (hub deco family); scenes/main.tscn ForestVisual/ForestSolid + hub_deco_meta.json; scenes/main.tscn node `EdgeTree_0451`; scenes/main.tscn node `ThickTree_0087` |
| `assets/art/hub/trees/sized/ring_tree_old_03_s105.png` | 360×360 | assets/art/hub/hub_deco_variants_meta.json (hub deco family); scenes/main.tscn ForestVisual/ForestSolid + hub_deco_meta.json; scenes/main.tscn node `EdgeTree_0345`; scenes/main.tscn node `EdgeTree_0359` |
| `assets/art/hub/trees/sized/ring_tree_old_03_s110.png` | 376×376 | assets/art/hub/hub_deco_variants_meta.json (hub deco family); scenes/main.tscn ForestVisual/ForestSolid + hub_deco_meta.json; scenes/main.tscn node `EdgeTree_0122`; scenes/main.tscn node `EdgeTree_0205` |
| `assets/art/hub/trees/sized/ring_tree_old_03_s115.png` | 392×392 | assets/art/hub/hub_deco_variants_meta.json (hub deco family); scenes/main.tscn ForestVisual/ForestSolid + hub_deco_meta.json; scenes/main.tscn node `ArtTree_0006`; scenes/main.tscn node `EdgeTree_0169` |
| `assets/art/hub/trees/sized/ring_tree_old_03_s125.png` | 432×432 | assets/art/hub/hub_deco_variants_meta.json (hub deco family); scenes/main.tscn ForestVisual/ForestSolid + hub_deco_meta.json; scenes/main.tscn node `ArtTree_0052`; scripts/forest_prop.gd |
| `assets/art/hub/trees/sized/ring_tree_old_04_s095.png` | 264×296 | assets/art/hub/hub_deco_variants_meta.json (hub deco family); scenes/main.tscn ForestVisual/ForestSolid + hub_deco_meta.json; scenes/main.tscn node `EdgeTree_0054`; scenes/main.tscn node `EdgeTree_0107` |
| `assets/art/hub/trees/sized/ring_tree_old_04_s105.png` | 288×328 | assets/art/hub/hub_deco_variants_meta.json (hub deco family); scenes/main.tscn ForestVisual/ForestSolid + hub_deco_meta.json; scenes/main.tscn node `EdgeTree_0039`; scenes/main.tscn node `EdgeTree_0049` |
| `assets/art/hub/trees/sized/ring_tree_old_04_s110.png` | 304×344 | assets/art/hub/hub_deco_variants_meta.json (hub deco family); scenes/main.tscn ForestVisual/ForestSolid + hub_deco_meta.json; scenes/main.tscn node `ArtTree_0027`; scenes/main.tscn node `EdgeTree_0001` |
| `assets/art/hub/trees/sized/ring_tree_old_04_s115.png` | 312×360 | assets/art/hub/hub_deco_variants_meta.json (hub deco family); scenes/main.tscn ForestVisual/ForestSolid + hub_deco_meta.json; scenes/main.tscn node `ArtTree_0013`; scenes/main.tscn node `EdgeTree_0007` |
| `assets/art/hub/trees/sized/ring_tree_old_04_s125.png` | 344×392 | assets/art/hub/hub_deco_variants_meta.json (hub deco family); scenes/main.tscn ForestVisual/ForestSolid + hub_deco_meta.json; scenes/main.tscn node `EdgeTree_0002`; scenes/main.tscn node `EdgeTree_0017` |
| `assets/art/hub/trees/sized/ring_tree_slim_01_s080.png` | 128×256 | assets/art/hub/hub_deco_sized_meta.json (hub deco family); scenes/main.tscn ForestVisual/ForestSolid + hub_deco_meta.json; scenes/main.tscn node `EdgeTree_0408`; scenes/main.tscn node `EdgeTree_0415` |
| `assets/art/hub/trees/sized/ring_tree_slim_01_s095.png` | 152×304 | assets/art/hub/hub_deco_sized_meta.json (hub deco family); scenes/main.tscn ForestVisual/ForestSolid + hub_deco_meta.json; scripts/forest_prop.gd; scripts/forest_prop.gd / scenes/main.tscn ForestVisual |
| `assets/art/hub/trees/sized/ring_tree_slim_01_s105.png` | 168×336 | assets/art/hub/hub_deco_sized_meta.json (hub deco family); scenes/main.tscn ForestVisual/ForestSolid + hub_deco_meta.json; scenes/main.tscn node `EdgeTree_0018`; scenes/main.tscn node `EdgeTree_0023` |
| `assets/art/hub/trees/sized/ring_tree_slim_01_s110.png` | 176×352 | assets/art/hub/hub_deco_sized_meta.json (hub deco family); scenes/main.tscn ForestVisual/ForestSolid + hub_deco_meta.json; scenes/main.tscn node `EdgeTree_0036`; scenes/main.tscn node `EdgeTree_0040` |
| `assets/art/hub/trees/sized/ring_tree_slim_01_s115.png` | 184×368 | assets/art/hub/hub_deco_sized_meta.json (hub deco family); scenes/main.tscn ForestVisual/ForestSolid + hub_deco_meta.json; scripts/forest_prop.gd; scripts/forest_prop.gd / scenes/main.tscn ForestVisual |
| `assets/art/hub/trees/sized/ring_tree_slim_01_s120.png` | 192×384 | assets/art/hub/hub_deco_sized_meta.json (hub deco family); scenes/main.tscn ForestVisual/ForestSolid + hub_deco_meta.json; scenes/main.tscn node `EdgeTree_0072`; scenes/main.tscn node `ThickTree_0135` |
| `assets/art/hub/trees/sized/ring_tree_slim_01_s125.png` | 200×400 | assets/art/hub/hub_deco_sized_meta.json (hub deco family); scenes/main.tscn ForestVisual/ForestSolid + hub_deco_meta.json; scenes/main.tscn node `EdgeTree_0416`; scenes/main.tscn node `EdgeTree_0417` |
| `assets/art/hub/trees/sized/ring_tree_slim_01_s130.png` | 208×416 | assets/art/hub/hub_deco_sized_meta.json (hub deco family); scenes/main.tscn ForestVisual/ForestSolid + hub_deco_meta.json; scenes/main.tscn node `EdgeTree_0067`; scripts/forest_prop.gd |
| `assets/art/hub/trees/sized/ring_tree_slim_01_s135.png` | 216×432 | assets/art/hub/hub_deco_sized_meta.json (hub deco family); scenes/main.tscn ForestVisual/ForestSolid + hub_deco_meta.json; scenes/main.tscn node `EdgeTree_0068`; scenes/main.tscn node `EdgeTree_0409` |
| `assets/art/hub/trees/sized/ring_tree_slim_01_s140.png` | 224×448 | assets/art/hub/hub_deco_sized_meta.json (hub deco family); scenes/main.tscn ForestVisual/ForestSolid + hub_deco_meta.json; scenes/main.tscn node `EdgeTree_0010`; scripts/forest_prop.gd |
| `assets/art/hub/trees/sized/ring_tree_slim_01_s150.png` | 240×480 | assets/art/hub/hub_deco_sized_meta.json (hub deco family); scenes/main.tscn ForestVisual/ForestSolid + hub_deco_meta.json; scripts/forest_prop.gd; scripts/forest_prop.gd / scenes/main.tscn ForestVisual |
| `assets/art/hub/trees/sized/ring_tree_tall_01_s095.png` | 120×384 | assets/art/hub/hub_deco_variants_meta.json (hub deco family); scenes/main.tscn ForestVisual/ForestSolid + hub_deco_meta.json; scenes/main.tscn node `EdgeTree_0410`; scenes/main.tscn node `EdgeTree_0421` |
| `assets/art/hub/trees/sized/ring_tree_tall_01_s105.png` | 136×424 | assets/art/hub/hub_deco_variants_meta.json (hub deco family); scenes/main.tscn ForestVisual/ForestSolid + hub_deco_meta.json; scenes/main.tscn node `ArtTree_0009`; scenes/main.tscn node `EdgeTree_0050` |
| `assets/art/hub/trees/sized/ring_tree_tall_01_s110.png` | 144×440 | assets/art/hub/hub_deco_variants_meta.json (hub deco family); scenes/main.tscn ForestVisual/ForestSolid + hub_deco_meta.json; scenes/main.tscn node `ArtTree_0038`; scenes/main.tscn node `ArtTree_0048` |
| `assets/art/hub/trees/sized/ring_tree_tall_01_s115.png` | 144×464 | assets/art/hub/hub_deco_variants_meta.json (hub deco family); scenes/main.tscn ForestVisual/ForestSolid + hub_deco_meta.json; scenes/main.tscn node `ArtTree_0020`; scenes/main.tscn node `EdgeTree_0021` |
| `assets/art/hub/trees/sized/ring_tree_tall_01_s125.png` | 160×504 | assets/art/hub/hub_deco_variants_meta.json (hub deco family); scenes/main.tscn ForestVisual/ForestSolid + hub_deco_meta.json; scenes/main.tscn node `ArtTree_0043`; scenes/main.tscn node `EdgeTree_0071` |
| `assets/art/hub/trees/sized/ring_tree_tall_02_s095.png` | 128×384 | assets/art/hub/hub_deco_variants_meta.json (hub deco family); scenes/main.tscn ForestVisual/ForestSolid + hub_deco_meta.json; scenes/main.tscn node `EdgeTree_0008`; scenes/main.tscn node `EdgeTree_0411` |
| `assets/art/hub/trees/sized/ring_tree_tall_02_s105.png` | 144×424 | assets/art/hub/hub_deco_variants_meta.json (hub deco family); scenes/main.tscn ForestVisual/ForestSolid + hub_deco_meta.json; scenes/main.tscn node `EdgeTree_0338`; scenes/main.tscn node `ThickTree_0020` |
| `assets/art/hub/trees/sized/ring_tree_tall_02_s110.png` | 144×440 | assets/art/hub/hub_deco_variants_meta.json (hub deco family); scenes/main.tscn ForestVisual/ForestSolid + hub_deco_meta.json; scenes/main.tscn node `EdgeTree_0019`; scenes/main.tscn node `EdgeTree_0085` |
| `assets/art/hub/trees/sized/ring_tree_tall_02_s115.png` | 152×464 | assets/art/hub/hub_deco_variants_meta.json (hub deco family); scenes/main.tscn ForestVisual/ForestSolid + hub_deco_meta.json; scenes/main.tscn node `EdgeTree_0275`; scenes/main.tscn node `EdgeTree_0352` |
| `assets/art/hub/trees/sized/ring_tree_tall_02_s125.png` | 168×504 | assets/art/hub/hub_deco_variants_meta.json (hub deco family); scenes/main.tscn ForestVisual/ForestSolid + hub_deco_meta.json; scenes/main.tscn node `EdgeTree_0081`; scenes/main.tscn node `EdgeTree_0349` |
| `assets/art/hub/trees/sized/ring_tree_wide_01_s095.png` | 352×264 | assets/art/hub/hub_deco_variants_meta.json (hub deco family); scenes/main.tscn ForestVisual/ForestSolid + hub_deco_meta.json; scenes/main.tscn node `EdgeTree_0233`; scripts/forest_prop.gd |
| `assets/art/hub/trees/sized/ring_tree_wide_01_s105.png` | 384×288 | assets/art/hub/hub_deco_variants_meta.json (hub deco family); scenes/main.tscn ForestVisual/ForestSolid + hub_deco_meta.json; scenes/main.tscn node `EdgeTree_0110`; scenes/main.tscn node `EdgeTree_0141` |
| `assets/art/hub/trees/sized/ring_tree_wide_01_s110.png` | 400×304 | assets/art/hub/hub_deco_variants_meta.json (hub deco family); scenes/main.tscn ForestVisual/ForestSolid + hub_deco_meta.json; scenes/main.tscn node `EdgeTree_0131`; scenes/main.tscn node `EdgeTree_0198` |
| `assets/art/hub/trees/sized/ring_tree_wide_01_s115.png` | 416×320 | assets/art/hub/hub_deco_variants_meta.json (hub deco family); scenes/main.tscn ForestVisual/ForestSolid + hub_deco_meta.json; scenes/main.tscn node `EdgeTree_0186`; scenes/main.tscn node `EdgeTree_0231` |
| `assets/art/hub/trees/sized/ring_tree_wide_01_s125.png` | 456×344 | assets/art/hub/hub_deco_variants_meta.json (hub deco family); scenes/main.tscn ForestVisual/ForestSolid + hub_deco_meta.json; scenes/main.tscn node `EdgeTree_0083`; scenes/main.tscn node `ThickTree_0001` |
| `assets/art/trees/tree_mana_02.png` | 91×112 | _not directly referenced (asset present; may be meta-only or unused)_ |
| `assets/art/trees/tree_mana_03.png` | 92×110 | _not directly referenced (asset present; may be meta-only or unused)_ |
| `assets/art/trees/tree_mana_04.png` | 87×98 | _not directly referenced (asset present; may be meta-only or unused)_ |

## Backgrounds & floor plates — Forge

| File | Size | Used by |
|---|---|---|
| `assets/art/forge/forge_arch_front.png` | 1600×1200 | _not directly referenced (asset present; may be meta-only or unused)_ |
| `assets/art/forge/forge_arch_front_haex.png` | 212×144 | scenes/forge_room.tscn; scenes/forge_room.tscn (arch front overlay) |
| `assets/art/forge/forge_bark_chamber_bg.png` | 1600×1200 | scenes/forge_room.tscn; scenes/forge_room.tscn node plate / FloorPlate; scripts/forge_room.gd |
| `assets/art/forge/forge_floor_mask.png` | 1600×1200 | scenes/forge_room.tscn; scripts/forge_room.gd (`floor_mask` export) |
| `assets/art/forge/forge_room_swirls.png` | 1600×1200 | scenes/forge_room.tscn; scenes/forge_room.tscn node `SwirlOverlay`; scripts/forge_room.gd (`swirl_texture`) |

## Forge station props (anvil, mill, crucible, press, reliquary, bench)

| File | Size | Used by |
|---|---|---|
| `assets/art/forge/bench_busy.png` | 192×192 | scenes/keepers_bench.tscn |
| `assets/art/forge/bench_idle.png` | 192×192 | scenes/keepers_bench.tscn |
| `assets/art/forge/prop_anvil_busy.png` | 192×192 | scenes/forge/anvil.tscn |
| `assets/art/forge/prop_anvil_idle.png` | 192×192 | scenes/forge/anvil.tscn |
| `assets/art/forge/prop_crucible_busy.png` | 192×192 | scenes/forge/crucible.tscn |
| `assets/art/forge/prop_crucible_idle.png` | 192×192 | scenes/forge/crucible.tscn |
| `assets/art/forge/prop_mill_busy.png` | 192×192 | scenes/forge/mill.tscn |
| `assets/art/forge/prop_mill_idle.png` | 192×192 | scenes/forge/mill.tscn |
| `assets/art/forge/prop_press_busy.png` | 192×192 | scenes/forge/press.tscn |
| `assets/art/forge/prop_press_idle.png` | 192×192 | scenes/forge/press.tscn |
| `assets/art/forge/prop_reliquary_busy.png` | 192×192 | scenes/forge/reliquary.tscn |
| `assets/art/forge/prop_reliquary_idle.png` | 192×192 | scenes/forge/reliquary.tscn |

## Backgrounds & floor plates — Battle arenas

| File | Size | Used by |
|---|---|---|
| `assets/art/battle/arena/arena_forest_bg_a.png` | 1600×900 | scenes/battle/battle_scene.tscn; scenes/battle/battle_scene.tscn (arena BG); scripts/battle/battle_view.gd; scripts/battle/battle_view.gd (shadows, slot marks) |
| `assets/art/battle/arena/arena_forest_bg_b.png` | 1600×900 | scenes/battle/battle_scene.tscn; scripts/battle/battle_view.gd (shadows, slot marks) |
| `assets/art/battle/arena/arena_forest_fg.png` | 1600×900 | scenes/battle/battle_scene.tscn; scenes/battle/battle_scene.tscn (arena FG); scripts/battle/battle_view.gd; scripts/battle/battle_view.gd (shadows, slot marks) |
| `assets/art/battle/arena/shadow_l.png` | 96×24 | scenes/battle/battle_scene.tscn; scripts/battle/battle_view.gd (shadows, slot marks) |
| `assets/art/battle/arena/shadow_m.png` | 64×16 | scenes/battle/battle_scene.tscn; scripts/battle/battle_view.gd (shadows, slot marks) |
| `assets/art/battle/arena/shadow_s.png` | 40×10 | scenes/battle/battle_scene.tscn; scripts/battle/battle_view.gd (shadows, slot marks) |
| `assets/art/battle/arena/slot_mark.png` | 56×16 | scenes/battle/battle_scene.tscn; scripts/battle/battle_view.gd (shadows, slot marks) |
| `assets/art/battle/arena/slot_mark_target.png` | 56×16 | scenes/battle/battle_scene.tscn; scripts/battle/battle_view.gd (shadows, slot marks) |

## Backgrounds & floor plates — Echo chamber

| File | Size | Used by |
|---|---|---|
| `assets/art/echo/echo_chamber_bg.png` | 1280×720 | scenes/echo_battle.tscn; scripts/echo_battle_view.gd (`CHAMBER_BG`) |

## UI textures (panels, frames, nine-patches, buttons, minigame kit)

| File | Size | Used by |
|---|---|---|
| `assets/art/ui/badge_station_busy.png` | 32×32 | scenes/forge/anvil.tscn; scenes/forge/crucible.tscn; scenes/forge/mill.tscn; scenes/forge/press.tscn |
| `assets/art/ui/badge_station_paused.png` | 32×32 | scenes/forge/anvil.tscn; scenes/forge/crucible.tscn; scenes/forge/mill.tscn; scenes/forge/press.tscn |
| `assets/art/ui/minigames/kit/bubble_body_9s_hover_24x26.png` | 24×26 | scripts/batch_panel.gd / scenes/ui/batch_panel.tscn (minigame kit); scripts/ui/expedition_shell.gd (`KIT_DIR`) |
| `assets/art/ui/minigames/kit/bubble_body_9s_normal_24x26.png` | 24×26 | scripts/batch_panel.gd / scenes/ui/batch_panel.tscn (minigame kit); scripts/ui/expedition_shell.gd (`KIT_DIR`) |
| `assets/art/ui/minigames/kit/bubble_hand_18x14.png` | 18×14 | scripts/batch_panel.gd / scenes/ui/batch_panel.tscn (minigame kit); scripts/ui/expedition_shell.gd (`KIT_DIR`) |
| `assets/art/ui/minigames/kit/bubble_hover_128x33.png` | 128×33 | scripts/batch_panel.gd / scenes/ui/batch_panel.tscn (minigame kit); scripts/ui/expedition_shell.gd (`KIT_DIR`) |
| `assets/art/ui/minigames/kit/bubble_normal_128x33.png` | 128×33 | scripts/batch_panel.gd / scenes/ui/batch_panel.tscn (minigame kit); scripts/ui/expedition_shell.gd (`KIT_DIR`) |
| `assets/art/ui/minigames/kit/bubble_pop_128x40_3f.png` | 384×40 | scripts/batch_panel.gd / scenes/ui/batch_panel.tscn (minigame kit); scripts/ui/expedition_shell.gd (`KIT_DIR`) |
| `assets/art/ui/minigames/kit/bubble_tail_hover_13x10.png` | 13×10 | scripts/batch_panel.gd / scenes/ui/batch_panel.tscn (minigame kit); scripts/ui/expedition_shell.gd (`KIT_DIR`) |
| `assets/art/ui/minigames/kit/bubble_tail_normal_13x10.png` | 13×10 | scripts/batch_panel.gd / scenes/ui/batch_panel.tscn (minigame kit); scripts/ui/expedition_shell.gd (`KIT_DIR`) |
| `assets/art/ui/minigames/kit/deco_leaf_8x5.png` | 8×5 | scripts/batch_panel.gd / scenes/ui/batch_panel.tscn (minigame kit); scripts/ui/expedition_shell.gd (`KIT_DIR`) |
| `assets/art/ui/minigames/kit/deco_vine_br.png` | 58×47 | scripts/batch_panel.gd / scenes/ui/batch_panel.tscn (minigame kit); scripts/ui/expedition_shell.gd (`KIT_DIR`) |
| `assets/art/ui/minigames/kit/deco_vine_tl.png` | 64×54 | scripts/batch_panel.gd / scenes/ui/batch_panel.tscn (minigame kit); scripts/ui/expedition_shell.gd (`KIT_DIR`) |
| `assets/art/ui/minigames/kit/fb_good_48x22.png` | 48×22 | scripts/batch_panel.gd / scenes/ui/batch_panel.tscn (minigame kit); scripts/ui/expedition_shell.gd (`KIT_DIR`) |
| `assets/art/ui/minigames/kit/fb_miss_44x22.png` | 44×22 | scripts/batch_panel.gd / scenes/ui/batch_panel.tscn (minigame kit); scripts/ui/expedition_shell.gd (`KIT_DIR`) |
| `assets/art/ui/minigames/kit/fb_perfect_72x22.png` | 72×22 | scripts/batch_panel.gd / scenes/ui/batch_panel.tscn (minigame kit); scripts/ui/expedition_shell.gd (`KIT_DIR`) |
| `assets/art/ui/minigames/kit/frame_720x448.png` | 720×448 | scripts/batch_panel.gd / scenes/ui/batch_panel.tscn (minigame kit); scripts/ui/expedition_shell.gd (`KIT_DIR`) |
| `assets/art/ui/minigames/kit/frame_9s_96.png` | 96×96 | scripts/batch_panel.gd / scenes/ui/batch_panel.tscn (minigame kit); scripts/ui/expedition_shell.gd (`KIT_DIR`) |
| `assets/art/ui/minigames/kit/fx_good_24x24_4f.png` | 96×24 | scripts/batch_panel.gd / scenes/ui/batch_panel.tscn (minigame kit); scripts/ui/expedition_shell.gd (`KIT_DIR`) |
| `assets/art/ui/minigames/kit/fx_miss_24x24_3f.png` | 72×24 | scripts/batch_panel.gd / scenes/ui/batch_panel.tscn (minigame kit); scripts/ui/expedition_shell.gd (`KIT_DIR`) |
| `assets/art/ui/minigames/kit/fx_perfect_32x32_4f.png` | 128×32 | scripts/batch_panel.gd / scenes/ui/batch_panel.tscn (minigame kit); scripts/ui/expedition_shell.gd (`KIT_DIR`) |
| `assets/art/ui/minigames/kit/gauge_arrow_l_6x11.png` | 6×11 | scripts/batch_panel.gd / scenes/ui/batch_panel.tscn (minigame kit); scripts/ui/expedition_shell.gd (`KIT_DIR`) |
| `assets/art/ui/minigames/kit/gauge_arrow_r_6x11.png` | 6×11 | scripts/batch_panel.gd / scenes/ui/batch_panel.tscn (minigame kit); scripts/ui/expedition_shell.gd (`KIT_DIR`) |
| `assets/art/ui/minigames/kit/gauge_band_9s_40x12.png` | 40×12 | scripts/batch_panel.gd / scenes/ui/batch_panel.tscn (minigame kit); scripts/ui/expedition_shell.gd (`KIT_DIR`) |
| `assets/art/ui/minigames/kit/gauge_frame_40x240.png` | 40×240 | scripts/batch_panel.gd / scenes/ui/batch_panel.tscn (minigame kit); scripts/ui/expedition_shell.gd (`KIT_DIR`) |
| `assets/art/ui/minigames/kit/gauge_frame_9s_40x24.png` | 40×24 | scripts/batch_panel.gd / scenes/ui/batch_panel.tscn (minigame kit); scripts/ui/expedition_shell.gd (`KIT_DIR`) |
| `assets/art/ui/minigames/kit/keycap_1_14x15.png` | 14×15 | scripts/batch_panel.gd / scenes/ui/batch_panel.tscn (minigame kit); scripts/ui/expedition_shell.gd (`KIT_DIR`) |
| `assets/art/ui/minigames/kit/keycap_2_14x15.png` | 14×15 | scripts/batch_panel.gd / scenes/ui/batch_panel.tscn (minigame kit); scripts/ui/expedition_shell.gd (`KIT_DIR`) |
| `assets/art/ui/minigames/kit/keycap_3_14x15.png` | 14×15 | scripts/batch_panel.gd / scenes/ui/batch_panel.tscn (minigame kit); scripts/ui/expedition_shell.gd (`KIT_DIR`) |
| `assets/art/ui/minigames/kit/keycap_4_14x15.png` | 14×15 | scripts/batch_panel.gd / scenes/ui/batch_panel.tscn (minigame kit); scripts/ui/expedition_shell.gd (`KIT_DIR`) |
| `assets/art/ui/minigames/kit/keycap_5_14x15.png` | 14×15 | scripts/batch_panel.gd / scenes/ui/batch_panel.tscn (minigame kit); scripts/ui/expedition_shell.gd (`KIT_DIR`) |
| `assets/art/ui/minigames/kit/keycap_6_14x15.png` | 14×15 | scripts/batch_panel.gd / scenes/ui/batch_panel.tscn (minigame kit); scripts/ui/expedition_shell.gd (`KIT_DIR`) |
| `assets/art/ui/minigames/kit/keycap_9s_14x15.png` | 14×15 | scripts/batch_panel.gd / scenes/ui/batch_panel.tscn (minigame kit); scripts/ui/expedition_shell.gd (`KIT_DIR`) |
| `assets/art/ui/minigames/kit/keycap_a_14x15.png` | 14×15 | scripts/batch_panel.gd / scenes/ui/batch_panel.tscn (minigame kit); scripts/ui/expedition_shell.gd (`KIT_DIR`) |
| `assets/art/ui/minigames/kit/keycap_d_14x15.png` | 14×15 | scripts/batch_panel.gd / scenes/ui/batch_panel.tscn (minigame kit); scripts/ui/expedition_shell.gd (`KIT_DIR`) |
| `assets/art/ui/minigames/kit/keycap_down_14x15.png` | 14×15 | scripts/batch_panel.gd / scenes/ui/batch_panel.tscn (minigame kit); scripts/ui/expedition_shell.gd (`KIT_DIR`) |
| `assets/art/ui/minigames/kit/keycap_esc.png` | 28×20 | scripts/batch_panel.gd / scenes/ui/batch_panel.tscn (minigame kit); scripts/ui/expedition_shell.gd (`KIT_DIR`) |
| `assets/art/ui/minigames/kit/keycap_esc_28x15.png` | 28×15 | scripts/batch_panel.gd / scenes/ui/batch_panel.tscn (minigame kit); scripts/ui/expedition_shell.gd (`KIT_DIR`) |
| `assets/art/ui/minigames/kit/keycap_left_14x15.png` | 14×15 | scripts/batch_panel.gd / scenes/ui/batch_panel.tscn (minigame kit); scripts/ui/expedition_shell.gd (`KIT_DIR`) |
| `assets/art/ui/minigames/kit/keycap_right_14x15.png` | 14×15 | scripts/batch_panel.gd / scenes/ui/batch_panel.tscn (minigame kit); scripts/ui/expedition_shell.gd (`KIT_DIR`) |
| `assets/art/ui/minigames/kit/keycap_s_14x15.png` | 14×15 | scripts/batch_panel.gd / scenes/ui/batch_panel.tscn (minigame kit); scripts/ui/expedition_shell.gd (`KIT_DIR`) |
| `assets/art/ui/minigames/kit/keycap_space_40x15.png` | 40×15 | scripts/batch_panel.gd / scenes/ui/batch_panel.tscn (minigame kit); scripts/ui/expedition_shell.gd (`KIT_DIR`) |
| `assets/art/ui/minigames/kit/keycap_up_14x15.png` | 14×15 | scripts/batch_panel.gd / scenes/ui/batch_panel.tscn (minigame kit); scripts/ui/expedition_shell.gd (`KIT_DIR`) |
| `assets/art/ui/minigames/kit/keycap_w_14x15.png` | 14×15 | scripts/batch_panel.gd / scenes/ui/batch_panel.tscn (minigame kit); scripts/ui/expedition_shell.gd (`KIT_DIR`) |
| `assets/art/ui/minigames/kit/kit_palette.png` | 336×8 | scripts/batch_panel.gd / scenes/ui/batch_panel.tscn (minigame kit); scripts/ui/expedition_shell.gd (`KIT_DIR`) |
| `assets/art/ui/minigames/kit/mouse_circle_14x14.png` | 14×14 | scripts/batch_panel.gd / scenes/ui/batch_panel.tscn (minigame kit); scripts/ui/expedition_shell.gd (`KIT_DIR`) |
| `assets/art/ui/minigames/kit/mouse_drag_16x10.png` | 16×10 | scripts/batch_panel.gd / scenes/ui/batch_panel.tscn (minigame kit); scripts/ui/expedition_shell.gd (`KIT_DIR`) |
| `assets/art/ui/minigames/kit/mouse_hold_12x10.png` | 12×10 | scripts/batch_panel.gd / scenes/ui/batch_panel.tscn (minigame kit); scripts/ui/expedition_shell.gd (`KIT_DIR`) |
| `assets/art/ui/minigames/kit/mouse_l_8x10.png` | 8×10 | scripts/batch_panel.gd / scenes/ui/batch_panel.tscn (minigame kit); scripts/ui/expedition_shell.gd (`KIT_DIR`) |
| `assets/art/ui/minigames/kit/mouse_r_8x10.png` | 8×10 | scripts/batch_panel.gd / scenes/ui/batch_panel.tscn (minigame kit); scripts/ui/expedition_shell.gd (`KIT_DIR`) |
| `assets/art/ui/minigames/kit/num_8x11_sheet.png` | 137×11 | scripts/batch_panel.gd / scenes/ui/batch_panel.tscn (minigame kit); scripts/ui/expedition_shell.gd (`KIT_DIR`) |
| `assets/art/ui/minigames/kit/pace_fill_gold_132x8.png` | 132×8 | scripts/batch_panel.gd / scenes/ui/batch_panel.tscn (minigame kit); scripts/ui/expedition_shell.gd (`KIT_DIR`) |
| `assets/art/ui/minigames/kit/pace_fill_good_132x8.png` | 132×8 | scripts/batch_panel.gd / scenes/ui/batch_panel.tscn (minigame kit); scripts/ui/expedition_shell.gd (`KIT_DIR`) |
| `assets/art/ui/minigames/kit/pace_tick_5x4.png` | 5×4 | scripts/batch_panel.gd / scenes/ui/batch_panel.tscn (minigame kit); scripts/ui/expedition_shell.gd (`KIT_DIR`) |
| `assets/art/ui/minigames/kit/pace_track_136x18.png` | 136×18 | scripts/batch_panel.gd / scenes/ui/batch_panel.tscn (minigame kit); scripts/ui/expedition_shell.gd (`KIT_DIR`) |
| `assets/art/ui/minigames/kit/pip_empty_12.png` | 12×12 | scripts/batch_panel.gd / scenes/ui/batch_panel.tscn (minigame kit); scripts/ui/expedition_shell.gd (`KIT_DIR`) |
| `assets/art/ui/minigames/kit/pip_good_12.png` | 12×12 | scripts/batch_panel.gd / scenes/ui/batch_panel.tscn (minigame kit); scripts/ui/expedition_shell.gd (`KIT_DIR`) |
| `assets/art/ui/minigames/kit/pip_miss_12.png` | 12×12 | scripts/batch_panel.gd / scenes/ui/batch_panel.tscn (minigame kit); scripts/ui/expedition_shell.gd (`KIT_DIR`) |
| `assets/art/ui/minigames/kit/pip_perfect_12.png` | 12×12 | scripts/batch_panel.gd / scenes/ui/batch_panel.tscn (minigame kit); scripts/ui/expedition_shell.gd (`KIT_DIR`) |
| `assets/art/ui/minigames/kit/pip_pop_16x16_3f.png` | 48×16 | scripts/batch_panel.gd / scenes/ui/batch_panel.tscn (minigame kit); scripts/ui/expedition_shell.gd (`KIT_DIR`) |
| `assets/art/ui/minigames/kit/play_bevel_9s_6x6.png` | 6×6 | scripts/batch_panel.gd / scenes/ui/batch_panel.tscn (minigame kit); scripts/ui/expedition_shell.gd (`KIT_DIR`) |
| `assets/art/ui/minigames/kit/stop_button_disabled_104x28.png` | 104×28 | scripts/batch_panel.gd / scenes/ui/batch_panel.tscn (minigame kit); scripts/ui/expedition_shell.gd (`KIT_DIR`) |
| `assets/art/ui/minigames/kit/stop_button_hover_104x28.png` | 104×28 | scripts/batch_panel.gd / scenes/ui/batch_panel.tscn (minigame kit); scripts/ui/expedition_shell.gd (`KIT_DIR`) |
| `assets/art/ui/minigames/kit/stop_button_normal_104x28.png` | 104×28 | scripts/batch_panel.gd / scenes/ui/batch_panel.tscn (minigame kit); scripts/ui/expedition_shell.gd (`KIT_DIR`) |
| `assets/art/ui/minigames/kit/stop_button_pressed_104x28.png` | 104×28 | scripts/batch_panel.gd / scenes/ui/batch_panel.tscn (minigame kit); scripts/ui/expedition_shell.gd (`KIT_DIR`) |
| `assets/art/ui/minigames/kit/title_plank_3s_48x40.png` | 48×40 | scripts/batch_panel.gd / scenes/ui/batch_panel.tscn (minigame kit); scripts/ui/expedition_shell.gd (`KIT_DIR`) |
| `assets/art/ui/minigames/kit/title_plate_312x46.png` | 312×46 | scripts/batch_panel.gd / scenes/ui/batch_panel.tscn (minigame kit); scripts/ui/expedition_shell.gd (`KIT_DIR`) |
| `assets/art/ui/minigames/kit/title_sprig_26x20.png` | 26×20 | scripts/batch_panel.gd / scenes/ui/batch_panel.tscn (minigame kit); scripts/ui/expedition_shell.gd (`KIT_DIR`) |
| `assets/art/ui/minigames/kit/toast_9s_40x30.png` | 40×30 | scripts/batch_panel.gd / scenes/ui/batch_panel.tscn (minigame kit); scripts/ui/expedition_shell.gd (`KIT_DIR`) |
| `assets/art/ui/minigames/kit/wood_button_9s_disabled_32x28.png` | 32×28 | scripts/batch_panel.gd / scenes/ui/batch_panel.tscn (minigame kit); scripts/ui/expedition_shell.gd (`KIT_DIR`) |
| `assets/art/ui/minigames/kit/wood_button_9s_hover_32x28.png` | 32×28 | scripts/batch_panel.gd / scenes/ui/batch_panel.tscn (minigame kit); scripts/ui/expedition_shell.gd (`KIT_DIR`) |
| `assets/art/ui/minigames/kit/wood_button_9s_normal_32x28.png` | 32×28 | scripts/batch_panel.gd / scenes/ui/batch_panel.tscn (minigame kit); scripts/ui/expedition_shell.gd (`KIT_DIR`) |
| `assets/art/ui/minigames/kit/wood_button_9s_pressed_32x28.png` | 32×28 | scripts/batch_panel.gd / scenes/ui/batch_panel.tscn (minigame kit); scripts/ui/expedition_shell.gd (`KIT_DIR`) |
| `assets/art/ui/relic_slot_empty.png` | 44×44 | scripts/character_sheet.gd (`EMPTY_RELIC_FRAME_PATH`) |

## Battle UI (panels, plates, bars, buttons, chrome)

| File | Size | Used by |
|---|---|---|
| `assets/art/battle/ui/action_button_disabled_160x44.png` | 160×44 | scenes/battle/battle_scene.tscn (BattleView); scripts/battle/battle_view.gd (`UI_ART_DIR` / `_load_ui_tex`) |
| `assets/art/battle/ui/action_button_hover_160x44.png` | 160×44 | scenes/battle/battle_scene.tscn (BattleView); scripts/battle/battle_view.gd (`UI_ART_DIR` / `_load_ui_tex`) |
| `assets/art/battle/ui/action_button_normal_160x44.png` | 160×44 | scenes/battle/battle_scene.tscn (BattleView); scripts/battle/battle_view.gd (`UI_ART_DIR` / `_load_ui_tex`) |
| `assets/art/battle/ui/action_button_pressed_160x44.png` | 160×44 | scenes/battle/battle_scene.tscn (BattleView); scripts/battle/battle_view.gd (`UI_ART_DIR` / `_load_ui_tex`) |
| `assets/art/battle/ui/action_button_toggled_160x44.png` | 160×44 | scenes/battle/battle_scene.tscn (BattleView); scripts/battle/battle_view.gd (`UI_ART_DIR` / `_load_ui_tex`) |
| `assets/art/battle/ui/active_arrow_13x9.png` | 13×9 | scenes/battle/battle_scene.tscn (BattleView); scripts/battle/battle_view.gd (`UI_ART_DIR` / `_load_ui_tex`) |
| `assets/art/battle/ui/banner_3s_48x28.png` | 48×28 | scenes/battle/battle_scene.tscn (BattleView); scripts/battle/battle_view.gd (`UI_ART_DIR` / `_load_ui_tex`) |
| `assets/art/battle/ui/banner_3s_48x32.png` | 48×32 | scenes/battle/battle_scene.tscn (BattleView); scripts/battle/battle_view.gd (`UI_ART_DIR` / `_load_ui_tex`) |
| `assets/art/battle/ui/bar_hp_low_50x4.png` | 50×4 | scenes/battle/battle_scene.tscn (BattleView); scripts/battle/battle_view.gd (`UI_ART_DIR` / `_load_ui_tex`) |
| `assets/art/battle/ui/bar_hp_ok_50x4.png` | 50×4 | scenes/battle/battle_scene.tscn (BattleView); scripts/battle/battle_view.gd (`UI_ART_DIR` / `_load_ui_tex`) |
| `assets/art/battle/ui/bar_shield_50x4.png` | 50×4 | scenes/battle/battle_scene.tscn (BattleView); scripts/battle/battle_view.gd (`UI_ART_DIR` / `_load_ui_tex`) |
| `assets/art/battle/ui/bar_weave_50x2.png` | 50×2 | scenes/battle/battle_scene.tscn (BattleView); scripts/battle/battle_view.gd (`UI_ART_DIR` / `_load_ui_tex`) |
| `assets/art/battle/ui/bottom_panel_1280x136.png` | 1280×136 | scenes/battle/battle_scene.tscn (BattleView); scripts/battle/battle_view.gd (`UI_ART_DIR` / `_load_ui_tex`) |
| `assets/art/battle/ui/bottom_panel_9s_48.png` | 48×48 | scenes/battle/battle_scene.tscn (BattleView); scripts/battle/battle_view.gd (`UI_ART_DIR` / `_load_ui_tex`) |
| `assets/art/battle/ui/depth_plate_120x28.png` | 120×28 | scenes/battle/battle_scene.tscn (BattleView); scripts/battle/battle_view.gd (`UI_ART_DIR` / `_load_ui_tex`) |
| `assets/art/battle/ui/log_panel_732x108.png` | 732×108 | scenes/battle/battle_scene.tscn (BattleView); scripts/battle/battle_view.gd (`UI_ART_DIR` / `_load_ui_tex`) |
| `assets/art/battle/ui/log_panel_9s_12.png` | 12×12 | scenes/battle/battle_scene.tscn (BattleView); scripts/battle/battle_view.gd (`UI_ART_DIR` / `_load_ui_tex`) |
| `assets/art/battle/ui/log_toggle_closed_hover_11x11.png` | 11×11 | scenes/battle/battle_scene.tscn (BattleView); scripts/battle/battle_view.gd (`UI_ART_DIR` / `_load_ui_tex`) |
| `assets/art/battle/ui/log_toggle_closed_normal_11x11.png` | 11×11 | scenes/battle/battle_scene.tscn (BattleView); scripts/battle/battle_view.gd (`UI_ART_DIR` / `_load_ui_tex`) |
| `assets/art/battle/ui/log_toggle_open_hover_11x11.png` | 11×11 | scenes/battle/battle_scene.tscn (BattleView); scripts/battle/battle_view.gd (`UI_ART_DIR` / `_load_ui_tex`) |
| `assets/art/battle/ui/log_toggle_open_normal_11x11.png` | 11×11 | scenes/battle/battle_scene.tscn (BattleView); scripts/battle/battle_view.gd (`UI_ART_DIR` / `_load_ui_tex`) |
| `assets/art/battle/ui/plate_beast_56x20.png` | 56×20 | scenes/battle/battle_scene.tscn (BattleView); scripts/battle/battle_view.gd (`UI_ART_DIR` / `_load_ui_tex`) |
| `assets/art/battle/ui/plate_beast_active_56x20.png` | 56×20 | scenes/battle/battle_scene.tscn (BattleView); scripts/battle/battle_view.gd (`UI_ART_DIR` / `_load_ui_tex`) |
| `assets/art/battle/ui/plate_beast_boss_56x20.png` | 56×20 | scenes/battle/battle_scene.tscn (BattleView); scripts/battle/battle_view.gd (`UI_ART_DIR` / `_load_ui_tex`) |
| `assets/art/battle/ui/plate_beast_boss_active_56x20.png` | 56×20 | scenes/battle/battle_scene.tscn (BattleView); scripts/battle/battle_view.gd (`UI_ART_DIR` / `_load_ui_tex`) |
| `assets/art/battle/ui/plate_party_56x24.png` | 56×24 | scenes/battle/battle_scene.tscn (BattleView); scripts/battle/battle_view.gd (`UI_ART_DIR` / `_load_ui_tex`) |
| `assets/art/battle/ui/plate_party_active_56x24.png` | 56×24 | scenes/battle/battle_scene.tscn (BattleView); scripts/battle/battle_view.gd (`UI_ART_DIR` / `_load_ui_tex`) |
| `assets/art/battle/ui/round_banner_324x38.png` | 324×38 | scenes/battle/battle_scene.tscn (BattleView); scripts/battle/battle_view.gd (`UI_ART_DIR` / `_load_ui_tex`) |
| `assets/art/battle/ui/slot_mark_target.png` | 56×16 | scenes/battle/battle_scene.tscn (BattleView); scripts/battle/battle_view.gd (`UI_ART_DIR` / `_load_ui_tex`) |
| `assets/art/battle/ui/speed_1x_hover.png` | 32×32 | scenes/battle/battle_scene.tscn (BattleView); scripts/battle/battle_view.gd (`UI_ART_DIR` / `_load_ui_tex`) |
| `assets/art/battle/ui/speed_1x_normal.png` | 32×32 | scenes/battle/battle_scene.tscn (BattleView); scripts/battle/battle_view.gd (`UI_ART_DIR` / `_load_ui_tex`) |
| `assets/art/battle/ui/speed_1x_pressed.png` | 32×32 | scenes/battle/battle_scene.tscn (BattleView); scripts/battle/battle_view.gd (`UI_ART_DIR` / `_load_ui_tex`) |
| `assets/art/battle/ui/speed_1x_selected.png` | 32×32 | scenes/battle/battle_scene.tscn (BattleView); scripts/battle/battle_view.gd (`UI_ART_DIR` / `_load_ui_tex`) |
| `assets/art/battle/ui/speed_2x_hover.png` | 32×32 | scenes/battle/battle_scene.tscn (BattleView); scripts/battle/battle_view.gd (`UI_ART_DIR` / `_load_ui_tex`) |
| `assets/art/battle/ui/speed_2x_normal.png` | 32×32 | scenes/battle/battle_scene.tscn (BattleView); scripts/battle/battle_view.gd (`UI_ART_DIR` / `_load_ui_tex`) |
| `assets/art/battle/ui/speed_2x_pressed.png` | 32×32 | scenes/battle/battle_scene.tscn (BattleView); scripts/battle/battle_view.gd (`UI_ART_DIR` / `_load_ui_tex`) |
| `assets/art/battle/ui/speed_2x_selected.png` | 32×32 | scenes/battle/battle_scene.tscn (BattleView); scripts/battle/battle_view.gd (`UI_ART_DIR` / `_load_ui_tex`) |
| `assets/art/battle/ui/speed_4x_hover.png` | 32×32 | scenes/battle/battle_scene.tscn (BattleView); scripts/battle/battle_view.gd (`UI_ART_DIR` / `_load_ui_tex`) |
| `assets/art/battle/ui/speed_4x_normal.png` | 32×32 | scenes/battle/battle_scene.tscn (BattleView); scripts/battle/battle_view.gd (`UI_ART_DIR` / `_load_ui_tex`) |
| `assets/art/battle/ui/speed_4x_pressed.png` | 32×32 | scenes/battle/battle_scene.tscn (BattleView); scripts/battle/battle_view.gd (`UI_ART_DIR` / `_load_ui_tex`) |
| `assets/art/battle/ui/speed_4x_selected.png` | 32×32 | scenes/battle/battle_scene.tscn (BattleView); scripts/battle/battle_view.gd (`UI_ART_DIR` / `_load_ui_tex`) |
| `assets/art/battle/ui/speed_blank_hover_32x32.png` | 32×32 | scenes/battle/battle_scene.tscn (BattleView); scripts/battle/battle_view.gd (`UI_ART_DIR` / `_load_ui_tex`) |
| `assets/art/battle/ui/speed_blank_normal_32x32.png` | 32×32 | scenes/battle/battle_scene.tscn (BattleView); scripts/battle/battle_view.gd (`UI_ART_DIR` / `_load_ui_tex`) |
| `assets/art/battle/ui/speed_blank_pressed_32x32.png` | 32×32 | scenes/battle/battle_scene.tscn (BattleView); scripts/battle/battle_view.gd (`UI_ART_DIR` / `_load_ui_tex`) |
| `assets/art/battle/ui/speed_blank_selected_32x32.png` | 32×32 | scenes/battle/battle_scene.tscn (BattleView); scripts/battle/battle_view.gd (`UI_ART_DIR` / `_load_ui_tex`) |
| `assets/art/battle/ui/target_corner_6x6.png` | 6×6 | scenes/battle/battle_scene.tscn (BattleView); scripts/battle/battle_view.gd (`UI_ART_DIR` / `_load_ui_tex`) |

## Battle UI — intents / status / keycaps / sigils

| File | Size | Used by |
|---|---|---|
| `assets/art/battle/ui/boss_crown_16.png` | 16×16 | scenes/battle/battle_scene.tscn (BattleView); scripts/battle/battle_view.gd (`UI_ART_DIR` / `_load_ui_tex`) |
| `assets/art/battle/ui/boss_sigil_176x24.png` | 176×24 | scenes/battle/battle_scene.tscn (BattleView); scripts/battle/battle_view.gd (`UI_ART_DIR` / `_load_ui_tex`) |
| `assets/art/battle/ui/intent_bubble_22x26.png` | 22×26 | scenes/battle/battle_scene.tscn (BattleView); scripts/battle/battle_view.gd (`UI_ART_DIR` / `_load_ui_tex`) |
| `assets/art/battle/ui/intent_bubble_wide_40x26.png` | 40×26 | scenes/battle/battle_scene.tscn (BattleView); scripts/battle/battle_view.gd (`UI_ART_DIR` / `_load_ui_tex`) |
| `assets/art/battle/ui/intent_heavy_16.png` | 16×16 | scenes/battle/battle_scene.tscn (BattleView); scripts/battle/battle_view.gd (`UI_ART_DIR` / `_load_ui_tex`) |
| `assets/art/battle/ui/intent_heavy_opt_0_maul_old_16.png` | 16×16 | scenes/battle/battle_scene.tscn (BattleView); scripts/battle/battle_view.gd (`UI_ART_DIR` / `_load_ui_tex`) |
| `assets/art/battle/ui/intent_heavy_opt_a_smash_16.png` | 16×16 | scenes/battle/battle_scene.tscn (BattleView); scripts/battle/battle_view.gd (`UI_ART_DIR` / `_load_ui_tex`) |
| `assets/art/battle/ui/intent_heavy_opt_b_boulder_16.png` | 16×16 | scenes/battle/battle_scene.tscn (BattleView); scripts/battle/battle_view.gd (`UI_ART_DIR` / `_load_ui_tex`) |
| `assets/art/battle/ui/intent_heavy_opt_c_maul_16.png` | 16×16 | scenes/battle/battle_scene.tscn (BattleView); scripts/battle/battle_view.gd (`UI_ART_DIR` / `_load_ui_tex`) |
| `assets/art/battle/ui/intent_mult_x1_5.png` | 17×7 | scenes/battle/battle_scene.tscn (BattleView); scripts/battle/battle_view.gd (`UI_ART_DIR` / `_load_ui_tex`) |
| `assets/art/battle/ui/intent_mult_x2.png` | 10×7 | scenes/battle/battle_scene.tscn (BattleView); scripts/battle/battle_view.gd (`UI_ART_DIR` / `_load_ui_tex`) |
| `assets/art/battle/ui/intent_mult_x3.png` | 10×7 | scenes/battle/battle_scene.tscn (BattleView); scripts/battle/battle_view.gd (`UI_ART_DIR` / `_load_ui_tex`) |
| `assets/art/battle/ui/intent_poison_16.png` | 16×16 | scenes/battle/battle_scene.tscn (BattleView); scripts/battle/battle_view.gd (`UI_ART_DIR` / `_load_ui_tex`) |
| `assets/art/battle/ui/intent_strike_16.png` | 16×16 | scenes/battle/battle_scene.tscn (BattleView); scripts/battle/battle_view.gd (`UI_ART_DIR` / `_load_ui_tex`) |
| `assets/art/battle/ui/keycap_1_14x15.png` | 14×15 | scenes/battle/battle_scene.tscn (BattleView); scripts/battle/battle_view.gd (`UI_ART_DIR` / `_load_ui_tex`) |
| `assets/art/battle/ui/keycap_2_14x15.png` | 14×15 | scenes/battle/battle_scene.tscn (BattleView); scripts/battle/battle_view.gd (`UI_ART_DIR` / `_load_ui_tex`) |
| `assets/art/battle/ui/keycap_3_14x15.png` | 14×15 | scenes/battle/battle_scene.tscn (BattleView); scripts/battle/battle_view.gd (`UI_ART_DIR` / `_load_ui_tex`) |
| `assets/art/battle/ui/keycap_4_14x15.png` | 14×15 | scenes/battle/battle_scene.tscn (BattleView); scripts/battle/battle_view.gd (`UI_ART_DIR` / `_load_ui_tex`) |
| `assets/art/battle/ui/keycap_5_14x15.png` | 14×15 | scenes/battle/battle_scene.tscn (BattleView); scripts/battle/battle_view.gd (`UI_ART_DIR` / `_load_ui_tex`) |
| `assets/art/battle/ui/keycap_6_14x15.png` | 14×15 | scenes/battle/battle_scene.tscn (BattleView); scripts/battle/battle_view.gd (`UI_ART_DIR` / `_load_ui_tex`) |
| `assets/art/battle/ui/status_braced_12.png` | 12×12 | scenes/battle/battle_scene.tscn (BattleView); scripts/battle/battle_view.gd (`UI_ART_DIR` / `_load_ui_tex`) |
| `assets/art/battle/ui/status_calmed_12.png` | 12×12 | scenes/battle/battle_scene.tscn (BattleView); scripts/battle/battle_view.gd (`UI_ART_DIR` / `_load_ui_tex`) |
| `assets/art/battle/ui/status_fogged_12.png` | 12×12 | scenes/battle/battle_scene.tscn (BattleView); scripts/battle/battle_view.gd (`UI_ART_DIR` / `_load_ui_tex`) |
| `assets/art/battle/ui/status_ko_12.png` | 12×12 | scenes/battle/battle_scene.tscn (BattleView); scripts/battle/battle_view.gd (`UI_ART_DIR` / `_load_ui_tex`) |
| `assets/art/battle/ui/status_poisoned_12.png` | 12×12 | scenes/battle/battle_scene.tscn (BattleView); scripts/battle/battle_view.gd (`UI_ART_DIR` / `_load_ui_tex`) |
| `assets/art/battle/ui/status_rootbind_12.png` | 12×12 | scenes/battle/battle_scene.tscn (BattleView); scripts/battle/battle_view.gd (`UI_ART_DIR` / `_load_ui_tex`) |
| `assets/art/battle/ui/status_shield_12.png` | 12×12 | scenes/battle/battle_scene.tscn (BattleView); scripts/battle/battle_view.gd (`UI_ART_DIR` / `_load_ui_tex`) |
| `assets/art/battle/ui/status_slowed_12.png` | 12×12 | scenes/battle/battle_scene.tscn (BattleView); scripts/battle/battle_view.gd (`UI_ART_DIR` / `_load_ui_tex`) |
| `assets/art/battle/ui/twist_ambush_12.png` | 12×12 | scenes/battle/battle_scene.tscn (BattleView); scripts/battle/battle_view.gd (`UI_ART_DIR` / `_load_ui_tex`) |
| `assets/art/battle/ui/twist_rich_hollow_12.png` | 12×12 | scenes/battle/battle_scene.tscn (BattleView); scripts/battle/battle_view.gd (`UI_ART_DIR` / `_load_ui_tex`) |

## HUD elements (buttons, scene toggles, equip slots)

| File | Size | Used by |
|---|---|---|
| `assets/art/ui/buttons/backpack_hover.png` | 32×32 | scenes/hud.tscn; scripts/hud.gd (`BTN_PACK_HOVER`); scripts/hud.gd (pause/backpack/speed buttons) |
| `assets/art/ui/buttons/backpack_normal.png` | 32×32 | scenes/hud.tscn; scripts/hud.gd (`BTN_PACK_NORMAL`); scripts/hud.gd (pause/backpack/speed buttons) |
| `assets/art/ui/buttons/backpack_pressed.png` | 32×32 | scenes/hud.tscn; scripts/hud.gd (`BTN_PACK_PRESSED`); scripts/hud.gd (pause/backpack/speed buttons) |
| `assets/art/ui/buttons/pause_hover.png` | 32×32 | scenes/hud.tscn; scripts/hud.gd (`BTN_PAUSE_HOVER`); scripts/hud.gd (pause/backpack/speed buttons) |
| `assets/art/ui/buttons/pause_normal.png` | 32×32 | scenes/hud.tscn; scripts/hud.gd (`BTN_PAUSE_NORMAL`); scripts/hud.gd (pause/backpack/speed buttons) |
| `assets/art/ui/buttons/pause_pressed.png` | 32×32 | scenes/hud.tscn; scripts/hud.gd (`BTN_PAUSE_PRESSED`); scripts/hud.gd (pause/backpack/speed buttons) |
| `assets/art/ui/buttons/speed_16x_hover.png` | 32×32 | scenes/hud.tscn; scripts/hud.gd (pause/backpack/speed buttons) |
| `assets/art/ui/buttons/speed_16x_normal.png` | 32×32 | scenes/hud.tscn; scripts/hud.gd (pause/backpack/speed buttons) |
| `assets/art/ui/buttons/speed_16x_pressed.png` | 32×32 | scenes/hud.tscn; scripts/hud.gd (pause/backpack/speed buttons) |
| `assets/art/ui/buttons/speed_1x_hover.png` | 32×32 | scenes/hud.tscn; scripts/hud.gd (pause/backpack/speed buttons) |
| `assets/art/ui/buttons/speed_1x_normal.png` | 32×32 | scenes/hud.tscn; scripts/hud.gd (pause/backpack/speed buttons) |
| `assets/art/ui/buttons/speed_1x_pressed.png` | 32×32 | scenes/hud.tscn; scripts/hud.gd (pause/backpack/speed buttons) |
| `assets/art/ui/buttons/speed_2x_hover.png` | 32×32 | scenes/hud.tscn; scripts/hud.gd (pause/backpack/speed buttons) |
| `assets/art/ui/buttons/speed_2x_normal.png` | 32×32 | scenes/hud.tscn; scripts/hud.gd (pause/backpack/speed buttons) |
| `assets/art/ui/buttons/speed_2x_pressed.png` | 32×32 | scenes/hud.tscn; scripts/hud.gd (pause/backpack/speed buttons) |
| `assets/art/ui/buttons/speed_4x_hover.png` | 32×32 | scenes/hud.tscn; scripts/hud.gd (pause/backpack/speed buttons) |
| `assets/art/ui/buttons/speed_4x_normal.png` | 32×32 | scenes/hud.tscn; scripts/hud.gd (pause/backpack/speed buttons) |
| `assets/art/ui/buttons/speed_4x_pressed.png` | 32×32 | scenes/hud.tscn; scripts/hud.gd (pause/backpack/speed buttons) |
| `assets/art/ui/buttons/speed_8x_hover.png` | 32×32 | scenes/hud.tscn; scripts/hud.gd (pause/backpack/speed buttons) |
| `assets/art/ui/buttons/speed_8x_normal.png` | 32×32 | scenes/hud.tscn; scripts/hud.gd (pause/backpack/speed buttons) |
| `assets/art/ui/buttons/speed_8x_pressed.png` | 32×32 | scenes/hud.tscn; scripts/hud.gd (pause/backpack/speed buttons) |
| `assets/art/ui/buttons/speed_play_hover.png` | 32×32 | scenes/hud.tscn; scripts/hud.gd (pause/backpack/speed buttons) |
| `assets/art/ui/buttons/speed_play_normal.png` | 32×32 | scenes/hud.tscn; scripts/hud.gd (pause/backpack/speed buttons) |
| `assets/art/ui/buttons/speed_play_pressed.png` | 32×32 | scenes/hud.tscn; scripts/hud.gd (pause/backpack/speed buttons) |
| `assets/art/ui/icons/hud_ascension.png` | 32×32 | scripts/character_sheet.gd; scripts/hud.gd; scripts/hud_icons.gd |
| `assets/art/ui/icons/hud_character.png` | 32×32 | scripts/battle/battle_view.gd; scripts/character_sheet.gd; scripts/hud.gd; scripts/hud_icons.gd |
| `assets/art/ui/icons/hud_equip_empty.png` | 32×32 | scripts/character_sheet.gd; scripts/hud.gd; scripts/hud_icons.gd |
| `assets/art/ui/icons/hud_equip_locked.png` | 32×32 | scripts/character_sheet.gd; scripts/hud.gd; scripts/hud_icons.gd |
| `assets/art/ui/icons/hud_help.png` | 32×32 | scripts/character_sheet.gd; scripts/hud.gd; scripts/hud_icons.gd |
| `assets/art/ui/icons/hud_keep_tools.png` | 32×32 | scripts/character_sheet.gd; scripts/hud.gd; scripts/hud_icons.gd |
| `assets/art/ui/icons/hud_scene_clearing.png` | 32×32 | scripts/character_sheet.gd; scripts/hud.gd; scripts/hud.gd (`path`); scripts/hud_icons.gd |
| `assets/art/ui/icons/hud_scene_forge.png` | 32×32 | scripts/character_sheet.gd; scripts/hud.gd; scripts/hud.gd (`path`); scripts/hud_icons.gd |
| `assets/art/ui/icons/hud_stone_sword_old.png` | 32×32 | scripts/character_sheet.gd; scripts/hud.gd; scripts/hud_icons.gd |
| `assets/art/ui/icons/hud_watering_can.png` | 32×32 | scripts/character_sheet.gd; scripts/hud.gd; scripts/hud_icons.gd |
| `assets/art/ui/icons/hud_wooden_basket.png` | 32×32 | scripts/character_sheet.gd; scripts/hud.gd; scripts/hud_icons.gd |

## Adventure / expedition board

| File | Size | Used by |
|---|---|---|
| `assets/art/props/expedition_board/board_exclaim.png` | 7×16 | scripts/expedition_board.gd (`EXCLAIM_ART`) |
| `assets/art/props/expedition_board/board_lantern_mask.png` | 128×136 | _not directly referenced (asset present; may be meta-only or unused)_ |
| `assets/art/props/expedition_board/expedition_board_amber.png` | 384×136 | _not directly referenced (asset present; may be meta-only or unused)_ |
| `assets/art/props/expedition_board/expedition_board_amber_0001.png` | 128×136 | scripts/expedition_board.gd (`DARK_ART`) |
| `assets/art/props/expedition_board/expedition_board_amber_0002.png` | 128×136 | scripts/expedition_board.gd (`DARK_ART`) |
| `assets/art/props/expedition_board/expedition_board_amber_0003.png` | 128×136 | scripts/expedition_board.gd (`DARK_ART`) |
| `assets/art/props/expedition_board/expedition_board_cyan.png` | 512×136 | _not directly referenced (asset present; may be meta-only or unused)_ |
| `assets/art/props/expedition_board/expedition_board_cyan_0001.png` | 128×136 | scripts/expedition_board.gd (`DARK_ART`) |
| `assets/art/props/expedition_board/expedition_board_cyan_0002.png` | 128×136 | scripts/expedition_board.gd |
| `assets/art/props/expedition_board/expedition_board_cyan_0003.png` | 128×136 | scripts/expedition_board.gd |
| `assets/art/props/expedition_board/expedition_board_cyan_0004.png` | 128×136 | scripts/expedition_board.gd |
| `assets/art/props/expedition_board/expedition_board_dark.png` | 128×136 | scripts/expedition_board.gd (`DARK_ART`) |
| `assets/art/props/expedition_board/expedition_board_states_strip.png` | 1024×136 | _not directly referenced (asset present; may be meta-only or unused)_ |
| `assets/art/ui/board/arrow_enemy_side_12x9.png` | 12×9 | scripts/expedition_board.gd (`BOARD_DIR`); scripts/ui/expedition_shell.gd (`BOARD_DIR`) |
| `assets/art/ui/board/cost_chip_9s_ok_24x32.png` | 24×32 | scripts/expedition_board.gd (`BOARD_DIR`); scripts/ui/expedition_shell.gd (`BOARD_DIR`) |
| `assets/art/ui/board/cost_chip_9s_short_24x32.png` | 24×32 | scripts/expedition_board.gd (`BOARD_DIR`); scripts/ui/expedition_shell.gd (`BOARD_DIR`) |
| `assets/art/ui/board/divider_3s_48x6.png` | 48×6 | scripts/expedition_board.gd (`BOARD_DIR`); scripts/ui/expedition_shell.gd (`BOARD_DIR`) |
| `assets/art/ui/board/field_9s_disabled_24x24.png` | 24×24 | scripts/expedition_board.gd (`BOARD_DIR`); scripts/ui/expedition_shell.gd (`BOARD_DIR`) |
| `assets/art/ui/board/field_9s_focus_24x24.png` | 24×24 | scripts/expedition_board.gd (`BOARD_DIR`); scripts/ui/expedition_shell.gd (`BOARD_DIR`) |
| `assets/art/ui/board/field_9s_invalid_24x24.png` | 24×24 | scripts/expedition_board.gd (`BOARD_DIR`); scripts/ui/expedition_shell.gd (`BOARD_DIR`) |
| `assets/art/ui/board/field_9s_normal_24x24.png` | 24×24 | scripts/expedition_board.gd (`BOARD_DIR`); scripts/ui/expedition_shell.gd (`BOARD_DIR`) |
| `assets/art/ui/board/glyph_minus_10x10.png` | 10×10 | scripts/expedition_board.gd (`BOARD_DIR`); scripts/ui/expedition_shell.gd (`BOARD_DIR`) |
| `assets/art/ui/board/glyph_minus_disabled_10x10.png` | 10×10 | scripts/expedition_board.gd (`BOARD_DIR`); scripts/ui/expedition_shell.gd (`BOARD_DIR`) |
| `assets/art/ui/board/glyph_plus_10x10.png` | 10×10 | scripts/expedition_board.gd (`BOARD_DIR`); scripts/ui/expedition_shell.gd (`BOARD_DIR`) |
| `assets/art/ui/board/glyph_plus_disabled_10x10.png` | 10×10 | scripts/expedition_board.gd (`BOARD_DIR`); scripts/ui/expedition_shell.gd (`BOARD_DIR`) |
| `assets/art/ui/board/item_slot_empty_44x44.png` | 44×44 | scripts/expedition_board.gd (`BOARD_DIR`); scripts/ui/expedition_shell.gd (`BOARD_DIR`) |
| `assets/art/ui/board/item_slot_hover_44x44.png` | 44×44 | scripts/expedition_board.gd (`BOARD_DIR`); scripts/ui/expedition_shell.gd (`BOARD_DIR`) |
| `assets/art/ui/board/item_slot_normal_44x44.png` | 44×44 | scripts/expedition_board.gd (`BOARD_DIR`); scripts/ui/expedition_shell.gd (`BOARD_DIR`) |
| `assets/art/ui/board/list_row_9s_even_24x24.png` | 24×24 | scripts/expedition_board.gd (`BOARD_DIR`); scripts/ui/expedition_shell.gd (`BOARD_DIR`) |
| `assets/art/ui/board/list_row_9s_loss_24x24.png` | 24×24 | scripts/expedition_board.gd (`BOARD_DIR`); scripts/ui/expedition_shell.gd (`BOARD_DIR`) |
| `assets/art/ui/board/lock_10x12.png` | 10×12 | scripts/expedition_board.gd (`BOARD_DIR`); scripts/ui/expedition_shell.gd (`BOARD_DIR`) |
| `assets/art/ui/board/party_slot_empty_60x60.png` | 60×60 | scripts/expedition_board.gd (`BOARD_DIR`); scripts/ui/expedition_shell.gd (`BOARD_DIR`) |
| `assets/art/ui/board/party_slot_empty_hover_60x60.png` | 60×60 | scripts/expedition_board.gd (`BOARD_DIR`); scripts/ui/expedition_shell.gd (`BOARD_DIR`) |
| `assets/art/ui/board/party_slot_filled_60x60.png` | 60×60 | scripts/expedition_board.gd (`BOARD_DIR`); scripts/ui/expedition_shell.gd (`BOARD_DIR`) |
| `assets/art/ui/board/party_slot_hover_60x60.png` | 60×60 | scripts/expedition_board.gd (`BOARD_DIR`); scripts/ui/expedition_shell.gd (`BOARD_DIR`) |
| `assets/art/ui/board/party_slot_locked_60x60.png` | 60×60 | scripts/expedition_board.gd (`BOARD_DIR`); scripts/ui/expedition_shell.gd (`BOARD_DIR`) |
| `assets/art/ui/board/party_slot_selected_60x60.png` | 60×60 | scripts/expedition_board.gd (`BOARD_DIR`); scripts/ui/expedition_shell.gd (`BOARD_DIR`) |
| `assets/art/ui/board/pick_row_9s_current_24x24.png` | 24×24 | scripts/expedition_board.gd (`BOARD_DIR`); scripts/ui/expedition_shell.gd (`BOARD_DIR`) |
| `assets/art/ui/board/pick_row_9s_disabled_24x24.png` | 24×24 | scripts/expedition_board.gd (`BOARD_DIR`); scripts/ui/expedition_shell.gd (`BOARD_DIR`) |
| `assets/art/ui/board/pick_row_9s_hover_24x24.png` | 24×24 | scripts/expedition_board.gd (`BOARD_DIR`); scripts/ui/expedition_shell.gd (`BOARD_DIR`) |
| `assets/art/ui/board/popup_9s_32x32.png` | 32×32 | scripts/expedition_board.gd (`BOARD_DIR`); scripts/ui/expedition_shell.gd (`BOARD_DIR`) |
| `assets/art/ui/board/popup_tail_l_8x14.png` | 8×14 | scripts/expedition_board.gd (`BOARD_DIR`); scripts/ui/expedition_shell.gd (`BOARD_DIR`) |
| `assets/art/ui/board/scroll_thumb_9s_drag_12x16.png` | 12×16 | scripts/expedition_board.gd (`BOARD_DIR`); scripts/ui/expedition_shell.gd (`BOARD_DIR`) |
| `assets/art/ui/board/scroll_thumb_9s_hover_12x16.png` | 12×16 | scripts/expedition_board.gd (`BOARD_DIR`); scripts/ui/expedition_shell.gd (`BOARD_DIR`) |
| `assets/art/ui/board/scroll_thumb_9s_normal_12x16.png` | 12×16 | scripts/expedition_board.gd (`BOARD_DIR`); scripts/ui/expedition_shell.gd (`BOARD_DIR`) |
| `assets/art/ui/board/scroll_track_9s_12x24.png` | 12×24 | scripts/expedition_board.gd (`BOARD_DIR`); scripts/ui/expedition_shell.gd (`BOARD_DIR`) |
| `assets/art/ui/board/wood_button_9s_selected_32x28.png` | 32×28 | scripts/expedition_board.gd (`BOARD_DIR`); scripts/ui/expedition_shell.gd (`BOARD_DIR`) |

## Portraits & status windows

| File | Size | Used by |
|---|---|---|
| `assets/art/portraits/elaia_portrait.png` | 52×52 | data/companions.json; scripts/character_sheet.gd (`ELAIA_PARTY_PORTRAIT_PATH`); scripts/expedition_board.gd |
| `assets/art/portraits/elaia_portrait_sheet.png` | 160×160 | scripts/character_sheet.gd (`ELAIA_SHEET_PORTRAIT_PATH`) |
| `assets/art/portraits/keeper_portrait.png` | 52×52 | data/companions.json; scripts/character_sheet.gd (`KEEPER_PARTY_PORTRAIT_PATH`); scripts/expedition_board.gd |
| `assets/art/portraits/keeper_portrait_sheet.png` | 160×160 | scripts/character_sheet.gd (`KEEPER_SHEET_PORTRAIT_PATH`) |

## Icons (resources, rewards, items, HUD/ascension)

| File | Size | Used by |
|---|---|---|
| `assets/art/battle/ui/icon_ability_32.png` | 32×32 | scenes/battle/battle_scene.tscn (BattleView); scripts/battle/battle_view.gd (`UI_ART_DIR` / `_load_ui_tex`) |
| `assets/art/battle/ui/icon_brace_32.png` | 32×32 | scenes/battle/battle_scene.tscn (BattleView); scripts/battle/battle_view.gd (`UI_ART_DIR` / `_load_ui_tex`) |
| `assets/art/battle/ui/icon_flee_32.png` | 32×32 | scenes/battle/battle_scene.tscn (BattleView); scripts/battle/battle_view.gd (`UI_ART_DIR` / `_load_ui_tex`) |
| `assets/art/ui/glyphs/glyph_0.png` | 5×7 | _not directly referenced (asset present; may be meta-only or unused)_ |
| `assets/art/ui/glyphs/glyph_1.png` | 5×7 | _not directly referenced (asset present; may be meta-only or unused)_ |
| `assets/art/ui/glyphs/glyph_2.png` | 5×7 | _not directly referenced (asset present; may be meta-only or unused)_ |
| `assets/art/ui/glyphs/glyph_3.png` | 5×7 | _not directly referenced (asset present; may be meta-only or unused)_ |
| `assets/art/ui/glyphs/glyph_4.png` | 5×7 | _not directly referenced (asset present; may be meta-only or unused)_ |
| `assets/art/ui/glyphs/glyph_5.png` | 5×7 | _not directly referenced (asset present; may be meta-only or unused)_ |
| `assets/art/ui/glyphs/glyph_6.png` | 5×7 | _not directly referenced (asset present; may be meta-only or unused)_ |
| `assets/art/ui/glyphs/glyph_7.png` | 5×7 | _not directly referenced (asset present; may be meta-only or unused)_ |
| `assets/art/ui/glyphs/glyph_8.png` | 5×7 | _not directly referenced (asset present; may be meta-only or unused)_ |
| `assets/art/ui/glyphs/glyph_9.png` | 5×7 | _not directly referenced (asset present; may be meta-only or unused)_ |
| `assets/art/ui/glyphs/glyph_x.png` | 5×7 | _not directly referenced (asset present; may be meta-only or unused)_ |
| `assets/art/ui/icon_amberbind.png` | 32×32 | scripts/verify_headless.gd |
| `assets/art/ui/icon_bile_vial.png` | 32×32 | _not directly referenced (asset present; may be meta-only or unused)_ |
| `assets/art/ui/icon_bitterroot.png` | 32×32 | scripts/verify_headless.gd |
| `assets/art/ui/icon_briarwood.png` | 32×32 | scripts/verify_headless.gd |
| `assets/art/ui/icon_essence.png` | 32×32 | scripts/autoload/forge_jobs.gd; scripts/hud.gd (`ICON_ESSENCE_TEX`); scripts/ui/expedition_shell.gd (`ICON_ESSENCE_TEX`) |
| `assets/art/ui/icon_fertilizer.png` | 32×32 | scripts/hud.gd (`ICON_FERTILIZER_TEX`) |
| `assets/art/ui/icon_food.png` | 32×32 | scenes/hud.tscn; scripts/autoload/forge_jobs.gd; scripts/hud.gd (`ICON_FOOD_TEX`) |
| `assets/art/ui/icon_glowcap.png` | 32×32 | scripts/verify_headless.gd |
| `assets/art/ui/icon_heart_salve.png` | 32×32 | scripts/battle/battle_view.gd |
| `assets/art/ui/icon_heartwand.png` | 32×32 | scripts/verify_headless.gd (`flint_icon`) |
| `assets/art/ui/icon_heartwood_bits.png` | 32×32 | scripts/verify_headless.gd |
| `assets/art/ui/icon_manashards.png` | 32×32 | scenes/hud.tscn; scripts/hud.gd (`ICON_SHARD_TEX`); scripts/title_screen.gd (`cursor_tex`) |
| `assets/art/ui/icon_rootsteel_edge.png` | 32×32 | scripts/verify_headless.gd (`flint_icon`) |
| `assets/art/ui/icon_sapstaff.png` | 32×32 | _not directly referenced (asset present; may be meta-only or unused)_ |
| `assets/art/ui/icon_sapsteel.png` | 32×32 | scripts/verify_headless.gd |
| `assets/art/ui/icon_stone.png` | 32×32 | scenes/hud.tscn; scripts/autoload/forge_jobs.gd; scripts/hud.gd (`ICON_STONE_TEX`) |
| `assets/art/ui/icon_stone_sword.png` | 32×32 | scripts/battle/battle_view.gd |
| `assets/art/ui/icon_switchshaft.png` | 32×32 | scripts/verify_headless.gd (`flint_icon`) |
| `assets/art/ui/icon_thornbow.png` | 32×32 | _not directly referenced (asset present; may be meta-only or unused)_ |
| `assets/art/ui/icon_wood.png` | 32×32 | scenes/hud.tscn; scripts/autoload/forge_jobs.gd; scripts/hud.gd (`ICON_WOOD_TEX`) |
| `assets/art/ui/icons/icon_asc_bonus_wisp.png` | 32×32 | scripts/character_sheet.gd; scripts/hud.gd; scripts/hud_icons.gd |
| `assets/art/ui/icons/icon_asc_deep_roots.png` | 32×32 | scripts/character_sheet.gd; scripts/hud.gd; scripts/hud_icons.gd |
| `assets/art/ui/icons/icon_asc_forager.png` | 32×32 | scripts/character_sheet.gd; scripts/hud.gd; scripts/hud_icons.gd |
| `assets/art/ui/icons/icon_asc_green_thumb.png` | 32×32 | scripts/character_sheet.gd; scripts/hud.gd; scripts/hud_icons.gd |
| `assets/art/ui/icons/icon_asc_keep_forge_intermediates.png` | 32×32 | scripts/character_sheet.gd; scripts/hud.gd; scripts/hud_icons.gd |
| `assets/art/ui/icons/icon_asc_keep_forge_jobs.png` | 32×32 | scripts/character_sheet.gd; scripts/hud.gd; scripts/hud_icons.gd |
| `assets/art/ui/icons/icon_asc_keep_tools.png` | 32×32 | scripts/character_sheet.gd; scripts/hud.gd; scripts/hud_icons.gd |
| `assets/art/ui/icons/icon_asc_keeper_stride.png` | 32×32 | scripts/character_sheet.gd; scripts/hud.gd; scripts/hud_icons.gd |
| `assets/art/ui/icons/icon_asc_shard_sight.png` | 32×32 | scripts/character_sheet.gd; scripts/hud.gd; scripts/hud_icons.gd |
| `assets/art/ui/icons/icon_asc_wisp_haste.png` | 32×32 | scripts/character_sheet.gd; scripts/hud.gd; scripts/hud_icons.gd |
| `assets/art/ui/icons/icon_axe_head.png` | 32×32 | scripts/character_sheet.gd; scripts/hud.gd; scripts/hud_icons.gd |
| `assets/art/ui/icons/icon_fertilizer.png` | 32×32 | scripts/character_sheet.gd; scripts/hud.gd; scripts/hud_icons.gd |
| `assets/art/ui/icons/icon_forge_key.png` | 32×32 | scripts/character_sheet.gd; scripts/hud.gd; scripts/hud_icons.gd |
| `assets/art/ui/icons/icon_oakheart_knot.png` | 32×32 | scripts/character_sheet.gd; scripts/hud.gd; scripts/hud_icons.gd |
| `assets/art/ui/icons/icon_pickaxe_head.png` | 32×32 | scripts/character_sheet.gd; scripts/hud.gd; scripts/hud_icons.gd |
| `assets/art/ui/icons/icon_shardlens.png` | 32×32 | scripts/character_sheet.gd; scripts/hud.gd; scripts/hud_icons.gd |
| `assets/art/ui/icons/icon_stone_axe.png` | 32×32 | scripts/character_sheet.gd; scripts/hud.gd; scripts/hud_icons.gd |
| `assets/art/ui/icons/icon_stone_fragments.png` | 32×32 | scripts/character_sheet.gd; scripts/hud.gd; scripts/hud_icons.gd |
| `assets/art/ui/icons/icon_stone_pickaxe.png` | 32×32 | scripts/character_sheet.gd; scripts/hud.gd; scripts/hud_icons.gd |
| `assets/art/ui/icons/icon_weapon_rod.png` | 32×32 | scripts/character_sheet.gd; scripts/hud.gd; scripts/hud_icons.gd |
| `assets/art/ui/icons/icon_windthorn_bead.png` | 32×32 | scripts/character_sheet.gd; scripts/hud.gd; scripts/hud_icons.gd |
| `assets/art/ui/icons/icon_wooden_planks.png` | 32×32 | scripts/character_sheet.gd; scripts/hud.gd; scripts/hud_icons.gd |
| `assets/art/ui/icons/icon_wooden_tool_rod.png` | 32×32 | scripts/character_sheet.gd; scripts/hud.gd; scripts/hud_icons.gd |

## Manatree (hub centerpiece stills; anim sheets excluded)

| File | Size | Used by |
|---|---|---|
| `assets/art/manatree/native/manatree_ancient.png` | 2048×2560 | scripts/manatree.gd (`META_PATH`) |
| `assets/art/manatree/native/manatree_elder.png` | 1536×2048 | scripts/manatree.gd (`META_PATH`) |
| `assets/art/manatree/native/manatree_mature.png` | 1024×1536 | scripts/manatree.gd (`META_PATH`) |
| `assets/art/manatree/native/manatree_sapling.png` | 256×384 | scripts/manatree.gd (`META_PATH`) |
| `assets/art/manatree/native/manatree_young.png` | 576×864 | scripts/manatree.gd (`META_PATH`) |

## World props (runestones, thorn, echo portal hub)

| File | Size | Used by |
|---|---|---|
| `assets/art/props/echo_portal_hub.png` | 784×1168 | scripts/verify_headless.gd |
| `assets/art/props/echo_portal_hub_v2.png` | 160×200 | scripts/echo_portal.gd (`PORTAL_ART`) |
| `assets/art/props/runestones/native/runestone_arcana.png` | 64×64 | _not directly referenced (asset present; may be meta-only or unused)_ |
| `assets/art/props/runestones/native/runestone_fate.png` | 64×64 | _not directly referenced (asset present; may be meta-only or unused)_ |
| `assets/art/props/runestones/native/runestone_might.png` | 64×64 | _not directly referenced (asset present; may be meta-only or unused)_ |
| `assets/art/props/runestones/native/runestone_resilience.png` | 64×64 | _not directly referenced (asset present; may be meta-only or unused)_ |
| `assets/art/props/runestones/native/runestone_swiftness.png` | 64×64 | _not directly referenced (asset present; may be meta-only or unused)_ |
| `assets/art/props/runestones/native/runestone_vitality.png` | 64×64 | _not directly referenced (asset present; may be meta-only or unused)_ |
| `assets/art/props/runestones/native/runestone_ward.png` | 64×64 | _not directly referenced (asset present; may be meta-only or unused)_ |
| `assets/art/props/runestones/native/runestones_sheet.png` | 512×512 | scripts/runestone.gd (`RUNE_SHEET`) |
| `assets/art/props/thorn/thorn_wall_closed.png` | 220×160 | scripts/thorn_wall.gd (`CLOSED_ART`) |
| `assets/art/props/thorn/thorn_wall_open.png` | 220×160 | scripts/thorn_wall.gd (`OPEN_ART`) |
| `assets/art/props/thorn/thorn_wall_retreat.png` | 1100×160 | _not directly referenced (asset present; may be meta-only or unused)_ |
| `assets/art/props/thorn/thorn_wall_retreat_0001.png` | 220×160 | scripts/thorn_wall.gd (`OPEN_ART`) |
| `assets/art/props/thorn/thorn_wall_retreat_0002.png` | 220×160 | scripts/thorn_wall.gd (`OPEN_ART`) |
| `assets/art/props/thorn/thorn_wall_retreat_0003.png` | 220×160 | scripts/thorn_wall.gd (`OPEN_ART`) |
| `assets/art/props/thorn/thorn_wall_retreat_0004.png` | 220×160 | scripts/thorn_wall.gd (`OPEN_ART`) |
| `assets/art/props/thorn/thorn_wall_retreat_0005.png` | 220×160 | scripts/thorn_wall.gd (`OPEN_ART`) |

## FX textures

| File | Size | Used by |
|---|---|---|
| `assets/art/fx/fx_vein_mote.png` | 5×5 | _not directly referenced (asset present; may be meta-only or unused)_ |
| `assets/art/fx/fx_vein_mote_strip.png` | 15×5 | scripts/manatree.gd (`VEIN_TEX`) |

## Fonts

**Font files:** none in the repo (no `.ttf` / `.otf` / `.fnt`). UI uses Godot’s default font via `theme_override_font_sizes/font_size` and `add_theme_font_size_override("font_size", …)`. No `.tres` Theme resources found.

### Font sizes in use (game scenes + scripts)

| Size (px) | Example usages |
|---:|---|
| 10 | `scenes/wisp.tscn`, `scripts/battle/battle_view.gd`, `scripts/battle/battle_view.gd:1016`, `scripts/battle/battle_view.gd:1228`, `scripts/battle/battle_view.gd:1454`, `scripts/character_sheet.gd` (+1 more) |
| 11 | `scenes/gatherable.tscn`, `scenes/hud.tscn`, `scenes/manatree.tscn`, `scenes/runestone.tscn`, `scripts/character_sheet.gd`, `scripts/character_sheet.gd:293` (+8 more) |
| 12 | `scenes/echo_battle.tscn`, `scenes/forge/anvil.tscn`, `scenes/forge/crucible.tscn`, `scenes/forge/mill.tscn`, `scenes/forge/press.tscn`, `scenes/forge/reliquary.tscn` (+25 more) |
| 13 | `scenes/hud.tscn`, `scenes/pause_menu.tscn`, `scripts/character_sheet.gd`, `scripts/character_sheet.gd:1213`, `scripts/character_sheet.gd:476`, `scripts/hud.gd` (+5 more) |
| 14 | `scenes/bramble_warden.tscn`, `scenes/echo_portal.tscn`, `scenes/expedition_board.tscn`, `scenes/forge/anvil.tscn`, `scenes/forge/crucible.tscn`, `scenes/forge/mill.tscn` (+17 more) |
| 15 | `scenes/echo_battle.tscn`, `scenes/hud.tscn`, `scripts/character_sheet.gd`, `scripts/character_sheet.gd:371`, `scripts/character_sheet.gd:437`, `scripts/character_sheet.gd:706` (+4 more) |
| 16 | `scenes/forge_room.tscn`, `scenes/hud.tscn`, `scenes/title_screen.tscn`, `scripts/hud.gd`, `scripts/hud.gd:1250`, `scripts/hud.gd:1763` (+6 more) |
| 18 | `scenes/battle/battle_scene.tscn`, `scenes/hud.tscn`, `scenes/pause_menu.tscn`, `scripts/character_sheet.gd`, `scripts/character_sheet.gd:682`, `scripts/hud.gd` (+1 more) |
| 20 | `scenes/pause_menu.tscn`, `scripts/character_sheet.gd`, `scripts/character_sheet.gd:278`, `scripts/ui/expedition_shell.gd`, `scripts/ui/expedition_shell.gd:369` |
| 22 | `scripts/hud.gd`, `scripts/hud.gd:1704`, `scripts/hud.gd:1720`, `scripts/title_screen.gd`, `scripts/title_screen.gd:147` |
| 28 | `scripts/hud.gd`, `scripts/hud.gd:1752` |

**Unique sizes:** 10, 11, 12, 13, 14, 15, 16, 18, 20, 22, 28 (11 sizes).

## Theme `.tres` files

None found under the project (no `*.tres` Theme resources). UI styling is inline StyleBoxFlat / StyleBoxTexture constructed in scripts (`expedition_shell.gd`, `character_sheet.gd`, `title_screen.gd`, etc.) plus per-control `theme_override_font_sizes`.

## Hard-coded 1280/720 layout

### `project.godot` window / stretch

```
[display]
window/size/viewport_width=1280
window/size/viewport_height=720
window/size/window_width_override=1280
window/size/window_height_override=720
window/stretch/mode="canvas_items"
window/stretch/aspect="expand"
```

### Camera limits

- **Hub (`scenes/main.tscn` → `Camera2D`)**: limit_left = 180, limit_top = 180, limit_right = 4140, limit_bottom = 3600
- **Forge (`scenes/forge_room.tscn` → `Camera2D`)**: limit_left = 0, limit_top = 0, limit_right = 1600, limit_bottom = 1200
- **Hub script defaults** (`scripts/main.gd`): `view_size = Vector2(1280, 720)`; reads `viewport_width`/`viewport_height` from `data/hub_map.json` (defaults 1280×720); world map described as 2560×2160 (2× × 3× of 1280×720).
- **Forge script** (`scripts/forge_room.gd`): resets camera limits to room size (scene defaults 1600×1200 matching `forge_bark_chamber_bg.png`).

### Grep scope

- Game `scenes/` + `scripts/` + `project.godot` hits listing below: **126** lines (raw number matches counted **126**; a line may match multiple of 1280/720/640/360).
- Tests (`tests/`): **16** matching lines (listed as count only).
- Capture / tools (`tools/` + `capture_*.gd`): **15** matching lines (count only).

Searched literals `1280`, `720`, `640`, `360`, and `Vector2(…)` pairs using those values. Skipped huge `tile_data` PackedInt32Array lines (false-positive noise).

| File:line | Snippet | Visual / layout dependency |
|---|---|---|
| `scenes/echo_battle.tscn:153` | `offset_right = 720.0` | echo_chamber_bg.png / echo battle UI |
| `scenes/echo_battle.tscn:220` | `offset_bottom = 720.0` | echo_chamber_bg.png / echo battle UI |
| `scenes/main.tscn:412` | `points = PackedVector2Array(2000, 1000, 2236.2, 1051.2, 2465, 1115, 2686.2, 1191.2, 2900, 1280)` | layout / positioning tied to base res |
| `scenes/main.tscn:422` | `points = PackedVector2Array(2900, 1280, 3001.2, 1363.8, 3085, 1445, 3151.2, 1523.8, 3200, 1600)` | layout / positioning tied to base res |
| `scenes/main.tscn:552` | `position = Vector2(2900, 1280)` | layout / positioning tied to base res |
| `scenes/main.tscn:782` | `position = Vector2(2900, 1280)` | layout / positioning tied to base res |
| `scenes/main.tscn:2639` | `position = Vector2(640.1413, 2255.6871)` | layout / positioning tied to base res |
| `scenes/main.tscn:8116` | `position = Vector2(1488.0384, 640.0939)` | layout / positioning tied to base res |
| `scenes/main.tscn:9470` | `position = Vector2(720.0165, 1157.2307)` | layout / positioning tied to base res |
| `scenes/main.tscn:12126` | `position = Vector2(2520, 720)` | layout / positioning tied to base res |
| `scenes/forge_room.tscn:49` | `polygon = PackedVector2Array(880.0, 1161.0, 974.0, 1005.0, 1043.0, 994.0, 1118.0, 971.0, 1200.0, 935.0, 1293.0, 884.0, 1371.0, 805.0, 1411.0, 705.0, 1379.0, ...` | forge_bark_chamber_bg / forge camera |
| `scenes/forge_room.tscn:52` | `position = Vector2(500, 640)` | layout / positioning tied to base res |
| `scenes/forge_room.tscn:64` | `position = Vector2(1100, 640)` | layout / positioning tied to base res |
| `scenes/forge_room.tscn:109` | `offset_right = 360.0` | layout / positioning tied to base res |
| `scenes/forge_room.tscn:117` | `offset_right = 360.0` | layout / positioning tied to base res |
| `scenes/hud.tscn:488` | `custom_minimum_size = Vector2(720, 500)` | HUD panels / character sheet / menus |
| `scenes/hud.tscn:494` | `offset_left = -360.0` | HUD panels / character sheet / menus |
| `scenes/hud.tscn:496` | `offset_right = 360.0` | HUD panels / character sheet / menus |
| `scenes/hud.tscn:610` | `custom_minimum_size = Vector2(640, 540)` | HUD panels / character sheet / menus |
| `scenes/hud.tscn:633` | `offset_right = 360.0` | HUD panels / character sheet / menus |
| `scenes/hud.tscn:702` | `custom_minimum_size = Vector2(640, 540)` | HUD panels / character sheet / menus |
| `scenes/hud.tscn:813` | `offset_bottom = 360.0` | HUD panels / character sheet / menus |
| `scenes/ui/batch_panel.tscn:6` | `offset_right = 360.0` | layout / positioning tied to base res |
| `scenes/battle/battle_scene.tscn:26` | `offset_left = -640.0` | battle arena / battle UI layout |
| `scenes/battle/battle_scene.tscn:27` | `offset_top = -360.0` | battle arena / battle UI layout |
| `scenes/battle/battle_scene.tscn:28` | `offset_right = 640.0` | battle arena / battle UI layout |
| `scenes/battle/battle_scene.tscn:29` | `offset_bottom = 360.0` | battle arena / battle UI layout |
| `scripts/character_sheet.gd:363` | `mid.size = Vector2(360, 600)` | layout / positioning tied to base res |
| `scripts/character_sheet.gd:369` | `gear_title.size = Vector2(360, 22)` | layout / positioning tied to base res |
| `scripts/character_sheet.gd:377` | `gear_hint.size = Vector2(360, 30)` | layout / positioning tied to base res |
| `scripts/character_sheet.gd:383` | `persist.size = Vector2(360, 16)` | layout / positioning tied to base res |
| `scripts/character_sheet.gd:391` | `tabs.size = Vector2(360, 28)` | layout / positioning tied to base res |
| `scripts/character_sheet.gd:415` | `scroll.size = Vector2(360, 480)` | layout / positioning tied to base res |
| `scripts/character_sheet.gd:429` | `right.size = Vector2(360, 620)` | layout / positioning tied to base res |
| `scripts/character_sheet.gd:435` | `stats_title.size = Vector2(360, 22)` | layout / positioning tied to base res |
| `scripts/character_sheet.gd:444` | `stats_hint.size = Vector2(360, 20)` | layout / positioning tied to base res |
| `scripts/character_sheet.gd:455` | `trait_row.size = Vector2(360, 28)` | layout / positioning tied to base res |
| `scripts/character_sheet.gd:491` | `block.size = Vector2(360, STAT_STRIDE)` | layout / positioning tied to base res |
| `scripts/character_sheet.gd:514` | `fate_note.size = Vector2(360, 0)` | layout / positioning tied to base res |
| `scripts/character_sheet.gd:534` | `host.size = Vector2(360, row_h)` | layout / positioning tied to base res |
| `scripts/character_sheet.gd:768` | `var panel_size := Vector2(360, 220)` | layout / positioning tied to base res |
| `scripts/forge_room.gd:576` | `var view := Vector2(1280, 720)` | forge_bark_chamber_bg / forge camera |
| `scripts/wisp.gd:268` | `## Same phase for every wisp. Slots are 360/n and jump when the count changes.` | layout / positioning tied to base res |
| `scripts/pass_f_playthrough.gd:199` | `var berry_zoom: float = 720.0 / berry_frame.size.x` | layout / positioning tied to base res |
| `scripts/pass_f_playthrough.gd:201` | `var berry_view: SubViewport = _make_view(main, berry_frame, berry_zoom, berry_h, 720)` | project viewport / camera half-view |
| `scripts/pass_f_playthrough.gd:398` | `var plate_ok: bool = art != null and art.visible and art.texture != null and art.texture.get_width() == 1280 and art.texture.get_height() == 720` | layout / positioning tied to base res |
| `scripts/pass_f_playthrough.gd:755` | `for deg: int in range(360):` | layout / positioning tied to base res |
| `scripts/echo_battle_view.gd:10` | `const COMMAND_SIZE: Vector2 = Vector2(720, 120)` | echo_chamber_bg.png / echo battle UI |
| `scripts/echo_battle_view.gd:19` | `## Opaque 1280×720 plate. Background + Ground stay underneath until this file exists.` | echo_chamber_bg.png / echo battle UI |
| `scripts/pause_menu.gd:136` | `var next_y: float = 360.0` | layout / positioning tied to base res |
| `scripts/forest_prop.gd:130` | `_glow_phase = float((int(position.x) * 13 + int(position.y) * 7) % 360) * 0.02` | layout / positioning tied to base res |
| `scripts/hud.gd:96` | `## Art lock ASCENSION_SHOP_LAYOUT_V01: 720×500, header 64 / list flex / footer 72, row 48.` | HUD panels / character sheet / menus |
| `scripts/hud.gd:97` | `const SHOP_SIZE: Vector2 = Vector2(720, 500)` | HUD panels / character sheet / menus |
| `scripts/hud.gd:98` | `const SHOP_MIN_SIZE: Vector2 = Vector2(640, 420)` | HUD panels / character sheet / menus |
| `scripts/hud.gd:1711` | `_ancient_confirm.size = Vector2(720, 300)` | HUD panels / character sheet / menus |
| `scripts/hud.gd:1759` | `_frozen_hint.position = Vector2(360, 322)` | HUD panels / character sheet / menus |
| `scripts/hud.gd:2999` | `dialog.size = Vector2(720, 360)` | HUD panels / character sheet / menus |
| `scripts/main.gd:2` | `## Forest hub 2560×2160 (2× × 3× of 1280×720): arrow-key camera, RTS LMB/RMB, wisps.` | Camera2D limits |
| `scripts/main.gd:30` | `var view_size: Vector2 = Vector2(1280, 720)` | project viewport / camera half-view |
| `scripts/main.gd:135` | `float(hub_map.get("viewport_width", 1280)),` | project viewport / camera half-view |
| `scripts/main.gd:136` | `float(hub_map.get("viewport_height", 720))` | project viewport / camera half-view |
| `scripts/main.gd:193` | `manatree.position = _vec2_from(marks.get("manatree", [1280, 1000]))` | hub mark default (manatree position) |
| `scripts/main.gd:684` | `rad = maxf(rad, 360.0)` | layout / positioning tied to base res |
| `scripts/verify_headless.gd:1294` | `failed += _assert(typeof(anc_size) == TYPE_ARRAY and int((anc_size as Array)[0]) == 512 and int((anc_size as Array)[1]) == 640, "ancient size 512x640")` | layout / positioning tied to base res |
| `scripts/verify_headless.gd:2621` | `failed += _assert(abs(shop_sz.x - 720.0) < 1.5 and abs(shop_sz.y - 500.0) < 1.5, "shop 720x500 (got %s)" % shop_sz)` | layout / positioning tied to base res |
| `scripts/verify_headless.gd:2624` | `failed += _assert(shop_sz.x + 0.1 >= 640.0 and shop_sz.y + 0.1 >= 420.0, "shop meets min 640x420")` | layout / positioning tied to base res |
| `scripts/verify_headless.gd:3848` | `failed += _assert(abs(csize.x - 720.0) < 0.5 and abs(csize.y - 120.0) < 0.5, "command band 720x120")` | layout / positioning tied to base res |
| `scripts/verify_headless.gd:5187` | `failed += _assert(floor[floor.size() - 1].distance_to(Vector2(720, 1161)) < 0.5, "west door point is x720 y1161")` | layout / positioning tied to base res |
| `scripts/verify_headless.gd:6664` | `_place_actor(game_state, "elaia", "clearing", Vector2(640, 640))` | layout / positioning tied to base res |
| `scripts/verify_headless.gd:8752` | `for _step: int in 360:` | layout / positioning tied to base res |
| `scripts/verify_headless.gd:8894` | `for _step: int in 360:` | layout / positioning tied to base res |
| `scripts/verify_headless.gd:8970` | `reach.call("advance_clock", 720.0 - float(reach.get("room_clock")) + 0.001)` | layout / positioning tied to base res |
| `scripts/verify_headless.gd:9145` | `reach.call("advance_clock", 720.0 - float(reach.get("room_clock")) + 0.001)` | layout / positioning tied to base res |
| `scripts/verify_headless.gd:14008` | `failed += _assert(party_front.position + half == Vector2(300, 360) and beast_back.position + half == Vector2(1176, 360), "slot marks sit on the v7 sole points")` | layout / positioning tied to base res |
| `scripts/verify_headless.gd:14465` | `failed += _assert(bottom.get_rect() == Rect2(0, 584, 1280, 136), "bottom bar rect in the arena (got %s)" % bottom.get_rect())` | battle arena / battle UI layout |
| `scripts/verify_headless.gd:16033` | `reach.call("advance_clock", 720.0)` | layout / positioning tied to base res |
| `scripts/verify_headless.gd:16054` | `reach.call("advance_clock", 720.0)` | layout / positioning tied to base res |
| `scripts/verify_headless.gd:16065` | `reach.call("advance_clock", 720.0)` | layout / positioning tied to base res |
| `scripts/verify_headless.gd:16125` | `reach.call("advance_clock", 3.0 * 720.0)` | layout / positioning tied to base res |
| `scripts/verify_headless.gd:16146` | `reach.call("advance_clock", 720.0)` | layout / positioning tied to base res |
| `scripts/verify_headless.gd:16150` | `reach.call("advance_clock", 720.0)` | layout / positioning tied to base res |
| `scripts/verify_headless.gd:16152` | `reach.call("advance_clock", 720.0)` | layout / positioning tied to base res |
| `scripts/verify_headless.gd:16156` | `reach.call("advance_clock", 720.0)` | layout / positioning tied to base res |
| `scripts/verify_headless.gd:16160` | `reach.call("advance_clock", 720.0)` | layout / positioning tied to base res |
| `scripts/verify_headless.gd:16187` | `reach.call("advance_clock", 720.0)` | layout / positioning tied to base res |
| `scripts/verify_headless.gd:16192` | `reach.call("advance_clock", 720.0)` | layout / positioning tied to base res |
| `scripts/verify_headless.gd:16206` | `reach.call("advance_clock", 720.0 * 5.0)` | layout / positioning tied to base res |
| `scripts/verify_headless.gd:16228` | `reach.call("advance_clock", 720.0)` | layout / positioning tied to base res |
| `scripts/verify_headless.gd:16235` | `reach.call("advance_clock", 720.0)` | layout / positioning tied to base res |
| `scripts/verify_headless.gd:16918` | `reach.call("advance_clock", 720.0)` | layout / positioning tied to base res |
| `scripts/verify_headless.gd:16928` | `reach.call("advance_clock", 720.0)` | layout / positioning tied to base res |
| `scripts/verify_headless.gd:16941` | `reach.call("advance_clock", 720.0)` | layout / positioning tied to base res |
| `scripts/verify_headless.gd:17080` | `reach.call("advance_clock", 720.0)` | layout / positioning tied to base res |
| `scripts/verify_headless.gd:17199` | `reach.call("advance_clock", 720.0)` | layout / positioning tied to base res |
| `scripts/verify_headless.gd:17400` | `reach.call("advance_clock", 720.0)` | layout / positioning tied to base res |
| `scripts/verify_headless.gd:17746` | `failed += _assert(used <= 10.0 * 720.0 + 1.0 and used + 1.0 >= 10.0 * 720.0, "seconds_used is 10 slots (got %s)" % used)` | layout / positioning tied to base res |
| `scripts/verify_headless.gd:17757` | `reach.call("advance_clock", 720.0)` | layout / positioning tied to base res |
| `scripts/verify_headless.gd:17790` | `reach.call("catch_up", 40.0 * 720.0, "load")` | layout / positioning tied to base res |
| `scripts/verify_headless.gd:17887` | `reach.call("process_frame_delta", 3.0 * 720.0)` | layout / positioning tied to base res |
| `scripts/verify_headless.gd:18257` | `reach.call("advance_clock", 720.0)` | layout / positioning tied to base res |
| `scripts/verify_headless.gd:18263` | `reach.call("advance_clock", 720.0)` | layout / positioning tied to base res |
| `scripts/verify_headless.gd:18264` | `reach.call("advance_clock", 720.0)` | layout / positioning tied to base res |
| `scripts/verify_headless.gd:18265` | `reach.call("advance_clock", 720.0)` | layout / positioning tied to base res |
| `scripts/verify_headless.gd:18317` | `reach.call("advance_clock", 720.0)` | layout / positioning tied to base res |
| `scripts/verify_headless.gd:18344` | `reach.call("advance_clock", 720.0)` | layout / positioning tied to base res |
| `scripts/verify_headless.gd:18782` | `reach.call("advance_clock", 720.0)` | layout / positioning tied to base res |
| `scripts/verify_headless.gd:19108` | `reach.call("advance_clock", 720.0)` | layout / positioning tied to base res |
| `scripts/hud_icons.gd:4` | `## Nearest-neighbor only. The 1280×512 sheet is no longer read.` | HUD panels / character sheet / menus |
| `scripts/playtest_ship.gd:272` | `"run_time_sec": 640.0,` | layout / positioning tied to base res |
| `scripts/playtest_ship.gd:547` | `await _wait_arrive(keeper, rune.global_position, 360)` | layout / positioning tied to base res |
| `scripts/playtest_ship.gd:840` | `win.size = Vector2i(1280, 720)` | layout / positioning tied to base res |
| `scripts/playtest_ship.gd:845` | `await _tooltip_check("5 tooltip at 1280")` | layout / positioning tied to base res |
| `scripts/playtest_ship.gd:852` | `win.size = Vector2i(1280, 720)` | layout / positioning tied to base res |
| `scripts/polish_smoke.gd:76` | `_check_corner_forest("1280")` | layout / positioning tied to base res |
| `scripts/autoload/reach.gd:15` | `const ROOM_SEC: float = 720.0` | layout / positioning tied to base res |
| `scripts/battle/battle_view.gd:14` | `const ARENA_SIZE: Vector2 = Vector2(1280.0, 720.0)` | battle arena / battle UI layout |
| `scripts/battle/battle_view.gd:22` | `"party_front": [Vector2(300, 360), Vector2(380, 424), Vector2(300, 536)],` | battle arena / battle UI layout |
| `scripts/battle/battle_view.gd:23` | `"party_back": [Vector2(80, 360), Vector2(160, 424), Vector2(80, 536)],` | battle arena / battle UI layout |
| `scripts/battle/battle_view.gd:24` | `"beast_front": [Vector2(920, 360), Vector2(792, 424), Vector2(920, 536)],` | battle arena / battle UI layout |
| `scripts/battle/battle_view.gd:25` | `"beast_back": [Vector2(1176, 360), Vector2(1048, 424), Vector2(1176, 536)],` | battle arena / battle UI layout |
| `scripts/battle/battle_view.gd:156` | `const BOTTOM_BAR_RECT: Rect2 = Rect2(0.0, 584.0, 1280.0, 136.0)` | battle arena / battle UI layout |
| `scripts/battle/slot_engine.gd:6` | `const ROOM_SEC: float = 720.0` | battle arena / battle UI layout |
| `project.godot:31` | `window/size/viewport_width=1280` | project viewport / camera half-view |
| `project.godot:32` | `window/size/viewport_height=720` | project viewport / camera half-view |
| `project.godot:33` | `window/size/window_width_override=1280` | project.godot display stretch |
| `project.godot:34` | `window/size/window_height_override=720` | project.godot display stretch |

## Top 10 layout hot spots (for 960×540)

| # | Location | Value / size | Visual / system |
|---:|---|---|---|
| 1 | `project.godot` `[display]` | viewport + override **1280×720**; stretch `canvas_items` / `expand` | Global base resolution |
| 2 | `scripts/battle/battle_view.gd` `ARENA_SIZE` + slot `Vector2`s | **1280×720**; party/beast slots use y=**360** and x up to **1176** | Battle arena + fighter placement vs `arena_forest_bg_*.png` / FG |
| 3 | `scripts/battle/battle_view.gd` `BOTTOM_BAR_RECT` + `bottom_panel_1280x136.png` | Rect **(0,584,1280,136)**; art **1280×136** | Battle bottom action bar (must redraw/reflow) |
| 4 | `scenes/battle/battle_scene.tscn` root offsets | **±640 / ±360** (centered 1280×720) | Battle scene full-screen frame |
| 5 | `assets/art/title/titlescreen.png` + `title_screen.tscn` `Background` | art **1248×832** | Title painting full-bleed |
| 6 | `assets/art/echo/echo_chamber_bg.png` (`CHAMBER_BG`) | art **1280×720** | Echo chamber full-screen BG |
| 7 | `assets/art/forge/forge_bark_chamber_bg.png` + Forge `Camera2D` | art **1600×1200**; limits **0..1600 × 0..1200** | Forge room plate / camera |
| 8 | `scripts/main.gd` `view_size` + hub `Camera2D` limits | **Vector2(1280, 720)**; limits **180..4140 × 180..3600** | Hub camera half-view math vs world map |
| 9 | `scripts/hud.gd` `SHOP_SIZE` / confirm dialogs + `scenes/hud.tscn` | **720×500**, min **640×420**; frozen hint at **(360,322)** | HUD shop / modal panels |
| 10 | `assets/art/ui/minigames/kit/frame_720x448.png` + expedition shell | art **720×448** | Adventure board / minigame frame chrome |

Also watch: arena FG `1600×900` (`arena_forest_fg.png`); battle plates/bars authored for the 1280-wide chrome set under `assets/art/battle/ui/`.

---

*Generated read-only from `/workspace/pr33_local` after `git pull -q --rebase` on `feat/battle-bundle-2-data`. No project files were modified.*
