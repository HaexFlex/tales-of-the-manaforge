class_name JustEnoughView
extends MinigameView

const GOOD: Color = Color(0.46, 0.73, 0.28, 1.0)
const WATER: Color = Color(0.36, 0.59, 0.84, 0.85)
const GOLD: Color = Color(0.95, 0.76, 0.31, 1.0)

var _bg: Texture2D
var _primary_down: bool = false


func _ready() -> void:
	custom_minimum_size = Vector2(640, 320)
	size = Vector2(640, 320)
	mouse_filter = Control.MOUSE_FILTER_STOP


func bind(p_core: MinigameCore) -> void:
	super.bind(p_core)
	if core != null:
		core.resolved.connect(_on_event)
		var path: String = str(core.cfg.get("play_bg", ""))
		if path != "":
			_bg = load(path) as Texture2D


func hint_key() -> String:
	return "mg_just_enough_hint"


func _draw() -> void:
	if core == null:
		return
	if _bg != null:
		draw_texture_rect(_bg, Rect2(Vector2.ZERO, size), false, Color(1, 1, 1, 0.45))
	var st: Dictionary = core.state()
	var gx: float = float(st.get("gauge_x", 0.0625)) * size.x
	var gy: float = float(st.get("gauge_y", 0.125)) * size.y
	var gw: float = float(st.get("gauge_w", 0.0625)) * size.x
	var gh: float = float(st.get("gauge_h", 0.75)) * size.y
	var lo: float = float(st.get("band_lo", 0.62))
	var hi: float = float(st.get("band_hi", 0.82))
	var level: float = float(st.get("level", 0.0))
	draw_rect(Rect2(gx, gy, gw, gh), Color(0.25, 0.22, 0.2, 0.5))
	var band_top: float = gy + gh * (1.0 - hi)
	var band_h: float = gh * (hi - lo)
	draw_rect(Rect2(gx, band_top, gw, band_h), Color(GOOD, 0.35))
	var fill_h: float = gh * level
	draw_rect(Rect2(gx, gy + gh - fill_h, gw, fill_h), WATER)
	if str(st.get("phase", "")) == "pour":
		draw_rect(Rect2(gx + gw + 8.0, gy + gh * 0.5, 24.0, 8.0), WATER)


func handle_input(ev: InputEvent, _local: Vector2) -> void:
	if core == null:
		return
	if ev is InputEventMouseButton:
		var mb: InputEventMouseButton = ev as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed and not _primary_down:
				_primary_down = true
				core.input({"type": "press", "x": 0.5, "y": 0.5, "key": ""})
			elif not mb.pressed and _primary_down:
				_primary_down = false
				core.input({"type": "release", "x": 0.5, "y": 0.5, "key": ""})
	elif ev is InputEventKey:
		var key: InputEventKey = ev as InputEventKey
		if key.echo or key.keycode != KEY_SPACE:
			return
		if key.pressed and not _primary_down:
			_primary_down = true
			core.input({"type": "press", "x": 0.5, "y": 0.5, "key": "space"})
		elif not key.pressed and _primary_down:
			_primary_down = false
			core.input({"type": "release", "x": 0.5, "y": 0.5, "key": "space"})


func _on_event(_a = null, _b = null, _c = null) -> void:
	queue_redraw()
