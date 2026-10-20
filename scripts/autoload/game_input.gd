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
## The emulated mouse echo of a touch double arrives after _double has cleared.
var _double_echo: bool = false
var _double_echo_pos: Vector2 = Vector2.ZERO
var _last_was_tap: bool = false
var _last_release_ms: int = -100000
var _last_release_pos: Vector2 = Vector2.ZERO
var _swallow_release: bool = false
var _swallowed_last_release: bool = false
var _injecting: bool = false
var _defer_gen: int = 0
var _marquee_armed: bool = false
## Finger indexes currently down. Index 0 is the only one that owns a gesture.
var _down: Dictionary = {}
var _back_frame: int = -1


func _ready() -> void:
	_ensure_input_actions()
	_install_android_back()
	for arg: String in OS.get_cmdline_user_args():
		if arg == "--emulate-touch":
			Input.emulate_touch_from_mouse = true


func _install_android_back() -> void:
	var tree: SceneTree = get_tree()
	if tree == null:
		return
	## The default handler quits on the signal. Modals have to close first.
	tree.quit_on_go_back = false
	var root: Window = tree.root
	if root == null:
		return
	if not root.go_back_requested.is_connected(on_android_back):
		root.go_back_requested.connect(on_android_back)
	## notification() on the root does not emit go_back_requested, and it is not
	## delivered to children. A script on the window itself sees it.
	if root.get_script() == null:
		var back_script: Script = load("res://scripts/ui/root_back.gd") as Script
		if back_script != null:
			root.set_script(back_script)


func on_android_back() -> void:
	var tree: SceneTree = get_tree()
	if tree == null:
		return
	tree.quit_on_go_back = false
	var frame: int = Engine.get_process_frames()
	if frame == _back_frame:
		return
	_back_frame = frame
	if _dismiss_back_modal(tree.root):
		return
	tree.quit()


func _dismiss_back_modal(node: Node) -> bool:
	if node is KitDialog:
		var dialog: KitDialog = node as KitDialog
		if dialog.is_visible_in_tree():
			dialog.cancel()
			return true
	if node is PauseMenu:
		var menu: PauseMenu = node as PauseMenu
		if menu.visible and menu.dismiss_for_back():
			return true
	if node != null and node.has_method("is_open") and node.has_method("close_immediate") and str(node.name) == "MinigameHost":
		if bool(node.call("is_open")):
			node.call("close_immediate")
			return true
	for child: Node in node.get_children():
		if _dismiss_back_modal(child):
			return true
	return false


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
	if not touch_mode() or event == null:
		return false
	if _double:
		if event is InputEventMouseButton:
			var live: InputEventMouseButton = event as InputEventMouseButton
			if live.pressed and live.button_index == MOUSE_BUTTON_LEFT and live.device == InputEvent.DEVICE_ID_EMULATION:
				return true
		elif event is InputEventScreenTouch:
			var touch: InputEventScreenTouch = event as InputEventScreenTouch
			if touch.pressed and touch.index == 0:
				return true
	return _is_double_echo(event)


func _is_double_echo(event: InputEvent) -> bool:
	if not _double_echo or not (event is InputEventMouseButton):
		return false
	var echo: InputEventMouseButton = event as InputEventMouseButton
	if not echo.pressed or echo.button_index != MOUSE_BUTTON_LEFT or echo.device != InputEvent.DEVICE_ID_EMULATION:
		return false
	return echo.position.distance_to(_double_echo_pos) <= DOUBLE_TAP_PX


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


func arm_touch_marquee() -> void:
	if touch_mode():
		_marquee_armed = true


func disarm_touch_marquee() -> void:
	_marquee_armed = false


func touch_marquee_armed() -> bool:
	return touch_mode() and _marquee_armed


func touch_drag_phase(event: InputEvent) -> String:
	if event is InputEventScreenTouch:
		var touch: InputEventScreenTouch = event as InputEventScreenTouch
		if touch.index != 0:
			return ""
		return "press" if touch.pressed else "release"
	if event is InputEventScreenDrag:
		var drag: InputEventScreenDrag = event as InputEventScreenDrag
		return "move" if drag.index == 0 else ""
	if not is_touch_pointer(event):
		return ""
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.button_index != MOUSE_BUTTON_LEFT:
			return ""
		return "press" if mb.pressed else "release"
	if event is InputEventMouseMotion:
		var motion: InputEventMouseMotion = event as InputEventMouseMotion
		if (motion.button_mask & MOUSE_BUTTON_MASK_LEFT) == 0:
			return ""
		return "move"
	return ""


func touch_pan_frozen() -> bool:
	if _multi:
		return true
	if _down.has(0):
		return _down.size() > 1
	return not _down.is_empty()


