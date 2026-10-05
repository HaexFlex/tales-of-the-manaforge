extends Node2D
## Forge v2 room. Walls are a CollisionPolygon2D you can drag in the editor.
## South door and Esc return to the clearing in front of the Manatree.

const HUB_SCENE: String = "res://scenes/main.tscn"
const WISP_SCENE: PackedScene = preload("res://scenes/wisp.tscn")
const RECIPE_BUTTON: Script = preload("res://scripts/forge_recipe_button.gd")

@onready var camera: Camera2D = get_node_or_null("Camera2D") as Camera2D
@onready var keeper: CharacterBody2D = get_node_or_null("Keeper") as CharacterBody2D
@onready var hud: Node = get_node_or_null("HUD")
@onready var pause_menu: Node = get_node_or_null("PauseMenu")
@onready var exit_area: Area2D = get_node_or_null("ExitDoor") as Area2D
@onready var recipe_panel: Panel = get_node_or_null("UI/RecipePanel") as Panel
@onready var recipe_list: VBoxContainer = get_node_or_null("UI/RecipePanel/List") as VBoxContainer
@onready var recipe_title: Label = get_node_or_null("UI/RecipePanel/Title") as Label
@onready var swirl_overlay: Sprite2D = get_node_or_null("SwirlOverlay") as Sprite2D
## Swirl draws under the stations. The floor mask is the source of the wall polygon.
@export var swirl_texture: Texture2D
@export var floor_mask: Texture2D

const CLICK_SLOP: float = 6.0
var _wisp_nodes: Dictionary = {}
var _dest_station: String = ""
## "keeper" or "elaia". Station arrival must not clear the other hero's job.
var _station_actor: String = ""
var _panel_station: String = ""
var _leaving: bool = false
## body_entered during _ready is the spawn overlap, not a step through the door.
var _exit_primed: bool = false
var _drag_active: bool = false
var _drag_from: Vector2 = Vector2.ZERO
var _marquee: Line2D
var _job_label: Label
var _job_border: ColorRect
var _job_track: ColorRect
var _job_fill: ColorRect


func _ready() -> void:
	add_to_group("forge_room")
	process_mode = Node.PROCESS_MODE_PAUSABLE
	if keeper:
		keeper.add_to_group("keeper")
		if not keeper.arrived.is_connected(_on_keeper_arrived):
			keeper.arrived.connect(_on_keeper_arrived)
	var elaia: Node = get_node_or_null("Elaia")
	if elaia and elaia.has_signal("arrived") and not elaia.arrived.is_connected(_on_elaia_arrived):
		elaia.arrived.connect(_on_elaia_arrived)
	if exit_area and not exit_area.body_entered.is_connected(_on_exit_body):
		exit_area.body_entered.connect(_on_exit_body)
	call_deferred("_prime_exit")
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
	_ensure_station_meter()
	_hide_recipes()
	GameState.wisps_changed.connect(_sync_wisps)
	_sync_wisps()
	_show_pending_toast()
	if has_node("/root/ForgeJobs"):
		ForgeJobs.note_entered_forge()
	if keeper and keeper.has_method("apply_keeper_presence"):
		keeper.apply_keeper_presence()
	var elaia_body: Node = get_node_or_null("Elaia")
	if elaia_body and elaia_body.has_method("_apply_presence"):
		elaia_body.call("_apply_presence")
	_focus_pending_actor()
	if hud and hud.has_method("maybe_show_elaia_footsteps"):
		hud.call("maybe_show_elaia_footsteps")


func _exit_tree() -> void:
	if _leaving:
		return
	if has_node("/root/GameAudio"):
		GameAudio.set_forge_room_mix(false)


func _process(delta: float) -> void:
	_pan_camera(delta)
	_clamp_camera()
	_refresh_station_job()


