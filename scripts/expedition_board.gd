extends Area2D
## Trailhead board. Lantern art can show dark, amber, or cyan.
## Depart starts a reach once the north road is open.

const DARK_ART: String = "res://assets/art/props/expedition_board/expedition_board_dark.png"
const AMBER_FRAMES: PackedStringArray = [
	"res://assets/art/props/expedition_board/expedition_board_amber_0001.png",
	"res://assets/art/props/expedition_board/expedition_board_amber_0002.png",
	"res://assets/art/props/expedition_board/expedition_board_amber_0003.png",
]
const CYAN_FRAMES: PackedStringArray = [
	"res://assets/art/props/expedition_board/expedition_board_cyan_0001.png",
	"res://assets/art/props/expedition_board/expedition_board_cyan_0002.png",
	"res://assets/art/props/expedition_board/expedition_board_cyan_0003.png",
	"res://assets/art/props/expedition_board/expedition_board_cyan_0004.png",
]
const EXCLAIM_ART: String = "res://assets/art/props/expedition_board/board_exclaim.png"
const FEET: Vector2 = Vector2(64, 135)
const WALK_BOX: Vector2 = Vector2(128, 45)
const EXCLAIM_OFFSET: Vector2 = Vector2(-5, -151)
const AMBER_FRAME_SEC: float = 0.10
const CYAN_FRAME_SEC: float = 0.15
const ROOM_MAX: int = 40
const DEPART_ESSENCE_COST: int = 20
const SHELL_SCENE: PackedScene = preload("res://scenes/ui/expedition_shell.tscn")
const BOARD_DIR: String = "res://assets/art/ui/board/"
## Stand point south of the feet. The Keeper's feet box (41 px tall) stops against the
## board's walk box at +41, so the stand must sit within ARRIVE_DIST of that contact.
## At +28 the Keeper stopped 13 px short and never arrived, so a click did nothing.
const ENTRY_OFFSET: Vector2 = Vector2(0, 44)

@onready var sprite: Sprite2D = $Visual/Sprite
@onready var exclaim: Sprite2D = $Visual/Exclaim
@onready var label: Label = $Label

var _amber: Array[Texture2D] = []
var _cyan: Array[Texture2D] = []
var _frame_i: int = 0
var _frame_t: float = 0.0
var _hovered: bool = false
var _members: Array[Dictionary] = [{"member": "keeper", "row": "front", "cell": 1}]
var _start_depth: int = 1
var _rooms: int = 1
var _control: String = "idle"
var _loadout_slots: Array[Dictionary] = [{"item": "", "qty": 0}, {"item": "", "qty": 0}]

var _layer: CanvasLayer
var _panel: Control
var _depart: Button
var _lantern_lbl: Label
var _shell_view: ExpeditionShellView
var _depth_lbl: Label
var _depth_minus: Button
var _depth_plus: Button
var _depth_field: LineEdit
var _rooms_lbl: Label
var _rooms_minus: Button
var _rooms_plus: Button
var _rooms_field: LineEdit
var _duration_lbl: Label
var _boss_lbl: Label
var _cost_lbl: Label
var _warning_lbl: Label
var _progress_lbl: Label
var _pack_lbl: Label
var _loadout_left_lbl: Label
var _party_slots: Dictionary = {}
var _picker_open: Dictionary = {}
var _simulate_modal: Control
var _simulate_window: Control
var _idle_btn: Button
var _manual_btn: Button
var _loadout_item_btns: Array[Button] = []
var _loadout_minus_btns: Array[Button] = []
var _loadout_plus_btns: Array[Button] = []
var _loadout_qty_lbls: Array[LineEdit] = []
var _party_title: Label
var _setup_nodes: Array[Control] = []
var _join_fight_btn: Button
var _simulate_btn: Button
var _simulate_result: Label
var _simulate_close: Button
var _close_btn: Button
var _sim_rng: RandomNumberGenerator = RandomNumberGenerator.new()
var last_sim: Dictionary = {}
var _depth_invalid: bool = false
var _rooms_invalid: bool = false
## Headless tests only: extra picker rows (member ids).
var _picker_test_extra: Array[String] = []


func _ready() -> void:
	add_to_group("expedition_board")
	add_to_group("interactable")
	y_sort_enabled = true
	input_pickable = true
	monitoring = false
	monitorable = true
	collision_layer = 4
	collision_mask = 0
	if label:
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.text = ContentStrings.get_text("expedition_board_name")
	mouse_entered.connect(_on_hover.bind(true))
	mouse_exited.connect(_on_hover.bind(false))
	_fit_art()
	_load_frames()
	_ensure_walk_body()
	input_event.connect(_on_input_event)
	if not GameState.echo_flags_changed.is_connected(_apply_lantern):
		GameState.echo_flags_changed.connect(_apply_lantern)
	if has_node("/root/Reach") and not Reach.changed.is_connected(_on_reach_changed):
		Reach.changed.connect(_on_reach_changed)
	_sim_rng.randomize()
	_apply_lantern()


func _exit_tree() -> void:
	if _layer != null and is_instance_valid(_layer):
		_layer.queue_free()
	_layer = null


func _unhandled_input(event: InputEvent) -> void:
	if not shell_open():
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		if _simulate_modal != null and _simulate_modal.visible:
			_close_simulate_window()
		else:
			close_shell()
		get_viewport().set_input_as_handled()


func _fit_art() -> void:
	if sprite:
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sprite.centered = false
		sprite.offset = Vector2(-FEET.x, -FEET.y)
	if exclaim:
		exclaim.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		exclaim.centered = false
		## Top-left of the mark, from the feet. board_info_v2.
		exclaim.position = EXCLAIM_OFFSET
		if ResourceLoader.exists(EXCLAIM_ART):
			exclaim.texture = load(EXCLAIM_ART) as Texture2D
		exclaim.visible = false
	var pick: CollisionShape2D = get_node_or_null("CollisionShape2D") as CollisionShape2D
	if pick and pick.shape is RectangleShape2D:
		var rect: RectangleShape2D = (pick.shape as RectangleShape2D).duplicate() as RectangleShape2D
		rect.size = Vector2(118, 129)
		pick.shape = rect
		pick.position = Vector2(0, -63.5)


