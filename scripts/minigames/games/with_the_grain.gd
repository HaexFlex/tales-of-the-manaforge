class_name WithTheGrain
extends Minigame
## One stroke along the grain. Curvy shapes take 6s on a phone and 4s otherwise.
## k comes from the average of those rounds.

var _k: float = 8.0
var _need: float = 0.75
var _round: float = 4.0
var _t: float = 0.0
var _shape_i: int = 0
var _points: PackedVector2Array = PackedVector2Array()
var _stroke: PackedVector2Array = PackedVector2Array()
var _drawing: bool = false
var _resolved: bool = false
var _dots: Node2D
var _ink: Line2D
var _ring: Sprite2D
var _phone: bool = false


func game_id() -> String:
	return "with_the_grain"


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	clip_contents = true
	_phone = Ui540.is_phone_export()
	_k = MinigameCatalog.k_for("with_the_grain", _phone)
	_need = float(MinigameCatalog.game("with_the_grain").get("accuracy", 0.75))
	MinigameArt.add_sprite(self, "bg_grass.png", Vector2(320, 160))
	## Opaque table stays inside the workpiece. The sprite's empty margin is above the board.
	var bench: Sprite2D = MinigameArt.add_sprite(self, "st_bench.png", Vector2(220, 65))
	bench.scale = Vector2(0.55, 0.55)
	var plank: Sprite2D = MinigameArt.add_sprite(self, "workpiece.png", Vector2(360, 170))
	plank.z_index = 1
	_dots = Node2D.new()
	_dots.name = "GrainPath"
	_dots.z_index = 3
	add_child(_dots)
	_ink = Line2D.new()
	_ink.width = 5.0
	_ink.default_color = Color8(62, 42, 24)
	_ink.joint_mode = Line2D.LINE_JOINT_ROUND
	_ink.z_index = 5
	add_child(_ink)
	_ring = MinigameArt.add_sprite(self, "start_ring.png", Vector2(140, 160))
	_ring.z_index = 4
	var pen: Sprite2D = MinigameArt.add_sprite(self, "pen.png", Vector2(560, 250))
	pen.z_index = 4
	_load_shape()


func _process(delta: float) -> void:
	if not playing:
		return
	_t += delta
	if _t >= _round:
		if not _resolved:
			if _drawing:
				_finish()
			else:
				_resolved = true
				miss()
		_t = 0.0
		_shape_i += 1
		_load_shape()


func _gui_input(event: InputEvent) -> void:
	if not playing or _resolved:
		return
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.button_index != MOUSE_BUTTON_LEFT:
			return
		if mb.pressed:
			_begin(mb.position)
		else:
			_finish()
	elif event is InputEventMouseMotion and _drawing:
		_stroke.append((event as InputEventMouseMotion).position)
		_ink.points = _stroke


func on_pointer_up() -> void:
	_finish()


func _begin(pos: Vector2) -> void:
	if _points.is_empty():
		return
	if pos.distance_to(_points[0]) > 36.0:
		return
	_drawing = true
	_stroke = PackedVector2Array()
	_stroke.append(pos)
	_ink.points = _stroke


func _finish() -> void:
	if not _drawing or _resolved:
		_drawing = false
		return
	_drawing = false
	_resolved = true
	if _accuracy() >= _need:
		succeed(_k)
	else:
		miss()


func _accuracy() -> float:
	if _points.is_empty() or _stroke.size() < 2:
		return 0.0
	var hit: int = 0
	var reach: float = 28.0 if _phone else 22.0
	for point: Vector2 in _points:
		var near: bool = false
		for sample: Vector2 in _stroke:
			if sample.distance_to(point) <= reach:
				near = true
				break
		if near:
			hit += 1
	return float(hit) / float(_points.size())


func _load_shape() -> void:
	_resolved = false
	_drawing = false
	_stroke = PackedVector2Array()
	_ink.clear_points()
	_round = MinigameCatalog.grain_round_seconds(_shape_i, _phone)
	var shapes: Array = MinigameCatalog.grain_shapes()
	var id: String = "rod"
	if not shapes.is_empty():
		var entry_v: Variant = shapes[posmod(_shape_i, shapes.size())]
		if typeof(entry_v) == TYPE_DICTIONARY:
			id = str((entry_v as Dictionary).get("id", "rod"))
	_points = _path_for(id)
	_paint_dots()
	if _ring != null and _points.size() > 0:
		_ring.position = _points[0]


func _paint_dots() -> void:
	if _dots == null:
		return
	for child: Node in _dots.get_children():
		child.queue_free()
	if _points.size() < 2:
		return
	var file: String = "dot_path_ph.png" if _phone else "dot_path.png"
	var step: float = 18.0 if _phone else 14.0
	var carried: float = step
	for i: int in _points.size() - 1:
		var a: Vector2 = _points[i]
		var b: Vector2 = _points[i + 1]
		var seg: float = a.distance_to(b)
		if seg <= 0.001:
			continue
		var walked: float = 0.0
		while carried + (seg - walked) >= step - 0.001:
			var need: float = step - carried
			walked += need
			_place_dot(file, a.lerp(b, clampf(walked / seg, 0.0, 1.0)))
			carried = 0.0
		carried += seg - walked
	_place_dot(file, _points[_points.size() - 1])


