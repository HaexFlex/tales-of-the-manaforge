class_name SplittingStoneView
extends MinigameView

const GOLD: Color = Color(0.95, 0.76, 0.31, 1.0)
const FAINT: Color = Color(0.5, 0.45, 0.4, 0.35)
const BOULDER: Color = Color(0.55, 0.52, 0.48, 1.0)

var _bg: Texture2D


func _ready() -> void:
	custom_minimum_size = Vector2(640, 320)
	size = Vector2(640, 320)
	mouse_filter = Control.MOUSE_FILTER_STOP


func bind(p_core: MinigameCore) -> void:
	super.bind(p_core)
	if core != null:
		core.resolved.connect(_on_event)
		core.spawned.connect(_on_event)
		var path: String = str(core.cfg.get("play_bg", ""))
		if path != "":
			_bg = load(path) as Texture2D


func hint_key() -> String:
	return "mg_splitting_stone_hint"


func _draw() -> void:
	if core == null:
		return
	if _bg != null:
		draw_texture_rect(_bg, Rect2(Vector2.ZERO, size), false, Color(1, 1, 1, 0.45))
	var st: Dictionary = core.state()
	draw_circle(Vector2(size.x * 0.5, size.y * 0.5), minf(size.x, size.y) * 0.22, BOULDER)
	var spots: Array = st.get("spots", [])
	var phase: String = str(st.get("phase", ""))
	var lit: int = int(st.get("lit_index", -1))
	var lit_until: float = float(st.get("lit_until", 0.0))
	var win: float = float(st.get("window_sec", 0.8))
	var radius: float = float(st.get("spot_radius", 0.06)) * minf(size.x, size.y)
	for i: int in range(spots.size()):
		var p: Vector2 = spots[i] as Vector2
		var px: float = p.x * size.x
		var py: float = p.y * size.y
		if phase == "preview":
			draw_circle(Vector2(px, py), radius * 0.6, FAINT)
			draw_string(ThemeDB.fallback_font, Vector2(px - 4.0, py + 4.0), str(i + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, FAINT)
		elif i == lit:
			var remain: float = maxf(0.0, lit_until - core.clock_sec)
			var frac: float = remain / maxf(win, 0.001)
			draw_circle(Vector2(px, py), radius, GOLD)
			draw_arc(Vector2(px, py), radius + 6.0, 0.0, TAU * frac, 32, GOLD, 2.0)
			draw_string(ThemeDB.fallback_font, Vector2(px - 4.0, py + 4.0), str(i + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, GOLD)


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
		var k: String = ""
		match key.keycode:
			KEY_1:
				k = "1"
			KEY_2:
				k = "2"
			KEY_3:
				k = "3"
		if k != "":
			core.input({"type": "press", "x": norm.x, "y": norm.y, "key": k})


func _on_event(_a = null, _b = null, _c = null) -> void:
	queue_redraw()
