extends CanvasLayer
## Two small in-world bars for a running batch. No labels. Hover explains each bar.

var station_id: String = ""
var _host: Node2D
var _root: Control
var _current: Control
var _total: Control


func bind(host: Node2D, spot_id: String) -> void:
	_host = host
	station_id = spot_id


func _ready() -> void:
	layer = 15
	_root = Control.new()
	_root.name = "Bars"
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.custom_minimum_size = Vector2(72, 16)
	_root.size = Vector2(72, 16)
	_root.gui_input.connect(_on_gui_input)
	add_child(_root)
	_current = _make_bar("CurrentBar", 0.0)
	_total = _make_bar("TotalBar", 10.0)
	visible = false


func _make_bar(node_name: String, y: float) -> Control:
	var bar := _Bar.new()
	bar.name = node_name
	bar.position = Vector2(0, y)
	bar.size = Vector2(72, 6)
	bar.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.add_child(bar)
	return bar


func _process(_delta: float) -> void:
	_refresh()


func _refresh() -> void:
	if _host == null or station_id == "" or not has_node("/root/ForgeJobs"):
		visible = false
		return
	if not ForgeJobs.has_job(station_id):
		visible = false
		return
	var state: Dictionary = ForgeJobs.job_state(station_id)
	if state.is_empty():
		visible = false
		return
	visible = true
	var y: float = -160.0
	var title: Label = _host.get_node_or_null("Title") as Label
	if title:
		y = title.offset_top - 18.0
	var sprite: Sprite2D = _host.get_node_or_null("Sprite") as Sprite2D
	if sprite:
		var visual_top: float = sprite.position.y + sprite.offset.y * sprite.scale.y
		y = minf(y, visual_top - 18.0)
	var screen: Vector2 = _host.get_global_transform_with_canvas() * Vector2(0.0, y)
	_root.position = screen + Vector2(-36.0, -16.0)
	(_current as _Bar).fraction = float(state.get("fraction", 0.0))
	(_total as _Bar).fraction = float(state.get("batch_fraction", 0.0))
	_current.tooltip_text = ForgeJobs.bar_tooltip(station_id, "current")
	_total.tooltip_text = ForgeJobs.bar_tooltip(station_id, "total")
	_current.queue_redraw()
	_total.queue_redraw()


func _on_gui_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton):
		return
	var mb: InputEventMouseButton = event
	if not mb.pressed or mb.button_index != MOUSE_BUTTON_LEFT:
		return
	if _host != null and _host.has_method("_on_left_click"):
		_host.call("_on_left_click")
	_root.accept_event()


class _Bar extends Control:
	var fraction: float = 0.0

	func _draw() -> void:
		var w: float = size.x
		var h: float = size.y
		draw_rect(Rect2(Vector2.ZERO, Vector2(w, h)), Color(0.08, 0.06, 0.04, 0.95), true)
		var fill_w: float = floorf(w * clampf(fraction, 0.0, 1.0))
		if fill_w >= 1.0:
			draw_rect(Rect2(Vector2.ZERO, Vector2(fill_w, h)), Color(0.55, 0.78, 0.34, 1.0), true)
		draw_rect(Rect2(Vector2.ZERO, Vector2(w, h)), Color(0.82, 0.64, 0.28, 1.0), false, 1.0)
