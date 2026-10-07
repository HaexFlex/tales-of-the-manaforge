extends Area2D
## Trailhead board. Lantern art can show dark, amber, or cyan.
## Depart starts a reach once the north road is open. Party is the Keeper alone.

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
var _party: Array[String] = ["keeper"]
var _route: String = "north"
var _walk: CollisionShape2D
var _start_depth: int = 1
var _hours: int = 1
var _pace: String = "hold"
var _control: String = "idle"

var _layer: CanvasLayer
var _panel: Panel
var _depart: Button
var _route_btn: Button
var _keeper_btn: Button
var _elaia_btn: Button
var _lantern_lbl: Label
var _depth_lbl: Label
var _hours_btn: Button
var _hold_btn: Button
var _push_btn: Button
var _idle_btn: Button
var _manual_btn: Button
var _odds_lbl: Label
var _skip_btn: Button
var _rush_btn: Button


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


func depart_disabled() -> bool:
	if not GameState.echo_02_resolved:
		return true
	if has_node("/root/Reach") and Reach.running:
		return true
	return false


func selected_party() -> Array[String]:
	return _party.duplicate()


func selected_route() -> String:
	return _route


func try_depart() -> String:
	if not GameState.echo_02_resolved:
		return "closed"
	if not has_node("/root/Reach"):
		return "closed"
	if Reach.running:
		return "busy"
	_start_depth = clampi(_start_depth, 1, Reach.max_start_depth())
	return Reach.depart(_start_depth, float(_hours), _pace, _control)


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
		get_viewport().set_input_as_handled()
		return
	if mb.button_index == MOUSE_BUTTON_RIGHT:
		apply_player_command()
		get_viewport().set_input_as_handled()


func apply_player_command() -> void:
	if EchoChamber.in_battle:
		return
	if not GameState.keeper_selected:
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
	_panel.offset_left = -280.0
	_panel.offset_top = -280.0
	_panel.offset_right = 280.0
	_panel.offset_bottom = 280.0
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.10, 0.09, 0.98)
	sb.border_color = Color(0.45, 0.55, 0.42, 1.0)
	sb.set_border_width_all(2)
	_panel.add_theme_stylebox_override("panel", sb)
	_layer.add_child(_panel)
	_make_label(_panel, "Title", Vector2(16, 12), Vector2(468, 28), 18, Color(0.86, 0.9, 0.78, 1)).text = ContentStrings.get_text("expedition_board_name")
	_make_label(_panel, "Hint", Vector2(16, 44), Vector2(468, 40), 14, Color(0.86, 0.88, 0.82, 1)).text = ContentStrings.get_text("expedition_board_hint")
	_lantern_lbl = _make_label(_panel, "Lantern", Vector2(16, 88), Vector2(468, 48), 14, Color(0.78, 0.86, 0.9, 1))
	_keeper_btn = _party_button("KeeperBtn", Vector2(16, 148), ContentStrings.get_text("char_sheet_title"))
	_elaia_btn = _party_button("ElaiaBtn", Vector2(180, 148), ContentStrings.get_text("echo_elaia_name"))
	_route_btn = Button.new()
	_route_btn.name = "Route"
	_route_btn.position = Vector2(16, 200)
	_route_btn.size = Vector2(468, 36)
	_route_btn.toggle_mode = true
	_route_btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_panel.add_child(_route_btn)
	_route_btn.pressed.connect(_on_route)
	_depart = Button.new()
	_depart.name = "Depart"
	_depart.text = "Depart"
	_depart.position = Vector2(16, 448)
	_depart.size = Vector2(200, 40)
	_depart.disabled = true
	_panel.add_child(_depart)
	_depart.pressed.connect(_on_depart)
	_depth_lbl = _make_label(_panel, "Depth", Vector2(16, 248), Vector2(200, 32), 15, Color(0.9, 0.88, 0.78, 1))
	var depth_down := Button.new()
	depth_down.name = "DepthDown"
	depth_down.text = "-"
	depth_down.position = Vector2(220, 244)
	depth_down.size = Vector2(48, 36)
	_panel.add_child(depth_down)
	depth_down.pressed.connect(_on_depth.bind(-1))
	var depth_up := Button.new()
	depth_up.name = "DepthUp"
	depth_up.text = "+"
	depth_up.position = Vector2(276, 244)
	depth_up.size = Vector2(48, 36)
	_panel.add_child(depth_up)
	depth_up.pressed.connect(_on_depth.bind(1))
	_hours_btn = Button.new()
	_hours_btn.name = "Hours"
	_hours_btn.position = Vector2(340, 244)
	_hours_btn.size = Vector2(180, 36)
	_panel.add_child(_hours_btn)
	_hours_btn.pressed.connect(_on_hours)
	_hold_btn = _party_button("Hold", Vector2(16, 292), "Hold")
	_push_btn = _party_button("Push", Vector2(180, 292), "Push")
	_idle_btn = _party_button("Idle", Vector2(16, 336), "Idle")
	_manual_btn = _party_button("Manual", Vector2(180, 336), "Manual")
	_hold_btn.pressed.connect(_on_pace.bind("hold"))
	_push_btn.pressed.connect(_on_pace.bind("push"))
	_idle_btn.pressed.connect(_on_control.bind("idle"))
	_manual_btn.pressed.connect(_on_control.bind("manual"))
	_odds_lbl = _make_label(_panel, "Odds", Vector2(16, 384), Vector2(500, 56), 15, Color(0.95, 0.9, 0.72, 1))
	_skip_btn = Button.new()
	_skip_btn.name = "SkipRoom"
	_skip_btn.text = "Skip room"
	_skip_btn.position = Vector2(16, 492)
	_skip_btn.size = Vector2(160, 36)
	_panel.add_child(_skip_btn)
	_skip_btn.pressed.connect(_on_skip)
	_rush_btn = Button.new()
	_rush_btn.name = "Rush"
	_rush_btn.text = "Rush"
	_rush_btn.position = Vector2(188, 492)
	_rush_btn.size = Vector2(120, 36)
	_rush_btn.toggle_mode = true
	_panel.add_child(_rush_btn)
	_rush_btn.pressed.connect(_on_rush)
	var back := Button.new()
	back.name = "Back"
	back.text = ContentStrings.get_text("portal_confirm_no")
	back.position = Vector2(340, 448)
	back.size = Vector2(180, 40)
	_panel.add_child(back)
	back.pressed.connect(close_shell)
	_keeper_btn.pressed.connect(_on_keeper)
	_elaia_btn.pressed.connect(_on_elaia)
	_layer.visible = false


