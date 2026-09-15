extends Area2D
class_name WispOrb
## Unassigned orbits Keeper (art v0.1.9). Assigned: tween with fly, then node_orbit at r≈28 (v0.1.10).

signal wisp_clicked(wisp_id: int)

const KEEPER_ORBIT_RADIUS: float = 56.0
const NODE_ORBIT_RADIUS: float = 28.0
const KEEPER_ORBIT_SPEED: float = 1.15
const NODE_ORBIT_SPEED: float = 1.45
const ORBIT_HOLD_MS: float = 80.0
const FLY_HOLD_MS: float = 60.0
const NODE_ORBIT_HOLD_MS: float = 90.0
const IDLE_HOLD_MS: float = 140.0
const FLY_SPEED: float = 240.0
const FLY_MIN_SEC: float = 0.12
const FLY_MAX_SEC: float = 1.15
const ARRIVE_DIST: float = 10.0
const TARGET_CHEST_OFFSET: Vector2 = Vector2(0, -48)
const KEEPER_CHEST_OFFSET: Vector2 = Vector2(0, -48)

enum MotionKind { KEEPER_ORBIT, FLY, NODE_ORBIT }

@onready var sprite: AnimatedSprite2D = $Sprite
@onready var label: Label = $Label

var wisp_id: int = 0
var _orbit_angle: float = 0.0
var _bob_t: float = 0.0
var _motion: int = MotionKind.KEEPER_ORBIT
var _cached_assignment: String = ""
var _fly_tween: Tween
var _at_assigned_orbit: bool = false
var _placed: bool = false


func _ready() -> void:
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.centered = true
	sprite.sprite_frames = _build_frames()
	sprite.play(&"orbit")
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.position = Vector2(-40, -28)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	input_event.connect(_on_input_event)
	add_to_group("wisp")
	add_to_group("interactable")
	z_index = 2
	_orbit_angle = _even_slot_angle()
	_refresh_label()


func _build_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")
	_add_anim(frames, &"orbit", [
		"res://assets/art/wisps/wisp_orbit_0000.png",
		"res://assets/art/wisps/wisp_orbit_0001.png",
		"res://assets/art/wisps/wisp_orbit_0002.png",
		"res://assets/art/wisps/wisp_orbit_0003.png",
		"res://assets/art/wisps/wisp_orbit_0004.png",
		"res://assets/art/wisps/wisp_orbit_0005.png",
		"res://assets/art/wisps/wisp_orbit_0006.png",
		"res://assets/art/wisps/wisp_orbit_0007.png",
	], ORBIT_HOLD_MS)
	_add_anim(frames, &"fly", [
		"res://assets/art/wisps/wisp_fly_0000.png",
		"res://assets/art/wisps/wisp_fly_0001.png",
		"res://assets/art/wisps/wisp_fly_0002.png",
		"res://assets/art/wisps/wisp_fly_0003.png",
		"res://assets/art/wisps/wisp_fly_0004.png",
		"res://assets/art/wisps/wisp_fly_0005.png",
	], FLY_HOLD_MS)
	_add_anim(frames, &"node_orbit", [
		"res://assets/art/wisps/wisp_node_orbit_0000.png",
		"res://assets/art/wisps/wisp_node_orbit_0001.png",
		"res://assets/art/wisps/wisp_node_orbit_0002.png",
		"res://assets/art/wisps/wisp_node_orbit_0003.png",
		"res://assets/art/wisps/wisp_node_orbit_0004.png",
		"res://assets/art/wisps/wisp_node_orbit_0005.png",
		"res://assets/art/wisps/wisp_node_orbit_0006.png",
		"res://assets/art/wisps/wisp_node_orbit_0007.png",
	], NODE_ORBIT_HOLD_MS)
	# parked / assigned are aliases of node_orbit (art v0.1.10).
	_add_anim(frames, &"parked", [
		"res://assets/art/wisps/wisp_node_orbit_0000.png",
		"res://assets/art/wisps/wisp_node_orbit_0001.png",
		"res://assets/art/wisps/wisp_node_orbit_0002.png",
		"res://assets/art/wisps/wisp_node_orbit_0003.png",
		"res://assets/art/wisps/wisp_node_orbit_0004.png",
		"res://assets/art/wisps/wisp_node_orbit_0005.png",
		"res://assets/art/wisps/wisp_node_orbit_0006.png",
		"res://assets/art/wisps/wisp_node_orbit_0007.png",
	], NODE_ORBIT_HOLD_MS)
	_add_anim(frames, &"assigned", [
		"res://assets/art/wisps/wisp_node_orbit_0000.png",
		"res://assets/art/wisps/wisp_node_orbit_0001.png",
		"res://assets/art/wisps/wisp_node_orbit_0002.png",
		"res://assets/art/wisps/wisp_node_orbit_0003.png",
		"res://assets/art/wisps/wisp_node_orbit_0004.png",
		"res://assets/art/wisps/wisp_node_orbit_0005.png",
		"res://assets/art/wisps/wisp_node_orbit_0006.png",
		"res://assets/art/wisps/wisp_node_orbit_0007.png",
	], NODE_ORBIT_HOLD_MS)
	_add_anim(frames, &"selected", [
		"res://assets/art/wisps/wisp_selected_0000.png",
		"res://assets/art/wisps/wisp_selected_0001.png",
		"res://assets/art/wisps/wisp_selected_0002.png",
		"res://assets/art/wisps/wisp_selected_0003.png",
	], IDLE_HOLD_MS)
	return frames


