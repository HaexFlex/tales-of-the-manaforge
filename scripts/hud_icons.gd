class_name HudIcons
extends RefCounted
## Single 32×32 HUD icons. Cell order matches the old sheet (left to right, then the next row).
## Nearest-neighbor only. The 1280×512 sheet is no longer read.

const CELL_PATHS: PackedStringArray = [
	"res://assets/art/ui/icons/hud_character.png",
	"res://assets/art/ui/icons/hud_help.png",
	"res://assets/art/ui/icons/hud_ascension.png",
	"res://assets/art/ui/icons/hud_keep_tools.png",
	"res://assets/art/ui/icons/hud_wooden_basket.png",
	"res://assets/art/ui/icons/hud_watering_can.png",
	"res://assets/art/ui/icons/hud_stone_sword_old.png",
	"res://assets/art/ui/icons/icon_weapon_rod.png",
	"res://assets/art/ui/icons/hud_equip_empty.png",
	"res://assets/art/ui/icons/hud_equip_locked.png",
]

const CHARACTER: int = 0
const HELP: int = 1
const ASCENSION: int = 2
const KEEP_TOOLS: int = 3
const WOODEN_BASKET: int = 4
const WATERING_CAN: int = 5
## Cell 6 is the old sword art. Flintblade resolves through art_name instead.
const STONE_SWORD: int = 6
const WEAPON_ROD: int = 7
const EQUIP_EMPTY: int = 8
const EQUIP_LOCKED: int = 9

static var _cache: Dictionary = {}


static func path_for(index: int) -> String:
	if index < 0 or index >= CELL_PATHS.size():
		return ""
	return CELL_PATHS[index]


static func cell(index: int) -> Texture2D:
	if _cache.has(index):
		return _cache[index] as Texture2D
	var path: String = path_for(index)
	var tex: Texture2D = load(path) as Texture2D if path != "" else null
	_cache[index] = tex
	return tex


static func index_for_item(item_id: String) -> int:
	match item_id:
		"wooden_basket":
			return WOODEN_BASKET
		"stone_watering_can":
			return WATERING_CAN
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
