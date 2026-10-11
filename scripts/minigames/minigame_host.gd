class_name MinigameHost
extends CanvasLayer
## Full-screen minigame overlay (debug feel test). No payout.

signal opened(game_id: String)
signal closed(reason: StringName, result: Dictionary)

static var _instance: MinigameHost = null
static var last_refusal: String = ""

var _game_id: String = ""
var _core: MinigameCore = null
var _view: MinigameView = null
var _closing: bool = false
var _closed_emitted: bool = false
var _frame_data: Dictionary = {}
var _root_data: Dictionary = {}
var _cfg: Dictionary = {}

var _world_dim_layer: CanvasLayer
var _frame: Control
var _success_label: Label
var _pace_value_label: Label
var _pace_fill: ColorRect
var _pip_nodes: Array[TextureRect] = []
var _play_area: Control
var _paused_label: Label
var _resume_pending: bool = false


static func is_open() -> bool:
	return _instance != null and is_instance_valid(_instance)


static func current() -> MinigameHost:
	return _instance if is_instance_valid(_instance) else null


static func real_dt(delta: float, time_scale: float, max_dt: float) -> float:
	return minf(delta / maxf(time_scale, 0.0001), max_dt)


static func refusal_text(reason: String) -> String:
	match reason:
		"frozen":
			return MinigameCatalog.text("mg_refused_frozen")
		"busy", "battle":
			return MinigameCatalog.text("mg_refused_busy")
		"not_built", "disabled":
			return MinigameCatalog.text("mg_not_built")
		_:
			return MinigameCatalog.text("mg_refused_busy")


static func can_open(game_id: String) -> String:
	var game_state: Node = _autoload("GameState")
	if game_state != null and bool(game_state.call("is_world_frozen")):
		return "frozen"
	if _battle_blocks():
		return "battle"
	if _echo_portal_fee_open() or _pause_menu_open():
		return "busy"
	if not MinigameCatalog.is_built(game_id):
		return "not_built"
	var cfg: Dictionary = MinigameCatalog.game_cfg(game_id)
	if cfg.is_empty():
		return "not_built"
	if cfg.has("enabled") and not bool(cfg.get("enabled", true)):
		return "disabled"
	return ""


static func open(game_id: String, seed: int = 0) -> bool:
	var reason: String = can_open(game_id)
	if reason != "":
		last_refusal = reason
		var deny: String = str(MinigameCatalog.data().get("cues", {}).get("deny", "sfx_ui_deny"))
		_play_cue(deny)
		return false
	if is_open():
		last_refusal = "busy"
		return false
	var scene: Node = _host_parent()
	if scene == null:
		return false
	var host: MinigameHost = MinigameHost.new()
	host._game_id = game_id
	scene.add_child(host)
	return host._begin(seed)


func _init() -> void:
	layer = 60
	process_mode = Node.PROCESS_MODE_PAUSABLE
	_root_data = MinigameCatalog.data()
	_frame_data = (_root_data.get("frame", {}) as Dictionary).duplicate(true)


func _begin(seed: int) -> bool:
	_instance = self
	_cfg = MinigameCatalog.game_cfg(_game_id)
	_cfg["_game_id"] = _game_id
	_cfg["_max_pace"] = float(_root_data.get("max_pace", 3.0))
	if seed == 0:
		seed = int(_root_data.get("test_seed", 12345))
	_build_ui()
	_core = MinigameCatalog.new_core(_game_id)
	_view = MinigameCatalog.new_view(_game_id)
	if _core == null or _view == null:
		queue_free()
		_instance = null
		return false
	_core.resolved.connect(_on_resolved)
	_core.start(_cfg, seed)
	_view.bind(_core)
	_play_area.add_child(_view)
	var open_cue: String = str(_root_data.get("cues", {}).get("open", "sfx_ui_open"))
	_play_cue(open_cue)
	opened.emit(_game_id)
	return true


func step(real_dt: float) -> void:
	if _closing:
		return
	var reason: String = can_open(_game_id)
	if reason != "":
		close(StringName(reason))
		return
	if _core != null:
		_core.advance(real_dt)
	_update_hud()
	if _view != null:
		_view.queue_redraw()


func close(reason: StringName) -> void:
	if _closing:
		return
	_closing = true
	var result: Dictionary = {}
	if _core != null:
		result = _core.finish()
	if not _closed_emitted:
		_closed_emitted = true
		var close_cue: String = str(_root_data.get("cues", {}).get("close", "sfx_ui_close"))
		_play_cue(close_cue)
		closed.emit(reason, result)
	_instance = null
	queue_free()


