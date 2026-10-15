extends CanvasLayer
## Lend-a-hand overlay. The hub keeps running underneath. Nothing here is saved.

const ARRIVE_PX: float = 72.0
## The resource chips occupy the top 64 px. The window, plank included, starts under that.
const HUD_BAR_PX: float = 64.0
## card.png parchment starts at x=40. Text sits 16 px inside that, clear of the wood.
const SUMMARY_COVER := Rect2(42, 46, 376, 166)
const SUMMARY_BODY := Rect2(56, 58, 348, 142)
const SUMMARY_BTN := Vector2(160, 52)
const SUMMARY_BTN_X: float = 62.0
const SUMMARY_BTN_Y: float = 222.0
const SUMMARY_BTN_GAP: float = 16.0
## Shortcut row is the 44 px buttons sat on the 24 px safe margin. The window stays above it.
const HUD_SHORTCUT_GAP: float = 6.0
const HEADER_ROW_Y: float = 20.0
const HEADER_ROW_H: float = 22.0
const PIP_PX: float = 19.0
const PIP_STEP: float = 22.0
const PACE_BAR_H: float = 8.0
const PACE_TICK_H: float = 16.0
const PARCHMENT: Color = Color8(231, 212, 166)

var _dim: ColorRect
var _panel: Panel
var _title: Label
var _succ_word: Label
var _succ_count: Label
var _pace_word: Label
var _pace: Label
var _pace_bar: ColorRect
var _pace_fill: TextureRect
var _flavour: Label
var _hint: Label
var _close: BaseButton
var _play: Control
var _summary: Control
var _summary_body: Label
var _summary_rows: Array[Label] = []
var _done: BaseButton
var _again: BaseButton
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
var _misses: int = 0
var _streak: int = 0
var _best_streak: int = 0
var _grades: Array[int] = []
var _pips: Array[TextureRect] = []
var _card_pips: Array[TextureRect] = []
var _win_plate: TextureRect
var _plate_footer_cover: ColorRect
var _plate_header_cover: ColorRect
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
	_dim.color = Color(0.05, 0.04, 0.03, 0.58)
	_dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_dim.visible = false
	root.add_child(_dim)

	_panel = Panel.new()
	_panel.name = "Window"
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(_panel)
	Ui540.apply_kit_panel(_panel, "minigame")
	_win_plate = TextureRect.new()
	_win_plate.name = "WinPlate"
	_win_plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_win_plate.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_win_plate.stretch_mode = TextureRect.STRETCH_SCALE
	_win_plate.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_panel.add_child(_win_plate)
	## The plate bakes the flavour, the old instruction, and "Feel test: no rewards."
	## across the footer. Cover that whole band. The live hint is the only line that remains.
	_plate_footer_cover = ColorRect.new()
	_plate_footer_cover.name = "FeelTestCover"
	_plate_footer_cover.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_plate_footer_cover.color = PARCHMENT
	_plate_footer_cover.anchor_left = 12.0 / 696.0
	_plate_footer_cover.anchor_top = 406.0 / 472.0
	_plate_footer_cover.anchor_right = 684.0 / 696.0
	_plate_footer_cover.anchor_bottom = 448.0 / 472.0
	_plate_footer_cover.offset_left = 0.0
	_plate_footer_cover.offset_top = 0.0
	_plate_footer_cover.offset_right = 0.0
	_plate_footer_cover.offset_bottom = 0.0
	_win_plate.add_child(_plate_footer_cover)
	## Baked Successes / Pace / pace bar, so the live 19 px header is not drawn twice.
	_plate_header_cover = ColorRect.new()
	_plate_header_cover.name = "HeaderCover"
	_plate_header_cover.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_plate_header_cover.color = PARCHMENT
	_plate_header_cover.anchor_left = 14.0 / 696.0
	_plate_header_cover.anchor_top = 26.0 / 472.0
	_plate_header_cover.anchor_right = 616.0 / 696.0
	_plate_header_cover.anchor_bottom = 52.0 / 472.0
	_plate_header_cover.offset_left = 0.0
	_plate_header_cover.offset_top = 0.0
	_plate_header_cover.offset_right = 0.0
	_plate_header_cover.offset_bottom = 0.0
	_win_plate.add_child(_plate_header_cover)

	_title = Label.new()
	_title.name = "Title"
	_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(_title)

	var closer := TextureButton.new()
	closer.name = "Close"
	closer.texture_normal = MinigameArt.texture("close_n.png")
	closer.texture_hover = MinigameArt.texture("close_h.png")
	closer.texture_pressed = MinigameArt.texture("close_h.png")
	closer.ignore_texture_size = true
	closer.stretch_mode = TextureButton.STRETCH_KEEP
	closer.focus_mode = Control.FOCUS_NONE
	closer.tooltip_text = "Close"
	closer.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_close = closer
	_panel.add_child(_close)
	_close.pressed.connect(_on_close)

	_succ_word = _ink_label("Successes", "Successes")
	_succ_count = _ink_label("0", "SuccessCount")
	_pace_word = _ink_label("Pace", "PaceWord")
	_pace = _ink_label("×1.0", "Pace")
	_pace.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_panel.add_child(_succ_word)
	_panel.add_child(_succ_count)
	_panel.add_child(_pace_word)
	_panel.add_child(_pace)
	_pace_bar = ColorRect.new()
	_pace_bar.name = "PaceBar"
	_pace_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pace_bar.color = Color8(52, 36, 24)
	_pace_bar.z_index = 4
	_panel.add_child(_pace_bar)
	_pace_fill = TextureRect.new()
	_pace_fill.name = "Fill"
	_pace_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pace_fill.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_pace_fill.stretch_mode = TextureRect.STRETCH_SCALE
	_pace_fill.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_pace_fill.z_index = 1
	_pace_bar.add_child(_pace_fill)
	for i: int in 3:
		var tick := ColorRect.new()
		tick.name = "Tick%d" % i
		tick.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tick.color = Color8(62, 42, 24)
		tick.size = Vector2(3, PACE_TICK_H)
		tick.z_index = 2
		_pace_bar.add_child(tick)
	_pips = _make_pips(_panel, Vector2(128, 34), PIP_PX, PIP_STEP)

	_flavour = Label.new()
	_flavour.name = "Flavour"
	_flavour.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_flavour.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_flavour.visible = false
	_flavour.z_index = 5
	GameTheme.style_ink_label(_flavour, true)
	_panel.add_child(_flavour)

	_hint = Label.new()
	_hint.name = "Hint"
	_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_hint.z_index = 5
	GameTheme.style_ink_label(_hint, true)
	_panel.add_child(_hint)

	_play = Control.new()
	_play.name = "Play"
	_play.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_play.clip_contents = true
	_panel.add_child(_play)

	_summary = TextureRect.new()
	_summary.name = "Summary"
	(_summary as TextureRect).texture = MinigameArt.texture("card.png")
	(_summary as TextureRect).expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	(_summary as TextureRect).stretch_mode = TextureRect.STRETCH_SCALE
	_summary.mouse_filter = Control.MOUSE_FILTER_STOP
	_summary.visible = false
	_summary.z_index = 20
	_panel.add_child(_summary)
	## card.png bakes an empty Successes/Misses list and "Feel test: no rewards."
	## at about (168, 176). The parchment cover leaves one summary, inside the frame.
	var cover := ColorRect.new()
	cover.name = "Parchment"
	cover.color = Color8(231, 212, 166)
	cover.position = SUMMARY_COVER.position
	cover.size = SUMMARY_COVER.size
	cover.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_summary.add_child(cover)

	_summary_body = _summary_line("SummaryBody", 48.0)
	_summary_body.size = Vector2(364, 34)
	_summary_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_summary_body.clip_text = false
	_summary.add_child(_summary_body)
	_summary_rows = [
		_summary_line("RowSuccesses", 86.0),
		_summary_line("RowMisses", 108.0),
		_summary_line("RowStreak", 130.0),
		_summary_line("RowPace", 152.0),
		_summary_line("RowBonus", 174.0),
	]
	for row: Label in _summary_rows:
		_summary.add_child(row)

	_done = _summary_button("Done", "btn_done_n.png", "btn_done_h.png")
	_done.position = Vector2(SUMMARY_BTN_X, SUMMARY_BTN_Y)
	_done.pressed.connect(_on_done)
	_summary.add_child(_done)
	_again = _summary_button("PlayAgain", "btn_again_n.png", "btn_again_h.png")
	_again.position = Vector2(SUMMARY_BTN_X + SUMMARY_BTN.x + SUMMARY_BTN_GAP, SUMMARY_BTN_Y)
	_again.pressed.connect(_on_again)
	_summary.add_child(_again)
	_card_pips = _make_pips(_summary, Vector2(155, 198), 12.0, 15.0)


