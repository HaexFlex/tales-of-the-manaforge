extends CharacterBody2D
class_name Keeper
## RTS LMB-select Keeper + harvest / water channels (SYSTEMS v0.3.2).

signal arrived
signal interaction_finished(target: Node)
signal channel_changed(kind: StringName, active: bool)

@onready var sprite: AnimatedSprite2D = $Sprite
@onready var label: Label = $Label
@onready var select_ring: Sprite2D = $SelectRing
@onready var click_area: Area2D = $ClickArea

var _target: Vector2 = Vector2.ZERO
var _moving: bool = false
var _pending_interact: Node = null
var _facing_back: bool = false

enum ChannelKind { NONE, HARVEST, WATER }
var _channel_kind: int = ChannelKind.NONE
var _channel_target: Node = null
var _channel_accum: float = 0.0

const ARRIVE_DIST: float = 12.0
const INTERACT_DIST: float = 64.0
const BODY_SIZE: Vector2 = Vector2(128, 128)
const IDLE_HOLD_MS: float = 140.0
const WALK_HOLD_MS: float = 90.0


func _ready() -> void:
	_target = global_position
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.centered = false
	sprite.offset = Vector2(-64, -128)
	sprite.sprite_frames = _build_frames()
	sprite.play(&"idle_front")
	label.text = ContentStrings.get_text("keeper_select")
	label.position = Vector2(-40, -148)
	add_to_group("keeper")
	if select_ring:
		select_ring.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		select_ring.centered = true
		select_ring.position = Vector2(0, 0)
		select_ring.texture = load("res://assets/art/keeper/keeper_select_ring.png") as Texture2D
		select_ring.visible = false
		select_ring.z_index = -1
	if click_area:
		click_area.input_event.connect(_on_click_area_input)
		click_area.collision_layer = 4
		click_area.collision_mask = 0
		click_area.monitoring = false
		click_area.monitorable = true
		click_area.add_to_group("interactable")
	GameState.selection_changed.connect(_on_selection_changed)
	_on_selection_changed()


func _build_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")
	_add_anim(frames, &"idle_front", [
		"res://assets/art/keeper/keeper_idle_front_0000.png",
		"res://assets/art/keeper/keeper_idle_front_0001.png",
		"res://assets/art/keeper/keeper_idle_front_0002.png",
		"res://assets/art/keeper/keeper_idle_front_0003.png",
	], IDLE_HOLD_MS)
	_add_anim(frames, &"idle_back", [
		"res://assets/art/keeper/keeper_idle_back_0000.png",
	], IDLE_HOLD_MS)
	_add_anim(frames, &"walk_back", [
		"res://assets/art/keeper/keeper_walk_back_0000.png",
		"res://assets/art/keeper/keeper_walk_back_0001.png",
		"res://assets/art/keeper/keeper_walk_back_0002.png",
		"res://assets/art/keeper/keeper_walk_back_0003.png",
		"res://assets/art/keeper/keeper_walk_back_0004.png",
		"res://assets/art/keeper/keeper_walk_back_0005.png",
	], WALK_HOLD_MS)
	return frames


func _add_anim(frames: SpriteFrames, anim: StringName, paths: Array, hold_ms: float) -> void:
	frames.add_animation(anim)
	frames.set_animation_loop(anim, true)
	frames.set_animation_speed(anim, 1000.0 / hold_ms)
	for path: String in paths:
		var tex: Texture2D = load(path) as Texture2D
		frames.add_frame(anim, tex)


func _physics_process(delta: float) -> void:
	if _moving:
		var speed: float = GameState.get_move_speed()
		var to_target: Vector2 = _target - global_position
		if to_target.length() <= ARRIVE_DIST:
			_moving = false
			velocity = Vector2.ZERO
			move_and_slide()
			_update_anim()
			arrived.emit()
			_try_interact()
		else:
			velocity = to_target.normalized() * speed
			if absf(velocity.y) >= absf(velocity.x):
				_facing_back = velocity.y < 0.0
			move_and_slide()
			_update_anim()
			# Walking away cancels channel once out of range.
			_check_channel_range()
		return

	velocity = Vector2.ZERO
	move_and_slide()
	_update_anim()
	_tick_channel(delta)


func _update_anim() -> void:
	var want: StringName
	if _moving:
		want = &"walk_back" if _facing_back else &"idle_front"
	else:
		want = &"idle_back" if _facing_back else &"idle_front"
	if sprite.animation != want or not sprite.is_playing():
		sprite.play(want)


func move_to(world_pos: Vector2, interact: Node = null) -> void:
	# New move / other interact cancels active channel.
	if _channel_kind != ChannelKind.NONE:
		if interact != _channel_target:
			cancel_channel()
	_target = world_pos
	_pending_interact = interact
	_moving = true


func start_harvest_channel(node: Gatherable) -> void:
	if node == null:
		return
	cancel_channel()
	_channel_kind = ChannelKind.HARVEST
	_channel_target = node
	_channel_accum = 0.0
	node.set_channeling(true)
	GameAudio.play_channel_start()
	GameState.status_message.emit(ContentStrings.get_text("harvest_start"))
	channel_changed.emit(&"harvest", true)
	# Immediate first pulse so click feels responsive, then every CHANNEL_PULSE_SEC.
	node.on_harvest_pulse()
	_channel_accum = 0.0


