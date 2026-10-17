extends Node
## Shared pointer actions for mouse, keyboard, and touch (540p phone groundwork).

const MOVE_SLOP_PX: float = 18.0
## 3-line scroll hint (20 px per line + 18). Placeholder copy lives in ui.longpress_hint.
const HOLD_HINT_SIZE: Vector2 = Vector2(200, 78)

var _touch_index: int = -1
var _touch_start_ms: int = 0
var _touch_pos: Vector2 = Vector2.ZERO
var _long_press_fired: bool = false
var _hold_panel_open: bool = false


func _ready() -> void:
	_ensure_input_actions()
	for arg: String in OS.get_cmdline_user_args():
		if arg == "--emulate-touch":
			Input.emulate_touch_from_mouse = true


func long_press_wait() -> float:
	## Same wait as the mouse-rest tooltip. No second constant.
	return WorldHover.rest_sec()


func show_hold_hint_if_needed(force: bool = false) -> bool:
	## Once per install, on a phone or a touch launch. The seen flag lives in settings.
	if not has_node("/root/GameAudio") or not has_node("/root/ContentStrings") or not has_node("/root/GameState"):
		return false
	if bool(GameAudio.get("touch_hold_hint_seen")):
		return false
	var touch: bool = force or OS.has_feature("mobile") or DisplayServer.is_touchscreen_available() or Input.emulate_touch_from_mouse
	if not touch:
		return false
	GameState.status_message.emit(ContentStrings.get_text("touch_hold_hint"))
	GameAudio.mark_touch_hold_hint_seen()
	return true


func _ensure_input_actions() -> void:
	# 0.5 is the action deadzone, not a hold. The long-press wait is long_press_wait() (0.8 s).
	if not InputMap.has_action("game_command"):
		InputMap.add_action("game_command", 0.5)
		var rmb := InputEventMouseButton.new()
		rmb.button_index = MOUSE_BUTTON_RIGHT
		InputMap.action_add_event("game_command", rmb)
		var key_g := InputEventKey.new()
		key_g.keycode = KEY_G
		InputMap.action_add_event("game_command", key_g)
	if not InputMap.has_action("game_inspect"):
		InputMap.add_action("game_inspect", 0.5)
		var key_h := InputEventKey.new()
		key_h.keycode = KEY_H
		InputMap.action_add_event("game_inspect", key_h)


func _process(_delta: float) -> void:
	if _touch_index < 0 or _long_press_fired:
		return
	if Time.get_ticks_msec() - _touch_start_ms >= int(long_press_wait() * 1000.0):
		_long_press_fired = true
		_dispatch_long_press(_touch_pos)


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var touch: InputEventScreenTouch = event as InputEventScreenTouch
		if touch.pressed:
			_touch_index = touch.index
			_touch_start_ms = Time.get_ticks_msec()
			_touch_pos = touch.position
			_long_press_fired = false
		elif touch.index == _touch_index:
			if not _long_press_fired:
				# Short tap: let Godot deliver normal gui/world clicks.
				pass
			_end_touch()
		return
	if event is InputEventScreenDrag and (event as InputEventScreenDrag).index == _touch_index:
		var drag: InputEventScreenDrag = event as InputEventScreenDrag
		if drag.position.distance_to(_touch_pos) > MOVE_SLOP_PX:
			_end_touch()
		return
	if event.is_action_pressed("game_inspect"):
		inspect_at_screen(get_viewport().get_mouse_position())


func is_command(event: InputEvent, require_pressed: bool = true) -> bool:
	if event == null:
		return false
	if InputMap.event_is_action(event, "game_command", true):
		return not require_pressed or event.is_pressed()
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if require_pressed and not mb.pressed:
			return false
		return mb.button_index == MOUSE_BUTTON_RIGHT
	return false


func pointer_position(event: InputEvent) -> Vector2:
	if event is InputEventMouseButton:
		return (event as InputEventMouseButton).position
	if event is InputEventScreenTouch:
		return (event as InputEventScreenTouch).position
	if event is InputEventKey:
		return get_viewport().get_mouse_position()
	return get_viewport().get_mouse_position()


func inspect_at_screen(screen_pos: Vector2) -> void:
	var tip: String = _tooltip_at_screen(screen_pos)
	if tip == "":
		return
	if has_node("/root/GameState"):
		GameState.status_message.emit(tip)


func _dispatch_long_press(screen_pos: Vector2) -> void:
	## Fires only after long_press_wait() (0.8 s). The 0.5 on the input actions is a deadzone.
	var tip: String = _tooltip_at_screen(screen_pos)
	if tip != "":
		_hold_panel_open = present_long_press_hint(screen_pos)
		return
	_route_world_command(screen_pos)


func present_long_press_hint(screen_pos: Vector2) -> bool:
	## Placeholder body. Lore replaces the one strings key. Toast only if the panel cannot open.
	var text: String = "ui.longpress_hint"
	if has_node("/root/ContentStrings"):
		text = str(ContentStrings.get_text("ui.longpress_hint"))
	if WorldHover.show_anchored_hint(text, screen_pos, HOLD_HINT_SIZE):
		return true
	if has_node("/root/GameState"):
		GameState.status_message.emit(text)
	return false


func _end_touch() -> void:
	_touch_index = -1
	if _hold_panel_open:
		_hold_panel_open = false
		WorldHover.dismiss_hold()


func _tooltip_at_screen(screen_pos: Vector2) -> String:
	var vp: Viewport = get_viewport()
	if vp == null:
		return ""
	var hovered: Control = vp.gui_get_hovered_control()
	if hovered == null:
		hovered = _control_at(screen_pos)
	if hovered == null:
		return ""
	var node: Node = hovered
	while node != null:
		if node is Control:
			var ctrl: Control = node as Control
			if str(ctrl.tooltip_text).strip_edges() != "":
				return str(ctrl.tooltip_text)
		node = node.get_parent()
	return ""


func _control_at(screen_pos: Vector2) -> Control:
	var vp: Viewport = get_viewport()
	if vp == null:
		return null
	return vp.gui_get_hovered_control() if vp.gui_get_hovered_control() != null else null


func _route_world_command(screen_pos: Vector2) -> void:
	var main: Node = get_tree().get_first_node_in_group("main_root")
	if main == null or not main.has_method("handle_rmb_ground"):
		return
	var world_pos: Vector2 = screen_pos
	if main is Node2D:
		var cam: Camera2D = main.get_node_or_null("Camera2D") as Camera2D
		if cam != null:
			world_pos = cam.get_global_mouse_position()
	main.call("handle_rmb_ground", world_pos)


func configure_scroll_container(scroll: ScrollContainer) -> void:
	scroll.scroll_deadzone = 12
	scroll.follow_focus = false
	if scroll.has_method("set_drag_and_drop_enabled"):
		scroll.set_drag_and_drop_enabled(false)
