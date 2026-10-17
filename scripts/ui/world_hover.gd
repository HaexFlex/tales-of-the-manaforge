class_name WorldHover
extends RefCounted
## One papyrus tooltip for map and world hovers. Control tooltips use the same
## TooltipPanel style. Area2D nodes cannot own a Control tooltip, so this panel
## sits on a canvas layer and follows the pointer.

const THEME_PATH: String = "res://assets/ui/manaforge_theme.tres"
## Mouse rest and a tap-and-hold use this one wait. Control tooltips read the same value.
const REST_SEC: float = 0.8

static var _layer: CanvasLayer
static var _panel: Panel
static var _label: Label
static var _owner_id: int = 0
static var _wait: Timer
static var _pending_source: Node
static var _pending_id: int = 0
static var _pending_text: String = ""


static func sync(source: Node, inside: bool, text: String) -> void:
	if inside:
		present(source, text)
	else:
		dismiss(source)


static func install() -> void:
	ProjectSettings.set_setting("gui/timers/tooltip_delay_sec", REST_SEC)


static func rest_sec() -> float:
	return REST_SEC


static func present(source: Node, text: String) -> void:
	install()
	if _minigame_open():
		hide_for_overlay()
		_clear_pending()
		return
	if source == null or not source.is_inside_tree() or text == "":
		dismiss(source)
		return
	var source_id: int = source.get_instance_id()
	if _owner_id == source_id and _panel != null and is_instance_valid(_panel) and _panel.visible and _label != null and _label.text == text:
		_place_near(_panel, _pointer(source))
		return
	_pending_source = source
	_pending_id = source_id
	_pending_text = text
	if _owner_id != 0 and _owner_id != source_id:
		_owner_id = 0
		if _panel != null and is_instance_valid(_panel):
			_panel.visible = false
	_arm_wait(source)


static func complete_rest() -> void:
	if _wait != null and is_instance_valid(_wait):
		_wait.stop()
	_on_rest()


static func _arm_wait(source: Node) -> void:
	_ensure(source.get_tree())
	if _wait == null or not is_instance_valid(_wait):
		_wait = Timer.new()
		_wait.name = "HoverRest"
		_wait.one_shot = true
		_wait.timeout.connect(_on_rest)
		_layer.add_child(_wait)
	_wait.wait_time = REST_SEC
	_wait.start()


static func _on_rest() -> void:
	if _pending_source == null or not is_instance_valid(_pending_source):
		return
	if _pending_source.get_instance_id() != _pending_id:
		return
	if not _pending_source.is_inside_tree() or _pending_text == "":
		return
	if _minigame_open():
		hide_for_overlay()
		_clear_pending()
		return
	var source: Node = _pending_source
	var text: String = _pending_text
	_clear_pending()
	_reveal(source, text)


static func _clear_pending() -> void:
	_pending_source = null
	_pending_id = 0
	_pending_text = ""
	if _wait != null and is_instance_valid(_wait):
		_wait.stop()


static func _reveal(source: Node, text: String) -> void:
	var panel := _ensure(source.get_tree())
	_owner_id = source.get_instance_id()
	_label.text = text
	var font: Font = _label.get_theme_font(&"font")
	var font_size: int = _label.get_theme_font_size(&"font_size")
	var text_sz := Vector2(80, 19)
	if font != null:
		text_sz = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var box: StyleBox = panel.get_theme_stylebox(&"panel")
	var left: float = 16.0
	var top: float = 10.0
	var right: float = 16.0
	var bottom: float = 10.0
	if box != null:
		left = box.get_content_margin(SIDE_LEFT)
		top = box.get_content_margin(SIDE_TOP)
		right = box.get_content_margin(SIDE_RIGHT)
		bottom = box.get_content_margin(SIDE_BOTTOM)
	## The papyrus is a Panel, not a container, so the line is pinned inside the
	## content margins. A container was leaving the glyphs on the rolled edge.
	_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	_label.position = Vector2(left, top)
	_label.size = text_sz
	var lines: int = maxi(1, text.count("\n") + 1)
	var height: float = maxf(Ui540.TOOLTIP_MIN_H, float(lines) * 20.0 + top + bottom)
	var width: float = maxf(Ui540.TOOLTIP_MIN_W, text_sz.x + left + right)
	panel.size = Vector2(width, height)
	panel.custom_minimum_size = panel.size
	_place_near(panel, _pointer(source))
	panel.visible = true
	Ui540.fade_in_tooltip(panel)


