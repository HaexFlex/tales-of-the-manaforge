extends CanvasLayer

const BattleRngScript := preload("res://scripts/battle/battle_rng.gd")
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
	"Wisps idle": "res://tools/debug/snapshots/wisps_idle.json",
}
const SNAPSHOT_ORDER: PackedStringArray = [
	"Pre-Echo", "Forge unlocked", "Elaia joined", "Ancient ready",
	"Echo 2 ready", "North road open", "Pre-boss", "Veteran reacher",
	"Mid-fight", "Wisps idle",
]
const FORCE_LABELS: Dictionary = {
	"flee": "Flee",
	"overwhelmed": "Overwhelmed",
	"win": "Win",
}
const BATCH_SIZE: int = 200
const WIN_SIZE: Vector2 = Vector2(912, 472)
const PAD: float = 24.0
const ROW_H: float = 44.0
const ROW_GAP: float = 8.0
const TAB_GAP: float = 4.0
const HEADER_Y: float = 20.0
const PINS_Y: float = 72.0
const TABS_Y: float = 124.0
const BODY_Y: float = 176.0
const BODY_PAD: float = 12.0
const STATUS_H: float = 24.0
const TAG_W: float = 132.0
const PIN_LABEL_W: float = 70.0
const FIELD_W: float = 110.0
const SCROLL_RESERVE: float = 14.0
const BEVEL_PATH: String = "res://assets/ui/theme/play_bevel_9s_6x6.png"
const TAB_LABELS: PackedStringArray = [
	"Tree", "Items", "Reach", "Party", "Forge", "Runes", "Battle", "Time", "Overlays",
]
var _offline_hours: PackedFloat32Array = PackedFloat32Array([1.0, 8.0, 24.0])
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

const PIN_PATH: String = "user://debug_pins.cfg"

var _pin_panel: Control
var _pin_width: float = 912.0
var _panel: Panel
var _tabs: TabContainer
var _tab_buttons: Array[Button] = []
var _global_search: LineEdit
var _grid_cols: int = 3
var _grid_w: float = 270.0
var _status: Label
var _recipes: Dictionary = {}
var _search: LineEdit
var _qty: SpinBox
var _list: ItemList
var _rows: Array[Dictionary] = []
var _fight_depth: SpinBox
var _fight_boss: CheckBox
var _fight_elaia: CheckBox
var _grant_add_mode: bool = true
var _grant_to_pack: bool = false
var _ancient_timer: SpinBox
var _ancient_freeze: CheckBox
var _reach_depth: SpinBox
var _reach_deepest: SpinBox
var _reach_dojo: SpinBox
var _reach_clears: SpinBox
var _echo_outcome: OptionButton
var _forge_craft_pick: OptionButton
var _blessing_pick: OptionButton
var _blessing_rank: SpinBox
var _rune_pick: OptionButton
var _rune_rank: SpinBox


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load_recipes()
	_load_catalogue()
	_build_ui()


func _layout_debug_panel() -> void:
	if _panel != null:
		Ui540.center_kit_panel(_panel)


