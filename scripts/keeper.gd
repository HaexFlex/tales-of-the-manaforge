extends CharacterBody2D
class_name Keeper
## Point-and-click Keeper. ColorRect stub 128×128, feet-anchored (VISUAL_BIBLE).

signal arrived
signal interaction_finished(target: Node)

@onready var body_rect: ColorRect = $BodyRect
@onready var label: Label = $Label

var _target: Vector2 = Vector2.ZERO
var _moving: bool = false
var _pending_interact: Node = null
const ARRIVE_DIST: float = 12.0
const INTERACT_DIST: float = 64.0
## Visual bible: feet at (64, 128) on 128×128 canvas → body sits above origin.
const BODY_SIZE: Vector2 = Vector2(128, 128)


func _ready() -> void:
	_target = global_position
	body_rect.size = BODY_SIZE
	body_rect.position = Vector2(-64, -128)
	body_rect.color = Color("2e7d4f")
	body_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.text = "Keeper"
	label.position = Vector2(-40, -148)
	add_to_group("keeper")


func _physics_process(_delta: float) -> void:
	if not _moving:
		velocity = Vector2.ZERO
		move_and_slide()
		return
	var speed: float = GameState.get_move_speed()
	var to_target: Vector2 = _target - global_position
	if to_target.length() <= ARRIVE_DIST:
		_moving = false
		velocity = Vector2.ZERO
		move_and_slide()
		arrived.emit()
		_try_interact()
		return
	velocity = to_target.normalized() * speed
	move_and_slide()


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
