class_name JustEnoughCore
extends MinigameCore

var _spawned_cycle_idx: int = -1
var _token_id: int = -1
var _holding: bool = false
var _level: float = 0.0
var _phase: String = "idle"
var _pour_until: float = 0.0
var _cycle_resolved: bool = false
var _overflow_failed: bool = false


func _on_start() -> void:
	_spawned_cycle_idx = -1
	_token_id = -1
	_holding = false
	_level = 0.0
	_phase = "idle"
	_pour_until = 0.0
	_cycle_resolved = false
	_overflow_failed = false
	_ensure_cycles()


func _on_advance(real_dt: float) -> void:
	_ensure_cycles()
	if _phase == "pour" and clock_sec >= _pour_until:
		_phase = "idle"
	if _holding and _phase == "fill" and not _cycle_resolved:
		_level += real_dt / _fill_sec()
		if _level >= 1.0:
			_level = 1.0
			_holding = false
			if not _overflow_failed:
				_overflow_failed = true
				_fail_token()


func _on_input(ev: Dictionary) -> void:
	var t: String = str(ev.get("type", ""))
	if _cycle_resolved or _token_id < 0:
		return
	if t == "press":
		if _phase == "fill" or _phase == "idle":
			_holding = true
			_phase = "fill"
	elif t == "release":
		if _holding and _phase == "fill":
			_holding = false
			_judge_release()


func state() -> Dictionary:
	var band: Array = cfg.get("band", [0.62, 0.82])
	return {
		"level": _level,
		"holding": _holding,
		"phase": _phase,
		"band_lo": float(band[0]),
		"band_hi": float(band[1]),
		"gauge_x": 40.0 / 640.0,
		"gauge_y": 40.0 / 320.0,
		"gauge_w": 40.0 / 640.0,
		"gauge_h": 240.0 / 320.0,
	}


func _cycle_sec() -> float:
	return float(cfg.get("cycle_sec", 3.0))


func _fill_sec() -> float:
	return float(cfg.get("fill_sec", 1.8))


func _pour_sec() -> float:
	return float(cfg.get("pour_sec", 0.8))


func _band() -> Vector2:
	var band: Array = cfg.get("band", [0.62, 0.82])
	return Vector2(float(band[0]), float(band[1]))


func _ensure_cycles() -> void:
	var cycle: float = _cycle_sec()
	if cycle <= 0.0:
		return
	var idx: int = int(floorf(clock_sec / cycle))
	while _spawned_cycle_idx < idx:
		if _spawned_cycle_idx >= 0 and not _cycle_resolved and _token_id >= 0:
			_fail_token()
		_spawned_cycle_idx += 1
		_begin_cycle(_spawned_cycle_idx)


func _begin_cycle(cycle_idx: int) -> void:
	_holding = false
	_level = 0.0
	_phase = "fill"
	_pour_until = 0.0
	_cycle_resolved = false
	_overflow_failed = false
	var cycle_start: float = float(cycle_idx) * _cycle_sec()
	_token_id = _spawn({
		"cycle_idx": cycle_idx,
		"cycle_end": cycle_start + _cycle_sec(),
	})


func _judge_release() -> void:
	if _cycle_resolved:
		return
	var b: Vector2 = _band()
	var ok: bool = _level >= b.x and _level <= b.y
	_resolve(_token_id, ok, 1)
	_cycle_resolved = true
	_phase = "pour"
	_pour_until = clock_sec + _pour_sec()


func _fail_token() -> void:
	if _cycle_resolved or _token_id < 0 or not _live.has(_token_id):
		return
	_resolve(_token_id, false, 1)
	_cycle_resolved = true
	_holding = false
	_phase = "pour"
	_pour_until = clock_sec + _pour_sec()