static func _pointer(source: Node) -> Vector2:
	if source.get_viewport():
		return source.get_viewport().get_mouse_position()
	return Vector2.ZERO


static func hide_for_overlay() -> void:
	_clear_pending()
	_owner_id = 0
	if _panel != null and is_instance_valid(_panel):
		_panel.visible = false


static func _minigame_open() -> bool:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null:
		return false
	var host: Node = tree.root.get_node_or_null("MinigameHost")
	return host != null and host.has_method("is_open") and bool(host.call("is_open"))


static func dismiss(source: Node) -> void:
	if source != null and source.get_instance_id() == _pending_id:
		_clear_pending()
	if source != null and source.get_instance_id() != _owner_id:
		return
	_owner_id = 0
	if _panel != null and is_instance_valid(_panel):
		_panel.visible = false


static func current_text() -> String:
	if _label == null or _panel == null or not is_instance_valid(_panel) or not _panel.visible:
		return ""
	return _label.text


static func panel() -> Panel:
	return _panel


## Long-press hint. The caller already waited out the 0.8 s rest. Size is the 3-line scroll.
static func show_anchored_hint(text: String, screen_pos: Vector2, panel_size: Vector2) -> bool:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null or text == "":
		return false
	var panel := _ensure(tree)
	if panel == null or _label == null:
		return false
	_clear_pending()
	_owner_id = 0
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.text = text
	var box: StyleBox = panel.get_theme_stylebox(&"panel")
	var left: float = 16.0
	var top: float = 9.0
	var right: float = 16.0
	var bottom: float = 9.0
	if box != null:
		left = box.get_content_margin(SIDE_LEFT)
		top = box.get_content_margin(SIDE_TOP)
		right = box.get_content_margin(SIDE_RIGHT)
		bottom = box.get_content_margin(SIDE_BOTTOM)
	panel.size = panel_size
	panel.custom_minimum_size = panel_size
	_label.position = Vector2(left, top)
	_label.size = Vector2(maxf(1.0, panel_size.x - left - right), maxf(1.0, panel_size.y - top - bottom))
	_place_near(panel, screen_pos)
	panel.visible = true
	Ui540.fade_in_tooltip(panel)
	return true


static func dismiss_hold() -> void:
	_owner_id = 0
	_clear_pending()
	if _panel != null and is_instance_valid(_panel):
		_panel.visible = false


static func shutdown() -> void:
	_owner_id = 0
	_clear_pending()
	_wait = null
	if _layer != null and is_instance_valid(_layer):
		_layer.queue_free()
	_layer = null
	_panel = null
	_label = null


static func _ensure(tree: SceneTree) -> Panel:
	if _panel != null and is_instance_valid(_panel):
		return _panel
	_layer = CanvasLayer.new()
	_layer.name = "WorldHoverLayer"
	_layer.layer = 120
	_panel = Panel.new()
	_panel.name = "WorldHoverTip"
	_panel.theme = load(THEME_PATH) as Theme
	_panel.theme_type_variation = &"TooltipPanel"
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.visible = false
	_label = Label.new()
	_label.name = "Text"
	_label.theme = _panel.theme
	_label.theme_type_variation = &"TooltipLabel"
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(_label)
	_layer.add_child(_panel)
	tree.root.add_child(_layer)
	return _panel


static func _place_near(panel: Control, screen_pos: Vector2) -> void:
	var sz: Vector2 = panel.size
	if sz.y < Ui540.TOOLTIP_MIN_H:
		sz.y = Ui540.TOOLTIP_MIN_H
		panel.size = sz
	var vs: Vector2 = Ui540.viewport_size()
	## Sit clear of the cursor so the panel does not steal the hover.
	var below: float = screen_pos.y + 20.0 + Ui540.TOOLTIP_GAP_PX
	var above: float = screen_pos.y - 20.0 - Ui540.TOOLTIP_GAP_PX - sz.y
	var y: float = below
	var left: float = Ui540.margin_left()
	var top: float = Ui540.margin_top()
	var right: float = Ui540.margin_right()
	var bottom: float = Ui540.margin_bottom()
	if below + sz.y > vs.y - bottom and above >= top:
		y = above
	var max_x: float = maxf(left, vs.x - right - sz.x)
	var max_y: float = maxf(top, vs.y - bottom - sz.y)
	panel.position = Vector2(
		clampf(screen_pos.x, left, max_x),
		clampf(y, top, max_y),
	)