func _input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton):
		return
	var released: InputEventMouseButton = event
	if released.button_index == MOUSE_BUTTON_LEFT and not released.pressed and _drag_active:
		_finish_marquee(get_global_mouse_position())


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var key: InputEventKey = event
		if key.keycode == KEY_ESCAPE:
			_on_escape()
			get_viewport().set_input_as_handled()
			return
	if event is InputEventMouseMotion and _drag_active:
		_update_marquee(get_global_mouse_position())
		return
	if not (event is InputEventMouseButton):
		return
	var mb: InputEventMouseButton = event
	if mb.button_index == MOUSE_BUTTON_LEFT:
		if mb.pressed:
			if _ui_blocks():
				return
			if _gui_blocks_drag():
				return
			if _interactable_under_point(get_global_mouse_position()):
				return
			_drag_active = true
			_drag_from = get_global_mouse_position()
			_update_marquee(_drag_from)
		elif _drag_active:
			_finish_marquee(get_global_mouse_position())
		return
	if not mb.pressed or _ui_blocks():
		return
	if _interactable_under_point(get_global_mouse_position()):
		return
	if mb.button_index == MOUSE_BUTTON_RIGHT:
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
	_station_actor = "keeper"
	if has_node("/root/ForgeJobs"):
		ForgeJobs.set_keeper_working("", false)
	_open_recipes(station_id)


func present_elaia_at_station(station_id: String) -> void:
	## Opens the same recipe list. Does not clear the Keeper's station job.
	_dest_station = station_id
	_station_actor = "elaia"
	_open_recipes(station_id)


func _on_keeper_arrived() -> void:
	if _station_actor != "keeper" or _dest_station == "" or not has_node("/root/ForgeJobs"):
		return
	var station: ForgeStation = _find_station(_dest_station)
	if station == null or keeper == null:
		return
	var stand: Vector2 = station.stand_global()
	if keeper.has_method("has_station_work_spot") and bool(keeper.call("has_station_work_spot")):
		stand = keeper.call("work_spot_position")
	if keeper.global_position.distance_to(stand) <= ForgeJobs.stand_radius():
		ForgeJobs.set_keeper_working(_dest_station, true)


func _on_elaia_arrived() -> void:
	if _station_actor != "elaia" or _dest_station == "" or not has_node("/root/ForgeJobs"):
		return
	var elaia: Node2D = get_node_or_null("Elaia") as Node2D
	var station: ForgeStation = _find_station(_dest_station)
	if station == null or elaia == null:
		return
	var stand: Vector2 = station.stand_global()
	if elaia.has_method("has_station_work_spot") and bool(elaia.call("has_station_work_spot")):
		stand = elaia.call("work_spot_position")
	if elaia.global_position.distance_to(stand) <= ForgeJobs.stand_radius():
		ForgeJobs.set_elaia_working(_dest_station, true)


func _on_rmb_ground(world_pos: Vector2) -> void:
	_dest_station = ""
	_station_actor = ""
	var elaia_selected: bool = GameState.selected_hero_id() == "elaia"
	if has_node("/root/ForgeJobs") and not elaia_selected:
		ForgeJobs.set_keeper_working("", false)
	_hide_recipes()
	var ids: Array[int] = GameState.selected_wisp_list()
	var unassigned: bool = false
	for wid: int in ids:
		if GameState.unassign_wisp(wid):
			unassigned = true
	if unassigned:
		GameState.status_message.emit(ContentStrings.get_text("wisp_unassign_ok"))
	if elaia_selected:
		var elaia: Node = get_node_or_null("Elaia")
		if elaia and elaia.has_method("command_move"):
			elaia.call("command_move", world_pos)
		return
	if GameState.keeper_selected and keeper and keeper.has_method("move_to"):
		keeper.call("move_to", world_pos, null)
		return
	if ids.is_empty():
		GameState.status_message.emit(ContentStrings.get_text("keeper_required"))


func focus_selection() -> void:
	if camera == null:
		return
	camera.position = _clamped_camera_pos(_selection_focus_point())


func _selection_focus_point() -> Vector2:
	if GameState.keeper_selected and keeper:
		return keeper.global_position
	var ids: Array[int] = GameState.selected_wisp_list()
	if not ids.is_empty():
		for node: Node in get_tree().get_nodes_in_group("wisp"):
			if node is Node2D and int(node.get("wisp_id")) == ids[0]:
				return (node as Node2D).global_position
	if str(GameState.selected_companion_id) != "":
		var companion_id: String = str(GameState.selected_companion_id)
		for node: Node in get_tree().get_nodes_in_group("companion"):
			if node is Node2D and str(node.get("companion_id")) == companion_id:
				return (node as Node2D).global_position
		if camera:
			return camera.position
	return keeper.global_position if keeper else Vector2.ZERO


