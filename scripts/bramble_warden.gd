extends Area2D
## Bramble keeps watch at the trailhead after he is spared.
## He is not in the party. Join lines stay in the string table for a later batch.

const IDLE_DIR: String = "res://assets/art/bramble/anim/idle/south"
const FRAME_SEC: float = 0.14
const ENTRY_OFFSET: Vector2 = Vector2(0, 24)

@onready var sprite: Sprite2D = $Visual/Sprite
@onready var label: Label = $Label

var _frames: Array[Texture2D] = []
var _frame_i: int = 0
var _frame_t: float = 0.0
var _hovered: bool = false


func _ready() -> void:
	add_to_group("bramble_warden")
	add_to_group("interactable")
	y_sort_enabled = true
	input_pickable = true
	monitoring = false
	monitorable = true
	collision_layer = 4
	collision_mask = 0
	if label:
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mouse_entered.connect(_on_hover.bind(true))
	mouse_exited.connect(_on_hover.bind(false))
	_load_frames()
	_fit_sprite()
	input_event.connect(_on_input_event)
	if not GameState.echo_flags_changed.is_connected(refresh_presence):
		GameState.echo_flags_changed.connect(refresh_presence)
	if not GameState.load_completed.is_connected(refresh_presence):
		GameState.load_completed.connect(refresh_presence)
	refresh_presence()


func _load_frames() -> void:
	_frames.clear()
	for i: int in range(1, 13):
		var path: String = "%s/bramble_idle_south_%04d.png" % [IDLE_DIR, i]
		if not ResourceLoader.exists(path):
			continue
		var tex: Texture2D = load(path) as Texture2D
		if tex:
			_frames.append(tex)


func _fit_sprite() -> void:
	if sprite == null:
		return
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.centered = false
	sprite.offset = Vector2(-64, -128)
	if not _frames.is_empty():
		sprite.texture = _frames[0]
	var pick: CollisionShape2D = get_node_or_null("CollisionShape2D") as CollisionShape2D
	if pick and pick.shape is RectangleShape2D:
		var rect: RectangleShape2D = (pick.shape as RectangleShape2D).duplicate() as RectangleShape2D
		rect.size = Vector2(48, 72)
		pick.shape = rect
		pick.position = Vector2(0, -40)


func _process(delta: float) -> void:
	if not visible or _frames.size() <= 1 or sprite == null:
		return
	_frame_t += delta
	if _frame_t < FRAME_SEC:
		return
	_frame_t = 0.0
	_frame_i = (_frame_i + 1) % _frames.size()
	sprite.texture = _frames[_frame_i]


func refresh_presence() -> void:
	var show_it: bool = GameState.echo_02_outcome == "spare"
	visible = show_it
	input_pickable = show_it
	monitorable = show_it
	if label:
		label.visible = _hovered and show_it
		label.text = ContentStrings.get_text("bramble_name")


func _on_hover(inside: bool) -> void:
	_hovered = inside
	if label:
		label.visible = _hovered and visible


func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if not visible or not (event is InputEventMouseButton):
		return
	var mb: InputEventMouseButton = event
	if not mb.pressed:
		return
	if mb.button_index == MOUSE_BUTTON_LEFT:
		get_viewport().set_input_as_handled()
		return
	if mb.button_index == MOUSE_BUTTON_RIGHT:
		apply_player_command()
		get_viewport().set_input_as_handled()


func apply_player_command() -> void:
	if not visible or EchoChamber.in_battle:
		return
	if not GameState.keeper_selected:
		GameState.status_message.emit(ContentStrings.get_text("keeper_required"))
		return
	var keepers: Array[Node] = get_tree().get_nodes_in_group("keeper")
	if keepers.is_empty():
		return
	var k: Keeper = keepers[0] as Keeper
	if k:
		k.move_to(global_position + ENTRY_OFFSET, self)


func on_interact(_keeper: Node) -> void:
	if not visible:
		return
	GameState.status_message.emit(ContentStrings.get_text("adventure_promised"))
