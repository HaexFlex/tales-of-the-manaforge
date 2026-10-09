extends Area2D
## North thorn gate. Closed until Bramble is spared or defeated.
## Feet sit on the node origin at canvas (110, 158). The side hedges always block.
## The centre gap blocks only while the road is shut.

const CLOSED_ART: String = "res://assets/art/props/thorn/thorn_wall_closed.png"
const OPEN_ART: String = "res://assets/art/props/thorn/thorn_wall_open.png"
const RETREAT_FRAMES: PackedStringArray = [
	"res://assets/art/props/thorn/thorn_wall_retreat_0001.png",
	"res://assets/art/props/thorn/thorn_wall_retreat_0002.png",
	"res://assets/art/props/thorn/thorn_wall_retreat_0003.png",
	"res://assets/art/props/thorn/thorn_wall_retreat_0004.png",
	"res://assets/art/props/thorn/thorn_wall_retreat_0005.png",
]
const FEET: Vector2 = Vector2(110, 158)
const FRAME_SEC: float = 0.1
const ENTRY_OFFSET: Vector2 = Vector2(0, 36)

@onready var sprite: Sprite2D = $Visual/Sprite
@onready var label: Label = $Label

var _retreat: Array[Texture2D] = []
var _retreating: bool = false
var _retreat_i: int = 0
var _retreat_t: float = 0.0
var _shown_open: bool = false
var _booted: bool = false
var _hovered: bool = false
var _left: CollisionShape2D
var _right: CollisionShape2D
var _centre: CollisionShape2D

static var _layer: CanvasLayer
static var _panel: Panel
static var _title: Label
static var _body: Label
static var _yes: Button
static var _no: Button


func _ready() -> void:
	add_to_group("thorn_wall")
	add_to_group("interactable")
	y_sort_enabled = true
	input_pickable = true
	monitoring = false
	monitorable = true
	collision_layer = 4
	collision_mask = 0
	if label:
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mouse_entered.connect(_on_hover.bind(true))
	mouse_exited.connect(_on_hover.bind(false))
	_fit_sprite()
	_load_retreat()
	_ensure_walk_body()
	input_event.connect(_on_input_event)
	if not GameState.echo_flags_changed.is_connected(_on_flags):
		GameState.echo_flags_changed.connect(_on_flags)
	if not GameState.load_completed.is_connected(_on_flags):
		GameState.load_completed.connect(_on_flags)
	_on_flags()


func _fit_sprite() -> void:
	if sprite == null:
		return
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.centered = false
	sprite.offset = Vector2(-FEET.x, -FEET.y)
	var pick: CollisionShape2D = get_node_or_null("CollisionShape2D") as CollisionShape2D
	if pick and pick.shape is RectangleShape2D:
		var rect: RectangleShape2D = (pick.shape as RectangleShape2D).duplicate() as RectangleShape2D
		rect.size = Vector2(209, 142)
		pick.shape = rect
		pick.position = Vector2(0.5, -70)


func _load_retreat() -> void:
	_retreat.clear()
	for path: String in RETREAT_FRAMES:
		if ResourceLoader.exists(path):
			var tex: Texture2D = load(path) as Texture2D
			if tex:
				_retreat.append(tex)


func _ensure_walk_body() -> void:
	var body: StaticBody2D = get_node_or_null("WalkBody") as StaticBody2D
	if body == null:
		body = StaticBody2D.new()
		body.name = "WalkBody"
		body.collision_layer = 1
		body.collision_mask = 0
		body.input_pickable = false
		add_child(body)
	_left = _foot_box(body, "Left", 6, 140, 83, 158)
	_right = _foot_box(body, "Right", 146, 140, 214, 158)
	_centre = _foot_box(body, "Centre", 84, 140, 145, 158)


func _foot_box(body: StaticBody2D, node_name: String, x0: int, y0: int, x1: int, y1: int) -> CollisionShape2D:
	var shape_node: CollisionShape2D = body.get_node_or_null(node_name) as CollisionShape2D
	if shape_node == null:
		shape_node = CollisionShape2D.new()
		shape_node.name = node_name
		body.add_child(shape_node)
	var rect := RectangleShape2D.new()
	var w: float = float(x1 - x0 + 1)
	var h: float = float(y1 - y0 + 1)
	rect.size = Vector2(w, h)
	shape_node.shape = rect
	shape_node.position = Vector2(float(x0) + w * 0.5 - FEET.x, float(y0) + h * 0.5 - FEET.y)
	shape_node.disabled = false
	return shape_node