func _ensure_marquee() -> Line2D:
	if _marquee == null:
		_marquee = Line2D.new()
		_marquee.name = "Marquee"
		_marquee.width = 2.0
		_marquee.default_color = Color(0.85, 0.98, 0.7, 0.9)
		_marquee.z_index = 20
		_marquee.visible = false
		add_child(_marquee)
	return _marquee


func _update_marquee(world_pos: Vector2) -> void:
	var box: Line2D = _ensure_marquee()
	if _drag_from.distance_to(world_pos) < CLICK_SLOP:
		box.visible = false
		return
	var a: Vector2 = _drag_from
	var b: Vector2 = world_pos
	box.visible = true
	box.points = PackedVector2Array([
		a, Vector2(b.x, a.y), b, Vector2(a.x, b.y), a,
	])


func _finish_marquee(world_pos: Vector2) -> void:
	_drag_active = false
	if _marquee:
		_marquee.visible = false
	if _drag_from.distance_to(world_pos) < CLICK_SLOP:
		if GameState.clear_selection():
			GameState.status_message.emit(ContentStrings.get_text("keeper_deselect_toast"))
		_hide_recipes()
		return
	var rect := Rect2(_drag_from, Vector2.ZERO)
	rect = rect.expand(world_pos)
	var picked: Array[int] = []
	for node: Node in get_tree().get_nodes_in_group("wisp"):
		if not (node is Node2D) or not node.visible:
			continue
		var wisp_pos: Vector2 = (node as Node2D).global_position
		if rect.intersects(Rect2(wisp_pos - Vector2(40, 40), Vector2(80, 80))):
			picked.append(int(node.get("wisp_id")))
	## Marquee is Wisps + the Keeper. Elaia stays out of the box; select_group clears her.
	var keeper_in: bool = keeper != null and rect.has_point(keeper.global_position)
	if picked.is_empty() and not keeper_in:
		GameState.clear_selection()
		return
	GameState.select_group(picked, keeper_in)


func _prime_exit() -> void:
	_exit_primed = true


func _on_exit_body(body: Node2D) -> void:
	if not _exit_primed:
		return
	if body == null or not body.has_method("actor_id"):
		return
	var actor: String = str(body.call("actor_id"))
	if actor != "keeper" and actor != "elaia":
		return
	if not (body as CanvasItem).visible:
		return
	if _leaving:
		return
	_leaving = true
	if has_node("/root/ForgeJobs"):
		ForgeJobs.commit_actor_exit(actor)
		if not ForgeJobs.scene_change_pending():
			_leaving = false
		return
	_leave()


func _leave() -> void:
	if _leaving:
		return
	_leaving = true
	if has_node("/root/GameAudio"):
		GameAudio.set_forge_room_mix(false)
	if has_node("/root/ForgeJobs"):
		ForgeJobs.switch_view(false)
	else:
		if has_node("/root/SaveService"):
			SaveService.boot_intent = "forge_return"
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
		var btn: Button = RECIPE_BUTTON.new() as Button
		btn.set("recipe_id", recipe_id)
		btn.text = ForgeJobs.recipe_button_text(recipe_id)
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.icon = ForgeJobs.output_icon(ForgeJobs.recipe_output_id(recipe_id))
		btn.expand_icon = false
		btn.add_theme_constant_override("icon_max_width", 28)
		btn.tooltip_text = recipe_id
		btn.pressed.connect(_on_recipe_pressed.bind(station_id, recipe_id))
		recipe_list.add_child(btn)
	_ensure_repeat_toggle(station_id)
	_refresh_station_job()


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


func _ensure_repeat_toggle(station_id: String) -> void:
	var existing: Button = recipe_panel.get_node_or_null("RepeatToggle") as Button
	var show: bool = ForgeJobs.station_supports_repeat(station_id)
	if not show:
		if existing:
			existing.visible = false
		return
	if existing == null:
		existing = Button.new()
		existing.name = "RepeatToggle"
		existing.position = Vector2(240, 8)
		existing.size = Vector2(120, 28)
		existing.pressed.connect(_on_repeat_toggled)
		recipe_panel.add_child(existing)
	existing.visible = true
	var on: bool = ForgeJobs.station_repeat_enabled(station_id)
	existing.text = ContentStrings.get_text("forge_repeat_on" if on else "forge_repeat_off")
	existing.set_meta("station_id", station_id)


