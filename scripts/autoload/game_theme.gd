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
const SAFE_MARGIN_PX: float = 24.0
const TAP_MIN_PX: float = 24.0

var _silver: FontFile
var _jersey: FontFile
var _theme: Theme
var _tree_hooked: bool = false


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
	for kind: StringName in [&"Label", &"Button", &"RichTextLabel", &"CheckBox", &"LineEdit", &"SpinBox", &"TabBar"]:
		theme.set_font_size(&"font", kind, BODY_SIZE)
		theme.set_font(&"font", kind, body)
	theme.set_font(&"font", &"Button", _silver_embolden())


func apply_app_theme() -> void:
	var tree: SceneTree = get_tree()
	if tree == null:
		return
	tree.root.theme = _theme
	if not _tree_hooked:
		_tree_hooked = true
		tree.node_added.connect(_on_node_added)
	sweep_theme(tree.root)


func _on_node_added(node: Node) -> void:
	if node is Control:
		apply_control_theme(node as Control)


func sweep_theme(root: Node) -> void:
	if root is Control:
		apply_control_theme(root as Control)
	for child: Node in root.get_children():
		sweep_theme(child)


func apply_control_theme(ctrl: Control) -> void:
	if ctrl is ScrollContainer and has_node("/root/GameInput"):
		GameInput.configure_scroll_container(ctrl as ScrollContainer)
	_ensure_tap_target(ctrl)
	if ctrl is Button:
		if ctrl.is_in_group("title_hero_button"):
			style_title_hero_button(ctrl as Button)
		else:
			style_primary_button(ctrl as Button)
		return
	if ctrl is Label:
		_style_label(ctrl as Label)


func _style_label(lbl: Label) -> void:
	var name_l: String = lbl.name.to_lower()
	var size_override: int = lbl.get_theme_font_size("font_size")
	if name_l.find("title") >= 0 and size_override >= 28:
		style_title_label(lbl)
	elif name_l.find("title") >= 0 or name_l.find("header") >= 0 or name_l.find("subtitle") >= 0:
		style_plank_label(lbl)
	else:
		lbl.add_theme_font_override("font", _silver)
		lbl.add_theme_font_size_override("font_size", BODY_SIZE)


func _ensure_tap_target(ctrl: Control) -> void:
	if not (ctrl is BaseButton):
		return
	var btn: BaseButton = ctrl as BaseButton
	if btn.mouse_filter == Control.MOUSE_FILTER_IGNORE:
		return
	var min_sz: Vector2 = btn.custom_minimum_size
	if min_sz.x < TAP_MIN_PX or min_sz.y < TAP_MIN_PX:
		btn.custom_minimum_size = Vector2(maxf(min_sz.x, TAP_MIN_PX), maxf(min_sz.y, TAP_MIN_PX))


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


func style_body_label(lbl: Label) -> void:
	lbl.add_theme_font_override("font", _silver)
	lbl.add_theme_font_size_override("font_size", BODY_SIZE)


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