func _load_frames() -> void:
	_amber = _load_list(AMBER_FRAMES)
	_cyan = _load_list(CYAN_FRAMES)


func _load_list(paths: PackedStringArray) -> Array[Texture2D]:
	var out: Array[Texture2D] = []
	for path: String in paths:
		if ResourceLoader.exists(path):
			var tex: Texture2D = load(path) as Texture2D
			if tex:
				out.append(tex)
	return out


func _ensure_walk_body() -> void:
	if get_node_or_null("WalkBody") != null:
		_walk = get_node_or_null("WalkBody/CollisionShape2D") as CollisionShape2D
		return
	var body := StaticBody2D.new()
	body.name = "WalkBody"
	body.collision_layer = 1
	body.collision_mask = 0
	body.input_pickable = false
	var shape_node := CollisionShape2D.new()
	shape_node.name = "CollisionShape2D"
	body.add_child(shape_node)
	add_child(body)
	FeetBox.apply_size(shape_node, WALK_BOX, Vector2.ZERO)
	_walk = shape_node


var _walk: CollisionShape2D


func _process(delta: float) -> void:
	var frames: Array[Texture2D] = _frames_for(lantern_state())
	if frames.size() <= 1 or sprite == null:
		return
	var step: float = CYAN_FRAME_SEC if lantern_state() == "cyan" else AMBER_FRAME_SEC
	_frame_t += delta
	if _frame_t < step:
		return
	_frame_t = 0.0
	_frame_i = (_frame_i + 1) % frames.size()
	sprite.texture = frames[_frame_i]
	if exclaim and lantern_state() == "cyan":
		exclaim.position = EXCLAIM_OFFSET + Vector2(0, -sin(_frame_i * 1.4))


func lantern_state() -> String:
	var state: String = GameState.expedition_lantern
	if state != "amber" and state != "cyan":
		return "dark"
	return state


func set_lantern(state: String) -> void:
	if state != "amber" and state != "cyan" and state != "dark":
		return
	GameState.expedition_lantern = state
	_frame_i = 0
	_frame_t = 0.0
	_apply_lantern()


func _frames_for(state: String) -> Array[Texture2D]:
	if state == "amber":
		return _amber
	if state == "cyan":
		return _cyan
	return []


func _apply_lantern() -> void:
	var state: String = lantern_state()
	var frames: Array[Texture2D] = _frames_for(state)
	if sprite:
		if frames.is_empty():
			if ResourceLoader.exists(DARK_ART):
				sprite.texture = load(DARK_ART) as Texture2D
		else:
			sprite.texture = frames[_frame_i % frames.size()]
	if exclaim:
		exclaim.visible = state == "cyan"
	if _lantern_lbl:
		_lantern_lbl.text = _lantern_line()


func _lantern_line() -> String:
	match lantern_state():
		"amber":
			return "%s\n%s" % [
				ContentStrings.get_text("lantern_lit"),
				ContentStrings.get_text("adventure_away"),
			]
		"cyan":
			return ContentStrings.get_text("lantern_done")
	return ContentStrings.get_text("lantern_dark")


func walk_box_size() -> Vector2:
	if _walk == null or not (_walk.shape is RectangleShape2D):
		return Vector2.ZERO
	return (_walk.shape as RectangleShape2D).size


func exclaim_visible() -> bool:
	return exclaim != null and exclaim.visible


func shell_starts_reach() -> bool:
	return true


func set_picker_test_extra(ids: Array) -> void:
	_picker_test_extra.clear()
	for id_v: Variant in ids:
		_picker_test_extra.append(str(id_v))


func available_members() -> Array[String]:
	var out: Array[String] = ["keeper"]
	for actor_id: String in CompanionRoster.ids():
		if GameState.companion_portrait_visible(actor_id) and not out.has(actor_id):
			out.append(actor_id)
	return out


func _party_full(member: String) -> bool:
	if _member_index(member) >= 0:
		return false
	return _members.size() >= CompanionRoster.party_cap()


func depth_checkpoints() -> Array[int]:
	return depth_range_list()


func depth_range() -> Vector2i:
	var cap: int = 1
	if has_node("/root/Reach"):
		cap = Reach.max_start_depth()
	return Vector2i(1, cap)


func depth_range_list() -> Array[int]:
	var cap: int = depth_range().y
	var out: Array[int] = [1]
	var step: int = 5
	while step <= cap:
		out.append(step)
		step += 5
	return out


func toggle_member(member: String) -> void:
	if not available_members().has(member):
		return
	var idx := _member_index(member)
	if idx >= 0:
		_members.remove_at(idx)
	else:
		if _party_full(member):
			return
		var row: String = _pick_row_for_new_member()
		var cell: int = _pick_cell_for_row(row)
		_members.append({"member": member, "row": row, "cell": cell})
	_refresh_shell()


func set_member_row(member: String, row: String) -> void:
	var idx := _member_index(member)
	if idx < 0:
		return
	var picked: String = "back" if row == "back" else "front"
	_members[idx]["row"] = picked
	if not _members[idx].has("cell"):
		_members[idx]["cell"] = _pick_cell_for_row(picked)
	_refresh_shell()


func place_member(member: String, row: String, cell: int) -> void:
	if _party_locked():
		return
	_ensure_shell()
	var picked_row: String = "back" if row == "back" else "front"
	var picked_cell: int = clampi(cell, 0, 2)
	if member == "":
		_remove_at_slot(picked_row, picked_cell)
		_refresh_shell()
		return
	if not available_members().has(member):
		return
	if _member_index(member) < 0 and _members.size() >= CompanionRoster.party_cap():
		return
	_remove_member(member)
	_remove_at_slot(picked_row, picked_cell)
	_members.append({"member": member, "row": picked_row, "cell": picked_cell})
	_refresh_shell()


