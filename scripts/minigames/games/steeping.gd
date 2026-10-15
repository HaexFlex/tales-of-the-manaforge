class_name Steeping
extends Minigame
## Herbs are shown, held, then picked. The world never offers this game.
## Show 1.2s per herb, hold 1s, input 10s, one replay, then a 0.8s gap. k is 21.2.

const HERB_COUNT: int = 5

var _k: float = 21.2
var _show_each: float = 1.2
var _hold: float = 1.0
var _input_sec: float = 10.0
var _input_left: float = 10.0
var _replays_max: int = 1
var _replays_left: int = 1
var _gap: float = 0.8
var _phase: String = "show"
var _phase_t: float = 0.0
var _order: Array[int] = []
var _step: int = 0
var _resolved: bool = false
var _slots: Array[TextureRect] = []
var _order_icons: Array[TextureRect] = []
var _cauldron: Sprite2D
var _drag_herb: int = -1
var _replay_btn: TextureButton
var _bar_fill: ColorRect
var _rng := RandomNumberGenerator.new()


func game_id() -> String:
	return "steeping"


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	var row: Dictionary = MinigameCatalog.game("steeping")
	_k = MinigameCatalog.k_for("steeping")
	_show_each = maxf(0.1, float(row.get("show_sec_per_herb", 1.2)))
	_hold = maxf(0.0, float(row.get("hold_sec", 1.0)))
	_input_sec = maxf(0.1, float(row.get("input_sec", 10.0)))
	_replays_max = maxi(0, int(row.get("replays", 1)))
	_gap = maxf(0.0, float(row.get("next_gap_sec", 0.8)))
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
	var track := ColorRect.new()
	track.name = "TimerTrack"
	track.mouse_filter = Control.MOUSE_FILTER_IGNORE
	track.color = Color8(52, 36, 24)
	track.position = Vector2(210, 80)
	track.size = Vector2(352, 8)
	track.z_index = 4
	add_child(track)
	_bar_fill = ColorRect.new()
	_bar_fill.name = "TimerFill"
	_bar_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bar_fill.color = Color8(143, 227, 230)
	_bar_fill.position = Vector2(210, 80)
	_bar_fill.size = Vector2(352, 8)
	_bar_fill.z_index = 5
	add_child(_bar_fill)
	_replay_btn = TextureButton.new()
	_replay_btn.name = "Replay"
	_replay_btn.position = Vector2(588, 26)
	_replay_btn.size = Vector2(44, 44)
	_replay_btn.ignore_texture_size = true
	_replay_btn.stretch_mode = TextureButton.STRETCH_KEEP
	_replay_btn.focus_mode = Control.FOCUS_NONE
	_replay_btn.z_index = 6
	_replay_btn.pressed.connect(_replay)
	add_child(_replay_btn)
	_new_order()


func _process(delta: float) -> void:
	if not playing:
		return
	_phase_t += delta
	if _phase == "show" and _phase_t >= _show_each * float(maxi(_order.size(), 1)):
		_phase = "hold"
		_phase_t = 0.0
	elif _phase == "hold" and _phase_t >= _hold:
		_phase = "input"
		_phase_t = 0.0
	elif _phase == "input":
		_input_left = maxf(0.0, _input_left - delta)
		if _input_left <= 0.0:
			_end_round(false)
	elif _phase == "gap" and _phase_t >= _gap:
		_new_order()
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
		_replay()
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
	if _resolved or _phase != "input":
		return
	if index < 0 or index >= HERB_COUNT or _step >= _order.size():
		return
	if index != _order[_step]:
		_end_round(false)
		return
	_step += 1
	if _step >= _order.size():
		_end_round(true)
	_paint()


func _replay() -> void:
	if _phase != "input" or _replays_left <= 0 or _resolved:
		return
	_replays_left -= 1
	_phase = "show"
	_phase_t = 0.0
	_step = 0
	_drag_herb = -1
	_paint()


func _end_round(ok: bool) -> void:
	if _resolved:
		return
	_resolved = true
	_phase = "gap"
	_phase_t = 0.0
	_drag_herb = -1
	if ok:
		succeed(_k)
	else:
		miss()
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
	_phase = "show"
	_phase_t = 0.0
	_input_left = _input_sec
	_replays_left = _replays_max
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
	var showing: bool = _phase == "show" or _phase == "hold"
	var revealed: int = _order.size()
	if _phase == "show":
		revealed = clampi(int(floor(_phase_t / _show_each)) + 1, 0, _order.size())
	elif _phase == "input":
		revealed = _step
	for i: int in _order_icons.size():
		var show_icon: bool = i < _order.size() and (showing or _phase == "gap" or i < revealed)
		_order_icons[i].visible = show_icon
	var flash: int = -1
	if _phase == "show" and revealed > 0:
		flash = _order[revealed - 1]
	for i: int in _slots.size():
		var frame: Sprite2D = _slots[i].get_meta("frame") as Sprite2D
		if frame == null:
			continue
		var file: String = "slot_n.png"
		if _resolved and _phase == "gap" and _step < _order.size() and i == _order[_step]:
			file = "slot_bad.png"
		elif i == flash:
			file = "slot_h.png"
		elif _step > 0 and _order.slice(0, _step).has(i):
			file = "slot_ok.png"
		var tex: Texture2D = MinigameArt.texture(file)
		if tex != null:
			frame.texture = tex
	if _bar_fill != null:
		var frac: float = 1.0
		if _phase == "input":
			frac = clampf(_input_left / _input_sec, 0.0, 1.0)
		elif _phase == "gap":
			frac = 0.0
		_bar_fill.size = Vector2(roundf(352.0 * frac), 8.0)
		_bar_fill.color = Color8(224, 150, 58) if frac < 0.3 else Color8(143, 227, 230)
	if _replay_btn != null:
		var live: bool = _phase == "input" and _replays_left > 0
		var face: Texture2D = MinigameArt.texture("btn_replay.png" if live else "btn_replay_off.png")
		_replay_btn.texture_normal = face
		_replay_btn.texture_hover = face
		_replay_btn.texture_pressed = face
		_replay_btn.disabled = not live
		_replay_btn.tooltip_text = "See the order again" if live else "Replay spent"
