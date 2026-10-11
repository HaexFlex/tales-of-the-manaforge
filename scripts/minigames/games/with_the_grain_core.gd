class_name WithTheGrainCore
extends MinigameCore

const POINT_COUNT: int = 20

var _spawned_cycle_idx: int = -1
var _draw: Dictionary = {}
var _stroking: bool = false
var _stroke_samples: Array[Vector2] = []
var _pen: Vector2 = Vector2.ZERO
var _space_pen: bool = false
var _path_points: PackedVector2Array = PackedVector2Array()


func _on_start() -> void:
	_spawned_cycle_idx = -1
	_reset_draw()


func _on_advance(_real_dt: float) -> void:
	if _space_pen and _stroking:
		_advance_pen_keyboard(_real_dt)
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
	var out: Dictionary = _draw.duplicate(true)
	out["path"] = _pack_points(_path_points)
	if _stroking:
		out["stroke"] = _pack_points(_stroke_samples)
	else:
		out["stroke"] = []
	return out


func path_points() -> PackedVector2Array:
	return _path_points


func _on_press(ev: Dictionary) -> void:
	var token_id: int = int(_draw.get("token_id", -1))
	if token_id < 0 or not _live.has(token_id):
		return
	if bool(_draw.get("resolved", false)):
		return
	var key: String = str(ev.get("key", ""))
	if key == "space":
		_space_pen = true
		_begin_stroke(_path_points[0] if _path_points.size() > 0 else Vector2(0.5, 0.5))
		return
	if _stroking:
		return
	var px: float = float(ev.get("x", -1.0))
	var py: float = float(ev.get("y", -1.0))
	var start: Vector2 = _path_points[0] if _path_points.size() > 0 else Vector2(0.5, 0.5)
	var tol2: float = _tolerance() * 2.0
	if Vector2(px, py).distance_to(start) > tol2:
		return
	_begin_stroke(Vector2(px, py))


func _on_release(ev: Dictionary) -> void:
	var key: String = str(ev.get("key", ""))
	if key == "space":
		if _space_pen:
			_space_pen = false
			_end_stroke()
		return
	if _stroking:
		_end_stroke()


func _on_move(ev: Dictionary) -> void:
	if not _stroking:
		return
	if _space_pen:
		var px: float = float(ev.get("x", 0.5))
		var py: float = float(ev.get("y", 0.5))
		_pen = Vector2(px, py)
		_stroke_samples.append(_pen)
		_draw["stroke_len"] = _stroke_samples.size()
		return
	var px: float = float(ev.get("x", 0.5))
	var py: float = float(ev.get("y", 0.5))
	_stroke_samples.append(Vector2(px, py))
	_draw["stroke_len"] = _stroke_samples.size()


func _begin_stroke(at: Vector2) -> void:
	_stroking = true
	_stroke_samples.clear()
	_stroke_samples.append(at)
	_pen = at
	_draw["stroking"] = true


func _end_stroke() -> void:
	if not _stroking:
		return
	_stroking = false
	_draw["stroking"] = false
	var token_id: int = int(_draw.get("token_id", -1))
	if token_id < 0 or not _live.has(token_id):
		return
	if bool(_draw.get("resolved", false)):
		return
	_draw["resolved"] = true
	var acc: float = _accuracy(_stroke_samples, _path_points)
	_draw["accuracy"] = acc
	var ok: bool = acc >= _accuracy_min()
	_resolve(token_id, ok, 1)


func _advance_pen_keyboard(dt: float) -> void:
	var key: String = str(_draw.get("last_steer", ""))
	if key == "":
		return
	var speed: float = float(cfg.get("key_steer_speed", 1.2))
	var delta: Vector2 = Vector2.ZERO
	match key:
		"left", "a":
			delta.x = -speed * dt
		"right", "d":
			delta.x = speed * dt
		"up", "w":
			delta.y = -speed * dt
		"down", "s":
			delta.y = speed * dt
		_:
			return
	_pen += delta
	_pen.x = clampf(_pen.x, 0.05, 0.95)
	_pen.y = clampf(_pen.y, 0.05, 0.95)
	_stroke_samples.append(_pen)
	_draw["stroke_len"] = _stroke_samples.size()


func steer_key(key: String) -> void:
	_draw["last_steer"] = key