func _add_anim(frames: SpriteFrames, anim: StringName, paths: Array, hold_ms: float) -> void:
	frames.add_animation(anim)
	frames.set_animation_loop(anim, true)
	frames.set_animation_speed(anim, 1000.0 / hold_ms)
	for path: String in paths:
		var tex: Texture2D = load(path) as Texture2D
		if tex:
			frames.add_frame(anim, tex)


func setup(id: int) -> void:
	wisp_id = id
	_orbit_angle = _even_slot_angle()
	_at_assigned_orbit = false
	_cached_assignment = ""
	if is_inside_tree():
		_refresh_label()


func _even_slot_angle() -> float:
	var n: int = maxi(1, GameState.wisp_count)
	return (TAU * float(wisp_id) / float(n))


func get_node_orbit_radius() -> float:
	return NODE_ORBIT_RADIUS


func get_motion_kind() -> StringName:
	match _motion:
		MotionKind.FLY:
			return &"fly"
		MotionKind.NODE_ORBIT:
			return &"node_orbit"
		_:
			return &"orbit"


func is_orbiting_assigned_target() -> bool:
	## Assigned (including fly tween toward the node).
	return GameState.get_wisp_assignment(wisp_id) != ""


func is_at_assigned_orbit() -> bool:
	return _at_assigned_orbit and _motion == MotionKind.NODE_ORBIT


func is_flying() -> bool:
	return _motion == MotionKind.FLY


func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event
		if not mb.pressed:
			return
		if mb.button_index == MOUSE_BUTTON_LEFT:
			wisp_clicked.emit(wisp_id)
			get_viewport().set_input_as_handled()
		elif mb.button_index == MOUSE_BUTTON_RIGHT:
			get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	_bob_t += delta
	if not _placed:
		global_position = _keeper_slot_pos()
		_placed = true
	var assigned_node: String = GameState.get_wisp_assignment(wisp_id)
	if assigned_node != _cached_assignment:
		_cached_assignment = assigned_node
		if assigned_node != "":
			_begin_fly_to(_node_insert_pos(assigned_node))
		else:
			_begin_fly_to(_keeper_slot_pos())

	if _motion == MotionKind.FLY:
		_play_anim(&"fly")
		_refresh_label()
		return

	var is_sel: bool = GameState.selected_wisp_id == wisp_id
	if assigned_node != "":
		_tick_node_orbit(assigned_node, delta)
		_play_anim(&"node_orbit")
		_refresh_label()
		return

	_at_assigned_orbit = false
	_tick_keeper_orbit(delta, is_sel)
	_refresh_label()


func _tick_keeper_orbit(delta: float, is_sel: bool) -> void:
	var keepers: Array[Node] = get_tree().get_nodes_in_group("keeper")
	if keepers.is_empty():
		return
	var k: Node2D = keepers[0] as Node2D
	sprite.flip_h = false
	if is_sel:
		_play_anim(&"selected")
	else:
		_orbit_angle += KEEPER_ORBIT_SPEED * delta
		_play_anim(&"orbit")
	var slot: float = _even_slot_angle()
	var angle: float = slot if is_sel else (_orbit_angle + slot)
	var bob: float = sin(_bob_t * 2.8 + float(wisp_id)) * 3.0
	var offset := Vector2(cos(angle), sin(angle) * 0.55) * KEEPER_ORBIT_RADIUS
	global_position = k.global_position + KEEPER_CHEST_OFFSET + offset + Vector2(0, bob)