func loadout_dict() -> Dictionary:
	var out: Dictionary = {}
	for slot: Dictionary in _loadout_slots:
		var item: String = str(slot.get("item", ""))
		var qty: int = int(slot.get("qty", 0))
		if item != "" and qty > 0:
			out[item] = qty
	return out


func board_config() -> Dictionary:
	return {
		"depth": _start_depth,
		"rooms": _rooms,
		"control": _control,
		"party": _members.duplicate(true),
		"loadout": loadout_dict(),
	}


func depart_disabled() -> bool:
	if not GameState.echo_02_resolved:
		return true
	if has_node("/root/Reach") and Reach.running:
		return true
	return false


func selected_party() -> Array[String]:
	var out: Array[String] = []
	for entry: Dictionary in _members:
		out.append(str(entry.get("member", "")))
	return out


func selected_route() -> String:
	return "north" if GameState.echo_02_resolved else ""


func try_depart() -> String:
	if not GameState.echo_02_resolved:
		return "closed"
	if not has_node("/root/Reach"):
		return "closed"
	if Reach.running:
		return "busy"
	if _members.is_empty():
		return "no_party"
	if GameState.essence < DEPART_ESSENCE_COST:
		return "no_essence"
	if _depth_field != null:
		_on_depth_field_commit(_depth_field.text)
	if _rooms_field != null:
		_on_rooms_field_commit(_rooms_field.text)
	_sync_depth_to_cap()
	return Reach.depart_slots(board_config())


func world_hover_name() -> String:
	return ContentStrings.get_text("expedition_board_name")


func _on_hover(inside: bool) -> void:
	_hovered = inside
	if label:
		## The papyrus hover names the board. The floating line sat on the post.
		label.visible = false
		label.text = ContentStrings.get_text("expedition_board_examine")
	WorldHover.sync(self, inside, world_hover_name())


func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if not (event is InputEventMouseButton):
		return
	var mb: InputEventMouseButton = event
	if not mb.pressed:
		return
	if mb.button_index == MOUSE_BUTTON_LEFT:
		if GameInput.yields_touch_double_tap(mb):
			return
		if GameInput.touch_mode() and GameInput.is_touch_pointer(mb) and GameState.member_away("keeper"):
			GameInput.defer_touch_tap(begin_entry)
		elif GameState.member_away("keeper"):
			begin_entry()
		get_viewport().set_input_as_handled()
		return
	if GameInput.is_command(mb):
		if GameState.member_away("keeper"):
			begin_entry()
		else:
			apply_player_command()
		get_viewport().set_input_as_handled()


func apply_player_command() -> void:
	if EchoChamber.in_battle:
		return
	if not GameState.keeper_selected:
		if GameState.member_away("keeper"):
			GameState.status_message.emit(ContentStrings.get_text("keeper_away_wait"))
		else:
			GameState.status_message.emit(ContentStrings.get_text("keeper_required"))
		return
	var keepers: Array[Node] = get_tree().get_nodes_in_group("keeper")
	if keepers.is_empty():
		return
	var k: Keeper = keepers[0] as Keeper
	if k:
		k.move_to(global_position + ENTRY_OFFSET, self)


func on_interact(_keeper: Node) -> void:
	begin_entry()


func road_open() -> bool:
	return GameState.echo_02_resolved


func begin_entry() -> String:
	## The click path. Until Bramble is spared or defeated the board teases the
	## shut road, the same way the thorn wall does, instead of opening the shell.
	if EchoChamber.in_battle:
		return "blocked"
	if not road_open():
		GameState.status_message.emit(ContentStrings.get_text("path_east_tease"))
		return "tease"
	open_shell()
	return "open"


func open_shell() -> void:
	_ensure_shell()
	_refresh_shell()
	_layer.visible = true
	_panel.visible = true
	GameAudio.play_ui_open()


func close_shell() -> void:
	_close_simulate_window()
	if _shell_view != null:
		_shell_view.hide_picker()
	if _layer:
		_layer.visible = false
	if _panel != null and is_instance_valid(_panel):
		_panel.visible = false
	GameAudio.play_ui_close()


func shell_open() -> bool:
	return _panel != null and is_instance_valid(_panel) and _panel.visible


