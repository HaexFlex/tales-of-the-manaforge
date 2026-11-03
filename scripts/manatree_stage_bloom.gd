extends Node2D
## Stage-up petal / glint / ground ring (sprint r3). Child of Manatree; listens to GameState.stage_changed.

const PETAL_TEX: String = "res://assets/art/fx/stage_bloom/bloom_petal_strip_5x5x6.png"
const GLINT_TEX: String = "res://assets/art/fx/stage_bloom/bloom_glint_strip_5x5x4.png"
const RING_DIR: String = "res://assets/art/fx/stage_bloom/"

const PETAL_AMOUNT: Dictionary = {
	"sapling": 8,
	"young": 12,
	"mature": 24,
	"elder": 32,
	"ancient": 32,
}
const GLINT_AMOUNT: Dictionary = {
	"sapling": 6,
	"young": 8,
	"mature": 12,
	"elder": 16,
	"ancient": 16,
}

var _tree: Manatree


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	_tree = get_parent() as Manatree
	z_index = -2
	GameState.stage_changed.connect(_on_stage_changed)


func _on_stage_changed(stage_id: StringName) -> void:
	if GameState.applying_save or stage_id == &"sapling":
		return
	_play_bloom(stage_id)


func _stage_canvas_size(stage_id: StringName) -> Vector2:
	var def: Dictionary = GameState.get_stage_def(stage_id)
	var size_v: Variant = def.get("size", [128, 192])
	if typeof(size_v) == TYPE_ARRAY and (size_v as Array).size() >= 2:
		var arr: Array = size_v
		return Vector2(float(arr[0]), float(arr[1]))
	return Vector2(128, 192)


func _ring_stage_key(stage_id: StringName) -> String:
	var s: String = String(stage_id)
	if s == "elder":
		return "ancient"
	return s


func _play_bloom(stage_id: StringName) -> void:
	if _tree == null:
		return
	var stage: String = String(stage_id)
	var canvas: Vector2 = _stage_canvas_size(stage_id)
	var crown_h: float = canvas.y
	var root_w: float = canvas.x
	var door: Vector2 = _tree.door_floor_px(stage_id)
	position = door + Vector2(0, 2)
	_spawn_particles(PETAL_TEX, 6, int(PETAL_AMOUNT.get(stage, 8)), 2.2, 0.85, crown_h, root_w, true)
	_spawn_particles(GLINT_TEX, 4, int(GLINT_AMOUNT.get(stage, 6)), 0.6, 0.6, crown_h, root_w, false)
	_run_ring_flash(_ring_stage_key(stage_id))


func _spawn_particles(
	tex_path: String,
	h_frames: int,
	amount: int,
	lifetime: float,
	explosiveness: float,
	crown_h: float,
	root_w: float,
	petals: bool,
) -> void:
	var tex: Texture2D = load(tex_path) as Texture2D
	if tex == null:
		return
	var motes := CPUParticles2D.new()
	motes.texture = tex
	motes.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	motes.local_coords = false
	motes.one_shot = true
	motes.emitting = true
	motes.amount = amount
	motes.lifetime = lifetime
	motes.explosiveness = explosiveness
	motes.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	var rect_w: float = root_w * 0.5
	var rect_h: float = crown_h * 0.3
	motes.emission_rect_extents = Vector2(rect_w * 0.5, rect_h * 0.5)
	motes.position = Vector2(0, -crown_h * 0.6)
	motes.direction = Vector2(0, -1)
	motes.spread = 70.0
	if petals:
		motes.initial_velocity_min = 30.0
		motes.initial_velocity_max = 60.0
		motes.gravity = Vector2(0, 22)
		motes.damping_min = 8.0
		motes.damping_max = 8.0
		motes.anim_speed_min = 1.5
		motes.anim_speed_max = 2.5
	else:
		motes.initial_velocity_min = 0.0
		motes.initial_velocity_max = 8.0
		motes.gravity = Vector2.ZERO
		motes.anim_speed_min = 1.0
		motes.anim_speed_max = 1.0
	var mat := CanvasItemMaterial.new()
	mat.particles_animation = true
	mat.particles_anim_h_frames = h_frames
	mat.particles_anim_v_frames = 1
	mat.particles_anim_loop = petals
	motes.material = mat
	motes.anim_offset_max = 1.0
	add_child(motes)
	get_tree().create_timer(lifetime + 0.2).timeout.connect(motes.queue_free)


func _run_ring_flash(ring_key: String) -> void:
	var frames: Array[Texture2D] = []
	for i: int in range(3):
		var path: String = "%sbloom_ring_%s_%d.png" % [RING_DIR, ring_key, i]
		var tex: Texture2D = load(path) as Texture2D
		if tex != null:
			frames.append(tex)
	if frames.is_empty():
		return
	var ring := Sprite2D.new()
	ring.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	ring.centered = true
	ring.z_index = -1
	add_child(ring)
	_ring_flash_async(ring, frames)


func _ring_flash_async(ring: Sprite2D, frames: Array[Texture2D]) -> void:
	for tex: Texture2D in frames:
		if not is_instance_valid(ring):
			return
		ring.texture = tex
		await get_tree().create_timer(0.09).timeout
	if is_instance_valid(ring):
		ring.queue_free()
