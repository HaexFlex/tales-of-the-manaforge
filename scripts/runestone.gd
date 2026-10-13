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
const SHARD_ICON: String = "res://assets_extra/shared/icon_manashards.png"
const PANEL_W: float = 600.0
const PAD: float = 24.0

static var _layer: CanvasLayer
static var _panel: Panel
static var _title: Label
static var _spend: Label
static var _body: Label
static var _hint: Label
static var _bank: Label
static var _yes: Button
static var _rune: TextureRect
static var _stat_box: Label
static var _next: Label
static var _shard: TextureRect
static var _have: Label
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
	_ensure_walk_body()
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


func _ensure_walk_body() -> void:
	if get_node_or_null("WalkBody") != null:
		return
	var body := StaticBody2D.new()
	body.name = "WalkBody"
	body.collision_layer = 1
	body.collision_mask = 0
	body.input_pickable = false
	var shape_node := CollisionShape2D.new()
	body.add_child(shape_node)
	add_child(body)
	FeetBox.apply(shape_node, Vector2(RUNE_CELL, RUNE_CELL), Vector2.ZERO)


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


func _stat_lines(sid: String) -> Dictionary:
	var trained: int = KeeperStats.get_base(sid)
	var total: int = trained
	if has_node("/root/Equipment"):
		total = Equipment.total_for(sid)
	return {"trained": trained, "total": total}


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
	var lines: Dictionary = _stat_lines(sid)
	var stat_line: String = ContentStrings.get_text(
		"runestone_stat_totals",
		{"trained": lines.get("trained", 0), "total": lines.get("total", 0)},
	)
	if cost < 0:
		label.text = "%s\n%s" % [stat_name, stat_line]
	else:
		label.text = "%s\n%s\n%s" % [
			stat_name,
			stat_line,
			ContentStrings.get_text("runestone_cost", {"cost": cost}),
		]
	label.visible = _hovered


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
		_layout_confirm_panel(sid, maxi(cost, 0))
		GameAudio.play_tree_deny()
		return result
	_yes.disabled = false
	return "confirm"


func confirm_spend() -> String:
	if _pending_stat == "":
		return "missing"
	var sid: String = _pending_stat
	var stat_name: String = KeeperStats.stat_display_name(sid)
	var result: String = KeeperStats.try_buy(sid)
	match result:
		"ok":
			GameAudio.play_upgrade_buy()
			GameState.status_message.emit(ContentStrings.get_text("runestone_ok", {"stat": stat_name}))
			SaveService.save_game()
			_refresh_open_confirm(sid)
		"cant_afford":
			GameAudio.play_tree_deny()
			GameState.status_message.emit(ContentStrings.get_text("runestone_cant_afford"))
			_refresh_open_confirm(sid)
		"maxed":
			GameAudio.play_tree_deny()
			GameState.status_message.emit(ContentStrings.get_text("runestone_maxed"))
			_close_confirm()
		_:
			GameAudio.play_tree_deny()
			_close_confirm()
	return result


func _refresh_open_confirm(sid: String) -> void:
	_ensure_confirm()
	var stat_name: String = KeeperStats.stat_display_name(sid)
	var reason: String = KeeperStats.try_buy_reason(sid)
	if reason == "maxed":
		_close_confirm()
		return
	_pending_stat = sid
	var cost: int = KeeperStats.get_next_cost(sid)
	var lines: Dictionary = _stat_lines(sid)
	_title.text = ContentStrings.get_text("runestone_title")
	_spend.text = ContentStrings.get_text("runestone_spend", {"stat": stat_name})
	_hint.text = ContentStrings.get_text(
		"runestone_stat_totals",
		{"trained": lines.get("trained", 0), "total": lines.get("total", 0)},
	)
	if reason == "cant_afford":
		_yes.disabled = true
		_body.text = "%s\n%s" % [
			ContentStrings.get_text("runestone_cant_afford"),
			ContentStrings.get_text("runestone_confirm", {"cost": maxi(cost, 0), "stat": stat_name}),
		]
	else:
		_yes.disabled = false
		_body.text = ContentStrings.get_text("runestone_confirm", {"cost": maxi(cost, 0), "stat": stat_name})
	_bank.text = ContentStrings.get_text("runestone_bank_hint")
	_layout_confirm_panel(sid, maxi(cost, 0))
	_panel.visible = true
	_layer.visible = true


func cancel_spend() -> void:
	_close_confirm()
	GameAudio.play_ui_cancel()