func _party_button(node_name: String, pos: Vector2, text: String) -> Button:
	var btn := Button.new()
	btn.name = node_name
	btn.position = pos
	btn.size = Vector2(150, 36)
	btn.toggle_mode = true
	btn.text = text
	_panel.add_child(btn)
	return btn


func _refresh_shell() -> void:
	if _keeper_btn == null:
		return
	_party = ["keeper"]
	_keeper_btn.button_pressed = true
	_keeper_btn.disabled = true
	_elaia_btn.disabled = true
	_elaia_btn.button_pressed = false
	var road_open: bool = GameState.echo_02_resolved
	_route = "north" if road_open else ""
	if road_open:
		_route_btn.text = ContentStrings.get_text("path_east_examine_open")
		_route_btn.disabled = true
		_route_btn.button_pressed = true
	else:
		_route_btn.text = ContentStrings.get_text("path_east_tease")
		_route_btn.disabled = true
		_route_btn.button_pressed = false
	var cap := 1
	if has_node("/root/Reach"):
		cap = Reach.max_start_depth()
	_start_depth = clampi(_start_depth, 1, cap)
	if _depth_lbl:
		_depth_lbl.text = "Depth %d" % _start_depth
	if _hours_btn:
		_hours_btn.text = "%d hour" % _hours if _hours == 1 else "%d hours" % _hours
	if _hold_btn:
		_hold_btn.button_pressed = _pace == "hold"
		_push_btn.button_pressed = _pace == "push"
		_idle_btn.button_pressed = _control == "idle"
		_manual_btn.button_pressed = _control == "manual"
	if _odds_lbl and has_node("/root/Reach"):
		var shown := _start_depth
		if Reach.running:
			shown = Reach.depth
		_odds_lbl.text = "%s\n%s" % [Reach.preview_line(shown), Reach.boss_line()]
	_depart.disabled = depart_disabled()
	_depart.text = "Depart"
	var debug := has_node("/root/Reach") and Reach.debug_tools()
	if _skip_btn:
		_skip_btn.visible = debug
		_rush_btn.visible = debug
		_rush_btn.button_pressed = Reach.rush if debug else false
	_lantern_lbl.text = _lantern_line()


func _on_reach_changed() -> void:
	if shell_open():
		_refresh_shell()
	_apply_lantern()


func _on_keeper() -> void:
	_party = ["keeper"]
	_refresh_shell()


func _on_elaia() -> void:
	_party = ["keeper"]
	_refresh_shell()


func _on_route() -> void:
	_refresh_shell()


func _on_depth(step: int) -> void:
	var cap := 1
	if has_node("/root/Reach"):
		cap = Reach.max_start_depth()
	_start_depth = clampi(_start_depth + step, 1, cap)
	_refresh_shell()


func _on_hours() -> void:
	var steps: Array[int] = [1, 2, 4, 8]
	var idx := steps.find(_hours)
	_hours = steps[(idx + 1) % steps.size()] if idx >= 0 else 1
	_refresh_shell()


func _on_pace(mode: String) -> void:
	if has_node("/root/Reach") and Reach.running:
		Reach.pace = "push" if mode == "push" else "hold"
	_pace = "push" if mode == "push" else "hold"
	_refresh_shell()


func _on_control(mode: String) -> void:
	_control = "manual" if mode == "manual" else "idle"
	if has_node("/root/Reach") and Reach.running:
		Reach.set_control(_control)
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
