extends Node
## F9 opens AnimPreview. F8 opens the debug panel.
## Both stay on the testing path: the manaforge_debug feature, or an editor
## debug run. Windows Release / Stable sets manaforge_stable and strips the
## scenes, so neither key opens anything there.

const PREVIEW_SCENE: String = "res://tools/AnimPreview.tscn"
const DEBUG_PANEL_SCENE: String = "res://tools/debug/debug_panel.tscn"
const DEBUG_PANEL_NAME: String = "DebugToolsPanel"


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func debug_tools_enabled() -> bool:
	## Stable wins even if that preset was exported with the debug template.
	if OS.has_feature("manaforge_stable"):
		return false
	if OS.has_feature("manaforge_debug"):
		return true
	return OS.is_debug_build()


func debug_panel_available() -> bool:
	return debug_tools_enabled() and ResourceLoader.exists(DEBUG_PANEL_SCENE)


func debug_panel_open() -> bool:
	return get_tree().root.get_node_or_null(DEBUG_PANEL_NAME) != null


func set_debug_panel(open: bool) -> void:
	if not debug_panel_available():
		return
	var existing: Node = get_tree().root.get_node_or_null(DEBUG_PANEL_NAME)
	if open:
		if existing != null:
			_sync_debug_toggles(true)
			return
		var packed: PackedScene = load(DEBUG_PANEL_SCENE) as PackedScene
		if packed == null:
			return
		var node: Node = packed.instantiate()
		node.name = DEBUG_PANEL_NAME
		get_tree().root.add_child(node)
	elif existing != null:
		existing.queue_free()
	_sync_debug_toggles(open)


func toggle_debug_panel() -> void:
	set_debug_panel(not debug_panel_open())


func _input(event: InputEvent) -> void:
	if _is_panel_key(event):
		get_viewport().set_input_as_handled()
		toggle_debug_panel()
		return
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


func _is_panel_key(event: InputEvent) -> bool:
	if not debug_panel_available():
		return false
	return _plain_key(event, KEY_F8)


func _is_preview_key(event: InputEvent) -> bool:
	if not debug_tools_enabled():
		return false
	return _plain_key(event, KEY_F9)


func _plain_key(event: InputEvent, keycode: Key) -> bool:
	if not (event is InputEventKey):
		return false
	var key: InputEventKey = event as InputEventKey
	if not key.pressed or key.echo:
		return false
	if key.keycode != keycode:
		return false
	if key.ctrl_pressed or key.alt_pressed or key.meta_pressed:
		return false
	return true


func _sync_debug_toggles(open: bool) -> void:
	for node: Node in get_tree().get_nodes_in_group("pause_menu"):
		if node.has_method("sync_debug_toggle"):
			node.call("sync_debug_toggle", open)
