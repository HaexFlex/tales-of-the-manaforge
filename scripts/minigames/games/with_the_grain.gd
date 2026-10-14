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
var _line: Line2D
var _ink: Line2D
var _ring: Sprite2D
var _phone: bool = false


func game_id() -> String:
	return "with_the_grain"


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_phone = Ui540.is_phone_export()
	_k = MinigameCatalog.k_for("with_the_grain", _phone)
	_need = float(MinigameCatalog.game("with_the_grain").get("accuracy", 0.75))
	MinigameArt.add_sprite(self, "bg_forge.png", Vector2(320, 160))
	var bench: Sprite2D = MinigameArt.add_sprite(self, "st_bench.png", Vector2(110, 80))
	bench.scale = Vector2(0.45, 0.45)
	var plank: Sprite2D = MinigameArt.add_sprite(self, "workpiece.png", Vector2(360, 170))
	plank.z_index = 1
	_line = Line2D.new()
	_line.width = 8.0
	_line.default_color = Color(0.62, 0.48, 0.28, 0.85)
	_line.joint_mode = Line2D.LINE_JOINT_ROUND
	_line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	_line.end_cap_mode = Line2D.LINE_CAP_ROUND
	_line.z_index = 2
	add_child(_line)
	_ink = Line2D.new()
	_ink.width = 5.0
	_ink.default_color = Color8(62, 42, 24)
	_ink.joint_mode = Line2D.LINE_JOINT_ROUND
	_ink.z_index = 3
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
		if _drawing and not _resolved:
			_finish()
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
	_line.points = _points
	if _ring != null and _points.size() > 0:
		_ring.position = _points[0]


func _path_for(id: String) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var steps: int = 28
	for i: int in steps:
		var t: float = float(i) / float(steps - 1)
		var p := Vector2(lerpf(150.0, 560.0, t), 170.0)
		if id == "head":
			p.y = 210.0 - sin(t * PI) * 110.0
		elif id == "plank":
			p.y = 170.0 + sin(t * TAU * 1.5) * 36.0
		pts.append(p)
	return pts
