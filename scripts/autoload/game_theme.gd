extends Node
## Project-wide Silver / Jersey 10 theme and 2× game cursor for 540p base resolution.

const SILVER_PATH: String = "res://assets/fonts/Silver.ttf"
const JERSEY_PATH: String = "res://assets/fonts/Jersey10-Regular.ttf"
const CURSOR_TEX: String = "res://assets/art/ui/icon_manashards.png"
const BODY_SIZE: int = 19
const TITLE_SIZE: int = 37
const PLANK_SIZE: int = 19
const TITLE_HERO_SIZE: int = 38
const CURSOR_SCALE: float = 2.0

var _silver: FontFile
var _jersey: FontFile
var _theme: Theme


func _ready() -> void:
	_silver = _load_font(SILVER_PATH)
	_jersey = _load_font(JERSEY_PATH)
	_theme = Theme.new()
	_apply_font_defaults(_theme)
	_apply_mouse_cursor()
	call_deferred("apply_app_theme")


func _load_font(path: String) -> FontFile:
	var file: FontFile = load(path) as FontFile
	if file == null:
		push_warning("GameTheme: missing font %s" % path)
		return FontFile.new()
	file.antialiasing = TextServer.FONT_ANTIALIASING_NONE
	file.hinting = TextServer.HINTING_NONE
	file.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
	return file


func _apply_font_defaults(theme: Theme) -> void:
	var body: Font = _silver
	theme.default_font = body
	theme.default_font_size = BODY_SIZE
	theme.set_font_size(&"font", &"Label", BODY_SIZE)
	theme.set_font(&"font", &"Label", body)
	theme.set_font_size(&"font", &"Button", BODY_SIZE)
	theme.set_font(&"font", &"Button", body)
	theme.set_font_size(&"font", &"RichTextLabel", BODY_SIZE)
	theme.set_font(&"font", &"RichTextLabel", body)


func apply_app_theme() -> void:
	var tree: SceneTree = get_tree()
	if tree == null:
		return
	tree.root.theme = _theme


func body_font() -> Font:
	return _silver


func title_font() -> Font:
	return _jersey


func jersey_plank_size() -> int:
	return PLANK_SIZE


func jersey_title_size() -> int:
	return TITLE_SIZE


func silver_body_size() -> int:
	return BODY_SIZE


func silver_hero_size() -> int:
	return TITLE_HERO_SIZE


func style_primary_button(btn: Button) -> void:
	btn.add_theme_font_override("font", _silver_embolden())
	btn.add_theme_font_size_override("font_size", BODY_SIZE)


func style_title_hero_button(btn: Button) -> void:
	btn.add_theme_font_override("font", _silver)
	btn.add_theme_font_size_override("font_size", TITLE_HERO_SIZE)


func style_title_label(lbl: Label) -> void:
	lbl.add_theme_font_override("font", _jersey)
	lbl.add_theme_font_size_override("font_size", TITLE_SIZE)


func style_plank_label(lbl: Label) -> void:
	lbl.add_theme_font_override("font", _jersey)
	lbl.add_theme_font_size_override("font_size", PLANK_SIZE)


func _silver_embolden() -> Font:
	var fv := FontVariation.new()
	fv.base_font = _silver
	fv.variation_embolden = 1.35
	return fv


func _apply_mouse_cursor() -> void:
	if DisplayServer.get_name() == "headless":
		return
	var tex: Texture2D = load(CURSOR_TEX) as Texture2D
	if tex == null:
		return
	var img: Image = tex.get_image()
	if img == null or img.is_empty():
		return
	var w: int = img.get_width()
	var h: int = img.get_height()
	img.resize(w * int(CURSOR_SCALE), h * int(CURSOR_SCALE), Image.INTERPOLATE_NEAREST)
	var big := ImageTexture.create_from_image(img)
	var hotspot := Vector2(float(w), float(h)) * 0.5
	Input.set_custom_mouse_cursor(big, Input.CURSOR_ARROW, hotspot)
	Input.set_custom_mouse_cursor(big, Input.CURSOR_IBEAM, hotspot)
	Input.set_custom_mouse_cursor(big, Input.CURSOR_POINTING_HAND, hotspot)
