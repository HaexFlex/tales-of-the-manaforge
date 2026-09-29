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


func _ready() -> void:
	_apply_visual()
	if Engine.is_editor_hint():
		return
	add_to_group("forest_prop")
	set_meta("prop_kind", prop_kind)
	var body: StaticBody2D = get_node_or_null("Body") as StaticBody2D
	if prop_kind == "decor":
		add_to_group("forest_decor")
	elif body == null:
		add_to_group("forest_fill")
	if body:
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
