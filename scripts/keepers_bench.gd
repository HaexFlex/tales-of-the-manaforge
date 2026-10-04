extends Area2D
class_name KeepersBench
## Hub handcraft station. The Keeper walks to KeeperStand, then the bench opens.
## Idle and busy frames are the 192px bench art, feet on the node origin.

@export var idle_texture: Texture2D
@export var busy_texture: Texture2D
@export var paused_badge: Texture2D
@export var busy_badge: Texture2D

@onready var sprite: Sprite2D = get_node_or_null("Sprite") as Sprite2D
@onready var placeholder: Polygon2D = get_node_or_null("Placeholder") as Polygon2D
@onready var keeper_stand: Marker2D = get_node_or_null("KeeperStand") as Marker2D
@onready var badge_art: Sprite2D = get_node_or_null("BadgeArt") as Sprite2D

var _awaiting_arrival: bool = false
var _busy: bool = false


func _ready() -> void:
	add_to_group("keepers_bench")
	add_to_group("interactable")
	collision_layer = 4
	collision_mask = 0
	input_pickable = true
	monitoring = false
	monitorable = true
	_apply_frame(false)
	call_deferred("_bind_keeper")


func stand_global() -> Vector2:
	if keeper_stand:
		return keeper_stand.global_position
	return global_position + Vector2(0, 40)


func work_footprint() -> Rect2:
	## Back edge of the tabletop. The stand sits south of this line, waist-deep in the bench.
	var local := Rect2(-88.0, -112.0, 176.0, 104.0)
	return Rect2(global_position + local.position, local.size)


func set_busy(busy: bool) -> void:
	_busy = busy
	_apply_frame(busy)


func _bind_keeper() -> void:
	var keeper: Node = get_tree().get_first_node_in_group("keeper")
	if keeper and keeper.has_signal("arrived") and not keeper.arrived.is_connected(_on_keeper_arrived):
		keeper.arrived.connect(_on_keeper_arrived)


func _apply_frame(busy: bool) -> void:
	var tex: Texture2D = busy_texture if busy and busy_texture != null else idle_texture
	if sprite:
		if tex != null:
			sprite.texture = tex
			sprite.visible = true
			if placeholder:
				placeholder.visible = false
		elif placeholder:
			sprite.visible = false
			placeholder.visible = true
	elif placeholder:
		placeholder.visible = true
	if badge_art:
		var badge: Texture2D = busy_badge if busy else paused_badge
		badge_art.texture = badge if busy else null
		badge_art.visible = badge_art.texture != null


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
		GameState.status_message.emit(ForgeJobs.copy_text("examine_bench"))


func _on_right_click() -> void:
	if not GameState.keeper_selected:
		GameState.status_message.emit(ContentStrings.get_text("keeper_required"))
		return
	var keeper: Node = get_tree().get_first_node_in_group("keeper")
	if keeper == null:
		return
	_awaiting_arrival = true
	if keeper.has_method("command_work"):
		keeper.call("command_work", self, "bench")
		return
	if keeper.has_method("move_to"):
		keeper.call("move_to", stand_global(), null)


func _on_keeper_arrived() -> void:
	if not _awaiting_arrival:
		return
	_awaiting_arrival = false
	try_open()


func keeper_at_stand() -> bool:
	var keeper: Node2D = get_tree().get_first_node_in_group("keeper") as Node2D
	if keeper == null:
		return false
	var radius: float = 56.0
	if has_node("/root/ForgeJobs"):
		radius = ForgeJobs.stand_radius()
	return keeper.global_position.distance_to(stand_global()) <= radius


func try_open() -> bool:
	if not keeper_at_stand():
		return false
	if has_node("/root/ForgeJobs"):
		ForgeJobs.open_bench_hook()
	var hud: Node = get_tree().get_first_node_in_group("game_hud")
	if hud and hud.has_method("open_bench_panel"):
		hud.call("open_bench_panel")
	return true