func work_footprint() -> Rect2:
	if stone:
		return Keeper.sprite_footprint(stone)
	return Rect2(global_position + Vector2(-32, -64), Vector2(64, 64))


func apply_player_command() -> void:
	## RMB: the selected hero walks in range, then the spend confirm. Wisps do not assign here.
	if _world_blocked():
		return
	if not GameState.selected_wisp_list().is_empty():
		GameState.status_message.emit(ContentStrings.get_text("wisp_assign_hint"))
		return
	if GameState.selected_hero_id() == "":
		GameState.status_message.emit(ContentStrings.get_text("keeper_required"))
		return
	GameState.command_selected_hero(self, "runestone", "runestone:%s" % String(stat_id))


func on_interact(keeper: Node) -> void:
	## Runestones are a stat confirm, not a harvest. The pickaxe loop is only the pose.
	var result: String = begin_spend()
	if result == "confirm" or result == "cant_afford":
		if keeper and keeper.has_method("begin_reach_pose"):
			keeper.call("begin_reach_pose")
		return
	if keeper and keeper.has_method("cancel_reach_pose"):
		keeper.call("cancel_reach_pose")


func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if not (event is InputEventMouseButton):
		return
	var mb: InputEventMouseButton = event
	if not mb.pressed:
		return
	if mb.button_index == MOUSE_BUTTON_LEFT:
		get_viewport().set_input_as_handled()
		return
	if GameInput.is_command(mb):
		apply_player_command()
		get_viewport().set_input_as_handled()


func _open_confirm(sid: String, stat_name: String, cost: int) -> void:
	_ensure_confirm()
	_pending_stat = sid
	_title.text = ContentStrings.get_text("runestone_title")
	_spend.text = ContentStrings.get_text("runestone_spend", {"stat": stat_name})
	_body.text = ContentStrings.get_text("runestone_confirm", {"cost": cost, "stat": stat_name})
	var lines: Dictionary = _stat_lines(sid)
	_hint.text = ContentStrings.get_text(
		"runestone_stat_totals",
		{"trained": lines.get("trained", 0), "total": lines.get("total", 0)},
	)
	_bank.text = ContentStrings.get_text("runestone_bank_hint")
	_yes.text = ContentStrings.get_text("runestone_confirm_yes")
	_no.text = ContentStrings.get_text("runestone_confirm_no")
	_layout_confirm_panel(sid, cost)
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
		for group_name: String in ["keeper", "elaia"]:
			for node: Node in get_tree().get_nodes_in_group(group_name):
				if node.has_method("finish_reach_pose"):
					node.call("finish_reach_pose")


func _ensure_confirm() -> void:
	if _layer != null and is_instance_valid(_layer):
		return
	_wired = false
	_layer = CanvasLayer.new()
	_layer.name = "RunestoneConfirm"
	_layer.layer = 40
	_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	## Shared by every stone, so it lives beside them (freed with the hub) rather than on root.
	get_parent().add_child(_layer)
	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.02, 0.03, 0.02, 0.45)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_layer.add_child(dim)
	_panel = Panel.new()
	_panel.name = "Panel"
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_layer.add_child(_panel)
	Ui540.apply_kit_panel(_panel, "runestone_confirm")
	_title = _make_label(_panel, "Title", false)
	_rune = TextureRect.new()
	_rune.name = "Rune"
	_rune.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_rune.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_rune.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_panel.add_child(_rune)
	_spend = _make_label(_panel, "Spend", false)
	GameTheme.style_heading_label(_spend)
	_stat_box = _make_label(_panel, "StatBox", false)
	_stat_box.add_theme_stylebox_override("normal", Ui540.kit_stylebox_9s(
		"res://assets/ui/theme/pick_row_9s_current_24x24.png", Vector4i(6, 6, 6, 6), Vector4(8, 0, 8, 0)))
	_stat_box.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_next = _make_label(_panel, "Next", true)
	_next.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_shard = TextureRect.new()
	_shard.name = "Shard"
	_shard.texture = load(SHARD_ICON) as Texture2D
	_shard.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	_panel.add_child(_shard)
	_hint = _make_label(_panel, "Hint", true)
	_body = _make_label(_panel, "Body", false)
	_bank = _make_label(_panel, "Bank", true)
	_have = _make_label(_panel, "Have", false)
	_yes = Button.new()
	_yes.name = "Yes"
	_panel.add_child(_yes)
	_no = Button.new()
	_no.name = "No"
	_panel.add_child(_no)
	if not _wired:
		_yes.pressed.connect(_on_yes_pressed)
		_no.pressed.connect(_on_no_pressed)
		_wired = true
	_layer.visible = false


