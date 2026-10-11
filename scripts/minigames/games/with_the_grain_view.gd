class_name WithTheGrainView
extends MinigameView

const INK: Color = Color(0.22, 0.16, 0.12, 0.95)
const PATH: Color = Color(0.78, 0.68, 0.52, 0.35)
const GOLD: Color = Color(0.95, 0.76, 0.31, 1.0)


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
	var path_arr: Array = st.get("path", []) as Array
	if path_arr.size() >= 2:
		for i: int in path_arr.size() - 1:
			var a: Dictionary = path_arr[i] as Dictionary
			var b: Dictionary = path_arr[i + 1] as Dictionary
			draw_line(_px(a), _px(b), PATH, 3.0)
	var stroke_arr: Array = st.get("stroke", []) as Array
	if stroke_arr.size() >= 2:
		for i: int in stroke_arr.size() - 1:
			var a: Dictionary = stroke_arr[i] as Dictionary
			var b: Dictionary = stroke_arr[i + 1] as Dictionary
			draw_line(_px(a), _px(b), INK, 4.0)
	var acc: float = float(st.get("accuracy", -1.0))
	if acc >= 0.0:
		var txt: String = "%d%%" % int(round(acc * 100.0))
		draw_string(ThemeDB.fallback_font, Vector2(12.0, 24.0), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, GOLD)


func handle_input(ev: InputEvent, local: Vector2) -> void:
	if core == null:
		return
	var norm: Vector2 = Vector2(local.x / size.x, local.y / size.y)
	if ev is InputEventMouseButton:
		var mb: InputEventMouseButton = ev as InputEventMouseButton
		if mb.button_index != MOUSE_BUTTON_LEFT:
			return
		if mb.pressed:
			core.input({"type": "press", "x": norm.x, "y": norm.y, "key": ""})
		else:
			core.input({"type": "release", "x": norm.x, "y": norm.y, "key": ""})
	elif ev is InputEventMouseMotion:
		var mm: InputEventMouseMotion = ev as InputEventMouseMotion
		if (mm.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
			core.input({"type": "move", "x": norm.x, "y": norm.y, "key": ""})
	elif ev is InputEventKey:
		var key: InputEventKey = ev as InputEventKey
		if key.echo:
			return
		var kname: String = _key_name(key)
		if kname == "":
			return
		if key.pressed:
			if kname == "space":
				core.input({"type": "press", "x": 0.5, "y": 0.5, "key": "space"})
			else:
				if core is WithTheGrainCore:
					(core as WithTheGrainCore).steer_key(kname)
				core.input({"type": "press", "x": norm.x, "y": norm.y, "key": kname})
		elif kname == "space":
			core.input({"type": "release", "x": 0.5, "y": 0.5, "key": "space"})


func _px(d: Dictionary) -> Vector2:
	return Vector2(float(d.get("x", 0.0)) * size.x, float(d.get("y", 0.0)) * size.y)


func _key_name(key: InputEventKey) -> String:
	match key.keycode:
		KEY_SPACE:
			return "space"
		KEY_A:
			return "a"
		KEY_D:
			return "d"
		KEY_W:
			return "w"
		KEY_S:
			return "s"
		KEY_LEFT:
			return "left"
		KEY_RIGHT:
			return "right"
		KEY_UP:
			return "up"
		KEY_DOWN:
			return "down"
		_:
			return ""
