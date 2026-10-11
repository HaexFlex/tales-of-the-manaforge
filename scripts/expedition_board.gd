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
const ROOM_STEPS: Array[int] = [5, 10, 20, 40]
const DEPART_ESSENCE_COST: int = 20
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
var _members: Array[Dictionary] = [{"member": "keeper", "row": "front"}]
var _start_depth: int = 1
var _rooms: int = 5
var _control: String = "idle"
var _loadout_slots: Array[Dictionary] = [{"item": "", "qty": 0}, {"item": "", "qty": 0}]

var _layer: CanvasLayer
var _panel: Panel
var _depart: Button
var _lantern_lbl: Label
var _depth_lbl: Label
var _depth_minus: Button
var _depth_plus: Button
var _rooms_btn: Button
var _duration_lbl: Label
var _boss_lbl: Label
var _cost_lbl: Label
var _warning_lbl: Label
var _progress_lbl: Label
var _pack_lbl: Label
var _loadout_left_lbl: Label
var _member_keeper: Button
var _member_elaia: Button
var _row_keeper: Button
var _row_elaia: Button
var _idle_btn: Button
var _manual_btn: Button
var _loadout_item_btns: Array[Button] = []
var _loadout_minus_btns: Array[Button] = []
var _loadout_plus_btns: Array[Button] = []
var _loadout_qty_lbls: Array[Label] = []
var _party_title: Label
var _setup_nodes: Array[Control] = []
var _skip_btn: Button
var _rush_btn: Button
var _simulate_btn: Button
var _simulate_result: Label
var _sim_rng: RandomNumberGenerator = RandomNumberGenerator.new()
var last_sim: Dictionary = {}


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


func available_members() -> Array[String]:
	var out: Array[String] = ["keeper"]
	if GameState.elaia_portrait_visible():
		out.append("elaia")
	return out


func depth_checkpoints() -> Array[int]:
	var cap: int = 1
	if has_node("/root/Reach"):
		cap = Reach.max_start_depth()
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
		var row: String = _pick_row_for_new_member()
		_members.append({"member": member, "row": row})
	_refresh_shell()


func set_member_row(member: String, row: String) -> void:
	var idx := _member_index(member)
	if idx < 0:
		return
	var picked: String = "back" if row == "back" else "front"
	_members[idx]["row"] = picked
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
	_sync_depth_to_cap()
	return Reach.depart_slots(board_config())


func _on_hover(inside: bool) -> void:
	_hovered = inside
	if label:
		label.visible = _hovered
		label.text = ContentStrings.get_text("expedition_board_examine")