func _ensure_shell() -> void:
	if _layer != null and is_instance_valid(_layer):
		return
	_layer = CanvasLayer.new()
	_layer.name = "ExpeditionShell"
	_layer.layer = 44
	_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().root.add_child(_layer)
	_shell_view = SHELL_SCENE.instantiate() as ExpeditionShellView
	_panel = _shell_view
	_layer.add_child(_shell_view)
	_party_slots = _shell_view.party_slots.duplicate()
	var panel: Control = _shell_view.get_node("Panel") as Control
	_lantern_lbl = panel.get_node("Lantern") as Label
	_party_title = panel.get_node("PartyTitle") as Label
	panel.get_node("PartyHint").text = "click a square to pick"
	_depth_lbl = panel.get_node("DepthLabel") as Label
	_depth_minus = panel.get_node("DepthMinus") as Button
	_depth_plus = panel.get_node("DepthPlus") as Button
	_depth_field = panel.get_node("DepthField") as LineEdit
	_rooms_lbl = panel.get_node("RoomsLabel") as Label
	_rooms_minus = panel.get_node("RoomsMinus") as Button
	_rooms_plus = panel.get_node("RoomsPlus") as Button
	_rooms_field = panel.get_node("RoomsField") as LineEdit
	_duration_lbl = panel.get_node("DurationLabel") as Label
	_boss_lbl = panel.get_node("BossLabel") as Label
	_idle_btn = panel.get_node("IdleButton") as Button
	_manual_btn = panel.get_node("ManualButton") as Button
	_cost_lbl = panel.get_node_or_null("CostLabel") as Label
	_warning_lbl = panel.get_node("BottomLeftCopy/WarningLabel") as Label
	_simulate_btn = panel.get_node("SimulateButton") as Button
	_depart = panel.get_node("Depart") as Button
	_close_btn = panel.get_node("CloseButton") as Button
	_progress_lbl = panel.get_node("ProgressLabel") as Label
	_pack_lbl = panel.get_node("PackLabel") as Label
	_loadout_left_lbl = panel.get_node("LoadoutLeftLabel") as Label
	_join_fight_btn = panel.get_node("JoinFightButton") as Button
	_loadout_item_btns.clear()
	_loadout_minus_btns.clear()
	_loadout_plus_btns.clear()
	_loadout_qty_lbls.clear()
	for slot_i: int in range(2):
		var n: int = slot_i + 1
		_loadout_item_btns.append(panel.get_node("LoadoutItem%d" % n) as Button)
		_loadout_minus_btns.append(panel.get_node("LoadoutMinus%d" % n) as Button)
		_loadout_plus_btns.append(panel.get_node("LoadoutPlus%d" % n) as Button)
		_loadout_qty_lbls.append(panel.get_node("LoadoutQty%d" % n) as LineEdit)
	_simulate_modal = _shell_view.simulate_modal
	_simulate_window = _shell_view.simulate_window
	_simulate_result = _shell_view.simulate_result
	_simulate_close = _shell_view.simulate_close
	panel.get_node("Title").text = ContentStrings.get_text("expedition_board_name")
	panel.get_node("Hint").text = ContentStrings.get_text("expedition_board_hint")
	_party_title.text = ContentStrings.get_text("board_party_title")
	_depth_minus.pressed.connect(_on_depth.bind(-1))
	_depth_plus.pressed.connect(_on_depth.bind(1))
	_depth_field.text_submitted.connect(_on_depth_field_commit)
	_depth_field.focus_exited.connect(_on_depth_field_commit.bind(_depth_field.text))
	_rooms_minus.pressed.connect(_on_rooms_step.bind(-1))
	_rooms_plus.pressed.connect(_on_rooms_step.bind(1))
	_rooms_field.text_submitted.connect(_on_rooms_field_commit)
	_rooms_field.focus_exited.connect(_on_rooms_field_commit.bind(_rooms_field.text))
	_idle_btn.pressed.connect(_on_control.bind("idle"))
	_manual_btn.pressed.connect(_on_control.bind("manual"))
	for slot_i: int in range(2):
		_loadout_item_btns[slot_i].pressed.connect(_on_loadout_item.bind(slot_i))
		_loadout_minus_btns[slot_i].pressed.connect(_on_loadout_qty.bind(slot_i, -1))
		_loadout_plus_btns[slot_i].pressed.connect(_on_loadout_qty.bind(slot_i, 1))
	_depart.pressed.connect(_on_depart)
	_close_btn.pressed.connect(close_shell)
	_simulate_btn.pressed.connect(_on_simulate)
	_simulate_close.pressed.connect(_close_simulate_window)
	_shell_view.simulate_rerun.pressed.connect(_on_simulate)
	if _join_fight_btn:
		_join_fight_btn.text = ContentStrings.get_text("adv_join_fight")
		_join_fight_btn.pressed.connect(_on_join_fight)
	for key: String in _party_slots.keys():
		var btn: Button = _party_slots[key] as Button
		var parts: PackedStringArray = key.split(":")
		btn.pressed.connect(_on_party_slot_pressed.bind(parts[0], int(parts[1])))
	for i: int in range(_shell_view.picker_rows.size()):
		_shell_view.picker_rows[i].pressed.connect(_on_picker_row.bind(i))
	_setup_nodes = [
		_party_title, _depth_lbl, _depth_minus, _depth_plus, _depth_field,
		_rooms_lbl, _rooms_minus, _rooms_plus, _rooms_field, _duration_lbl, _boss_lbl,
		_cost_lbl, _warning_lbl, _simulate_btn, _depart, _idle_btn, _manual_btn,
	]
	for btn: Button in _party_slots.values():
		_setup_nodes.append(btn)
	for btn: Button in _loadout_item_btns:
		_setup_nodes.append(btn)
	for btn: Button in _loadout_minus_btns:
		_setup_nodes.append(btn)
	for btn: Button in _loadout_plus_btns:
		_setup_nodes.append(btn)
	for field: LineEdit in _loadout_qty_lbls:
		_setup_nodes.append(field)
	_layer.visible = false