func _build_ui() -> void:
	var backdrop := ColorRect.new()
	backdrop.name = "Backdrop"
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.color = Color(0, 0, 0, 0.5)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(backdrop)

	var panel := Panel.new()
	panel.name = "Panel"
	panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(panel)
	_panel = panel
	Ui540.apply_kit_panel(panel, "debug")
	var sz: Vector2 = Ui540.fit_kit_window(panel, WIN_SIZE)
	call_deferred("_layout_debug_panel")

	var title := Label.new()
	title.name = "Title"
	title.text = "Debug"
	panel.add_child(title)
	Ui540.place_title_plank(title, sz.x)
	var close_icon := Button.new()
	close_icon.name = "CloseIcon"
	Ui540.configure_kit_close_button(close_icon)
	Ui540.place_close_button(close_icon, sz.x)
	close_icon.tooltip_text = "Close (Ctrl+F8)"
	close_icon.pressed.connect(_on_close_pressed)
	panel.add_child(close_icon)

	var tag := Label.new()
	tag.name = "BuildTag"
	tag.text = "debug · %s" % str(ProjectSettings.get_setting("application/config/version", "dev"))
	tag.tooltip_text = "Ctrl+F8  ·  testing build"
	tag.mouse_filter = Control.MOUSE_FILTER_PASS
	_style_line_label(tag, true)
	panel.add_child(tag)
	Ui540.anchor_rect_safe(tag, PAD, HEADER_Y, TAG_W, ROW_H)
	_global_search = LineEdit.new()
	_global_search.name = "SearchAll"
	_global_search.placeholder_text = "Search all tabs…"
	_global_search.clear_button_enabled = true
	_global_search.text_changed.connect(_on_global_search)
	panel.add_child(_global_search)
	var search_x: float = PAD + TAG_W + ROW_GAP
	Ui540.anchor_rect_safe(_global_search, search_x, HEADER_Y, close_icon.position.x - 12.0 - search_x, ROW_H)

	var pin_label := Label.new()
	pin_label.name = "PinnedLabel"
	pin_label.text = "Pinned"
	_style_line_label(pin_label, true)
	panel.add_child(pin_label)
	Ui540.anchor_rect_safe(pin_label, PAD, PINS_Y, PIN_LABEL_W, ROW_H)
	_pin_panel = panel
	_pin_width = sz.x
	_fill_pin_row()

	var body_w: float = sz.x - PAD * 2.0
	var body_h: float = sz.y - PAD - BODY_Y
	var body := Panel.new()
	body.name = "TabBody"
	body.add_theme_stylebox_override("panel", Ui540.kit_stylebox_9s(BEVEL_PATH, Vector4i(2, 2, 2, 2)))
	panel.add_child(body)
	Ui540.anchor_rect_safe(body, PAD, BODY_Y, body_w, body_h)
	_status = Label.new()
	_status.name = "Status"
	_status.text = "Ready."
	_style_line_label(_status, false)
	_status.mouse_filter = Control.MOUSE_FILTER_PASS
	body.add_child(_status)
	Ui540.anchor_rect_safe(_status, BODY_PAD, 8.0, body_w - BODY_PAD * 2.0, STATUS_H)

	_grid_cols = 2 if Ui540.is_phone_export() else 3
	var page_w: float = body_w - BODY_PAD * 2.0
	_grid_w = floorf((page_w - SCROLL_RESERVE - ROW_GAP * float(_grid_cols - 1)) / float(_grid_cols))
	var tabs := TabContainer.new()
	tabs.name = "DebugTabs"
	tabs.tabs_visible = false
	tabs.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	body.add_child(tabs)
	Ui540.anchor_rect_safe(tabs, BODY_PAD, 8.0 + STATUS_H + 6.0, page_w, body_h - STATUS_H - 24.0)
	_tabs = tabs
	_build_tab_tree(tabs)
	_build_tab_resources(tabs)
	_build_tab_reach(tabs)
	_build_tab_party(tabs)
	_build_tab_forge(tabs)
	_build_tab_runes(tabs)
	_build_tab_battle(tabs)
	_build_tab_time_save(tabs)
	_build_tab_overlays(tabs)

	var tab_count: int = tabs.get_tab_count()
	var tab_w: float = floorf((body_w - TAB_GAP * float(tab_count - 1)) / float(tab_count))
	var group := ButtonGroup.new()
	for i: int in tab_count:
		var tab := Button.new()
		tab.name = "Tab%s" % TAB_LABELS[i]
		tab.text = TAB_LABELS[i]
		GameTheme.style_tab_button(tab)
		tab.button_group = group
		tab.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		tab.tooltip_text = tabs.get_tab_title(i)
		tab.pressed.connect(_select_tab.bind(i))
		panel.add_child(tab)
		Ui540.anchor_rect_safe(tab, PAD + float(i) * (tab_w + TAB_GAP), TABS_Y, tab_w, ROW_H)
		tabs.set_tab_title(i, TAB_LABELS[i])
		_tab_buttons.append(tab)
	_tabs.tab_changed.connect(_sync_tab_highlight)
	_select_tab(0)


