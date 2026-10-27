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
var _damp_sprite: Sprite2D
var _damp_active: bool = false
var _damp_elapsed: float = 0.0
var _damp_step: int = -1
## stage_id -> {file, size:[w,h], anchor, ...} from assets/art/manatree/native/manatree_meta.json
var _meta_stages: Dictionary = {}
var _anim_frames: int = 1
var _anim_fps: float = 7.0
var _anim_time: float = 0.0
## Wide strips are split on frame boundaries. Empty means one texture, hframes = frames.
var _tile_textures: Array[Texture2D] = []
var _frames_per_tile: int = 1
var _shown_tile: int = -1

const META_PATH: String = "res://assets/art/manatree/native/manatree_meta.json"
const BREATH_SHADER: Shader = preload("res://assets/art/manatree/manatree_breath.gdshader")
const BREATH_SWAY_AMP: Dictionary = {
	"sapling": 1.0, "young": 1.0, "mature": 1.0, "elder": 2.0, "ancient": 2.0,
}
const BREATH_SWAY_HZ: Dictionary = {
	"sapling": 0.30, "young": 0.26, "mature": 0.22, "elder": 0.19, "ancient": 0.16,
}
const BREATH_LEAF_AMOUNT: Dictionary = {
	"sapling": 1, "young": 2, "mature": 3, "elder": 5, "ancient": 7,
}
const LEAF_DRIFT_ATLAS: String = "res://assets/art/manatree/leaf_drift/leaf_drift_atlas_4x3.png"
const BREATH_LEAF_LIFETIME: float = 5.0
var _leaf_tex: Texture2D
const STAGE_TEXTURES: Dictionary = {
	&"sapling": "res://assets/art/manatree/native/manatree_sapling.png",
	&"young": "res://assets/art/manatree/native/manatree_young.png",
	&"mature": "res://assets/art/manatree/native/manatree_mature.png",
	&"elder": "res://assets/art/manatree/native/manatree_elder.png",
	&"ancient": "res://assets/art/manatree/native/manatree_ancient.png",
}
const TINT_FOLDER_IDS: PackedStringArray = ["default", "blossom", "autumn"]
const TINT_LUT_PATH: String = "res://assets/art/manatree/native/tints/canopy_tint_lut.json"


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
	_apply_manatree_tint()
	if not GameState.load_completed.is_connected(_on_tint_or_save):
		GameState.load_completed.connect(_on_tint_or_save)
	if not GameState.echo_flags_changed.is_connected(_on_tint_or_save):
		GameState.echo_flags_changed.connect(_on_tint_or_save)
	GameState.fruit_ready_changed.connect(_on_fruit_changed)
	GameState.needs_changed.connect(_refresh_label)
	GameState.selection_changed.connect(_refresh_label)
	add_to_group("manatree")
	add_to_group("interactable")
	_ensure_trunk()
	_ensure_door_trigger()
	_ensure_veins()
	_ensure_leaf_drift()
	_ensure_stage_bloom()
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
			if GameInput.yields_touch_double_tap(mb):
				return
			if _click_is_door():
				_request_door()
			# LMB on the tree is not empty ground — swallow so Main does not deselect.
			get_viewport().set_input_as_handled()
			return
		if GameInput.is_command(mb):
			apply_player_command()
			get_viewport().set_input_as_handled()


func _click_is_door() -> bool:
	var local: Vector2 = to_local(get_global_mouse_position())
	return absf(local.x) <= DOOR_HALF_W and local.y >= -20.0 and local.y <= 24.0


func _request_door() -> void:
	## The arch is not an entrance. Only the Enter Forge button changes the scene.
	return


func work_footprint() -> Rect2:
	## Door sill is the node origin at every stage. Watering uses this point, not the grown sprite.
	return Rect2(global_position, Vector2.ZERO)


func apply_player_command() -> void:
	## RMB: wisp assign to Manatree, and the selected hero walks to tend it.
	## Watering stops, then he walks to the tree and the tending window opens on arrival.
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
	var was_watering: bool = _watering
	_watering = active
	if active and not was_watering:
		_restart_damp_decal()
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
	## The channel's gain line is the toast that stays. Ancient used to replace it.
	if GameState.stage_id == &"ancient":
		GameState.status_message.emit(ContentStrings.get_text("tree_water_ancient_ok"))
	hero.call("start_water_channel", self)


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
	_tick_damp_decal(delta)
	if _anim_frames <= 1 or sprite == null:
		return
	_anim_time += delta
	var frame: int = int(_anim_time * _anim_fps) % _anim_frames
	_show_frame(frame)


