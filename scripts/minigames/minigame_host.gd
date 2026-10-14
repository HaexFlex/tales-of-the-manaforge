extends CanvasLayer
## Lend-a-hand overlay. The hub keeps running underneath. Nothing here is saved.

const ARRIVE_PX: float = 72.0

var _dim: ColorRect
var _panel: Panel
var _title: Label
var _pace: Label
var _hint: Label
var _close: Button
var _play: Control
var _summary: Control
var _summary_body: Label
var _done: Button
var _prompt: Button
var _game: Minigame
var _open: bool = false
var _summary_up: bool = false
var _game_id: String = ""
var _worker: String = ""
var _target_id: String = ""
var _elapsed: float = 0.0
var _pace_seconds: float = 0.0
var _earned: float = 0.0
var _successes: int = 0
var _prompt_on: bool = false
var _prompt_target: String = ""
var _prompt_world: Vector2 = Vector2.ZERO
var _walk: bool = false
var _walk_target: String = ""
var _walk_worker: String = ""
var _walk_approach: Vector2 = Vector2.ZERO
var _walk_t: float = 0.0


func _ready() -> void:
	layer = 80
	process_mode = Node.PROCESS_MODE_PAUSABLE
	_build()
	_set_open(false)


func _build() -> void:
	var root := Control.new()
	root.name = "MinigameRoot"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	_prompt = Button.new()
	_prompt.name = "LendPrompt"
	_prompt.text = "Lend a hand"
	_prompt.visible = false
	_prompt.custom_minimum_size = Vector2(168, Ui540.TAP_MIN_PX)
	_prompt.focus_mode = Control.FOCUS_NONE
	_prompt.pressed.connect(_on_prompt_pressed)
	root.add_child(_prompt)

	_dim = ColorRect.new()
	_dim.name = "Dim"
	_dim.color = Color(0.05, 0.04, 0.03, 0.45)
	_dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_dim.visible = false
	root.add_child(_dim)

	_panel = Panel.new()
	_panel.name = "Window"
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(_panel)
	Ui540.apply_kit_panel(_panel, "minigame")

	_title = Label.new()
	_title.name = "Title"
	_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(_title)

	_close = Button.new()
	_close.name = "Close"
	_panel.add_child(_close)
	Ui540.configure_kit_close_button(_close)
	_close.pressed.connect(_on_close)

	_pace = Label.new()
	_pace.name = "Pace"
	_pace.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pace.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_pace.add_theme_font_size_override("font_size", 19)
	_pace.add_theme_color_override("font_color", Color8(62, 42, 24))
	_panel.add_child(_pace)

	_hint = Label.new()
	_hint.name = "Hint"
	_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hint.add_theme_font_size_override("font_size", 19)
	_hint.add_theme_color_override("font_color", Color8(90, 62, 40))
	_panel.add_child(_hint)

	_play = Control.new()
	_play.name = "Play"
	_play.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(_play)

	_summary = TextureRect.new()
	_summary.name = "Summary"
	(_summary as TextureRect).texture = MinigameArt.texture("card.png")
	(_summary as TextureRect).expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	(_summary as TextureRect).stretch_mode = TextureRect.STRETCH_SCALE
	_summary.mouse_filter = Control.MOUSE_FILTER_STOP
	_summary.visible = false
	_panel.add_child(_summary)

	var summary_title := Label.new()
	summary_title.name = "SummaryTitle"
	summary_title.text = "Bonus"
	summary_title.position = Vector2(30, 28)
	summary_title.size = Vector2(400, 32)
	summary_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	summary_title.add_theme_color_override("font_color", Color8(62, 42, 24))
	_summary.add_child(summary_title)

	_summary_body = Label.new()
	_summary_body.name = "SummaryBody"
	_summary_body.position = Vector2(30, 74)
	_summary_body.size = Vector2(400, 130)
	_summary_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_summary_body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_summary_body.add_theme_font_size_override("font_size", 19)
	_summary_body.add_theme_color_override("font_color", Color8(62, 42, 24))
	_summary.add_child(_summary_body)

	_done = Button.new()
	_done.name = "Done"
	_done.text = "Done"
	_done.position = Vector2(44, 222)
	_done.size = Vector2(136, 52)
	_done.focus_mode = Control.FOCUS_NONE
	_done.pressed.connect(_on_done)
	_summary.add_child(_done)


func _process(delta: float) -> void:
	_refresh_prompt()
	if _walk:
		_walk_t += delta
		_tick_walk()
	if not _open or _summary_up:
		return
	_elapsed += delta
	_refresh_pace()


func show_prompt(target_id: String, world: Vector2, show: bool) -> void:
	if show:
		_prompt_target = target_id
		_prompt_world = world
		_prompt_on = true
	elif _prompt_target == target_id:
		_prompt_on = false
	_refresh_prompt()


