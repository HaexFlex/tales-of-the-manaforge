@tool
extends Node2D
class_name ForestProp
## One reusable forest piece (tree, bush, or glade tuft).
## The hub scene instances this; nothing spawns these at runtime.

@export_file("*.png") var texture_path: String = "":
	set(value):
		texture_path = value
		if is_node_ready() or Engine.is_editor_hint():
			_apply_visual()

@export var prop_kind: String = "tree":
	set(value):
		prop_kind = value
		if is_node_ready() or Engine.is_editor_hint():
			_apply_visual()

@export var sprite_scale: float = 1.0:
	set(value):
		sprite_scale = value
		if is_node_ready() or Engine.is_editor_hint():
			_apply_visual()

@export var collider_size: Vector2 = Vector2(16, 10):
	set(value):
		collider_size = value
		if is_node_ready() or Engine.is_editor_hint():
			_apply_visual()

@export var sprite_modulate: Color = Color.WHITE:
	set(value):
		sprite_modulate = value
		if is_node_ready() or Engine.is_editor_hint():
			_apply_visual()

## Ground families (grass, fern, mushroom, rock, flower). No forest_decor slot and no collision.
@export var ground_deco: bool = false

var _glow: Sprite2D
var _glow_phase: float = 0.0
var _day_texture_path: String = ""


func _ready() -> void:
	set_process(false)
	if texture_path != "":
		_day_texture_path = HubGroundDusk.paired_day_path(texture_path)
	_apply_visual()
	if Engine.is_editor_hint():
		return
	add_to_group("forest_prop")
	set_meta("prop_kind", prop_kind)
	var body: StaticBody2D = get_node_or_null("Body") as StaticBody2D
	if ground_deco:
		add_to_group("hub_ground_deco")
		if body:
			var col: CollisionShape2D = body.get_node_or_null("CollisionShape2D") as CollisionShape2D
			if col:
				col.disabled = true
	elif prop_kind == "decor":
		add_to_group("forest_decor")
	elif body == null:
		add_to_group("forest_fill")
	if body and not ground_deco:
		body.add_to_group("forest_collision")
		_bind_hover(body)
		var applied: Vector2 = collider_size
		var walk_col: CollisionShape2D = body.get_node_or_null("CollisionShape2D") as CollisionShape2D
		if walk_col != null and walk_col.shape is RectangleShape2D:
			applied = (walk_col.shape as RectangleShape2D).size
		set_meta("collider_size", applied)


func apply_dusk_variant(use_dusk: bool) -> void:
	if not ground_deco:
		return
	if _day_texture_path == "" and texture_path != "":
		_day_texture_path = HubGroundDusk.paired_day_path(texture_path)
	if _day_texture_path == "":
		return
	var target: String = _day_texture_path
	if use_dusk:
		target = HubGroundDusk.paired_dusk_path(_day_texture_path)
	if target != texture_path:
		texture_path = target


func world_hover_name() -> String:
	if prop_kind == "tree":
		return ContentStrings.get_text("hover_tree")
	if prop_kind == "bush":
		return ContentStrings.get_text("hover_bush")
	return ""


func _bind_hover(body: StaticBody2D) -> void:
	if world_hover_name() == "":
		return
	body.input_pickable = true
	if body.mouse_entered.is_connected(_on_prop_hover):
		return
	body.mouse_entered.connect(_on_prop_hover.bind(true))
	body.mouse_exited.connect(_on_prop_hover.bind(false))


func _on_prop_hover(inside: bool) -> void:
	WorldHover.sync(self, inside, world_hover_name())


func _apply_visual() -> void:
	var spr: Sprite2D = get_node_or_null("Sprite") as Sprite2D
	if spr == null:
		return
	spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	spr.centered = false
	spr.y_sort_enabled = true
	var scale_v: float = sprite_scale
	if scale_v <= 0.0:
		scale_v = 1.0
	spr.scale = Vector2(scale_v, scale_v)
	spr.modulate = sprite_modulate
	if texture_path != "" and ResourceLoader.exists(texture_path):
		var tex: Texture2D = load(texture_path) as Texture2D
		spr.texture = tex
		if tex != null:
			var sz := Vector2(float(tex.get_width()), float(tex.get_height()))
			spr.offset = Vector2(-sz.x * 0.5, -sz.y)
	_sync_glow()
	var body: StaticBody2D = get_node_or_null("Body") as StaticBody2D
	if body == null:
		return
	var col: CollisionShape2D = body.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if col == null:
		return
	## The crown is paint. The authored size is already the trunk's feet box,
	## so a third of the canvas would wall off the clearing under the leaves.
	FeetBox.apply_size(col, collider_size, Vector2.ZERO)


func _glow_texture_path() -> String:
	var file_name: String = texture_path.get_file()
	if not file_name.begins_with("mushroom_glow_") or file_name.ends_with("_glow.png"):
		return ""
	var glow_path: String = texture_path.get_base_dir().path_join(file_name.get_basename() + "_glow.png")
	if ResourceLoader.exists(glow_path):
		return glow_path
	return ""


func _sync_glow() -> void:
	var glow_path: String = _glow_texture_path()
	if glow_path == "":
		if _glow:
			_glow.visible = false
		set_process(false)
		return
	if _glow == null:
		_glow = Sprite2D.new()
		_glow.name = "Glow"
		var mat := CanvasItemMaterial.new()
		mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		_glow.material = mat
		_glow.centered = false
		_glow.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		_glow.offset = Vector2(-48, -72)
		add_child(_glow)
	_glow.visible = true
	_glow.texture = load(glow_path) as Texture2D
	_glow_phase = float((int(position.x) * 13 + int(position.y) * 7) % 360) * 0.02
	set_process(not Engine.is_editor_hint())


func _process(delta: float) -> void:
	if _glow == null or not _glow.visible:
		return
	_glow_phase += delta
	var wave: float = 0.5 + 0.5 * sin(_glow_phase * TAU / 3.5)
	var color: Color = _glow.modulate
	color.a = lerpf(0.55, 1.0, wave)
	_glow.modulate = color
