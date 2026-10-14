class_name SplittingStone
extends Minigame
## Three lit runes per boulder, on a 6s clock. Each rune in its window is one success.

var _k: float = 4.0
var _cycle: float = 6.0
var _preview: float = 0.6
var _window: float = 0.8
var _t: float = 0.0
var _spots: Array[Sprite2D] = []
var _resolved: Array[bool] = []
var _hit: Array[bool] = []


func game_id() -> String:
	return "splitting_stone"


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	var row: Dictionary = MinigameCatalog.game("splitting_stone")
	_k = MinigameCatalog.k_for("splitting_stone")
	_cycle = float(row.get("cycle_sec", 6.0))
	_preview = float(row.get("preview_sec", 0.6))
	_window = float(row.get("window_sec", 0.8))
	MinigameArt.add_sprite(self, "bg_grass.png", Vector2(320, 160))
	MinigameArt.add_sprite(self, "node_stone.png", Vector2(360, 168))
	MinigameArt.add_sprite(self, "keeper_pick_e.png", Vector2(150, 230), 9)
	var points: Array[Vector2] = [Vector2(292, 112), Vector2(430, 128), Vector2(352, 214)]
	for i: int in points.size():
		var spot: Sprite2D = MinigameArt.add_sprite(self, "spot_dim.png", _clamp_spot(points[i]))
		spot.z_index = 2
		_spots.append(spot)
		_resolved.append(false)
		_hit.append(false)


func _process(delta: float) -> void:
	if not playing:
		return
	_t += delta
	if _t >= _cycle:
		_t = 0.0
		_reset_spots()
	_paint()


func _gui_input(event: InputEvent) -> void:
	if not playing or not (event is InputEventMouseButton):
		return
	var mb: InputEventMouseButton = event as InputEventMouseButton
	if not mb.pressed or mb.button_index != MOUSE_BUTTON_LEFT:
		return
	_strike(_spot_at(mb.position))


func on_key(event: InputEvent) -> void:
	if not playing or not (event is InputEventKey):
		return
	var key: InputEventKey = event as InputEventKey
	if not key.pressed or key.echo:
		return
	if key.keycode == KEY_1:
		_strike(0)
	elif key.keycode == KEY_2:
		_strike(1)
	elif key.keycode == KEY_3:
		_strike(2)


func _strike(index: int) -> void:
	var lit: int = _lit_index()
	if lit < 0 or _resolved[lit]:
		return
	_resolved[lit] = true
	_hit[lit] = index == lit
	if _hit[lit]:
		succeed(_k)
	_paint()


func _lit_index() -> int:
	if _t < _preview:
		return -1
	var at: float = _t - _preview
	var index: int = int(floor(at / _window))
	if index < 0 or index >= _spots.size():
		return -1
	return index


func _spot_at(pos: Vector2) -> int:
	var best: int = -1
	var best_d: float = 38.0
	for i: int in _spots.size():
		var d: float = pos.distance_to(_spots[i].position)
		if d <= best_d:
			best_d = d
			best = i
	return best


func _paint() -> void:
	var lit: int = _lit_index()
	for i: int in _spots.size():
		var file: String = "spot_dim.png"
		if _resolved[i]:
			file = "spot_hit.png" if _hit[i] else "spot_miss.png"
		elif _t < _preview:
			file = "spot_next.png"
		elif i == lit:
			file = "spot_lit.png"
		var tex: Texture2D = MinigameArt.texture(file)
		if tex != null:
			_spots[i].texture = tex


func _reset_spots() -> void:
	for i: int in _spots.size():
		_resolved[i] = false
		_hit[i] = false


func _clamp_spot(pos: Vector2) -> Vector2:
	return Vector2(clampf(pos.x, 48.0, 592.0), clampf(pos.y, 48.0, 272.0))
