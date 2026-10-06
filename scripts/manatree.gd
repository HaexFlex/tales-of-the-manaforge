@tool
extends Area2D
class_name Manatree
## 5-stage Manatree; textures/size/hitbox from manatree_meta.json. Needs-only (SYSTEMS v0.2.0).
## preview_stage is editor-only so the canopy is visible before a save loads.

@export_enum("sapling", "young", "mature", "elder", "ancient") var preview_stage: String = "sapling":
	set(value):
		preview_stage = value if value != "" else "sapling"
		if Engine.is_editor_hint() and is_inside_tree():
			_load_meta()
			_refresh_visual()

signal fruit_menu_requested
signal care_menu_requested

@onready var sprite: Sprite2D = $Sprite
@onready var label: Label = $Label
@onready var fruit_hint: Label = $FruitHint

var _watering: bool = false
var _hovered: bool = false
## stage_id -> {file, size:[w,h], anchor, ...} from assets/art/manatree/native/manatree_meta.json
var _meta_stages: Dictionary = {}
var _anim_frames: int = 1
var _anim_fps: float = 7.0
var _anim_time: float = 0.0

const META_PATH: String = "res://assets/art/manatree/native/manatree_meta.json"
const STAGE_TEXTURES: Dictionary = {
	&"sapling": "res://assets/art/manatree/native/manatree_sapling.png",
	&"young": "res://assets/art/manatree/native/manatree_young.png",
	&"mature": "res://assets/art/manatree/native/manatree_mature.png",
	&"elder": "res://assets/art/manatree/native/manatree_elder.png",
	&"ancient": "res://assets/art/manatree/native/manatree_ancient.png",
}


func _ready() -> void:
	_load_meta()
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.centered = false
	if Engine.is_editor_hint():
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if fruit_hint:
			fruit_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_refresh_visual()
		return
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.visible = false
	fruit_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fruit_hint.visible = false
	input_event.connect(_on_input_event)
	mouse_entered.connect(_on_hover.bind(true))
	mouse_exited.connect(_on_hover.bind(false))
	GameState.stage_changed.connect(_on_stage_changed)
	GameState.fruit_ready_changed.connect(_on_fruit_changed)
	GameState.needs_changed.connect(_refresh_label)
	GameState.selection_changed.connect(_refresh_label)
	add_to_group("manatree")
	add_to_group("interactable")
	_ensure_trunk()
	_ensure_door_trigger()
	_ensure_veins()
	_refresh_visual()
	_on_fruit_changed(GameState.fruit_ready)


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
	if Engine.is_editor_hint():
		return Vector2(128, 192)
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
			if _click_is_door():
				_request_door()
			# LMB on the tree is not empty ground — swallow so Main does not deselect.
			get_viewport().set_input_as_handled()
			return
		if mb.button_index == MOUSE_BUTTON_RIGHT:
			apply_player_command()
			get_viewport().set_input_as_handled()


func _click_is_door() -> bool:
	var local: Vector2 = to_local(get_global_mouse_position())
	return absf(local.x) <= DOOR_HALF_W and local.y >= -20.0 and local.y <= 24.0


func _request_door() -> void:
	## One click: the selected hero walks to the sill and the feet trigger enters.
	if has_node("/root/ForgeJobs"):
		ForgeJobs.request_door_walk()


func work_footprint() -> Rect2:
	## Door sill is the node origin at every stage. Watering uses this point, not the grown sprite.
	return Rect2(global_position, Vector2.ZERO)


func apply_player_command() -> void:
	## RMB: wisp assign to Manatree, and the selected hero walks to tend it.
	if not GameState.selected_wisp_list().is_empty():
		var node_id: String = GameState.NODE_ID_MANATREE
		var result: String = GameState.command_selected_wisps(node_id)
		GameState.toast_wisp_assign(result, node_id)
		if GameState.selected_hero_id() != "":
			GameState.command_selected_hero(self, "manatree")
		return
	if GameState.selected_hero_id() == "":
		GameState.status_message.emit(ContentStrings.get_text("keeper_required_tree"))
		return
	GameState.command_selected_hero(self, "manatree")


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
	## Start / continue water channel on the selected hero (income only).
	if GameState.fruit_harvested_pending_ascend:
		fruit_menu_requested.emit()
		return
	var hero: Node = null
	if GameState.selected_hero_id() == "elaia":
		hero = get_tree().get_first_node_in_group("elaia")
	if hero == null:
		var keepers: Array[Node] = get_tree().get_nodes_in_group("keeper")
		if not keepers.is_empty():
			hero = keepers[0]
	if hero == null or not hero.has_method("start_water_channel"):
		return
	hero.call("start_water_channel", self)
	if GameState.stage_id == &"ancient":
		GameState.status_message.emit(ContentStrings.get_text("tree_water_ancient_ok"))


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
	if Engine.is_editor_hint():
		return
	if _anim_frames <= 1 or sprite == null:
		return
	_anim_time += delta
	var frame: int = int(_anim_time * _anim_fps) % _anim_frames
	if sprite.frame != frame:
		sprite.frame = frame


