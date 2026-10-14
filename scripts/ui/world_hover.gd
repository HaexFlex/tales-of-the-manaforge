class_name WorldHover
extends RefCounted
## One papyrus tooltip for map and world hovers. Control tooltips use the same
## TooltipPanel style. Area2D nodes cannot own a Control tooltip, so this panel
## sits on a canvas layer and follows the pointer.

static var _layer: CanvasLayer
static var _panel: PanelContainer
static var _label: Label
static var _owner_id: int = 0


static func sync(source: Node, inside: bool, text: String) -> void:
	if inside:
		present(source, text)
	else:
		dismiss(source)


static func present(source: Node, text: String) -> void:
	if _minigame_open():
		hide_for_overlay()
		return
	if source == null or not source.is_inside_tree() or text == "":
		dismiss(source)
		return
	var panel := _ensure(source.get_tree())
	_owner_id = source.get_instance_id()
	_label.text = text
	var font: Font = _label.get_theme_font(&"font")
	var font_size: int = _label.get_theme_font_size(&"font_size")
	var text_sz := Vector2(80, 19)
	if font != null:
		text_sz = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var box: StyleBox = panel.get_theme_stylebox(&"panel")
	var pad := Vector2(20, 8)
	if box != null:
		pad = Vector2(
			box.get_content_margin(SIDE_LEFT) + box.get_content_margin(SIDE_RIGHT),
			box.get_content_margin(SIDE_TOP) + box.get_content_margin(SIDE_BOTTOM),
		)
	panel.size = Vector2(maxf(48.0, text_sz.x + pad.x), maxf(Ui540.TOOLTIP_MIN_H, text_sz.y + pad.y))
	panel.custom_minimum_size = panel.size
	var screen := Vector2.ZERO
	if source.get_viewport():
		screen = source.get_viewport().get_mouse_position()
	_place_near(panel, screen)
	panel.visible = true


static func hide_for_overlay() -> void:
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
	if source != null and source.get_instance_id() != _owner_id:
		return
	_owner_id = 0
	if _panel != null and is_instance_valid(_panel):
		_panel.visible = false


static func current_text() -> String:
	if _label == null or _panel == null or not is_instance_valid(_panel) or not _panel.visible:
		return ""
	return _label.text


static func panel() -> PanelContainer:
	return _panel


static func shutdown() -> void:
	_owner_id = 0
	if _layer != null and is_instance_valid(_layer):
		_layer.queue_free()
	_layer = null
	_panel = null
	_label = null


static func _ensure(tree: SceneTree) -> PanelContainer:
	if _panel != null and is_instance_valid(_panel):
		return _panel
	_layer = CanvasLayer.new()
	_layer.name = "WorldHoverLayer"
	_layer.layer = 120
	_panel = PanelContainer.new()
	_panel.name = "WorldHoverTip"
	_panel.theme_type_variation = &"TooltipPanel"
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.visible = false
	_label = Label.new()
	_label.name = "Text"
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
	if below + sz.y > vs.y - Ui540.SAFE_MARGIN_PX and above >= Ui540.SAFE_MARGIN_PX:
		y = above
	var max_x: float = maxf(Ui540.SAFE_MARGIN_PX, vs.x - Ui540.SAFE_MARGIN_PX - sz.x)
	var max_y: float = maxf(Ui540.SAFE_MARGIN_PX, vs.y - Ui540.SAFE_MARGIN_PX - sz.y)
	panel.position = Vector2(
		clampf(screen_pos.x, Ui540.SAFE_MARGIN_PX, max_x),
		clampf(y, Ui540.SAFE_MARGIN_PX, max_y),
	)
