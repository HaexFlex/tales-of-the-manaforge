extends Node
## Loads the kit Theme resource and keeps shared 540p font/size helpers for VERIFY.

const THEME_PATH: String = "res://assets/ui/manaforge_theme.tres"
const POINTER_PATH: String = "res://assets/ui/theme/pointer_12x17.png"
const BODY_FONT_PATH: String = "res://assets/fonts/font_body_silver19.tres"
const PRIMARY_FONT_PATH: String = "res://assets/fonts/font_primary_silver38_bold.tres"
const TITLE_FONT_PATH: String = "res://assets/fonts/font_title_jersey30.tres"
const INK: Color = Color8(62, 42, 24)
const MUTED: Color = Color8(90, 62, 40)
const CREAM_BTN: Color = Color8(243, 230, 200)
const OUTLINE: Color = Color8(26, 15, 8)
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
	WorldHover.install()
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
	if node is Window and node != get_tree().root:
		# Theme immediately so the first draw is not the engine square.
		# Seat after popup(), which runs once add_child returns.
		_apply_window_theme(node, false)
		call_deferred("_apply_window_theme_id", node.get_instance_id(), true)


func _apply_window_theme_id(id: int, seat: bool) -> void:
	var found: Object = instance_from_id(id)
	if found == null or not is_instance_valid(found):
		return
	_apply_window_theme(found as Node, seat)


func _apply_window_theme(node: Node, seat: bool) -> void:
	var win: Window = node as Window
	if win == null or not is_instance_valid(win) or win == get_tree().root:
		return
	if _is_debug_only(win):
		return
	if _theme != null and win.theme != _theme:
		win.theme = _theme
	if not seat or not (win is PopupPanel):
		return
	var pop: PopupPanel = win as PopupPanel
	if pop.theme_type_variation != &"TooltipPanel" or not pop.visible:
		return
	Ui540.place_tooltip(pop, pop.get_parent() as Control)
	Ui540.fade_in_tooltip(pop)


func _is_debug_only(node: Node) -> bool:
	var cursor: Node = node
	while cursor != null:
		var scr: Script = cursor.get_script() as Script
		if scr != null and str(scr.resource_path).find("tools/debug/") >= 0:
			return true
		cursor = cursor.get_parent()
	return false


func sweep_theme(root: Node) -> void:
	# Windows already in the tree (option lists built during _ready) missed node_added.
	if root is Window and root != get_tree().root:
		_apply_window_theme(root, false)
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


## Primary face copied onto the button. The variation alone still draws the engine
## button on some popups; the override is the kit action button at full contrast.
func force_primary_button(btn: Button) -> void:
	style_primary_button(btn)
	if btn == null or _theme == null:
		return
	for state: StringName in [&"normal", &"hover", &"pressed", &"hover_pressed", &"disabled", &"focus"]:
		var box: StyleBox = _theme.get_stylebox(state, &"PrimaryButton")
		if box:
			btn.add_theme_stylebox_override(state, box)
	for state: StringName in [
		&"font_color", &"font_hover_color", &"font_pressed_color",
		&"font_hover_pressed_color", &"font_focus_color", &"font_disabled_color",
	]:
		btn.add_theme_color_override(state, CREAM_BTN)
	btn.add_theme_color_override(&"font_outline_color", OUTLINE)
	btn.add_theme_constant_override(&"outline_size", 2)


func style_title_hero_button(btn: Button) -> void:
	btn.theme_type_variation = &"TitleMenuButton"
	btn.add_theme_font_override("font", _primary_font)
	btn.add_theme_font_size_override("font_size", TITLE_HERO_SIZE)
	for state: StringName in [
		&"font_color", &"font_hover_color", &"font_pressed_color",
		&"font_hover_pressed_color", &"font_focus_color", &"font_disabled_color",
	]:
		btn.add_theme_color_override(state, CREAM_BTN)
	btn.add_theme_color_override(&"font_outline_color", OUTLINE)
	btn.add_theme_constant_override(&"outline_size", 2)


func style_outlined_ink_label(lbl: Label, muted: bool = false) -> void:
	style_body_label(lbl)
	lbl.add_theme_color_override(&"font_color", MUTED if muted else INK)
	lbl.add_theme_color_override(&"font_shadow_color", OUTLINE)
	lbl.add_theme_constant_override(&"shadow_offset_x", 1)
	lbl.add_theme_constant_override(&"shadow_offset_y", 1)