func _process(delta: float) -> void:
	var max_dt: float = float(_root_data.get("max_frame_dt", 0.1))
	step(real_dt(delta, Engine.time_scale, max_dt))


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		if _core != null:
			_core.set_paused(true)
		if _paused_label != null:
			_paused_label.visible = true
	elif what == NOTIFICATION_WM_CLOSE_REQUEST:
		pass


func _exit_tree() -> void:
	if not _closing:
		close(&"scene_change")


func _input(event: InputEvent) -> void:
	if _resume_pending:
		_resume_pending = false
		if _core != null:
			_core.set_paused(false)
		if _paused_label != null:
			_paused_label.visible = false
		get_viewport().set_input_as_handled()
		return
	if _core != null and _core.paused and (event is InputEventKey or event is InputEventMouseButton):
		_resume_pending = true
		get_viewport().set_input_as_handled()
		return
	if event is InputEventKey:
		var key: InputEventKey = event as InputEventKey
		if key.pressed and not key.echo:
			if key.keycode == KEY_ESCAPE or key.physical_keycode == KEY_ESCAPE:
				close(&"escape")
				get_viewport().set_input_as_handled()
				return
			if _passes_debug_hotkey(key):
				return
		if _view != null and _play_area != null:
			_view.handle_input(event, _play_area.get_local_mouse_position())
		get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseButton or event is InputEventMouseMotion:
		if _is_over_minigame_ui(event):
			return
		var local: Vector2 = _event_local_in_play_area(event)
		if _play_area != null and _play_area.get_rect().has_point(local):
			if _view != null:
				_view.handle_input(event, local)
		get_viewport().set_input_as_handled()


func _on_resolved(_token_id: int, success: bool, weight: int) -> void:
	_update_hud()
	var cue_id: String = ""
	if success:
		var game_cues: Dictionary = _cfg.get("cues", {}) as Dictionary
		cue_id = str(game_cues.get("success", _root_data.get("cues", {}).get("success", "sfx_ui_confirm")))
	else:
		cue_id = str(_root_data.get("cues", {}).get("fail", "sfx_ui_cancel"))
	_play_cue(cue_id)
	if _view != null:
		_view.queue_redraw()