func request(target_id: String, approach: Vector2) -> void:
	if _open:
		return
	if has_node("/root/GameState") and GameState.is_world_frozen():
		GameState.note_frozen_deny()
		return
	var game_id: String = MinigameCatalog.game_for(target_id)
	var worker: String = hero_for(target_id)
	if game_id == "" or worker == "":
		return
	_walk = true
	_walk_t = 0.0
	_walk_target = target_id
	_walk_worker = worker
	_walk_approach = approach
	var keeper: Node2D = _keeper()
	if keeper == null or keeper.global_position.distance_to(approach) <= ARRIVE_PX:
		_open_walk()
		return
	if worker == "keeper":
		_open_walk()
		return
	if keeper.has_method("move_to"):
		keeper.call("move_to", approach, null)


func hero_for(target_id: String) -> String:
	if not has_node("/root/ForgeJobs"):
		return ""
	var keeper_task: Dictionary = ForgeJobs.keeper_task()
	if bool(keeper_task.get("working", false)) and str(keeper_task.get("target", "")) == target_id:
		return "keeper"
	var elaia_task: Dictionary = ForgeJobs.elaia_task()
	if bool(elaia_task.get("working", false)) and str(elaia_task.get("target", "")) == target_id:
		return "elaia"
	return ""


func note_success(k_seconds: float) -> void:
	if not _open or _summary_up or k_seconds <= 0.0:
		return
	var result: Dictionary = MinigamePayout.grant(_worker, _game_id, _target_id, k_seconds)
	if not bool(result.get("ok", false)):
		return
	_successes += 1
	_pace_seconds += k_seconds
	_earned += float(result.get("applied", k_seconds))
	_refresh_pace()
	_spawn_pop(k_seconds)


func is_open() -> bool:
	return _open


func close_immediate() -> void:
	_walk = false
	_clear_game()
	_set_open(false)


func _tick_walk() -> void:
	if has_node("/root/GameState") and GameState.is_world_frozen():
		_walk = false
		GameState.note_frozen_deny()
		return
	var keeper: Node2D = _keeper()
	var close_enough: bool = keeper == null or keeper.global_position.distance_to(_walk_approach) <= ARRIVE_PX
	if close_enough or _walk_t >= 8.0:
		_open_walk()


func _open_walk() -> void:
	var target: String = _walk_target
	var worker: String = _walk_worker
	_walk = false
	open_game(MinigameCatalog.game_for(target), worker, target)


func open_game(game_id: String, worker: String, target_id: String) -> bool:
	if game_id == "" or (worker != "keeper" and worker != "elaia"):
		return false
	if has_node("/root/GameState") and GameState.is_world_frozen():
		GameState.note_frozen_deny()
		return false
	var packed: PackedScene = load(MinigameCatalog.scene_path(game_id)) as PackedScene
	if packed == null:
		return false
	_clear_game()
	_game_id = game_id
	_worker = worker
	_target_id = target_id
	_elapsed = 0.0
	_pace_seconds = 0.0
	_earned = 0.0
	_successes = 0
	_summary_up = false
	_layout_window()
	_title.text = MinigameCatalog.title(game_id)
	Ui540.place_title_plank(_title, _panel.size.x)
	_hint.text = MinigameCatalog.hint(game_id, Ui540.is_phone_export())
	_summary.visible = false
	var node: Node = packed.instantiate()
	_game = node as Minigame
	if _game == null:
		node.queue_free()
		return false
	_game.position = MinigameCatalog.PLAY_ORIGIN
	_game.size = MinigameCatalog.PLAY_SIZE
	_game.custom_minimum_size = MinigameCatalog.PLAY_SIZE
	_game.mouse_filter = Control.MOUSE_FILTER_STOP
	_panel.add_child(_game)
	_panel.move_child(_summary, -1)
	_game.begin()
	_set_open(true)
	_refresh_pace()
	return true


func _layout_window() -> void:
	Ui540.fit_kit_window(_panel, MinigameCatalog.WINDOW_SIZE, true)
	var sz: Vector2 = _panel.size
	Ui540.place_close_button(_close, sz.x)
	_pace.position = Vector2(sz.x - 24.0 - Ui540.TAP_MIN_PX - 120.0, 28.0)
	_pace.size = Vector2(110, 28)
	var play_h: float = minf(MinigameCatalog.PLAY_SIZE.y, sz.y - MinigameCatalog.PLAY_ORIGIN.y - 36.0)
	_play.position = MinigameCatalog.PLAY_ORIGIN
	_play.size = Vector2(MinigameCatalog.PLAY_SIZE.x, play_h)
	_hint.position = Vector2(28, sz.y - 32.0)
	_hint.size = Vector2(sz.x - 56.0, 24)
	_summary.position = ((sz - Vector2(460, 308)) * 0.5).round()
	_summary.size = Vector2(460, 308)