func touch_pan_delta(event: InputEvent) -> Vector2:
	## Screen pixels to pan once the first finger leaves the slop. Zero while pinched.
	if not touch_mode() or _injecting or touch_pan_frozen() or not _finger0_down or _gesture_dead or _long_press_fired:
		return Vector2.ZERO
	var relative := Vector2.ZERO
	var pos := _touch_current
	if event is InputEventScreenDrag:
		var drag: InputEventScreenDrag = event as InputEventScreenDrag
		if drag.index != 0:
			return Vector2.ZERO
		relative = drag.relative
		pos = drag.position
	elif event is InputEventMouseMotion and is_touch_pointer(event):
		var motion: InputEventMouseMotion = event as InputEventMouseMotion
		if (motion.button_mask & MOUSE_BUTTON_MASK_LEFT) == 0:
			return Vector2.ZERO
		relative = motion.relative
		pos = motion.position
	else:
		return Vector2.ZERO
	if not _moved and pos.distance_to(_touch_pos) <= MOVE_SLOP_PX:
		return Vector2.ZERO
	return relative


func last_release_swallowed() -> bool:
	return _swallowed_last_release


func yields_touch_double_tap(event: InputEvent) -> bool:
	## The second tap falls through so the world can turn it into a right-click.
	return is_double_tap(event)


func defer_touch_tap(action: Callable) -> void:
	## Touch openers wait 280 ms so a second tap can cancel the left action.
	if not action.is_valid():
		return
	if not touch_mode():
		action.call()
		return
	_defer_gen += 1
	var token: int = _defer_gen
	var timer: SceneTreeTimer = get_tree().create_timer(0.28)
	timer.timeout.connect(func() -> void:
		if token != _defer_gen or not action.is_valid():
			return
		action.call()
	)


func inject_right_click(screen_pos: Vector2) -> void:
	## Synthetic right-click, device 0, so the existing command paths run.
	## screen_pos is already the viewport point the touch landed on. push_input()
	## otherwise runs it through the stretch inverse again, so on a 2× window the
	## click misses every world Area2D. The real mouse is still on the node, so
	## the ground path bails out and the double-tap does nothing.
	var vp: Viewport = get_viewport()
	if vp == null:
		return
	_injecting = true
	var motion := InputEventMouseMotion.new()
	motion.device = 0
	motion.position = screen_pos
	motion.global_position = screen_pos
	vp.push_input(motion, true)
	var press := InputEventMouseButton.new()
	press.device = 0
	press.button_index = MOUSE_BUTTON_RIGHT
	press.pressed = true
	press.button_mask = MOUSE_BUTTON_MASK_RIGHT
	press.position = screen_pos
	press.global_position = screen_pos
	vp.push_input(press, true)
	var release: InputEventMouseButton = press.duplicate() as InputEventMouseButton
	release.pressed = false
	release.button_mask = 0
	vp.push_input(release, true)
	_injecting = false


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
		# Godot 4.7 defaults a mouse event to DEVICE_ID_MOUSE (32) and rewrites a
		# stored device 0 into that. Matching does not rewrite an incoming event,
		# so device 0 would miss. -1 is InputMap's all-devices id and still matches 32.
		rmb.device = -1
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
			if _is_double_echo(mb):
				# Echo of the touch double. Do not start another tap.
				return true
			if not _finger0_down:
				_begin_primary(mb.position)
			else:
				_touch_current = mb.position
		else:
			var echo_release: bool = _double_echo and not _finger0_down
			if _swallow_release:
				_swallow_primary_release()
			if _finger0_down:
				_touch_current = mb.position
				_end_primary()
			if echo_release:
				_double_echo = false
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
	_double_echo = false
	if not _multi and not _gesture_dead and _last_was_tap and (now - _last_release_ms) <= DOUBLE_TAP_MS and pos.distance_to(_last_release_pos) <= DOUBLE_TAP_PX:
		_double = true
		_double_echo = true
		_double_echo_pos = pos
		_defer_gen += 1
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
	_unpress_control(vp.gui_get_hovered_control())
	_unpress_control(_control_at(_touch_current))


func _unpress_control(ctrl: Control) -> void:
	var node: Node = ctrl
	while node != null:
		if node is BaseButton:
			var button: BaseButton = node as BaseButton
			# Mouse exit only clears the hover. The pressed look is press_attempt,
			# which scroll-begin drops without emitting pressed.
			button.notification(Control.NOTIFICATION_MOUSE_EXIT)
			button.notification(Control.NOTIFICATION_SCROLL_BEGIN)
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
	if event is InputEventMouse:
		return (event as InputEventMouse).position
	if event is InputEventScreenTouch:
		return (event as InputEventScreenTouch).position
	if event is InputEventScreenDrag:
		return (event as InputEventScreenDrag).position
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
	## Fires only after long_press_wait() (0.8 s). Hover only: no walk, no press.
	_preview_gear_under(screen_pos)
	var tip: String = _tooltip_at_screen(screen_pos)
	if tip != "":
		_hold_panel_open = WorldHover.show_anchored_hint(tip, screen_pos, _anchored_size(tip))
		return
	var source: Node = _world_named_at(screen_pos)
	if source == null:
		return
	var world_name: String = str(source.call("world_hover_name")).strip_edges()
	if world_name == "":
		return
	WorldHover.present(source, world_name)
	WorldHover.complete_rest()
	_hold_panel_open = true


