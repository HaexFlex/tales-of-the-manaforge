class_name WoodsongView
extends MinigameView

const LEAF: Color = Color(0.46, 0.73, 0.28, 1.0)
const LOG: Color = Color(0.55, 0.38, 0.22, 1.0)
const GOLD: Color = Color(0.95, 0.76, 0.31, 1.0)

var _bg: Texture2D
var _cued_beats: Dictionary = {}


func _ready() -> void:
	custom_minimum_size = Vector2(640, 320)
	size = Vector2(640, 320)
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_process(true)


func bind(p_core: MinigameCore) -> void:
	super.bind(p_core)
	_cued_beats.clear()
	if core != null:
		core.spawned.connect(_on_spawned)
		core.resolved.connect(_on_event)
		var path: String = str(core.cfg.get("play_bg", ""))
		if path != "":
			_bg = load(path) as Texture2D


func hint_key() -> String:
	return "mg_woodsong_hint"


func _process(_delta: float) -> void:
	if core == null:
		return
	for b: Dictionary in core.state().get("beats", []):
		var beat_i: int = int(b.get("beat_index", 0))
		var t: float = float(b.get("beat_time", 0.0))
		if _cued_beats.has(beat_i):
			continue
		if core.clock_sec >= t:
			_cued_beats[beat_i] = true
			var cues: Dictionary = core.cfg.get("cues", {})
			var cue: String = str(cues.get("heavy_beat" if bool(b.get("heavy", false)) else "beat", ""))
			if cue != "":
				GameAudio.play(cue)
	queue_redraw()


func _draw() -> void:
	if core == null:
		return
	var st: Dictionary = core.state()
	var lane_y0: float = float(st.get("lane_y0", 0.04)) * size.y
	var lane_y1: float = float(st.get("lane_y1", 0.16)) * size.y
	var notch_x: float = float(st.get("notch_x", 0.13)) * size.x
	var beat_px: float = float(st.get("beat_px", 70.0))
	var bpm: float = float(st.get("bpm", 48.0))
	var sec_per_beat: float = 60.0 / bpm
	draw_rect(Rect2(0.0, lane_y0, size.x, lane_y1 - lane_y0), Color(0.2, 0.28, 0.18, 0.35))
	draw_line(Vector2(notch_x, lane_y0), Vector2(notch_x, lane_y1), GOLD, 2.0)
	for b: Dictionary in st.get("beats", []):
		var t: float = float(b.get("beat_time", 0.0))
		var dt: float = t - core.clock_sec
		var x: float = notch_x + dt / sec_per_beat * beat_px
		if x < -20.0 or x > size.x + 20.0:
			continue
		var cy: float = (lane_y0 + lane_y1) * 0.5
		if bool(b.get("heavy", false)):
			draw_circle(Vector2(x, cy), 10.0, LOG)
		else:
			draw_circle(Vector2(x, cy), 6.0, LEAF)


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
		if key.pressed and not key.echo and key.keycode == KEY_SPACE:
			core.input({"type": "press", "x": norm.x, "y": norm.y, "key": "space"})


func _on_spawned(_id: int, _info: Dictionary) -> void:
	queue_redraw()


func _on_event(_a = null, _b = null, _c = null) -> void:
	queue_redraw()