func _build_ui() -> void:
	_build_world_dim()
	var offset: Vector2 = _viewport_offset()
	_frame = Control.new()
	_frame.name = "FrameRoot"
	_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_frame)
	_add_nine_patch("Frame", _MG_TEX("frame_720x448.png"), _rect("frame", offset), Vector4(24, 24, 24, 24))
	_add_texture_rect("TitlePlate", _MG_TEX("title_plate_312x46.png"), _rect("title_sprite", offset))
	var title_plate_rect: Rect2 = _rect("title_plate", offset)
	var title_lbl := _make_label("Title", _title_text(), 18, Color(0.93, 0.86, 0.62))
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_lbl.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	title_lbl.position = title_plate_rect.position
	title_lbl.size = title_plate_rect.size
	_frame.add_child(title_lbl)
	var header_rect: Rect2 = _rect("header", offset)
	var flavour: String = _flavour_text()
	if flavour != "":
		var flavour_lbl := _make_label("Flavour", flavour, 13, Color(0.28, 0.22, 0.18, 0.92))
		flavour_lbl.position = header_rect.position + Vector2(180, 8)
		flavour_lbl.size = Vector2(header_rect.size.x - 360, 22)
		flavour_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_frame.add_child(flavour_lbl)
	var header := Control.new()
	header.name = "Header"
	header.position = header_rect.position
	header.size = header_rect.size
	header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_frame.add_child(header)
	_success_label = _make_label("Successes", "%s: 0" % MinigameCatalog.text("mg_successes"), 16, Color(0.93, 0.86, 0.62))
	_success_label.position = Vector2(0, 6)
	header.add_child(_success_label)
	_build_pips(header, offset)
	var pace_lbl := _make_label("PaceCaption", MinigameCatalog.text("mg_pace"), 14, Color(0.78, 0.86, 0.74))
	pace_lbl.position = Vector2(header_rect.size.x - 200, 6)
	header.add_child(pace_lbl)
	var pace_rect: Rect2 = _rect("pace_meter", offset)
	var pace_local: Vector2 = pace_rect.position - header_rect.position
	var track := TextureRect.new()
	track.name = "PaceMeter"
	track.texture = load(_MG_TEX("pace_track_136x18.png")) as Texture2D
	track.position = pace_local
	track.size = pace_rect.size
	track.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header.add_child(track)
	_pace_fill = ColorRect.new()
	_pace_fill.name = "PaceFill"
	_pace_fill.color = Color(0.46, 0.73, 0.28)
	_pace_fill.position = pace_local + Vector2(2, 2)
	_pace_fill.size = Vector2(0, pace_rect.size.y - 4)
	_pace_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header.add_child(_pace_fill)
	_pace_value_label = _make_label("PaceValue", "1.0×", 14, Color(0.93, 0.86, 0.62))
	_pace_value_label.position = pace_local + Vector2(pace_rect.size.x + 6, -2)
	header.add_child(_pace_value_label)
	_play_area = Control.new()
	_play_area.name = "PlayArea"
	var pa: Rect2 = _rect("play_area", offset)
	_play_area.position = pa.position
	_play_area.size = pa.size
	_play_area.clip_contents = true
	_frame.add_child(_play_area)
	if _game_id == "tap_test":
		var parchment := ColorRect.new()
		parchment.color = Color(0.86, 0.78, 0.62, 0.35)
		parchment.set_anchors_preset(Control.PRESET_FULL_RECT)
		_play_area.add_child(parchment)
	else:
		var bg_path: String = str(_cfg.get("play_bg", ""))
		if bg_path != "" and ResourceLoader.exists(bg_path):
			var bg := TextureRect.new()
			bg.texture = load(bg_path) as Texture2D
			bg.modulate.a = 0.35
			bg.set_anchors_preset(Control.PRESET_FULL_RECT)
			bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
			_play_area.add_child(bg)
	var footer_rect: Rect2 = _rect("footer", offset)
	var hint_key: String = str(_cfg.get("hint_key", ""))
	if _game_id == "tap_test":
		hint_key = ""
	var hint_text: String = MinigameCatalog.text(hint_key) if hint_key != "" else "Space — tap the lit target."
	var hint := _make_label("Hint", hint_text, 14, Color(0.78, 0.86, 0.74))
	hint.position = footer_rect.position + Vector2(20, 8)
	hint.size = Vector2(footer_rect.size.x - 40, 24)
	_frame.add_child(hint)
	var tag := _make_label("FeelTag", MinigameCatalog.text("mg_feel_test_tag"), 12, Color(0.68, 0.72, 0.66))
	tag.position = footer_rect.position + Vector2(footer_rect.size.x - 220, 10)
	tag.size = Vector2(200, 20)
	tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_frame.add_child(tag)
	_build_stop_button(_rect("stop_button", offset))
	_paused_label = _make_label("PausedLabel", MinigameCatalog.text("mg_paused"), 20, Color(0.93, 0.86, 0.62))
	_paused_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_paused_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_paused_label.set_anchors_preset(Control.PRESET_CENTER)
	_paused_label.size = Vector2(400, 48)
	_paused_label.visible = false
	add_child(_paused_label)


func _build_world_dim() -> void:
	_world_dim_layer = CanvasLayer.new()
	_world_dim_layer.name = "WorldDim"
	_world_dim_layer.layer = 19
	add_child(_world_dim_layer)
	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var alpha: float = float(_frame_data.get("dim_alpha", 0.58))
	var desat: float = float(_frame_data.get("dim_desaturate", 0.25))
	var shader_text: String = """
shader_type canvas_item;
render_mode unshaded;
uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform float dim_alpha : hint_range(0.0, 1.0) = 0.58;
uniform float dim_desaturate : hint_range(0.0, 1.0) = 0.25;
void fragment() {
	vec4 bg = texture(screen_texture, SCREEN_UV);
	float l = dot(bg.rgb, vec3(0.299, 0.587, 0.114));
	vec3 desat = mix(bg.rgb, vec3(l), dim_desaturate);
	vec3 final = mix(desat, vec3(0.0), dim_alpha);
	COLOR = vec4(final, 1.0);
}
"""
	var shader: Shader = Shader.new()
	shader.code = shader_text
	var mat: ShaderMaterial = ShaderMaterial.new()
	mat.shader = shader
	mat.set_shader_parameter("dim_alpha", alpha)
	mat.set_shader_parameter("dim_desaturate", desat)
	dim.material = mat
	_world_dim_layer.add_child(dim)


