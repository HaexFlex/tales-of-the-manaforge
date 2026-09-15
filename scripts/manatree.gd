extends Area2D
class_name Manatree
## 5-stage Manatree; textures/size/hitbox from manatree_meta.json. Needs-only (SYSTEMS v0.2.0).

signal fruit_menu_requested
signal care_menu_requested

@onready var sprite: Sprite2D = $Sprite
@onready var label: Label = $Label
@onready var fruit_hint: Label = $FruitHint

var _watering: bool = false
## stage_id -> {file, size:[w,h], anchor, ...} from assets/art/manatree/manatree_meta.json
var _meta_stages: Dictionary = {}

const META_PATH: String = "res://assets/art/manatree/manatree_meta.json"
const STAGE_TEXTURES: Dictionary = {
	&"sapling": "res://assets/art/manatree/manatree_sapling.png",
	&"young": "res://assets/art/manatree/manatree_young.png",
	&"mature": "res://assets/art/manatree/manatree_mature.png",
	&"elder": "res://assets/art/manatree/manatree_elder.png",
	&"ancient": "res://assets/art/manatree/manatree_ancient.png",
}


func _ready() -> void:
	_load_meta()
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.centered = false
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fruit_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	input_event.connect(_on_input_event)
	GameState.stage_changed.connect(_on_stage_changed)
	GameState.fruit_ready_changed.connect(_on_fruit_changed)
	GameState.needs_changed.connect(_refresh_label)
	_refresh_visual()
	_on_fruit_changed(GameState.fruit_ready)
	add_to_group("manatree")
	add_to_group("interactable")


func _load_meta() -> void:
	_meta_stages.clear()
	var file := FileAccess.open(META_PATH, FileAccess.READ)
	if file == null:
		push_warning("Manatree: missing manatree_meta.json — falling back to stage table sizes")
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	var stages: Variant = (parsed as Dictionary).get("stages", [])
	if typeof(stages) != TYPE_ARRAY:
		return
	for entry: Variant in stages:
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var d: Dictionary = entry
		var sid: String = str(d.get("stage_id", ""))
		if sid != "":
			_meta_stages[sid] = d


func _stage_size(stage: StringName) -> Vector2:
	var meta: Variant = _meta_stages.get(String(stage), {})
	if typeof(meta) == TYPE_DICTIONARY:
		var size_v: Variant = (meta as Dictionary).get("size", null)
		if typeof(size_v) == TYPE_ARRAY and (size_v as Array).size() >= 2:
			var arr: Array = size_v
			return Vector2(float(arr[0]), float(arr[1]))
	var def: Dictionary = GameState.get_stage_def(stage)
	var size_v2: Variant = def.get("size", [96, 160])
	if typeof(size_v2) == TYPE_ARRAY and (size_v2 as Array).size() >= 2:
		var arr2: Array = size_v2
		return Vector2(float(arr2[0]), float(arr2[1]))
	return Vector2(96, 160)


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
	## Fruit ready or pending Ascend → Fruit/Blessings/Ascend panel. Else care (Water + Pay).
	if GameState.fruit_ready or GameState.fruit_harvested_pending_ascend:
		fruit_menu_requested.emit()
		return
	care_menu_requested.emit()


func set_watering(active: bool) -> void:
	_watering = active
	if active:
		label.modulate = Color(0.85, 0.95, 1.1, 1.0)
	else:
		label.modulate = Color.WHITE
	_refresh_label()


func do_water() -> void:
	## Start / continue water channel via Keeper (income only).
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


func do_pay_stage() -> String:
	## Spend needs to advance. Audio stage-up fires via GameAudio on stage_changed.
	var result: String = GameState.try_pay_stage()
	match result:
		"ok":
			pass
		"cant_afford":
			GameAudio.play_tree_deny()
		"ancient":
			if GameState.fruit_ready or GameState.fruit_harvested_pending_ascend:
				fruit_menu_requested.emit()
	_refresh_visual()
	return result


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


func _refresh_label() -> void:
	var suffix: String = ""
	if _watering:
		suffix = "\n" + ContentStrings.get_text("tree_water_channel_hud")
	var stage_name: String = str(GameState.get_stage_def().get("display_name", GameState.stage_id))
	if GameState.stage_id == &"ancient":
		var note: String = ""
		if GameState.fruit_ready:
			note = "\n" + ContentStrings.get_text("tree_at_ancient_idle")
		label.text = "%s%s%s" % [stage_name, note, suffix]
	else:
		label.text = "%s%s" % [stage_name, suffix]


func _refresh_visual() -> void:
	var path: String = str(STAGE_TEXTURES.get(GameState.stage_id, STAGE_TEXTURES[&"sapling"]))
	# Prefer meta file name when present.
	var meta: Variant = _meta_stages.get(String(GameState.stage_id), {})
	if typeof(meta) == TYPE_DICTIONARY:
		var fname: String = str((meta as Dictionary).get("file", ""))
		if fname != "":
			path = "res://assets/art/manatree/%s" % fname
	var tex: Texture2D = load(path) as Texture2D
	sprite.texture = tex
	var sz: Vector2 = _stage_size(GameState.stage_id)
	var w: float = sz.x
	var h: float = sz.y
	# base_center anchor: feet at node origin.
	sprite.offset = Vector2(-w * 0.5, -h)
	var cs: CollisionShape2D = $CollisionShape2D
	if cs and cs.shape is RectangleShape2D:
		# Full sprite hitbox — Ancient 512×640 must not be cropped.
		var rect_shape: RectangleShape2D = cs.shape as RectangleShape2D
		rect_shape.size = Vector2(w, h)
		cs.position = Vector2(0, -h * 0.5)
	_refresh_label()
	label.position = Vector2(-80, -h - 36)
	fruit_hint.position = Vector2(-140, 8)
