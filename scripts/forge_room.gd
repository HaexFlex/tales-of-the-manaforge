extends Node2D
## Walkable bark chamber. Hub controls: LMB select, RMB move or assign. Jobs stay in GameState.

@onready var keeper: Keeper = $World/Keeper
@onready var camera: Camera2D = $Camera2D
@onready var hud: GameHUD = $HUD
@onready var pause_menu: PauseMenu = $PauseMenu
@onready var world: Node2D = $World

const ROOM_SIZE: Vector2 = Vector2(1680, 1120)
const VIEW_SIZE: Vector2 = Vector2(1280, 720)
const WALL: float = 96.0
const PAN_SPEED: float = 420.0
const BARK_PATH: String = "res://assets/art/forge/forge_bark_chamber_bg.png"
const WISP_SCENE: PackedScene = preload("res://scenes/wisp.tscn")
const INTERACT_PICK_MASK: int = 4

var _wisp_nodes: Dictionary = {}
var _picker: CanvasLayer


func _ready() -> void:
	add_to_group("forge_room")
	process_mode = Node.PROCESS_MODE_PAUSABLE
	get_viewport().physics_object_picking = true
	get_viewport().physics_object_picking_sort = true
	_build_room()
	if keeper:
		keeper.position = Vector2(840, 820)
		keeper.add_to_group("forge_tender")
	_setup_camera()
	if hud and pause_menu:
		hud.bind_pause_menu(pause_menu)
	GameState.wisps_changed.connect(_sync_wisps)
	_sync_wisps()
	GameState.status_message.emit(ContentStrings.get_text("forge_room_examine"))


func _build_room() -> void:
	var bg := Sprite2D.new()
	bg.name = "Bark"
	bg.z_index = -20
	bg.centered = true
	bg.position = ROOM_SIZE * 0.5
	bg.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if ResourceLoader.exists(BARK_PATH):
		var tex: Texture2D = load(BARK_PATH) as Texture2D
		bg.texture = tex
		if tex:
			var sz: Vector2 = tex.get_size()
			if sz.x > 1.0 and sz.y > 1.0:
				bg.scale = Vector2(ROOM_SIZE.x / sz.x, ROOM_SIZE.y / sz.y)
	add_child(bg)
	move_child(bg, 0)
	var blockers := Node2D.new()
	blockers.name = "Walls"
	add_child(blockers)
	_add_wall(blockers, Rect2(0, 0, ROOM_SIZE.x, WALL))
	_add_wall(blockers, Rect2(0, ROOM_SIZE.y - WALL, ROOM_SIZE.x, WALL))
	_add_wall(blockers, Rect2(0, 0, WALL, ROOM_SIZE.y))
	_add_wall(blockers, Rect2(ROOM_SIZE.x - WALL, 0, WALL, ROOM_SIZE.y))
	_add_station(GameState.FORGE_CRUCIBLE, Vector2(420, 560))
	_add_station(GameState.FORGE_MILL, Vector2(840, 500))
	_add_station(GameState.FORGE_ANVIL, Vector2(1260, 560))
	var door := ForgeStation.new()
	door.name = "ExitDoor"
	door.is_exit = true
	door.position = Vector2(840, 960)
	world.add_child(door)


func _add_wall(parent: Node, rect: Rect2) -> void:
	var body := StaticBody2D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = rect.size
	shape.shape = box
	shape.position = rect.position + rect.size * 0.5
	body.add_child(shape)
	parent.add_child(body)


func _add_station(station_id: String, pos: Vector2) -> void:
	var station := ForgeStation.new()
	station.station_id = station_id
	station.name = station_id
	station.position = pos
	world.add_child(station)


func _setup_camera() -> void:
	if camera == null:
		return
	camera.enabled = true
	camera.make_current()
	camera.position_smoothing_enabled = false
	camera.position = _clamped_camera_pos(keeper.global_position if keeper else ROOM_SIZE * 0.5)


func _half_view() -> Vector2:
	var view := VIEW_SIZE
	if is_inside_tree():
		var vp: Vector2 = get_viewport().get_visible_rect().size
		if vp.x >= 64.0 and vp.y >= 64.0:
			view = vp
	return view * 0.5


func camera_min() -> Vector2:
	return _half_view()


func camera_max() -> Vector2:
	return ROOM_SIZE - _half_view()


func _clamped_camera_pos(pos: Vector2) -> Vector2:
	var lo: Vector2 = camera_min()
	var hi: Vector2 = camera_max()
	if hi.x < lo.x:
		hi.x = lo.x
	if hi.y < lo.y:
		hi.y = lo.y
	return Vector2(clampf(pos.x, lo.x, hi.x), clampf(pos.y, lo.y, hi.y))


func get_camera_position_clamped() -> Vector2:
	return _clamped_camera_pos(camera.position if camera else Vector2.ZERO)


func pan_camera(delta: Vector2) -> void:
	if camera == null:
		return
	camera.position = _clamped_camera_pos(camera.position + delta)


func _process(delta: float) -> void:
	if camera == null or world_input_blocked():
		return
	var dir := Vector2.ZERO
	if Input.is_action_pressed("ui_left"):
		dir.x -= 1.0
	if Input.is_action_pressed("ui_right"):
		dir.x += 1.0
	if Input.is_action_pressed("ui_up"):
		dir.y -= 1.0
	if Input.is_action_pressed("ui_down"):
		dir.y += 1.0
	if dir == Vector2.ZERO:
		return
	pan_camera(dir.normalized() * PAN_SPEED * delta)