func _style_line_label(lbl: Label, muted: bool) -> void:
	GameTheme.style_ink_label(lbl, muted)
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.autowrap_mode = TextServer.AUTOWRAP_OFF
	lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	lbl.clip_text = true


func _select_tab(index: int) -> void:
	if _tabs == null or index < 0 or index >= _tabs.get_tab_count():
		return
	_tabs.current_tab = index
	_sync_tab_highlight(index)


func _sync_tab_highlight(index: int) -> void:
	for i: int in _tab_buttons.size():
		_tab_buttons[i].set_pressed_no_signal(i == index)


func _on_global_search(text: String) -> void:
	if _tabs == null:
		return
	var query: String = text.strip_edges().to_lower()
	var first_hit: int = -1
	var current_hits: int = 0
	for i: int in _tabs.get_tab_count():
		var hits: int = 0
		for node: Node in _tabs.get_tab_control(i).find_children("*", "Button", true, false):
			var button: Button = node as Button
			if button == null or not button.get_parent().has_meta(&"auto_grid"):
				continue
			button.visible = query == "" or button.text.to_lower().contains(query)
			if button.visible:
				hits += 1
		if i < _tab_buttons.size():
			_tab_buttons[i].disabled = query != "" and hits == 0
		if hits > 0 and first_hit < 0:
			first_hit = i
		if i == _tabs.current_tab:
			current_hits = hits
	if query != "" and current_hits == 0 and first_hit >= 0:
		_select_tab(first_hit)


func _pin_catalog() -> Dictionary:
	return {
		"go_shop": ["Go to shop", _on_ascension_pressed],
		"skip_station": ["Skip station work", _on_skip_pressed],
		"manashards": ["+1000 Manashards", _on_pin_manashards],
		"ancient_ready": ["Ancient ready", _on_snapshot_pressed.bind(str(SNAPSHOTS["Ancient ready"]), "Ancient ready")],
	}


func _default_pins() -> PackedStringArray:
	return PackedStringArray(["go_shop", "skip_station", "manashards", "ancient_ready"])


func _load_pin_ids() -> PackedStringArray:
	var defaults: PackedStringArray = _default_pins()
	var cfg := ConfigFile.new()
	if cfg.load(PIN_PATH) != OK:
		_save_pin_ids(defaults)
		return defaults
	var raw: Variant = cfg.get_value("pins", "ids", defaults)
	if raw is PackedStringArray and not (raw as PackedStringArray).is_empty():
		return raw as PackedStringArray
	return defaults


func _save_pin_ids(ids: PackedStringArray) -> void:
	var cfg := ConfigFile.new()
	cfg.load(PIN_PATH)
	cfg.set_value("pins", "ids", ids)
	cfg.save(PIN_PATH)


func _fill_pin_row() -> void:
	if _pin_panel == null:
		return
	for child: Node in _pin_panel.get_children():
		if str(child.name).begins_with("Pin"):
			child.queue_free()
	var catalog: Dictionary = _pin_catalog()
	var ids: PackedStringArray = _load_pin_ids()
	var shown: PackedStringArray = PackedStringArray()
	for id: String in ids:
		if catalog.has(id):
			shown.append(id)
	if shown.is_empty():
		return
	var star: String = "★ " if GameTheme.body_font().has_char(0x2605) else ""
	var pin_x: float = PAD + PIN_LABEL_W
	var pin_w: float = floorf((_pin_width - PAD - pin_x - ROW_GAP * float(shown.size() - 1)) / float(shown.size()))
	for i: int in shown.size():
		var entry: Array = catalog[shown[i]]
		var pin: Button = _make_button(star + str(entry[0]), entry[1] as Callable, true)
		pin.name = "Pin%d" % i
		pin.tooltip_text = "Right-click to unpin. Pins are kept in user://debug_pins.cfg."
		pin.gui_input.connect(_on_pin_gui.bind(shown[i]))
		_pin_panel.add_child(pin)
		Ui540.anchor_rect_safe(pin, pin_x + float(i) * (pin_w + ROW_GAP), PINS_Y, pin_w, ROW_H)