func start_water_channel(tree: Manatree) -> void:
	if tree == null:
		return
	cancel_channel()
	_channel_kind = ChannelKind.WATER
	_channel_target = tree
	_channel_accum = 0.0
	tree.set_watering(true)
	GameAudio.play_channel_start()
	GameState.status_message.emit(ContentStrings.get_text("tree_water_start"))
	channel_changed.emit(&"water", true)
	_do_water_pulse()
	_channel_accum = 0.0


func cancel_channel(emit_status: bool = true) -> void:
	if _channel_kind == ChannelKind.NONE:
		return
	var kind: int = _channel_kind
	var target: Node = _channel_target
	_channel_kind = ChannelKind.NONE
	_channel_target = null
	_channel_accum = 0.0
	if kind == ChannelKind.HARVEST and target is Gatherable:
		var g: Gatherable = target as Gatherable
		if emit_status:
			g.on_channel_cancel()
		else:
			g.set_channeling(false)
		channel_changed.emit(&"harvest", false)
	elif kind == ChannelKind.WATER and target is Manatree:
		var t: Manatree = target as Manatree
		t.set_watering(false)
		if emit_status:
			GameState.status_message.emit(ContentStrings.get_text("tree_water_cancel"))
		channel_changed.emit(&"water", false)


func is_channeling() -> bool:
	return _channel_kind != ChannelKind.NONE


func get_channel_kind() -> StringName:
	match _channel_kind:
		ChannelKind.HARVEST:
			return &"harvest"
		ChannelKind.WATER:
			return &"water"
		_:
			return &""


func _channel_stand_pos(target: Node) -> Vector2:
	if target is Manatree:
		return target.global_position + Vector2(0, 40)
	return target.global_position


func _check_channel_range() -> void:
	if _channel_kind == ChannelKind.NONE or _channel_target == null or not is_instance_valid(_channel_target):
		if _channel_kind != ChannelKind.NONE:
			cancel_channel()
		return
	var range_px: float = GameState.get_harvest_range() + 24.0
	if global_position.distance_to(_channel_stand_pos(_channel_target)) > range_px * 2.0:
		var was_harvest: bool = _channel_kind == ChannelKind.HARVEST
		cancel_channel(false)
		if was_harvest:
			GameState.status_message.emit(ContentStrings.get_text("harvest_out_of_range"))
		else:
			GameState.status_message.emit(ContentStrings.get_text("tree_water_out_of_range"))


func _tick_channel(delta: float) -> void:
	if _channel_kind == ChannelKind.NONE:
		return
	if _channel_target == null or not is_instance_valid(_channel_target):
		cancel_channel(false)
		return
	var range_px: float = GameState.get_harvest_range() + 32.0
	if global_position.distance_to(_channel_stand_pos(_channel_target)) > range_px:
		var was_harvest: bool = _channel_kind == ChannelKind.HARVEST
		cancel_channel(false)
		if was_harvest:
			GameState.status_message.emit(ContentStrings.get_text("harvest_out_of_range"))
		else:
			GameState.status_message.emit(ContentStrings.get_text("tree_water_out_of_range"))
		return
	_channel_accum += delta
	var pulse: float = GameState.get_channel_pulse_sec()
	while _channel_accum >= pulse:
		_channel_accum -= pulse
		if _channel_kind == ChannelKind.HARVEST and _channel_target is Gatherable:
			(_channel_target as Gatherable).on_harvest_pulse()
		elif _channel_kind == ChannelKind.WATER:
			_do_water_pulse()


func _do_water_pulse() -> void:
	var result: Dictionary = GameState.apply_water_pulse()
	if not bool(result.get("ok", false)):
		cancel_channel(false)
		return
	GameAudio.play_water_pulse()
	GameState.status_message.emit(ContentStrings.get_text("tree_water_pulse_hud", {
		"shards": int(result.get("shards", 0)),
		"essence": int(result.get("essence", 0)),
	}))
	if _channel_target is Manatree:
		(_channel_target as Manatree).refresh_after_care()


func _try_interact() -> void:
	if _pending_interact == null or not is_instance_valid(_pending_interact):
		_pending_interact = null
		return
	if global_position.distance_to(_pending_interact.global_position) > INTERACT_DIST * 2.5:
		_pending_interact = null
		return
	if _pending_interact.has_method("on_interact"):
		_pending_interact.call("on_interact", self)
	interaction_finished.emit(_pending_interact)
	_pending_interact = null


func _on_click_area_input(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event
		if not mb.pressed:
			return
		if mb.button_index == MOUSE_BUTTON_LEFT:
			GameState.select_keeper()
			GameState.status_message.emit(ContentStrings.get_text("keeper_select_hint"))
			get_viewport().set_input_as_handled()
		elif mb.button_index == MOUSE_BUTTON_RIGHT:
			get_viewport().set_input_as_handled()


func _on_selection_changed() -> void:
	if select_ring:
		select_ring.visible = GameState.keeper_selected
	if label:
		if GameState.keeper_selected:
			label.text = ContentStrings.get_text("keeper_selected")
			modulate = Color(1.08, 1.12, 1.0, 1.0)
		else:
			label.text = ContentStrings.get_text("keeper_select")
			modulate = Color.WHITE
