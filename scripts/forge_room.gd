extends Node2D
## Forge v2 room. Walls are a CollisionPolygon2D you can drag in the editor.
## South door and Esc return to the clearing in front of the Manatree.

const HUB_SCENE: String = "res://scenes/main.tscn"
const WISP_SCENE: PackedScene = preload("res://scenes/wisp.tscn")

@onready var camera: Camera2D = get_node_or_null("Camera2D") as Camera2D
@onready var keeper: CharacterBody2D = get_node_or_null("Keeper") as CharacterBody2D
@onready var hud: Node = get_node_or_null("HUD")
@onready var pause_menu: Node = get_node_or_null("PauseMenu")
@onready var exit_area: Area2D = get_node_or_null("ExitDoor") as Area2D
@onready var recipe_panel: Panel = get_node_or_null("UI/RecipePanel") as Panel
@onready var recipe_list: VBoxContainer = get_node_or_null("UI/RecipePanel/List") as VBoxContainer
@onready var recipe_title: Label = get_node_or_null("UI/RecipePanel/Title") as Label
@onready var swirl_overlay: Sprite2D = get_node_or_null("SwirlOverlay") as Sprite2D
## Art slots. The bark plate is the round-room placeholder. Swirl and floor mask stay empty.
@export var swirl_texture: Texture2D
@export var floor_mask: Texture2D

var _wisp_nodes: Dictionary = {}
var _dest_station: String = ""
var _panel_station: String = ""
var _leaving: bool = false


func _ready() -> void:
	add_to_group("forge_room")
	process_mode = Node.PROCESS_MODE_PAUSABLE
	if keeper:
		keeper.add_to_group("keeper")
		if not keeper.arrived.is_connected(_on_keeper_arrived):
			keeper.arrived.connect(_on_keeper_arrived)
	if exit_area and not exit_area.body_entered.is_connected(_on_exit_body):
		exit_area.body_entered.connect(_on_exit_body)
	if pause_menu:
		pause_menu.set("suppress_pause_hotkey", true)
	if hud and hud.has_method("bind_pause_menu") and pause_menu:
		hud.call("bind_pause_menu", pause_menu)
	if has_node("/root/GameAudio") and has_node("/root/ForgeJobs"):
		GameAudio.set_forge_room_mix(true, ForgeJobs.audio_lowpass_hz(), ForgeJobs.audio_reverb_room(), ForgeJobs.audio_music_db())
		GameAudio.play_hub_music()
	if swirl_overlay and swirl_texture != null:
		swirl_overlay.texture = swirl_texture
	_setup_camera()
	_hide_recipes()
	GameState.wisps_changed.connect(_sync_wisps)
	_sync_wisps()
	_show_pending_toast()
	if has_node("/root/ForgeJobs"):
		ForgeJobs.note_entered_forge()


func _exit_tree() -> void:
	if _leaving:
		return
	if has_node("/root/GameAudio"):
		GameAudio.set_forge_room_mix(false)


func _process(delta: float) -> void:
	_pan_camera(delta)
	_clamp_camera()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var key: InputEventKey = event
		if key.keycode == KEY_ESCAPE:
			_on_escape()
			get_viewport().set_input_as_handled()
			return
	if not (event is InputEventMouseButton):
		return
	var mb: InputEventMouseButton = event
	if not mb.pressed:
		return
	if _ui_blocks():
		return
	if _interactable_under_point(get_global_mouse_position()):
		return
	if mb.button_index == MOUSE_BUTTON_LEFT:
		if GameState.clear_selection():
			GameState.status_message.emit(ContentStrings.get_text("keeper_deselect_toast"))
		_hide_recipes()
	elif mb.button_index == MOUSE_BUTTON_RIGHT:
		_on_rmb_ground(get_global_mouse_position())


func _on_escape() -> void:
	if pause_menu and pause_menu.has_method("is_open") and bool(pause_menu.call("is_open")):
		if pause_menu.has_method("resume_game"):
			pause_menu.call("resume_game")
		return
	if hud and hud.has_method("is_character_open") and bool(hud.call("is_character_open")):
		hud.call("close_character_sheet")
		return
	if hud and hud.has_method("is_bench_open") and bool(hud.call("is_bench_open")):
		hud.call("close_bench")
		return
	if hud and hud.has_method("is_backpack_open") and bool(hud.call("is_backpack_open")):
		hud.call("close_backpack")
		return
	if recipe_panel and recipe_panel.visible:
		_hide_recipes()
		return
	_leave()


func walk_keeper_to_station(station_id: String) -> void:
	_dest_station = station_id
	if has_node("/root/ForgeJobs"):
		ForgeJobs.set_keeper_working("", false)
	_open_recipes(station_id)


func _on_keeper_arrived() -> void:
	if _dest_station == "" or not has_node("/root/ForgeJobs"):
		return
	var station: ForgeStation = _find_station(_dest_station)
	if station == null or keeper == null:
		return
	if keeper.global_position.distance_to(station.stand_global()) <= ForgeJobs.stand_radius():
		ForgeJobs.set_keeper_working(_dest_station, true)