func _accuracy(samples: Array[Vector2], path: PackedVector2Array) -> float:
	if samples.is_empty() or path.is_empty():
		return 0.0
	var tol: float = _tolerance()
	var on_path: int = 0
	for p: Vector2 in samples:
		if _dist_to_polyline(p, path) <= tol:
			on_path += 1
	var share: float = float(on_path) / float(samples.size())
	var covered: int = 0
	for i: int in path.size():
		var cp: Vector2 = path[i]
		var hit: bool = false
		for p: Vector2 in samples:
			if p.distance_to(cp) <= tol:
				hit = true
				break
		if hit:
			covered += 1
	var cov: float = float(covered) / float(path.size())
	return minf(share, cov)


func _dist_to_polyline(p: Vector2, path: PackedVector2Array) -> float:
	var best: float = INF
	for i: int in path.size() - 1:
		var a: Vector2 = path[i]
		var b: Vector2 = path[i + 1]
		best = minf(best, _dist_point_segment(p, a, b))
	return best


func _dist_point_segment(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab: Vector2 = b - a
	var t: float = 0.0
	if ab.length_squared() > 0.000001:
		t = clampf((p - a).dot(ab) / ab.length_squared(), 0.0, 1.0)
	return p.distance_to(a + ab * t)


func _tolerance() -> float:
	return float(cfg.get("tolerance", 0.05))


func _accuracy_min() -> float:
	return float(cfg.get("accuracy_min", 0.75))


func _reset_draw() -> void:
	_draw = {
		"token_id": -1,
		"shape": "",
		"resolved": false,
		"accuracy": -1.0,
		"stroking": false,
		"stroke_len": 0,
		"last_steer": "",
	}


func _cycle_sec() -> float:
	return float(cfg.get("cycle_sec", 4.0))


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
	_stroking = false
	_space_pen = false
	_stroke_samples.clear()
	var shapes: Array = cfg.get("shapes", ["rod", "head", "plank"]) as Array
	var shape: String = str(shapes[rng.randi_range(0, shapes.size() - 1)])
	_path_points = _build_shape(shape, cycle_idx)
	_reset_draw()
	var cycle: float = _cycle_sec()
	var expire_at: float = float(cycle_idx + 1) * cycle
	var token_id: int = _spawn({
		"cycle_idx": cycle_idx,
		"shape": shape,
		"expire_at": expire_at,
	})
	_draw["token_id"] = token_id
	_draw["shape"] = shape


func _expire_tokens() -> void:
	for token_id: Variant in _live.keys():
		var info: Dictionary = _live[token_id] as Dictionary
		if clock_sec >= float(info.get("expire_at", 0.0)):
			_resolve(int(token_id), false, 1)
			if int(_draw.get("token_id", -1)) == int(token_id):
				_draw["token_id"] = -1
				_draw["resolved"] = true
			_stroking = false
			_space_pen = false


func _build_shape(shape: String, cycle_idx: int) -> PackedVector2Array:
	var pts: PackedVector2Array = PackedVector2Array()
	var n: int = POINT_COUNT
	var seed_off: int = cycle_idx * 131
	var local_rng := RandomNumberGenerator.new()
	local_rng.seed = int(rng.seed) + seed_off
	match shape:
		"head":
			var cx: float = local_rng.randf_range(0.35, 0.65)
			var cy: float = local_rng.randf_range(0.35, 0.65)
			var rad: float = local_rng.randf_range(0.18, 0.28)
			var a0: float = local_rng.randf_range(-PI * 0.25, PI * 0.25)
			var a1: float = a0 + local_rng.randf_range(PI * 0.6, PI * 1.1)
			for i: int in n:
				var t: float = float(i) / float(n - 1)
				var ang: float = lerpf(a0, a1, t)
				pts.append(Vector2(cx + cos(ang) * rad, cy + sin(ang) * rad))
		"plank":
			var x0: float = local_rng.randf_range(0.15, 0.25)
			var y0: float = local_rng.randf_range(0.25, 0.4)
			for i: int in n:
				var t: float = float(i) / float(n - 1)
				var x: float = lerpf(x0, 0.85, t)
				var y: float = y0 + sin(t * PI * 1.5) * 0.12 + t * 0.35
				pts.append(Vector2(x, clampf(y, 0.12, 0.88)))
		_:  # rod
			var x0: float = local_rng.randf_range(0.15, 0.28)
			var y0: float = local_rng.randf_range(0.3, 0.7)
			var x1: float = local_rng.randf_range(0.72, 0.85)
			var y1: float = local_rng.randf_range(0.3, 0.7)
			for i: int in n:
				var t: float = float(i) / float(n - 1)
				pts.append(Vector2(lerpf(x0, x1, t), lerpf(y0, y1, t)))
	return pts


func _pack_points(pts: PackedVector2Array) -> Array:
	var out: Array = []
	for p: Vector2 in pts:
		out.append({"x": p.x, "y": p.y})
	return out
