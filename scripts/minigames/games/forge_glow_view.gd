class_name ForgeGlowView
extends MinigameView

const GOLD: Color = Color(0.95, 0.76, 0.31, 1.0)
const EMBER_LO: Color = Color(0.35, 0.12, 0.08, 1.0)
const EMBER_HI: Color = Color(0.98, 0.95, 0.88, 1.0)
const NEEDLE: Color = Color(0.93, 0.86, 0.62, 1.0)


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
	var bar_h: float = 28.0
	var margin: float = 48.0
	var bar_w: float = size.x - margin * 2.0
	var top: float = size.y * 0.55
	var bar_rect: Rect2 = Rect2(margin, top, bar_w, bar_h)
	for i: int in 32:
		var t0: float = float(i) / 32.0
		var t1: float = float(i + 1) / 32.0
		var c: Color = EMBER_LO.lerp(EMBER_HI, t0)
		var x0: float = bar_rect.position.x + bar_w * t0
		var w: float = bar_w / 32.0 + 1.0
		draw_rect(Rect2(x0, bar_rect.position.y, w, bar_h), c)
	var lo: float = float(st.get("sweet_lo", 0.55))
	var hi: float = float(st.get("sweet_hi", 0.75))
	var sweet_x: float = bar_rect.position.x + bar_w * lo
	var sweet_w: float = bar_w * (hi - lo)
	draw_rect(Rect2(sweet_x, bar_rect.position.y - 3.0, sweet_w, bar_h + 6.0), GOLD, false, 2.0)
	var needle: float = float(st.get("needle", 0.0))
	var nx: float = bar_rect.position.x + bar_w * needle
	draw_line(Vector2(nx, bar_rect.position.y - 8.0), Vector2(nx, bar_rect.position.y + bar_h + 8.0), NEEDLE, 3.0)
	draw_circle(Vector2(nx, bar_rect.position.y + bar_h * 0.5), 5.0, NEEDLE)


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
			core.input({"type": "press", "x": 0.5, "y": 0.5, "key": "space"})
