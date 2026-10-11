class_name SteepingView
extends MinigameView

const HERB_COLORS: Array[Color] = [
	Color(0.46, 0.73, 0.28, 1.0),
	Color(0.95, 0.76, 0.31, 1.0),
	Color(0.55, 0.42, 0.72, 1.0),
	Color(0.78, 0.55, 0.32, 1.0),
	Color(0.42, 0.62, 0.82, 1.0),
]


func _ready() -> void:
	custom_minimum_size = Vector2(640, 320)
	size = Vector2(640, 320)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func bind(p_core: MinigameCore) -> void:
	super.bind(p_core)
	if core != null:
		core.spawned.connect(_on_tick)
		core.resolved.connect(_on_tick)


func _on_tick(_a = null, _b = null, _c = null) -> void:
	queue_redraw()


func _draw() -> void:
	if core == null:
		return
	var st: Dictionary = core.state()
	var herbs: int = int(core.cfg.get("herbs", 5))
	var row_y: float = size.y * 0.72
	var slot_w: float = size.x / float(herbs)
	for i: int in herbs:
		var cx: float = slot_w * (float(i) + 0.5)
		var col: Color = HERB_COLORS[i % HERB_COLORS.size()]
		draw_circle(Vector2(cx, row_y), 22.0, col)
		draw_string(ThemeDB.fallback_font, Vector2(cx - 4.0, row_y + 6.0), str(i + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.2, 0.15, 0.1))
	var order: Array = st.get("order", []) as Array
	var revealed: int = int(st.get("revealed", 0))
	var cauldron_y: float = size.y * 0.35
	var cx0: float = size.x * 0.5 - float(order.size()) * 18.0
	for j: int in order.size():
		if j >= revealed and str(st.get("phase", "")) == "show":
			continue
		var herb_i: int = int(order[j])
		var col2: Color = HERB_COLORS[herb_i % HERB_COLORS.size()]
		draw_circle(Vector2(cx0 + float(j) * 36.0, cauldron_y), 14.0, col2)


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
		var digit: String = _digit_key(key)
		if digit != "":
			core.input({"type": "press", "x": norm.x, "y": norm.y, "key": digit})


func _digit_key(key: InputEventKey) -> String:
	match key.keycode:
		KEY_1:
			return "1"
		KEY_2:
			return "2"
		KEY_3:
			return "3"
		KEY_4:
			return "4"
		KEY_5:
			return "5"
		_:
			return ""
