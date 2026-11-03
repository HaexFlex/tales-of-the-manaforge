extends Keeper
class_name MossTortoise
## Moss tortoise companion — walk8 (~0.92 s loop); 9×100 walk folder is not wired.

const ART: String = "res://assets/art/moss_tortoise/anim"
const COMPANION_IDLE_MS: float = 160.0
## Imagine walk period 22 @ 24 fps → 920 ms (Keeper WALK_MS × 0.92); see moss_tortoise CODE_NOTES.
const TORTOISE_WALK8_MS: Array[float] = [
	110.4, 115.0, 119.6, 115.0, 110.4, 115.0, 119.6, 115.0,
]


static func walk_loop_ms() -> float:
	var total: float = 0.0
	for ms: float in TORTOISE_WALK8_MS:
		total += ms
	return total

@export var home_area: String = "clearing"


func _auto(node_name: String) -> Variant:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	return tree.root.get_node_or_null(node_name)


func _gs() -> Variant:
	return _auto("GameState")


func _strings() -> Variant:
	return _auto("ContentStrings")


func _ready() -> void:
	super._ready()
	var gs: Variant = _gs()
	if not gs.is_connected("echo_flags_changed", _on_join_flags):
		gs.connect("echo_flags_changed", _on_join_flags)
	_apply_presence()


func _on_join_flags() -> void:
	if is_inside_tree():
		_apply_presence()


func _join_groups() -> void:
	companion_id = "moss_tortoise"
	add_to_group("companion")
	add_to_group("moss_tortoise")


func actor_id() -> String:
	return "moss_tortoise"


func actor_idle_uses_facing() -> bool:
	return true


func actor_selected() -> bool:
	return str(_gs().get("selected_companion_id")) == "moss_tortoise"


func actor_select() -> void:
	_gs().call("select_companion", "moss_tortoise")


func actor_label_idle() -> String:
	return str(_strings().call("get_text", "moss_tortoise_name"))


func actor_label_selected() -> String:
	return str(_strings().call("get_text", "moss_tortoise_name"))


func _build_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")
	for dir: String in ["south", "north", "east", "west"]:
		_add_idle_dir(frames, dir)
		_add_timed_root(frames, StringName("walk_%s" % dir), "walk8/%s" % dir, TORTOISE_WALK8_MS)
	_add_anim(frames, &"idle_front", _idle_paths("south"), COMPANION_IDLE_MS)
	_add_timed_root(frames, &"walk_front", "walk8/south", TORTOISE_WALK8_MS)
	return frames


func _idle_paths(dir: String) -> Array:
	var paths: Array = []
	for i: int in range(1, IDLE_FRAME_COUNT + 1):  # Keeper.IDLE_FRAME_COUNT
		paths.append("%s/idle/%s/moss_tortoise_idle_%s_%04d.png" % [ART, dir, dir, i])
	return paths


func _add_idle_dir(frames: SpriteFrames, dir: String) -> void:
	_add_anim(frames, StringName("idle_%s" % dir), _idle_paths(dir), COMPANION_IDLE_MS)


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
	var gs: Variant = _gs()
	var here: bool = bool(gs.call("moss_tortoise_joined")) and not bool(gs.call("member_away", "moss_tortoise"))
	if here and not bool(gs.get("moss_tortoise_has_pos")):
		_spawn_beside_keeper()
		here = true
	_set_present(here)
	if not here:
		return
	if bool(gs.get("moss_tortoise_has_pos")):
		global_position = gs.get("moss_tortoise_pos")
		_target = global_position
	_facing = str(gs.get("moss_tortoise_facing"))
	if _facing == "":
		_facing = "south"


func _spawn_beside_keeper() -> void:
	var spot := global_position
	var keepers: Array[Node] = get_tree().get_nodes_in_group("keeper") if is_inside_tree() else []
	if not keepers.is_empty() and keepers[0] is Node2D:
		spot = (keepers[0] as Node2D).global_position + Vector2(-96, 10)
	var gs: Variant = _gs()
	gs.set("moss_tortoise_has_pos", true)
	gs.set("moss_tortoise_pos", spot)
	gs.set("moss_tortoise_facing", "east")
	global_position = spot
	_target = spot
	_facing = "east"


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
	var gs: Variant = _gs()
	if not bool(gs.call("moss_tortoise_joined")):
		return
	gs.set("moss_tortoise_pos", global_position)
	gs.set("moss_tortoise_has_pos", true)
	gs.set("moss_tortoise_facing", _facing)