func _on_pin_gui(event: InputEvent, pin_id: String) -> void:
	if not (event is InputEventMouseButton):
		return
	var mb: InputEventMouseButton = event as InputEventMouseButton
	if not mb.pressed or mb.button_index != MOUSE_BUTTON_RIGHT:
		return
	var ids: PackedStringArray = _load_pin_ids()
	var next := PackedStringArray()
	for id: String in ids:
		if id != pin_id:
			next.append(id)
	if next.is_empty():
		next = _default_pins()
	_save_pin_ids(next)
	_fill_pin_row()
	get_viewport().set_input_as_handled()


func _on_dev_speed(scale: float) -> void:
	Engine.time_scale = scale
	var jobs: Node = get_node_or_null("/root/ForgeJobs")
	if jobs != null and jobs.has_method("set_dev_speed_override"):
		jobs.call("set_dev_speed_override", scale)
	if _status:
		_status.text = "Dev speed %s×" % str(scale)


func _on_pin_manashards() -> void:
	GameState.add_resource(&"manashards", 1000)
	_set_status("+1000 Manashards.")


func _tab_scroll(parent: TabContainer, title: String) -> VBoxContainer:
	var scroll := ScrollContainer.new()
	scroll.name = title.replace(" ", "")
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	parent.add_child(scroll)
	parent.set_tab_title(parent.get_tab_count() - 1, title)
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", int(ROW_GAP))
	box.set_meta(&"debug_tab", true)
	scroll.add_child(box)
	return box


## Free-width buttons in a tab flow into a shared grid of equal columns.
func _tab_grid(box: Container) -> GridContainer:
	var count: int = box.get_child_count()
	var last: Node = box.get_child(count - 1) if count > 0 else null
	if last is GridContainer and last.has_meta(&"auto_grid"):
		return last as GridContainer
	var grid := GridContainer.new()
	grid.columns = _grid_cols
	grid.add_theme_constant_override("h_separation", int(ROW_GAP))
	grid.add_theme_constant_override("v_separation", int(ROW_GAP))
	grid.set_meta(&"auto_grid", true)
	box.add_child(grid)
	return grid


func _row(parent: Container) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", int(ROW_GAP))
	parent.add_child(row)
	return row


func _row_label(row: Container, text: String, width: float = 0.0) -> Label:
	var lbl := Label.new()
	lbl.text = text
	GameTheme.style_ink_label(lbl)
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.custom_minimum_size = Vector2(width, ROW_H)
	row.add_child(lbl)
	return lbl


func _field_spin(row: Container, min_v: int, max_v: int, val: int, width: float = FIELD_W) -> SpinBox:
	var spin := SpinBox.new()
	spin.min_value = min_v
	spin.max_value = max_v
	spin.value = val
	spin.rounded = true
	spin.custom_minimum_size = Vector2(width, ROW_H)
	row.add_child(spin)
	return spin


func _switch(row: Container, text: String) -> CheckBox:
	var toggle := CheckBox.new()
	toggle.text = text
	toggle.custom_minimum_size = Vector2(0, ROW_H)
	row.add_child(toggle)
	return toggle


func _picker(row: Container, width: float) -> OptionButton:
	var pick := OptionButton.new()
	pick.custom_minimum_size = Vector2(width, ROW_H)
	pick.fit_to_longest_item = false
	pick.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	row.add_child(pick)
	return pick


## Two or more toggle chips sharing one group; `on_pick` gets the chosen index.
func _segmented(row: Container, labels: PackedStringArray, picked: int, width: float, on_pick: Callable) -> void:
	var group := ButtonGroup.new()
	for i: int in labels.size():
		var chip := Button.new()
		chip.text = labels[i]
		GameTheme.style_tab_button(chip)
		chip.button_group = group
		chip.custom_minimum_size = Vector2(width, ROW_H)
		chip.button_pressed = i == picked
		chip.pressed.connect(on_pick.bind(i))
		row.add_child(chip)