func _refresh_pace() -> void:
	var pace: float = MinigameMath.pace_multiplier(_pace_seconds, _elapsed)
	_pace.text = "×%.1f" % pace


func _spawn_pop(k_seconds: float) -> void:
	var pop := Label.new()
	pop.text = "+%.1fs" % k_seconds
	pop.position = MinigameCatalog.PLAY_ORIGIN + Vector2(MinigameCatalog.PLAY_SIZE.x * 0.5 - 36.0, 36.0)
	pop.size = Vector2(90, 28)
	pop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pop.z_index = 4
	pop.add_theme_font_size_override("font_size", 19)
	pop.add_theme_color_override("font_color", Color8(62, 42, 24))
	_panel.add_child(pop)
	var tw: Tween = create_tween()
	tw.tween_property(pop, "position:y", pop.position.y - 26.0, 0.55)
	tw.parallel().tween_property(pop, "modulate:a", 0.0, 0.55)
	tw.tween_callback(pop.queue_free)


func _show_summary() -> void:
	if _game != null:
		_game.shutdown()
	_summary_up = true
	var pace: float = MinigameMath.pace_multiplier(_pace_seconds, _elapsed)
	var line: String = _bonus_line()
	_summary_body.text = "%s\n%d tended\nPace ×%.1f" % [line, _successes, pace]
	_summary.visible = true


func _bonus_line() -> String:
	var kind: String = MinigameCatalog.kind(_game_id)
	if kind == "station":
		return "Bonus +%.1fs on this job" % _earned
	if kind == "water":
		return "Bonus +%.1fs of watering" % _earned
	var item: String = MinigameCatalog.resource_id(_game_id)
	if has_node("/root/ContentStrings"):
		var named: String = ContentStrings.get_text("hud_%s" % item)
		if named != "hud_%s" % item:
			item = named
	return "Bonus +%.1fs of %s" % [_earned, item]


func _on_close() -> void:
	if not _summary_up:
		_show_summary()
		return
	close_immediate()


func _on_done() -> void:
	close_immediate()


func _on_prompt_pressed() -> void:
	request(_prompt_target, _prompt_world)


func _unhandled_input(event: InputEvent) -> void:
	if not _open:
		return
	if event.is_action_pressed("ui_cancel"):
		_on_close()
		get_viewport().set_input_as_handled()
		return
	if _game != null and _game.playing and not _summary_up:
		_game.on_key(event)
		if event is InputEventMouseButton:
			var mb: InputEventMouseButton = event as InputEventMouseButton
			if not mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
				_game.on_pointer_up()


func _refresh_prompt() -> void:
	var show: bool = _prompt_on and not _open and not _walk
	if show:
		var game_id: String = MinigameCatalog.game_for(_prompt_target)
		show = game_id != "" and hero_for(_prompt_target) != ""
		if has_node("/root/GameState") and GameState.is_world_frozen():
			show = false
	_prompt.visible = show
	_prompt.mouse_filter = Control.MOUSE_FILTER_STOP if show else Control.MOUSE_FILTER_IGNORE
	if not show:
		return
	var screen: Vector2 = _screen_of(_prompt_world)
	var sz: Vector2 = _prompt.get_combined_minimum_size()
	if sz.x < 168.0:
		sz.x = 168.0
	sz.y = Ui540.TAP_MIN_PX
	_prompt.size = sz
	Ui540.fit_button_font(_prompt, sz.x)
	var vs: Vector2 = Ui540.viewport_size()
	var x: float = clampf(screen.x - sz.x * 0.5, Ui540.SAFE_MARGIN_PX, maxf(Ui540.SAFE_MARGIN_PX, vs.x - Ui540.SAFE_MARGIN_PX - sz.x))
	var y: float = clampf(screen.y - sz.y - 12.0, Ui540.SAFE_MARGIN_PX, maxf(Ui540.SAFE_MARGIN_PX, vs.y - Ui540.SAFE_MARGIN_PX - sz.y))
	_prompt.position = Vector2(x, y)


func _screen_of(world: Vector2) -> Vector2:
	var vp: Viewport = get_viewport()
	if vp == null:
		return world
	var cam: Camera2D = vp.get_camera_2d()
	if cam == null:
		return world
	return cam.get_canvas_transform() * world


func _keeper() -> Node2D:
	var tree: SceneTree = get_tree()
	if tree == null:
		return null
	return tree.get_first_node_in_group("keeper") as Node2D


func _clear_game() -> void:
	if _game != null and is_instance_valid(_game):
		_game.shutdown()
		_game.queue_free()
	_game = null


func _set_open(open: bool) -> void:
	_open = open
	_dim.visible = open
	_panel.visible = open
	if not open:
		_summary.visible = false
		_summary_up = false
		_prompt_on = false