func _refresh_shell() -> void:
	if _depth_field == null:
		return
	var running: bool = has_node("/root/Reach") and Reach.running
	_sync_depth_to_cap()
	for node: Control in _setup_nodes:
		if node != null and is_instance_valid(node):
			node.visible = not running
	_progress_lbl.visible = running
	_pack_lbl.visible = running
	_loadout_left_lbl.visible = running
	_refresh_party_slots(running)
	if _depth_lbl:
		_depth_lbl.text = ContentStrings.get_text("board_depth").replace("{d}", "")
	if _depth_field and not _depth_field.has_focus():
		_depth_field.text = str(_start_depth)
	if _shell_view != null:
		_shell_view.set_field_invalid(_depth_field, _depth_invalid)
	if _rooms_lbl:
		var rooms_cap: String = ContentStrings.get_text("board_rooms").replace("{n}", "").strip_edges()
		if rooms_cap.is_empty():
			rooms_cap = "Rooms"
		elif rooms_cap.to_lower() == "rooms":
			rooms_cap = "Rooms"
		_rooms_lbl.text = rooms_cap
	if _rooms_field and not _rooms_field.has_focus():
		_rooms_field.text = str(_rooms)
	if _shell_view != null:
		_shell_view.set_field_invalid(_rooms_field, _rooms_invalid)
	var depth_max: Label = _panel.get_node("Panel/DepthMaxLabel") as Label if _panel != null else null
	if depth_max != null:
		depth_max.text = "max %d" % depth_range().y
	if _duration_lbl:
		var mins: int = _rooms * 12
		var h: int = mins / 60
		var m: int = mins % 60
		_duration_lbl.text = ContentStrings.get_text("board_duration").replace("{h}", str(h)).replace("{m}", str(m))
	if _boss_lbl:
		var bosses: int = _rooms / 10
		if bosses <= 0:
			_boss_lbl.text = ContentStrings.get_text("board_bosses_none")
		else:
			_boss_lbl.text = ContentStrings.get_text("board_bosses_up_to").replace("{n}", str(bosses))
	if _shell_view != null and _shell_view.has_method("reflow_footer_copy"):
		_shell_view.call("reflow_footer_copy")
	var mode_hint: Label = _panel.get_node("Panel/BottomLeftCopy/ModeHint") as Label if _panel != null else null
	if mode_hint != null:
		var hint_key: String = "board_mode_idle_hint" if _control == "idle" else "board_mode_manual_hint"
		var hint_txt: String = ContentStrings.get_text(hint_key)
		if hint_txt == hint_key:
			hint_txt = "Idle: the party walks and fights on its own." if _control == "idle" else "Manual: you choose each room."
		mode_hint.text = hint_txt
	var predeparture: String = ContentStrings.get_text("adv_predeparture_warning")
	if _warning_lbl:
		_warning_lbl.text = ContentStrings.get_text("adv_depart_cost")
		_warning_lbl.tooltip_text = predeparture
	if _cost_lbl != null:
		_cost_lbl.visible = false
	_idle_btn.button_pressed = _control == "idle"
	_manual_btn.button_pressed = _control == "manual"
	_refresh_loadout_ui()
	if running:
		var used: int = Reach.slots_used
		var total: int = Reach.slots_total
		var line: String = ContentStrings.get_text("board_progress").replace("{used}", str(used)).replace("{total}", str(total))
		if str(Reach.phase) == "rest":
			line = "%s — %s" % [line, ContentStrings.get_text("board_resting")]
		_progress_lbl.text = line
		var pack: Pack = Reach.pack
		_pack_lbl.text = ContentStrings.get_text("board_pack").replace("{n}", str(pack.total() if pack != null else 0))
		var list: String = _format_loadout_list(Reach.loadout)
		_loadout_left_lbl.text = ContentStrings.get_text("board_loadout_left").replace("{list}", list)
	if _simulate_btn != null:
		_simulate_btn.disabled = _members.is_empty()
	var blocked: bool = depart_disabled() or _members.is_empty() or GameState.essence < DEPART_ESSENCE_COST
	_depart.disabled = blocked
	if GameState.essence < DEPART_ESSENCE_COST and not depart_disabled() and not running:
		_depart.tooltip_text = "%s\n%s" % [ContentStrings.get_text("board_need_essence"), predeparture]
	else:
		_depart.tooltip_text = predeparture
	_depart.text = "Depart"
	var warn: Label = _panel.get_node("Panel/DepartEssenceWarn") as Label if _panel != null else null
	if warn != null:
		if GameState.essence < DEPART_ESSENCE_COST and not depart_disabled() and not running:
			warn.text = ContentStrings.get_text("board_depart_no_essence")
			warn.visible = true
		else:
			warn.visible = false
	var hint: Label = _panel.get_node("Panel/DepartHint") as Label if _panel != null else null
	if hint != null:
		hint.text = "You have %d" % GameState.essence
	var chip: NinePatchRect = _panel.get_node("Panel/CostChip") as NinePatchRect if _panel != null else null
	if chip != null:
		var short: bool = GameState.essence < DEPART_ESSENCE_COST
		var tex_path: String = BOARD_DIR + ("cost_chip_9s_short_24x32.png" if short else "cost_chip_9s_ok_24x32.png")
		chip.texture = load(tex_path) as Texture2D
	var can_join: bool = running and has_node("/root/Reach") and str(Reach.phase) in ["idle_room", "rest"]
	if _join_fight_btn:
		_join_fight_btn.visible = can_join
	_lantern_lbl.text = _lantern_line()


func _refresh_loadout_ui() -> void:
	for slot_i: int in range(2):
		var slot: Dictionary = _loadout_slots[slot_i]
		var item: String = str(slot.get("item", ""))
		var qty: int = int(slot.get("qty", 0))
		var item_btn: Button = _loadout_item_btns[slot_i]
		var name_lbl: Label = _panel.get_node("Panel/LoadoutName%d" % (slot_i + 1)) as Label
		if item == "":
			if name_lbl:
				var empty_txt: String = ContentStrings.get_text("adv_loadout_empty_slot")
				name_lbl.text = "%s\nclick to choose" % empty_txt
		else:
			if name_lbl:
				name_lbl.text = "%s\nYou have %d" % [Backpack.item_display_name(item), Backpack.get_count(item)]
		var qty_field: LineEdit = _loadout_qty_lbls[slot_i]
		if qty_field and not qty_field.has_focus():
			qty_field.text = str(qty)
		var cap: int = _loadout_cap(slot_i)
		_loadout_minus_btns[slot_i].disabled = qty <= 0 or item == ""
		_loadout_plus_btns[slot_i].disabled = item == "" or qty >= cap


func _format_loadout_list(loadout: Dictionary) -> String:
	if loadout.is_empty():
		return ContentStrings.get_text("adv_item_none_packed")
	var parts: PackedStringArray = []
	for key_v: Variant in loadout.keys():
		var item_id: String = str(key_v)
		var count: int = int(loadout.get(item_id, 0))
		if count <= 0:
			continue
		var line: String = ContentStrings.get_text("adv_item_count")
		line = line.replace("{item}", Backpack.item_display_name(item_id))
		line = line.replace("{count}", str(count))
		parts.append(line)
	if parts.is_empty():
		return ContentStrings.get_text("adv_item_none_packed")
	return ", ".join(parts)


func _owned_consumables() -> Array[String]:
	var out: Array[String] = []
	if not has_node("/root/Backpack"):
		return out
	for entry: Variant in Backpack.items_data:
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var iid: String = str((entry as Dictionary).get("id", ""))
		if iid == "":
			continue
		if Backpack.item_kind(iid) != "consumable":
			continue
		if Backpack.get_count(iid) > 0:
			out.append(iid)
	out.sort()
	return out


