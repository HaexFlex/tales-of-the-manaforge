class_name SteadyPressCore
extends MinigameCore

var _spawned_cycle_idx: int = -1
var _draw: Dictionary = {}
var _fill: float = 0.0
var _mouse_held: bool = false
var _space_held: bool = false
var _last_angle: float = 0.0
var _angle_valid: bool = false
var _dir_accum: float = 0.0
var _last_turn_sign: int = 0
var _last_key_side: String = ""
var _fill_allowance: float = 0.0
var _fill_pending: float = 0.0
var _display_angle: float = 0.0
var _vented: bool = false
var _turning: bool = false


func _on_start() -> void:
	_reset_cycle_draw()
	_spawned_cycle_idx = -1


func _on_advance(real_dt: float) -> void:
	if not _turning:
		_apply_sag(real_dt)
	_turning = false
	_fill_allowance = _max_fill_per_sec() * real_dt
	_apply_fill_pending()
	_sync_draw()
	_expire_tokens()
	_ensure_cycles()


func _on_input(ev: Dictionary) -> void:
	var typ: String = str(ev.get("type", ""))
	if typ == "press":
		_on_press(ev)
	elif typ == "release":
		_on_release(ev)
	elif typ == "move":
		_on_move(ev)


func state() -> Dictionary:
	return _draw.duplicate(true)


func _on_press(ev: Dictionary) -> void:
	var key: String = str(ev.get("key", ""))
	if key == "space":
		_space_held = true
		_sync_draw()
		return
	if key == "a" or key == "left":
		_try_key_turn("a")
		return
	if key == "d" or key == "right":
		_try_key_turn("d")
		return
	if _live.is_empty():
		return
	_mouse_held = true
	_angle_valid = false
	_on_move(ev)


func _on_release(ev: Dictionary) -> void:
	var key: String = str(ev.get("key", ""))
	if key == "space":
		if _space_held:
			_space_held = false
			_try_resolve()
		return
	if _mouse_held:
		_mouse_held = false
		_try_resolve()


func _on_move(ev: Dictionary) -> void:
	if not _mouse_held or _live.is_empty():
		return
	var px: float = float(ev.get("x", 0.5))
	var py: float = float(ev.get("y", 0.5))
	var ang: float = atan2(py - 0.5, px - 0.5)
	_display_angle = ang
	if not _angle_valid:
		_last_angle = ang
		_angle_valid = true
		_sync_draw()
		return
	var delta: float = _wrap_angle(ang - _last_angle)
	_last_angle = ang
	if absf(delta) < 0.0005:
		return
	_turning = true
	var sign: int = 1 if delta > 0.0 else -1
	if _last_turn_sign != 0 and sign != _last_turn_sign:
		_dir_accum = 0.0
	else:
		_dir_accum += absf(delta)
		var per_turn: float = _fill_per_turn()
		while _dir_accum >= TAU:
			_dir_accum -= TAU
			_add_fill(per_turn)
	_last_turn_sign = sign
	_check_vent()
	_sync_draw()


func _try_key_turn(side: String) -> void:
	if not _space_held or _live.is_empty():
		return
	if _last_key_side != "" and _last_key_side != side:
		_turning = true
		var step_deg: float = _key_step_deg()
		var per_turn: float = _fill_per_turn()
		_add_fill(per_turn * (step_deg / 360.0))
		_display_angle += deg_to_rad(step_deg) * (1.0 if side == "d" else -1.0)
		_check_vent()
	_last_key_side = side
	_sync_draw()


func _try_resolve() -> void:
	var token_id: int = int(_draw.get("token_id", -1))
	if token_id < 0 or not _live.has(token_id):
		return
	if bool(_draw.get("resolved", false)):
		return
	var band: Array = cfg.get("band", [0.7, 0.85]) as Array
	var lo: float = float(band[0])
	var hi: float = float(band[1])
	var eff: float = _effective_fill()
	var ok: bool = eff >= lo and eff <= hi
	_fill = eff
	_fill_pending = 0.0
	_draw["resolved"] = true
	_resolve(token_id, ok, 1)


func _effective_fill() -> float:
	return clampf(_fill + _fill_pending, 0.0, 1.0)