func _build_tab_time_save(tabs: TabContainer) -> void:
	var box := _tab_scroll(tabs, "Time & Save")
	_add_section(box, "Snapshots")
	for label: String in SNAPSHOT_ORDER:
		_add_button(box, label, _on_snapshot_pressed.bind(str(SNAPSHOTS[label]), label))
	_add_section(box, "Offline skip")
	for h: float in _offline_hours:
		_add_button(box, "Skip offline %.0f h" % h, _on_offline_skip.bind(h))
	_add_section(box, "Dev speed")
	var speed_row := _row(box)
	for scale: int in [1, 2, 4, 8, 16]:
		_add_button(speed_row, "%d×" % scale, _on_dev_speed.bind(float(scale)))
	_add_section(box, "Save")
	_add_button(box, "Dump save JSON", _on_dump_save)
	_add_button(box, "Reset game (confirm)", _on_reset_game)


func _build_tab_resources(tabs: TabContainer) -> void:
	var box := _tab_scroll(tabs, "Resources & Items")
	var mode_row := _row(box)
	_segmented(mode_row, PackedStringArray(["Add", "Set"]), 0, 72.0, func(i: int) -> void:
		_grant_add_mode = i == 0
	)
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(16, 0)
	mode_row.add_child(gap)
	_segmented(mode_row, PackedStringArray(["Backpack", "Reach pack"]), 0, 120.0, func(i: int) -> void:
		_grant_to_pack = i == 1
	)
	_build_catalogue(box)
	for preset: int in [10, 100, 1000]:
		_add_button(box, "+%d" % preset, _on_preset_grant.bind(preset))


func _build_tab_forge(tabs: TabContainer) -> void:
	var box := _tab_scroll(tabs, "Forge")
	var row := _row(box)
	_forge_craft_pick = _picker(row, 260.0)
	for rid: String in _free_crafts:
		_forge_craft_pick.add_item(_pretty(rid), _forge_craft_pick.item_count)
	_add_button(row, "Test craft recipe", _on_forge_craft_picked)
	_add_button(box, "Skip station work", _on_skip_pressed)


func _build_tab_tree(tabs: TabContainer) -> void:
	var box := _tab_scroll(tabs, "Tree & Ascension")
	var timer_row := _row(box)
	_row_label(timer_row, "Ancient timer (s)", 140.0)
	_ancient_timer = _field_spin(timer_row, 0, 3600, 0)
	_add_button(timer_row, "Set", _on_apply_ancient_timer).custom_minimum_size.x = 90.0
	_ancient_freeze = _switch(timer_row, "Freeze")
	_add_button(box, "Commit Fruit", _on_debug_commit_fruit)
	_add_button(box, "Cancel Fruit commit", _on_debug_cancel_fruit)
	_add_button(box, "Grow one stage", _on_grow_stage)
	_add_button(box, "Go to Ascension shop", _on_ascension_pressed)
	_add_button(box, "Reset all blessing ranks", _on_reset_blessings)
	_add_section(box, "Blessing rank")
	var bless_row := _row(box)
	_blessing_pick = _picker(bless_row, 300.0)
	for entry: Variant in GameState.upgrades_data:
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var uid: String = str((entry as Dictionary).get("id", ""))
		if uid != "":
			_blessing_pick.add_item(uid)
	_blessing_rank = _field_spin(bless_row, 0, 999, 0)
	_add_button(bless_row, "Set blessing rank", _on_set_blessing_rank)


func _build_tab_reach(tabs: TabContainer) -> void:
	var box := _tab_scroll(tabs, "Reach")
	var row := _row(box)
	_reach_depth = _labeled_spin(row, "Depth", 1, 99, 1)
	_reach_deepest = _labeled_spin(row, "Deepest", 1, 99, 1)
	_reach_dojo = _labeled_spin(row, "Dojo exp", 0, 99999, 0)
	_reach_clears = _labeled_spin(row, "Clears", 0, 99, 0)
	_add_button(box, "Apply reach stats", _on_apply_reach_stats)
	_add_button(box, "Mossmite room roll", _on_room_roll)
	_add_button(box, "Finish run (finished)", _on_finish_run.bind("finished"))
	_add_button(box, "Finish run (flee)", _on_finish_run.bind("flee"))
	_add_section(box, "Force the next idle room")
	for outcome: String in ["flee", "overwhelmed", "win"]:
		_add_button(box, "Force next room: %s" % FORCE_LABELS[outcome], _on_force_pressed.bind(outcome))
	_add_section(box, "Queue several outcomes")
	for outcome: String in ["flee", "overwhelmed", "win"]:
		_add_button(box, "Queue outcome: %s" % FORCE_LABELS[outcome], _on_queue_force.bind(outcome))
	_add_button(box, "Apply queued outcomes", _on_apply_force_queue)


