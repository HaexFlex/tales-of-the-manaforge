extends Node2D
## Catchable fireflies at dusk/night on the forest ring. Jar count on KeepersBench.

var _spawn_accum: float = 0.0
var _active: Array[Area2D] = []


func _ready() -> void:
	add_to_group("firefly_ring")
	set_process(true)


func _process(delta: float) -> void:
	if not has_node("/root/HubTimePhase"):
		return
	var phase: float = HubTimePhase.sample_phase01()
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
	var dot := ColorRect.new()
	dot.size = Vector2(8, 8)
	dot.position = Vector2(-4, -4)
	dot.color = Color(1.0, 0.95, 0.5, 0.9 * strength)
	mote.add_child(dot)
	mote.global_position = _ring_point()
	mote.input_event.connect(_on_mote_click.bind(mote))
	add_child(mote)
	_active.append(mote)


func _ring_point() -> Vector2:
	var center: Vector2 = Vector2(2160, 2025)
	if has_node("/root/ForgeJobs"):
		center = ForgeJobs.manatree_origin() + Vector2(0, -80)
	var angle: float = randf() * TAU
	var rx: float = 1500.0
	var ry: float = 1200.0
	return center + Vector2(cos(angle) * rx, sin(angle) * ry)


func _on_mote_click(_viewport: Node, event: InputEvent, _idx: int, mote: Area2D) -> void:
	if not (event is InputEventMouseButton):
		return
	var mb: InputEventMouseButton = event
	if not mb.pressed or mb.button_index != MOUSE_BUTTON_LEFT:
		return
	GameState.firefly_jar_count += 1
	GameState.echo_flags_changed.emit()
	mote.queue_free()
	_active.erase(mote)
