extends Area2D
class_name Gatherable
## 64×64 ColorRect gather prop (VISUAL_BIBLE). SYSTEMS gather amounts + cooldown.

@export var resource_id: StringName = &"wood"
@export var display_name: String = "Wood"
@export var stub_color: Color = Color("8d6e63")
@export var node_key: String = "wood"

@onready var body_rect: ColorRect = $BodyRect
@onready var label: Label = $Label

var _available: bool = true
const BODY_SIZE: Vector2 = Vector2(64, 64)


func _ready() -> void:
	body_rect.size = BODY_SIZE
	body_rect.position = Vector2(-32, -64)
	body_rect.color = stub_color
	body_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.position = Vector2(-40, -84)
	label.text = ContentStrings.get_text("node_%s_prompt" % node_key)
	input_event.connect(_on_input_event)
	add_to_group("gatherable")
	add_to_group("interactable")
	var cs: CollisionShape2D = $CollisionShape2D
	if cs and cs.shape is RectangleShape2D:
		(cs.shape as RectangleShape2D).size = BODY_SIZE
		cs.position = Vector2(0, -32)


func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT and _available:
			_request_keeper_interact()


func _request_keeper_interact() -> void:
	var keepers: Array[Node] = get_tree().get_nodes_in_group("keeper")
	if keepers.is_empty():
		return
	var k: Keeper = keepers[0] as Keeper
	if k:
		k.move_to(global_position, self)


func on_interact(_keeper: Node) -> void:
	if not _available:
		GameState.status_message.emit(ContentStrings.get_text("node_%s_cd" % node_key))
		GameAudio.play(&"sfx_gather_cooldown")
		return
	var amount: int = GameState.get_gather_grant(resource_id)
	GameState.add_resource(resource_id, amount)
	GameState.status_message.emit(ContentStrings.get_text("node_%s_ok" % node_key))
	GameAudio.play_gather(resource_id)
	_available = false
	modulate = Color(0.45, 0.45, 0.45, 0.7)
	label.text = ContentStrings.get_text("node_%s_cd" % node_key)
	var cd: float = GameState.param_float("NODE_COOLDOWN_SEC", 3.0)
	get_tree().create_timer(cd).timeout.connect(_respawn)


func _respawn() -> void:
	_available = true
	modulate = Color.WHITE
	label.text = ContentStrings.get_text("node_%s_prompt" % node_key)