func _loadout_choices(slot_i: int) -> Array[String]:
	var choices: Array[String] = [""]
	var blocked: String = ""
	if slot_i == 1 and _loadout_slots[0].get("item", "") != "":
		blocked = str(_loadout_slots[0].get("item", ""))
	elif slot_i == 0 and _loadout_slots[1].get("item", "") != "":
		blocked = str(_loadout_slots[1].get("item", ""))
	for item_id: String in _owned_consumables():
		if item_id != blocked:
			choices.append(item_id)
	return choices


func _loadout_cap(slot_i: int) -> int:
	var item: String = str(_loadout_slots[slot_i].get("item", ""))
	if item == "":
		return 0
	return mini(100, Backpack.get_count(item))


func _on_reach_changed() -> void:
	if shell_open():
		_refresh_shell()
	_apply_lantern()


func _on_depth(step: int) -> void:
	var cap: int = depth_range().y
	_start_depth = clampi(_start_depth + step, 1, cap)
	_depth_invalid = false
	_refresh_shell()


func _on_depth_field_commit(text: String = "") -> void:
	var raw: String = text if text != "" else _depth_field.text
	var stripped: String = raw.strip_edges()
	var cap: int = depth_range().y
	if stripped == "" or not stripped.is_valid_int():
		_depth_invalid = true
		_start_depth = clampi(_start_depth, 1, cap)
	else:
		var parsed: int = int(stripped)
		if parsed < 1 or parsed > cap:
			_depth_invalid = true
			_start_depth = clampi(parsed, 1, cap)
		else:
			_depth_invalid = false
			_start_depth = parsed
	_refresh_shell()


func _on_rooms_step(step: int) -> void:
	_rooms = _rooms_step_value(_rooms, step)
	_rooms_invalid = false
	_refresh_shell()


func _on_rooms_field_commit(text: String = "") -> void:
	var raw: String = text if text != "" else _rooms_field.text
	var stripped: String = raw.strip_edges()
	if stripped == "" or not stripped.is_valid_int():
		_rooms_invalid = true
		_rooms = clampi(_rooms, 1, ROOM_MAX)
	else:
		var parsed: int = int(stripped)
		if parsed < 1 or parsed > ROOM_MAX:
			_rooms_invalid = true
			_rooms = clampi(parsed, 1, ROOM_MAX)
		else:
			_rooms_invalid = false
			_rooms = parsed
	_refresh_shell()


func _rooms_step_value(cur: int, dir: int) -> int:
	if dir > 0:
		if cur <= 1:
			return 5
		if cur >= ROOM_MAX:
			return ROOM_MAX
		if cur < 5:
			return 5
		return mini(ROOM_MAX, cur + 5)
	if cur <= 1:
		return 1
	if cur <= 5:
		return 1
	return maxi(5, cur - 5)


func _on_control(mode: String) -> void:
	_control = "manual" if mode == "manual" else "idle"
	if has_node("/root/Reach") and Reach.running:
		Reach.set_control(_control)
	_refresh_shell()


func _on_loadout_item(slot_i: int) -> void:
	var choices: Array[String] = _loadout_choices(slot_i)
	var cur: String = str(_loadout_slots[slot_i].get("item", ""))
	var pos: int = choices.find(cur)
	if pos < 0:
		pos = 0
	var next: String = choices[(pos + 1) % choices.size()]
	_loadout_slots[slot_i]["item"] = next
	_loadout_slots[slot_i]["qty"] = 0
	_refresh_shell()


func _on_loadout_qty(slot_i: int, delta: int) -> void:
	var item: String = str(_loadout_slots[slot_i].get("item", ""))
	if item == "":
		return
	var qty: int = int(_loadout_slots[slot_i].get("qty", 0))
	qty = clampi(qty + delta, 0, _loadout_cap(slot_i))
	_loadout_slots[slot_i]["qty"] = qty
	_refresh_shell()


func _on_join_fight() -> void:
	if has_node("/root/Reach"):
		Reach.set_control("manual")
	_refresh_shell()


func _on_depart() -> void:
	var result := try_depart()
	if result == "ok":
		close_shell()


func _on_simulate() -> void:
	if _members.is_empty():
		return
	var sim_seed: int = _sim_rng.randi() & 0x7FFFFFFF
	if has_node("/root/Reach"):
		while sim_seed == int(Reach.run_seed):
			sim_seed = _sim_rng.randi() & 0x7FFFFFFF
	last_sim = RunSim.simulate(board_config(), sim_seed)
	last_sim["sim_seed"] = sim_seed
	_open_simulate_window()


func _open_simulate_window() -> void:
	if _simulate_modal == null or last_sim.is_empty():
		return
	_refresh_simulate_result()
	_simulate_modal.visible = true


func _close_simulate_window() -> void:
	if _simulate_modal != null:
		_simulate_modal.visible = false