## One frame of the stage strip. Tiled stages swap a ≤2048-wide texture and use a local hframe.
func _show_frame(frame: int) -> void:
	if sprite == null:
		return
	if _tile_textures.size() <= 1 or _frames_per_tile <= 0:
		if sprite.frame != frame:
			sprite.frame = frame
		return
	var per: int = _frames_per_tile
	var tile_i: int = clampi(int(frame / float(per)), 0, _tile_textures.size() - 1)
	var local_frame: int = frame % per
	if tile_i != _shown_tile:
		sprite.texture = _tile_textures[tile_i]
		sprite.hframes = per
		sprite.vframes = 1
		_shown_tile = tile_i
	if sprite.frame != local_frame:
		sprite.frame = local_frame


func _on_fruit_changed(ready: bool) -> void:
	if ready:
		fruit_hint.text = ContentStrings.get_text("fruit_ready_prompt")
	elif GameState.fruit_harvested_pending_ascend:
		fruit_hint.text = ContentStrings.get_text("ascension_paused_hint")
	else:
		fruit_hint.text = ""
	_apply_label_visibility()


func world_hover_name() -> String:
	return ContentStrings.get_text("tree_menu_title")


func _on_hover(inside: bool) -> void:
	_hovered = inside
	_apply_label_visibility()
	WorldHover.sync(self, inside, world_hover_name())
	if has_node("/root/MinigameHost"):
		MinigameHost.call("show_prompt", "manatree", global_position + Vector2(0, -72), inside)


func _refresh_label() -> void:
	var suffix: String = ""
	if _watering:
		suffix = "\n" + ContentStrings.get_text("tree_water_channel_hud")
		if Backpack.owns_watering_can():
			suffix += "\n" + ContentStrings.get_text("tool_water_hint")
		if has_node("/root/MinigameHost") and str(MinigameHost.call("hero_for", "manatree")) == "keeper":
			suffix += "\n" + ContentStrings.get_text("minigame_lend_a_hand")
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
	## The papyrus hover names the tree. The floating stage line sat on the crown.
	if label:
		label.visible = false
	if fruit_hint:
		fruit_hint.visible = false


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


func _on_tint_or_save() -> void:
	if Engine.is_editor_hint():
		return
	_refresh_visual()


func _tint_texture_path(stage: StringName) -> String:
	var idx: int = clampi(GameState.manatree_tint, 0, TINT_FOLDER_IDS.size() - 1)
	var folder: String = TINT_FOLDER_IDS[idx]
	var tinted: String = "res://assets/art/manatree/native/tints/%s/manatree_%s.png" % [folder, String(stage)]
	if FileAccess.file_exists(tinted):
		return tinted
	return str(STAGE_TEXTURES.get(stage, STAGE_TEXTURES[&"sapling"]))


func _refresh_visual() -> void:
	var stage: StringName = StringName(preview_stage) if Engine.is_editor_hint() else GameState.stage_id
	var path: String = _tint_texture_path(stage) if not Engine.is_editor_hint() else str(STAGE_TEXTURES.get(stage, STAGE_TEXTURES[&"sapling"]))
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
	_tile_textures.clear()
	_frames_per_tile = 1
	_shown_tile = -1
	var tiles_v: Variant = meta.get("tiles", [])
	if typeof(tiles_v) == TYPE_ARRAY:
		for tile_name: Variant in tiles_v:
			var ttex: Texture2D = load("res://assets/art/manatree/%s" % str(tile_name)) as Texture2D
			if ttex == null:
				_tile_textures.clear()
				break
			_tile_textures.append(ttex)
	if _tile_textures.size() > 1:
		_frames_per_tile = maxi(1, int(meta.get("tile_frames", 1)))
		sprite.hframes = _frames_per_tile
		sprite.vframes = 1
		sprite.texture = _tile_textures[0]
		sprite.frame = 0
		_shown_tile = 0
	else:
		_tile_textures.clear()
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
			label.visible = false
	else:
		_refresh_label()
	label.position = Vector2(-80, -door.y * scale_v - 36)
	fruit_hint.position = Vector2(-140, 12)
	_apply_trunk(String(stage))
	_apply_veins(String(stage))
	_apply_breath(String(stage))
	if _damp_active and _damp_sprite != null and _damp_sprite.visible:
		_apply_damp_step(_damp_step)
		_update_damp_position()


