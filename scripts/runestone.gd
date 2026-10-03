@tool
extends Area2D
class_name Runestone
## One hub stone per combat stat. Keeper selected + right-click walks in range,
## then a Manashard confirm raises that stat by 1.
## Each stat uses a distinct 32×32 cell of runestones_sheet.png (8×8 atlas).

@export var stat_id: StringName = &"might":
	set(value):
		stat_id = value
		if Engine.is_editor_hint() and is_inside_tree():
			_apply_editor_preview()

@onready var stone: Sprite2D = $Stone
@onready var label: Label = $Label

const RUNE_SHEET: String = "res://assets/art/props/runestones/native/runestones_sheet.png"
const RUNE_CELL: int = 64

static var _layer: CanvasLayer
static var _panel: Panel
static var _title: Label
static var _spend: Label
static var _body: Label
static var _hint: Label
static var _bank: Label
static var _yes: Button
static var _no: Button
static var _pending_stat: String = ""
static var _wired: bool = false

var _hovered: bool = false


func _ready() -> void:
	if Engine.is_editor_hint():
		_apply_editor_preview()
		return
	add_to_group("runestone")
	add_to_group("interactable")
	y_sort_enabled = true
	input_pickable = true
	monitoring = false
	monitorable = true
	collision_layer = 4
	collision_mask = 0
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.visible = false
	input_event.connect(_on_input_event)
	mouse_entered.connect(_on_hover.bind(true))
	mouse_exited.connect(_on_hover.bind(false))
	if not KeeperStats.ranks_changed.is_connected(_on_ranks):
		KeeperStats.ranks_changed.connect(_on_ranks)
	if not GameState.resources_changed.is_connected(_on_resources):
		GameState.resources_changed.connect(_on_resources)
	if stone:
		stone.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		stone.centered = false
		stone.hframes = 1
		stone.scale = Vector2(1, 1)
		stone.offset = Vector2(-32, -64)
		_apply_sheet_frame()
	_refresh()


## Column, row on the 8×8 runestone sheet. Chosen from separate silhouette groups.
func _apply_editor_preview() -> void:
	if stone == null:
		stone = get_node_or_null("Stone") as Sprite2D
	if stone:
		stone.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		stone.centered = false
		stone.hframes = 1
		stone.scale = Vector2(1, 1)
		stone.offset = Vector2(-32, -64)
		_apply_sheet_frame()
	if label:
		label.text = String(stat_id).capitalize()
		label.visible = true


func sheet_cell() -> Vector2i:
	match String(stat_id):
		"might":
			return Vector2i(0, 0)
		"arcana":
			return Vector2i(2, 5)
		"resilience":
			return Vector2i(3, 3)
		"ward":
			return Vector2i(1, 3)
		"vitality":
			return Vector2i(3, 5)
		"swiftness":
			return Vector2i(0, 3)
		"fate":
			return Vector2i(2, 3)
		_:
			return Vector2i(0, 0)


func _apply_sheet_frame() -> void:
	var sheet: Texture2D = load(RUNE_SHEET) as Texture2D
	if sheet == null or stone == null:
		return
	var cell: Vector2i = sheet_cell()
	var atlas := AtlasTexture.new()
	atlas.atlas = sheet
	atlas.region = Rect2(cell.x * RUNE_CELL, cell.y * RUNE_CELL, RUNE_CELL, RUNE_CELL)
	stone.texture = atlas


## Glyphs already carry the stat colour. Leave the stone white so that colour reads true.
func glow_modulate(_tint: Color, affordable: bool) -> Color:
	var glow := Color(1, 1, 1, 1)
	if not affordable:
		glow = glow.darkened(0.22)
	return glow


func _on_ranks(_stat_id: StringName) -> void:
	_refresh()


func _on_resources(resource_id: StringName, _amount: int) -> void:
	if resource_id == &"manashards":
		_refresh()


func _refresh() -> void:
	var sid: String = String(stat_id)
	var tint: Color = KeeperStats.stat_color(sid)
	var cost: int = KeeperStats.get_next_cost(sid)
	var affordable: bool = cost < 0 or GameState.manashards >= cost
	if stone:
		stone.modulate = glow_modulate(tint, affordable)
	if label == null:
		return
	var stat_name: String = KeeperStats.stat_display_name(sid)
	if cost < 0:
		label.text = "%s\n%s" % [stat_name, ContentStrings.get_text("runestone_maxed")]
	else:
		label.text = "%s\n%s" % [stat_name, ContentStrings.get_text("runestone_cost", {"cost": cost})]
	var confirming: bool = is_spend_confirm_open() and _pending_stat == sid
	label.visible = _hovered or confirming


func _on_hover(inside: bool) -> void:
	_hovered = inside
	_refresh()


func _world_blocked() -> bool:
	var mains: Array[Node] = get_tree().get_nodes_in_group("main_root")
	if mains.is_empty():
		return GameState.fruit_committed
	var main: Node = mains[0]
	if main.has_method("world_input_blocked"):
		return bool(main.call("world_input_blocked"))
	return false


func is_spend_confirm_open() -> bool:
	return _panel != null and _panel.visible


