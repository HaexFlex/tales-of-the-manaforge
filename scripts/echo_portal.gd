@tool
extends Area2D
class_name EchoPortal
## Hub portal. Same command as a Runestone: Keeper selected, right-click, walk in range, confirm.
## One arch serves Elaia's Echo (Echo 1), then Bramble's Echo (Echo 2) after the first
## Anvil weapon. EchoChamber.hub_portal_context() decides which, or hides it.

const PORTAL_ART: String = "res://assets/art/props/echo_portal_hub_v2.png"
## Native 160×200, bottom-centre anchor (80, 200). Five empty rows sit above the arch.
const PORTAL_OFFSET: Vector2 = Vector2(-80, -200)
const ENTRY_OFFSET: Vector2 = Vector2(0, 50)

@onready var marker: Sprite2D = $Visual/Marker
@onready var label: Label = $Label

static var _layer: CanvasLayer
static var _panel: Panel
static var _title: Label
static var _body: Label
static var _yes: Button
static var _no: Button
static var _wired: bool = false

var _pulse: float = 0.0
var _hovered: bool = false


func _ready() -> void:
	if Engine.is_editor_hint():
		_fit_marker()
		if label:
			var shown := "Echo"
			var cs: Node = get_tree().root.get_node_or_null("ContentStrings") if get_tree() else null
			if cs != null and cs.has_method("get_text"):
				var labeled: String = str(cs.call("get_text", "portal_label"))
				if labeled != "":
					shown = labeled
			label.text = shown
			label.visible = true
		return
	add_to_group("echo_portal")
	add_to_group("interactable")
	y_sort_enabled = true
	input_pickable = true
	monitoring = false
	monitorable = true
	collision_layer = 4
	collision_mask = 0
	if label:
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.visible = false
	mouse_entered.connect(_on_hover.bind(true))
	mouse_exited.connect(_on_hover.bind(false))
	_fit_marker()
	_ensure_walk_body()
	input_event.connect(_on_input_event)
	if not GameState.echo_flags_changed.is_connected(refresh_visibility):
		GameState.echo_flags_changed.connect(refresh_visibility)
	if not GameState.load_completed.is_connected(refresh_visibility):
		GameState.load_completed.connect(refresh_visibility)
	## Crafting the first Anvil weapon only changes Equipment, not the echo flags.
	if has_node("/root/Equipment") and not Equipment.equipment_changed.is_connected(refresh_visibility):
		Equipment.equipment_changed.connect(refresh_visibility)
	refresh_visibility()


func _fit_marker() -> void:
	if marker == null:
		return
	marker.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	marker.centered = false
	var tex: Texture2D = load(PORTAL_ART) as Texture2D
	marker.texture = tex
	marker.scale = Vector2.ONE
	marker.offset = PORTAL_OFFSET
	if label:
		label.offset_left = -80.0
		label.offset_right = 80.0
		label.offset_top = -228.0
		label.offset_bottom = -204.0
	var pick: CollisionShape2D = get_node_or_null("CollisionShape2D") as CollisionShape2D
	if pick and pick.shape is RectangleShape2D:
		var rect: RectangleShape2D = (pick.shape as RectangleShape2D).duplicate() as RectangleShape2D
		rect.size = Vector2(160, 180)
		pick.shape = rect
		pick.position = Vector2(0, -100)


func _ensure_walk_body() -> void:
	if get_node_or_null("WalkBody") != null:
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
	var shown := Vector2(160, 200)
	if marker != null and marker.texture != null:
		shown = marker.texture.get_size() * Vector2(absf(marker.scale.x), absf(marker.scale.y))
	## Base of the arch only, so the Keeper can walk up into the opening.
	FeetBox.apply(shape_node, shown, Vector2.ZERO)


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if not visible or marker == null:
		return
	_pulse += delta
	var glow: float = 0.88 + 0.12 * sin(_pulse * 1.6)
	marker.modulate = Color(glow, glow, glow, 1.0)


func refresh_visibility() -> void:
	## Sprite, click area, and walk box always move together. A hidden arch must not
	## leave a bare collision box behind, and a shown arch must be clickable.
	var show_it: bool = EchoChamber.hub_portal_open()
	visible = show_it
	input_pickable = show_it
	monitorable = show_it
	_set_walk_enabled(show_it)
	if not show_it:
		_hovered = false
	if label:
		label.text = ContentStrings.get_text("portal_label")
		label.visible = _hovered and show_it


func _set_walk_enabled(on: bool) -> void:
	var shape_node: CollisionShape2D = get_node_or_null("WalkBody/CollisionShape2D") as CollisionShape2D
	if shape_node == null:
		return
	if Engine.is_in_physics_frame():
		shape_node.set_deferred("disabled", not on)
	else:
		shape_node.disabled = not on


func walk_collision_enabled() -> bool:
	var shape_node: CollisionShape2D = get_node_or_null("WalkBody/CollisionShape2D") as CollisionShape2D
	return shape_node != null and not shape_node.disabled


func serves_bramble() -> bool:
	return EchoChamber.hub_portal_context() == "echo2"


func _on_hover(inside: bool) -> void:
	_hovered = inside
	if label:
		label.visible = _hovered and visible


