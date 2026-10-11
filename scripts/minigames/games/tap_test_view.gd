class_name TapTestView
extends MinigameView

const INK: Color = Color(0.28, 0.22, 0.18, 1.0)
const GOOD: Color = Color(0.46, 0.73, 0.28, 1.0)
const GOLD: Color = Color(0.95, 0.76, 0.31, 1.0)


func _ready() -> void:
	custom_minimum_size = Vector2(640, 320)
	size = Vector2(640, 320)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func bind(p_core: MinigameCore) -> void:
	super.bind(p_core)
	if core != null:
		core.resolved.connect(_on_resolved)
		core.spawned.connect(_on_spawned)


func hint_key() -> String:
	return ""


func _draw() -> void:
	if core == null:
		return
	var st: Dictionary = core.state()
	if not bool(st.get("active", false)):
		return
	var px: float = float(st.get("x", 0.5)) * size.x
	var py: float = float(st.get("y", 0.5)) * size.y
	var radius: float = TapTestCore.SPOT_RADIUS * minf(size.x, size.y)
	draw_circle(Vector2(px, py), radius, GOLD)
	draw_arc(Vector2(px, py), radius + 3.0, 0.0, TAU, 32, GOOD, 2.0)
	draw_circle(Vector2(px, py), 6.0, INK)


func handle_input(ev: InputEvent, local: Vector2) -> void:
	if core == null:
		return
	var norm: Vector2 = Vector2(local.x / size.x, local.y / size.y)
	if ev is InputEventMouseButton:
		var mb: InputEventMouseButton = ev as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			core.input({"type": "press", "x": norm.x, "y": norm.y, "key": ""})
	elif ev is InputEventKey:
		var key: InputEventKey = ev as InputEventKey
		if not key.pressed or key.echo:
			return
		if key.keycode == KEY_SPACE:
			var st: Dictionary = core.state()
			core.input({
				"type": "press",
				"x": float(st.get("x", 0.5)),
				"y": float(st.get("y", 0.5)),
				"key": "space",
			})


func feedback_pos(_success: bool, _weight: int) -> Vector2:
	if core == null:
		return size * 0.5
	var st: Dictionary = core.state()
	return Vector2(float(st.get("x", 0.5)) * size.x, float(st.get("y", 0.5)) * size.y)


func _on_resolved(_token_id: int, _success: bool, _weight: int) -> void:
	queue_redraw()


func _on_spawned(_token_id: int, _info: Dictionary) -> void:
	queue_redraw()