func _build_tab_party(tabs: TabContainer) -> void:
	var box := _tab_scroll(tabs, "Party")
	_add_button(box, "Launch Echo 2 (portal)", _on_echo2_pressed)
	var bramble := _add_button(box, "Recruit Bramble [ON HOLD]", _on_bramble_hold)
	bramble.disabled = true
	bramble.tooltip_text = "Bramble is ON HOLD — not implemented."
	_add_section(box, "Echo 2 outcome")
	var row := _row(box)
	_echo_outcome = _picker(row, 160.0)
	_echo_outcome.add_item("spare")
	_echo_outcome.add_item("flee")
	_echo_outcome.add_item("ko")
	_add_button(row, "Apply Echo 2 outcome (resolved)", _on_apply_echo2)


func _build_tab_runes(tabs: TabContainer) -> void:
	var box := _tab_scroll(tabs, "Runestones")
	_add_section(box, "Runestone ranks")
	var row := _row(box)
	_rune_pick = _picker(row, 200.0)
	for sid: StringName in KeeperStats.STAT_ORDER:
		_rune_pick.add_item(String(sid))
	_rune_rank = _field_spin(row, 0, 9999, 0)
	_add_button(row, "Set runestone rank", _on_set_rune_rank)


func _build_tab_overlays(tabs: TabContainer) -> void:
	var box := _tab_scroll(tabs, "Visual / Debug overlays")
	_add_button(box, "Toggle debug panel (close)", _on_close_pressed)
	_add_button(box, "Open Steeping", func() -> void:
		if not has_node("/root/MinigameHost"):
			_set_status("Steeping needs the minigame host.")
			return
		var opened: bool = bool(MinigameHost.call("debug_open", "steeping"))
		_set_status("Steeping opened." if opened else "Could not open Steeping.")
	)
	_add_button(box, "Open AnimPreview scene", func() -> void:
		var path: String = "res://tools/AnimPreview.tscn"
		if ResourceLoader.exists(path):
			get_tree().call_deferred("change_scene_to_file", path)
	)


func _build_tab_battle(tabs: TabContainer) -> void:
	var box := _tab_scroll(tabs, "Battle")
	_build_fight_at_depth(box)
	_add_button(box, "Jump to Echo", _on_echo_pressed)
	_add_button(box, "Open arena (empty)", _on_battle_arena_pressed)
	_add_button(box, "Batch-sim %d" % BATCH_SIZE, _on_batch_sim_pressed)


func _labeled_spin(parent: HBoxContainer, label: String, min_v: int, max_v: int, val: int) -> SpinBox:
	_row_label(parent, label)
	return _field_spin(parent, min_v, max_v, val, 88.0)


var _force_queue: Array[String] = []


func _on_offline_skip(hours: float) -> void:
	var eff: float = GameState.debug_skip_offline_hours(hours)
	_set_status("Offline skip %.0f h (effective %.1f s)." % [hours, eff])


func _on_dump_save() -> void:
	var data: Dictionary = GameState.to_save_dict()
	_set_status(JSON.stringify(data).substr(0, 400) + "…")


func _on_reset_game() -> void:
	GameState.reset_for_new_game()
	if has_node("/root/Reach"):
		Reach.reset_for_new_game()
	if has_node("/root/ForgeJobs"):
		ForgeJobs.reset_for_new_game()
	if has_node("/root/Backpack"):
		Backpack.reset_for_new_game()
	if has_node("/root/KeeperStats"):
		KeeperStats.reset_for_new_game()
	_set_status("Game reset.")


func _on_preset_grant(amount: int) -> void:
	if _list == null or _list.get_selected_items().is_empty():
		_set_status("Pick a catalogue row first.")
		return
	_on_catalogue_add_with(amount)


