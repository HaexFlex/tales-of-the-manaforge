extends Area2D
class_name ForgeStation
## One Forge station. KeeperStand and WispOrbit are editor markers.
## Idle and busy frames swap while a job is being worked.

@export var station_id: String = ""
@export var idle_texture: Texture2D
@export var busy_texture: Texture2D

@onready var sprite: Sprite2D = get_node_or_null("Sprite") as Sprite2D
@onready var placeholder: Polygon2D = get_node_or_null("Placeholder") as Polygon2D
@onready var keeper_stand: Marker2D = get_node_or_null("KeeperStand") as Marker2D
@onready var wisp_orbit: Marker2D = get_node_or_null("WispOrbit") as Marker2D
@onready var badge: Label = get_node_or_null("Badge") as Label
@onready var title: Label = get_node_or_null("Title") as Label


func _ready() -> void:
	add_to_group("forge_station")
	add_to_group("interactable")
	collision_layer = 4
	collision_mask = 0
	input_pickable = true
	monitoring = false
	monitorable = true
	if title and has_node("/root/ForgeJobs"):
		title.text = ForgeJobs.station_display(station_id)
	_refresh_visual()


func stand_global() -> Vector2:
	if keeper_stand:
		return keeper_stand.global_position
	return global_position + Vector2(0, 48)


func orbit_global() -> Vector2:
	if wisp_orbit:
		return wisp_orbit.global_position
	return global_position + Vector2(28, -36)


func _process(_delta: float) -> void:
	_refresh_visual()


func _refresh_visual() -> void:
	var worked: bool = false
	var line: String = ""
	if has_node("/root/ForgeJobs") and station_id != "":
		worked = ForgeJobs.station_is_busy(station_id)
		line = ForgeJobs.station_badge(station_id)
	if sprite:
		var tex: Texture2D = busy_texture if worked and busy_texture != null else idle_texture
		if tex != null:
			sprite.texture = tex
			sprite.visible = true
			if placeholder:
				placeholder.visible = false
		elif placeholder:
			placeholder.visible = true
	elif placeholder:
		placeholder.visible = true
		if worked:
			placeholder.color = placeholder.color.lightened(0.15)
	if badge:
		badge.text = line


func _input_event(_viewport: Viewport, event: InputEvent, _shape_idx: int) -> void:
	if not (event is InputEventMouseButton):
		return
	var mb: InputEventMouseButton = event
	if not mb.pressed:
		return
	if mb.button_index == MOUSE_BUTTON_LEFT:
		_on_left_click()
		get_viewport().set_input_as_handled()
	elif mb.button_index == MOUSE_BUTTON_RIGHT:
		_on_right_click()
		get_viewport().set_input_as_handled()


func _on_left_click() -> void:
	if has_node("/root/ForgeJobs"):
		GameState.status_message.emit(ForgeJobs.examine_line(station_id))


func _on_right_click() -> void:
	var room: Node = get_tree().get_first_node_in_group("forge_room")
	if GameState.selected_wisp_id >= 0:
		var result: String = GameState.try_assign_wisp(GameState.selected_wisp_id, station_id)
		if result == "full":
			if has_node("/root/ForgeJobs"):
				GameState.status_message.emit(ForgeJobs.copy_text("queue_full"))
			return
		GameState.toast_wisp_assign(result, station_id)
		return
	if GameState.keeper_selected:
		var keeper: Node = get_tree().get_first_node_in_group("keeper")
		if keeper and keeper.has_method("move_to"):
			keeper.call("move_to", stand_global(), null)
		if room and room.has_method("walk_keeper_to_station"):
			room.call("walk_keeper_to_station", station_id)
		return
	GameState.status_message.emit(ContentStrings.get_text("keeper_required"))
