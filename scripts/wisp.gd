extends Area2D
class_name WispOrb
## Clickable wisp — unassigned orbits Keeper (art v0.1.9); assigned parks on node.

signal wisp_clicked(wisp_id: int)

const ORBIT_RADIUS: float = 56.0
const ORBIT_SPEED: float = 1.15
const ORBIT_HOLD_MS: float = 80.0
const IDLE_HOLD_MS: float = 140.0
const PARK_OFFSET: Vector2 = Vector2(28, -36)
const KEEPER_CHEST_OFFSET: Vector2 = Vector2(0, -48)

@onready var sprite: AnimatedSprite2D = $Sprite
@onready var label: Label = $Label

var wisp_id: int = 0
var _orbit_angle: float = 0.0
var _bob_t: float = 0.0


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
	_add_anim(frames, &"selected", [
		"res://assets/art/wisps/wisp_selected_0000.png",
		"res://assets/art/wisps/wisp_selected_0001.png",
		"res://assets/art/wisps/wisp_selected_0002.png",
		"res://assets/art/wisps/wisp_selected_0003.png",
	], IDLE_HOLD_MS)
	_add_anim(frames, &"parked", [
		"res://assets/art/wisps/wisp_parked_0000.png",
		"res://assets/art/wisps/wisp_parked_0001.png",
		"res://assets/art/wisps/wisp_parked_0002.png",
		"res://assets/art/wisps/wisp_parked_0003.png",
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
	if is_inside_tree():
		_refresh_label()


func _even_slot_angle() -> float:
	var n: int = maxi(1, GameState.wisp_count)
	return (TAU * float(wisp_id) / float(n))


func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			wisp_clicked.emit(wisp_id)
			get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	_bob_t += delta
	var assigned_node: String = GameState.get_wisp_assignment(wisp_id)
	var is_sel: bool = GameState.selected_wisp_id == wisp_id
	if assigned_node != "":
		_park_at_node(assigned_node, delta)
		_play_anim(&"parked" if not is_sel else &"selected")
		_refresh_label()
		return
	# Orbit Keeper — even spacing, follow walk (meta.orbit_layout).
	var keepers: Array[Node] = get_tree().get_nodes_in_group("keeper")
	if keepers.is_empty():
		return
	var k: Node2D = keepers[0] as Node2D
	if is_sel:
		# Pause orbit motion; freeze near slot + selected clip.
		_play_anim(&"selected")
	else:
		_orbit_angle += ORBIT_SPEED * delta
		_play_anim(&"orbit")
	var slot: float = _even_slot_angle()
	var angle: float = _orbit_angle if not is_sel else slot
	# Keep relative slot offset so wisps stay evenly spaced while spinning.
	if not is_sel:
		angle = _orbit_angle + slot
	var bob: float = sin(_bob_t * 2.8 + float(wisp_id)) * 3.0
	var offset := Vector2(cos(angle), sin(angle) * 0.55) * ORBIT_RADIUS
	global_position = k.global_position + KEEPER_CHEST_OFFSET + offset + Vector2(0, bob)
	_refresh_label()


func _park_at_node(node_id: String, delta: float) -> void:
	var target: Vector2 = global_position
	var nodes: Array[Node] = get_tree().get_nodes_in_group("harvest_node")
	for n: Node in nodes:
		if n is Gatherable:
			var g: Gatherable = n as Gatherable
			if GameState.node_id_for_resource(g.resource_id) == node_id:
				target = g.global_position + PARK_OFFSET
				break
	var bob: float = sin(_bob_t * 2.2 + float(wisp_id)) * 3.0
	global_position = global_position.lerp(target + Vector2(0, bob), mini(1.0, delta * 6.0))


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
