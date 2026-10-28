extends Area2D
class_name KeepersBench
const BatchWorldBars := preload("res://scripts/batch_world_bars.gd")
## KeeperSeat marks the seat top edge; feet for the idle sit land SEAT_FEET_BELOW_TOP_PX lower.
const SEAT_FEET_BELOW_TOP_PX: float = 23.0
## Hub handcraft station. The Keeper walks to KeeperStand, then the bench opens.
## Idle and busy frames are the 192px bench art, feet on the node origin.

@export var idle_texture: Texture2D
@export var busy_texture: Texture2D
@export var paused_badge: Texture2D
@export var busy_badge: Texture2D

@onready var sprite: Sprite2D = get_node_or_null("Sprite") as Sprite2D
@onready var placeholder: Polygon2D = get_node_or_null("Placeholder") as Polygon2D
@onready var keeper_stand: Marker2D = get_node_or_null("KeeperStand") as Marker2D
@onready var keeper_seat: Marker2D = get_node_or_null("KeeperSeat") as Marker2D
@onready var badge_art: Sprite2D = get_node_or_null("BadgeArt") as Sprite2D

var _awaiting_arrival: bool = false
var _awaiting_actor: String = ""
var _busy: bool = false
var _title_hover: bool = false
var _bars: BatchWorldBars
var _dusk_cup: Sprite2D
var _dusk_steam: AnimatedSprite2D
var _dusk_blanket: Sprite2D


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
	_setup_dusk_props()
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


func world_hover_name() -> String:
	return ContentStrings.get_text("bench_title")


func _on_title_hover(inside: bool) -> void:
	_title_hover = inside
	var title: Label = get_node_or_null("Title") as Label
	if title:
		var covered: bool = false
		if has_node("/root/MinigameHost"):
			covered = bool(MinigameHost.call("is_open")) or str(MinigameHost.call("hero_for", "workbench")) != ""
		title.visible = false
	WorldHover.sync(self, inside, world_hover_name())
	if has_node("/root/MinigameHost"):
		MinigameHost.call("show_prompt", "workbench", global_position + Vector2(0, -56), inside)


func stand_global() -> Vector2:
	if keeper_stand:
		return keeper_stand.global_position
	return global_position + Vector2(0, 40)


func seat_global() -> Vector2:
	if keeper_seat:
		return keeper_seat.global_position + Vector2(0.0, SEAT_FEET_BELOW_TOP_PX)
	return stand_global()


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


func bench_route_footprint() -> Rect2:
	## Tabletop only — used for flank routing so the apron south of the bench still flanks.
	var local := Rect2(-88.0, -112.0, 176.0, 88.0)
	return Rect2(global_position + local.position, local.size)


func set_busy(busy: bool) -> void:
	_busy = busy
	_apply_frame(busy)


func _setup_dusk_props() -> void:
	_dusk_cup = Sprite2D.new()
	_dusk_cup.name = "DuskCup"
	_dusk_cup.position = Vector2(46.0, -100.0)
	_dusk_cup.texture = load("res://assets/art/hub/bench_props/teacup_8x8.png") as Texture2D
	_dusk_cup.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_dusk_cup.scale = Vector2.ONE
	_dusk_cup.visible = false
	add_child(_dusk_cup)
	_dusk_blanket = Sprite2D.new()
	_dusk_blanket.name = "DuskBlanket"
	_dusk_blanket.position = Vector2(-74.0, -96.0)
	_dusk_blanket.texture = load("res://assets/art/hub/bench_props/blanket_draped_30x20.png") as Texture2D
	_dusk_blanket.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_dusk_blanket.scale = Vector2.ONE
	_dusk_blanket.visible = false
	add_child(_dusk_blanket)
	_dusk_steam = AnimatedSprite2D.new()
	_dusk_steam.name = "DuskSteam"
	_dusk_steam.position = Vector2(48.0, -107.0)
	_dusk_steam.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_dusk_steam.scale = Vector2.ONE
	_dusk_steam.visible = false
	var frames := SpriteFrames.new()
	var steam_tex: Texture2D = load("res://assets/art/hub/bench_props/teacup_steam_strip_5x7x4.png") as Texture2D
	if steam_tex != null:
		frames.add_animation(&"steam")
		frames.set_animation_speed(&"steam", 1.0 / 0.15)
		frames.set_animation_loop(&"steam", true)
		for i: int in range(4):
			var atlas := AtlasTexture.new()
			atlas.atlas = steam_tex
			atlas.region = Rect2(float(i * 5), 0.0, 5.0, 7.0)
			frames.add_frame(&"steam", atlas)
		_dusk_steam.sprite_frames = frames
		_dusk_steam.animation = &"steam"
		_dusk_steam.play(&"steam")
	add_child(_dusk_steam)


