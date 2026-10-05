extends CanvasLayer
## Testing-build debug panel. F8, or Options → Show debug tools.
## Stable exports exclude this scene, this script, and tools/debug/snapshots/.


const SNAPSHOTS: Dictionary = {
	"Pre-Echo": "res://tools/debug/snapshots/pre_echo.json",
	"Forge unlocked": "res://tools/debug/snapshots/forge_unlocked.json",
	"Elaia joined": "res://tools/debug/snapshots/elaia_joined.json",
	"Ancient ready": "res://tools/debug/snapshots/ancient_ready.json",
}
var _free_crafts: PackedStringArray = PackedStringArray([
	"sapsteel",
	"heartwood_bits",
	"amberbind",
])
var _stations: PackedStringArray = PackedStringArray([
	"crucible", "mill", "press", "anvil", "reliquary",
])
var _resource_ids: PackedStringArray = PackedStringArray([
	"wood", "stone", "food", "manashards", "essence",
])

var _status: Label
var _recipes: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load_recipes()
	_build_ui()


func _build_ui() -> void:
	var backdrop := ColorRect.new()
	backdrop.name = "Backdrop"
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.color = Color(0.02, 0.04, 0.03, 0.62)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(backdrop)

	var panel := ColorRect.new()
	panel.name = "Panel"
	panel.color = Color(0.09, 0.12, 0.11, 0.97)
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -270.0
	panel.offset_top = -340.0
	panel.offset_right = 270.0
	panel.offset_bottom = 340.0
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(panel)

	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.offset_left = 18.0
	box.offset_top = 14.0
	box.offset_right = -18.0
	box.offset_bottom = -14.0
	box.add_theme_constant_override("separation", 4)
	panel.add_child(box)

	var title := Label.new()
	title.text = "Debug tools"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color(0.93, 0.86, 0.62, 1))
	box.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "F8  ·  testing build"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 13)
	subtitle.add_theme_color_override("font_color", Color(0.78, 0.86, 0.74, 1))
	box.add_child(subtitle)

	_add_section(box, "Load snapshots")
	var snapshot_labels: PackedStringArray = PackedStringArray([
		"Pre-Echo", "Forge unlocked", "Elaia joined", "Ancient ready",
	])
	for label: String in snapshot_labels:
		_add_button(box, label, _on_snapshot_pressed.bind(str(SNAPSHOTS[label]), label))

	_add_section(box, "Forge")
	_add_button(box, "Free Sapsteel", _on_free_craft_pressed.bind("sapsteel"))
	_add_button(box, "Free Heartwood", _on_free_craft_pressed.bind("heartwood_bits"))
	_add_button(box, "Free Amberbind", _on_free_craft_pressed.bind("amberbind"))
	_add_button(box, "Skip station work", _on_skip_pressed)

	_add_section(box, "Inventory")
	_add_button(box, "Add resources and crafted bits", _on_add_items_pressed)

	_add_section(box, "Jumps")
	_add_button(box, "Jump to Echo", _on_echo_pressed)
	_add_button(box, "Open Ascension shop", _on_ascension_pressed)

	_status = Label.new()
	_status.name = "Status"
	_status.text = "Ready."
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status.custom_minimum_size = Vector2(0, 36)
	_status.add_theme_font_size_override("font_size", 13)
	_status.add_theme_color_override("font_color", Color(0.93, 0.86, 0.62, 1))
	box.add_child(_status)

	var close := Button.new()
	close.text = "Close"
	close.custom_minimum_size = Vector2(0, 32)
	close.pressed.connect(_on_close_pressed)
	box.add_child(close)


func _add_section(parent: VBoxContainer, text: String) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 15)
	label.add_theme_color_override("font_color", Color(0.78, 0.86, 0.74, 1))
	parent.add_child(label)


func _add_button(parent: VBoxContainer, text: String, callback: Callable) -> void:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0, 28)
	button.pressed.connect(callback)
	parent.add_child(button)


func _on_close_pressed() -> void:
	AnimPreviewHotkey.set_debug_panel(false)


func _on_snapshot_pressed(path: String, label: String) -> void:
	if not FileAccess.file_exists(path):
		_set_status("Missing snapshot %s." % label)
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if typeof(parsed) != TYPE_DICTIONARY:
		_set_status("Snapshot %s is not a save." % label)
		return
	var state_v: Variant = (parsed as Dictionary).get("state", {})
	if typeof(state_v) != TYPE_DICTIONARY:
		_set_status("Snapshot %s has no state." % label)
		return
	if EchoChamber.in_battle:
		EchoChamber.dismiss_battle_without_reward()
	GameState.apply_save_dict(state_v as Dictionary)
	SaveService.note_session_started()
	SaveService.boot_intent = "auto"
	SaveService.boot_slot = 0
	SaveService.boot_slot_kind = "manual"
	get_tree().paused = false
	AnimPreviewHotkey.set_debug_panel(false)
	get_tree().change_scene_to_file("res://scenes/main.tscn")