func _make_label(parent: Control, node_name: String, muted: bool) -> Label:
	var lbl := Label.new()
	lbl.name = node_name
	GameTheme.style_ink_label(lbl, muted)
	parent.add_child(lbl)
	return lbl


## Mockup runestone540_pc_16x9_r3: 600 wide; rune + "Raise Might" + stat box + next cost on
## top, ink body lines below, Raise (wood, left) and Not now (primary, right).
func _layout_confirm_panel(sid: String, cost: int) -> void:
	var w: float = PANEL_W
	var inner: float = w - PAD * 2.0
	var font: Font = GameTheme.body_font()
	var line_h: float = font.get_height(GameTheme.BODY_SIZE)
	var cell: Vector2i = sheet_cell()
	var atlas := AtlasTexture.new()
	atlas.atlas = load(RUNE_SHEET) as Texture2D
	atlas.region = Rect2(cell.x * RUNE_CELL, cell.y * RUNE_CELL, RUNE_CELL, RUNE_CELL)
	_rune.texture = atlas
	Ui540.anchor_rect_safe(_rune, PAD, 36, 64, 64)
	var tx: float = PAD + 80.0
	Ui540.anchor_rect_safe(_spend, tx, 30, w - tx - PAD, 40)
	var lines: Dictionary = _stat_lines(sid)
	_stat_box.text = "%s %d" % [KeeperStats.stat_display_name(sid), int(lines.get("trained", 0))]
	_stat_box.add_theme_color_override("font_color", KeeperStats.stat_color(sid).darkened(0.35))
	var box_w: float = ceilf(font.get_string_size(_stat_box.text, HORIZONTAL_ALIGNMENT_LEFT, -1, GameTheme.BODY_SIZE).x) + 20.0
	Ui540.anchor_rect_safe(_stat_box, tx, 74, box_w, 32)
	_next.text = ContentStrings.get_text("runestone_next_raise")
	var next_w: float = ceilf(font.get_string_size(_next.text, HORIZONTAL_ALIGNMENT_LEFT, -1, GameTheme.BODY_SIZE).x)
	Ui540.anchor_rect_safe(_next, tx + box_w + 16.0, 74, next_w, 32)
	Ui540.anchor_rect_safe(_shard, tx + box_w + 24.0 + next_w, 74, 32, 32)
	_shard.tooltip_text = ContentStrings.get_text("runestone_cost", {"cost": cost})
	var cost_lbl: Label = _panel.get_node_or_null("NextCost") as Label
	if cost_lbl == null:
		cost_lbl = _make_label(_panel, "NextCost", false)
		cost_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	cost_lbl.text = str(cost)
	Ui540.anchor_rect_safe(cost_lbl, tx + box_w + 60.0 + next_w, 74, 80, 32)
	Ui540.anchor_rect_safe(_hint, tx, 108, w - tx - PAD, line_h)
	var y: float = 136.0
	_have.text = ContentStrings.get_text("runestone_have", {"count": GameState.manashards})
	for lbl: Label in [_body, _bank, _have]:
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lbl.update_minimum_size()
		var n: int = Ui540.text_line_count(lbl.text, font, GameTheme.BODY_SIZE, inner)
		Ui540.anchor_rect_safe(lbl, PAD, y, inner, line_h * n)
		y += line_h * n + 8.0
	y += 4.0
	_yes.theme_type_variation = &"BigButton"
	_no.theme_type_variation = &"PrimaryButton"
	Ui540.anchor_rect_safe(_yes, PAD, y, 200, 44)
	Ui540.anchor_rect_safe(_no, w - PAD - 160.0, y, 160, 44)
	Ui540.fit_button_font(_yes, 200)
	Ui540.fit_button_font(_no, 160)
	var h: float = y + 44.0 + 24.0
	_panel.custom_minimum_size = Vector2(w, h)
	_panel.size = Vector2(w, h)
	Ui540.place_title_plank(_title, w)
	Ui540.center_kit_panel(_panel)
	_no.grab_focus.call_deferred()


func _on_yes_pressed() -> void:
	confirm_spend()


func _on_no_pressed() -> void:
	cancel_spend()