func _tick_node_orbit(node_id: String, delta: float) -> void:
	sprite.flip_h = false
	_orbit_angle += NODE_ORBIT_SPEED * delta
	global_position = _node_slot_pos(node_id)
	_at_assigned_orbit = true


func _node_insert_pos(node_id: String) -> Vector2:
	return _node_slot_pos(node_id)


func _node_slot_pos(node_id: String) -> Vector2:
	var center: Vector2 = _resolve_assignment_center(node_id)
	var angle: float = _orbit_angle + _even_slot_angle()
	var bob: float = sin(_bob_t * 2.8 + float(wisp_id)) * 2.0
	var offset := Vector2(cos(angle), sin(angle) * 0.55) * NODE_ORBIT_RADIUS
	return center + offset + Vector2(0, bob)


func _keeper_slot_pos() -> Vector2:
	var keepers: Array[Node] = get_tree().get_nodes_in_group("keeper")
	if keepers.is_empty():
		return global_position
	var k: Node2D = keepers[0] as Node2D
	var angle: float = _orbit_angle + _even_slot_angle()
	var offset := Vector2(cos(angle), sin(angle) * 0.55) * KEEPER_ORBIT_RADIUS
	return k.global_position + KEEPER_CHEST_OFFSET + offset


func _begin_fly_to(dest: Vector2) -> void:
	_kill_fly_tween()
	_at_assigned_orbit = false
	if global_position.distance_to(dest) <= ARRIVE_DIST:
		_on_fly_finished()
		return
	_motion = MotionKind.FLY
	sprite.flip_h = dest.x < global_position.x
	_play_anim(&"fly")
	var dist: float = global_position.distance_to(dest)
	var dur: float = clampf(dist / FLY_SPEED, FLY_MIN_SEC, FLY_MAX_SEC)
	_fly_tween = create_tween()
	_fly_tween.set_trans(Tween.TRANS_SINE)
	_fly_tween.set_ease(Tween.EASE_IN_OUT)
	_fly_tween.tween_property(self, "global_position", dest, dur)
	_fly_tween.finished.connect(_on_fly_finished)


func _on_fly_finished() -> void:
	_fly_tween = null
	sprite.flip_h = false
	if GameState.get_wisp_assignment(wisp_id) != "":
		_motion = MotionKind.NODE_ORBIT
		_at_assigned_orbit = true
		_play_anim(&"node_orbit")
	else:
		_motion = MotionKind.KEEPER_ORBIT
		_at_assigned_orbit = false
		_play_anim(&"orbit")


func _kill_fly_tween() -> void:
	if _fly_tween != null:
		_fly_tween.kill()
		_fly_tween = null


func _resolve_assignment_center(node_id: String) -> Vector2:
	if node_id == GameState.NODE_ID_MANATREE:
		var trees: Array[Node] = get_tree().get_nodes_in_group("manatree")
		for n: Node in trees:
			if n is Node2D:
				return (n as Node2D).global_position + TARGET_CHEST_OFFSET
		return global_position
	var nodes: Array[Node] = get_tree().get_nodes_in_group("harvest_node")
	for n: Node in nodes:
		if n is Node2D and n.get("resource_id") != null:
			var rid: StringName = n.get("resource_id") as StringName
			if GameState.node_id_for_resource(rid) == node_id:
				return (n as Node2D).global_position + TARGET_CHEST_OFFSET
	return global_position


func _play_anim(anim: StringName) -> void:
	if sprite.animation != anim or not sprite.is_playing():
		sprite.play(anim)


func _refresh_label() -> void:
	if label == null:
		return
	var assigned: String = GameState.get_wisp_assignment(wisp_id)
	if GameState.selected_wisp_id == wisp_id:
		label.text = ContentStrings.get_text("wisp_selected")
	elif assigned != "":
		var rid: StringName = GameState.resource_for_node_id(assigned)
		var item: String = ContentStrings.get_text("hud_%s" % String(rid))
		label.text = ContentStrings.get_text("wisp_gathering_hud", {"item": item})
	else:
		label.text = ContentStrings.get_text("wisp_idle_hud")
