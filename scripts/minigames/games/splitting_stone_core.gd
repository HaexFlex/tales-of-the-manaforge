class_name SplittingStoneCore
extends MinigameCore

var _spawned_cycle_idx: int = -1
var _cycle_spots: Array[Vector2] = []
var _cycle_base: float = 0.0
var _cycle_successes: int = 0
var _spot_tokens: Array[int] = []
var _draw: Dictionary = {}


func _on_start() -> void:
	_spawned_cycle_idx = -1
	_cycle_spots.clear()
	_spot_tokens.clear()
	_cycle_successes = 0
	_draw = {"phase": "idle", "spots": [], "lit_index": -1, "lit_until": 0.0}
	_ensure_cycles()


func _on_advance(_real_dt: float) -> void:
	_ensure_cycles()
	_update_lit()
	_expire_tokens()


func _on_input(ev: Dictionary) -> void:
	if ev.get("type", "") != "press":
		return
	var lit_id: int = _lit_token_id()
	if lit_id < 0:
		return
	if clock_sec < _preview_end_for_current():
		return
	var info: Dictionary = _live[lit_id] as Dictionary
	var sx: float = float(info.get("x", 0.0))
	var sy: float = float(info.get("y", 0.0))
	var spot_idx: int = int(info.get("spot_index", 0))
	var radius: float = _spot_radius()
	var px: float = float(ev.get("x", -1.0))
	var py: float = float(ev.get("y", -1.0))
	var key: String = str(ev.get("key", ""))
	var hit: bool = false
	var wrong_key: bool = false
	if key in ["1", "2", "3"]:
		var order_idx: int = _spot_order_index(spot_idx)
		var pressed_idx: int = int(key) - 1
		if pressed_idx == order_idx:
			hit = true
		else:
			wrong_key = true
	else:
		var dist: float = Vector2(px - sx, py - sy).length()
		hit = dist <= radius
	if hit:
		_resolve(lit_id, true, 1)
		_cycle_successes += 1
		_draw["lit_index"] = -1
		if _cycle_successes >= _spot_count():
			perfect_cycle.emit()
	elif wrong_key or (px >= 0.0 and py >= 0.0):
		_resolve(lit_id, false, 1)
		_draw["lit_index"] = -1


func state() -> Dictionary:
	var st: Dictionary = _draw.duplicate(true)
	st["spots"] = _cycle_spots.duplicate()
	st["cycle_base"] = _cycle_base
	st["preview_sec"] = _preview_sec()
	st["window_sec"] = _window_sec()
	st["spot_radius"] = _spot_radius()
	return st


func _cycle_sec() -> float:
	return float(cfg.get("cycle_sec", 6.0))


func _preview_sec() -> float:
	return float(cfg.get("preview_sec", 0.6))


func _window_sec() -> float:
	return float(cfg.get("window_sec", 0.8))


func _spot_gap() -> float:
	return float(cfg.get("spot_gap_sec", 0.0))


func _spot_radius() -> float:
	return float(cfg.get("spot_radius", 0.06))


func _spot_count() -> int:
	return int(cfg.get("spots", 3))


func _preview_end_for_current() -> float:
	return _cycle_base + _preview_sec()


func _ensure_cycles() -> void:
	var cycle: float = _cycle_sec()
	if cycle <= 0.0:
		return
	var idx: int = int(floorf(clock_sec / cycle))
	while _spawned_cycle_idx < idx:
		_spawned_cycle_idx += 1
		_begin_cycle(_spawned_cycle_idx)


func _begin_cycle(cycle_idx: int) -> void:
	for tid: Variant in _live.keys():
		_resolve(int(tid), false, 1)
	_cycle_successes = 0
	_spot_tokens.clear()
	_cycle_base = float(cycle_idx) * _cycle_sec()
	_cycle_spots = _generate_spots()
	_draw = {
		"phase": "preview",
		"spots": _cycle_spots.duplicate(),
		"lit_index": -1,
		"lit_until": 0.0,
		"cycle_base": _cycle_base,
	}
	for i: int in range(_spot_count()):
		var start: float = _cycle_base + _preview_sec() + float(i) * (_window_sec() + _spot_gap())
		var end: float = start + _window_sec()
		var pos: Vector2 = _cycle_spots[i]
		var token_id: int = _spawn({
			"spot_index": i,
			"x": pos.x,
			"y": pos.y,
			"window_start": start,
			"window_end": end,
		})
		_spot_tokens.append(token_id)


func _generate_spots() -> Array[Vector2]:
	var count: int = _spot_count()
	var min_sep: float = _spot_radius() * 3.0
	var spots: Array[Vector2] = []
	var attempts: int = 0
	while spots.size() < count and attempts < 200:
		attempts += 1
		var p: Vector2 = Vector2(rng.randf_range(0.28, 0.72), rng.randf_range(0.38, 0.62))
		var ok: bool = true
		for other: Vector2 in spots:
			if p.distance_to(other) < min_sep:
				ok = false
				break
		if ok:
			spots.append(p)
	while spots.size() < count:
		spots.append(Vector2(0.35 + 0.12 * spots.size(), 0.5))
	return spots


func _spot_order_index(spot_index: int) -> int:
	var sorted: Array[int] = []
	for i: int in range(_cycle_spots.size()):
		sorted.append(i)
	sorted.sort_custom(func(a: int, b: int) -> bool:
		return _cycle_spots[a].x < _cycle_spots[b].x
	)
	for oi: int in range(sorted.size()):
		if sorted[oi] == spot_index:
			return oi
	return spot_index


func _lit_token_id() -> int:
	for tid: Variant in _live.keys():
		var info: Dictionary = _live[tid] as Dictionary
		var start: float = float(info.get("window_start", 0.0))
		var end: float = float(info.get("window_end", 0.0))
		if clock_sec >= start and clock_sec < end:
			return int(tid)
	return -1


func _update_lit() -> void:
	if _cycle_spots.is_empty():
		return
	if clock_sec < _cycle_base:
		return
	if clock_sec < _preview_end_for_current():
		_draw["phase"] = "preview"
		_draw["lit_index"] = -1
		return
	_draw["phase"] = "strike"
	var lit: int = -1
	var until: float = 0.0
	for i: int in range(_spot_count()):
		var start: float = _cycle_base + _preview_sec() + float(i) * (_window_sec() + _spot_gap())
		var end: float = start + _window_sec()
		if clock_sec >= start and clock_sec < end:
			lit = i
			until = end
			break
	_draw["lit_index"] = lit
	_draw["lit_until"] = until
	if lit < 0 and clock_sec >= _cycle_base + _preview_sec() + float(_spot_count()) * (_window_sec() + _spot_gap()):
		_draw["phase"] = "split"


func _expire_tokens() -> void:
	for tid: Variant in _live.keys():
		var info: Dictionary = _live[tid] as Dictionary
		if clock_sec >= float(info.get("window_end", 0.0)):
			_resolve(int(tid), false, 1)