func _on_fruit_changed(ready: bool) -> void:
	if ready:
		fruit_hint.text = ContentStrings.get_text("fruit_ready_prompt")
	elif GameState.fruit_harvested_pending_ascend:
		fruit_hint.text = ContentStrings.get_text("ascension_paused_hint")
	else:
		fruit_hint.text = ""
	_apply_label_visibility()


func _on_hover(inside: bool) -> void:
	_hovered = inside
	_apply_label_visibility()


func _refresh_label() -> void:
	var suffix: String = ""
	if _watering:
		suffix = "\n" + ContentStrings.get_text("tree_water_channel_hud")
		if Backpack.owns_watering_can():
			suffix += "\n" + ContentStrings.get_text("tool_water_hint")
	if GameState.selected_wisp_id >= 0:
		label.text = "%s%s" % [ContentStrings.get_text("wisp_assign_to_manatree"), suffix]
		_apply_label_visibility()
		return
	var stage_name: String = str(GameState.get_stage_def().get("display_name", GameState.stage_id))
	var ascension: String = ContentStrings.get_text("ascend_count_hud", {"count": GameState.ascensions})
	if GameState.stage_id == &"ancient":
		label.text = "%s  |  %s%s" % [stage_name, ascension, suffix]
	else:
		label.text = "%s  |  %s%s" % [stage_name, ascension, suffix]
	_apply_label_visibility()


func _apply_label_visibility() -> void:
	## The name shows on hover only. Watering and wisp text stay in the same label.
	if label:
		label.visible = _hovered
	if fruit_hint:
		fruit_hint.visible = _hovered and fruit_hint.text != ""


func _stage_meta() -> Dictionary:
	var meta: Variant = _meta_stages.get(String(GameState.stage_id), {})
	if typeof(meta) == TYPE_DICTIONARY:
		return meta
	return {}


## Frame-pixel midpoint of the door sill. Measured on frame 0 of each strip:
## the last row where the trunk still bridges the center, above the root split.
func door_floor_px(stage: StringName = &"") -> Vector2:
	var sid: StringName = stage if stage != &"" else GameState.stage_id
	var meta: Dictionary = {}
	var raw: Variant = _meta_stages.get(String(sid), {})
	if typeof(raw) == TYPE_DICTIONARY:
		meta = raw
	var door_v: Variant = meta.get("door_floor", null)
	if typeof(door_v) == TYPE_ARRAY and (door_v as Array).size() >= 2:
		var arr: Array = door_v
		return Vector2(float(arr[0]), float(arr[1]))
	var sz: Vector2 = _stage_size(sid)
	return Vector2(sz.x * 0.5, sz.y)


## Local position of the door-floor midpoint after offset and scale. Zero pins the sill to the node.
func door_anchor_offset() -> Vector2:
	if sprite == null:
		return Vector2(9999, 9999)
	var door: Vector2 = door_floor_px(GameState.stage_id)
	return (sprite.offset + door) * sprite.scale


func _display_scale(stage: StringName) -> float:
	if Engine.is_editor_hint():
		var raw: Variant = _meta_stages.get(String(stage), {})
		if typeof(raw) == TYPE_DICTIONARY and (raw as Dictionary).has("display_scale"):
			return float((raw as Dictionary).get("display_scale", 1.0))
		return 1.0
	var meta: Dictionary = _stage_meta()
	if stage == GameState.stage_id and meta.has("display_scale"):
		return float(meta.get("display_scale", 1.0))
	return visual_scale_for(stage)


func _refresh_visual() -> void:
	var stage: StringName = StringName(preview_stage) if Engine.is_editor_hint() else GameState.stage_id
	var path: String = str(STAGE_TEXTURES.get(stage, STAGE_TEXTURES[&"sapling"]))
	var meta: Dictionary = {}
	var raw_meta: Variant = _meta_stages.get(String(stage), {})
	if typeof(raw_meta) == TYPE_DICTIONARY:
		meta = raw_meta
	if not Engine.is_editor_hint():
		meta = _stage_meta()
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
	var scale_v: float = _display_scale(stage)
	sprite.scale = Vector2(scale_v, scale_v)
	# Door sill is the world anchor. Offset is in frame pixels; scale grows the crown up from that point.
	var door: Vector2 = door_floor_px(stage)
	sprite.offset = Vector2(-door.x, -door.y)
	_apply_click_shape()
	if Engine.is_editor_hint():
		if label:
			label.text = String(stage).capitalize()
			label.visible = true
	else:
		_refresh_label()
	label.position = Vector2(-80, -door.y * scale_v - 36)
	fruit_hint.position = Vector2(-140, 12)
	_apply_trunk(String(stage))
	_apply_veins(String(stage))