func _on_forge_craft_picked() -> void:
	if _forge_craft_pick == null:
		return
	var rid: String = _free_crafts[_forge_craft_pick.selected]
	_on_free_craft_pressed(rid)


func _on_apply_ancient_timer() -> void:
	var frozen: bool = _ancient_freeze != null and _ancient_freeze.button_pressed
	GameState.debug_set_ancient_timer(float(_ancient_timer.value) if _ancient_timer else 0.0, frozen)
	_set_status("Ancient timer set.")


func _on_debug_commit_fruit() -> void:
	GameState.debug_commit_fruit()
	_set_status("Fruit committed." if GameState.fruit_committed else "Could not commit Fruit.")


func _on_debug_cancel_fruit() -> void:
	GameState.debug_cancel_fruit()
	_set_status("Fruit commit cancelled.")


func _on_grow_stage() -> void:
	var result: String = GameState.try_grow_stage()
	_set_status("Grow: %s" % result)


func _on_set_blessing_rank() -> void:
	if _blessing_pick == null:
		return
	GameState.debug_set_upgrade_rank(_blessing_pick.get_item_text(_blessing_pick.selected), int(_blessing_rank.value))
	_set_status("Blessing rank set.")


func _on_reset_blessings() -> void:
	GameState.debug_reset_upgrade_ranks()
	_set_status("Blessing ranks reset.")


func _on_apply_reach_stats() -> void:
	Reach.debug_set_depths(int(_reach_depth.value), int(_reach_deepest.value))
	Reach.debug_set_dojo_exp(int(_reach_dojo.value))
	Reach.debug_set_reaches_cleared(int(_reach_clears.value))
	_set_status("Reach stats applied.")


func _on_queue_force(outcome: String) -> void:
	_force_queue.append(outcome)
	_set_status("Queued %s (%d)." % [outcome, _force_queue.size()])


func _on_apply_force_queue() -> void:
	if _force_queue.is_empty():
		_set_status("No outcomes queued.")
		return
	Reach.debug_force_outcomes(_force_queue.duplicate())
	_force_queue.clear()
	_set_status("Outcomes queued for next rooms.")


func _on_finish_run(reason: String) -> void:
	Reach.debug_finish_run(reason)
	_set_status("Finish run: %s." % reason)


func _on_room_roll() -> void:
	var depth: int = int(_reach_depth.value) if _reach_depth else 1
	var boss: bool = _fight_boss != null and _fight_boss.button_pressed
	var rng: BattleRng = BattleRngScript.new()
	rng.seed = randi() & 0x7FFFFFFF
	var roll: Array = SpawnRoller.roll_room_with_mossmites(depth, rng, boss)
	_set_status("Room roll d%d (%d slots): %s" % [depth, roll.size(), JSON.stringify(roll)])


func _on_echo2_pressed() -> void:
	GameState.portal_unlocked = true
	GameState.echo_02_fee_paid = true
	GameState.echo_flags_changed.emit()
	_set_status("Echo 2 portal fees waived — use adventure board.")


func _on_apply_echo2() -> void:
	if _echo_outcome == null:
		return
	var outcome: String = _echo_outcome.get_item_text(_echo_outcome.selected)
	Reach.debug_set_echo_02(true, outcome, true)
	_set_status("Echo 2 resolved: %s." % outcome)


func _on_bramble_hold() -> void:
	_set_status("Recruit Bramble is ON HOLD.")


func _on_set_rune_rank() -> void:
	if _rune_pick == null:
		return
	var sid: String = _rune_pick.get_item_text(_rune_pick.selected)
	KeeperStats.set_rank(sid, int(_rune_rank.value))
	_set_status("Runestone %s rank %d." % [sid, int(_rune_rank.value)])


func _add_section(parent: Container, text: String) -> void:
	var label := Label.new()
	label.text = text
	GameTheme.style_ink_label(label, true)
	label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	label.custom_minimum_size = Vector2(0, 28)
	parent.add_child(label)


## Buttons added straight to a tab flow into its grid; buttons added to a row keep their text width.
func _add_button(parent: Container, text: String, callback: Callable) -> Button:
	var in_grid: bool = parent.has_meta(&"debug_tab")
	var button: Button = _make_button(text, callback, in_grid)
	if in_grid:
		button.custom_minimum_size.x = _grid_w
		_tab_grid(parent).add_child(button)
	else:
		parent.add_child(button)
	return button