func _summary_line(node_name: String, y: float) -> Label:
	var lbl := Label.new()
	lbl.name = node_name
	lbl.position = Vector2(48, y)
	lbl.size = Vector2(364, 22)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.clip_text = true
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl.z_index = 2
	GameTheme.style_ink_label(lbl)
	return lbl


func _ink_label(text: String, node_name: String) -> Label:
	var lbl := Label.new()
	lbl.name = node_name
	lbl.text = text
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.z_index = 5
	GameTheme.style_ink_label(lbl)
	return lbl


func _make_pips(parent: Node, origin: Vector2, pip_px: float, step: float) -> Array[TextureRect]:
	var out: Array[TextureRect] = []
	for i: int in 10:
		var pip := TextureRect.new()
		pip.name = "GradePip%d" % i
		pip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pip.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		pip.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		pip.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		pip.position = origin + Vector2(float(i) * step, 0.0)
		pip.size = Vector2(pip_px, pip_px)
		pip.z_index = 6
		parent.add_child(pip)
		out.append(pip)
	return out


## Win plates are the window backdrop for the whole session (package README:
## full-size window plates). The result state is the card, not a second plate.
func _apply_win_plate(game_id: String) -> void:
	if _win_plate == null:
		return
	var live_text: bool = MinigameCatalog.plate_draws_live_text(game_id)
	if _plate_footer_cover != null:
		_plate_footer_cover.visible = not live_text
	if _plate_header_cover != null:
		_plate_header_cover.visible = not live_text
	var suffix: String = "ph" if Ui540.is_phone_export() else "pc"
	var tex: Texture2D = MinigameArt.texture("win_%s_%s.png" % [game_id, suffix])
	if tex == null:
		_win_plate.texture = null
		return
	var atlas := AtlasTexture.new()
	atlas.atlas = tex
	atlas.region = Rect2(132, 44, 696, 472)
	_win_plate.texture = atlas


