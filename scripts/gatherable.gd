@tool
extends Area2D
class_name Gatherable
## One of three harvest channels (tree→wood, stone→stone, berry→food). Hold/channel @ 1/sec.

@export var resource_id: StringName = &"wood"
@export var display_name: String = "Wood"
@export var stub_color: Color = Color("8d6e63")
@export var node_key: String = "wood":
	set(value):
		node_key = value
		if is_node_ready():
			_apply_art()
## On-screen height in pixels. 0 keeps the small harvest box.
## The sprite stays bottom-centered on this node (feet at the origin). Art swaps the texture and edits this number.
@export var stand_height: float = 0.0:
	set(value):
		stand_height = maxf(0.0, value)
		if is_node_ready():
			_apply_art()
## Walk-blocking trunk, as a fraction of the standing sprite. Click area stays the full sprite.
@export_range(0.05, 0.45, 0.01) var trunk_height_ratio: float = 0.14:
	set(value):
		trunk_height_ratio = clampf(value, 0.05, 0.45)
		if is_node_ready():
			_apply_art()
## Wood trunk on the 288-wide canvas runs about x 105–182. 0.26 of that width.
@export_range(0.08, 0.6, 0.01) var trunk_width_ratio: float = 0.26:
	set(value):
		trunk_width_ratio = clampf(value, 0.08, 0.6)
		if is_node_ready():
			_apply_art()
## Click box in world pixels. Zero uses the full sprite. The tall tree uses 120×240, centered on (0, -120).
@export var click_size: Vector2 = Vector2.ZERO:
	set(value):
		click_size = value
		if is_node_ready():
			_apply_art()
## Ready for a depleted swap. Nothing in play turns this on yet.
@export var spent_texture: Texture2D

@onready var sprite: Sprite2D = $Sprite
@onready var label: Label = $Label

var _channeling: bool = false
var _hovered: bool = false
const BODY_WIDTH: float = 64.0

const HARVEST_TEXTURES: Dictionary = {
	"wood": "res://assets/art/props/harvest_tree.png",
	"stone": "res://assets/art/props/native/harvest_stone.png",
	"food": "res://assets/art/props/native/berry_harvest_node.png",
}
const HARVEST_HEIGHT: Dictionary = {
	"wood": 80.0,
	"stone": 64.0,
	"food": 64.0,
}


const HARVEST_SCALE: Dictionary = {
	"wood": 1.0,
	"stone": 1.0,
	"food": 1.0,
}


func _ready() -> void:
	_apply_art()
	if Engine.is_editor_hint():
		if label:
			label.mouse_filter = Control.MOUSE_FILTER_IGNORE
			label.visible = true
		return
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.text = ContentStrings.get_text("node_%s_prompt" % node_key)
	input_event.connect(_on_input_event)
	mouse_entered.connect(_on_hover.bind(true))
	mouse_exited.connect(_on_hover.bind(false))
	GameState.selection_changed.connect(_refresh_prompt)
	label.visible = false
	add_to_group("gatherable")
	add_to_group("interactable")
	add_to_group("harvest_node")
	y_sort_enabled = true


func _apply_art() -> void:
	if sprite == null:
		return
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.centered = false
	var path: String = str(HARVEST_TEXTURES.get(node_key, HARVEST_TEXTURES["wood"]))
	sprite.texture = load(path) as Texture2D
	var box := Vector2(BODY_WIDTH, float(HARVEST_HEIGHT.get(node_key, 64.0)))
	var scale_v: float = float(HARVEST_SCALE.get(node_key, 1.0))
	var frame := box
	if sprite.texture:
		frame = Vector2(float(sprite.texture.get_width()), float(sprite.texture.get_height()))
	## Berry art fits the 64 food box, then doubles in play. Tree and stone keep their scales.
	## stand_height overrides that and sizes the sprite to a fixed on-screen height.
	if stand_height > 0.0 and frame.y > 0.0:
		scale_v = stand_height / frame.y
	elif node_key == "food" and frame.x > 0.0 and frame.y > 0.0:
		scale_v = minf(box.x / frame.x, box.y / frame.y) * 2.0
	sprite.scale = Vector2(scale_v, scale_v)
	sprite.offset = Vector2(-frame.x * 0.5, -frame.y)
	var vis := frame * scale_v
	if label:
		label.position = Vector2(-48, -vis.y - 20.0)
		if Engine.is_editor_hint():
			label.text = display_name if display_name != "" else node_key
	var cs: CollisionShape2D = get_node_or_null("CollisionShape2D") as CollisionShape2D
	if cs and cs.shape is RectangleShape2D:
		var rect := (cs.shape as RectangleShape2D).duplicate() as RectangleShape2D
		var click := vis
		var click_pos := Vector2(0, -vis.y * 0.5)
		if click_size.x > 1.0 and click_size.y > 1.0:
			click = click_size
			click_pos = Vector2(0, -click_size.y * 0.5)
		rect.size = click
		cs.shape = rect
		cs.position = click_pos
	_apply_trunk(vis)


