class_name SteadyPress
extends Minigame
## Crank the wheel. Turn speed builds pressure. Ease off inside the green
## and hold it to pay. Past the vent the attempt misses and the cycle resets.
## One try every 4 seconds. Stopping sags, and that sag is not a miss.

const CRANK_C := Vector2(440, 120)
const DIAL_TL := Vector2(512, 20)
const DIAL_C := Vector2(60, 60)
const DRAG_R := 104.0
const DRAG_SLOP := 20.0
const HUB_DEAD := 12.0

var _k: float = 8.0
var _cycle: float = 4.0
var _gain: float = 0.4
var _speed_win: float = 0.3
var _max_tps: float = 1.4
var _settle: float = 0.4
var _sag: float = 0.06
var _ease: float = 0.25
var _dwell_need: float = 0.5
var _vent_at: float = 0.96
var _band_width: float = 0.16
var _band_center: float = 0.6
var _drift_amp: float = 0.14
var _drift_period: float = 10.0
var _clock: float = 0.0
var _cycle_i: int = 0
var _level: float = 0.0
var _angle: float = 0.0
var _idle: float = 9.0
var _dwell: float = 0.0
var _resolved: bool = false
var _vented: bool = false
var _drag: bool = false
var _last_ang: float = 0.0
var _has_ang: bool = false
var _last_key: String = ""
var _hist: Array[Vector2] = []
var _station: Sprite2D
var _keeper: Sprite2D
var _crank: Sprite2D
var _vent: Sprite2D
var _ink: Control


func game_id() -> String:
	return "steady_press"


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	var row: Dictionary = MinigameCatalog.game("steady_press")
	_k = MinigameCatalog.k_for("steady_press")
	_cycle = float(row.get("cycle_sec", 4.0))
	_gain = float(row.get("gain_per_turn", 0.4))
	_speed_win = maxf(0.05, float(row.get("speed_win", 0.3)))
	_max_tps = float(row.get("max_tps", 1.4))
	_settle = float(row.get("settle_sec", 0.4))
	_sag = float(row.get("sag_per_sec", 0.06))
	_ease = float(row.get("ease_tps", 0.25))
	_dwell_need = float(row.get("dwell_sec", 0.5))
	_vent_at = float(row.get("vent_at", 0.96))
	_band_width = float(row.get("band_width", 0.16))
	_band_center = float(row.get("band_center", 0.6))
	_drift_amp = float(row.get("drift_amp", 0.14))
	_drift_period = maxf(0.1, float(row.get("drift_period", 10.0)))
	MinigameArt.add_sprite(self, "bg_forge.png", Vector2(320, 160))
	_station = MinigameArt.add_sprite(self, "st_mill.png", Vector2(246, 205))
	_keeper = MinigameArt.add_sprite(self, "keeper_station_n.png", Vector2(252, 258), 4)
	_keeper.z_index = 2
	_crank = MinigameArt.add_sprite(self, "crank_8f.png", CRANK_C, 8)
	_crank.z_index = 3
	var dial: Sprite2D = MinigameArt.add_sprite(self, "press_dial.png", DIAL_TL + Vector2(62, 75))
	dial.z_index = 3
	_vent = MinigameArt.add_sprite(self, "vent.png", Vector2(580, 192))
	_vent.z_index = 4
	_ink = Control.new()
	_ink.name = "Ink"
	_ink.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ink.z_index = 5
	_ink.position = Vector2.ZERO
	_ink.size = Vector2(640, 320)
	add_child(_ink)
	_ink.draw.connect(_paint_ink)


func bind_target(target_id: String) -> void:
	if _station == null:
		return
	var file: String = "st_press.png" if target_id == "press" else "st_mill.png"
	var tex: Texture2D = MinigameArt.texture(file)
	if tex != null:
		_station.texture = tex


func _process(delta: float) -> void:
	if not playing:
		return
	_clock += delta
	var idx: int = int(floor(_clock / _cycle))
	if idx != _cycle_i:
		_cycle_i = idx
		_reset_round()
	if _resolved:
		_level = maxf(0.0, _level - _sag * 2.0 * delta)
		_paint()
		return
	var sp: float = _speed()
	if sp > 0.05:
		_idle = 0.0
	else:
		_idle += delta
	_level += _gain * sp * delta
	if _idle > _settle:
		_level = maxf(0.0, _level - _sag * delta)
	if _level >= _vent_at:
		_level = _vent_at
		_vented = true
		_finish(false)
	else:
		var lo: float = _band_lo()
		var hi: float = _band_hi()
		if _level >= lo and _level <= hi and sp < _ease:
			_dwell += delta
			if _dwell >= _dwell_need:
				_finish(true)
		else:
			_dwell = 0.0
	_paint()


func _gui_input(event: InputEvent) -> void:
	if not playing or _resolved:
		return
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.button_index != MOUSE_BUTTON_LEFT:
			return
		if mb.pressed:
			var r: float = mb.position.distance_to(CRANK_C)
			if r <= DRAG_R + DRAG_SLOP:
				_drag = true
				_has_ang = r >= HUB_DEAD
				_last_ang = (mb.position - CRANK_C).angle()
		else:
			_drag = false
			_has_ang = false
	elif event is InputEventMouseMotion and _drag:
		_drag_to((event as InputEventMouseMotion).position)


func on_pointer_up() -> void:
	_drag = false
	_has_ang = false