func _place_dot(file: String, at: Vector2) -> void:
	var spr: Sprite2D = MinigameArt.add_sprite(_dots, file, at)
	spr.z_index = 1


## Workpiece panel. The sprite is 424×272, centered at (360, 170).
const PANEL_ORIGIN := Vector2(148.0, 34.0)
const PANEL_SIZE := Vector2(424.0, 272.0)
var _rng_a: int = 0


func _path_for(id: String) -> PackedVector2Array:
	_rng_seed(12345 + _shape_i * 131)
	var norm: Array[Vector2] = _shape_norm(id)
	var pts := PackedVector2Array()
	for p: Vector2 in norm:
		pts.append(PANEL_ORIGIN + Vector2(p.x * PANEL_SIZE.x, p.y * PANEL_SIZE.y))
	return pts


func _shape_norm(id: String) -> Array[Vector2]:
	var n: int = 20
	if id == "head":
		var cx: float = _rng_range(0.35, 0.65)
		var cy: float = _rng_range(0.35, 0.65)
		var rad: float = _rng_range(0.18, 0.28)
		var a0: float = _rng_range(-PI / 4.0, PI / 4.0)
		var a1: float = a0 + _rng_range(PI * 0.6, PI * 1.1)
		var head: Array[Vector2] = []
		for i: int in n:
			var a: float = lerpf(a0, a1, float(i) / float(n - 1))
			head.append(Vector2(cx + cos(a) * rad, cy + sin(a) * rad))
		return head
	if id == "plank":
		var x0: float = _rng_range(0.15, 0.25)
		var y0: float = _rng_range(0.25, 0.4)
		var plank: Array[Vector2] = []
		for i: int in n:
			var t: float = float(i) / float(n - 1)
			var y: float = clampf(y0 + sin(t * PI * 1.5) * 0.12 + t * 0.35, 0.12, 0.88)
			plank.append(Vector2(lerpf(x0, 0.85, t), y))
		return plank
	if id == "rod":
		var rx0: float = _rng_range(0.15, 0.28)
		var ry0: float = _rng_range(0.3, 0.7)
		var rx1: float = _rng_range(0.72, 0.85)
		var ry1: float = _rng_range(0.3, 0.7)
		var rod: Array[Vector2] = []
		for i: int in n:
			var t: float = float(i) / float(n - 1)
			rod.append(Vector2(lerpf(rx0, rx1, t), lerpf(ry0, ry1, t)))
		return rod
	var poly: Array[Vector2] = _poly(id)
	if not poly.is_empty():
		var sampled: Array[Vector2] = _resample(poly, 32)
		for i: int in sampled.size():
			sampled[i] = Vector2(clampf(sampled[i].x, 0.08, 0.92), clampf(sampled[i].y, 0.1, 0.9))
		return sampled
	return _parametric(id)


func _poly(id: String) -> Array[Vector2]:
	var pts: Array[Vector2] = []
	if id == "zigzag":
		var y0: float = _rng_range(0.3, 0.4)
		pts = [Vector2(0.12, y0), Vector2(0.3, y0 + 0.36), Vector2(0.5, y0), Vector2(0.7, y0 + 0.36), Vector2(0.88, y0)]
	elif id == "arch":
		for i: int in 17:
			var a: float = PI * (1.0 - float(i) / 16.0)
			pts.append(Vector2(0.5 + 0.34 * cos(a), 0.78 - 0.55 * sin(a)))
	elif id == "vee":
		pts = [Vector2(0.18, 0.2), Vector2(0.5, 0.8), Vector2(0.82, 0.2)]
	elif id == "tick":
		pts = [Vector2(0.15, 0.5), Vector2(0.38, 0.78), Vector2(0.86, 0.18)]
	elif id == "stairs":
		pts = [Vector2(0.12, 0.8), Vector2(0.3, 0.8), Vector2(0.3, 0.6), Vector2(0.5, 0.6), Vector2(0.5, 0.4), Vector2(0.7, 0.4), Vector2(0.7, 0.2), Vector2(0.88, 0.2)]
	elif id == "diamond":
		pts = [Vector2(0.5, 0.12), Vector2(0.76, 0.5), Vector2(0.5, 0.88), Vector2(0.24, 0.5), Vector2(0.5, 0.14)]
	elif id == "hook":
		pts = [Vector2(0.34, 0.14), Vector2(0.34, 0.58)]
		for i: int in 14:
			var an: float = PI - PI * float(i + 1) / 14.0
			pts.append(Vector2(0.49 + 0.15 * cos(an), 0.58 + 0.24 * sin(an)))
		pts.append(Vector2(0.64, 0.45))
	return pts