func style_title_label(lbl: Label) -> void:
	lbl.theme_type_variation = &"TitlePlank"


## Window titles: the theme plank (Jersey 10 30, cream on wood). No size override, so the
## plank art and the cap centring from build_theme.gd stay in step.
func style_plank_label(lbl: Label) -> void:
	lbl.theme_type_variation = &"TitlePlank"
	lbl.remove_theme_font_override("font")
	lbl.remove_theme_font_size_override("font_size")
	lbl.remove_theme_color_override("font_color")


func style_body_label(lbl: Label) -> void:
	lbl.add_theme_font_override("font", _body_font)
	lbl.add_theme_font_size_override("font_size", BODY_SIZE)


## Plain parchment text: Silver 19, ink or muted ink, no outline.
func style_ink_label(lbl: Label, muted: bool = false) -> void:
	style_body_label(lbl)
	lbl.add_theme_color_override(&"font_color", MUTED if muted else INK)
	lbl.remove_theme_color_override(&"font_shadow_color")
	lbl.remove_theme_constant_override(&"shadow_offset_x")
	lbl.remove_theme_constant_override(&"shadow_offset_y")


## Parchment headings (section names, item names): Silver 38 ink.
func style_heading_label(lbl: Label) -> void:
	lbl.add_theme_font_override("font", _body_font)
	lbl.add_theme_font_size_override("font_size", TITLE_HERO_SIZE)
	lbl.add_theme_color_override(&"font_color", INK)


## Wood menu button with the Silver 38 caps (pause rows, confirm choices, Back).
func style_menu_button(btn: Button) -> void:
	btn.theme_type_variation = &"BigButton"
	btn.remove_theme_font_override("font")
	btn.remove_theme_font_size_override("font_size")
	for state: StringName in [
		&"font_color", &"font_hover_color", &"font_pressed_color",
		&"font_hover_pressed_color", &"font_focus_color", &"font_disabled_color",
	]:
		btn.remove_theme_color_override(state)


## Wood button with Silver 19 caps (tabs, small actions, list chips).
func style_wood_button(btn: Button) -> void:
	btn.theme_type_variation = &""
	btn.flat = false
	for state: StringName in [&"normal", &"hover", &"pressed", &"hover_pressed", &"disabled", &"focus"]:
		btn.remove_theme_stylebox_override(state)
	for state: StringName in [
		&"font_color", &"font_hover_color", &"font_pressed_color",
		&"font_hover_pressed_color", &"font_focus_color", &"font_disabled_color",
	]:
		btn.remove_theme_color_override(state)
	btn.add_theme_font_override("font", _body_font)
	btn.add_theme_font_size_override("font_size", BODY_SIZE)


## Wood tab: Silver 19 caps, the selected face while pressed.
func style_tab_button(btn: Button) -> void:
	style_wood_button(btn)
	btn.theme_type_variation = &"ToggleButton"
	btn.toggle_mode = true


## Window filter tab (char, bag, workbench): the wood tab with Silver 38 caps.
func style_big_tab_button(btn: Button) -> void:
	style_tab_button(btn)
	btn.add_theme_font_override("font", _primary_font)
	btn.add_theme_font_size_override("font_size", 38)


## Faceless text button sitting on parchment: ink caps.
func style_ink_button(btn: Button) -> void:
	btn.theme_type_variation = &"InkButton"
	btn.flat = false
	for state: StringName in [&"normal", &"hover", &"pressed", &"hover_pressed", &"disabled"]:
		btn.remove_theme_stylebox_override(state)
	for state: StringName in [
		&"font_color", &"font_hover_color", &"font_pressed_color",
		&"font_hover_pressed_color", &"font_focus_color", &"font_disabled_color",
	]:
		btn.remove_theme_color_override(state)


func _apply_mouse_cursor() -> void:
	if DisplayServer.get_name() == "headless":
		return
	var tex: Texture2D = load(POINTER_PATH) as Texture2D
	if tex == null:
		return
	Input.set_custom_mouse_cursor(tex, Input.CURSOR_ARROW, Vector2.ZERO)
	Input.set_custom_mouse_cursor(tex, Input.CURSOR_IBEAM, Vector2.ZERO)
	Input.set_custom_mouse_cursor(tex, Input.CURSOR_POINTING_HAND, Vector2.ZERO)
