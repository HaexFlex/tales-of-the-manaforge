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


func _ready() -> void:
	set_process(false)
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
		set_meta("collider_size", collider_size)


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
	var shape := RectangleShape2D.new()
	shape.size = collider_size
	col.shape = shape
	col.position = Vector2(0.0, -collider_size.y * 0.5)


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