func _on_rmb_ground(world_pos: Vector2) -> void:
	_dest_station = ""
	if has_node("/root/ForgeJobs"):
		ForgeJobs.set_keeper_working("", false)
	_hide_recipes()
	if GameState.selected_wisp_id >= 0:
		if GameState.unassign_wisp(GameState.selected_wisp_id):
			GameState.status_message.emit(ContentStrings.get_text("wisp_unassign_ok"))
		return
	if GameState.keeper_selected and keeper and keeper.has_method("move_to"):
		keeper.call("move_to", world_pos, null)
		return
	GameState.status_message.emit(ContentStrings.get_text("keeper_required"))


func _on_exit_body(body: Node2D) -> void:
	if body == keeper:
		_leave()


func _leave() -> void:
	if _leaving:
		return
	_leaving = true
	if has_node("/root/GameAudio"):
		GameAudio.set_forge_room_mix(false)
	if has_node("/root/ForgeJobs"):
		ForgeJobs.exit_forge()
	else:
		get_tree().change_scene_to_file(HUB_SCENE)


func _open_recipes(station_id: String) -> void:
	if recipe_panel == null or recipe_list == null or not has_node("/root/ForgeJobs"):
		return
	_panel_station = station_id
	recipe_panel.visible = true
	if recipe_title:
		recipe_title.text = ForgeJobs.station_display(station_id)
	for child: Node in recipe_list.get_children():
		child.queue_free()
	var ids: PackedStringArray = ForgeJobs.recipe_ids_for(station_id)
	for recipe_id: String in ids:
		var btn := Button.new()
		btn.text = ForgeJobs.recipe_button_text(recipe_id)
		btn.pressed.connect(_on_recipe_pressed.bind(station_id, recipe_id))
		recipe_list.add_child(btn)


func _on_recipe_pressed(station_id: String, recipe_id: String) -> void:
	if not has_node("/root/ForgeJobs"):
		return
	var result: String = ForgeJobs.try_begin_job(station_id, recipe_id)
	if result == "ok":
		GameState.status_message.emit(ForgeJobs.copy_text("job_started"))
	elif result == "cant_afford":
		GameState.status_message.emit(ForgeJobs.copy_text("not_enough_material"))
	elif result == "owned":
		GameState.status_message.emit(ForgeJobs.copy_text("already_owned"))
	elif result == "busy":
		GameState.status_message.emit(ForgeJobs.copy_text("station_busy"))


func _hide_recipes() -> void:
	if recipe_panel:
		recipe_panel.visible = false
	_panel_station = ""


func _show_pending_toast() -> void:
	if not has_node("/root/ForgeJobs"):
		return
	var text: String = ForgeJobs.take_offline_toast()
	if text != "":
		GameState.status_message.emit(text)


func _setup_camera() -> void:
	if camera == null:
		return
	camera.enabled = true
	camera.make_current()
	var room: Vector2 = ForgeJobs.room_size() if has_node("/root/ForgeJobs") else Vector2(1600, 1200)
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = int(room.x)
	camera.limit_bottom = int(room.y)
	camera.position = room * 0.5
	_clamp_camera()


func _half_view() -> Vector2:
	var view := Vector2(1280, 720)
	if is_inside_tree():
		var vp := get_viewport().get_visible_rect().size
		if vp.x >= 64.0 and vp.y >= 64.0:
			view = vp
	return view * 0.5


func _camera_bounds() -> Vector2:
	var room: Vector2 = ForgeJobs.room_size() if has_node("/root/ForgeJobs") else Vector2(1600, 1200)
	if camera:
		room = Vector2(float(camera.limit_right - camera.limit_left), float(camera.limit_bottom - camera.limit_top))
	return room


func _clamped_camera_pos(pos: Vector2) -> Vector2:
	var half: Vector2 = _half_view()
	var room: Vector2 = _camera_bounds()
	var lo := half
	var hi := room - half
	if hi.x < lo.x:
		hi.x = lo.x
	if hi.y < lo.y:
		hi.y = lo.y
	return Vector2(clampf(pos.x, lo.x, hi.x), clampf(pos.y, lo.y, hi.y))


func _clamp_camera() -> void:
	if camera == null:
		return
	camera.position = _clamped_camera_pos(camera.position)


func _pan_camera(delta: float) -> void:
	if camera == null or not has_node("/root/ForgeJobs"):
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
	camera.position += dir.normalized() * ForgeJobs.camera_pan_speed() * delta


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
		add_child(orb)
		_wisp_nodes[i] = orb


func _find_station(station_id: String) -> ForgeStation:
	for node: Node in get_tree().get_nodes_in_group("forge_station"):
		if node is ForgeStation and (node as ForgeStation).station_id == station_id:
			return node as ForgeStation
	return null


func _ui_blocks() -> bool:
	if pause_menu and pause_menu.has_method("is_open") and bool(pause_menu.call("is_open")):
		return true
	if hud and hud.has_method("is_backpack_open") and bool(hud.call("is_backpack_open")):
		return true
	if hud and hud.has_method("is_character_open") and bool(hud.call("is_character_open")):
		return true
	return false


func _interactable_under_point(world_pos: Vector2) -> bool:
	var space: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
	if space == null:
		return false
	var q := PhysicsPointQueryParameters2D.new()
	q.position = world_pos
	q.collide_with_areas = true
	q.collide_with_bodies = false
	q.collision_mask = 4
	var hits: Array[Dictionary] = space.intersect_point(q, 8)
	for hit: Dictionary in hits:
		var collider: Variant = hit.get("collider")
		if collider is Node and (collider as Node).is_in_group("interactable"):
			return true
	return false