func _build_pips(header: Control, offset: Vector2) -> void:
	var pips: Dictionary = _frame_data.get("pips", {}) as Dictionary
	var count: int = int(pips.get("count", 10))
	var pitch: int = int(pips.get("pitch", 15))
	var start_x: float = float(pips.get("x", 320)) - header.position.x + offset.x - offset.x
	start_x = float(pips.get("x", 320)) - _rect("header", offset).position.x
	var center_y: float = float(pips.get("center_y", 178)) - _rect("header", offset).position.y
	var box := HBoxContainer.new()
	box.name = "Pips"
	box.position = Vector2(start_x, center_y - 6)
	box.add_theme_constant_override("separation", pitch - 12)
	header.add_child(box)
	var empty_tex: Texture2D = load(_MG_TEX("pip_empty_12.png")) as Texture2D
	var good_tex: Texture2D = load(_MG_TEX("pip_good_12.png")) as Texture2D
	var perfect_tex: Texture2D = load(_MG_TEX("pip_perfect_12.png")) as Texture2D
	var miss_tex: Texture2D = load(_MG_TEX("pip_miss_12.png")) as Texture2D
	_pip_nodes.clear()
	for _i: int in count:
		var pip := TextureRect.new()
		pip.custom_minimum_size = Vector2(12, 12)
		pip.texture = empty_tex
		pip.set_meta("empty", empty_tex)
		pip.set_meta("good", good_tex)
		pip.set_meta("perfect", perfect_tex)
		pip.set_meta("miss", miss_tex)
		box.add_child(pip)
		_pip_nodes.append(pip)


func _build_stop_button(rect: Rect2) -> void:
	var btn := TextureButton.new()
	btn.name = "StopButton"
	btn.position = rect.position
	btn.size = rect.size
	btn.texture_normal = load(_MG_TEX("stop_button_normal_104x28.png")) as Texture2D
	btn.texture_hover = load(_MG_TEX("stop_button_hover_104x28.png")) as Texture2D
	btn.texture_pressed = load(_MG_TEX("stop_button_pressed_104x28.png")) as Texture2D
	btn.texture_disabled = load(_MG_TEX("stop_button_disabled_104x28.png")) as Texture2D
	btn.add_to_group("minigame_ui")
	btn.pressed.connect(func() -> void: close(&"stop"))
	var lbl := _make_label("StopLabel", MinigameCatalog.text("mg_stop"), 14, Color(0.93, 0.86, 0.62))
	lbl.position = Vector2(8, 4)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(lbl)
	var cap := TextureRect.new()
	cap.texture = load(_MG_TEX("keycap_esc.png")) as Texture2D
	cap.position = Vector2(rect.size.x - 28, 4)
	cap.custom_minimum_size = Vector2(24, 20)
	cap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(cap)
	_frame.add_child(btn)


func _update_hud() -> void:
	if _core == null:
		return
	_success_label.text = "%s: %d" % [MinigameCatalog.text("mg_successes"), _core.successes]
	var pace: float = _core.pace()
	_pace_value_label.text = "%.1f×" % pace
	var max_pace: float = float(_root_data.get("max_pace", 3.0))
	var track_w: float = _rect("pace_meter", _viewport_offset()).size.x - 4.0
	var frac: float = (pace - 1.0) / maxf(max_pace - 1.0, 0.001)
	_pace_fill.size.x = maxf(0.0, track_w * clampf(frac, 0.0, 1.0))
	_pace_fill.color = Color(0.95, 0.76, 0.31) if pace >= 2.95 else Color(0.46, 0.73, 0.28)
	var results: Array = _core.last_results
	var offset: int = maxi(0, results.size() - _pip_nodes.size())
	for i: int in _pip_nodes.size():
		var pip: TextureRect = _pip_nodes[i]
		var idx: int = offset + i
		var tex: Texture2D = pip.get_meta("empty") as Texture2D
		if idx < results.size():
			var code: int = int(results[idx])
			if code == 2:
				tex = pip.get_meta("perfect") as Texture2D
			elif code == 1:
				tex = pip.get_meta("good") as Texture2D
			elif code == 0:
				tex = pip.get_meta("miss") as Texture2D
		pip.texture = tex


func _viewport_offset() -> Vector2:
	var vp: Vector2 = get_viewport().get_visible_rect().size
	return ((vp - Vector2(1280, 720)) / 2.0).floor()


