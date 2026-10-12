extends CanvasLayer
## Testing-build debug panel. Ctrl+F8, or Options → Show debug tools.
## Stable exports exclude this scene, this script, and tools/debug/snapshots/.


const SNAPSHOTS: Dictionary = {
	"Pre-Echo": "res://tools/debug/snapshots/pre_echo.json",
	"Forge unlocked": "res://tools/debug/snapshots/forge_unlocked.json",
	"Elaia joined": "res://tools/debug/snapshots/elaia_joined.json",
	"Ancient ready": "res://tools/debug/snapshots/ancient_ready.json",
	"Echo 2 ready": "res://tools/debug/snapshots/echo2_ready.json",
	"North road open": "res://tools/debug/snapshots/north_road_open.json",
	"Pre-boss": "res://tools/debug/snapshots/pre_boss.json",
	"Veteran reacher": "res://tools/debug/snapshots/veteran_reacher.json",
	"Mid-fight": "res://tools/debug/snapshots/mid_fight.json",
}
const SNAPSHOT_ORDER: PackedStringArray = [
	"Pre-Echo", "Forge unlocked", "Elaia joined", "Ancient ready",
	"Echo 2 ready", "North road open", "Pre-boss", "Veteran reacher",
	"Mid-fight",
]
const FORCE_LABELS: Dictionary = {
	"flee": "Flee",
	"overwhelmed": "Overwhelmed",
	"win": "Win",
}
const BATCH_SIZE: int = 200
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
var _search: LineEdit
var _qty: SpinBox
var _list: ItemList
var _rows: Array[Dictionary] = []
var _fight_depth: SpinBox
var _fight_boss: CheckBox
var _fight_elaia: CheckBox


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load_recipes()
	_load_catalogue()
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
	panel.offset_top = -356.0
	panel.offset_right = 270.0
	panel.offset_bottom = 356.0
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(panel)

	## Scrolls, so the expedition rows fit under the item catalogue.
	var scroll := ScrollContainer.new()
	scroll.name = "Scroll"
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.offset_left = 18.0
	scroll.offset_top = 14.0
	scroll.offset_right = -18.0
	scroll.offset_bottom = -14.0
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(scroll)
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 4)
	scroll.add_child(box)

	var title := Label.new()
	title.text = "Debug tools"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color(0.93, 0.86, 0.62, 1))
	box.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Ctrl+F8  ·  testing build"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 13)
	subtitle.add_theme_color_override("font_color", Color(0.78, 0.86, 0.74, 1))
	box.add_child(subtitle)

	_add_section(box, "Load snapshots")
	## Two columns, so eight snapshots take the height the first four did.
	var snapshot_grid := GridContainer.new()
	snapshot_grid.name = "SnapshotGrid"
	snapshot_grid.columns = 2
	snapshot_grid.add_theme_constant_override("h_separation", 6)
	snapshot_grid.add_theme_constant_override("v_separation", 4)
	box.add_child(snapshot_grid)
	for label: String in SNAPSHOT_ORDER:
		var snap_button: Button = _add_button(snapshot_grid, label, _on_snapshot_pressed.bind(str(SNAPSHOTS[label]), label))
		snap_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	_add_section(box, "Forge")
	_add_button(box, "Free Sapsteel", _on_free_craft_pressed.bind("sapsteel"))
	_add_button(box, "Free Heartwood", _on_free_craft_pressed.bind("heartwood_bits"))
	_add_button(box, "Free Amberbind", _on_free_craft_pressed.bind("amberbind"))
	_add_button(box, "Skip station work", _on_skip_pressed)

	_add_section(box, "Add items")
	_build_catalogue(box)

	_add_section(box, "Jumps")
	_add_button(box, "Jump to Echo", _on_echo_pressed)
	_add_button(box, "Battle arena (test)", _on_battle_arena_pressed)
	_add_button(box, "Open Ascension shop", _on_ascension_pressed)

	_add_section(box, "Expedition")
	var force_row := HBoxContainer.new()
	force_row.name = "ForceRow"
	force_row.add_theme_constant_override("separation", 6)
	box.add_child(force_row)
	for outcome: String in ["flee", "overwhelmed", "win"]:
		var force_button: Button = _add_button(force_row, "Force next room: %s" % str(FORCE_LABELS[outcome]), _on_force_pressed.bind(outcome))
		force_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_build_fight_at_depth(box)
	_add_button(box, "Batch-sim %d" % BATCH_SIZE, _on_batch_sim_pressed)

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


