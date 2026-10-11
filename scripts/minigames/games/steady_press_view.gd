class_name SteadyPressView
extends MinigameView

const GOLD: Color = Color(0.95, 0.76, 0.31, 1.0)
const FILL: Color = Color(0.46, 0.73, 0.28, 0.9)
const HANDLE: Color = Color(0.78, 0.68, 0.52, 1.0)

var _vent_played: bool = false
var _bg: Texture2D
var _gauge_frame: Texture2D
var _gauge_band: Texture2D
var _arrow_l: Texture2D
var _arrow_r: Texture2D


func _ready() -> void:
	custom_minimum_size = Vector2(640, 320)
	size = Vector2(640, 320)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func bind(p_core: MinigameCore) -> void:
	super.bind(p_core)
	_vent_played = false
	var path: String = str(core.cfg.get("play_bg", ""))
	if path != "":
		_bg = load(path) as Texture2D
	_gauge_frame = MinigameKit.load_tex("gauge_frame_40x240.png")
	_gauge_band = MinigameKit.load_tex("gauge_band_9s_40x12.png")
	_arrow_l = MinigameKit.load_tex("gauge_arrow_l_6x11.png")
	_arrow_r = MinigameKit.load_tex("gauge_arrow_r_6x11.png")
	if core != null:
		core.spawned.connect(_on_tick)
		core.resolved.connect(_on_tick)


func _on_tick(_a = null, _b = null, _c = null) -> void:
	if core == null:
		return
	var st: Dictionary = core.state()
	if bool(st.get("vent", false)) and not _vent_played:
		_vent_played = true
		var cues: Dictionary = (core.cfg.get("cues", {}) as Dictionary)
		var vent_id: String = str(cues.get("vent", ""))
		if vent_id != "":
			GameAudio.play(vent_id)
	queue_redraw()


func _draw() -> void:
	if core == null:
		return
	if _bg != null:
		draw_texture_rect(_bg, Rect2(Vector2.ZERO, size), false, Color(1, 1, 1, 0.35))
	var st: Dictionary = core.state()
	var gx: float = size.x * 0.72
	var gw: float = 36.0
	var gh: float = size.y * 0.7
	var gy: float = (size.y - gh) * 0.5
	if _gauge_frame != null:
		draw_texture_rect(_gauge_frame, Rect2(gx, gy, gw, gh), false)
	var fill: float = float(st.get("fill", 0.0))
	var fill_h: float = gh * fill
	draw_rect(Rect2(gx + 4.0, gy + gh - fill_h, gw - 8.0, fill_h), FILL)
	var band_lo: float = float(st.get("band_lo", 0.7))
	var band_hi: float = float(st.get("band_hi", 0.85))
	var by0: float = gy + gh * (1.0 - band_hi)
	var by1: float = gy + gh * (1.0 - band_lo)
	if _gauge_band != null:
		draw_texture_rect(_gauge_band, Rect2(gx, by0, gw, by1 - by0), false)
	var band_mid: float = (by0 + by1) * 0.5
	if _arrow_r != null:
		draw_texture(_arrow_r, Vector2(gx - 8.0, band_mid - 5.0))
	if _arrow_l != null:
		draw_texture(_arrow_l, Vector2(gx + gw + 2.0, band_mid - 5.0))
	var cx: float = size.x * 0.38
	var cy: float = size.y * 0.5
	var radius: float = minf(size.x, size.y) * 0.22
	draw_arc(Vector2(cx, cy), radius, 0.0, TAU, 64, HANDLE, 2.0)
	var frame: int = int(st.get("crank_frame", 0))
	var frames: int = maxi(1, int(core.cfg.get("crank_frames", 8)))
	var ang: float = (float(frame) / float(frames)) * TAU
	var hx: float = cx + cos(ang) * radius
	var hy: float = cy + sin(ang) * radius
	draw_line(Vector2(cx, cy), Vector2(hx, hy), GOLD, 4.0)
	draw_circle(Vector2(hx, hy), 8.0, HANDLE)


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
				core.input({"type": "press", "x": 0.5, "y": 0.5, "key": kname})
		elif kname == "space":
			core.input({"type": "release", "x": 0.5, "y": 0.5, "key": "space"})


func _key_name(key: InputEventKey) -> String:
	match key.keycode:
		KEY_SPACE:
			return "space"
		KEY_A:
			return "a"
		KEY_D:
			return "d"
		KEY_LEFT:
			return "left"
		KEY_RIGHT:
			return "right"
		_:
			return ""
