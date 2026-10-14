class_name Steeping
extends Minigame
## Herbs flash an order, then go into the cauldron in that order.
## The cycle never starts the next one before 8 seconds. k is 16.

const HERB_COUNT: int = 5

var _k: float = 16.0
var _cycle: float = 8.0
var _show_for: float = 2.4
var _t: float = 0.0
var _order: Array[int] = []
var _step: int = 0
var _resolved: bool = false
var _showing: bool = true
var _replay: float = 0.0
var _slots: Array[TextureRect] = []
var _order_icons: Array[TextureRect] = []
var _cauldron: Sprite2D
var _drag_herb: int = -1
var _rng := RandomNumberGenerator.new()


func game_id() -> String:
	return "steeping"


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_k = MinigameCatalog.k_for("steeping")
	_cycle = MinigameCatalog.steeping_cycle()
	_rng.randomize()
	MinigameArt.add_sprite(self, "bg_forge.png", Vector2(320, 160))
	_cauldron = MinigameArt.add_sprite(self, "st_cauldron.png", Vector2(320, 150))
	_cauldron.z_index = 1
	var bubble: Sprite2D = MinigameArt.add_sprite(self, "order_bubble.png", Vector2(320, 42))
	bubble.z_index = 2
	for i: int in HERB_COUNT:
		var icon := TextureRect.new()
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		icon.z_index = 3
		icon.position = Vector2(160.0 + float(i) * 40.0, 22)
		icon.size = Vector2(32, 32)
		add_child(icon)
		_order_icons.append(icon)
		var slot := TextureRect.new()
		slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		slot.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		slot.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		slot.z_index = 3
		slot.texture = MinigameArt.herb_region(i)
		slot.position = Vector2(70.0 + float(i) * 104.0, 230)
		slot.size = Vector2(72, 72)
		add_child(slot)
		var frame: Sprite2D = MinigameArt.add_sprite(self, "slot_n.png", slot.position + slot.size * 0.5)
		frame.z_index = 2
		slot.set_meta("frame", frame)
		_slots.append(slot)
	_new_order()


func _process(delta: float) -> void:
	if not playing:
		return
	_t += delta
	if _replay > 0.0:
		_replay = maxf(0.0, _replay - delta)
	if _t >= _cycle:
		_t = 0.0
		_new_order()
	elif _showing and _t >= _show_for:
		_showing = false
	_paint()


func _gui_input(event: InputEvent) -> void:
	if not playing or not (event is InputEventMouseButton):
		return
	var mb: InputEventMouseButton = event as InputEventMouseButton
	if not mb.pressed or mb.button_index != MOUSE_BUTTON_LEFT:
		return
	if _cauldron != null and mb.position.distance_to(_cauldron.position) < 70.0 and _drag_herb >= 0:
		_pick(_drag_herb)
		_drag_herb = -1
		return
	var slot: int = _slot_at(mb.position)
	if slot >= 0:
		_drag_herb = slot
		_pick(slot)


func on_key(event: InputEvent) -> void:
	if not playing or not (event is InputEventKey):
		return
	var key: InputEventKey = event as InputEventKey
	if not key.pressed or key.echo:
		return
	if key.keycode == KEY_R:
		_replay = 1.4
		_showing = true
		return
	var index: int = -1
	match key.keycode:
		KEY_1:
			index = 0
		KEY_2:
			index = 1
		KEY_3:
			index = 2
		KEY_4:
			index = 3
		KEY_5:
			index = 4
	if index >= 0:
		_pick(index)


func _pick(index: int) -> void:
	if _resolved or _showing or _replay > 0.0:
		return
	if index < 0 or index >= HERB_COUNT or _step >= _order.size():
		return
	if index != _order[_step]:
		_resolved = true
		_paint()
		return
	_step += 1
	if _step >= _order.size():
		_resolved = true
		succeed(_k)
	_paint()


func _new_order() -> void:
	var row: Dictionary = MinigameCatalog.game("steeping")
	var lo: int = clampi(int(row.get("herb_min", 3)), 1, HERB_COUNT)
	var hi: int = clampi(int(row.get("herb_max", 5)), lo, HERB_COUNT)
	var count: int = _rng.randi_range(lo, hi)
	var bag: Array[int] = []
	for i: int in HERB_COUNT:
		bag.append(i)
	bag.shuffle()
	_order = []
	for i: int in count:
		_order.append(bag[i])
	_step = 0
	_resolved = false
	_showing = true
	_replay = 0.0
	_drag_herb = -1
	for icon: TextureRect in _order_icons:
		icon.texture = null
		icon.visible = false
	for i: int in _order.size():
		if i >= _order_icons.size():
			break
		_order_icons[i].texture = MinigameArt.herb_region(_order[i])
		_order_icons[i].visible = true


func _slot_at(pos: Vector2) -> int:
	for i: int in _slots.size():
		if Rect2(_slots[i].position, _slots[i].size).has_point(pos):
			return i
	return -1


func _paint() -> void:
	var flash: int = -1
	if (_showing or _replay > 0.0) and not _order.is_empty():
		var pulse: float = _t if _replay <= 0.0 else (1.4 - _replay)
		flash = _order[posmod(int(floor(pulse / 0.45)), _order.size())]
	for i: int in _slots.size():
		var frame: Sprite2D = _slots[i].get_meta("frame") as Sprite2D
		if frame == null:
			continue
		var file: String = "slot_n.png"
		if _resolved and _step < _order.size():
			file = "slot_bad.png" if i == _order[_step] else "slot_n.png"
		elif i == flash:
			file = "slot_h.png"
		elif _step > 0 and _order.slice(0, _step).has(i):
			file = "slot_ok.png"
		var tex: Texture2D = MinigameArt.texture(file)
		if tex != null:
			frame.texture = tex