func _check_vent() -> void:
	if _vented or _live.is_empty():
		return
	if not _cranking():
		return
	if _fill < _vent_at():
		return
	if not _turning:
		return
	_vented = true
	var token_id: int = int(_draw.get("token_id", -1))
	if token_id >= 0 and _live.has(token_id):
		_draw["resolved"] = true
		_draw["vent"] = true
		_resolve(token_id, false, 1)


func _cranking() -> bool:
	return _mouse_held or _space_held


func _add_fill(amount: float) -> void:
	if amount <= 0.0:
		return
	_fill_pending += amount
	_apply_fill_pending()


func _apply_fill_pending() -> void:
	while _fill_pending > 0.000001 and _fill_allowance > 0.000001:
		var take: float = minf(_fill_pending, _fill_allowance)
		_fill_pending -= take
		_fill_allowance -= take
		_fill = clampf(_fill + take, 0.0, 1.0)


func _apply_sag(dt: float) -> void:
	var sag: float = float(cfg.get("sag_per_sec", 0.08))
	_fill = maxf(0.0, _fill - sag * dt)


func _sync_draw() -> void:
	var frames: int = maxi(1, int(cfg.get("crank_frames", 8)))
	var frame_idx: int = int(floorf((_display_angle + TAU) / (TAU / float(frames)))) % frames
	_draw["fill"] = _effective_fill()
	_draw["band_lo"] = float((cfg.get("band", [0.7, 0.85]) as Array)[0])
	_draw["band_hi"] = float((cfg.get("band", [0.7, 0.85]) as Array)[1])
	_draw["crank_frame"] = frame_idx
	_draw["cranking"] = _turning or _cranking()
	_draw["vent"] = _vented


func _reset_cycle_draw() -> void:
	_fill = 0.0
	_mouse_held = false
	_space_held = false
	_last_angle = 0.0
	_angle_valid = false
	_dir_accum = 0.0
	_last_turn_sign = 0
	_last_key_side = ""
	_fill_allowance = 0.0
	_fill_pending = 0.0
	_display_angle = 0.0
	_vented = false
	_turning = false
	_draw = {
		"token_id": -1,
		"fill": 0.0,
		"resolved": false,
		"vent": false,
		"crank_frame": 0,
		"band_lo": float((cfg.get("band", [0.7, 0.85]) as Array)[0]),
		"band_hi": float((cfg.get("band", [0.7, 0.85]) as Array)[1]),
		"cranking": false,
	}


func _cycle_sec() -> float:
	return float(cfg.get("cycle_sec", 4.0))


func _fill_per_turn() -> float:
	return float(cfg.get("fill_per_turn", 0.25))


func _max_fill_per_sec() -> float:
	return float(cfg.get("max_fill_per_sec", 0.6))


func _vent_at() -> float:
	return float(cfg.get("vent_at", 0.97))


func _key_step_deg() -> float:
	if cfg.has("key_step_deg"):
		return float(cfg.get("key_step_deg", 90.0))
	if bool(cfg.get("key_quarter_turn", false)):
		return 90.0
	return 90.0


func _wrap_angle(rad: float) -> float:
	while rad > PI:
		rad -= TAU
	while rad < -PI:
		rad += TAU
	return rad


func _ensure_cycles() -> void:
	var cycle: float = _cycle_sec()
	if cycle <= 0.0:
		return
	var idx: int = int(floorf(clock_sec / cycle))
	while _spawned_cycle_idx < idx:
		_spawned_cycle_idx += 1
		_spawn_cycle_token(_spawned_cycle_idx)


func _spawn_cycle_token(cycle_idx: int) -> void:
	for live_id: Variant in _live.keys():
		_resolve(int(live_id), false, 1)
	_reset_cycle_draw()
	var cycle: float = _cycle_sec()
	var expire_at: float = float(cycle_idx + 1) * cycle
	var token_id: int = _spawn({
		"cycle_idx": cycle_idx,
		"expire_at": expire_at,
	})
	_draw["token_id"] = token_id
	_sync_draw()


func _expire_tokens() -> void:
	for token_id: Variant in _live.keys():
		var info: Dictionary = _live[token_id] as Dictionary
		if clock_sec >= float(info.get("expire_at", 0.0)):
			_resolve(int(token_id), false, 1)
			if int(_draw.get("token_id", -1)) == int(token_id):
				_draw["token_id"] = -1
				_draw["resolved"] = true
