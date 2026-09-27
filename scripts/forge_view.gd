extends CanvasLayer
## Bark-chamber overlay. Stations tick in GameState, so work continues after you leave.

const BARK_PATH: String = "res://assets/art/forge/forge_bark_chamber_bg.png"

var _mats: Label
var _toast: Label
var _tend: Dictionary = {}
var _send: Dictionary = {}
var _recall: Dictionary = {}
var _status: Dictionary = {}
var _fill: Dictionary = {}
var _swatch: Dictionary = {}
var _swatch_busy: Dictionary = {}
var _anvil_buttons: Dictionary = {}


func _ready() -> void:
	layer = 15
	process_mode = Node.PROCESS_MODE_PAUSABLE
	_build()
	if not GameState.forge_changed.is_connected(_on_forge_changed):
		GameState.forge_changed.connect(_on_forge_changed)
	if not GameState.status_message.is_connected(_on_status):
		GameState.status_message.connect(_on_status)
	if _toast:
		_toast.text = ContentStrings.get_text("forge_room_examine")
	_refresh()


func _process(_delta: float) -> void:
	if not GameState.in_forge:
		return
	_refresh()


func _on_forge_changed() -> void:
	if not is_inside_tree():
		return
	if not GameState.in_forge:
		queue_free()
		return
	_refresh()


func _on_status(text: String) -> void:
	if _toast:
		_toast.text = text


func _on_exit() -> void:
	GameState.end_forge_visit()


func _on_tend(station_id: String) -> void:
	GameState.try_toggle_forge_station(station_id)


func _on_send(station_id: String) -> void:
	GameState.send_wisp_to_forge(station_id)


func _on_recall(station_id: String) -> void:
	GameState.recall_wisp_from_forge(station_id)


func _on_anvil(recipe_id: String) -> void:
	GameState.try_begin_anvil(recipe_id)


func _build() -> void:
	var root := Control.new()
	root.name = "Root"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(root)
	root.add_child(_bark_background())
	var title := _label(root, "Title", Vector2(36, 152), Vector2(720, 28), ContentStrings.get_text("forge_title"), 22)
	title.add_theme_color_override("font_color", Color(0.95, 0.88, 0.72, 1))
	_label(root, "Subtitle", Vector2(36, 182), Vector2(980, 22), ContentStrings.get_text("forge_room_examine"), 14)
	_mats = _label(root, "Mats", Vector2(36, 206), Vector2(1000, 22), "", 13)
	_label(root, "Hint", Vector2(36, 228), Vector2(980, 20), ContentStrings.get_text("weapon_persist_hint"), 12)
	var exit_btn := Button.new()
	exit_btn.name = "ExitButton"
	exit_btn.position = Vector2(1040, 152)
	exit_btn.size = Vector2(200, 36)
	exit_btn.text = ContentStrings.get_text("forge_exit")
	exit_btn.pressed.connect(_on_exit)
	root.add_child(exit_btn)
	_add_station(root, GameState.FORGE_CRUCIBLE, Vector2(28, 258), Color(0.72, 0.42, 0.22, 1))
	_add_station(root, GameState.FORGE_MILL, Vector2(438, 258), Color(0.55, 0.36, 0.2, 1))
	_add_station(root, GameState.FORGE_ANVIL, Vector2(848, 258), Color(0.32, 0.46, 0.32, 1))
	_toast = _label(root, "Toast", Vector2(36, 688), Vector2(1208, 24), "", 13)


