class_name RipeCatchCore
extends MinigameCore

const CANOPY_Y: float = 0.125
const CATCH_Y: float = 0.79

var _spawned_cycle_idx: int = -1
var _basket_x: float = 0.5
var _streak: int = 0
var _berries: Array[Dictionary] = []
var _splats: Array[Dictionary] = []
var _rotten_spawn_ticks: int = 0
var _spawn_tick_count: int = 0


func _on_start() -> void:
	_spawned_cycle_idx = -1
	_basket_x = 0.5
	_streak = 0
	_berries.clear()
	_splats.clear()
	_rotten_spawn_ticks = 0
	_spawn_tick_count = 0
	_ensure_cycles()


func _on_advance(_real_dt: float) -> void:
	_ensure_cycles()
	_tick_berries()
	_trim_splats()


func _on_input(ev: Dictionary) -> void:
	var t: String = str(ev.get("type", ""))
	if t == "move":
		_set_basket_x(float(ev.get("x", _basket_x)))


func state() -> Dictionary:
	return {
		"basket_x": _basket_x,
		"basket_half_w": _basket_half_w(),
		"berries": _berries.duplicate(true),
		"splats": _splats.duplicate(true),
		"streak": _streak,
		"catch_y": CATCH_Y,
		"canopy_y": CANOPY_Y,
	}


func _cycle_sec() -> float:
	return float(cfg.get("cycle_sec", 1.5))


func _fall_sec() -> float:
	return float(cfg.get("fall_sec", 1.6))


func _basket_half_w() -> float:
	return float(cfg.get("basket_half_w", 0.07))


func _rotten_chance() -> float:
	return float(cfg.get("rotten_chance", 0.125))


func _spawn_x_range() -> Vector2:
	return Vector2(float(cfg.get("spawn_x_min", 0.04)), float(cfg.get("spawn_x_max", 0.96)))


func _set_basket_x(x: float) -> void:
	var hw: float = _basket_half_w()
	_basket_x = clampf(x, hw, 1.0 - hw)


func _ensure_cycles() -> void:
	var cycle: float = _cycle_sec()
	if cycle <= 0.0:
		return
	var idx: int = int(floorf(clock_sec / cycle))
	while _spawned_cycle_idx < idx:
		_spawned_cycle_idx += 1
		_spawn_tick_count += 1
		_spawn_ripe_for_cycle(_spawned_cycle_idx)
		if rng.randf() < _rotten_chance():
			_rotten_spawn_ticks += 1
			_spawn_rotten_berry()


func _spawn_ripe_for_cycle(cycle_idx: int) -> void:
	var xr: Vector2 = _spawn_x_range()
	var x: float = rng.randf_range(xr.x, xr.y)
	var spawn_at: float = float(cycle_idx) * _cycle_sec()
	var catch_at: float = spawn_at + _fall_sec()
	var token_id: int = _spawn({
		"kind": "ripe",
		"x": x,
		"spawn_at": spawn_at,
		"catch_at": catch_at,
	})
	_berries.append({
		"kind": "ripe",
		"x": x,
		"spawn_at": spawn_at,
		"catch_at": catch_at,
		"token_id": token_id,
	})


func _spawn_rotten_berry() -> void:
	var xr: Vector2 = _spawn_x_range()
	var x: float = rng.randf_range(xr.x, xr.y)
	var spawn_at: float = clock_sec
	var catch_at: float = spawn_at + _fall_sec()
	_berries.append({
		"kind": "rotten",
		"x": x,
		"spawn_at": spawn_at,
		"catch_at": catch_at,
		"token_id": -1,
	})


func _berry_y(spawn_at: float) -> float:
	var t: float = (clock_sec - spawn_at) / _fall_sec()
	return lerpf(CANOPY_Y, CATCH_Y, clampf(t, 0.0, 1.0))


func rotten_spawn_ticks() -> int:
	return _rotten_spawn_ticks


func spawn_tick_count() -> int:
	return _spawn_tick_count


func _tick_berries() -> void:
	for b: Dictionary in _berries:
		b["y"] = _berry_y(float(b.get("spawn_at", 0.0)))
	var i: int = _berries.size() - 1
	while i >= 0:
		var b: Dictionary = _berries[i]
		var catch_at: float = float(b.get("catch_at", 0.0))
		if clock_sec < catch_at:
			i -= 1
			continue
		var kind: String = str(b.get("kind", ""))
		var x: float = float(b.get("x", 0.5))
		if kind == "ripe":
			var token_id: int = int(b.get("token_id", -1))
			var hit: bool = absf(x - _basket_x) <= _basket_half_w()
			if hit:
				_streak += 1
			else:
				_splats.append({"x": x, "until": clock_sec + 0.35})
			if token_id >= 0:
				_resolve(token_id, hit, 1)
		elif kind == "rotten":
			if absf(x - _basket_x) <= _basket_half_w():
				_streak = 0
		_berries.remove_at(i)
		i -= 1


func _trim_splats() -> void:
	var out: Array[Dictionary] = []
	for s: Dictionary in _splats:
		if clock_sec < float(s.get("until", 0.0)):
			out.append(s)
	_splats = out
