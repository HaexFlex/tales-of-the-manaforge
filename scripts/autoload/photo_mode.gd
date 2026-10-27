extends Node
## Sprint photo mode: hide UI, pan/zoom the hub camera, save a viewport PNG.
## Keys: P enter, F12 save (exits), Esc cancel (restores camera). Content & Lore: UI strings.

const TOGGLE_KEY: Key = KEY_P
const CAPTURE_KEY: Key = KEY_F12
const SCREENSHOT_DIR: String = "user://screenshots/"

var _active: bool = false
var _saved_pos: Vector2 = Vector2.ZERO
var _saved_zoom: float = 1.0
var _ui_restore: Array[Dictionary] = []
var _dragging: bool = false
var _drag_last: Vector2 = Vector2.ZERO


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func is_active() -> bool:
	return _active


func try_enter() -> bool:
	if _active:
		return true
	if not _can_enter():
		return false
	var main: Node = _main()
	if main == null:
		return false
	var cam: Camera2D = main.get_node_or_null("Camera2D") as Camera2D
	if cam == null:
		return false
	_saved_pos = cam.position
	_saved_zoom = float(main.get("camera_zoom"))
	_close_pause_if_open()
	_hide_ui()
	_active = true
	_dragging = false
	if get_tree() != null:
		get_tree().paused = false
	return true


func try_exit(restore_camera: bool = true) -> void:
	if not _active:
		return
	_active = false
	_dragging = false
	if restore_camera:
		_restore_camera()
	_restore_ui()


func capture_and_exit() -> bool:
	if not _active:
		return false
	var path: String = _screenshot_path()
	var ok: bool = _save_viewport_png(path)
	# Content & Lore: photo_mode_saved_toast
	var toast: String = ContentStrings.get_text("photo_mode_saved_toast")
	try_exit(true)
	if ok:
		call_deferred("_emit_saved_toast", toast)
	return ok


func _emit_saved_toast(text: String) -> void:
	if has_node("/root/GameState"):
		GameState.status_message.emit(text)


func _can_enter() -> bool:
	if BattleView.is_open():
		return false
	if has_node("/root/EchoChamber") and EchoChamber.in_battle:
		return false
	var host: Node = get_tree().root.get_node_or_null("MinigameHost")
	if host != null and host.has_method("is_open") and bool(host.call("is_open")):
		return false
	return _main() != null


func _main() -> Node:
	var tree: SceneTree = get_tree()
	if tree == null:
		return null
	return tree.get_first_node_in_group("main_root")


func _close_pause_if_open() -> void:
	for pm: Node in get_tree().get_nodes_in_group("pause_menu"):
		if pm.has_method("is_open") and bool(pm.call("is_open")):
			if pm.has_method("resume_game"):
				pm.call("resume_game")


func _hide_ui() -> void:
	_ui_restore.clear()
	var main: Node = _main()
	if main != null:
		for ch: Node in main.get_children():
			if ch is CanvasLayer:
				var layer: CanvasLayer = ch as CanvasLayer
				_ui_restore.append({"node": layer, "visible": layer.visible})
				layer.visible = false
	for ov: Node in get_tree().get_nodes_in_group("battle_overlay"):
		if ov is CanvasItem:
			var item: CanvasItem = ov as CanvasItem
			_ui_restore.append({"node": item, "visible": item.visible})
			item.visible = false


func _restore_ui() -> void:
	for row: Dictionary in _ui_restore:
		var node: Variant = row.get("node")
		if node is Node and is_instance_valid(node):
			(node as Node).visible = bool(row.get("visible", true))
	_ui_restore.clear()


func _restore_camera() -> void:
	var main: Node = _main()
	if main == null:
		return
	main.call("set_camera_zoom", _saved_zoom, false)
	var cam: Camera2D = main.get_node_or_null("Camera2D") as Camera2D
	if cam == null:
		return
	cam.position = _saved_pos
	main.call("_clamp_camera")


func _screenshot_path() -> String:
	var dt: Dictionary = Time.get_datetime_dict_from_system()
	var stamp: String = "%04d%02d%02d_%02d%02d%02d" % [
		int(dt.year), int(dt.month), int(dt.day),
		int(dt.hour), int(dt.minute), int(dt.second),
	]
	return "%smanaforge_%s.png" % [SCREENSHOT_DIR, stamp]


func _save_viewport_png(path: String) -> bool:
	var tree: SceneTree = get_tree()
	if tree == null:
		return false
	DirAccess.make_dir_recursive_absolute(SCREENSHOT_DIR)
	var vp: Viewport = tree.root.get_viewport()
	var tex: ViewportTexture = vp.get_texture()
	if tex == null:
		return false
	var img: Image = tex.get_image()
	if img == null or img.is_empty():
		return false
	return img.save_png(path) == OK


func _process(delta: float) -> void:
	if not _active:
		return
	var main: Node = _main()
	if main == null:
		return
	var dir := Vector2.ZERO
	if Input.is_action_pressed("ui_left"):
		dir.x -= 1.0
	if Input.is_action_pressed("ui_right"):
		dir.x += 1.0
	if Input.is_action_pressed("ui_up"):
		dir.y -= 1.0
	if Input.is_action_pressed("ui_down"):
		dir.y += 1.0
	if dir == Vector2.ZERO:
		return
	var speed: float = float(main.call("get_camera_pan_speed"))
	main.call("pan_camera", dir.normalized() * speed * delta)


func _input(event: InputEvent) -> void:
	if _active:
		_photo_input(event)
		return
	if not (event is InputEventKey):
		return
	var key: InputEventKey = event as InputEventKey
	if not key.pressed or key.echo:
		return
	if key.ctrl_pressed or key.alt_pressed or key.meta_pressed:
		return
	if key.keycode != TOGGLE_KEY and int(key.physical_keycode) != int(TOGGLE_KEY):
		return
	if try_enter():
		get_viewport().set_input_as_handled()


func _photo_input(event: InputEvent) -> void:
	if event is InputEventKey:
		var key: InputEventKey = event as InputEventKey
		if not key.pressed or key.echo:
			return
		if key.keycode == KEY_ESCAPE:
			get_viewport().set_input_as_handled()
			try_exit(true)
			return
		if key.keycode == CAPTURE_KEY:
			get_viewport().set_input_as_handled()
			capture_and_exit()
			return
	var main: Node = _main()
	if main == null:
		return
	if main.has_method("_handle_zoom_input") and bool(main.call("_handle_zoom_input", event)):
		get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				_dragging = true
				_drag_last = mb.position
			else:
				_dragging = false
			get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseMotion and _dragging:
		var motion: InputEventMouseMotion = event as InputEventMouseMotion
		var delta: Vector2 = motion.position - _drag_last
		_drag_last = motion.position
		var cam: Camera2D = main.get_node_or_null("Camera2D") as Camera2D
		var zoom: float = cam.zoom.x if cam != null and cam.zoom.x > 0.001 else 1.0
		main.call("pan_camera", -delta / zoom)
		get_viewport().set_input_as_handled()
