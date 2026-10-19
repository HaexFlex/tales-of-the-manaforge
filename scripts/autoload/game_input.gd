extends Node
## Shared pointer actions for mouse, keyboard, and touch (540p phone groundwork).

const MOVE_SLOP_PX: float = 18.0
## Second press counts as a double-tap inside this window of the first release.
const DOUBLE_TAP_MS: int = 300
const DOUBLE_TAP_PX: float = 32.0
## 3-line scroll hint (20 px per line + 18). Lore final copy lives in ui.longpress_hint.
const HOLD_HINT_SIZE: Vector2 = Vector2(200, 78)

var _touch_index: int = -1
var _touch_start_ms: int = 0
var _touch_pos: Vector2 = Vector2.ZERO
var _touch_current: Vector2 = Vector2.ZERO
var _long_press_fired: bool = false
var _hold_panel_open: bool = false
var _finger0_down: bool = false
var _moved: bool = false
var _multi: bool = false
var _gesture_dead: bool = false
var _double: bool = false
var _last_was_tap: bool = false
var _last_release_ms: int = -100000
var _last_release_pos: Vector2 = Vector2.ZERO
var _swallow_release: bool = false
var _swallowed_last_release: bool = false
var _injecting: bool = false
## Finger indexes currently down. Index 0 is the only one that owns a gesture.
var _down: Dictionary = {}


func _ready() -> void:
	_ensure_input_actions()
	for arg: String in OS.get_cmdline_user_args():
		if arg == "--emulate-touch":
			Input.emulate_touch_from_mouse = true


func long_press_wait() -> float:
	## Same wait as the mouse-rest tooltip. No second constant.
	return WorldHover.rest_sec()


func touch_mode() -> bool:
	## Phone export, or a PC launch with `-- --emulate-touch`. Not a touchscreen laptop.
	return OS.has_feature("mobile") or Input.emulate_touch_from_mouse


func is_touch_pointer(event: InputEvent) -> bool:
	if event == null:
		return false
	if event is InputEventScreenTouch or event is InputEventScreenDrag:
		return true
	if event is InputEventMouse:
		return (event as InputEventMouse).device == InputEvent.DEVICE_ID_EMULATION
	return false


func blocks_scene_mouse(event: InputEvent) -> bool:
	## Scene mouse paths ignore emulated and native touch pointers. Wheel zoom stays.
	if _injecting or not touch_mode() or not is_touch_pointer(event):
		return false
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_WHEEL_UP or mb.button_index == MOUSE_BUTTON_WHEEL_DOWN or mb.button_index == MOUSE_BUTTON_WHEEL_LEFT or mb.button_index == MOUSE_BUTTON_WHEEL_RIGHT:
			return false
	return true


func is_double_tap(event: InputEvent) -> bool:
	if not _double or not touch_mode() or event == null:
		return false
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		return mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT and mb.device == InputEvent.DEVICE_ID_EMULATION
	if event is InputEventScreenTouch:
		var touch: InputEventScreenTouch = event as InputEventScreenTouch
		return touch.pressed and touch.index == 0
	return false


func last_release_was_tap() -> bool:
	return _last_was_tap


func press_is_double_tap() -> bool:
	return _double


func long_press_did_fire() -> bool:
	return _long_press_fired


func gesture_start_ms() -> int:
	return _touch_start_ms


func primary_down() -> bool:
	return _finger0_down


func multi_touch_cancelled() -> bool:
	return _gesture_dead or _multi


func touch_pan_frozen() -> bool:
	if _multi:
		return true
	if _down.has(0):
		return _down.size() > 1
	return not _down.is_empty()


func last_release_swallowed() -> bool:
	return _swallowed_last_release


func show_hold_hint_if_needed(force: bool = false) -> bool:
	## Once per install, on a phone or a touch launch. The seen flag lives in settings.
	if not has_node("/root/GameAudio") or not has_node("/root/ContentStrings") or not has_node("/root/GameState"):
		return false
	if bool(GameAudio.get("touch_hold_hint_seen")):
		return false
	var touch: bool = force or touch_mode()
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
	if not _finger0_down or _long_press_fired or _moved or _gesture_dead or _multi:
		return
	if Time.get_ticks_msec() - _touch_start_ms >= int(long_press_wait() * 1000.0):
		_long_press_fired = true
		_swallow_release = true
		_dispatch_long_press(_touch_current)


func _input(event: InputEvent) -> void:
	if _handle_touch_event(event):
		return
	if event.is_action_pressed("game_inspect"):
		inspect_at_screen(get_viewport().get_mouse_position())


