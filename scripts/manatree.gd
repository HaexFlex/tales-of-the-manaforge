extends Area2D
class_name Manatree
## 5-stage Manatree; watering spends Food; ancient Fruit + non-interactive door stub.

signal fruit_menu_requested

@onready var body_rect: ColorRect = $BodyRect
@onready var door_rect: ColorRect = $DoorRect
@onready var label: Label = $Label
@onready var fruit_hint: Label = $FruitHint


func _ready() -> void:
	body_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	door_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fruit_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	door_rect.visible = false
	input_event.connect(_on_input_event)
	GameState.stage_changed.connect(_on_stage_changed)
	GameState.fruit_ready_changed.connect(_on_fruit_changed)
	GameState.growth_changed.connect(_on_growth)
	_refresh_visual()
	_on_fruit_changed(GameState.fruit_ready)
	add_to_group("manatree")
	add_to_group("interactable")


func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			_request_keeper_interact()


func _request_keeper_interact() -> void:
	var keepers: Array[Node] = get_tree().get_nodes_in_group("keeper")
	if keepers.is_empty():
		return
	var k: Keeper = keepers[0] as Keeper
	if k:
		k.move_to(global_position + Vector2(0, 40), self)


func on_interact(_keeper: Node) -> void:
	if GameState.fruit_harvested_pending_ascend or GameState.stage_id == &"ancient":
		if GameState.fruit_ready or GameState.fruit_harvested_pending_ascend:
			fruit_menu_requested.emit()
			return
	var stage_before: StringName = GameState.stage_id
	var result: String = GameState.try_water()
	match result:
		"ok":
			GameState.status_message.emit(ContentStrings.get_text("tree_water_ok"))
			# Prefer stage sting over water SFX on the same advance frame.
			if GameState.stage_id == stage_before:
				GameAudio.play_tree_water_ok()
		"no_food":
			GameState.status_message.emit(ContentStrings.get_text("tree_water_no_food"))
			GameAudio.play_tree_deny()
		"cooldown":
			GameState.status_message.emit(ContentStrings.get_text("tree_water_cooldown"))
			GameAudio.play_tree_deny()
		"ancient":
			GameState.status_message.emit(ContentStrings.get_text("tree_at_ancient_idle"))
			fruit_menu_requested.emit()
	_refresh_visual()


func _on_stage_changed(_id: StringName) -> void:
	_refresh_visual()


func _on_fruit_changed(ready: bool) -> void:
	fruit_hint.visible = ready or GameState.fruit_harvested_pending_ascend
	if ready:
		fruit_hint.text = ContentStrings.get_text("fruit_ready_prompt")
	elif GameState.fruit_harvested_pending_ascend:
		fruit_hint.text = ContentStrings.get_text("ascend_prompt")
	else:
		fruit_hint.text = ""


func _on_growth(g: int, req: int) -> void:
	if GameState.stage_id == &"ancient":
		label.text = "%s\n%s" % [
			str(GameState.get_stage_def().get("display_name", "Ancient")),
			ContentStrings.get_text("tree_at_ancient_idle") if GameState.fruit_ready else ""
		]
	else:
		label.text = "%s\n%s %d/%d" % [
			str(GameState.get_stage_def().get("display_name", GameState.stage_id)),
			ContentStrings.get_text("tree_growth_hud"),
			g,
			req,
		]


func _refresh_visual() -> void:
	var def: Dictionary = GameState.get_stage_def()
	body_rect.color = Color(str(def.get("color", "#7ec850")))
	var size_v: Variant = def.get("size", [64, 128])
	if typeof(size_v) == TYPE_ARRAY and (size_v as Array).size() >= 2:
		var arr: Array = size_v
		# Feet/base-center pivot (visual bible).
		body_rect.size = Vector2(float(arr[0]), float(arr[1]))
		body_rect.position = Vector2(-body_rect.size.x * 0.5, -body_rect.size.y)
	var is_ancient: bool = GameState.stage_id == &"ancient"
	# Door = later Forge art only; non-interactive in v0.1.
	door_rect.visible = is_ancient
	if is_ancient:
		door_rect.size = Vector2(40, 56)
		door_rect.position = Vector2(-20, -56)
		door_rect.color = Color(0.25, 0.15, 0.1, 1)
	var cs: CollisionShape2D = $CollisionShape2D
	if cs and cs.shape is RectangleShape2D:
		var rect_shape: RectangleShape2D = cs.shape as RectangleShape2D
		rect_shape.size = Vector2(maxi(64, int(body_rect.size.x * 0.6)), 64)
		cs.position = Vector2(0, -32)
	_on_growth(GameState.growth, GameState.get_growth_required_for_next())
	label.position = Vector2(-80, body_rect.position.y - 36)
	fruit_hint.position = Vector2(-140, 8)