func on_key(event: InputEvent) -> void:
	if not playing or _resolved or not (event is InputEventKey):
		return
	var key: InputEventKey = event as InputEventKey
	if not key.pressed or key.echo:
		return
	var side: String = ""
	var code: int = int(key.keycode)
	if code == KEY_A or code == KEY_LEFT:
		side = "a"
	elif code == KEY_D or code == KEY_RIGHT:
		side = "d"
	if side == "":
		return
	if _last_key != "" and _last_key != side:
		_turn(PI * 0.5 * (1.0 if side == "d" else -1.0))
	_last_key = side


func _drag_to(pos: Vector2) -> void:
	if pos.distance_to(CRANK_C) < HUB_DEAD:
		return
	var ang: float = (pos - CRANK_C).angle()
	if not _has_ang:
		_last_ang = ang
		_has_ang = true
		return
	_turn(wrapf(ang - _last_ang, -PI, PI))
	_last_ang = ang


func _turn(rad: float) -> void:
	if _resolved or is_zero_approx(rad):
		return
	_hist.append(Vector2(_clock, rad))
	_angle += rad


func _speed() -> float:
	var kept: Array[Vector2] = []
	var sum: float = 0.0
	for sample: Vector2 in _hist:
		if _clock - sample.x < _speed_win:
			kept.append(sample)
			sum += absf(sample.y)
	_hist = kept
	return minf(_max_tps, sum / _speed_win / TAU)


func _band_mid() -> float:
	return _band_center + _drift_amp * sin(TAU * _clock / _drift_period)


func _band_lo() -> float:
	return _band_mid() - _band_width * 0.5


func _band_hi() -> float:
	return _band_mid() + _band_width * 0.5


func _in_band() -> bool:
	return _level >= _band_lo() and _level <= _band_hi()


func _finish(ok: bool) -> void:
	if _resolved:
		return
	_resolved = true
	_drag = false
	_has_ang = false
	if ok:
		succeed(_k, 1.0, DIAL_TL + DIAL_C)
	else:
		miss()


func _reset_round() -> void:
	_level = 0.0
	_hist.clear()
	_idle = 9.0
	_dwell = 0.0
	_resolved = false
	_vented = false
	_drag = false
	_has_ang = false
	if _vent != null and is_instance_valid(_vent):
		_vent.texture = MinigameArt.texture("vent.png")


func _paint() -> void:
	if _crank != null:
		var turned: float = _angle + TAU
		_crank.frame = posmod(int(floor(turned / (PI * 0.5))), 8)
	if _keeper != null:
		_keeper.frame = posmod(int(floor(_clock * 8.0)), 4) if _idle < 0.2 else 0
	if _vent != null and _vented:
		var open_tex: Texture2D = MinigameArt.texture("vent_open.png")
		if open_tex != null:
			_vent.texture = open_tex
	if _ink != null:
		_ink.queue_redraw()


func _paint_ink() -> void:
	if _ink == null:
		return
	var ring := Color(0.56, 0.89, 0.90, 0.75 if _drag else 0.35)
	var steps: int = 48
	for i: int in steps:
		if i % 2 == 1:
			continue
		var a0: float = TAU * float(i) / float(steps)
		var a1: float = TAU * float(i + 1) / float(steps)
		_ink.draw_line(CRANK_C + Vector2(cos(a0), sin(a0)) * DRAG_R, CRANK_C + Vector2(cos(a1), sin(a1)) * DRAG_R, ring, 2.0)
	var c: Vector2 = DIAL_TL + DIAL_C
	var lo: float = _band_lo()
	var hi: float = _band_hi()
	var slices: int = 28
	for s: int in slices:
		var u0: float = lo + (hi - lo) * float(s) / float(slices)
		var u1: float = lo + (hi - lo) * float(s + 1) / float(slices)
		var edge: bool = s < 1 or s > slices - 2
		var bcol := Color8(44, 70, 40) if edge else Color8(120, 184, 80)
		var p0: Vector2 = c + Vector2(cos(_ang(u0)), sin(_ang(u0))) * 40.0
		var p1: Vector2 = c + Vector2(cos(_ang(u1)), sin(_ang(u1))) * 40.0
		_ink.draw_line(p0, p1, bcol, 8.0)
	var dir := Vector2(cos(_ang(clampf(_level, 0.0, 1.0))), sin(_ang(clampf(_level, 0.0, 1.0))))
	var ncol := Color8(224, 150, 58) if _vented else (Color8(168, 224, 112) if _in_band() else Color8(143, 227, 230))
	_ink.draw_line(c + dir * 4.0, c + dir * 38.0, Color8(26, 15, 8), 3.0)
	_ink.draw_line(c + dir * 4.0, c + dir * 37.0, ncol, 1.0)
	_ink.draw_circle(c, 4.5, Color8(26, 15, 8))
	_ink.draw_circle(c, 3.5, Color8(216, 162, 50))
	if _dwell > 0.0 and not _resolved and _dwell_need > 0.0:
		var frac: float = clampf(_dwell / _dwell_need, 0.0, 1.0)
		var bits: int = maxi(2, int(ceil(frac * 16.0)))
		for b: int in bits:
			var w0: float = -PI * 0.5 + TAU * frac * float(b) / float(bits)
			var w1: float = -PI * 0.5 + TAU * frac * float(b + 1) / float(bits)
			_ink.draw_line(c + Vector2(cos(w0), sin(w0)) * 14.0, c + Vector2(cos(w1), sin(w1)) * 14.0, Color8(168, 224, 112), 3.0)


func _ang(u: float) -> float:
	return deg_to_rad(150.0 + 240.0 * u)