const TRUNK_SIZE: Dictionary = {
	"sapling": Vector2(28, 40),
	"young": Vector2(40, 90),
	"mature": Vector2(56, 160),
	"elder": Vector2(72, 220),
	"ancient": Vector2(88, 260),
}
const VEIN_AMOUNT: Dictionary = {
	"sapling": 3, "young": 5, "mature": 8, "elder": 12, "ancient": 14,
}
const VEIN_POS: Dictionary = {
	"sapling": Vector2(0, -45), "young": Vector2(8, -110), "mature": Vector2(0, -250),
	"elder": Vector2(0, -440), "ancient": Vector2(0, -450),
}
const VEIN_EXTENT: Dictionary = {
	"sapling": Vector2(10, 30), "young": Vector2(12, 90), "mature": Vector2(120, 230),
	"elder": Vector2(200, 400), "ancient": Vector2(200, 410),
}
const VEIN_TEX: String = "res://assets/art/fx/fx_vein_mote_strip.png"
## Wider than the Keeper's feet box (48) so the sill at local y=8 stays walkable.
const DOOR_HALF_W: float = 32.0
## Below this line the door corridor is open. Collision never continues south of the sill.
const DOOR_CLEAR_Y: float = -48.0
var _door_latched: bool = false
## Spawn can sit inside the feet trigger. Latch that overlap and do not enter
## until they have been seen clear of it, or the new scene bounces straight back.
var _door_seen_clear: bool = false


func _physics_process(_delta: float) -> void:
	if Engine.is_editor_hint() or not is_inside_tree():
		return
	_check_door_feet()


func _ensure_trunk() -> void:
	if get_node_or_null("Trunk") != null:
		return
	var body := StaticBody2D.new()
	body.name = "Trunk"
	body.collision_layer = 1
	body.collision_mask = 0
	body.input_pickable = false
	var shape_node := CollisionShape2D.new()
	shape_node.name = "CollisionShape2D"
	shape_node.shape = RectangleShape2D.new()
	body.add_child(shape_node)
	add_child(body)


func _apply_click_shape() -> void:
	var cs: CollisionShape2D = get_node_or_null("CollisionShape2D") as CollisionShape2D
	if cs == null:
		return
	var bounds: Rect2 = _opaque_local_rect()
	var rect_shape := RectangleShape2D.new()
	rect_shape.size = bounds.size
	cs.shape = rect_shape
	cs.position = bounds.get_center()
	_ensure_door_click()


func _opaque_local_rect() -> Rect2:
	## Alpha bounds of the current frame, so the click does not stick out beside the sprite.
	if sprite == null or sprite.texture == null:
		return Rect2(-24, -48, 48, 48)
	var tex: Texture2D = sprite.texture
	var img: Image = tex.get_image()
	var frame_w: int = int(tex.get_width() / maxi(sprite.hframes, 1))
	var frame_h: int = int(tex.get_height() / maxi(sprite.vframes, 1))
	var origin_x: int = sprite.frame * frame_w
	var min_x: int = frame_w
	var min_y: int = frame_h
	var max_x: int = 0
	var max_y: int = 0
	var found: bool = false
	if img != null:
		var step: int = 2
		for py: int in range(0, frame_h, step):
			for px: int in range(0, frame_w, step):
				if img.get_pixel(origin_x + px, py).a <= 0.12:
					continue
				found = true
				min_x = mini(min_x, px)
				min_y = mini(min_y, py)
				max_x = maxi(max_x, px + step)
				max_y = maxi(max_y, py + step)
	if not found:
		min_x = 0
		min_y = 0
		max_x = frame_w
		max_y = frame_h
	var sc: Vector2 = sprite.scale
	var local_pos: Vector2 = (sprite.offset + Vector2(min_x, min_y)) * sc
	var local_size: Vector2 = Vector2(max_x - min_x, max_y - min_y) * sc
	return Rect2(local_pos, local_size)


func _ensure_door_click() -> void:
	var door: Area2D = get_node_or_null("DoorHit") as Area2D
	if door == null:
		door = Area2D.new()
		door.name = "DoorHit"
		door.collision_layer = 4
		door.collision_mask = 0
		door.monitoring = false
		door.monitorable = true
		door.input_pickable = true
		door.z_index = 2
		var shape_node := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = Vector2(DOOR_HALF_W * 2.0, 36.0)
		shape_node.shape = rect
		shape_node.position = Vector2(0, 8)
		door.add_child(shape_node)
		door.input_event.connect(_on_door_input)
		add_child(door)