func begin_spend() -> String:
	if GameState.is_world_frozen():
		GameState.note_frozen_deny()
		return "blocked"
	if _world_blocked():
		return "blocked"
	var sid: String = String(stat_id)
	var result: String = KeeperStats.try_buy_reason(sid)
	var stat_name: String = KeeperStats.stat_display_name(sid)
	if result == "maxed":
		GameAudio.play_tree_deny()
		GameState.status_message.emit(ContentStrings.get_text("runestone_maxed"))
		return result
	if result != "" and result != "cant_afford":
		GameAudio.play_tree_deny()
		return result
	var cost: int = KeeperStats.get_next_cost(sid)
	_open_confirm(sid, stat_name, maxi(cost, 0))
	if result == "cant_afford":
		_yes.disabled = true
		_body.text = "%s\n%s" % [
			ContentStrings.get_text("runestone_cant_afford"),
			ContentStrings.get_text("runestone_confirm", {"cost": maxi(cost, 0), "stat": stat_name}),
		]
		GameAudio.play_tree_deny()
		return result
	_yes.disabled = false
	return "confirm"


func confirm_spend() -> String:
	if _pending_stat == "":
		return "missing"
	var sid: String = _pending_stat
	var stat_name: String = KeeperStats.stat_display_name(sid)
	_close_confirm()
	var result: String = KeeperStats.try_buy(sid)
	match result:
		"ok":
			GameAudio.play_upgrade_buy()
			GameState.status_message.emit(ContentStrings.get_text("runestone_ok", {"stat": stat_name}))
			SaveService.save_game()
		"cant_afford":
			GameAudio.play_tree_deny()
			GameState.status_message.emit(ContentStrings.get_text("runestone_cant_afford"))
		"maxed":
			GameAudio.play_tree_deny()
			GameState.status_message.emit(ContentStrings.get_text("runestone_maxed"))
		_:
			GameAudio.play_tree_deny()
	return result


func cancel_spend() -> void:
	_close_confirm()
	GameAudio.play_ui_cancel()


func work_footprint() -> Rect2:
	if stone:
		return Keeper.sprite_footprint(stone)
	return Rect2(global_position + Vector2(-32, -64), Vector2(64, 64))


func apply_player_command() -> void:
	## RMB: Keeper walks in range, then the spend confirm. Wisps do not assign here.
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
		k.command_work(self, "runestone")


func on_interact(keeper: Node) -> void:
	## Runestones are a stat confirm, not a harvest. The pickaxe loop is only the pose.
	var result: String = begin_spend()
	if result == "confirm" or result == "cant_afford":
		if keeper and keeper.has_method("begin_work_loop"):
			keeper.call("begin_work_loop")
		return
	if keeper and keeper.has_method("end_work_loop"):
		keeper.call("end_work_loop")


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


func _open_confirm(sid: String, stat_name: String, cost: int) -> void:
	_ensure_confirm()
	_pending_stat = sid
	_title.text = ContentStrings.get_text("runestone_title")
	_spend.text = ContentStrings.get_text("runestone_spend", {"stat": stat_name})
	_body.text = ContentStrings.get_text("runestone_confirm", {"cost": cost, "stat": stat_name})
	_hint.text = ContentStrings.get_text("runestone_hint")
	_bank.text = ContentStrings.get_text("runestone_bank_hint")
	_yes.text = ContentStrings.get_text("runestone_confirm_yes")
	_no.text = ContentStrings.get_text("runestone_confirm_no")
	_panel.visible = true
	_layer.visible = true
	GameAudio.play_ui_confirm()
	GameState.status_message.emit(ContentStrings.get_text("runestone_prompt"))


func _close_confirm() -> void:
	_pending_stat = ""
	if _panel:
		_panel.visible = false
	if _layer:
		_layer.visible = false
	if is_inside_tree():
		for node: Node in get_tree().get_nodes_in_group("keeper"):
			if node.has_method("end_work_loop"):
				node.call("end_work_loop")


func _ensure_confirm() -> void:
	if _layer != null and is_instance_valid(_layer):
		return
	_wired = false
	_layer = CanvasLayer.new()
	_layer.name = "RunestoneConfirm"
	_layer.layer = 40
	_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().root.add_child(_layer)
	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.02, 0.03, 0.02, 0.45)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_layer.add_child(dim)
	_panel = Panel.new()
	_panel.name = "Panel"
	_panel.custom_minimum_size = Vector2(520, 280)
	_panel.anchor_left = 0.5
	_panel.anchor_top = 0.5
	_panel.anchor_right = 0.5
	_panel.anchor_bottom = 0.5
	_panel.offset_left = -260.0
	_panel.offset_top = -150.0
	_panel.offset_right = 260.0
	_panel.offset_bottom = 150.0
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.16, 0.11, 0.07, 0.98)
	sb.border_color = Color(0.82, 0.64, 0.28, 1.0)
	sb.set_border_width_all(2)
	_panel.add_theme_stylebox_override("panel", sb)
	_layer.add_child(_panel)
	_title = _make_label(_panel, "Title", Vector2(16, 12), Vector2(488, 24), 18, Color(0.82, 0.64, 0.28, 1.0))
	_spend = _make_label(_panel, "Spend", Vector2(16, 40), Vector2(488, 22), 15, Color(0.92, 0.86, 0.72, 1.0))
	_body = _make_label(_panel, "Body", Vector2(16, 68), Vector2(488, 40), 14, Color(0.92, 0.86, 0.72, 1.0))
	_hint = _make_label(_panel, "Hint", Vector2(16, 112), Vector2(488, 48), 12, Color(0.70, 0.64, 0.52, 1.0))
	_bank = _make_label(_panel, "Bank", Vector2(16, 162), Vector2(488, 40), 12, Color(0.70, 0.64, 0.52, 1.0))
	_yes = Button.new()
	_yes.name = "Yes"
	_yes.position = Vector2(16, 220)
	_yes.size = Vector2(140, 36)
	_panel.add_child(_yes)
	_no = Button.new()
	_no.name = "No"
	_no.position = Vector2(168, 220)
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
	confirm_spend()


func _on_no_pressed() -> void:
	cancel_spend()