func _parametric(id: String) -> Array[Vector2]:
	var m: int = 32
	var aspect: float = 272.0 / 424.0
	var cx: float = _rng_range(0.45, 0.55)
	var cy: float = _rng_range(0.46, 0.54)
	var pts: Array[Vector2] = []
	for i: int in m:
		var t: float = float(i) / float(m - 1)
		var turn: float = TAU * t
		var p := Vector2.ZERO
		if id == "s_curve":
			var ry: float = 0.2
			var rx: float = ry * aspect * 1.3
			if t < 0.5:
				var a: float = -PI / 4.0 - (t / 0.5) * (5.0 * PI / 4.0)
				p = Vector2(cx + rx * cos(a), cy - ry + ry * sin(a))
			else:
				var a2: float = -PI / 2.0 + ((t - 0.5) / 0.5) * (5.0 * PI / 4.0)
				p = Vector2(cx + rx * cos(a2), cy + ry + ry * sin(a2))
		elif id == "spiral":
			var ang: float = turn * 1.6
			var rr: float = 0.07 + 0.28 * t
			p = Vector2(cx + rr * aspect * cos(ang), cy + rr * sin(ang))
		elif id == "wave":
			p = Vector2(lerpf(0.12, 0.88, t), cy + 0.24 * sin(t * 3.0 * PI))
		elif id == "loop":
			p = Vector2(0.24 + 0.52 * t + 0.17 * sin(turn), 0.7 - 0.44 * (1.0 - cos(turn)) / 2.0)
		elif id == "heart":
			var s: float = sin(turn)
			var hx: float = 16.0 * s * s * s
			var hy: float = 13.0 * cos(turn) - 5.0 * cos(2.0 * turn) - 2.0 * cos(3.0 * turn) - cos(4.0 * turn)
			p = Vector2(cx + hx / 17.0 * 0.36 * aspect * 1.3, cy - 0.04 - hy / 17.0 * 0.36)
		elif id == "circle":
			var ca: float = -PI / 2.0 + turn * 0.97
			p = Vector2(cx + 0.3 * aspect * cos(ca), cy + 0.3 * sin(ca))
		elif id == "figure8":
			p = Vector2(cx + 0.3 * aspect * 1.3 * sin(turn), cy + 0.3 * sin(turn) * cos(turn) * 1.6)
		elif id == "crescent":
			var qa: float = PI * (0.25 + 1.5 * t)
			p = Vector2(cx + 0.32 * aspect * cos(qa), cy + 0.32 * sin(qa))
		elif id == "bell":
			var z: float = (t - 0.5) / 0.17
			p = Vector2(lerpf(0.12, 0.88, t), 0.72 - 0.44 * exp(-z * z))
		elif id == "leaf":
			var la: float = PI - turn
			var lobe: float = pow(absf(sin(la / 2.0 + PI / 2.0)), 0.9)
			p = Vector2(cx + 0.34 * aspect * 1.4 * cos(la), cy + 0.3 * sin(la) * lobe)
		else:
			p = Vector2(lerpf(0.15, 0.85, t), 0.5)
		pts.append(Vector2(clampf(p.x, 0.08, 0.92), clampf(p.y, 0.1, 0.9)))
	return pts


func _resample(pts: Array[Vector2], count: int) -> Array[Vector2]:
	var lengths: PackedFloat32Array = PackedFloat32Array()
	lengths.append(0.0)
	for i: int in range(1, pts.size()):
		var d: Vector2 = pts[i] - pts[i - 1]
		var step: float = Vector2(d.x * PANEL_SIZE.x, d.y * PANEL_SIZE.y).length()
		lengths.append(lengths[i - 1] + step)
	var out: Array[Vector2] = []
	var total: float = lengths[lengths.size() - 1]
	for j: int in count:
		var dist: float = total * float(j) / float(count - 1)
		var i: int = 1
		while i < lengths.size() - 1 and lengths[i] < dist:
			i += 1
		var span: float = maxf(0.000001, lengths[i] - lengths[i - 1])
		var u: float = (dist - lengths[i - 1]) / span
		out.append(pts[i - 1].lerp(pts[i], u))
	return out


func _rng_seed(seed: int) -> void:
	_rng_a = seed & 0xFFFFFFFF


func _rng_range(lo: float, hi: float) -> float:
	return lo + (hi - lo) * _rng_randf()


func _rng_randf() -> float:
	_rng_a = _i32(_rng_a)
	_rng_a = _i32(_rng_a + 0x6D2B79F5)
	var a: int = _rng_a
	var t: int = _imul(a ^ _ushr(a, 15), 1 | a)
	t = _i32((t + _imul(t ^ _ushr(t, 7), 61 | t)) ^ t)
	return float(_u32(t ^ _ushr(t, 14))) / 4294967296.0


func _u32(v: int) -> int:
	return v & 0xFFFFFFFF


func _i32(v: int) -> int:
	var u: int = _u32(v)
	if u >= 0x80000000:
		return u - 0x100000000
	return u


func _ushr(v: int, n: int) -> int:
	return _u32(v) >> n


func _imul(x: int, y: int) -> int:
	return _i32(_i32(x) * _i32(y))
