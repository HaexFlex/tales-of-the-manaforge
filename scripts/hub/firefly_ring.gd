extends Node2D
## Catchable fireflies at dusk/night on the forest edge. Jar count on KeepersBench.

const WARM_STRIP: String = "res://assets/art/fx/fireflies/firefly_warm_strip_8x8x4.png"
const GLADE_RECT: Rect2 = Rect2(760, 820, 1680, 1360)
const CATCH_THROTTLE_MSEC: int = 500

var _spawn_accum: float = 0.0
var _active: Array[Area2D] = []
static var _last_catch_msec: int = -1000000


func _ready() -> void:
	add_to_group("firefly_ring")
	set_process(true)


func _process(delta: float) -> void:
	if not has_node("/root/HubTimePhase"):
		return
	var phase: float = HubTimePhase.sample_phase01()
	if not HubTimePhase.is_dusk_or_night():
		return
	var strength: float = HubTimePhase.firefly_strength(phase)
	if strength <= 0.0:
		return
	_prune_active()
	if _active.size() >= R5Constants.FIREFLY_MAX_ACTIVE:
		return
	_spawn_accum += delta
	if _spawn_accum < R5Constants.FIREFLY_SPAWN_SEC:
		return
	_spawn_accum = 0.0
	_spawn_mote(strength)


func _prune_active() -> void:
	var kept: Array[Area2D] = []
	for node: Area2D in _active:
		if is_instance_valid(node):
			kept.append(node)
	_active = kept


func _spawn_mote(strength: float) -> void:
	var mote := Area2D.new()
	mote.collision_layer = 4
	mote.collision_mask = 0
	mote.input_pickable = true
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 10.0
	shape.shape = circle
	mote.add_child(shape)
	var sprite := AnimatedSprite2D.new()
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.centered = true
	sprite.scale = Vector2.ONE
	var frames := SpriteFrames.new()
	var tex: Texture2D = load(WARM_STRIP) as Texture2D
	if tex != null:
		frames.add_animation(&"mote")
		frames.set_animation_loop(&"mote", true)
		frames.set_animation_speed(&"mote", 4.0)
		for i: int in range(4):
			var atlas := AtlasTexture.new()
			atlas.atlas = tex
			atlas.region = Rect2(float(i * 8), 0.0, 8.0, 8.0)
			frames.add_frame(&"mote", atlas)
		sprite.sprite_frames = frames
		sprite.play(&"mote")
	sprite.modulate = Color(1.0, 0.95, 0.5, 0.9 * strength)
	mote.add_child(sprite)
	mote.global_position = _forest_edge_point()
	mote.input_event.connect(_on_mote_click.bind(mote))
	add_child(mote)
	_active.append(mote)


func _forest_edge_point() -> Vector2:
	var r: Rect2 = GLADE_RECT
	var side: int = randi() % 4
	var t: float = randf()
	match side:
		0:
			return Vector2(lerpf(r.position.x, r.end.x, t), r.position.y)
		1:
			return Vector2(r.end.x, lerpf(r.position.y, r.end.y, t))
		2:
			return Vector2(lerpf(r.position.x, r.end.x, t), r.end.y)
		_:
			return Vector2(r.position.x, lerpf(r.position.y, r.end.y, t))


func _on_mote_click(_viewport: Node, event: InputEvent, _idx: int, mote: Area2D) -> void:
	if not (event is InputEventMouseButton):
		return
	var mb: InputEventMouseButton = event
	if not mb.pressed or mb.button_index != MOUSE_BUTTON_LEFT:
		return
	GameState.firefly_jar_count += 1
	GameState.echo_flags_changed.emit()
	var now: int = Time.get_ticks_msec()
	if now - _last_catch_msec >= CATCH_THROTTLE_MSEC and has_node("/root/GameAudio"):
		_last_catch_msec = now
		GameAudio.play(&"sfx_firefly_catch")
	mote.queue_free()
	_active.erase(mote)


static func catch_throttle_msec() -> int:
	return CATCH_THROTTLE_MSEC