func _push_grade(grade: int) -> void:
	_grades.append(clampi(grade, 0, 2))
	while _grades.size() > 10:
		_grades.remove_at(0)
	_paint_grades()


func _paint_grades() -> void:
	for i: int in 10:
		var grade: int = _grades[i] if i < _grades.size() else -1
		var file: String = "pip_empty.png"
		if grade == 0:
			file = "pip_miss.png"
		elif grade == 1:
			file = "pip_good.png"
		elif grade == 2:
			file = "pip_perfect.png"
		var tex: Texture2D = MinigameArt.texture(file)
		if i < _pips.size() and _pips[i] != null:
			_pips[i].texture = tex
		if i < _card_pips.size() and _card_pips[i] != null:
			_card_pips[i].texture = tex


func _text_width(text: String) -> float:
	var font: Font = GameTheme.body_font()
	if font == null:
		return float(text.length()) * 10.0
	return font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, GameTheme.BODY_SIZE).x


func _fit_ink(lbl: Label, x: float, y: float, h: float) -> void:
	var w: float = ceilf(_text_width(lbl.text)) + 2.0
	lbl.position = Vector2(x, y)
	lbl.size = Vector2(w, h)


func _summary_button(node_name: String, normal_file: String, hover_file: String) -> TextureButton:
	var button := TextureButton.new()
	button.name = node_name
	button.texture_normal = MinigameArt.texture(normal_file)
	button.texture_hover = MinigameArt.texture(hover_file)
	button.texture_pressed = MinigameArt.texture(hover_file)
	button.ignore_texture_size = true
	button.stretch_mode = TextureButton.STRETCH_SCALE
	button.custom_minimum_size = SUMMARY_BTN
	button.size = SUMMARY_BTN
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	return button


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
	if game_id == "" or worker == "" or not MinigameCatalog.is_reachable(game_id):
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