func _refresh_simulate_result() -> void:
	if _simulate_window == null or last_sim.is_empty() or _shell_view == null:
		return
	var header: Label = _simulate_window.get_node("SimulateHeader") as Label
	var summary_lbl: Label = _simulate_window.get_node("SimulateSummary") as Label
	var footer: VBoxContainer = _simulate_window.get_node("SimulateFooter") as VBoxContainer
	var losses_lbl: Label = footer.get_node("SimulateLosses") as Label if footer != null else null
	var banked_lbl: Label = footer.get_node("SimulateBanked") as Label if footer != null else null
	var used_lbl: Label = footer.get_node("SimulateUsed") as Label if footer != null else null
	var note_lbl: Label = footer.get_node("SimulateNote") as Label if footer != null else null
	var names: PackedStringArray = []
	for entry: Dictionary in _members:
		names.append(_member_display(str(entry.get("member", ""))))
	if header != null:
		header.text = "Depth %d · %d Rooms · %s · %s" % [
			_start_depth, _rooms, _control.capitalize(), ", ".join(names),
		]
	var summary: String = ContentStrings.get_text("sim_summary")
	summary = summary.replace("{cleared}", str(int(last_sim.get("rooms_cleared", 0))))
	summary = summary.replace("{rooms}", str(int(last_sim.get("rooms_total", 0))))
	summary = summary.replace("{exp}", str(int(last_sim.get("exp", 0))))
	if summary_lbl != null:
		summary_lbl.text = summary
	var lost_rooms: Dictionary = {}
	var lost_v: Variant = last_sim.get("lost", [])
	if lost_v is Array:
		for entry_v: Variant in lost_v as Array:
			if entry_v is Dictionary:
				var reason: String = str((entry_v as Dictionary).get("reason", ""))
				var room_i: int = reason.find("Room ")
				if room_i >= 0:
					var tail: String = reason.substr(room_i + 5)
					var num: int = int(tail.split(":")[0].split(" ")[0])
					if num > 0:
						lost_rooms[num] = true
	_shell_view.clear_simulate_rows()
	var log_v: Variant = last_sim.get("room_log", [])
	var row_i: int = 0
	if log_v is Array:
		for row_v: Variant in log_v as Array:
			if not row_v is Dictionary:
				continue
			var row: Dictionary = row_v as Dictionary
			var room_n: int = int(row.get("room", 0))
			var outcome: String = str(row.get("outcome", ""))
			var boss: bool = bool(row.get("boss", false))
			var beasts: int = int(row.get("beasts", 0))
			var beast_label: String = str(row.get("beast_label", ""))
			var left: String
			if boss:
				left = "Room %d · BOSS %s" % [room_n, beast_label if beast_label != "" else "boss"]
			else:
				left = "Room %d · %d beasts" % [room_n, maxi(beasts, 1)]
			var right: String = ""
			if outcome == "win":
				right = "cleared"
				if row.has("loot"):
					right += " · " + _format_item_dict(row.get("loot", {}) as Dictionary)
			elif outcome == "flee":
				right = "fled"
				if lost_v is Array:
					for entry_v: Variant in lost_v as Array:
						if entry_v is Dictionary and int((entry_v as Dictionary).get("room", -1)) == room_n:
							var reason: String = str((entry_v as Dictionary).get("reason", ""))
							if reason.find("below half") >= 0:
								right = "lost half the pack"
			elif outcome == "overwhelmed":
				right = "lost"
			else:
				right = outcome
			var kind: String = ""
			if lost_rooms.has(room_n) or outcome == "overwhelmed":
				kind = "loss"
			elif row_i % 2 == 0:
				kind = "even"
			var icon_kind: String = "boss" if boss else ("miss" if kind == "loss" else "good")
			_shell_view.add_simulate_row(left, right, kind, icon_kind)
			row_i += 1
	if losses_lbl != null:
		var lost_bits: PackedStringArray = []
		if lost_v is Array:
			for entry_v: Variant in lost_v as Array:
				if entry_v is Dictionary:
					lost_bits.append(str((entry_v as Dictionary).get("reason", "")))
		if lost_bits.is_empty():
			losses_lbl.text = "Lost: —"
		elif lost_bits.size() <= 3:
			losses_lbl.text = "Lost: " + " · ".join(lost_bits)
		else:
			var head: PackedStringArray = PackedStringArray()
			for i: int in range(3):
				head.append(lost_bits[i])
			losses_lbl.text = "Lost: " + " · ".join(head) + " · +%d more" % (lost_bits.size() - 3)
	var banked_v: Variant = last_sim.get("banked", {})
	var banked: Dictionary = banked_v if typeof(banked_v) == TYPE_DICTIONARY else {}
	var used_v: Variant = last_sim.get("items_used", {})
	var used: Dictionary = used_v if typeof(used_v) == TYPE_DICTIONARY else {}
	var essence_back: int = int(last_sim.get("essence_payback", 0))
	if banked_lbl != null:
		var bank_line: String = ContentStrings.get_text("sim_banked").replace("{list}", _format_item_dict(banked))
		if essence_back > 0:
			bank_line += "  " + ContentStrings.get_text("sim_essence").replace("{n}", str(essence_back))
		banked_lbl.text = bank_line
	if used_lbl != null:
		if used.is_empty():
			used_lbl.text = ContentStrings.get_text("sim_items_none")
		else:
			used_lbl.text = ContentStrings.get_text("sim_items_used").replace("{list}", _format_item_dict(used))
	if _shell_view != null and _shell_view.simulate_essence_icon != null:
		_shell_view.simulate_essence_icon.visible = essence_back > 0
	if note_lbl != null:
		var disc: String = ContentStrings.get_text("sim_forecast_note")
		if disc == "" or disc == "sim_forecast_note":
			disc = "A forecast with a random seed; the real run will differ."
		note_lbl.text = disc


func _format_item_dict(items: Dictionary) -> String:
	if items.is_empty():
		return ContentStrings.get_text("adv_item_none_packed")
	var parts: PackedStringArray = []
	for key_v: Variant in items.keys():
		var item_id: String = str(key_v)
		var count: int = int(items.get(item_id, 0))
		if count <= 0:
			continue
		var line: String = ContentStrings.get_text("adv_item_count")
		line = line.replace("{item}", Backpack.item_display_name(item_id))
		line = line.replace("{count}", str(count))
		parts.append(line)
	if parts.is_empty():
		return ContentStrings.get_text("adv_item_none_packed")
	return ", ".join(parts)


func _member_index(member: String) -> int:
	for i: int in range(_members.size()):
		if str(_members[i].get("member", "")) == member:
			return i
	return -1


func _pick_row_for_new_member() -> String:
	var front: int = 0
	var back: int = 0
	for entry: Dictionary in _members:
		if str(entry.get("row", "")) == "back":
			back += 1
		else:
			front += 1
	return "front" if front < 3 else "back"


func _row_label_for(member: String) -> String:
	var idx := _member_index(member)
	if idx < 0:
		return ContentStrings.get_text("board_row_front")
	var row: String = str(_members[idx].get("row", "front"))
	return ContentStrings.get_text("board_row_back") if row == "back" else ContentStrings.get_text("board_row_front")


func _sync_depth_to_cap() -> void:
	_start_depth = clampi(_start_depth, depth_range().x, depth_range().y)
	_rooms = clampi(_rooms, 1, ROOM_MAX)


func _party_locked() -> bool:
	return has_node("/root/Reach") and Reach.running


