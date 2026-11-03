extends Node
## Lucky-harvest burst + gold sparks + mana chime (SPRINT lucky-spark).

const SPARK_TEX_PATH: String = "res://assets/art/fx/lucky_spark/lucky_spark_3x3.png"
const LuckySparkBurstScript: GDScript = preload("res://scripts/fx/lucky_spark_burst.gd")
const CHIME_COOLDOWN_MSEC: int = 1500
const CHIME_RELATIVE_DB: float = -6.0

static var _last_chime_msec: int = -100000000
static var _burst_spawn_count: int = 0
static var _spark_emit_count: int = 0

var _connected: bool = false


func _ready() -> void:
	call_deferred("_connect_lucky_harvest")


func _connect_lucky_harvest() -> void:
	var game_state: Node = get_node_or_null("/root/GameState")
	if _connected or game_state == null:
		return
	if not game_state.lucky_harvest.is_connected(_on_lucky_harvest):
		game_state.lucky_harvest.connect(_on_lucky_harvest)
	_connected = true


static func reset_test_state() -> void:
	_last_chime_msec = -100000000
	_burst_spawn_count = 0
	_spark_emit_count = 0


static func burst_spawn_count() -> int:
	return _burst_spawn_count


static func spark_emit_count() -> int:
	return _spark_emit_count


static func chime_cooldown_msec() -> int:
	return CHIME_COOLDOWN_MSEC


static func chime_cue_for_stage(stage_index: int) -> StringName:
	match stage_index + 1:
		1:
			return &"sfx_mana_chime_1"
		2:
			return &"sfx_mana_chime_2"
		3:
			return &"sfx_mana_chime_3"
		_:
			return &"sfx_mana_chime_4"


static func _game_state() -> Node:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null:
		return null
	return tree.root.get_node_or_null("GameState")


static func _game_audio() -> Node:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null:
		return null
	return tree.root.get_node_or_null("GameAudio")


static func chime_volume_offset_db() -> float:
	var audio: Node = _game_audio()
	if audio == null:
		return -18.0
	return float(audio.call("gather_offset_db")) + CHIME_RELATIVE_DB


## Returns the cue id when a chime plays; empty when throttled.
static func try_play_chime(now_msec: int = Time.get_ticks_msec()) -> StringName:
	if now_msec - _last_chime_msec < CHIME_COOLDOWN_MSEC:
		return &""
	_last_chime_msec = now_msec
	var stage_idx: int = 0
	var game_state: Node = _game_state()
	if game_state != null:
		stage_idx = int(game_state.call("get_stage_index"))
	var cue: StringName = chime_cue_for_stage(stage_idx)
	var audio: Node = _game_audio()
	if audio != null:
		audio.call("play", cue, chime_volume_offset_db(), 1.0)
	return cue


static func spawn_over_gatherable(gatherable: Node2D) -> void:
	if gatherable == null or not is_instance_valid(gatherable):
		return
	if not gatherable.has_method("lucky_spark_local_pos"):
		return
	var parent: Node = gatherable.get_parent()
	if parent == null:
		return
	var local_pos: Vector2 = gatherable.call("lucky_spark_local_pos") as Vector2
	spawn_at_parent(parent, gatherable.to_global(local_pos))


static func spawn_at_parent(parent: Node, global_pos: Vector2) -> void:
	if parent == null:
		return
	var burst: Node2D = LuckySparkBurstScript.new() as Node2D
	burst.global_position = global_pos
	burst.z_index = 12
	parent.add_child(burst)
	_burst_spawn_count += 1
	_spawn_sparks(parent, global_pos)


static func _spawn_sparks(parent: Node, global_pos: Vector2) -> void:
	var motes := CPUParticles2D.new()
	motes.name = "LuckySparkMotes"
	motes.texture = load(SPARK_TEX_PATH) as Texture2D
	motes.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	motes.one_shot = true
	motes.explosiveness = 1.0
	motes.amount = 5
	motes.lifetime = 0.3
	motes.initial_velocity_min = 20.0
	motes.initial_velocity_max = 40.0
	motes.spread = 180.0
	motes.gravity = Vector2(0.0, -10.0)
	motes.scale_amount_min = 1.0
	motes.scale_amount_max = 1.0
	motes.local_coords = false
	motes.z_index = 11
	motes.global_position = global_pos
	parent.add_child(motes)
	motes.emitting = true
	_spark_emit_count += 1


func _on_lucky_harvest(resource_id: StringName, _bonus: int) -> void:
	var gatherable: Node2D = _resolve_gatherable(resource_id)
	if gatherable != null:
		spawn_over_gatherable(gatherable)
	try_play_chime()


static func _resolve_gatherable(resource_id: StringName) -> Node2D:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null:
		return null
	var keeper: Node = tree.get_first_node_in_group("keeper")
	if keeper != null and keeper.has_method("get_channel_target"):
		var target: Node = keeper.call("get_channel_target") as Node
		if target is Node2D and target.is_in_group("harvest_node"):
			var rid: Variant = target.get("resource_id")
			if rid == resource_id:
				return target as Node2D
	for node: Node in tree.get_nodes_in_group("harvest_node"):
		if node is Node2D:
			var g: Node2D = node as Node2D
			if g.get("resource_id") == resource_id:
				return g
	return null
