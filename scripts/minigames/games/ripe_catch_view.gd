class_name RipeCatchView
extends MinigameView

const PURPLE: Color = Color(0.45, 0.22, 0.55, 1.0)
const BROWN: Color = Color(0.42, 0.28, 0.18, 1.0)
const GOLD: Color = Color(0.95, 0.76, 0.31, 1.0)
const SPLAT: Color = Color(0.59, 0.52, 0.44, 0.65)

var _bg: Texture2D
var _keys: Dictionary = {"left": false, "right": false, "a": false, "d": false}


func _ready() -> void:
	custom_minimum_size = Vector2(640, 320)
	size = Vector2(640, 320)
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_process(true)


func bind(p_core: MinigameCore) -> void:
	super.bind(p_core)
	if core != null:
		core.resolved.connect(_on_core_event)
		core.spawned.connect(_on_core_event)
		var path: String = str(core.cfg.get("play_bg", ""))
		if path != "":
			_bg = load(path) as Texture2D


func hint_key() -> String:
	return "mg_ripe_catch_hint"


func _process(delta: float) -> void:
	if core == null:
		return
	var speed: float = float(core.cfg.get("basket_speed_keys", 0.9))
	var dir: float = 0.0
	if _keys.get("left", false) or _keys.get("a", false):
		dir -= 1.0
	if _keys.get("right", false) or _keys.get("d", false):
		dir += 1.0
	if dir != 0.0:
		var st: Dictionary = core.state()
		var x: float = float(st.get("basket_x", 0.5)) + dir * speed * delta
		core.input({"type": "move", "x": x, "y": 0.0, "key": ""})
		queue_redraw()


func _draw() -> void:
	if core == null:
		return
	var st: Dictionary = core.state()
	var catch_y: float = float(st.get("catch_y", 0.79)) * size.y
	var hw: float = float(st.get("basket_half_w", 0.07)) * size.x
	var bx: float = float(st.get("basket_x", 0.5)) * size.x
	draw_rect(Rect2(bx - hw, catch_y - 4.0, hw * 2.0, 8.0), Color(0.35, 0.25, 0.18, 0.22))
	if int(st.get("streak", 0)) >= 3:
		draw_rect(Rect2(bx - hw - 4.0, catch_y - 10.0, hw * 2.0 + 8.0, 22.0), GOLD, false, 3.0)
	for s: Dictionary in st.get("splats", []):
		var sx: float = float(s.get("x", 0.5)) * size.x
		draw_circle(Vector2(sx, catch_y), 8.0, SPLAT)
	for b: Dictionary in st.get("berries", []):
		var px: float = float(b.get("x", 0.5)) * size.x
		var py: float = float(b.get("y", 0.5)) * size.y
		var col: Color = PURPLE if str(b.get("kind", "")) == "ripe" else BROWN
		draw_circle(Vector2(px, py), 7.0, col)


func handle_input(ev: InputEvent, local: Vector2) -> void:
	if core == null:
		return
	var norm: Vector2 = Vector2(local.x / size.x, local.y / size.y)
	if ev is InputEventMouseMotion:
		core.input({"type": "move", "x": norm.x, "y": norm.y, "key": ""})
	elif ev is InputEventMouseButton:
		var mb: InputEventMouseButton = ev as InputEventMouseButton
		if mb.pressed:
			core.input({"type": "move", "x": norm.x, "y": norm.y, "key": ""})
	elif ev is InputEventKey:
		var key: InputEventKey = ev as InputEventKey
		if key.echo:
			return
		_track_key(key, key.pressed)


func _track_key(key: InputEventKey, down: bool) -> void:
	match key.keycode:
		KEY_LEFT:
			_keys["left"] = down
		KEY_A:
			_keys["a"] = down
		KEY_RIGHT:
			_keys["right"] = down
		KEY_D:
			_keys["d"] = down


func _on_core_event(_a = null, _b = null, _c = null) -> void:
	queue_redraw()
