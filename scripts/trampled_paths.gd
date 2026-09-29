@tool
extends Node2D
## Faint trampled paths on the ground, under the y-sorted props.
## One texture slot: assign path_texture on this node and every line tiles it.
## Leave the texture empty for the dirt-tint placeholder. Edit each Line2D's points in main.tscn.
## Keep this node between Ground and World. World stays at a higher z_index so props draw on top.

@export var path_texture: Texture2D:
	set(value):
		path_texture = value
		if is_node_ready():
			_apply()
@export var tint: Color = Color(0.55, 0.46, 0.34, 0.32):
	set(value):
		tint = value
		if is_node_ready():
			_apply()
@export var path_width: float = 36.0:
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
		line.texture_mode = Line2D.LINE_TEXTURE_TILE
		line.joint_mode = Line2D.LINE_JOINT_ROUND
		line.begin_cap_mode = Line2D.LINE_CAP_ROUND
		line.end_cap_mode = Line2D.LINE_CAP_ROUND
		line.antialiased = false
		line.z_index = 0