func _handle_touch_event(event: InputEvent) -> bool:
	## First finger only. A second finger cancels tap, long-press, and pan.
	if _injecting or not touch_mode() or not is_touch_pointer(event):
		return false
	if event is InputEventScreenTouch:
		var touch: InputEventScreenTouch = event as InputEventScreenTouch
		if touch.pressed:
			_note_finger_down(touch.index, touch.position)
		else:
			if _swallow_release and touch.index == 0:
				_swallow_primary_release()
			_note_finger_up(touch.index)
		return true
	if event is InputEventScreenDrag:
		var drag: InputEventScreenDrag = event as InputEventScreenDrag
		if drag.index != 0:
			if _finger0_down or not _down.is_empty():
				_multi = true
				_gesture_dead = true
			return true
		if _finger0_down:
			_note_move(drag.position)
		return true
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.button_index != MOUSE_BUTTON_LEFT:
			return false
		if mb.pressed:
			if not _finger0_down:
				_begin_primary(mb.position)
			else:
				_touch_current = mb.position
		else:
			if _swallow_release:
				_swallow_primary_release()
			if _finger0_down:
				_touch_current = mb.position
				_end_primary()
		return true
	if event is InputEventMouseMotion:
		var motion: InputEventMouseMotion = event as InputEventMouseMotion
		if _finger0_down and (motion.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
			_note_move(motion.position)
		return true
	return false


func _note_finger_down(index: int, pos: Vector2) -> void:
	if bool(_down.get(index, false)):
		return
	_down[index] = true
	if index != 0:
		_multi = true
		_gesture_dead = true
		return
	if _finger0_down:
		# Emulated mouse already started this gesture. Do not retarget the clock.
		_touch_current = pos
		return
	_begin_primary(pos)


func _note_finger_up(index: int) -> void:
	_down.erase(index)
	if index == 0:
		_end_primary()
	if _down.is_empty() and not _finger0_down:
		_multi = false
		_gesture_dead = false


func _begin_primary(pos: Vector2) -> void:
	var now: int = Time.get_ticks_msec()
	_double = false
	if not _multi and not _gesture_dead and _last_was_tap and (now - _last_release_ms) <= DOUBLE_TAP_MS and pos.distance_to(_last_release_pos) <= DOUBLE_TAP_PX:
		_double = true
	_finger0_down = true
	_touch_index = 0
	_touch_start_ms = now
	_touch_pos = pos
	_touch_current = pos
	_moved = false
	_long_press_fired = false
	_swallowed_last_release = false
	if _multi:
		_gesture_dead = true


func _note_move(pos: Vector2) -> void:
	_touch_current = pos
	if _gesture_dead or _multi:
		return
	if pos.distance_to(_touch_pos) > MOVE_SLOP_PX:
		_moved = true


func _end_primary() -> void:
	if not _finger0_down:
		return
	var elapsed: int = Time.get_ticks_msec() - _touch_start_ms
	var quick: bool = elapsed < int(long_press_wait() * 1000.0)
	var tap: bool = quick and not _moved and not _gesture_dead and not _multi and not _long_press_fired
	var pos: Vector2 = _touch_current
	_finger0_down = false
	_touch_index = -1
	_double = false
	if _hold_panel_open:
		_hold_panel_open = false
		WorldHover.dismiss_hold()
	_last_was_tap = tap
	if tap:
		_last_release_ms = Time.get_ticks_msec()
		_last_release_pos = pos
		WorldHover.cancel_pending()
		_cancel_trait_hovers()
	if _down.is_empty():
		_multi = false
		_gesture_dead = false


func _swallow_primary_release() -> void:
	_swallow_release = false
	_swallowed_last_release = true
	_unpress_hovered_button()
	var vp: Viewport = get_viewport()
	if vp != null:
		vp.set_input_as_handled()


func _unpress_hovered_button() -> void:
	var vp: Viewport = get_viewport()
	if vp == null:
		return
	var node: Node = vp.gui_get_hovered_control()
	while node != null:
		if node is BaseButton:
			(node as BaseButton).notification(Control.NOTIFICATION_MOUSE_EXIT)
			return
		node = node.get_parent()


func _cancel_trait_hovers() -> void:
	var tree: SceneTree = get_tree()
	if tree == null:
		return
	for node: Node in tree.get_nodes_in_group("character_sheet"):
		if node.has_method("cancel_trait_hover"):
			node.call("cancel_trait_hover")


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
	## Lore final body in ui.longpress_hint. Toast only if the panel cannot open.
	var text: String = "ui.longpress_hint"
	if has_node("/root/ContentStrings"):
		text = str(ContentStrings.get_text("ui.longpress_hint"))
	if WorldHover.show_anchored_hint(text, screen_pos, HOLD_HINT_SIZE):
		return true
	if has_node("/root/GameState"):
		GameState.status_message.emit(text)
	return false


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
