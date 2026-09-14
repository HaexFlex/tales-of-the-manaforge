extends CharacterBody2D
class_name Keeper
## Point-and-click Keeper. AnimatedSprite2D 128×128, feet-anchored (art pack).

signal arrived
signal interaction_finished(target: Node)

@onready var sprite: AnimatedSprite2D = $Sprite
@onready var label: Label = $Label

var _target: Vector2 = Vector2.ZERO
var _moving: bool = false
var _pending_interact: Node = null
var _facing_back: bool = false
const ARRIVE_DIST: float = 12.0
const INTERACT_DIST: float = 64.0
## Visual bible: feet at (64, 128) on 128×128 canvas → body sits above origin.
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
	label.text = "Keeper"
	label.position = Vector2(-40, -148)
	add_to_group("keeper")


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


func _physics_process(_delta: float) -> void:
	if not _moving:
		velocity = Vector2.ZERO
		move_and_slide()
		_update_anim()
		return
	var speed: float = GameState.get_move_speed()
	var to_target: Vector2 = _target - global_position
	if to_target.length() <= ARRIVE_DIST:
		_moving = false
		velocity = Vector2.ZERO
		move_and_slide()
		_update_anim()
		arrived.emit()
		_try_interact()
		return
	velocity = to_target.normalized() * speed
	if absf(velocity.y) >= absf(velocity.x):
		_facing_back = velocity.y < 0.0
	move_and_slide()
	_update_anim()


func _update_anim() -> void:
	var want: StringName
	if _moving:
		# walk_front missing in pack — use walk_back when facing back, idle_front otherwise
		want = &"walk_back" if _facing_back else &"idle_front"
	else:
		want = &"idle_back" if _facing_back else &"idle_front"
	if sprite.animation != want or not sprite.is_playing():
		sprite.play(want)


func move_to(world_pos: Vector2, interact: Node = null) -> void:
	_target = world_pos
	_pending_interact = interact
	_moving = true


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