const DAMP_SOIL_PATH: String = "res://assets/art/hub/ground/damp/"
const DAMP_FADE_STEPS: Array[String] = ["0_full", "1_66", "2_33", "3_faint"]
const DAMP_FADE_AT: Array[float] = [8.0, 16.0, 24.0]
const DAMP_HIDE_SEC: float = 30.0
const DAMP_TOP_PAD: float = 4.0

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
		door.mouse_entered.connect(_on_door_hover.bind(true))
		door.mouse_exited.connect(_on_door_hover.bind(false))
		add_child(door)


func _on_door_hover(inside: bool) -> void:
	var door: Area2D = get_node_or_null("DoorHit") as Area2D
	if door == null:
		return
	WorldHover.sync(door, inside, ContentStrings.get_text("hover_forge_door"))


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
	var keeper_half_h: float = Keeper.BODY_SIZE.y * 0.5
	if not Engine.is_editor_hint() and is_inside_tree():
		var keepers: Array[Node] = get_tree().get_nodes_in_group("keeper")
		if not keepers.is_empty() and keepers[0] is Keeper:
			keeper_half_h = Keeper.idle_frame_height_world((keepers[0] as Keeper).sprite) * 0.5
	return global_position + Vector2(0, -third * 0.5 - keeper_half_h)


func wisp_orbit_radius() -> float:
	## Vertical semi-axis (ry) of the wide manatree orbit ellipse.
	return wisp_orbit_radii().y


func wisp_orbit_radii() -> Vector2:
	if String(GameState.stage_id) == "elder" or String(GameState.stage_id) == "ancient":
		return Vector2(280.0, 140.0)
	var sz: Vector2 = TRUNK_SIZE.get(String(GameState.stage_id), Vector2(28, 40))
	var ry: float = sz.x * 0.5 + 14.0
	if has_node("/root/ForgeJobs"):
		ry = ForgeJobs.wisp_orbit_radius_for_size(Vector2(sz.x, sz.y / 3.0))
	return Vector2(ry, ry * 0.5)


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
	## Standing on the sill does not enter. The Enter Forge button is the only way in.
	return


func _ensure_stage_bloom() -> void:
	if get_node_or_null("StageBloom") != null:
		return
	var bloom := Node2D.new()
	bloom.name = "StageBloom"
	var script_res: Script = load("res://scripts/manatree_stage_bloom.gd") as Script
	if script_res != null:
		bloom.set_script(script_res)
	add_child(bloom)


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


func _leaf_placeholder_tex() -> Texture2D:
	if _leaf_tex != null:
		return _leaf_tex
	_leaf_tex = load(LEAF_DRIFT_ATLAS) as Texture2D
	return _leaf_tex


func _ensure_leaf_drift() -> void:
	if get_node_or_null("LeafDrift") != null:
		return
	var leaves := CPUParticles2D.new()
	leaves.name = "LeafDrift"
	leaves.texture = _leaf_placeholder_tex()
	leaves.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	leaves.local_coords = true
	leaves.explosiveness = 0.0
	leaves.randomness = 0.45
	leaves.lifetime = BREATH_LEAF_LIFETIME
	leaves.direction = Vector2(0, 1)
	leaves.spread = 28.0
	leaves.gravity = Vector2(0, 18)
	leaves.initial_velocity_min = 4.0
	leaves.initial_velocity_max = 14.0
	leaves.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	leaves.z_index = 1
	var leaf_mat := CanvasItemMaterial.new()
	leaf_mat.particles_animation = true
	leaf_mat.particles_anim_h_frames = 4
	leaf_mat.particles_anim_v_frames = 3
	leaves.material = leaf_mat
	add_child(leaves)