func _make_button(text: String, callback: Callable, trims: bool) -> Button:
	var button := Button.new()
	button.text = text
	GameTheme.style_wood_button(button)
	button.custom_minimum_size = Vector2(0, ROW_H)
	if trims:
		button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		button.tooltip_text = text
	button.pressed.connect(callback)
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


func _build_catalogue(parent: Container) -> void:
	var row := _row(parent)
	var search := LineEdit.new()
	search.name = "ItemSearch"
	search.placeholder_text = "Search items and materials"
	search.custom_minimum_size = Vector2(0, ROW_H)
	search.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	search.text_changed.connect(_on_catalogue_filter)
	row.add_child(search)
	_search = search
	_row_label(row, "Quantity")
	var qty: SpinBox = _field_spin(row, 1, 999, 1)
	qty.name = "ItemQuantity"
	_qty = qty
	var add: Button = _add_button(row, "Add selected", _on_catalogue_add)
	add.name = "AddItem"
	var list := ItemList.new()
	list.name = "ItemCatalogue"
	list.custom_minimum_size = Vector2(0, 132)
	list.select_mode = ItemList.SELECT_SINGLE
	list.add_theme_stylebox_override("panel", Ui540.kit_stylebox_9s(BEVEL_PATH, Vector4i(2, 2, 2, 2), Vector4(8, 6, 8, 6)))
	list.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	for state: StringName in [&"selected", &"selected_focus", &"cursor", &"cursor_unfocused"]:
		list.add_theme_stylebox_override(state, Ui540.list_row_style(true))
	list.add_theme_stylebox_override("hovered", Ui540.list_row_style(false))
	list.add_theme_font_override("font", GameTheme.body_font())
	list.add_theme_font_size_override("font_size", GameTheme.BODY_SIZE)
	for color: StringName in [&"font_color", &"font_hovered_color", &"font_selected_color"]:
		list.add_theme_color_override(color, GameTheme.INK)
	list.add_theme_color_override("guide_color", Color(GameTheme.INK, 0.15))
	parent.add_child(list)
	_list = list
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
	var qty: int = 1
	if _qty != null:
		qty = maxi(1, int(_qty.value))
	_on_catalogue_add_with(qty)


func _on_catalogue_add_with(qty: int) -> void:
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
	var id: String = str(row.get("id", ""))
	var kind: String = str(row.get("kind", "item"))
	if _grant_to_pack and kind != "resource" and kind != "gear":
		if not Reach.running:
			_set_status("Start a reach run to fill the pack.")
			return
		Reach.debug_add_pack(id, qty)
		_set_status("Pack +%d %s." % [qty, id])
		return
	if kind == "resource":
		if _grant_add_mode:
			GameState.add_resource(StringName(id), qty)
		else:
			GameState.debug_set_resource_exact(StringName(id), qty)
	elif kind == "gear":
		if not _grant_add_mode:
			_set_status("Set mode is for resources only.")
			return
		if not Equipment.add_gear(id, qty):
			_set_status("Could not add %s." % str(row.get("label", id)))
			return
	else:
		if not _grant_add_mode:
			Backpack.set_count(id, qty)
		else:
			Backpack.add_item(id, qty)
	var verb: String = "Added" if _grant_add_mode else "Set"
	_set_status("%s %d %s." % [verb, qty, str(row.get("label", id))])


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


func _build_fight_at_depth(parent: Container) -> void:
	var row := _row(parent)
	row.name = "FightAtDepthRow"
	_row_label(row, "Fight at depth")
	var depth: SpinBox = _field_spin(row, 1, 40, 1, 88.0)
	depth.name = "FightDepth"
	_fight_depth = depth
	var boss: CheckBox = _switch(row, "Boss")
	boss.name = "FightBoss"
	_fight_boss = boss
	var elaia: CheckBox = _switch(row, "With Elaia")
	elaia.name = "FightElaia"
	elaia.button_pressed = true
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
		_status.tooltip_text = text
