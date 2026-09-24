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
var _anim_frames: int = 1
var _anim_fps: float = 7.0
var _anim_time: float = 0.0

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
	GameState.selection_changed.connect(_refresh_label)
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


## D7 visual scale only — multiplies the stage canvas. Gather and costs stay on the stage row.
func visual_scale_for(stage: StringName) -> float:
	var def: Dictionary = GameState.get_stage_def(stage)
	if def.has("visual_scale"):
		return float(def.get("visual_scale", 1.0))
	return 1.0


func _stage_size(stage: StringName) -> Vector2:
	var meta: Variant = _meta_stages.get(String(stage), {})
	if typeof(meta) == TYPE_DICTIONARY:
		var size_v: Variant = (meta as Dictionary).get("size", null)
		if typeof(size_v) == TYPE_ARRAY and (size_v as Array).size() >= 2:
			var arr: Array = size_v
			return Vector2(float(arr[0]), float(arr[1]))
	var def: Dictionary = GameState.get_stage_def(stage)
	var size_v2: Variant = def.get("size", [128, 192])
	if typeof(size_v2) == TYPE_ARRAY and (size_v2 as Array).size() >= 2:
		var arr2: Array = size_v2
		return Vector2(float(arr2[0]), float(arr2[1]))
	return Vector2(128, 192)


func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event
		if not mb.pressed:
			return
		if mb.button_index == MOUSE_BUTTON_LEFT:
			# LMB on the tree is not empty ground — swallow so Main does not deselect.
			get_viewport().set_input_as_handled()
			return
		if mb.button_index == MOUSE_BUTTON_RIGHT:
			apply_player_command()
			get_viewport().set_input_as_handled()


func apply_player_command() -> void:
	## RMB: wisp assign to Manatree (manashards pulse) OR Keeper walks + care/water as today.
	if GameState.selected_wisp_id >= 0:
		var node_id: String = GameState.NODE_ID_MANATREE
		var result: String = GameState.try_assign_wisp(GameState.selected_wisp_id, node_id)
		GameState.toast_wisp_assign(result, node_id)
		return
	if not GameState.keeper_selected:
		GameState.status_message.emit(ContentStrings.get_text("keeper_required_tree"))
		return
	var keepers: Array[Node] = get_tree().get_nodes_in_group("keeper")
	if keepers.is_empty():
		return
	var k: Keeper = keepers[0] as Keeper
	if k:
		k.move_to(global_position + Vector2(0, 40), self)


func on_interact(_keeper: Node) -> void:
	## Pending Ascend → paused shop. Fruit ready (uncommitted) → care with Water + Harvest CTA.
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
		GameState.status_message.emit("%s\n%s" % [
			ContentStrings.get_text("tree_water_ancient_note"),
			ContentStrings.get_text("tree_water_ancient_ok"),
		])


func do_pay_stage() -> String:
	## Spend needs to advance. Audio stage-up fires via GameAudio on stage_changed.
	var result: String = GameState.try_pay_stage()
	match result:
		"ok":
			pass
		"cant_afford":
			GameAudio.play_tree_deny()
		"ancient":
			if GameState.fruit_harvested_pending_ascend:
				fruit_menu_requested.emit()
			elif GameState.fruit_ready:
				care_menu_requested.emit()
	_refresh_visual()
	return result


func refresh_after_care() -> void:
	_refresh_visual()


func _on_stage_changed(_id: StringName) -> void:
	_refresh_visual()


func _process(delta: float) -> void:
	if _anim_frames <= 1 or sprite == null:
		return
	_anim_time += delta
	var frame: int = int(_anim_time * _anim_fps) % _anim_frames
	if sprite.frame != frame:
		sprite.frame = frame


func _on_fruit_changed(ready: bool) -> void:
	fruit_hint.visible = ready or GameState.fruit_harvested_pending_ascend
	if ready:
		fruit_hint.text = ContentStrings.get_text("fruit_ready_prompt")
	elif GameState.fruit_harvested_pending_ascend:
		fruit_hint.text = ContentStrings.get_text("ascension_paused_hint")
	else:
		fruit_hint.text = ""


func _refresh_label() -> void:
	var suffix: String = ""
	if _watering:
		suffix = "\n" + ContentStrings.get_text("tree_water_channel_hud")
		if Backpack.owns_watering_can():
			suffix += "\n" + ContentStrings.get_text("tool_water_hint")
	if GameState.selected_wisp_id >= 0:
		label.text = "%s%s" % [ContentStrings.get_text("wisp_assign_to_manatree"), suffix]
		return
	var stage_name: String = str(GameState.get_stage_def().get("display_name", GameState.stage_id))
	if GameState.stage_id == &"ancient":
		var note: String = ""
		if GameState.fruit_ready:
			note = "\n" + ContentStrings.get_text("tree_at_ancient_idle")
		label.text = "%s%s%s" % [stage_name, note, suffix]
	else:
		label.text = "%s%s" % [stage_name, suffix]


func _stage_meta() -> Dictionary:
	var meta: Variant = _meta_stages.get(String(GameState.stage_id), {})
	if typeof(meta) == TYPE_DICTIONARY:
		return meta
	return {}


func _display_scale(stage: StringName) -> float:
	var meta: Dictionary = _stage_meta()
	if stage == GameState.stage_id and meta.has("display_scale"):
		return float(meta.get("display_scale", 1.0))
	return visual_scale_for(stage)


func _refresh_visual() -> void:
	var path: String = str(STAGE_TEXTURES.get(GameState.stage_id, STAGE_TEXTURES[&"sapling"]))
	var meta: Dictionary = _stage_meta()
	var fname: String = str(meta.get("file", ""))
	if fname != "":
		path = "res://assets/art/manatree/%s" % fname
	var tex: Texture2D = load(path) as Texture2D
	var frames: int = maxi(1, int(meta.get("frames", 1)))
	_anim_frames = frames
	_anim_fps = float(meta.get("fps", 7.0))
	if _anim_fps < 1.0:
		_anim_fps = 7.0
	sprite.hframes = frames
	sprite.vframes = 1
	sprite.texture = tex
	sprite.frame = 0
	_anim_time = 0.0
	var sz: Vector2 = _stage_size(GameState.stage_id)
	var scale_v: float = _display_scale(GameState.stage_id)
	sprite.scale = Vector2(scale_v, scale_v)
	var w: float = sz.x
	var h: float = sz.y
	# base_center anchor: feet at node origin. Offset is in frame pixels; scale grows the crown up.
	sprite.offset = Vector2(-w * 0.5, -h)
	var vis_h: float = h * scale_v
	var vis_w: float = w * scale_v
	var cs: CollisionShape2D = $CollisionShape2D
	if cs and cs.shape is RectangleShape2D:
		# Hitbox follows the visual scale so the grown canopy stays clickable.
		var rect_shape: RectangleShape2D = cs.shape as RectangleShape2D
		rect_shape.size = Vector2(vis_w, vis_h)
		cs.position = Vector2(0, -vis_h * 0.5)
	_refresh_label()
	label.position = Vector2(-80, -vis_h - 36)
	fruit_hint.position = Vector2(-140, 8)