func _bind_keeper() -> void:
	var keeper: Node = get_tree().get_first_node_in_group("keeper")
	if keeper and keeper.has_signal("keeper_bench_sat") and not keeper.is_connected("keeper_bench_sat", _on_keeper_bench_sat_props):
		keeper.connect("keeper_bench_sat", _on_keeper_bench_sat_props)
	if keeper and keeper.has_signal("keeper_bench_stood") and not keeper.is_connected("keeper_bench_stood", _on_keeper_bench_stood_props):
		keeper.connect("keeper_bench_stood", _on_keeper_bench_stood_props)
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
		if GameInput.yields_touch_double_tap(mb):
			return
		if GameInput.touch_mode() and GameInput.is_touch_pointer(mb):
			GameInput.defer_touch_tap(_on_left_click)
		else:
			_on_left_click()
		get_viewport().set_input_as_handled()
	elif GameInput.is_command(mb):
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
	var hero_id: String = GameState.selected_hero_id()
	if hero_id != "" and hero_id != "keeper":
		var hero: Node = GameState.find_selected_hero()
		if hero == null or not hero.has_method("command_work"):
			return
		_awaiting_arrival = true
		_awaiting_actor = hero_id
		if hero.has_signal("arrived") and not hero.arrived.is_connected(_on_companion_arrived):
			hero.arrived.connect(_on_companion_arrived)
		hero.call("command_work", self, "bench", "workbench")
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
	_on_companion_arrived()


func _on_companion_arrived() -> void:
	if not _awaiting_arrival or _awaiting_actor == "" or _awaiting_actor == "keeper":
		return
	var actor_id: String = _awaiting_actor
	_awaiting_arrival = false
	_awaiting_actor = ""
	if not _companion_at_stand(actor_id):
		return
	if has_node("/root/ForgeJobs"):
		ForgeJobs.set_actor_working(actor_id, "workbench", true)
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
	return _companion_at_stand("elaia")


func _companion_at_stand(actor_id: String) -> bool:
	var body: Node2D = GameState.find_companion_body(actor_id) as Node2D
	if body == null:
		return false
	var radius: float = 56.0
	if has_node("/root/ForgeJobs"):
		radius = ForgeJobs.stand_radius()
	return body.global_position.distance_to(stand_global()) <= radius


func try_open() -> bool:
	if not keeper_at_stand():
		return false
	return _open_panel()


func _on_keeper_bench_sat_props() -> void:
	if not HubTimePhase.is_dusk_or_night():
		return
	_set_dusk_props_visible(true)


func _on_keeper_bench_stood_props() -> void:
	_set_dusk_props_visible(false)


func _set_dusk_props_visible(show_props: bool) -> void:
	if _dusk_cup:
		_dusk_cup.visible = show_props
	if _dusk_blanket:
		_dusk_blanket.visible = show_props
	if _dusk_steam:
		_dusk_steam.visible = show_props
		if show_props:
			_dusk_steam.play(&"steam")
		else:
			_dusk_steam.stop()


func _open_panel() -> bool:
	if has_node("/root/ForgeJobs"):
		ForgeJobs.open_bench_hook()
	var hud: Node = get_tree().get_first_node_in_group("game_hud")
	if hud and hud.has_method("open_bench_panel"):
		hud.call("open_bench_panel")
	return true
