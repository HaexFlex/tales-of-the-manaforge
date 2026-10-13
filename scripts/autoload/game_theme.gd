extends Node
## Loads the kit Theme resource and keeps shared 540p font/size helpers for VERIFY.

const THEME_PATH: String = "res://assets/ui/manaforge_theme.tres"
const POINTER_PATH: String = "res://assets/ui/theme/pointer_12x17.png"
const BODY_FONT_PATH: String = "res://assets/fonts/font_body_silver19.tres"
const PRIMARY_FONT_PATH: String = "res://assets/fonts/font_primary_silver38_bold.tres"
const TITLE_FONT_PATH: String = "res://assets/fonts/font_title_jersey30.tres"
const INK: Color = Color8(62, 42, 24)
const MUTED: Color = Color8(90, 62, 40)
const SAFE_MARGIN_PX: float = 24.0
const TAP_MIN_PX: float = 44.0
const BODY_SIZE: int = 19
const TITLE_SIZE: int = 37
const PLANK_SIZE: int = 19
const TITLE_HERO_SIZE: int = 38

var _theme: Theme
var _body_font: Font
var _primary_font: Font
var _title_font: Font
var _tree_hooked: bool = false


func _ready() -> void:
	_theme = load(THEME_PATH) as Theme
	_body_font = load(BODY_FONT_PATH) as Font
	_primary_font = load(PRIMARY_FONT_PATH) as Font
	_title_font = load(TITLE_FONT_PATH) as Font
	_apply_mouse_cursor()
	call_deferred("apply_app_theme")


func apply_app_theme() -> void:
	var tree: SceneTree = get_tree()
	if tree == null or _theme == null:
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
	return _body_font


func title_font() -> Font:
	return _title_font


func jersey_plank_size() -> int:
	return PLANK_SIZE


func jersey_title_size() -> int:
	return TITLE_SIZE


func silver_body_size() -> int:
	return BODY_SIZE


func silver_hero_size() -> int:
	return TITLE_HERO_SIZE


func style_primary_button(btn: Button) -> void:
	btn.theme_type_variation = &"PrimaryButton"


func style_title_hero_button(btn: Button) -> void:
	btn.add_theme_font_override("font", _primary_font)
	btn.add_theme_font_size_override("font_size", TITLE_HERO_SIZE)


func style_title_label(lbl: Label) -> void:
	lbl.theme_type_variation = &"TitlePlank"


func style_plank_label(lbl: Label) -> void:
	lbl.add_theme_font_override("font", _title_font)
	lbl.add_theme_font_size_override("font_size", PLANK_SIZE)


func style_body_label(lbl: Label) -> void:
	lbl.add_theme_font_override("font", _body_font)
	lbl.add_theme_font_size_override("font_size", BODY_SIZE)


func _apply_mouse_cursor() -> void:
	if DisplayServer.get_name() == "headless":
		return
	var tex: Texture2D = load(POINTER_PATH) as Texture2D
	if tex == null:
		return
	Input.set_custom_mouse_cursor(tex, Input.CURSOR_ARROW, Vector2.ZERO)
	Input.set_custom_mouse_cursor(tex, Input.CURSOR_IBEAM, Vector2.ZERO)
	Input.set_custom_mouse_cursor(tex, Input.CURSOR_POINTING_HAND, Vector2.ZERO)