func _add_button(parent: Container, text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0, 24)
	button.pressed.connect(callback)
	parent.add_child(button)
	return button


func _on_close_pressed() -> void:
	AnimPreviewHotkey.set_debug_panel(false)


static func load_snapshot_state(path: String) -> Dictionary:
	## Reads a snapshot and runs it through SaveService migration, like a slot load.
	## {"state": migrated, "error": ""} on success; "state" is empty when the file cannot be used.
	## A snapshot with an "adventure" key (Mid-fight) also writes the adventure file, owned by
	## the snapshot's save_id, so the slot-load resume step brings the fight back.
	if not FileAccess.file_exists(path):
		return {"state": {}, "error": "missing"}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if typeof(parsed) != TYPE_DICTIONARY:
		return {"state": {}, "error": "not a save"}
	var root: Dictionary = parsed
	var state_v: Variant = root.get("state", {})
	if typeof(state_v) != TYPE_DICTIONARY:
		return {"state": {}, "error": "no state"}
	var save_service: Node = (Engine.get_main_loop() as SceneTree).root.get_node_or_null("SaveService")
	if save_service == null:
		return {"state": {}, "error": "no SaveService"}
	var version: int = int(root.get("save_version", 0))
	if bool(save_service.call("is_newer_than_build", version)):
		return {"state": {}, "error": str(save_service.call("newer_save_message", version))}
	var migrated: Dictionary = save_service.call("migrate_state", version, state_v as Dictionary)
	if migrated.is_empty():
		return {"state": {}, "error": "migration failed"}
	var save_id: int = int(root.get("save_id", 0))
	var adv_v: Variant = root.get("adventure", null)
	if typeof(adv_v) != TYPE_DICTIONARY:
		return {"state": migrated, "error": "", "save_id": save_id, "adventure": false}
	var adv: Dictionary = (adv_v as Dictionary).duplicate(true)
	adv["owner_save_id"] = save_id
	if not bool(save_service.call("write_adventure_raw", adv)):
		return {"state": {}, "error": "adventure refused"}
	return {"state": migrated, "error": "", "save_id": save_id, "adventure": true}


func _on_snapshot_pressed(path: String, label: String) -> void:
	var loaded: Dictionary = load_snapshot_state(path)
	var state: Dictionary = loaded.get("state", {}) as Dictionary
	if state.is_empty():
		_set_status("Snapshot %s: %s." % [label, str(loaded.get("error", "unusable"))])
		return
	if EchoChamber.in_battle:
		EchoChamber.dismiss_battle_without_reward()
	GameState.apply_save_dict(state)
	var resumes: bool = bool(loaded.get("adventure", false))
	if resumes:
		## The adventure file the loader wrote is owned by this save_id.
		SaveService.current_save_id = int(loaded.get("save_id", 0))
	SaveService.note_session_started()
	SaveService.boot_intent = "auto"
	SaveService.boot_slot = 0
	SaveService.boot_slot_kind = "manual"
	get_tree().paused = false
	AnimPreviewHotkey.set_debug_panel(false)
	get_tree().change_scene_to_file("res://scenes/main.tscn")
	if resumes:
		## The same resume step a slot load runs, once the new hub is up so the view opens on it.
		get_tree().scene_changed.connect(SaveService._apply_loaded_adventure, CONNECT_ONE_SHOT)


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


