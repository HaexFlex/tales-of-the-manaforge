class_name SplittingStone
extends Minigame
## Three lit runes per boulder, on a 6s clock. Each rune in its window is one success.

var _k: float = 4.0
var _cycle: float = 6.0
var _preview: float = 0.6
var _window: float = 0.8
var _t: float = 0.0
var _spots: Array[Sprite2D] = []
var _numbers: Array[Label] = []
var _resolved: Array[bool] = []
var _hit: Array[bool] = []
var _miss_from: int = 0
var _keeper: Sprite2D
var _clock: float = 0.0
var _swing_at: float = -10.0
var _labels: Array[int] = [1, 2, 3]
## Which spot lights on each beat. A fresh permutation every boulder.
var _order: Array[int] = [0, 1, 2]
const RUNE_FONT: int = 26
## Impact of swing frame 6, relative to the sprite centre. The sheet is 384×272.
const KEEPER_POS := Vector2(228, 158)
const STONE_POS := Vector2(360, 168)
const PICK_TIP := Vector2(127, 12)


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
	MinigameArt.add_sprite(self, "node_stone.png", STONE_POS)
	_keeper = MinigameArt.add_sprite(self, "keeper_pick_e2.png", KEEPER_POS, 9)
	_keeper.z_index = 2
	for i: int in 3:
		var spot: Sprite2D = MinigameArt.add_sprite(self, "spot_dim.png", Vector2.ZERO)
		spot.name = "RuneSpot%d" % (i + 1)
		spot.z_index = 2
		_spots.append(spot)
		var number := Label.new()
		number.name = "Rune%d" % (i + 1)
		number.text = ""
		number.mouse_filter = Control.MOUSE_FILTER_IGNORE
		number.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		number.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		number.size = Vector2(40, 32)
		number.z_index = 4
		number.add_theme_font_size_override("font_size", RUNE_FONT)
		number.add_theme_color_override("font_color", Color8(255, 244, 192))
		add_child(number)
		_numbers.append(number)
		_resolved.append(false)
		_hit.append(false)
	_roll_spots()


func _process(delta: float) -> void:
	if not playing:
		return
	_clock += delta
	_t += delta
	_grade_passed()
	if _t >= _cycle:
		_grade_rest()
		_t = 0.0
		_reset_spots()
	_paint()
	_paint_keeper()


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
		_strike(_labels.find(1))
	elif key.keycode == KEY_2:
		_strike(_labels.find(2))
	elif key.keycode == KEY_3:
		_strike(_labels.find(3))


func _strike(index: int) -> void:
	var lit: int = _lit_index()
	if lit < 0 or _resolved[lit]:
		return
	_resolved[lit] = true
	_hit[lit] = index == lit
	if _hit[lit]:
		_swing_at = _clock
		succeed(_k, 1.0, _spots[lit].position)
	else:
		miss()
	_paint()
	_paint_keeper()


func _time_slot() -> int:
	if _t < _preview:
		return -1
	var at: float = _t - _preview
	var index: int = int(floor(at / _window))
	if index < 0 or index >= _order.size():
		return -1
	return index


func _lit_index() -> int:
	var slot: int = _time_slot()
	if slot < 0:
		return -1
	return _order[slot]


func _spot_at(pos: Vector2) -> int:
	var best: int = -1
	var best_d: float = 38.0
	for i: int in _spots.size():
		var d: float = pos.distance_to(_spots[i].position)
		if d <= best_d:
			best_d = d
			best = i
	return best


func _paint_keeper() -> void:
	if _keeper == null:
		return
	var age: float = _clock - _swing_at
	if age >= 0.0 and age < 0.45:
		_keeper.frame = mini(8, int(floor(age / 0.05)))
	else:
		_keeper.frame = 0


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
		if i < _numbers.size():
			var ink: Color = Color8(226, 255, 250) if i == lit else Color8(255, 244, 192)
			_numbers[i].add_theme_color_override("font_color", ink)


func _grade_passed() -> void:
	var slot: int = _time_slot()
	if slot < 0:
		return
	while _miss_from < slot and _miss_from < _order.size():
		_miss_slot(_miss_from)
		_miss_from += 1


func _grade_rest() -> void:
	for slot: int in range(_miss_from, _order.size()):
		_miss_slot(slot)
	_miss_from = 0


func _miss_slot(slot: int) -> void:
	var spot: int = _order[slot]
	if spot < 0 or spot >= _resolved.size() or _resolved[spot]:
		return
	_resolved[spot] = true
	miss()


func _reset_spots() -> void:
	_miss_from = 0
	for i: int in _spots.size():
		_resolved[i] = false
		_hit[i] = false
	_roll_spots()


## Clustered on the stone face, at least 60 px apart.
## Numbers follow position: 1 leftmost, 2 middle, 3 rightmost.
## The hit order is a fresh permutation of those positions.
const CLUSTER := Vector2(320, 224)
const CLUSTER_RX: float = 62.0
const CLUSTER_RY: float = 52.0
const CLUSTER_SEP: float = 60.0


func _roll_spots() -> void:
	var placed: Array[Vector2] = []
	for _attempt: int in 40:
		placed = _try_cluster()
		if placed.size() == _spots.size():
			break
	while placed.size() < _spots.size():
		var n: int = placed.size()
		placed.append(Vector2(224.0 + 76.8 * float(n), 160.0))
	placed.sort_custom(func(a: Vector2, b: Vector2) -> bool:
		return a.x < b.x or (is_equal_approx(a.x, b.x) and a.y < b.y)
	)
	_labels = [1, 2, 3]
	_order = [0, 1, 2]
	_order.shuffle()
	for i: int in _spots.size():
		_spots[i].position = placed[i]
		if i < _numbers.size():
			_numbers[i].text = str(_labels[i])
			_numbers[i].position = placed[i] + Vector2(-20, -16)


func _try_cluster() -> Array[Vector2]:
	var placed: Array[Vector2] = []
	var guard: int = 0
	while placed.size() < _spots.size() and guard < 400:
		guard += 1
		var angle: float = randf() * TAU
		var radius: float = sqrt(randf())
		var point := Vector2(
			CLUSTER.x + CLUSTER_RX * radius * cos(angle),
			CLUSTER.y + CLUSTER_RY * radius * sin(angle)
		)
		var clear: bool = true
		for other: Vector2 in placed:
			if other.distance_to(point) < CLUSTER_SEP:
				clear = false
				break
		if clear:
			placed.append(point)
	return placed