func _remove_member(member: String) -> void:
	var idx := _member_index(member)
	if idx >= 0:
		_members.remove_at(idx)


func _remove_at_slot(row: String, cell: int) -> void:
	for i: int in range(_members.size() - 1, -1, -1):
		var entry: Dictionary = _members[i]
		if str(entry.get("row", "")) == row and int(entry.get("cell", -1)) == cell:
			_members.remove_at(i)


func _running_party() -> Array[Dictionary]:
	if has_node("/root/Reach") and Reach.running:
		return Reach.party
	return _members


func _member_at_slot(row: String, cell: int) -> String:
	for entry: Dictionary in _running_party():
		if str(entry.get("row", "")) == row and int(entry.get("cell", -1)) == cell:
			return str(entry.get("member", ""))
	return ""


func _pick_cell_for_row(row: String) -> int:
	var used: Dictionary = {}
	for entry: Dictionary in _members:
		if str(entry.get("row", "")) == row:
			used[int(entry.get("cell", 1))] = true
	for cell: int in [1, 0, 2]:
		if not used.has(cell):
			return cell
	return 1


func _on_party_slot_pressed(row: String, cell: int) -> void:
	if _party_locked():
		return
	_picker_open = {"row": row, "cell": cell}
	_populate_picker(row, cell)
	var btn: Button = _party_slots.get("%s:%d" % [row, cell]) as Button
	if _shell_view != null and btn != null:
		_shell_view.place_picker(btn)


func _populate_picker(row: String, cell: int) -> void:
	if _shell_view == null:
		return
	var current: String = _member_at_slot(row, cell)
	var title: String = ContentStrings.get_text("board_who_stands")
	if title == "board_who_stands":
		title = "Who stands here?"
	_shell_view.picker_title.text = title
	var choices: Array[Dictionary] = []
	var listed: Dictionary = {}
	for member: String in available_members():
		choices.append(_picker_choice(member, row, cell, current))
		listed[member] = true
	for extra_id: String in _picker_test_extra:
		if extra_id != "" and not listed.has(extra_id):
			choices.append(_picker_choice(extra_id, row, cell, current))
			listed[extra_id] = true
	choices.append({
		"member": "",
		"label": "Leave empty",
		"sub": "clear this square",
		"state": "normal",
		"portrait": BOARD_DIR + "party_slot_empty_60x60.png",
		"locked": false,
	})
	_shell_view.ensure_picker_rows(choices.size())
	for i: int in range(_shell_view.picker_rows.size()):
		var btn: Button = _shell_view.picker_rows[i]
		if i >= choices.size():
			btn.visible = false
			continue
		btn.visible = true
		var choice: Dictionary = choices[i]
		btn.set_meta("pick_member", str(choice.get("member", "")))
		_shell_view.configure_picker_row(
			i,
			str(choice.get("label", "")),
			str(choice.get("sub", "")),
			str(choice.get("portrait", "")),
			str(choice.get("state", "normal")),
			bool(choice.get("locked", false)),
		)


func _picker_choice(member: String, row: String, cell: int, current: String) -> Dictionary:
	var sub: String = ""
	var state: String = "normal"
	var idx := _member_index(member)
	if idx >= 0:
		var e: Dictionary = _members[idx]
		if str(e.get("row", "")) == row and int(e.get("cell", -1)) == cell:
			sub = "Here now"
			state = "current"
		else:
			sub = "In the party (%s)" % ("Back" if str(e.get("row", "")) == "back" else "Front")
			state = "disabled"
	return {
		"member": member,
		"label": _member_display(member),
		"sub": sub,
		"state": state,
		"portrait": _portrait_path(member),
		"locked": false,
	}


func _on_picker_row(index: int) -> void:
	if _picker_open.is_empty():
		return
	var row: String = str(_picker_open.get("row", "front"))
	var cell: int = int(_picker_open.get("cell", 1))
	if index < 0 or index >= _shell_view.picker_rows.size():
		return
	var btn: Button = _shell_view.picker_rows[index]
	if bool(btn.get_meta("picker_locked", false)):
		return
	var member: String = str(btn.get_meta("pick_member", ""))
	place_member(member, row, cell)
	if _shell_view != null:
		_shell_view.hide_picker()
	_picker_open.clear()


func _refresh_party_slots(running: bool) -> void:
	var selected_key: String = ""
	if not _picker_open.is_empty():
		selected_key = "%s:%d" % [str(_picker_open.get("row", "")), int(_picker_open.get("cell", -1))]
	for key: String in _party_slots.keys():
		var btn: Button = _party_slots[key] as Button
		btn.disabled = running
		var parts: PackedStringArray = key.split(":")
		var member: String = _member_at_slot(parts[0], int(parts[1]))
		var style: String = "empty"
		if member != "":
			style = "filled"
		if key == selected_key:
			style = "selected"
		if _shell_view != null:
			_shell_view.set_party_slot_style(btn, style)
		for child: Node in btn.get_children():
			child.queue_free()
		if member != "":
			var portrait := TextureRect.new()
			portrait.texture = load(_portrait_path(member)) as Texture2D
			portrait.position = Vector2(4, 4)
			portrait.size = Vector2(52, 52)
			portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
			btn.add_child(portrait)


func _portrait_path(member: String) -> String:
	var row: Dictionary = CompanionRoster.row(member)
	var path: String = str(row.get("portrait_52", row.get("portrait_path", "")))
	if path != "" and ResourceLoader.exists(path):
		return path
	return BOARD_DIR + "party_slot_empty_60x60.png"


func _member_display(member: String) -> String:
	if member == "keeper" or CompanionRoster.has_id(member):
		return GameState.hero_display_name(member)
	return member.capitalize()


func _make_label(parent: Control, node_name: String, pos: Vector2, sz: Vector2, font_size: int, color: Color) -> Label:
	var lbl := Label.new()
	lbl.name = node_name
	lbl.position = pos
	lbl.size = sz
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.add_theme_font_size_override("font_size", font_size)
	lbl.add_theme_color_override("font_color", color)
	parent.add_child(lbl)
	return lbl
