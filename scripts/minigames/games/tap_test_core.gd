class_name TapTestCore
extends MinigameCore

const SPOT_RADIUS: float = 0.08

var _spawned_cycle_idx: int = -1
var _draw_state: Dictionary = {}


func _on_start() -> void:
	_spawned_cycle_idx = -1
	_draw_state = {"active": false, "x": 0.5, "y": 0.5, "token_id": -1}


func _on_advance(_real_dt: float) -> void:
	_expire_tokens()
	_ensure_cycles()


func _on_input(ev: Dictionary) -> void:
	if ev.get("type", "") != "press":
		return
	var token_id: int = int(_draw_state.get("token_id", -1))
	if token_id < 0 or not _live.has(token_id):
		return
	var tx: float = float(_draw_state.get("x", 0.5))
	var ty: float = float(_draw_state.get("y", 0.5))
	var px: float = float(ev.get("x", -1.0))
	var py: float = float(ev.get("y", -1.0))
	var dist: float = Vector2(px - tx, py - ty).length()
	if dist <= SPOT_RADIUS:
		_resolve(token_id, true, 1)
		_draw_state["active"] = false
		_draw_state["token_id"] = -1
	else:
		_resolve(token_id, false, 1)
		_draw_state["active"] = false
		_draw_state["token_id"] = -1


func state() -> Dictionary:
	return _draw_state.duplicate(true)


func _cycle_sec() -> float:
	return float(cfg.get("cycle_sec", 2.0))


func _window_sec() -> float:
	return float(cfg.get("window_sec", 0.8))


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
	var x: float = rng.randf_range(0.12, 0.88)
	var y: float = rng.randf_range(0.12, 0.88)
	var expire_at: float = float(cycle_idx) * cycle + _window_sec()
	var token_id: int = _spawn({
		"x": x,
		"y": y,
		"expire_at": expire_at,
		"cycle_idx": cycle_idx,
	})
	_draw_state = {"active": true, "x": x, "y": y, "token_id": token_id, "expire_at": expire_at}


func _expire_tokens() -> void:
	for token_id: Variant in _live.keys():
		var info: Dictionary = _live[token_id] as Dictionary
		if clock_sec >= float(info.get("expire_at", 0.0)):
			_resolve(int(token_id), false, 1)
			if int(_draw_state.get("token_id", -1)) == int(token_id):
				_draw_state["active"] = false
				_draw_state["token_id"] = -1
