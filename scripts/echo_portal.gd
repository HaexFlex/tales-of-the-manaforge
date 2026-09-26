extends Area2D
class_name EchoPortal
## Hub portal. Same command as a Runestone: Keeper selected, right-click, walk in range, confirm.

const PORTAL_ART: String = "res://assets/art/props/echo_portal_hub.png"
const PORTAL_BOX: float = 96.0

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
	input_event.connect(_on_input_event)
	if not GameState.echo_flags_changed.is_connected(refresh_visibility):
		GameState.echo_flags_changed.connect(refresh_visibility)
	if not GameState.load_completed.is_connected(refresh_visibility):
		GameState.load_completed.connect(refresh_visibility)
	refresh_visibility()


func _fit_marker() -> void:
	if marker == null:
		return
	marker.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	marker.centered = false
	var tex: Texture2D = load(PORTAL_ART) as Texture2D
	marker.texture = tex
	var tw: float = PORTAL_BOX
	var th: float = PORTAL_BOX
	if tex != null:
		tw = float(tex.get_width())
		th = float(tex.get_height())
	var fit: float = 1.0
	if tw > 0.0 and th > 0.0:
		fit = minf(PORTAL_BOX / tw, PORTAL_BOX / th)
	marker.scale = Vector2(fit, fit)
	marker.offset = Vector2(-tw * 0.5, -th)


func _process(delta: float) -> void:
	if not visible or marker == null:
		return
	_pulse += delta
	var glow: float = 0.88 + 0.12 * sin(_pulse * 1.6)
	marker.modulate = Color(glow, glow, glow, 1.0)


func refresh_visibility() -> void:
	var show_it: bool = EchoChamber.portal_visible()
	visible = show_it
	input_pickable = show_it
	monitorable = show_it
	if label:
		label.text = ContentStrings.get_text("portal_label")
		label.visible = _hovered


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
		k.move_to(global_position, self)


func on_interact(_keeper: Node) -> void:
	begin_entry()


func begin_entry() -> String:
	if EchoChamber.in_battle:
		return "blocked"
	if not EchoChamber.portal_visible():
		return "closed"
	if GameState.portal_fee_paid:
		EchoChamber.open_battle(true)
		return "enter"
	var can_pay: bool = GameState.essence >= EchoChamber.FEE
	_open_confirm(can_pay)
	if not can_pay:
		GameAudio.play_ui_deny()
		return "reject"
	return "confirm"


func confirm_fee() -> String:
	var already: bool = GameState.portal_fee_paid
	if not already:
		var paid: String = EchoChamber.try_pay_fee()
		if paid != "paid":
			return paid
		SaveService.save_game()
	_close_confirm()
	GameState.status_message.emit(ContentStrings.get_text("portal_enter_ok"))
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
	_panel.offset_top = -90.0
	_panel.offset_right = 240.0
	_panel.offset_bottom = 90.0
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.14, 0.12, 0.98)
	sb.border_color = Color(0.45, 0.62, 0.52, 1.0)
	sb.set_border_width_all(2)
	_panel.add_theme_stylebox_override("panel", sb)
	_layer.add_child(_panel)
	_title = _make_label(_panel, "Title", Vector2(16, 12), Vector2(448, 28), 18, Color(0.78, 0.9, 0.82, 1))
	_body = _make_label(_panel, "Body", Vector2(16, 48), Vector2(448, 56), 14, Color(0.86, 0.9, 0.84, 1))
	_yes = Button.new()
	_yes.name = "Yes"
	_yes.position = Vector2(16, 120)
	_yes.size = Vector2(140, 36)
	_panel.add_child(_yes)
	_no = Button.new()
	_no.name = "No"
	_no.position = Vector2(168, 120)
	_no.size = Vector2(140, 36)
	_panel.add_child(_no)
	if not _wired:
		_yes.pressed.connect(_on_yes_pressed)
		_no.pressed.connect(_on_no_pressed)
		_wired = true
	_layer.visible = false


func _make_label(parent: Control, node_name: String, pos: Vector2, sz: Vector2, font_size: int, color: Color) -> Label:
	var lbl := Label.new()
	lbl.name = node_name
	lbl.position = pos
	lbl.size = sz
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.add_theme_font_size_override("font_size", font_size)
	lbl.add_theme_color_override("font_color", color)
	parent.add_child(lbl)
	return lbl


func _on_yes_pressed() -> void:
	confirm_fee()


func _on_no_pressed() -> void:
	cancel_fee()