func _build_catalogue(parent: VBoxContainer) -> void:
	var search := LineEdit.new()
	search.name = "ItemSearch"
	search.placeholder_text = "Search items and materials"
	search.custom_minimum_size = Vector2(0, 28)
	search.text_changed.connect(_on_catalogue_filter)
	parent.add_child(search)
	_search = search
	var qty_row := HBoxContainer.new()
	qty_row.add_theme_constant_override("separation", 8)
	parent.add_child(qty_row)
	var qty_label := Label.new()
	qty_label.text = "Quantity"
	qty_label.custom_minimum_size = Vector2(88, 0)
	qty_row.add_child(qty_label)
	var qty := SpinBox.new()
	qty.name = "ItemQuantity"
	qty.min_value = 1
	qty.max_value = 999
	qty.value = 1
	qty.rounded = true
	qty.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	qty_row.add_child(qty)
	_qty = qty
	var list := ItemList.new()
	list.name = "ItemCatalogue"
	list.custom_minimum_size = Vector2(0, 132)
	list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	list.select_mode = ItemList.SELECT_SINGLE
	parent.add_child(list)
	_list = list
	var add := Button.new()
	add.name = "AddItem"
	add.text = "Add selected"
	add.custom_minimum_size = Vector2(0, 28)
	add.pressed.connect(_on_catalogue_add)
	parent.add_child(add)
	_fill_catalogue()


func _load_catalogue() -> void:
	_rows.clear()
	var seen: Dictionary = {}
	var raw_names: Dictionary = {
		"wood": "Wood",
		"stone": "Stone",
		"food": "Food",
		"manashards": "Manashards",
		"essence": "Essence",
	}
	for id: String in ["wood", "stone", "food", "manashards", "essence"]:
		_rows.append({"id": id, "label": str(raw_names[id]), "kind": "resource"})
		seen[id] = true
	_append_table("res://data/handcraft_recipes.json", "items", "item", seen)
	_append_table("res://data/equipment.json", "items", "gear", seen)
	var forge: Variant = _read_json("res://data/forge_tuning.json")
	if typeof(forge) != TYPE_DICTIONARY:
		return
	var recipes: Variant = (forge as Dictionary).get("recipes", {})
	if typeof(recipes) != TYPE_DICTIONARY:
		return
	for key: Variant in (recipes as Dictionary).keys():
		var output: String = str(key)
		if output == "" or seen.has(output):
			continue
		_rows.append({"id": output, "label": _pretty(output), "kind": "item"})
		seen[output] = true


func _append_table(path: String, key: String, kind: String, seen: Dictionary) -> void:
	var parsed: Variant = _read_json(path)
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	var items: Variant = (parsed as Dictionary).get(key, [])
	if typeof(items) != TYPE_ARRAY:
		return
	for entry: Variant in items:
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var row: Dictionary = entry
		var id: String = str(row.get("id", ""))
		if id == "" or seen.has(id):
			continue
		var label: String = str(row.get("display_name", id))
		_rows.append({"id": id, "label": label, "kind": kind})
		seen[id] = true


