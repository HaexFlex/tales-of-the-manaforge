class_name HudIcons
extends RefCounted
## Atlas slices of manaforge_hud_icons_sheet.png (1280×512, 5×2 cells of 256).
## Cell order is left to right, then the next row. Nearest-neighbor only.

const SHEET_PATH: String = "res://assets/art/ui/manaforge_hud_icons_sheet.png"
const CELL: int = 256
const COLS: int = 5

const CHARACTER: int = 0
const HELP: int = 1
const ASCENSION: int = 2
const KEEP_TOOLS: int = 3
const WOODEN_BASKET: int = 4
const WATERING_CAN: int = 5
const STONE_SWORD: int = 6
const WEAPON_ROD: int = 7
const EQUIP_EMPTY: int = 8
const EQUIP_LOCKED: int = 9

static var _sheet: Texture2D
static var _cache: Dictionary = {}


static func sheet() -> Texture2D:
	if _sheet == null:
		_sheet = load(SHEET_PATH) as Texture2D
	return _sheet


static func cell(index: int) -> AtlasTexture:
	if _cache.has(index):
		return _cache[index] as AtlasTexture
	var atlas := AtlasTexture.new()
	atlas.atlas = sheet()
	var col: int = posmod(index, COLS)
	var row: int = int(index / COLS)
	atlas.region = Rect2(col * CELL, row * CELL, CELL, CELL)
	atlas.filter_clip = true
	_cache[index] = atlas
	return atlas


static func index_for_item(item_id: String) -> int:
	match item_id:
		"wooden_basket":
			return WOODEN_BASKET
		"stone_watering_can":
			return WATERING_CAN
		"stone_sword":
			return STONE_SWORD
		"weapon_rod":
			return WEAPON_ROD
		_:
			return -1


static func apply(rect: TextureRect, index: int) -> void:
	rect.texture = cell(index)
	rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE


static func make_icon(index: int, icon_size: Vector2 = Vector2(32, 32)) -> TextureRect:
	var icon := TextureRect.new()
	icon.custom_minimum_size = icon_size
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	apply(icon, index)
	return icon


static func icon_or_swatch(item_id: String, fallback: Color) -> Control:
	var index: int = index_for_item(item_id)
	if index < 0:
		var swatch := ColorRect.new()
		swatch.custom_minimum_size = Vector2(32, 32)
		swatch.color = fallback
		swatch.mouse_filter = Control.MOUSE_FILTER_IGNORE
		return swatch
	return make_icon(index)
