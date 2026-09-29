@tool
extends Node2D
## Trampled paths on the ground, under the y-sorted props.
## One texture slot: path_texture tiles along every Line2D. Swap that texture for a new path piece.
## Patch sprites under this node (bends and node bases) are left as placed. Edit them in main.tscn.
## Keep this node between Ground and World. World stays at a higher z_index so props draw on top.

@export var path_texture: Texture2D:
	set(value):
		path_texture = value
		if is_node_ready():
			_apply()
@export var tint: Color = Color(1, 1, 1, 1):
	set(value):
		tint = value
		if is_node_ready():
			_apply()
@export var path_width: float = 48.0:
	set(value):
		path_width = maxf(4.0, value)
		if is_node_ready():
			_apply()


func _ready() -> void:
	_apply()


func _apply() -> void:
	z_index = 0
	y_sort_enabled = false
	for child: Node in get_children():
		var line: Line2D = child as Line2D
		if line == null:
			continue
		line.width = path_width
		line.default_color = tint
		line.texture = path_texture
		line.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		line.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
		line.texture_mode = Line2D.LINE_TEXTURE_TILE
		line.joint_mode = Line2D.LINE_JOINT_ROUND
		line.begin_cap_mode = Line2D.LINE_CAP_ROUND
		line.end_cap_mode = Line2D.LINE_CAP_ROUND
		line.antialiased = false
		line.z_index = 0