func _apply_trunk(vis: Vector2) -> void:
	var trunk: StaticBody2D = get_node_or_null("Trunk") as StaticBody2D
	var shape_node: CollisionShape2D = get_node_or_null("Trunk/CollisionShape2D") as CollisionShape2D
	if trunk == null or shape_node == null:
		return
	trunk.input_pickable = false
	var use_trunk: bool = stand_height > 0.0 and vis.y > 1.0
	shape_node.disabled = not use_trunk
	if not use_trunk:
		return
	var trunk_size := Vector2(
		maxf(18.0, vis.x * trunk_width_ratio),
		maxf(12.0, vis.y * trunk_height_ratio)
	)
	var rect := RectangleShape2D.new()
	if shape_node.shape is RectangleShape2D:
		rect = (shape_node.shape as RectangleShape2D).duplicate() as RectangleShape2D
	rect.size = trunk_size
	shape_node.shape = rect
	shape_node.position = Vector2(0, -trunk_size.y * 0.5)


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


func approach_point() -> Vector2:
	## Feet stay on this node. The trunk collider sits on those feet (it does not
	## hang south of y=0), so a wider trunk does not move this stop. The Keeper
	## halts just south of it — close enough to channel, clear of the body shape.
	if stand_height <= 0.0:
		return global_position
	return global_position + Vector2(0, 72)


func apply_player_command() -> void:
	## RMB: wisp assign (no Keeper gate) OR Keeper walks + harvest channel.
	if not GameState.selected_wisp_list().is_empty():
		var node_id: String = GameState.node_id_for_resource(resource_id)
		var result: String = GameState.command_selected_wisps(node_id)
		GameState.toast_wisp_assign(result, node_id)
		if GameState.keeper_selected:
			var keepers_both: Array[Node] = get_tree().get_nodes_in_group("keeper")
			if not keepers_both.is_empty() and keepers_both[0] is Keeper:
				(keepers_both[0] as Keeper).move_to(approach_point(), self)
		return
	if not GameState.keeper_selected:
		GameState.status_message.emit(ContentStrings.get_text("keeper_required_harvest"))
		return
	var keepers: Array[Node] = get_tree().get_nodes_in_group("keeper")
	if keepers.is_empty():
		return
	var k: Keeper = keepers[0] as Keeper
	if k:
		k.move_to(approach_point(), self)


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
		_apply_label_visibility()
		return
	if GameState.selected_wisp_id >= 0:
		label.text = _wisp_assign_prompt()
		_apply_label_visibility()
		return
	var prompt: String = ContentStrings.get_text("node_%s_prompt" % node_key)
	if Backpack.owns_tool_for_resource(resource_id):
		prompt = "%s\n%s" % [prompt, _tool_owned_hint()]
	label.text = prompt
	_apply_label_visibility()


func _on_hover(inside: bool) -> void:
	_hovered = inside
	_apply_label_visibility()


func _label_should_show() -> bool:
	if _hovered or _channeling:
		return true
	if GameState.selected_wisp_id < 0:
		return false
	var assigned: String = GameState.get_wisp_assignment(GameState.selected_wisp_id)
	return assigned != "" and assigned == GameState.node_id_for_resource(resource_id)


func _apply_label_visibility() -> void:
	if label:
		label.visible = _label_should_show()


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