func note_success(k_seconds: float, weight: float = 1.0) -> void:
	if not _open or _summary_up or k_seconds <= 0.0:
		return
	var result: Dictionary = MinigamePayout.grant(_worker, _game_id, _target_id, k_seconds)
	if not bool(result.get("ok", false)):
		return
	_successes += 1
	_streak += 1
	_best_streak = maxi(_best_streak, _streak)
	_pace_seconds += k_seconds
	_earned += float(result.get("applied", k_seconds))
	_push_grade(2 if weight > 1.0 else 1)
	_refresh_pace()
	_spawn_pop(k_seconds)


func note_miss() -> void:
	if not _open or _summary_up:
		return
	_misses += 1
	_streak = 0
	_push_grade(0)


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
	return _open_game(game_id, worker, target_id, false)


## The debug panel can open a game the world does not offer. Steeping uses this.
func debug_open(game_id: String) -> bool:
	var target: String = ""
	var nodes_v: Variant = MinigameCatalog.game(game_id).get("nodes", [])
	if typeof(nodes_v) == TYPE_ARRAY and not (nodes_v as Array).is_empty():
		target = str((nodes_v as Array)[0])
	return _open_game(game_id, "keeper", target, true)


func _open_game(game_id: String, worker: String, target_id: String, from_debug: bool) -> bool:
	if game_id == "" or (worker != "keeper" and worker != "elaia"):
		return false
	if not from_debug and not MinigameCatalog.is_reachable(game_id):
		return false
	if not from_debug and has_node("/root/GameState") and GameState.is_world_frozen():
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
	_misses = 0
	_streak = 0
	_best_streak = 0
	_summary_up = false
	_grades.clear()
	_layout_window()
	_apply_win_plate(game_id)
	_paint_grades()
	_title.text = MinigameCatalog.title(game_id)
	Ui540.place_title_plank(_title, _panel.size.x)
	var live_text: bool = MinigameCatalog.plate_draws_live_text(game_id)
	_flavour.text = MinigameCatalog.flavour(game_id)
	_flavour.visible = live_text and _flavour.text != ""
	_hint.text = MinigameCatalog.hint(game_id, Ui540.is_phone_export())
	_hint.visible = true
	_summary.visible = false
	_play.visible = true
	var node: Node = packed.instantiate()
	_game = node as Minigame
	if _game == null:
		node.queue_free()
		return false
	_game.position = Vector2.ZERO
	_game.size = _play.size
	_game.custom_minimum_size = _play.size
	_game.mouse_filter = Control.MOUSE_FILTER_STOP
	_game.visible = true
	_play.add_child(_game)
	_panel.move_child(_summary, -1)
	_game.bind_target(target_id)
	_game.begin()
	_set_open(true)
	_refresh_pace()
	return true