func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if not (event is InputEventMouseButton):
		return
	var mb: InputEventMouseButton = event
	if not mb.pressed:
		return
	if mb.button_index == MOUSE_BUTTON_LEFT:
		if GameState.member_away("keeper"):
			begin_entry()
		get_viewport().set_input_as_handled()
		return
	if mb.button_index == MOUSE_BUTTON_RIGHT:
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
	if _layer:
		_layer.visible = false
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
	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.03, 0.05, 0.06, 0.45)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_layer.add_child(dim)
	_panel = Panel.new()
	_panel.name = "Panel"
	_panel.anchor_left = 0.5
	_panel.anchor_top = 0.5
	_panel.anchor_right = 0.5
	_panel.anchor_bottom = 0.5
	_panel.offset_left = -300.0
	_panel.offset_top = -300.0
	_panel.offset_right = 300.0
	_panel.offset_bottom = 360.0
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.10, 0.09, 0.98)
	sb.border_color = Color(0.45, 0.55, 0.42, 1.0)
	sb.set_border_width_all(2)
	_panel.add_theme_stylebox_override("panel", sb)
	_layer.add_child(_panel)
	_make_label(_panel, "Title", Vector2(16, 8), Vector2(568, 24), 18, Color(0.86, 0.9, 0.78, 1)).text = ContentStrings.get_text("expedition_board_name")
	_make_label(_panel, "Hint", Vector2(16, 32), Vector2(568, 36), 13, Color(0.86, 0.88, 0.82, 1)).text = ContentStrings.get_text("expedition_board_hint")
	_lantern_lbl = _make_label(_panel, "Lantern", Vector2(16, 68), Vector2(568, 40), 13, Color(0.78, 0.86, 0.9, 1))
	_party_title = _make_label(_panel, "PartyTitle", Vector2(16, 112), Vector2(120, 24), 14, Color(0.82, 0.86, 0.78, 1))
	_party_title.text = ContentStrings.get_text("board_party_title")
	_member_keeper = _party_button("MemberKeeper", Vector2(16, 136), ContentStrings.get_text("char_sheet_title"))
	_row_keeper = _party_button("RowKeeper", Vector2(170, 136), ContentStrings.get_text("board_row_front"))
	_member_elaia = _party_button("MemberElaia", Vector2(280, 136), ContentStrings.get_text("echo_elaia_name"))
	_row_elaia = _party_button("RowElaia", Vector2(434, 136), ContentStrings.get_text("board_row_front"))
	_member_keeper.pressed.connect(_on_member_pressed.bind("keeper"))
	_member_elaia.pressed.connect(_on_member_pressed.bind("elaia"))
	_row_keeper.pressed.connect(_on_row_pressed.bind("keeper"))
	_row_elaia.pressed.connect(_on_row_pressed.bind("elaia"))
	_depth_lbl = _make_label(_panel, "DepthLabel", Vector2(16, 180), Vector2(200, 28), 15, Color(0.9, 0.88, 0.78, 1))
	_depth_minus = Button.new()
	_depth_minus.name = "DepthMinus"
	_depth_minus.text = "-"
	_depth_minus.position = Vector2(220, 176)
	_depth_minus.size = Vector2(48, 32)
	_panel.add_child(_depth_minus)
	_depth_minus.pressed.connect(_on_depth.bind(-1))
	_depth_plus = Button.new()
	_depth_plus.name = "DepthPlus"
	_depth_plus.text = "+"
	_depth_plus.position = Vector2(276, 176)
	_depth_plus.size = Vector2(48, 32)
	_panel.add_child(_depth_plus)
	_depth_plus.pressed.connect(_on_depth.bind(1))
	_rooms_btn = Button.new()
	_rooms_btn.name = "RoomsButton"
	_rooms_btn.position = Vector2(340, 176)
	_rooms_btn.size = Vector2(200, 32)
	_panel.add_child(_rooms_btn)
	_rooms_btn.pressed.connect(_on_rooms)
	_duration_lbl = _make_label(_panel, "DurationLabel", Vector2(16, 216), Vector2(360, 24), 14, Color(0.78, 0.84, 0.88, 1))
	_boss_lbl = _make_label(_panel, "BossLabel", Vector2(16, 244), Vector2(360, 24), 14, Color(0.95, 0.9, 0.72, 1))
	_idle_btn = _party_button("IdleButton", Vector2(16, 276), ContentStrings.get_text("board_row_front"))
	_manual_btn = _party_button("ManualButton", Vector2(180, 276), "Manual")
	_idle_btn.name = "IdleButton"
	_manual_btn.name = "ManualButton"
	_idle_btn.text = "Idle"
	_manual_btn.text = "Manual"
	_idle_btn.pressed.connect(_on_control.bind("idle"))
	_manual_btn.pressed.connect(_on_control.bind("manual"))
	for slot_i: int in range(2):
		var n: int = slot_i + 1
		var item_btn := Button.new()
		item_btn.name = "LoadoutItem%d" % n
		item_btn.position = Vector2(16, 316 + slot_i * 36)
		item_btn.size = Vector2(220, 32)
		item_btn.pressed.connect(_on_loadout_item.bind(slot_i))
		_panel.add_child(item_btn)
		_loadout_item_btns.append(item_btn)
		var minus_btn := Button.new()
		minus_btn.name = "LoadoutMinus%d" % n
		minus_btn.text = "-"
		minus_btn.position = Vector2(244, 316 + slot_i * 36)
		minus_btn.size = Vector2(40, 32)
		minus_btn.pressed.connect(_on_loadout_qty.bind(slot_i, -1))
		_panel.add_child(minus_btn)
		_loadout_minus_btns.append(minus_btn)
		var qty_lbl := _make_label(_panel, "LoadoutQty%d" % n, Vector2(290, 318 + slot_i * 36), Vector2(48, 28), 14, Color(0.9, 0.88, 0.82, 1))
		_loadout_qty_lbls.append(qty_lbl)
		var plus_btn := Button.new()
		plus_btn.name = "LoadoutPlus%d" % n
		plus_btn.text = "+"
		plus_btn.position = Vector2(344, 316 + slot_i * 36)
		plus_btn.size = Vector2(40, 32)
		plus_btn.pressed.connect(_on_loadout_qty.bind(slot_i, 1))
		_panel.add_child(plus_btn)
		_loadout_plus_btns.append(plus_btn)
	_cost_lbl = _make_label(_panel, "CostLabel", Vector2(16, 396), Vector2(540, 24), 13, Color(0.82, 0.88, 0.9, 1))
	_warning_lbl = _make_label(_panel, "WarningLabel", Vector2(16, 420), Vector2(540, 52), 12, Color(0.92, 0.82, 0.7, 1))
	_simulate_btn = Button.new()
	_simulate_btn.name = "SimulateButton"
	_simulate_btn.text = ContentStrings.get_text("board_simulate")
	_simulate_btn.position = Vector2(16, 476)
	_simulate_btn.size = Vector2(120, 32)
	_panel.add_child(_simulate_btn)
	_simulate_btn.pressed.connect(_on_simulate)
	_simulate_result = _make_label(_panel, "SimulateResult", Vector2(16, 512), Vector2(540, 96), 12, Color(0.82, 0.88, 0.9, 1))
	_simulate_result.max_lines_visible = 8
	_progress_lbl = _make_label(_panel, "ProgressLabel", Vector2(16, 180), Vector2(540, 28), 15, Color(0.9, 0.88, 0.78, 1))
	_pack_lbl = _make_label(_panel, "PackLabel", Vector2(16, 212), Vector2(540, 24), 14, Color(0.78, 0.84, 0.88, 1))
	_loadout_left_lbl = _make_label(_panel, "LoadoutLeftLabel", Vector2(16, 240), Vector2(540, 24), 14, Color(0.78, 0.84, 0.88, 1))
	_depart = Button.new()
	_depart.name = "Depart"
	_depart.text = "Depart"
	_depart.position = Vector2(16, 616)
	_depart.size = Vector2(200, 40)
	_depart.disabled = true
	_panel.add_child(_depart)
	_depart.pressed.connect(_on_depart)
	_skip_btn = Button.new()
	_skip_btn.name = "SkipRoom"
	_skip_btn.text = "Skip room"
	_skip_btn.position = Vector2(16, 528)
	_skip_btn.size = Vector2(160, 36)
	_panel.add_child(_skip_btn)
	_skip_btn.pressed.connect(_on_skip)
	_rush_btn = Button.new()
	_rush_btn.name = "Rush"
	_rush_btn.text = "Rush"
	_rush_btn.position = Vector2(188, 528)
	_rush_btn.toggle_mode = true
	_rush_btn.size = Vector2(120, 36)
	_panel.add_child(_rush_btn)
	_rush_btn.pressed.connect(_on_rush)
	_setup_nodes = [
		_party_title, _member_keeper, _row_keeper, _member_elaia, _row_elaia,
		_depth_lbl, _depth_minus, _depth_plus, _rooms_btn, _duration_lbl, _boss_lbl,
		_cost_lbl, _warning_lbl, _simulate_btn, _simulate_result, _depart,
	]
	for btn: Button in _loadout_item_btns:
		_setup_nodes.append(btn)
	for btn: Button in _loadout_minus_btns:
		_setup_nodes.append(btn)
	for btn: Button in _loadout_plus_btns:
		_setup_nodes.append(btn)
	for lbl: Label in _loadout_qty_lbls:
		_setup_nodes.append(lbl)
	_layer.visible = false