func _process(delta: float) -> void:
	if not _retreating:
		return
	_retreat_t += delta
	if _retreat_t < FRAME_SEC:
		return
	_retreat_t = 0.0
	_retreat_i += 1
	if _retreat_i >= _retreat.size():
		_retreating = false
		_show_still(true)
		return
	if sprite:
		sprite.texture = _retreat[_retreat_i]


func _on_flags() -> void:
	var open: bool = path_is_open()
	_set_walk_blocked(not open)
	if not _booted:
		_booted = true
		_shown_open = open
		_show_still(open)
		_refresh_label()
		return
	if open and not _shown_open:
		_shown_open = true
		if GameState.applying_save:
			_show_still(true)
		else:
			_begin_retreat()
			GameAudio.play(&"sfx_path_open")
	elif not open and _shown_open:
		_shown_open = false
		_retreating = false
		_show_still(false)
	_refresh_label()


func _begin_retreat() -> void:
	if _retreat.size() < 2 or sprite == null:
		_show_still(true)
		return
	_retreating = true
	_retreat_i = 0
	_retreat_t = 0.0
	sprite.texture = _retreat[0]


func _show_still(open: bool) -> void:
	if sprite == null:
		return
	var path: String = OPEN_ART if open else CLOSED_ART
	if ResourceLoader.exists(path):
		sprite.texture = load(path) as Texture2D


func _set_walk_blocked(blocked: bool) -> void:
	## Left and right hedges stay. Only the centre knot drops when the road opens.
	if _centre:
		_centre.disabled = not blocked


func path_is_open() -> bool:
	return GameState.echo_02_resolved


func collider_enabled() -> bool:
	return _centre != null and not _centre.disabled


func sides_blocked() -> bool:
	return _left != null and not _left.disabled and _right != null and not _right.disabled


func walk_box_size() -> Vector2:
	if _centre == null or not (_centre.shape is RectangleShape2D):
		return Vector2.ZERO
	return (_centre.shape as RectangleShape2D).size


func _on_hover(inside: bool) -> void:
	_hovered = inside
	_refresh_label()


func _refresh_label() -> void:
	if label == null:
		return
	label.visible = _hovered
	if path_is_open():
		if GameState.echo_02_outcome == "defeat":
			label.text = ContentStrings.get_text("echo_02_rest")
		else:
			label.text = ContentStrings.get_text("path_east_examine_open")
	else:
		label.text = ContentStrings.get_text("path_east_examine_closed")


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


func _world_blocked() -> bool:
	if EchoChamber.in_battle:
		return true
	var mains: Array[Node] = get_tree().get_nodes_in_group("main_root")
	if mains.is_empty():
		return false
	var main: Node = mains[0]
	if main.has_method("world_input_blocked"):
		return bool(main.call("world_input_blocked"))
	return false


func apply_player_command() -> void:
	if _world_blocked():
		return
	if GameState.selected_wisp_id >= 0:
		GameState.status_message.emit(ContentStrings.get_text("wisp_assign_hint"))
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


func begin_entry() -> String:
	if GameState.is_world_frozen():
		GameState.note_frozen_deny()
		return "blocked"
	if EchoChamber.in_battle:
		return "blocked"
	if path_is_open():
		if GameState.echo_02_outcome == "defeat":
			GameState.status_message.emit(ContentStrings.get_text("echo_02_rest"))
			return "rest"
		GameState.status_message.emit(ContentStrings.get_text("path_east_examine_open"))
		return "examine"
	if not EchoChamber.bramble_gate_open():
		GameState.status_message.emit(ContentStrings.get_text("path_east_tease"))
		return "tease"
	if GameState.echo_02_fee_paid:
		EchoChamber.open_bramble(true)
		return "enter"
	var can_pay: bool = GameState.essence >= EchoChamber.BRAMBLE_FEE
	_open_confirm(can_pay)
	if not can_pay:
		GameAudio.play_ui_deny()
		return "reject"
	return "confirm"


