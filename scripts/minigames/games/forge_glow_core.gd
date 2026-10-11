class_name ForgeGlowCore
extends MinigameCore

var _spawned_cycle_idx: int = -1
var _draw: Dictionary = {}


func _on_start() -> void:
	_spawned_cycle_idx = -1
	_draw = {
		"token_id": -1,
		"needle": 0.0,
		"sweet_lo": 0.0,
		"sweet_hi": 1.0,
		"resolved": false,
	}


func _on_advance(_real_dt: float) -> void:
	_update_needle()
	_expire_tokens()
	_ensure_cycles()


func _on_input(ev: Dictionary) -> void:
	var typ: String = str(ev.get("type", ""))
	if typ != "press":
		return
	var token_id: int = int(_draw.get("token_id", -1))
	if token_id < 0 or not _live.has(token_id):
		return
	if bool(_draw.get("resolved", false)):
		return
	_draw["resolved"] = true
	var sweet: Array = cfg.get("sweet", [0.55, 0.75]) as Array
	var lo: float = float(sweet[0])
	var hi: float = float(sweet[1])
	var needle: float = float(_draw.get("needle", 0.0))
	var ok: bool = needle >= lo and needle <= hi
	_resolve(token_id, ok, 1)


func state() -> Dictionary:
	return _draw.duplicate(true)


func needle_at_time(t: float) -> float:
	var cycle: float = _cycle_sec()
	if cycle <= 0.0:
		return 0.0
	var phase: float = fmod(t, cycle) / cycle
	return clampf(phase, 0.0, 1.0)


func _cycle_sec() -> float:
	return float(cfg.get("cycle_sec", 2.5))


func _update_needle() -> void:
	_draw["needle"] = needle_at_time(clock_sec)
	var sweet: Array = cfg.get("sweet", [0.55, 0.75]) as Array
	_draw["sweet_lo"] = float(sweet[0])
	_draw["sweet_hi"] = float(sweet[1])


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
	var cycle: float = _cycle_sec()
	var expire_at: float = float(cycle_idx + 1) * cycle
	var token_id: int = _spawn({
		"cycle_idx": cycle_idx,
		"expire_at": expire_at,
	})
	_draw = {
		"token_id": token_id,
		"needle": needle_at_time(clock_sec),
		"sweet_lo": float((cfg.get("sweet", [0.55, 0.75]) as Array)[0]),
		"sweet_hi": float((cfg.get("sweet", [0.55, 0.75]) as Array)[1]),
		"resolved": false,
	}


func _expire_tokens() -> void:
	for token_id: Variant in _live.keys():
		var info: Dictionary = _live[token_id] as Dictionary
		if clock_sec >= float(info.get("expire_at", 0.0)):
			_resolve(int(token_id), false, 1)
			if int(_draw.get("token_id", -1)) == int(token_id):
				_draw["token_id"] = -1
				_draw["resolved"] = true
