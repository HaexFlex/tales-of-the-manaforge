extends Area2D
class_name ForgeStation
## World station. RMB assigns a Wisp or walks a companion in to tend. Jobs live in GameState.

@export var station_id: String = ""
@export var is_exit: bool = false

var _label: Label
var _sprite: Sprite2D
var _hovered: bool = false
var _shown_busy: bool = false
var _tex_ready: bool = false


func _ready() -> void:
	collision_layer = 4
	collision_mask = 0
	monitoring = false
	monitorable = true
	input_pickable = true
	y_sort_enabled = true
	add_to_group("interactable")
	if is_exit:
		add_to_group("forge_exit")
	else:
		add_to_group("forge_station")
	_build_visual()
	input_event.connect(_on_input_event)
	mouse_entered.connect(_on_hover.bind(true))
	mouse_exited.connect(_on_hover.bind(false))
	if not GameState.forge_changed.is_connected(_refresh):
		GameState.forge_changed.connect(_refresh)
	if not GameState.selection_changed.is_connected(_refresh):
		GameState.selection_changed.connect(_refresh)
	_refresh()


func stand_position() -> Vector2:
	return global_position + Vector2(0, 40)


func _build_visual() -> void:
	if is_exit:
		var door := Polygon2D.new()
		door.color = Color(0.55, 0.32, 0.16, 1)
		door.polygon = PackedVector2Array([
			Vector2(-28, -72), Vector2(28, -72), Vector2(28, 0), Vector2(-28, 0),
		])
		add_child(door)
	_sprite = Sprite2D.new()
	_sprite.name = "Sprite"
	_sprite.centered = true
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_sprite.position = Vector2(0, -48)
	add_child(_sprite)
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(72, 64) if is_exit else Vector2(96, 88)
	shape.shape = rect
	shape.position = Vector2(0, -36)
	add_child(shape)
	_label = Label.new()
	_label.name = "Label"
	_label.position = Vector2(-90, -120)
	_label.size = Vector2(180, 64)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.add_theme_font_size_override("font_size", 13)
	_label.add_theme_color_override("font_color", Color(0.95, 0.9, 0.78, 1))
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_label)
	_apply_texture(false)


func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton:
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
	if is_exit:
		_walk_selected(self)
		return
	if GameState.selected_wisp_id >= 0:
		var result: String = GameState.try_assign_wisp(GameState.selected_wisp_id, station_id)
		GameState.toast_wisp_assign(result, station_id)
		return
	_walk_selected(self)


func _walk_selected(target: Node) -> void:
	var tender_id: String = GameState.selected_tender_id()
	if tender_id == "":
		GameState.status_message.emit(ContentStrings.get_text("keeper_required_harvest"))
		return
	var unit: Node = _find_tender(tender_id)
	if unit == null or not unit.has_method("move_to"):
		GameState.status_message.emit(ContentStrings.get_text("keeper_required_harvest"))
		return
	var dest: Vector2 = stand_position()
	unit.call("move_to", dest, target)


func _find_tender(tender_id: String) -> Node:
	var tenders: Array[Node] = get_tree().get_nodes_in_group("forge_tender")
	for node: Node in tenders:
		if node.has_method("tender_id") and str(node.call("tender_id")) == tender_id:
			return node
	return null


func on_interact(unit: Node) -> void:
	if is_exit:
		GameState.end_forge_visit()
		return
	if station_id == GameState.FORGE_ANVIL and GameState.anvil_recipe == "":
		var room: Node = get_tree().get_first_node_in_group("forge_room")
		if room != null and room.has_method("open_anvil_picker"):
			room.call("open_anvil_picker")
		return
	var tender_id: String = "keeper"
	if unit != null and unit.has_method("tender_id"):
		tender_id = str(unit.call("tender_id"))
	GameState.try_tend_station(station_id, tender_id)
	_refresh()


func _process(_delta: float) -> void:
	if is_exit or _sprite == null:
		return
	var busy: bool = _station_busy()
	if _tex_ready and busy == _shown_busy:
		return
	_shown_busy = busy
	_tex_ready = true
	_apply_texture(busy)
	_refresh()


func _station_busy() -> bool:
	if bool(GameState.forge_running.get(station_id, false)):
		return true
	if bool(GameState.forge_job_paid.get(station_id, false)):
		return true
	if station_id == GameState.FORGE_ANVIL and GameState.anvil_recipe != "":
		return true
	return GameState.count_wisps_on_node(station_id) > 0


func _apply_texture(busy: bool) -> void:
	if _sprite == null:
		return
	if is_exit:
		_sprite.modulate = Color(0.85, 0.62, 0.32, 1)
		return
	var key: String = "crucible"
	if station_id == GameState.FORGE_MILL:
		key = "mill"
	elif station_id == GameState.FORGE_ANVIL:
		key = "anvil"
	var path := "res://assets/art/forge/prop_%s_%s.png" % [key, "busy" if busy else "idle"]
	if not ResourceLoader.exists(path):
		return
	var tex: Texture2D = load(path) as Texture2D
	if tex == null or _sprite.texture == tex:
		return
	_sprite.texture = tex
	var h: float = float(tex.get_height())
	if h > 1.0:
		var s: float = 112.0 / h
		_sprite.scale = Vector2(s, s)


func _on_hover(inside: bool) -> void:
	_hovered = inside
	_refresh()


func _refresh() -> void:
	if _label == null:
		return
	if is_exit:
		_label.text = ContentStrings.get_text("forge_exit")
	elif GameState.selected_wisp_id >= 0:
		_label.text = ContentStrings.get_text("forge_assign_wisp")
	else:
		_label.text = _status_line()
	var working: bool = not is_exit and (_station_busy() or GameState.count_wisps_on_node(station_id) > 0)
	_label.visible = _hovered or working


func _status_line() -> String:
	var name: String = GameState.assignment_target_display(station_id)
	if station_id == GameState.FORGE_ANVIL and GameState.anvil_recipe == "":
		return "%s\n%s" % [name, ContentStrings.get_text("forge_anvil_prompt")]
	if bool(GameState.forge_job_paid.get(station_id, false)) or (station_id == GameState.FORGE_ANVIL and GameState.anvil_recipe != ""):
		var current: int = GameState.anvil_pulses_done if station_id == GameState.FORGE_ANVIL else int(GameState.forge_pulses.get(station_id, 0))
		return ContentStrings.get_text("forge_job_progress", {
			"station": name,
			"current": current,
			"need": GameState.STATION_PULSES_TO_FINISH,
		})
	if station_id == GameState.FORGE_CRUCIBLE:
		return ContentStrings.get_text("sapsteel_process_cost")
	if station_id == GameState.FORGE_MILL:
		return ContentStrings.get_text("heartwood_bits_process_cost")
	return name
