extends Area2D
class_name ForgeStation
## One Forge station. KeeperStand and WispOrbit are editor markers.
## Idle and busy frames swap while a job is being worked.

@export var station_id: String = ""
@export var idle_texture: Texture2D
@export var busy_texture: Texture2D
## Paused and busy badges. Drawn at BadgeArt, which sits on the marker anchor.
@export var paused_badge: Texture2D
@export var busy_badge: Texture2D

@onready var sprite: Sprite2D = get_node_or_null("Sprite") as Sprite2D
@onready var placeholder: Polygon2D = get_node_or_null("Placeholder") as Polygon2D
@onready var keeper_stand: Marker2D = get_node_or_null("KeeperStand") as Marker2D
@onready var wisp_orbit: Marker2D = get_node_or_null("WispOrbit") as Marker2D
@onready var badge: Label = get_node_or_null("Badge") as Label
@onready var badge_art: Sprite2D = get_node_or_null("BadgeArt") as Sprite2D
@onready var title: Label = get_node_or_null("Title") as Label

var _meter: JobMeter


func _ready() -> void:
	add_to_group("forge_station")
	add_to_group("interactable")
	collision_layer = 4
	collision_mask = 0
	input_pickable = true
	monitoring = false
	monitorable = true
	_meter = JobMeter.new()
	_meter.name = "JobMeter"
	_meter.z_index = 6
	_meter.visible = false
	add_child(_meter)
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
	if title and has_node("/root/ForgeJobs") and station_id != "":
		var named: String = ForgeJobs.station_display(station_id)
		var speed: float = ForgeJobs.station_speed_mult(station_id)
		title.text = named if speed <= 0.0 else "%s  %s" % [named, ForgeJobs.station_speed_text(speed)]
	_apply_badge_art(worked)
	_refresh_meter()


func _refresh_meter() -> void:
	if _meter == null:
		return
	if station_id == "" or not has_node("/root/ForgeJobs"):
		_meter.visible = false
		return
	var state: Dictionary = ForgeJobs.job_state(station_id)
	if state.is_empty():
		_meter.visible = false
		return
	var y: float = -160.0
	if title:
		y = title.offset_top - 12.0
	if sprite:
		var visual_top: float = sprite.position.y + sprite.offset.y * sprite.scale.y
		y = minf(y, visual_top - 12.0)
	_meter.position = Vector2(0, y)
	_meter.fraction = float(state.get("fraction", 0.0))
	_meter.visible = true
	_meter.queue_redraw()


func _apply_badge_art(worked: bool) -> void:
	if badge_art == null:
		return
	var tex: Texture2D = null
	if worked and busy_badge != null:
		tex = busy_badge
	elif not worked and has_node("/root/ForgeJobs") and ForgeJobs.has_job(station_id) and paused_badge != null:
		tex = paused_badge
	badge_art.texture = tex
	badge_art.visible = tex != null


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
	if not GameState.selected_wisp_list().is_empty():
		var result: String = GameState.command_selected_wisps(station_id)
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


class JobMeter extends Node2D:
	var fraction: float = 0.0

	func _draw() -> void:
		var w := 72.0
		var h := 6.0
		var origin := Vector2(-36, 0)
		draw_rect(Rect2(origin, Vector2(w, h)), Color(0.08, 0.06, 0.04, 0.95), true)
		var fill_w: float = floorf(w * clampf(fraction, 0.0, 1.0))
		if fill_w >= 1.0:
			draw_rect(Rect2(origin, Vector2(fill_w, h)), Color(0.55, 0.78, 0.34, 1.0), true)
		draw_rect(Rect2(origin, Vector2(w, h)), Color(0.82, 0.64, 0.28, 1.0), false, 1.0)