func _on_repeat_toggled() -> void:
	if recipe_panel == null:
		return
	var btn: Button = recipe_panel.get_node_or_null("RepeatToggle") as Button
	if btn == null:
		return
	var station_id: String = str(btn.get_meta("station_id", ""))
	if station_id == "":
		return
	var nxt: bool = not ForgeJobs.station_repeat_enabled(station_id)
	ForgeJobs.set_station_repeat(station_id, nxt)
	btn.text = ContentStrings.get_text("forge_repeat_on" if nxt else "forge_repeat_off")


func focus_actor(actor_id: String) -> void:
	if camera == null:
		return
	var node: Node2D = null
	if actor_id == "elaia":
		node = get_node_or_null("Elaia") as Node2D
	else:
		node = keeper
	if node == null or not node.visible:
		return
	camera.position = node.global_position


func _focus_pending_actor() -> void:
	if not has_node("/root/GameState"):
		return
	var who: String = str(GameState.pending_focus_actor)
	if who == "":
		return
	GameState.pending_focus_actor = ""
	focus_actor(who)


func _gui_blocks_drag() -> bool:
	var hovered: Control = get_viewport().gui_get_hovered_control()
	return hovered != null and hovered.mouse_filter != Control.MOUSE_FILTER_IGNORE


func _hide_recipes() -> void:
	if recipe_panel:
		recipe_panel.visible = false
	_panel_station = ""
	_refresh_station_job()


func _ensure_station_meter() -> void:
	if recipe_panel == null or _job_label != null:
		return
	_job_label = Label.new()
	_job_label.name = "JobProgress"
	_job_label.position = Vector2(12, 36)
	_job_label.size = Vector2(348, 20)
	_job_label.add_theme_font_size_override("font_size", 14)
	_job_label.add_theme_color_override("font_color", Color(0.93, 0.9, 0.78, 1))
	_job_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	recipe_panel.add_child(_job_label)
	_job_border = ColorRect.new()
	_job_border.name = "JobBorder"
	_job_border.position = Vector2(11, 57)
	_job_border.size = Vector2(350, 10)
	_job_border.color = Color(0.82, 0.64, 0.28, 1)
	_job_border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	recipe_panel.add_child(_job_border)
	_job_track = ColorRect.new()
	_job_track.name = "JobTrack"
	_job_track.position = Vector2(12, 58)
	_job_track.size = Vector2(348, 8)
	_job_track.color = Color(0.08, 0.06, 0.04, 1)
	_job_track.mouse_filter = Control.MOUSE_FILTER_IGNORE
	recipe_panel.add_child(_job_track)
	_job_fill = ColorRect.new()
	_job_fill.name = "JobFill"
	_job_fill.position = Vector2(12, 58)
	_job_fill.size = Vector2(0, 8)
	_job_fill.color = Color(0.55, 0.78, 0.34, 1)
	_job_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	recipe_panel.add_child(_job_fill)
	if recipe_list:
		recipe_list.offset_top = 74.0


func _refresh_station_job() -> void:
	if _job_label == null:
		return
	var show: bool = recipe_panel != null and recipe_panel.visible and _panel_station != "" and has_node("/root/ForgeJobs")
	var state: Dictionary = {}
	if show:
		state = ForgeJobs.job_state(_panel_station)
	var live: bool = show and not state.is_empty()
	_job_label.visible = live
	_job_border.visible = live
	_job_track.visible = live
	_job_fill.visible = live
	if not live:
		return
	_job_label.text = ForgeJobs.job_line(_panel_station)
	var width: float = _job_track.size.x * clampf(float(state.get("fraction", 0.0)), 0.0, 1.0)
	_job_fill.size = Vector2(width, _job_track.size.y)


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
	if hud and hud.has_method("is_footsteps_open") and bool(hud.call("is_footsteps_open")):
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