func _on_free_craft_pressed(recipe_id: String) -> void:
	if not _free_crafts.has(recipe_id):
		_set_status("Unknown craft.")
		return
	var recipe: Dictionary = _recipe(recipe_id)
	if recipe.is_empty():
		_set_status("Recipe %s is missing." % recipe_id)
		return
	var station_id: String = str(recipe.get("station", ""))
	if station_id == "" or not _stations.has(station_id):
		_set_status("Recipe %s has no station." % recipe_id)
		return
	if ForgeJobs.has_job(station_id):
		_set_status("That station is busy. Skip station work first.")
		return
	var inputs_v: Variant = recipe.get("inputs", {})
	var inputs: Dictionary = {}
	if typeof(inputs_v) == TYPE_DICTIONARY:
		inputs = inputs_v as Dictionary
	_grant_inputs(inputs)
	var repeat_was: bool = _pause_repeat(station_id)
	ForgeJobs.set_keeper_working(station_id, true)
	var result: String = str(ForgeJobs.try_begin_job(station_id, recipe_id))
	if result != "ok":
		ForgeJobs.set_keeper_working(station_id, false)
		_restore_repeat(station_id, repeat_was)
		_set_status("Free craft failed (%s)." % result)
		return
	var state: Dictionary = ForgeJobs.job_state(station_id)
	ForgeJobs.advance_seconds(float(state.get("remaining_sec", 1.0)) + 0.05)
	ForgeJobs.set_keeper_working(station_id, false)
	_restore_repeat(station_id, repeat_was)
	_set_status("Crafted %s." % _pretty(recipe_id))


func _on_skip_pressed() -> void:
	var finished: int = 0
	for station_id: String in _stations:
		if not ForgeJobs.has_job(station_id):
			continue
		var forced: bool = false
		var repeat_was: bool = _pause_repeat(station_id)
		var state: Dictionary = ForgeJobs.job_state(station_id)
		if float(state.get("speed", 0.0)) <= 0.0:
			ForgeJobs.set_keeper_working(station_id, true)
			forced = true
			state = ForgeJobs.job_state(station_id)
		ForgeJobs.advance_seconds(float(state.get("remaining_sec", 0.0)) + 0.05)
		if forced:
			ForgeJobs.set_keeper_working(station_id, false)
		_restore_repeat(station_id, repeat_was)
		finished += 1
	if finished == 0:
		_set_status("No station work to skip.")
	else:
		_set_status("Finished %d station job(s)." % finished)


func _on_add_items_pressed() -> void:
	GameState.add_resource(&"wood", 40)
	GameState.add_resource(&"stone", 40)
	GameState.add_resource(&"essence", 40)
	GameState.add_resource(&"manashards", 40)
	Backpack.add_item("wooden_planks", 8)
	Backpack.add_item("fertilizer", 4)
	_set_status("Added 40 wood, stone, essence, and shards, plus 8 planks and 4 fertilizer.")


func _on_echo_pressed() -> void:
	if EchoChamber.in_battle:
		_set_status("Echo is already open.")
		return
	GameState.portal_unlocked = true
	if GameState.ascensions < 1:
		GameState.ascensions = 1
	GameState.echo_01_resolved = false
	GameState.portal_fee_paid = true
	if GameState.essence < 30:
		GameState.add_resource(&"essence", 30 - GameState.essence)
	GameState.echo_flags_changed.emit()
	_dismiss_pause()
	get_tree().paused = false
	AnimPreviewHotkey.set_debug_panel(false)
	EchoChamber.open_battle(true)


func _on_ascension_pressed() -> void:
	GameState.stage_id = &"ancient"
	GameState.fruit_ready = false
	GameState.fruit_committed = true
	GameState.fruit_harvested_pending_ascend = true
	GameState.ancient_frozen = false
	GameState.ancient_remaining_sec = 0.0
	GameState.welcome_shown = true
	GameState.stage_changed.emit(GameState.stage_id)
	GameState.fruit_ready_changed.emit(false)
	SaveService.note_session_started()
	SaveService.boot_intent = "auto"
	SaveService.boot_slot = 0
	var hud: Node = get_tree().get_first_node_in_group("game_hud")
	if hud != null and hud.has_method("show_ascension_shop"):
		_dismiss_pause()
		if hud.has_method("hide_welcome"):
			hud.call("hide_welcome")
		get_tree().paused = false
		AnimPreviewHotkey.set_debug_panel(false)
		hud.call("show_ascension_shop")
		return
	get_tree().paused = false
	AnimPreviewHotkey.set_debug_panel(false)
	get_tree().change_scene_to_file("res://scenes/main.tscn")


func _dismiss_pause() -> void:
	var menus: Array[Node] = get_tree().get_nodes_in_group("pause_menu")
	for node: Node in menus:
		if bool(node.get("standalone")) and node.has_method("close_standalone"):
			node.call("close_standalone")
		elif node.has_method("is_open") and bool(node.call("is_open")) and node.has_method("resume_game"):
			node.call("resume_game")


func _pause_repeat(station_id: String) -> bool:
	var was: bool = bool(ForgeJobs.station_repeat_enabled(station_id))
	if bool(ForgeJobs.station_supports_repeat(station_id)):
		ForgeJobs.set_station_repeat(station_id, false)
	return was


func _restore_repeat(station_id: String, was: bool) -> void:
	if bool(ForgeJobs.station_supports_repeat(station_id)):
		ForgeJobs.set_station_repeat(station_id, was)


func _grant_inputs(inputs: Dictionary) -> void:
	for key: Variant in inputs.keys():
		var item_id: String = str(key)
		var need: int = int(inputs[key])
		if need <= 0:
			continue
		if _resource_ids.has(item_id):
			GameState.add_resource(StringName(item_id), need)
		else:
			Backpack.add_item(item_id, need)


func _load_recipes() -> void:
	var file := FileAccess.open("res://data/forge_tuning.json", FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	var raw: Variant = (parsed as Dictionary).get("recipes", {})
	if typeof(raw) == TYPE_DICTIONARY:
		_recipes = raw


func _recipe(recipe_id: String) -> Dictionary:
	var found: Variant = _recipes.get(recipe_id, {})
	if typeof(found) != TYPE_DICTIONARY:
		return {}
	return found


func _pretty(recipe_id: String) -> String:
	return recipe_id.capitalize().replace("_", " ")


func _set_status(text: String) -> void:
	if _status:
		_status.text = text
