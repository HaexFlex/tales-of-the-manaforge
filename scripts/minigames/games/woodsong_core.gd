class_name WoodsongCore
extends MinigameCore

var _spawned_beat_idx: int = 0
var _beat_cue_times: Array[float] = []
var _scroll_origin: float = 0.0


func _on_start() -> void:
	_spawned_beat_idx = 0
	_beat_cue_times.clear()
	_scroll_origin = 0.0


func _on_advance(_real_dt: float) -> void:
	_ensure_beats()
	_expire_beats()


func _on_input(ev: Dictionary) -> void:
	if ev.get("type", "") != "press":
		return
	if _live.is_empty():
		return
	var best_id: int = -1
	var best_dist: float = 1e9
	for tid: Variant in _live.keys():
		var info: Dictionary = _live[tid] as Dictionary
		var beat_t: float = float(info.get("beat_time", 0.0))
		var dist: float = absf(clock_sec - beat_t)
		if dist < best_dist:
			best_dist = dist
			best_id = int(tid)
	if best_id < 0:
		return
	var info: Dictionary = _live[best_id] as Dictionary
	var beat_t: float = float(info.get("beat_time", 0.0))
	var win: float = _window_sec()
	if absf(clock_sec - beat_t) <= win:
		var weight: int = int(info.get("weight", 1))
		_resolve(best_id, true, weight)


func state() -> Dictionary:
	return {
		"bpm": _bpm(),
		"beats": _live_beats_for_view(),
		"beat_px": 70.0,
		"notch_x": 0.13,
		"lane_y0": 0.04,
		"lane_y1": 0.16,
		"scroll_sec": clock_sec,
	}


func _bpm() -> float:
	return float(cfg.get("bpm", 48.0))


func _window_sec() -> float:
	return float(cfg.get("window_ms", 180.0)) / 1000.0


func _latency_sec() -> float:
	return float(cfg.get("latency_ms", 0.0)) / 1000.0


func _heavy_every() -> int:
	return int(cfg.get("heavy_every", 8))


func _heavy_weight() -> int:
	return int(cfg.get("heavy_weight", 2))


func _beat_time(beat_i: int) -> float:
	return float(beat_i) * 60.0 / _bpm() + _latency_sec()


func _beat_weight(beat_i: int) -> int:
	if _heavy_every() > 0 and beat_i % _heavy_every() == 0:
		return _heavy_weight()
	return 1


func _ensure_beats() -> void:
	var dt: float = 1.0 / 60.0
	while true:
		var beat_i: int = _spawned_beat_idx + 1
		var t: float = _beat_time(beat_i)
		var open_at: float = t - _window_sec()
		if clock_sec + dt < open_at:
			break
		_spawned_beat_idx = beat_i
		var w: int = _beat_weight(beat_i)
		_spawn({
			"beat_index": beat_i,
			"beat_time": t,
			"window_start": open_at,
			"window_end": t + _window_sec(),
			"weight": w,
			"heavy": w > 1,
		})


func _expire_beats() -> void:
	for tid: Variant in _live.keys():
		var info: Dictionary = _live[tid] as Dictionary
		if clock_sec > float(info.get("window_end", 0.0)):
			_resolve(int(tid), false, int(info.get("weight", 1)))


func _live_beats_for_view() -> Array:
	var out: Array = []
	for tid: Variant in _live.keys():
		var info: Dictionary = (_live[tid] as Dictionary).duplicate(true)
		info["token_id"] = int(tid)
		out.append(info)
	return out
