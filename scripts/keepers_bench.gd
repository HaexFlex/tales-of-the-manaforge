extends Area2D
class_name KeepersBench
const BatchWorldBars := preload("res://scripts/batch_world_bars.gd")
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
var _awaiting_actor: String = ""
var _busy: bool = false
var _bars: BatchWorldBars


func _ready() -> void:
	add_to_group("keepers_bench")
	add_to_group("interactable")
	collision_layer = 4
	collision_mask = 0
	input_pickable = true
	monitoring = false
	monitorable = true
	_apply_frame(false)
	_bars = BatchWorldBars.new()
	_bars.name = "BatchBars"
	add_child(_bars)
	_bars.bind(self, "workbench")
	var title: Label = get_node_or_null("Title") as Label
	if title:
		title.visible = false
	mouse_entered.connect(_on_title_hover.bind(true))
	mouse_exited.connect(_on_title_hover.bind(false))
	call_deferred("_bind_keeper")
	_apply_walk_box()


func _apply_walk_box() -> void:
	var shape_node: CollisionShape2D = get_node_or_null("WalkBody/CollisionShape2D") as CollisionShape2D
	if shape_node == null or sprite == null or sprite.texture == null:
		return
	var frame := Vector2(float(sprite.texture.get_width()), float(sprite.texture.get_height()))
	var shown := frame * Vector2(absf(sprite.scale.x), absf(sprite.scale.y))
	var box: Vector2 = FeetBox.size_for(shown)
	## A north stand has to stay outside the legs. The south stand already does.
	if keeper_stand != null and keeper_stand.position.y < 0.0:
		var limit: float = maxf(12.0, -keeper_stand.position.y - 6.0)
		if box.y > limit:
			box.y = limit
	FeetBox.apply_size(shape_node, box, Vector2.ZERO)


func _on_title_hover(inside: bool) -> void:
	var title: Label = get_node_or_null("Title") as Label
	if title:
		title.visible = inside


func stand_global() -> Vector2:
	if keeper_stand:
		return keeper_stand.global_position
	return global_position + Vector2(0, 40)


func wisp_orbit_draws_in_front() -> bool:
	return true


func wisp_orbit_center() -> Vector2:
	return _sprite_visual_center()


func wisp_orbit_radius() -> float:
	var shown: Vector2 = _sprite_shown_size()
	return maxf(shown.x, shown.y) * 0.5 + 40.0


func _sprite_shown_size() -> Vector2:
	if sprite == null or sprite.texture == null:
		return Vector2(192, 192)
	var frame := Vector2(float(sprite.texture.get_width()), float(sprite.texture.get_height()))
	return Vector2(frame.x * absf(sprite.scale.x), frame.y * absf(sprite.scale.y))


func _sprite_visual_center() -> Vector2:
	if sprite == null or sprite.texture == null:
		return global_position
	var shown: Vector2 = _sprite_shown_size()
	var top_left: Vector2 = sprite.position
	if sprite.centered:
		top_left -= shown * 0.5
	else:
		top_left += sprite.offset * sprite.scale
	return to_global(top_left + shown * 0.5)


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
	var elaia: Node = get_tree().get_first_node_in_group("elaia")
	if elaia and elaia.has_signal("arrived") and not elaia.arrived.is_connected(_on_elaia_arrived):
		elaia.arrived.connect(_on_elaia_arrived)


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
	_open_panel()


func _on_right_click() -> void:
	if not GameState.selected_wisp_list().is_empty():
		var result: String = GameState.command_selected_wisps("workbench")
		if result == "full":
			return
		GameState.toast_wisp_assign(result, "workbench")
		return
	if GameState.selected_hero_id() == "elaia":
		var elaia: Node = get_tree().get_first_node_in_group("elaia")
		if elaia == null or not elaia.has_method("command_work"):
			return
		_awaiting_arrival = true
		_awaiting_actor = "elaia"
		elaia.call("command_work", self, "bench", "workbench")
		return
	if not GameState.keeper_selected:
		GameState.status_message.emit(ContentStrings.get_text("keeper_required"))
		return
	var keeper: Node = get_tree().get_first_node_in_group("keeper")
	if keeper == null:
		return
	_awaiting_arrival = true
	_awaiting_actor = "keeper"
	if keeper.has_method("command_work"):
		keeper.call("command_work", self, "bench", "workbench")
		return
	if keeper.has_method("move_to"):
		keeper.call("move_to", stand_global(), null)


func _on_keeper_arrived() -> void:
	if not _awaiting_arrival or (_awaiting_actor != "" and _awaiting_actor != "keeper"):
		return
	_awaiting_arrival = false
	_awaiting_actor = ""
	if not keeper_at_stand():
		return
	if has_node("/root/ForgeJobs"):
		ForgeJobs.set_keeper_working("workbench", true)
	try_open()


func _on_elaia_arrived() -> void:
	if not _awaiting_arrival or _awaiting_actor != "elaia":
		return
	_awaiting_arrival = false
	_awaiting_actor = ""
	if not elaia_at_stand():
		return
	if has_node("/root/ForgeJobs"):
		ForgeJobs.set_elaia_working("workbench", true)
	_open_panel()


func keeper_at_stand() -> bool:
	var keeper: Node2D = get_tree().get_first_node_in_group("keeper") as Node2D
	if keeper == null:
		return false
	var radius: float = 56.0
	if has_node("/root/ForgeJobs"):
		radius = ForgeJobs.stand_radius()
	return keeper.global_position.distance_to(stand_global()) <= radius


func elaia_at_stand() -> bool:
	var elaia: Node2D = get_tree().get_first_node_in_group("elaia") as Node2D
	if elaia == null:
		return false
	var radius: float = 56.0
	if has_node("/root/ForgeJobs"):
		radius = ForgeJobs.stand_radius()
	return elaia.global_position.distance_to(stand_global()) <= radius


func try_open() -> bool:
	if not keeper_at_stand():
		return false
	return _open_panel()


func _open_panel() -> bool:
	if has_node("/root/ForgeJobs"):
		ForgeJobs.open_bench_hook()
	var hud: Node = get_tree().get_first_node_in_group("game_hud")
	if hud and hud.has_method("open_bench_panel"):
		hud.call("open_bench_panel")
	return true
