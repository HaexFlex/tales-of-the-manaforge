extends Area2D
class_name Gatherable
## One of three harvest channels (tree→wood, stone→stone, berry→food). Hold/channel @ 1/sec.

@export var resource_id: StringName = &"wood"
@export var display_name: String = "Wood"
@export var stub_color: Color = Color("8d6e63")
@export var node_key: String = "wood"

@onready var sprite: Sprite2D = $Sprite
@onready var label: Label = $Label

var _channeling: bool = false
const BODY_WIDTH: float = 64.0

const HARVEST_TEXTURES: Dictionary = {
	"wood": "res://assets/art/props/harvest_tree.png",
	"stone": "res://assets/art/props/harvest_stone.png",
	"food": "res://assets/art/props/harvest_berry.png",
}
const HARVEST_HEIGHT: Dictionary = {
	"wood": 80.0,
	"stone": 64.0,
	"food": 64.0,
}


const HARVEST_SCALE: Dictionary = {
	"wood": 1.0,
	"stone": 2.0,
	"food": 1.0,
}


func _ready() -> void:
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.centered = false
	var path: String = str(HARVEST_TEXTURES.get(node_key, HARVEST_TEXTURES["wood"]))
	sprite.texture = load(path) as Texture2D
	var scale_v: float = float(HARVEST_SCALE.get(node_key, 1.0))
	var frame := Vector2(BODY_WIDTH, float(HARVEST_HEIGHT.get(node_key, 64.0)))
	if sprite.texture:
		frame = Vector2(float(sprite.texture.get_width()), float(sprite.texture.get_height()))
	sprite.scale = Vector2(scale_v, scale_v)
	sprite.offset = Vector2(-frame.x * 0.5, -frame.y)
	var vis := frame * scale_v
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.position = Vector2(-48, -vis.y - 20.0)
	label.text = ContentStrings.get_text("node_%s_prompt" % node_key)
	input_event.connect(_on_input_event)
	GameState.selection_changed.connect(_refresh_prompt)
	add_to_group("gatherable")
	add_to_group("interactable")
	add_to_group("harvest_node")
	y_sort_enabled = true
	var cs: CollisionShape2D = $CollisionShape2D
	if cs and cs.shape is RectangleShape2D:
		# Full sprite footprint (not just feet box) so canopy/upper clicks count.
		(cs.shape as RectangleShape2D).size = vis
		cs.position = Vector2(0, -vis.y * 0.5)


func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event
		if not mb.pressed:
			return
		if mb.button_index == MOUSE_BUTTON_LEFT:
			# LMB on a node is not empty ground — swallow so Main does not deselect.
			get_viewport().set_input_as_handled()
			return
		if mb.button_index == MOUSE_BUTTON_RIGHT:
			apply_player_command()
			get_viewport().set_input_as_handled()


func apply_player_command() -> void:
	## RMB: wisp assign (no Keeper gate) OR Keeper walks + harvest channel.
	if GameState.selected_wisp_id >= 0:
		var node_id: String = GameState.node_id_for_resource(resource_id)
		var result: String = GameState.try_assign_wisp(GameState.selected_wisp_id, node_id)
		GameState.toast_wisp_assign(result, node_id)
		return
	if not GameState.keeper_selected:
		GameState.status_message.emit(ContentStrings.get_text("keeper_required_harvest"))
		return
	var keepers: Array[Node] = get_tree().get_nodes_in_group("keeper")
	if keepers.is_empty():
		return
	var k: Keeper = keepers[0] as Keeper
	if k:
		k.move_to(global_position, self)


func on_interact(keeper: Node) -> void:
	var k: Keeper = keeper as Keeper
	if k == null:
		return
	k.start_harvest_channel(self)


func set_channeling(active: bool) -> void:
	_channeling = active
	if active:
		modulate = Color(1.05, 1.1, 0.95, 1.0)
	else:
		modulate = Color.WHITE
	_refresh_prompt()


func _refresh_prompt() -> void:
	if label == null:
		return
	if _channeling:
		label.text = ContentStrings.get_text("node_%s_busy" % node_key)
		return
	if GameState.selected_wisp_id >= 0:
		label.text = _wisp_assign_prompt()
		return
	var prompt: String = ContentStrings.get_text("node_%s_prompt" % node_key)
	if Backpack.owns_tool_for_resource(resource_id):
		prompt = "%s\n%s" % [prompt, _tool_owned_hint()]
	label.text = prompt


func _tool_owned_hint() -> String:
	match resource_id:
		&"wood":
			return ContentStrings.get_text("tool_wood_hint")
		&"stone":
			return ContentStrings.get_text("tool_stone_hint")
		&"food":
			return ContentStrings.get_text("tool_food_hint")
		_:
			return ContentStrings.get_text("tool_owned_hint")


func _wisp_assign_prompt() -> String:
	match node_key:
		"wood":
			return ContentStrings.get_text("wisp_assign_to_tree")
		"stone":
			return ContentStrings.get_text("wisp_assign_to_stone")
		"food":
			return ContentStrings.get_text("wisp_assign_to_berry")
		_:
			return ContentStrings.get_text("wisp_assign_prompt")


func on_channel_cancel() -> void:
	set_channeling(false)
	GameState.status_message.emit(ContentStrings.get_text("node_%s_cancel" % node_key))


func on_harvest_pulse() -> int:
	var grant: int = GameState.apply_harvest_pulse(resource_id)
	GameAudio.play_gather(resource_id)
	var item: String = ContentStrings.get_text("hud_%s" % String(resource_id))
	GameState.status_message.emit(
		ContentStrings.get_text("harvest_pulse_hud", {"amount": grant, "item": item})
	)
	return grant