func _layout_window() -> void:
	var vs: Vector2 = Ui540.viewport_size()
	var top: float = HUD_BAR_PX + Ui540.PLANK_RISE
	var shortcut_top: float = vs.y - Ui540.SAFE_MARGIN_PX - Ui540.TAP_MIN_PX
	var max_bottom: float = shortcut_top - HUD_SHORTCUT_GAP
	var max_h: float = maxf(120.0, max_bottom - top)
	var max_w: float = maxf(120.0, vs.x - Ui540.SAFE_MARGIN_PX * 2.0)
	var sz := Vector2(
		minf(MinigameCatalog.WINDOW_SIZE.x, max_w),
		minf(MinigameCatalog.WINDOW_SIZE.y, max_h)
	)
	_panel.custom_minimum_size = Vector2.ZERO
	_panel.size = sz
	_panel.custom_minimum_size = sz
	_panel.position = Vector2(roundf((vs.x - sz.x) * 0.5), roundf(top))
	Ui540.place_close_button(_close, sz.x)
	_layout_header()
	## The plate is stretched onto this window. The play field is the plate's
	## content well, so it has to use the same stretch or a second frame and
	## an empty strip show beside it.
	var fit := Vector2(sz.x / MinigameCatalog.WINDOW_SIZE.x, sz.y / MinigameCatalog.WINDOW_SIZE.y)
	_play.position = MinigameCatalog.PLAY_ORIGIN * fit
	_play.size = MinigameCatalog.PLAY_SIZE
	_play.scale = fit
	var footer_w: float = sz.x - 56.0
	_hint.position = Vector2(28, sz.y - 30.0)
	_hint.size = Vector2(footer_w, 22)
	if _flavour != null:
		_flavour.position = Vector2(28, sz.y - 54.0)
		_flavour.size = Vector2(footer_w, 22)
	_summary.position = ((sz - Vector2(460, 308)) * 0.5).round()
	_summary.size = Vector2(460, 308)
	if _win_plate != null:
		_win_plate.position = Vector2.ZERO
		_win_plate.size = sz


func _layout_header() -> void:
	var row_y: float = HEADER_ROW_Y
	var row_h: float = HEADER_ROW_H
	var gap: float = 6.0
	var x: float = 16.0
	_fit_ink(_succ_word, x, row_y, row_h)
	x += _succ_word.size.x + gap
	_fit_ink(_succ_count, x, row_y, row_h)
	_succ_count.size.x = maxf(_succ_count.size.x, _text_width("99") + 2.0)
	x += _succ_count.size.x + gap
	var pip_y: float = row_y + (row_h - PIP_PX) * 0.5
	for i: int in _pips.size():
		_pips[i].position = Vector2(x + float(i) * PIP_STEP, pip_y)
		_pips[i].size = Vector2(PIP_PX, PIP_PX)
	x += 9.0 * PIP_STEP + PIP_PX + gap
	_fit_ink(_pace_word, x, row_y, row_h)
	x += _pace_word.size.x + gap
	var readout_w: float = maxf(_text_width("×3.0") + 4.0, 36.0)
	var room: float = _close.position.x - 8.0 - readout_w - 8.0 - x
	var bar_w: float = clampf(room, 48.0, 132.0)
	_pace_bar.position = Vector2(x, row_y + (row_h - PACE_BAR_H) * 0.5)
	_pace_bar.size = Vector2(bar_w, PACE_BAR_H)
	var tick_y: float = (PACE_BAR_H - PACE_TICK_H) * 0.5
	for i: int in 3:
		var tick: ColorRect = _pace_bar.get_node("Tick%d" % i) as ColorRect
		var along: float = 0.0 if i == 0 else (0.5 if i == 1 else 1.0)
		tick.position = Vector2(roundf(along * bar_w) - 1.0, tick_y)
		tick.size = Vector2(3, PACE_TICK_H)
	_pace.position = Vector2(x + bar_w + 8.0, row_y)
	_pace.size = Vector2(readout_w, row_h)
	_refresh_pace()


func _refresh_pace() -> void:
	var pace: float = MinigameMath.pace_multiplier(_pace_seconds, _elapsed)
	if _succ_count != null:
		_succ_count.text = str(_successes)
	if _pace == null or _pace_bar == null:
		return
	_pace.text = "×%.1f" % pace
	var frac: float = clampf(pace / 3.0, 0.0, 1.0)
	var fill_w: float = _pace_bar.size.x * frac
	_pace_fill.position = Vector2.ZERO
	_pace_fill.size = Vector2(fill_w, PACE_BAR_H)
	_pace_fill.visible = fill_w >= 1.0
	var file: String = "kit_pace_fill_gold.png" if pace >= 2.95 else "kit_pace_fill_good.png"
	_pace_fill.texture = MinigameArt.texture(file)