func world_input_blocked() -> bool:
	if hud == null or pause_menu == null:
		return false
	if hud.care_panel.visible or hud.ascension_panel.visible or hud.welcome_panel.visible:
		return true
	if hud.fruit_confirm_panel.visible:
		return true
	if hud.has_method("is_backpack_open") and bool(hud.call("is_backpack_open")):
		return true
	if hud.has_method("is_character_open") and bool(hud.call("is_character_open")):
		return true
	if hud.has_method("is_forge_popup_open") and bool(hud.call("is_forge_popup_open")):
		return true
	if _picker != null and _picker.visible:
		return true
	return pause_menu.is_open()


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton):
		return
	var mb: InputEventMouseButton = event
	if not mb.pressed or world_input_blocked():
		return
	if _interactable_under_point(get_global_mouse_position()):
		return
	if mb.button_index == MOUSE_BUTTON_LEFT:
		if GameState.clear_selection():
			GameState.status_message.emit(ContentStrings.get_text("keeper_deselect_toast"))
		return
	if mb.button_index == MOUSE_BUTTON_RIGHT:
		_handle_rmb_ground(get_global_mouse_position())


func _handle_rmb_ground(world_pos: Vector2) -> void:
	if GameState.selected_wisp_id >= 0:
		var wid: int = GameState.selected_wisp_id
		if GameState.unassign_wisp(wid):
			GameState.status_message.emit(ContentStrings.get_text("wisp_unassign_ok"))
		return
	var tender_id: String = GameState.selected_tender_id()
	if tender_id == "" or keeper == null:
		GameState.status_message.emit(ContentStrings.get_text("keeper_required"))
		return
	keeper.move_to(world_pos, null)


func _interactable_under_point(world_pos: Vector2) -> bool:
	var space: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
	if space == null:
		return false
	var q := PhysicsPointQueryParameters2D.new()
	q.position = world_pos
	q.collide_with_areas = true
	q.collide_with_bodies = false
	q.collision_mask = INTERACT_PICK_MASK
	var hits: Array[Dictionary] = space.intersect_point(q, 32)
	for hit: Dictionary in hits:
		var collider: Variant = hit.get("collider")
		if collider is Node and (collider as Node).is_in_group("interactable"):
			return true
	return false


func _sync_wisps() -> void:
	var want: int = GameState.wisp_count
	var existing: Array = _wisp_nodes.keys()
	for kid: Variant in existing:
		var id: int = int(kid)
		if id >= want:
			var node: Node = _wisp_nodes[id]
			_wisp_nodes.erase(id)
			if is_instance_valid(node):
				node.queue_free()
	for i: int in range(want):
		if _wisp_nodes.has(i) and is_instance_valid(_wisp_nodes[i]):
			continue
		var orb: Node = WISP_SCENE.instantiate()
		if orb.has_method("setup"):
			orb.call("setup", i)
		world.add_child(orb)
		if orb.has_signal("wisp_clicked"):
			orb.connect("wisp_clicked", _on_wisp_clicked)
		_wisp_nodes[i] = orb


func _on_wisp_clicked(wisp_id: int) -> void:
	GameState.select_wisp(wisp_id)
	if GameState.selected_wisp_id == wisp_id:
		GameState.status_message.emit("%s  ·  %s  ·  %s" % [
			ContentStrings.get_text("wisp_orbit_hint"),
			ContentStrings.get_text("wisp_assign_hint"),
			ContentStrings.get_text("wisp_node_shared_hint"),
		])


func open_anvil_picker() -> void:
	_close_anvil_picker()
	_picker = CanvasLayer.new()
	_picker.name = "AnvilPicker"
	_picker.layer = 22
	add_child(_picker)
	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.05, 0.03, 0.02, 0.45)
	dim.gui_input.connect(_on_picker_dim)
	_picker.add_child(dim)
	var panel := Panel.new()
	panel.position = Vector2(390, 220)
	panel.size = Vector2(500, 280)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.12, 0.08, 0.06, 0.96)
	sb.border_color = Color(0.72, 0.54, 0.28, 1)
	sb.set_border_width_all(2)
	sb.set_content_margin_all(12)
	panel.add_theme_stylebox_override("panel", sb)
	_picker.add_child(panel)
	var title := Label.new()
	title.position = Vector2(16, 12)
	title.size = Vector2(468, 28)
	title.text = ContentStrings.get_text("forge_anvil_name")
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color(0.95, 0.88, 0.72, 1))
	panel.add_child(title)
	var y: float = 52.0
	for entry: Variant in Equipment.recipes_data:
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var rec: Dictionary = entry
		if str(rec.get("station", "")) != "anvil":
			continue
		var recipe_id: String = str(rec.get("id", ""))
		if recipe_id == "":
			continue
		var btn := Button.new()
		btn.position = Vector2(16, y)
		btn.size = Vector2(468, 40)
		var out_id: String = str(rec.get("output_id", recipe_id))
		btn.text = Equipment.item_display_name(out_id)
		btn.tooltip_text = ContentStrings.get_text("%s_craft_cost" % recipe_id)
		btn.pressed.connect(_on_anvil_choice.bind(recipe_id))
		panel.add_child(btn)
		y += 48.0
	var cancel := Button.new()
	cancel.position = Vector2(16, 236)
	cancel.size = Vector2(160, 32)
	cancel.text = ContentStrings.get_text("btn_close")
	cancel.pressed.connect(_close_anvil_picker)
	panel.add_child(cancel)


func _on_picker_dim(event: InputEvent) -> void:
	if event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
		_close_anvil_picker()


func _on_anvil_choice(recipe_id: String) -> void:
	_close_anvil_picker()
	GameState.try_begin_anvil(recipe_id)


func _close_anvil_picker() -> void:
	if _picker != null and is_instance_valid(_picker):
		_picker.queue_free()
	_picker = null
