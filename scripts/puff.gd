extends Keeper
class_name Puff
## Puff companion — 8-frame walk (Keeper WALK_MS) and 12-frame idle per direction.

const ART: String = "res://assets/art/puff/anim"
const COMPANION_IDLE_MS: float = 160.0

@export var home_area: String = "clearing"


func _ready() -> void:
	super._ready()
	if not GameState.echo_flags_changed.is_connected(_on_join_flags):
		GameState.echo_flags_changed.connect(_on_join_flags)
	_apply_presence()


func _on_join_flags() -> void:
	if is_inside_tree():
		_apply_presence()


func _join_groups() -> void:
	companion_id = "puff"
	add_to_group("companion")
	add_to_group("puff")


func actor_id() -> String:
	return "puff"


func actor_idle_uses_facing() -> bool:
	return true


func actor_selected() -> bool:
	return str(GameState.selected_companion_id) == "puff"


func actor_select() -> void:
	GameState.select_companion("puff")


func actor_label_idle() -> String:
	return ContentStrings.get_text("puff_name")


func actor_label_selected() -> String:
	return ContentStrings.get_text("puff_name")


func _build_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")
	for dir: String in ["south", "north", "east", "west"]:
		_add_idle_dir(frames, dir)
		_add_timed_root(frames, StringName("walk_%s" % dir), "walk/%s" % dir, WALK_MS)
	_add_anim(frames, &"idle_front", _idle_paths("south"), COMPANION_IDLE_MS)
	frames.add_animation(&"walk_front")
	frames.set_animation_loop(&"walk_front", true)
	frames.set_animation_speed(&"walk_front", 1000.0)
	for i: int in range(WALK_MS.size()):
		var path := "%s/walk/south/frame_%04d.png" % [ART, i]
		var tex: Texture2D = load(path) as Texture2D
		if tex:
			frames.add_frame(&"walk_front", tex, WALK_MS[i])
	return frames


func _idle_paths(dir: String) -> Array:
	var paths: Array = []
	for i: int in range(1, IDLE_FRAME_COUNT + 1):  # Keeper.IDLE_FRAME_COUNT
		paths.append("%s/idle/%s/puff_idle_%s_%04d.png" % [ART, dir, dir, i])
	return paths


func _add_idle_dir(frames: SpriteFrames, anim_root: String) -> void:
	_add_anim(frames, StringName("idle_%s" % anim_root), _idle_paths(anim_root), COMPANION_IDLE_MS)


func _add_timed_root(frames: SpriteFrames, anim: StringName, folder: String, durations: Array[float]) -> void:
	frames.add_animation(anim)
	frames.set_animation_loop(anim, true)
	frames.set_animation_speed(anim, 1000.0)
	for i: int in range(durations.size()):
		var path := "%s/%s/frame_%04d.png" % [ART, folder, i]
		var tex: Texture2D = load(path) as Texture2D
		if tex:
			frames.add_frame(anim, tex, durations[i])


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if visible:
		_remember_pose()


func _apply_presence() -> void:
	var here: bool = GameState.puff_in_party_active() and not GameState.member_away("puff")
	if here and not GameState.puff_has_pos:
		_spawn_beside_keeper()
		here = true
	_set_present(here)
	if not here:
		return
	if GameState.puff_has_pos:
		global_position = GameState.puff_pos
		_target = global_position
	_facing = GameState.puff_facing
	if _facing == "":
		_facing = "south"


func _spawn_beside_keeper() -> void:
	var spot := global_position
	var keepers: Array[Node] = get_tree().get_nodes_in_group("keeper") if is_inside_tree() else []
	if not keepers.is_empty() and keepers[0] is Node2D:
		spot = (keepers[0] as Node2D).global_position + Vector2(112, 8)
	GameState.puff_has_pos = true
	GameState.puff_pos = spot
	GameState.puff_facing = "west"
	global_position = spot
	_target = spot
	_facing = "west"


func _set_present(on: bool) -> void:
	visible = on
	set_physics_process(on)
	var body_shape := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if body_shape:
		body_shape.disabled = not on
	if click_area:
		click_area.monitorable = on
		var click_shape := click_area.get_node_or_null("CollisionShape2D") as CollisionShape2D
		if click_shape:
			click_shape.disabled = not on
	if not on:
		_moving = false
		velocity = Vector2.ZERO


func _remember_pose() -> void:
	if not GameState.puff_in_party_active():
		return
	GameState.puff_pos = global_position
	GameState.puff_has_pos = true
	GameState.puff_facing = _facing