static func is_fee_confirm_open() -> bool:
	return _panel != null and is_instance_valid(_panel) and _panel.visible


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
	var ctx: String = EchoChamber.hub_portal_context()
	if ctx == "":
		return "closed"
	if ctx == "echo2":
		if GameState.echo_02_fee_paid:
			EchoChamber.open_bramble(true)
			return "enter"
	elif GameState.portal_fee_paid:
		EchoChamber.open_battle(true)
		return "enter"
	var fee: int = EchoChamber.BRAMBLE_FEE if ctx == "echo2" else EchoChamber.FEE
	var can_pay: bool = GameState.essence >= fee
	_open_confirm(can_pay)
	if not can_pay:
		GameAudio.play_ui_deny()
		return "reject"
	return "confirm"


func confirm_fee() -> String:
	var bramble: bool = serves_bramble()
	var already: bool = GameState.echo_02_fee_paid if bramble else GameState.portal_fee_paid
	if not already:
		var paid: String = EchoChamber.try_pay_bramble() if bramble else EchoChamber.try_pay_fee()
		if paid != "paid":
			return paid
		SaveService.save_game()
	_close_confirm()
	GameState.status_message.emit(ContentStrings.get_text("portal_enter_ok"))
	if bramble:
		EchoChamber.open_bramble(already)
	else:
		EchoChamber.open_battle(already)
	return "enter"


func cancel_fee() -> void:
	_close_confirm()
	GameAudio.play_ui_cancel()


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


func _open_confirm(can_pay: bool) -> void:
	_ensure_confirm()
	_layout_confirm()
	_rebind_confirm()
	if serves_bramble():
		_fill_bramble_confirm(can_pay)
	else:
		_fill_elaia_confirm(can_pay)
	_yes.text = ContentStrings.get_text("portal_confirm_yes")
	_no.text = ContentStrings.get_text("portal_confirm_no")
	_panel.visible = true
	_layer.visible = true
	if can_pay:
		GameAudio.play_ui_confirm()


func _fill_bramble_confirm(can_pay: bool) -> void:
	## Same copy as the thorn wall's Bramble confirm.
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


func _fill_elaia_confirm(can_pay: bool) -> void:
	_title.text = ContentStrings.get_text("portal_title")
	var cost: int = EchoChamber.FEE
	if can_pay:
		_body.text = "%s\n%s\n%s" % [
			ContentStrings.get_text("portal_prompt"),
			ContentStrings.get_text("portal_confirm", {"cost": cost}),
			ContentStrings.get_text("portal_hint"),
		]
		_yes.disabled = false
	else:
		_body.text = "%s\n%s" % [
			ContentStrings.get_text("portal_cant_afford", {"cost": cost}),
			ContentStrings.get_text("portal_confirm", {"cost": cost}),
		]
		_yes.disabled = true


func _close_confirm() -> void:
	if _panel:
		_panel.visible = false
	if _layer:
		_layer.visible = false


func _ensure_confirm() -> void:
	if _layer != null and is_instance_valid(_layer):
		return
	_wired = false
	_layer = CanvasLayer.new()
	_layer.name = "EchoPortalConfirm"
	_layer.layer = 45
	_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().root.add_child(_layer)
	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.02, 0.05, 0.04, 0.5)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_layer.add_child(dim)
	_panel = Panel.new()
	_panel.name = "Panel"
	_panel.anchor_left = 0.5
	_panel.anchor_top = 0.5
	_panel.anchor_right = 0.5
	_panel.anchor_bottom = 0.5
	_panel.offset_left = -240.0
	_panel.offset_top = -130.0
	_panel.offset_right = 240.0
	_panel.offset_bottom = 130.0
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.14, 0.12, 0.98)
	sb.border_color = Color(0.45, 0.62, 0.52, 1.0)
	sb.set_border_width_all(2)
	_panel.add_theme_stylebox_override("panel", sb)
	_layer.add_child(_panel)
	_title = _make_label(_panel, "Title", Vector2(16, 12), Vector2(448, 28), 18, Color(0.78, 0.9, 0.82, 1))
	_body = _make_label(_panel, "Body", Vector2(16, 48), Vector2(448, 120), 14, Color(0.86, 0.9, 0.84, 1))
	_yes = Button.new()
	_yes.name = "Yes"
	_panel.add_child(_yes)
	_no = Button.new()
	_no.name = "No"
	_panel.add_child(_no)
	_layout_confirm()
	_rebind_confirm()
	_layer.visible = false


func _layout_confirm() -> void:
	if _panel == null or not is_instance_valid(_panel):
		return
	_panel.custom_minimum_size = Vector2(480, 260)
	_panel.offset_left = -240.0
	_panel.offset_top = -130.0
	_panel.offset_right = 240.0
	_panel.offset_bottom = 130.0
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	if _yes:
		_yes.position = Vector2(24, 196)
		_yes.size = Vector2(180, 40)
		_yes.mouse_filter = Control.MOUSE_FILTER_STOP
	if _no:
		_no.position = Vector2(220, 196)
		_no.size = Vector2(180, 40)
		_no.disabled = false
		_no.mouse_filter = Control.MOUSE_FILTER_STOP


func _rebind_confirm() -> void:
	## The confirm layer lives on the root and outlives the portal that built it.
	## Rebind every open so Not now calls this portal, not a freed one.
	_drop_pressed(_yes)
	_drop_pressed(_no)
	if _yes:
		_yes.pressed.connect(_on_yes_pressed)
	if _no:
		_no.pressed.connect(_on_no_pressed)
	_wired = true


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


func _on_yes_pressed() -> void:
	confirm_fee()


func _on_no_pressed() -> void:
	cancel_fee()