func _add_station(parent: Control, station_id: String, origin: Vector2, swatch: Color) -> void:
	var card := ColorRect.new()
	card.name = _card_name(station_id)
	card.position = origin
	card.size = Vector2(400, 420)
	card.color = Color(0.11, 0.08, 0.06, 0.94)
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	parent.add_child(card)
	var icon := TextureRect.new()
	icon.name = "Swatch"
	icon.position = Vector2(16, 14)
	icon.size = Vector2(56, 56)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var idle_tex: Texture2D = _prop_texture(station_id, false)
	if idle_tex:
		icon.texture = idle_tex
	else:
		icon.modulate = swatch
	card.add_child(icon)
	_swatch[station_id] = icon
	_swatch_busy[station_id] = false
	var name_lbl := _label(card, "Name", Vector2(84, 16), Vector2(300, 24), _station_name(station_id), 18)
	name_lbl.add_theme_color_override("font_color", Color(0.95, 0.9, 0.78, 1))
	var examine := _label(card, "Examine", Vector2(16, 78), Vector2(368, 64), _station_examine(station_id), 13)
	examine.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var back := ColorRect.new()
	back.name = "ProgressBack"
	back.position = Vector2(16, 150)
	back.size = Vector2(368, 12)
	back.color = Color(0.05, 0.04, 0.03, 1)
	back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(back)
	var fill := ColorRect.new()
	fill.name = "ProgressFill"
	fill.position = Vector2(16, 150)
	fill.size = Vector2(0, 12)
	fill.color = swatch
	fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(fill)
	_fill[station_id] = fill
	var status := _label(card, "Status", Vector2(16, 168), Vector2(368, 48), "", 13)
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status[station_id] = status
	var tend := Button.new()
	tend.name = "Tend"
	tend.position = Vector2(16, 224)
	tend.size = Vector2(176, 34)
	tend.pressed.connect(_on_tend.bind(station_id))
	card.add_child(tend)
	_tend[station_id] = tend
	var send := Button.new()
	send.name = "SendWisp"
	send.position = Vector2(204, 224)
	send.size = Vector2(180, 34)
	send.text = ContentStrings.get_text("forge_assign_wisp")
	send.pressed.connect(_on_send.bind(station_id))
	card.add_child(send)
	_send[station_id] = send
	var recall := Button.new()
	recall.name = "RecallWisp"
	recall.position = Vector2(16, 266)
	recall.size = Vector2(368, 32)
	recall.text = ContentStrings.get_text("forge_unassign_wisp")
	recall.pressed.connect(_on_recall.bind(station_id))
	card.add_child(recall)
	_recall[station_id] = recall
	if station_id == GameState.FORGE_ANVIL:
		_add_anvil_recipes(card)


func _add_anvil_recipes(card: Control) -> void:
	var y: float = 308.0
	for entry: Variant in Equipment.recipes_data:
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var rec: Dictionary = entry
		if str(rec.get("station", "")) != "anvil":
			continue
		var recipe_id: String = str(rec.get("id", ""))
		if recipe_id == "":
			continue
		var btn := Button.new()
		btn.name = "Anvil_%s" % recipe_id
		btn.position = Vector2(16, y)
		btn.size = Vector2(368, 32)
		btn.pressed.connect(_on_anvil.bind(recipe_id))
		card.add_child(btn)
		_anvil_buttons[recipe_id] = btn
		y += 36.0


func _refresh() -> void:
	if _mats:
		_mats.text = ContentStrings.get_text("forge_mats_line", {
			"fragments": Backpack.get_count("stone_fragments"),
			"wood": GameState.wood,
			"sapsteel": Backpack.get_count("sapsteel"),
			"heartwood": Backpack.get_count("heartwood_bits"),
			"essence": GameState.essence,
		})
	for station_id: String in GameState.FORGE_STATION_IDS:
		_refresh_station(station_id)
	_refresh_anvil_buttons()


func _refresh_station(station_id: String) -> void:
	var tend: Button = _tend.get(station_id) as Button
	var running: bool = bool(GameState.forge_running.get(station_id, false))
	if tend:
		tend.text = ContentStrings.get_text("forge_rest" if running else "forge_tend")
	var busy: bool = _station_busy(station_id)
	var swatch: TextureRect = _swatch.get(station_id) as TextureRect
	if swatch and bool(_swatch_busy.get(station_id, false)) != busy:
		_swatch_busy[station_id] = busy
		var tex: Texture2D = _prop_texture(station_id, busy)
		if tex:
			swatch.texture = tex
	var fill: ColorRect = _fill.get(station_id) as ColorRect
	if fill:
		var ratio: float = GameState.forge_progress_ratio(station_id)
		fill.size = Vector2(368.0 * ratio, 12)
	var status: Label = _status.get(station_id) as Label
	if status:
		status.text = _station_status(station_id)


func _refresh_anvil_buttons() -> void:
	var busy: bool = GameState.anvil_recipe != ""
	for recipe_id: Variant in _anvil_buttons.keys():
		var rid: String = str(recipe_id)
		var btn: Button = _anvil_buttons[rid] as Button
		if btn == null:
			continue
		var def: Dictionary = Equipment.get_recipe_def(rid)
		var out_id: String = str(def.get("output_id", rid))
		var item_name: String = Equipment.item_display_name(out_id)
		btn.tooltip_text = ContentStrings.get_text("%s_craft_cost" % rid)
		if GameState.anvil_recipe == rid:
			btn.text = item_name
			btn.disabled = true
		elif Equipment.craft_block_reason(rid) == "unique":
			btn.text = ContentStrings.get_text("handcraft_owned_unique")
			btn.disabled = true
		else:
			btn.text = item_name
			btn.disabled = busy