func confirm_fee() -> String:
	var already: bool = GameState.echo_02_fee_paid
	if not already:
		var paid: String = EchoChamber.try_pay_bramble()
		if paid != "paid":
			return paid
		SaveService.save_game()
	_close_confirm()
	GameState.status_message.emit(ContentStrings.get_text("portal_enter_ok"))
	EchoChamber.open_bramble(already)
	return "enter"


func cancel_fee() -> void:
	_close_confirm()
	GameAudio.play_ui_cancel()


func _open_confirm(can_pay: bool) -> void:
	_ensure_confirm()
	var cost: int = EchoChamber.BRAMBLE_FEE
	_title.text = ContentStrings.get_text("bramble_name")
	if can_pay:
		_body.text = "%s\n%s\n%s" % [
			ContentStrings.get_text("echo_bramble_examine"),
			ContentStrings.get_text("portal_confirm", {"cost": cost}),
			ContentStrings.get_text("portal_fee", {"cost": cost}),
		]
		_yes.disabled = false
	else:
		_body.text = "%s\n%s" % [
			ContentStrings.get_text("portal_cant_afford", {"cost": cost}),
			ContentStrings.get_text("echo_bramble_examine"),
		]
		_yes.disabled = true
	_yes.text = ContentStrings.get_text("portal_confirm_yes")
	_no.text = ContentStrings.get_text("portal_confirm_no")
	_panel.visible = true
	_layer.visible = true
	if can_pay:
		GameAudio.play_ui_confirm()


func _close_confirm() -> void:
	if _panel:
		_panel.visible = false
	if _layer:
		_layer.visible = false


func _ensure_confirm() -> void:
	if _layer != null and is_instance_valid(_layer):
		_rebind_confirm()
		return
	_layer = CanvasLayer.new()
	_layer.name = "ThornEchoConfirm"
	_layer.layer = 46
	_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().root.add_child(_layer)
	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.05, 0.03, 0.04, 0.5)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_layer.add_child(dim)
	_panel = Panel.new()
	_panel.name = "Panel"
	_panel.anchor_left = 0.5
	_panel.anchor_top = 0.5
	_panel.anchor_right = 0.5
	_panel.anchor_bottom = 0.5
	_panel.offset_left = -240.0
	_panel.offset_top = -140.0
	_panel.offset_right = 240.0
	_panel.offset_bottom = 140.0
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.10, 0.08, 0.07, 0.98)
	sb.border_color = Color(0.55, 0.34, 0.38, 1.0)
	sb.set_border_width_all(2)
	_panel.add_theme_stylebox_override("panel", sb)
	_layer.add_child(_panel)
	_title = _make_label(_panel, "Title", Vector2(16, 12), Vector2(448, 28), 18, Color(0.95, 0.82, 0.78, 1))
	_body = _make_label(_panel, "Body", Vector2(16, 48), Vector2(448, 140), 14, Color(0.92, 0.88, 0.84, 1))
	_yes = Button.new()
	_yes.name = "Yes"
	_yes.position = Vector2(24, 210)
	_yes.size = Vector2(180, 40)
	_panel.add_child(_yes)
	_no = Button.new()
	_no.name = "No"
	_no.position = Vector2(220, 210)
	_no.size = Vector2(180, 40)
	_panel.add_child(_no)
	_rebind_confirm()
	_layer.visible = false


func _rebind_confirm() -> void:
	_drop_pressed(_yes)
	_drop_pressed(_no)
	if _yes:
		_yes.pressed.connect(confirm_fee)
	if _no:
		_no.pressed.connect(cancel_fee)


func _drop_pressed(btn: Button) -> void:
	if btn == null or not is_instance_valid(btn):
		return
	var conns: Array = btn.pressed.get_connections()
	for conn_v: Variant in conns:
		if typeof(conn_v) != TYPE_DICTIONARY:
			continue
		var cb: Callable = (conn_v as Dictionary).get("callable", Callable())
		if btn.pressed.is_connected(cb):
			btn.pressed.disconnect(cb)


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