func _preview_gear_under(screen_pos: Vector2) -> void:
	## A gear row's tip would return before the compare preview. Set it first.
	if not touch_mode():
		return
	var node: Node = _control_at(screen_pos)
	while node != null:
		var raw: Variant = node.get("item_id")
		var host: Variant = node.get("host")
		if raw is String and str(raw) != "" and host is Node and (host as Node).has_method("set_hover_item"):
			(host as Node).call("set_hover_item", str(raw))
			return
		node = node.get_parent()


func _anchored_size(text: String) -> Vector2:
	var lines: int = maxi(1, text.count("\n") + 1)
	var height: float = maxf(Ui540.TOOLTIP_MIN_H, float(lines) * 20.0 + 18.0)
	return Vector2(HOLD_HINT_SIZE.x, height)


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
	if hovered == null or not _control_contains(hovered, screen_pos):
		hovered = _control_at(screen_pos)
	if hovered == null:
		return ""
	var node: Node = hovered
	while node != null:
		if node is Control:
			var ctrl: Control = node as Control
			var custom: String = _custom_tooltip_text(ctrl)
			if custom != "":
				return custom
			if str(ctrl.tooltip_text).strip_edges() != "":
				return str(ctrl.tooltip_text)
		node = node.get_parent()
	return ""


func _custom_tooltip_text(ctrl: Control) -> String:
	## Forge recipe rows build their tip in _make_custom_tooltip. Use that text.
	if ctrl == null or not ctrl.has_method("_make_custom_tooltip"):
		return ""
	var made: Variant = ctrl.call("_make_custom_tooltip", ctrl.tooltip_text)
	var text := ""
	if made is Node:
		text = _plain_from_tooltip(made as Node)
		(made as Node).free()
	return text.strip_edges()


func _plain_from_tooltip(node: Node) -> String:
	if node is RichTextLabel:
		return _strip_bbcode((node as RichTextLabel).text)
	if node is Label:
		return (node as Label).text
	for child: Node in node.get_children():
		var nested: String = _plain_from_tooltip(child)
		if nested != "":
			return nested
	return ""


func _strip_bbcode(text: String) -> String:
	var rx := RegEx.new()
	if rx.compile("\\[[^\\]]*\\]") != OK:
		return text
	return rx.sub(text, "", true)


func _control_at(screen_pos: Vector2) -> Control:
	var vp: Viewport = get_viewport()
	if vp == null:
		return null
	return _deepest_control(vp, screen_pos)


func _deepest_control(node: Node, screen_pos: Vector2) -> Control:
	var found: Control = null
	for child: Node in node.get_children():
		var nested: Control = _deepest_control(child, screen_pos)
		if nested != null:
			found = nested
	if found != null:
		return found
	if node is Control and _control_contains(node as Control, screen_pos):
		return node as Control
	return null


func _control_contains(ctrl: Control, screen_pos: Vector2) -> bool:
	if ctrl == null or not ctrl.visible or ctrl.mouse_filter == Control.MOUSE_FILTER_IGNORE:
		return false
	return ctrl.get_global_rect().has_point(screen_pos)


func _world_named_at(screen_pos: Vector2) -> Node:
	var vp: Viewport = get_viewport()
	if vp == null or vp.world_2d == null:
		return null
	var space: PhysicsDirectSpaceState2D = vp.world_2d.direct_space_state
	if space == null:
		return null
	var query := PhysicsPointQueryParameters2D.new()
	query.position = _screen_to_world(screen_pos)
	query.collide_with_areas = true
	query.collide_with_bodies = false
	query.collision_mask = 0x7FFFFFFF
	var hits: Array[Dictionary] = space.intersect_point(query, 16)
	for hit: Dictionary in hits:
		var collider: Variant = hit.get("collider")
		if collider is Node and (collider as Node).has_method("world_hover_name"):
			if str((collider as Node).call("world_hover_name")).strip_edges() != "":
				return collider as Node
	return null


func _screen_to_world(screen_pos: Vector2) -> Vector2:
	var vp: Viewport = get_viewport()
	if vp == null:
		return screen_pos
	return vp.get_canvas_transform().affine_inverse() * screen_pos


func configure_scroll_container(scroll: ScrollContainer) -> void:
	scroll.scroll_deadzone = 12
	scroll.follow_focus = false
	if scroll.has_method("set_drag_and_drop_enabled"):
		scroll.set_drag_and_drop_enabled(false)