func _station_status(station_id: String) -> String:
	var wisps: int = GameState.count_wisps_on_node(station_id)
	var wisp_line: String = ContentStrings.get_text("forge_station_empty" if wisps == 0 else "forge_station_busy")
	var progress: String = ""
	if station_id == GameState.FORGE_ANVIL:
		if GameState.anvil_recipe == "":
			progress = ContentStrings.get_text("forge_anvil_prompt")
		else:
			progress = ContentStrings.get_text("forge_job_progress", {
				"station": ContentStrings.get_text("forge_anvil_name"),
				"current": GameState.anvil_pulses_done,
				"need": GameState.STATION_PULSES_TO_FINISH,
			})
	else:
		var paid: bool = bool(GameState.forge_job_paid.get(station_id, false))
		if paid:
			progress = ContentStrings.get_text("forge_job_progress", {
				"station": GameState.assignment_target_display(station_id),
				"current": int(GameState.forge_pulses.get(station_id, 0)),
				"need": GameState.STATION_PULSES_TO_FINISH,
			})
		elif station_id == GameState.FORGE_CRUCIBLE:
			progress = ContentStrings.get_text("sapsteel_process_cost")
		else:
			progress = ContentStrings.get_text("heartwood_bits_process_cost")
	return "%s\n%s" % [progress, wisp_line]


func _bark_background() -> Control:
	var tex: Texture2D = null
	if ResourceLoader.exists(BARK_PATH):
		tex = load(BARK_PATH) as Texture2D
	if tex:
		var bg := TextureRect.new()
		bg.name = "Bark"
		bg.set_anchors_preset(Control.PRESET_FULL_RECT)
		bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bg.texture = tex
		bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		bg.stretch_mode = TextureRect.STRETCH_SCALE
		return bg
	var fallback := ColorRect.new()
	fallback.name = "Bark"
	fallback.set_anchors_preset(Control.PRESET_FULL_RECT)
	fallback.color = Color(0.22, 0.14, 0.09, 1)
	fallback.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return fallback


func _prop_key(station_id: String) -> String:
	match station_id:
		GameState.FORGE_CRUCIBLE:
			return "crucible"
		GameState.FORGE_MILL:
			return "mill"
		_:
			return "anvil"


func _prop_texture(station_id: String, busy: bool) -> Texture2D:
	var path := "res://assets/art/forge/prop_%s_%s.png" % [_prop_key(station_id), "busy" if busy else "idle"]
	if not ResourceLoader.exists(path):
		return null
	return load(path) as Texture2D


func _station_busy(station_id: String) -> bool:
	if bool(GameState.forge_running.get(station_id, false)):
		return true
	if bool(GameState.forge_job_paid.get(station_id, false)):
		return true
	if station_id == GameState.FORGE_ANVIL and GameState.anvil_recipe != "":
		return true
	return GameState.count_wisps_on_node(station_id) > 0


func _card_name(station_id: String) -> String:
	match station_id:
		GameState.FORGE_CRUCIBLE:
			return "Crucible"
		GameState.FORGE_MILL:
			return "Mill"
		_:
			return "Anvil"


func _station_name(station_id: String) -> String:
	match station_id:
		GameState.FORGE_CRUCIBLE:
			return ContentStrings.get_text("forge_crucible_name")
		GameState.FORGE_MILL:
			return ContentStrings.get_text("forge_mill_name")
		_:
			return ContentStrings.get_text("forge_anvil_name")


func _station_examine(station_id: String) -> String:
	match station_id:
		GameState.FORGE_CRUCIBLE:
			return ContentStrings.get_text("forge_crucible_examine")
		GameState.FORGE_MILL:
			return ContentStrings.get_text("forge_mill_examine")
		_:
			return ContentStrings.get_text("forge_anvil_examine")


func _label(parent: Control, node_name: String, pos: Vector2, sz: Vector2, text: String, font_size: int) -> Label:
	var lbl := Label.new()
	lbl.name = node_name
	lbl.position = pos
	lbl.size = sz
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", font_size)
	lbl.add_theme_color_override("font_color", Color(0.9, 0.84, 0.72, 1))
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(lbl)
	return lbl
