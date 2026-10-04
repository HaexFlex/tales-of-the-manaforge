extends Node
## F9 opens the animation preview. Debug builds only.
## The scene stays under tools/, which the export strip removes, so a packed
## release has nothing to open even if this check were skipped.

const PREVIEW_SCENE: String = "res://tools/AnimPreview.tscn"


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _input(event: InputEvent) -> void:
	if not _is_preview_key(event):
		return
	get_viewport().set_input_as_handled()
	if not ResourceLoader.exists(PREVIEW_SCENE):
		return
	var tree := get_tree()
	var current: Node = tree.current_scene
	if current != null and current.scene_file_path == PREVIEW_SCENE:
		return
	tree.call_deferred("change_scene_to_file", PREVIEW_SCENE)


func _is_preview_key(event: InputEvent) -> bool:
	## A release export reports is_debug_build() as false, so F9 never opens it.
	if not OS.is_debug_build():
		return false
	if not (event is InputEventKey):
		return false
	var key: InputEventKey = event as InputEventKey
	if not key.pressed or key.echo:
		return false
	if key.keycode != KEY_F9:
		return false
	if key.ctrl_pressed or key.alt_pressed or key.meta_pressed:
		return false
	return true