func _on_door_input(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if not (event is InputEventMouseButton):
		return
	var mb: InputEventMouseButton = event
	if not mb.pressed or mb.button_index != MOUSE_BUTTON_LEFT:
		return
	_request_door()
	get_viewport().set_input_as_handled()


func wisp_orbit_center() -> Vector2:
	var sz: Vector2 = TRUNK_SIZE.get(String(GameState.stage_id), Vector2(28, 40))
	var third: float = sz.y / 3.0
	return global_position + Vector2(0, -third * 0.5)


func wisp_orbit_radius() -> float:
	## Elder canopy is far wider than the trunk. The ring has to match the tree.
	if String(GameState.stage_id) == "elder":
		return 280.0
	var sz: Vector2 = TRUNK_SIZE.get(String(GameState.stage_id), Vector2(28, 40))
	if has_node("/root/ForgeJobs"):
		return ForgeJobs.wisp_orbit_radius_for_size(Vector2(sz.x, sz.y / 3.0))
	return sz.x * 0.5 + 14.0


func _apply_trunk(stage: String) -> void:
	## Feet box of the trunk. The bottom edge is the Forge door sill (local y=0).
	## Painted roots south of that line are soil, so they stay walkable, and the
	## west watering stand (about 100px out, 35px south) is clear at every stage.
	var body: StaticBody2D = get_node_or_null("Trunk") as StaticBody2D
	if body == null:
		return
	for child: Node in body.get_children():
		child.queue_free()
	var sz: Vector2 = TRUNK_SIZE.get(stage, Vector2(28, 40))
	var box: Vector2 = FeetBox.size_for(sz)
	var half_w: float = box.x * 0.5
	var cap_top: float = -maxf(box.y, 56.0)
	## Crown only. The band from the cap down through the sill, and everything
	## south of the sill, stays open. Side jambs used to pinch that corridor.
	if cap_top < DOOR_CLEAR_Y:
		_add_trunk_rect(body, Rect2(-half_w, cap_top, box.x, DOOR_CLEAR_Y - cap_top))


func _add_trunk_rect(body: StaticBody2D, local_rect: Rect2) -> void:
	if local_rect.size.x < 4.0 or local_rect.size.y < 4.0:
		return
	var shape_node := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = local_rect.size
	shape_node.shape = rect
	shape_node.position = local_rect.get_center()
	body.add_child(shape_node)


func _ensure_door_trigger() -> void:
	set_physics_process(not Engine.is_editor_hint())


func _check_door_feet() -> void:
	if not has_node("/root/ForgeJobs"):
		return
	var occupied: bool = false
	var occupant: Node = null
	for group_name: String in ["keeper", "elaia"]:
		for node: Node in get_tree().get_nodes_in_group(group_name):
			if not (node is Node2D) or not (node as CanvasItem).visible:
				continue
			if node.has_method("actor_id") == false:
				continue
			var rel: Vector2 = (node as Node2D).global_position - global_position
			if absf(rel.x) > 22.0 or rel.y < -4.0 or rel.y > 16.0:
				continue
			occupied = true
			occupant = node
			break
		if occupied:
			break
	if not _door_seen_clear:
		if occupied:
			_door_latched = true
			return
		_door_seen_clear = true
	if not occupied:
		_door_latched = false
		return
	if _door_latched or occupant == null:
		return
	_door_latched = true
	ForgeJobs.try_door_entry(str(occupant.call("actor_id")))


func _ensure_veins() -> void:
	if get_node_or_null("VeinMotes") != null:
		return
	var motes := CPUParticles2D.new()
	motes.name = "VeinMotes"
	motes.texture = load(VEIN_TEX) as Texture2D
	motes.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	motes.local_coords = true
	motes.explosiveness = 0.0
	motes.randomness = 0.3
	motes.lifetime = 1.8
	motes.direction = Vector2(0, -1)
	motes.spread = 20.0
	motes.gravity = Vector2(0, -4)
	motes.initial_velocity_min = 6.0
	motes.initial_velocity_max = 14.0
	motes.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	motes.z_index = 1
	var mat := CanvasItemMaterial.new()
	mat.particles_animation = true
	mat.particles_anim_h_frames = 3
	mat.particles_anim_v_frames = 1
	mat.particles_anim_loop = false
	motes.material = mat
	motes.anim_speed_min = 1.0
	motes.anim_speed_max = 1.0
	add_child(motes)


func _apply_veins(stage: String) -> void:
	var motes: CPUParticles2D = get_node_or_null("VeinMotes") as CPUParticles2D
	if motes == null:
		return
	motes.amount = int(VEIN_AMOUNT.get(stage, 3))
	motes.position = VEIN_POS.get(stage, Vector2(0, -45))
	motes.emission_rect_extents = VEIN_EXTENT.get(stage, Vector2(10, 30))
	motes.emitting = true
