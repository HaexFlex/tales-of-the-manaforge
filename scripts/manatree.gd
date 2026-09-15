extends Area2D
class_name Manatree
## 5-stage Manatree; water channel (shards+essence+growth) + Offer care; ancient door baked in.

signal fruit_menu_requested
signal care_menu_requested

@onready var sprite: Sprite2D = $Sprite
@onready var label: Label = $Label
@onready var fruit_hint: Label = $FruitHint

var _watering: bool = false

const STAGE_TEXTURES: Dictionary = {
	&"sapling": "res://assets/art/manatree/manatree_sapling.png",
	&"young": "res://assets/art/manatree/manatree_young.png",
	&"mature": "res://assets/art/manatree/manatree_mature.png",
	&"elder": "res://assets/art/manatree/manatree_elder.png",
	&"ancient": "res://assets/art/manatree/manatree_ancient.png",
}


func _ready() -> void:
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.centered = false
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fruit_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
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
			get_viewport().set_input_as_handled()


func _request_keeper_interact() -> void:
	var keepers: Array[Node] = get_tree().get_nodes_in_group("keeper")
	if keepers.is_empty():
		return
	var k: Keeper = keepers[0] as Keeper
	if k:
		k.move_to(global_position + Vector2(0, 40), self)


func on_interact(_keeper: Node) -> void:
	## Pending ascend → Fruit/Ascend panel. Otherwise care menu (Water channel works at Ancient).
	if GameState.fruit_harvested_pending_ascend:
		fruit_menu_requested.emit()
		return
	care_menu_requested.emit()


func set_watering(active: bool) -> void:
	_watering = active
	if active:
		label.modulate = Color(0.85, 0.95, 1.1, 1.0)
	else:
		label.modulate = Color.WHITE
	_refresh_visual()


func do_water() -> void:
	## Start / continue water channel via Keeper (Haex hold/channel).
	var keepers: Array[Node] = get_tree().get_nodes_in_group("keeper")
	if keepers.is_empty():
		return
	var k: Keeper = keepers[0] as Keeper
	if k == null:
		return
	if GameState.fruit_harvested_pending_ascend:
		fruit_menu_requested.emit()
		return
	k.start_water_channel(self)
	if GameState.stage_id == &"ancient":
		GameState.status_message.emit(ContentStrings.get_text("tree_water_ancient_note"))


func do_offer(resource_id: StringName) -> void:
	var result: String = GameState.try_offer(resource_id)
	var item: String = String(resource_id).capitalize()
	if resource_id == &"manashards":
		item = "Manashards"
	match result:
		"ok":
			var ok_key: String = "tree_offer_ok_%s" % String(resource_id)
			GameState.status_message.emit(ContentStrings.get_text(ok_key))
			GameAudio.play_tree_offer()
		"no_res":
			GameState.status_message.emit(ContentStrings.get_text("tree_offer_deny", {"item": item}))
			GameAudio.play_tree_deny()
		"cooldown":
			GameState.status_message.emit(ContentStrings.get_text("tree_offer_cooldown"))
			GameAudio.play_tree_deny()
		"ancient":
			GameState.status_message.emit(ContentStrings.get_text("tree_offer_ancient_block"))
			if GameState.fruit_ready or GameState.fruit_harvested_pending_ascend:
				fruit_menu_requested.emit()
	_refresh_visual()


func refresh_after_care() -> void:
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
	var suffix: String = ""
	if _watering:
		suffix = "\n" + ContentStrings.get_text("tree_water_channel_hud")
	if GameState.stage_id == &"ancient":
		label.text = "%s\n%s%s" % [
			str(GameState.get_stage_def().get("display_name", "Ancient")),
			ContentStrings.get_text("tree_at_ancient_idle") if GameState.fruit_ready else "",
			suffix,
		]
	else:
		label.text = "%s\n%s %d/%d%s" % [
			str(GameState.get_stage_def().get("display_name", GameState.stage_id)),
			ContentStrings.get_text("tree_growth_hud"),
			g,
			req,
			suffix,
		]


func _refresh_visual() -> void:
	var def: Dictionary = GameState.get_stage_def()
	var path: String = str(STAGE_TEXTURES.get(GameState.stage_id, STAGE_TEXTURES[&"sapling"]))
	var tex: Texture2D = load(path) as Texture2D
	sprite.texture = tex
	var size_v: Variant = def.get("size", [64, 128])
	var w: float = 64.0
	var h: float = 128.0
	if typeof(size_v) == TYPE_ARRAY and (size_v as Array).size() >= 2:
		var arr: Array = size_v
		w = float(arr[0])
		h = float(arr[1])
	sprite.offset = Vector2(-w * 0.5, -h)
	var cs: CollisionShape2D = $CollisionShape2D
	if cs and cs.shape is RectangleShape2D:
		# Generous rect covering the full drawn landmark (canopy + trunk).
		var rect_shape: RectangleShape2D = cs.shape as RectangleShape2D
		rect_shape.size = Vector2(w, h)
		cs.position = Vector2(0, -h * 0.5)
	_on_growth(GameState.growth, GameState.get_growth_required_for_next())
	label.position = Vector2(-80, -h - 36)
	fruit_hint.position = Vector2(-140, 8)