func _read_json(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		return {}
	return JSON.parse_string(FileAccess.get_file_as_string(path))


func _fill_catalogue() -> void:
	if _list == null:
		return
	_list.clear()
	var query: String = ""
	if _search != null:
		query = _search.text.strip_edges().to_lower()
	for row: Dictionary in _rows:
		var label: String = str(row.get("label", ""))
		var id: String = str(row.get("id", ""))
		if query != "" and label.to_lower().find(query) < 0 and id.to_lower().find(query) < 0:
			continue
		var kind: String = str(row.get("kind", "item"))
		var index: int = _list.add_item("%s   %s" % [label, kind])
		_list.set_item_metadata(index, row)


func _on_catalogue_filter(_text: String) -> void:
	_fill_catalogue()


func _on_catalogue_add() -> void:
	if _list == null:
		return
	var selected: PackedInt32Array = _list.get_selected_items()
	if selected.is_empty():
		_set_status("Pick an item from the list.")
		return
	var meta: Variant = _list.get_item_metadata(selected[0])
	if typeof(meta) != TYPE_DICTIONARY:
		return
	var row: Dictionary = meta
	var qty: int = 1
	if _qty != null:
		qty = maxi(1, int(_qty.value))
	var id: String = str(row.get("id", ""))
	var kind: String = str(row.get("kind", "item"))
	if kind == "resource":
		GameState.add_resource(StringName(id), qty)
	elif kind == "gear":
		if not Equipment.add_gear(id, qty):
			_set_status("Could not add %s." % str(row.get("label", id)))
			return
	else:
		Backpack.add_item(id, qty)
	_set_status("Added %d %s." % [qty, str(row.get("label", id))])


func _on_echo_pressed() -> void:
	if EchoChamber.in_battle:
		_set_status("Echo is already open.")
		return
	if BattleView.is_open():
		_set_status("Close the battle arena first.")
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


func _on_battle_arena_pressed() -> void:
	## Same open_arena() the headless shell test calls. Refuse leaves the panel up.
	if not BattleView.open_arena():
		_set_status("Battle arena stays closed while Echo or a reach fight is open.")
		return
	_dismiss_pause()
	AnimPreviewHotkey.set_debug_panel(false)


func _on_force_pressed(outcome: String) -> void:
	if not FORCE_LABELS.has(outcome):
		_set_status("Unknown outcome.")
		return
	Reach.debug_force_outcomes([outcome])
	_set_status("Next idle room is forced: %s." % str(FORCE_LABELS[outcome]))


func _build_fight_at_depth(parent: VBoxContainer) -> void:
	var row := HBoxContainer.new()
	row.name = "FightAtDepthRow"
	row.add_theme_constant_override("separation", 6)
	parent.add_child(row)
	var label := Label.new()
	label.text = "Fight at depth"
	row.add_child(label)
	var depth := SpinBox.new()
	depth.name = "FightDepth"
	depth.min_value = 1
	depth.max_value = 40
	depth.value = 1
	depth.rounded = true
	row.add_child(depth)
	_fight_depth = depth
	var boss := CheckBox.new()
	boss.name = "FightBoss"
	boss.text = "Boss"
	row.add_child(boss)
	_fight_boss = boss
	var elaia := CheckBox.new()
	elaia.name = "FightElaia"
	elaia.text = "With Elaia"
	elaia.button_pressed = true
	row.add_child(elaia)
	_fight_elaia = elaia
	var open := _add_button(row, "Open fight", _on_fight_at_depth_pressed)
	open.name = "OpenFight"
	open.size_flags_horizontal = Control.SIZE_EXPAND_FILL


func _chosen_depth() -> int:
	if _fight_depth == null:
		return 1
	return clampi(int(_fight_depth.value), 1, 40)


func _on_fight_at_depth_pressed() -> void:
	## Same open_arena() as the arena button. Echo and a reach fight refuse it; the extra checks
	## keep the test fight off a reach fight's overlay even if open_arena() changes.
	if EchoChamber.in_battle or Reach.fight_active() or not BattleView.open_arena():
		_set_status("Battle arena stays closed while Echo or a reach fight is open.")
		return
	var view: BattleView = null
	for node: Node in get_tree().get_nodes_in_group("battle_overlay"):
		if node is BattleView and not node.is_queued_for_deletion():
			view = node as BattleView
	if view == null:
		_set_status("The battle arena did not open.")
		return
	var depth: int = _chosen_depth()
	var boss: bool = _fight_boss != null and _fight_boss.button_pressed
	var with_elaia: bool = _fight_elaia == null or _fight_elaia.button_pressed
	view.start_test_fight(depth, boss, with_elaia, randi() & 0x7FFFFFFF)
	_dismiss_pause()
	AnimPreviewHotkey.set_debug_panel(false)


func _on_batch_sim_pressed() -> void:
	var depth: int = _chosen_depth()
	var started: int = Time.get_ticks_msec()
	var result: Dictionary = BatchSim.run_batch("duo", depth, BATCH_SIZE, randi() & 0x7FFFFFFF)
	var ms: int = Time.get_ticks_msec() - started
	## run_batch reports percents; turn them back into fight counts.
	var n: int = int(result.get("n", BATCH_SIZE))
	var wins: int = roundi(float(result.get("win", 0.0)) * float(n) / 100.0)
	var flees: int = roundi(float(result.get("flee", 0.0)) * float(n) / 100.0)
	var overwhelmed: int = roundi(float(result.get("overwhelmed", 0.0)) * float(n) / 100.0)
	_set_status("Batch-sim %d at depth %d: win %d / flee %d / overwhelmed %d (%d ms)." % [n, depth, wins, flees, overwhelmed, ms])


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