func _clear_pace_pops() -> void:
	if _panel == null:
		return
	for child: Node in _panel.get_children():
		if child.name != "PacePop":
			continue
		if child is CanvasItem:
			(child as CanvasItem).visible = false
		child.free()


func _spawn_pop(k_seconds: float) -> void:
	_clear_pace_pops()
	var text: String = "+%.1fs" % k_seconds
	var pop := Control.new()
	pop.name = "PacePop"
	pop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pop.z_index = 40
	var width: float = ceilf(_text_width(text)) + 22.0
	var height: float = 32.0
	pop.size = Vector2(width, height)
	pop.pivot_offset = pop.size * 0.5
	var local: Vector2 = Vector2(320, 120)
	if _game != null:
		local = _game.feedback_at
	var anchor: Vector2 = _play.position + Vector2(local.x * _play.scale.x, local.y * _play.scale.y)
	var visual := Rect2(_play.position, _play.size * _play.scale)
	var pos := Vector2(anchor.x - width * 0.5, anchor.y - height - 4.0)
	pos.x = clampf(pos.x, visual.position.x + 4.0, maxf(visual.position.x + 4.0, visual.end.x - width - 4.0))
	pos.y = clampf(pos.y, visual.position.y + 4.0, maxf(visual.position.y + 4.0, visual.end.y - height - 4.0))
	pop.position = pos.round()
	var edge := ColorRect.new()
	edge.name = "Edge"
	edge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	edge.color = Color8(62, 42, 24)
	edge.set_anchors_preset(Control.PRESET_FULL_RECT)
	pop.add_child(edge)
	var chip := ColorRect.new()
	chip.name = "Chip"
	chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chip.color = PARCHMENT
	chip.position = Vector2(1, 1)
	chip.size = Vector2(width - 2.0, height - 2.0)
	pop.add_child(chip)
	var label := Label.new()
	label.name = "Value"
	label.text = text
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	GameTheme.style_ink_label(label)
	label.add_theme_constant_override("outline_size", 0)
	pop.add_child(label)
	_panel.add_child(pop)
	pop.scale = Vector2(1.22, 1.22)
	var tw: Tween = create_tween()
	tw.tween_property(pop, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(pop, "position:y", pop.position.y - 12.0, 0.45)
	tw.tween_property(pop, "modulate:a", 0.0, 0.2)
	tw.tween_callback(pop.queue_free)


func _show_summary() -> void:
	_clear_pace_pops()
	if _game != null:
		_game.shutdown()
		_game.visible = false
	_play.visible = false
	_summary_up = true
	_hint.visible = false
	if _flavour != null:
		_flavour.visible = false
	var pace: float = MinigameMath.pace_multiplier(_pace_seconds, _elapsed)
	_summary_body.text = MinigameCatalog.flavour(_game_id)
	if _summary_rows.size() == 5:
		_summary_rows[0].text = "Successes  %d" % _successes
		_summary_rows[1].text = "Misses  %d" % _misses
		_summary_rows[2].text = "Best streak  %d" % _best_streak
		_summary_rows[3].text = "Pace  ×%.1f" % pace
		_summary_rows[4].text = _bonus_line()
	_summary.visible = true
	_panel.move_child(_summary, -1)


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


func _on_again() -> void:
	var game_id: String = _game_id
	var worker: String = _worker
	var target_id: String = _target_id
	open_game(game_id, worker, target_id)


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
		show = game_id != "" and MinigameCatalog.is_reachable(game_id) and hero_for(_prompt_target) != ""
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
		_game.visible = false
		_game.queue_free()
	_game = null


func _set_open(open: bool) -> void:
	_open = open
	if _dim == null or _panel == null or _play == null:
		return
	_dim.visible = open
	_panel.visible = open
	if open:
		WorldHover.hide_for_overlay()
	if not open:
		_summary.visible = false
		_summary_up = false
		_prompt_on = false
		_play.visible = false