func _party_button(node_name: String, pos: Vector2, text: String) -> Button:
	var btn := Button.new()
	btn.name = node_name
	btn.position = pos
	btn.size = Vector2(140, 32)
	btn.toggle_mode = true
	btn.text = text
	_panel.add_child(btn)
	return btn


func _refresh_shell() -> void:
	if _member_keeper == null:
		return
	var running: bool = has_node("/root/Reach") and Reach.running
	_sync_depth_to_cap()
	for node: Control in _setup_nodes:
		if node != null and is_instance_valid(node):
			node.visible = not running
	_progress_lbl.visible = running
	_pack_lbl.visible = running
	_loadout_left_lbl.visible = running
	if _member_elaia != null:
		var show_elaia: bool = available_members().has("elaia")
		_member_elaia.visible = show_elaia
		_row_elaia.visible = show_elaia
	_member_keeper.button_pressed = _member_index("keeper") >= 0
	if _member_elaia != null:
		_member_elaia.button_pressed = _member_index("elaia") >= 0
	_row_keeper.disabled = _member_index("keeper") < 0
	_row_elaia.disabled = _member_index("elaia") < 0
	_row_keeper.text = _row_label_for("keeper")
	_row_elaia.text = _row_label_for("elaia")
	if _depth_lbl:
		_depth_lbl.text = ContentStrings.get_text("board_depth").replace("{d}", str(_start_depth))
	if _rooms_btn:
		_rooms_btn.text = ContentStrings.get_text("board_rooms").replace("{n}", str(_rooms))
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
	if _cost_lbl:
		_cost_lbl.text = ContentStrings.get_text("adv_depart_cost")
	if _warning_lbl:
		_warning_lbl.text = ContentStrings.get_text("adv_predeparture_warning")
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
	if _simulate_result != null and not running and last_sim.is_empty():
		_simulate_result.text = ""
	var blocked: bool = depart_disabled() or _members.is_empty() or GameState.essence < DEPART_ESSENCE_COST
	_depart.disabled = blocked
	if GameState.essence < DEPART_ESSENCE_COST and not depart_disabled() and not running:
		_depart.tooltip_text = ContentStrings.get_text("board_need_essence")
	else:
		_depart.tooltip_text = ""
	_depart.text = "Depart"
	var debug := has_node("/root/Reach") and Reach.debug_tools()
	if _skip_btn:
		_skip_btn.visible = debug
		_rush_btn.visible = debug
		_rush_btn.button_pressed = Reach.rush if debug else false
	_lantern_lbl.text = _lantern_line()