func _apply_breath(stage: String) -> void:
	if Engine.is_editor_hint():
		if sprite != null:
			sprite.material = null
		return
	if sprite == null:
		return
	var mat: ShaderMaterial
	if sprite.material is ShaderMaterial and (sprite.material as ShaderMaterial).shader == BREATH_SHADER:
		mat = sprite.material as ShaderMaterial
	else:
		mat = ShaderMaterial.new()
		mat.shader = BREATH_SHADER
		sprite.material = mat
	var door: Vector2 = door_floor_px(StringName(stage))
	var sc: float = _display_scale(StringName(stage))
	var sz: Vector2 = TRUNK_SIZE.get(stage, Vector2(28, 40))
	var box: Vector2 = FeetBox.size_for(sz)
	var canopy_base_y: float = -maxf(box.y, 56.0)
	var crown_h: float = maxf(canopy_base_y + door.y * sc, 8.0)
	mat.set_shader_parameter("sway_amp_px", float(BREATH_SWAY_AMP.get(stage, 1.0)))
	mat.set_shader_parameter("sway_hz", float(BREATH_SWAY_HZ.get(stage, 0.25)))
	mat.set_shader_parameter("canopy_base_y", canopy_base_y)
	mat.set_shader_parameter("crown_h_px", crown_h)
	var leaves: CPUParticles2D = get_node_or_null("LeafDrift") as CPUParticles2D
	if leaves == null:
		return
	leaves.amount = int(BREATH_LEAF_AMOUNT.get(stage, 2))
	leaves.position = Vector2(0, -crown_h * 0.55)
	leaves.emission_rect_extents = Vector2(door.x * sc * 0.42, crown_h * 0.14)
	leaves.emitting = true


func _damp_decal_size_key(stage: StringName) -> String:
	match String(stage):
		"sapling":
			return "sapling"
		"young":
			return "young"
		"mature":
			return "mature"
		"elder", "ancient":
			return "ancient"
		_:
			return "sapling"


func _ensure_damp_decal() -> void:
	if _damp_sprite != null:
		return
	var world: Node = get_parent()
	if world == null:
		return
	_damp_sprite = Sprite2D.new()
	_damp_sprite.name = &"WateredGroundDecal"
	_damp_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_damp_sprite.centered = true
	_damp_sprite.visible = false
	_damp_sprite.y_sort_enabled = true
	world.add_child(_damp_sprite)
	world.move_child(_damp_sprite, get_index())


func _restart_damp_decal() -> void:
	if Engine.is_editor_hint():
		return
	_ensure_damp_decal()
	if _damp_sprite == null:
		return
	_damp_active = true
	_damp_elapsed = 0.0
	_damp_step = 0
	_apply_damp_step(0)
	_update_damp_position()
	_damp_sprite.visible = true


func _apply_damp_step(step: int) -> void:
	if _damp_sprite == null:
		return
	var idx: int = clampi(step, 0, DAMP_FADE_STEPS.size() - 1)
	_damp_step = idx
	var size_key: String = _damp_decal_size_key(GameState.stage_id)
	var step_key: String = DAMP_FADE_STEPS[idx]
	var path: String = "%sdamp_soil_%s_%s.png" % [DAMP_SOIL_PATH, size_key, step_key]
	_damp_sprite.texture = load(path) as Texture2D


func _update_damp_position() -> void:
	if _damp_sprite == null:
		return
	_damp_sprite.z_index = z_index - 1
	var door: Vector2 = door_floor_px(GameState.stage_id)
	var scale_v: float = _display_scale(GameState.stage_id)
	var door_local: Vector2 = door * scale_v
	var tex_h: float = 16.0
	if _damp_sprite.texture != null:
		tex_h = float(_damp_sprite.texture.get_height())
	_damp_sprite.global_position = global_position + Vector2(door_local.x, door_local.y - DAMP_TOP_PAD - tex_h * 0.5)


func _tick_damp_decal(delta: float) -> void:
	if not _damp_active or _damp_sprite == null:
		return
	_damp_elapsed += delta
	if _damp_elapsed >= DAMP_HIDE_SEC:
		_damp_active = false
		_damp_sprite.visible = false
		return
	if _damp_elapsed >= DAMP_FADE_AT[2] and _damp_step < 3:
		_apply_damp_step(3)
	elif _damp_elapsed >= DAMP_FADE_AT[1] and _damp_step < 2:
		_apply_damp_step(2)
	elif _damp_elapsed >= DAMP_FADE_AT[0] and _damp_step < 1:
		_apply_damp_step(1)
	_update_damp_position()


func _exit_tree() -> void:
	if _damp_sprite != null and is_instance_valid(_damp_sprite):
		_damp_sprite.queue_free()
		_damp_sprite = null


func _apply_manatree_tint() -> void:
	if Engine.is_editor_hint():
		return
	_refresh_visual()