func _rect(key: String, offset: Vector2) -> Rect2:
	var arr: Array = _frame_data.get(key, []) as Array
	if arr.size() != 4:
		return Rect2()
	return Rect2(
		Vector2(float(arr[0]), float(arr[1])) + offset,
		Vector2(float(arr[2]), float(arr[3]))
	)


static func _MG_TEX(file: String) -> String:
	return "res://assets/art/ui/minigames/placeholder/kit/%s" % file


func _add_nine_patch(node_name: String, tex_path: String, rect: Rect2, margin: Vector4) -> void:
	var np := NinePatchRect.new()
	np.name = node_name
	np.texture = load(tex_path) as Texture2D
	np.position = rect.position
	np.size = rect.size
	np.patch_margin_left = int(margin.x)
	np.patch_margin_top = int(margin.y)
	np.patch_margin_right = int(margin.z)
	np.patch_margin_bottom = int(margin.w)
	np.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_frame.add_child(np)


func _add_texture_rect(node_name: String, tex_path: String, rect: Rect2) -> void:
	var tr := TextureRect.new()
	tr.name = node_name
	tr.texture = load(tex_path) as Texture2D
	tr.position = rect.position
	tr.size = rect.size
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_frame.add_child(tr)


func _make_label(node_name: String, text: String, font_size: int, color: Color) -> Label:
	var lbl := Label.new()
	lbl.name = node_name
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", font_size)
	lbl.add_theme_color_override("font_color", color)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return lbl


func _title_text() -> String:
	if _game_id == "tap_test":
		return "Tap test"
	var key: String = str(_cfg.get("name_key", ""))
	if key == "":
		return _game_id
	return MinigameCatalog.text(key)


func _flavour_text() -> String:
	var key: String = str(_cfg.get("flavour_key", ""))
	if key == "":
		return ""
	return MinigameCatalog.text(key)


func _event_local_in_play_area(event: InputEvent) -> Vector2:
	if _play_area == null:
		return Vector2.ZERO
	var pos: Vector2 = event.position
	if event is InputEventMouse:
		pos = (event as InputEventMouse).position
	return _play_area.get_global_transform_with_canvas().affine_inverse() * pos


func _is_over_minigame_ui(event: InputEvent) -> bool:
	var pos: Vector2 = event.position
	for node: Node in get_tree().get_nodes_in_group("minigame_ui"):
		if node is Control and (node as Control).get_global_rect().has_point(pos):
			return true
	return false


static func _pause_menu_open() -> bool:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null:
		return false
	for node: Node in tree.get_nodes_in_group("pause_menu"):
		if node.has_method("is_open") and bool(node.call("is_open")):
			return true
	return false


static func _battle_blocks() -> bool:
	var echo: Node = _autoload("EchoChamber")
	if echo != null and bool(echo.get("in_battle")):
		return true
	var reach: Node = _autoload("Reach")
	if reach != null and reach.has_method("fight_active") and bool(reach.call("fight_active")):
		return true
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree != null and tree.root.get_node_or_null("ReachFightView") != null:
		return true
	for entry: Dictionary in ProjectSettings.get_global_class_list():
		if str(entry.get("class", "")) != "BattleView":
			continue
		var path: String = str(entry.get("path", ""))
		if path == "":
			continue
		var script: Script = load(path) as Script
		if script == null:
			continue
		if script.has_method("is_open") and bool(script.call("is_open")):
			return true
	return false


static func _passes_debug_hotkey(key: InputEventKey) -> bool:
	if key.keycode == KEY_F9:
		return true
	return key.keycode == KEY_F8 and key.ctrl_pressed


static func _host_parent() -> Node:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null:
		return null
	if tree.current_scene != null:
		return tree.current_scene
	for child: Node in tree.root.get_children():
		var script: Script = child.get_script() as Script
		if script != null:
			var path: String = script.resource_path
			if path.ends_with("main.gd") or path.ends_with("forge_room.gd"):
				return child
	return null


static func _autoload(name: String) -> Node:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null:
		return null
	return tree.root.get_node_or_null(name)


static func _echo_portal_fee_open() -> bool:
	var portal_script: Script = load("res://scripts/echo_portal.gd") as Script
	if portal_script != null and portal_script.has_method("is_fee_confirm_open"):
		return bool(portal_script.call("is_fee_confirm_open"))
	return false


static func _play_cue(cue_id: String) -> void:
	var audio: Node = _autoload("GameAudio")
	if audio != null and audio.has_method("play"):
		audio.call("play", StringName(cue_id))