func _refresh_loadout_ui() -> void:
	for slot_i: int in range(2):
		var slot: Dictionary = _loadout_slots[slot_i]
		var item: String = str(slot.get("item", ""))
		var qty: int = int(slot.get("qty", 0))
		var item_btn: Button = _loadout_item_btns[slot_i]
		if item == "":
			item_btn.text = ContentStrings.get_text("adv_loadout_empty_slot")
		else:
			item_btn.text = Backpack.item_display_name(item)
		_loadout_qty_lbls[slot_i].text = str(qty)
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


func _on_member_pressed(member: String) -> void:
	toggle_member(member)


func _on_row_pressed(member: String) -> void:
	var idx := _member_index(member)
	if idx < 0:
		return
	var row: String = str(_members[idx].get("row", "front"))
	set_member_row(member, "back" if row == "front" else "front")


func _on_depth(step: int) -> void:
	var checkpoints: Array[int] = depth_checkpoints()
	var pos: int = checkpoints.find(_start_depth)
	if pos < 0:
		pos = 0
	pos = clampi(pos + step, 0, checkpoints.size() - 1)
	_start_depth = checkpoints[pos]
	_refresh_shell()


func _on_rooms() -> void:
	var idx := ROOM_STEPS.find(_rooms)
	_rooms = ROOM_STEPS[(idx + 1) % ROOM_STEPS.size()] if idx >= 0 else ROOM_STEPS[0]
	_refresh_shell()


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


func _on_skip() -> void:
	if has_node("/root/Reach"):
		Reach.debug_skip_room()
	_refresh_shell()


func _on_rush() -> void:
	if has_node("/root/Reach"):
		Reach.set_rush(_rush_btn.button_pressed if _rush_btn else false)
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
	_refresh_simulate_result()


func _refresh_simulate_result() -> void:
	if _simulate_result == null or last_sim.is_empty():
		return
	var lines: PackedStringArray = []
	var summary: String = ContentStrings.get_text("sim_summary")
	summary = summary.replace("{cleared}", str(int(last_sim.get("rooms_cleared", 0))))
	summary = summary.replace("{rooms}", str(int(last_sim.get("rooms_total", 0))))
	summary = summary.replace("{exp}", str(int(last_sim.get("exp", 0))))
	lines.append(summary)
	var lost_v: Variant = last_sim.get("lost", [])
	if lost_v is Array:
		for entry_v: Variant in lost_v as Array:
			if typeof(entry_v) != TYPE_DICTIONARY:
				continue
			lines.append(str((entry_v as Dictionary).get("reason", "")))
	var banked_v: Variant = last_sim.get("banked", {})
	var banked: Dictionary = banked_v if typeof(banked_v) == TYPE_DICTIONARY else {}
	var bank_line: String = ContentStrings.get_text("sim_banked").replace("{list}", _format_item_dict(banked))
	lines.append(bank_line)
	var used_v: Variant = last_sim.get("items_used", {})
	var used: Dictionary = used_v if typeof(used_v) == TYPE_DICTIONARY else {}
	if used.is_empty():
		lines.append(ContentStrings.get_text("sim_items_none"))
	else:
		lines.append(ContentStrings.get_text("sim_items_used").replace("{list}", _format_item_dict(used)))
	var essence_back: int = int(last_sim.get("essence_payback", 0))
	if essence_back > 0:
		lines.append(ContentStrings.get_text("sim_essence").replace("{n}", str(essence_back)))
	_simulate_result.text = "\n".join(lines)


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
	var checkpoints: Array[int] = depth_checkpoints()
	if checkpoints.is_empty():
		return
	if not checkpoints.has(_start_depth):
		_start_depth = checkpoints[0]


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
