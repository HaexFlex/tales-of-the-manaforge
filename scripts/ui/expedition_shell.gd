extends Control
class_name ExpeditionShellView
## Expedition board shell (Art mockup 2026-10-11). Built at runtime; expedition_board owns state.

const BOARD_DIR: String = "res://assets/art/ui/board/"
const KIT_DIR: String = "res://assets/art/ui/minigames/kit/"
const BATTLE_UI: String = "res://assets/art/battle/ui/"
const INK: Color = Color(0.243137, 0.164706, 0.0941176, 1.0)
const PARCHMENT: Color = Color(0.86, 0.88, 0.82, 1.0)
const WOOD_9S: int = 6
const FRAME_9S: int = 24
const FIELD_9S: int = 6
const POPUP_9S: int = 8
const ICON_ESSENCE_TEX: String = "res://assets/art/ui/icon_essence.png"
const ESSENCE_TINT: Color = Color(0.78, 0.62, 1.18, 1.0)

var picker_popup: PanelContainer
var picker_rows: Array[Button] = []
var party_slots: Dictionary = {}
var simulate_window: Control
var simulate_scroll: ScrollContainer
var simulate_result: Label
var simulate_close: Button
var simulate_rerun: Button
var essence_icons: Array[TextureRect] = []


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build()


func _build() -> void:
	var dim := ColorRect.new()
	dim.name = "Dim"
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0.58)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)
	var panel: NinePatchRect = _nine_patch("Panel", KIT_DIR + "frame_9s_96.png", FRAME_9S, Vector2(200, 60), Vector2(880, 600))
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(panel)
	_build_panel(panel)


func _build_panel(panel: Control) -> void:
	_add_vines(panel)
	_add_title(panel)
	_add_close(panel)
	_make_label(panel, "Hint", Vector2(224, 84), Vector2(832, 20), 13, PARCHMENT).text = ""
	_make_label(panel, "Lantern", Vector2(224, 104), Vector2(832, 20), 13, Color(0.78, 0.86, 0.9, 1.0))
	_divider(panel, Vector2(224, 128), Vector2(832, 6))
	_party_block(panel)
	_route_block(panel)
	_mode_block(panel)
	_loadout_block(panel)
	_divider(panel, Vector2(224, 424), Vector2(832, 6))
	_make_label(panel, "WarningLabel", Vector2(224, 436), Vector2(832, 52), 12, Color(0.92, 0.82, 0.7, 1.0))
	_add_footer(panel)
	_build_picker()
	_build_simulate_window()
	_add_progress(panel)


func _party_block(panel: Control) -> void:
	_make_label(panel, "PartyTitle", Vector2(224, 140), Vector2(200, 20), 16, INK).text = ""
	var sub := _make_label(panel, "PartyHint", Vector2(224, 158), Vector2(280, 16), 12, PARCHMENT)
	sub.text = ""
	var bed := _nine_patch("FormationBed", KIT_DIR + "play_bevel_9s_6x6.png", 2, Vector2(224, 176), Vector2(360, 242))
	panel.add_child(bed)
	_make_label(panel, "LabelBack", Vector2(248, 188), Vector2(60, 16), 12, INK).text = "Back"
	_make_label(panel, "LabelFront", Vector2(448, 188), Vector2(60, 16), 12, INK).text = "Front"
	var arrow := _tex_rect(panel, BOARD_DIR + "arrow_enemy_side_12x9.png", Vector2(548, 188), Vector2(12, 9))
	arrow.name = "EnemyArrow"
	_make_label(panel, "EnemyLabel", Vector2(564, 188), Vector2(60, 16), 12, PARCHMENT).text = "enemies"
	var defs: Array[Dictionary] = [
		{"name": "SlotBackTop", "row": "back", "cell": 0, "pos": Vector2(248, 208)},
		{"name": "SlotBackMid", "row": "back", "cell": 1, "pos": Vector2(248, 276)},
		{"name": "SlotBackBot", "row": "back", "cell": 2, "pos": Vector2(248, 344)},
		{"name": "SlotFrontTop", "row": "front", "cell": 0, "pos": Vector2(448, 208)},
		{"name": "SlotFrontMid", "row": "front", "cell": 1, "pos": Vector2(448, 276)},
		{"name": "SlotFrontBot", "row": "front", "cell": 2, "pos": Vector2(448, 344)},
	]
	for def: Dictionary in defs:
		var btn := _party_slot_button(str(def["name"]), def["pos"] as Vector2)
		panel.add_child(btn)
		party_slots["%s:%d" % [str(def["row"]), int(def["cell"])]] = btn


func _route_block(panel: Control) -> void:
	_make_label(panel, "RouteTitle", Vector2(616, 140), Vector2(120, 20), 16, INK).text = "Route"
	_make_label(panel, "DepthLabel", Vector2(616, 178), Vector2(100, 16), 14, INK)
	_add_stepper(panel, "Depth", Vector2(728, 172))
	_make_label(panel, "DepthMaxLabel", Vector2(874, 178), Vector2(70, 16), 12, PARCHMENT)
	_make_label(panel, "RoomsLabel", Vector2(616, 218), Vector2(100, 16), 14, INK)
	_add_stepper(panel, "Rooms", Vector2(728, 212))
	_make_label(panel, "RoomsStepNote", Vector2(874, 218), Vector2(70, 16), 12, PARCHMENT).text = "step 5"
	_make_label(panel, "DurationLabel", Vector2(616, 252), Vector2(360, 20), 14, Color(0.78, 0.84, 0.88, 1.0))
	_make_label(panel, "BossLabel", Vector2(616, 276), Vector2(360, 20), 14, Color(0.95, 0.9, 0.72, 1.0))


func _mode_block(panel: Control) -> void:
	_make_label(panel, "ModeTitle", Vector2(224, 428), Vector2(120, 20), 16, INK).text = "Mode"
	var manual := _mode_toggle(panel, "ManualButton", Vector2(224, 452), "Manual")
	var idle := _mode_toggle(panel, "IdleButton", Vector2(360, 452), "Idle")
	manual.toggle_mode = true
	idle.toggle_mode = true
	var group := ButtonGroup.new()
	manual.button_group = group
	idle.button_group = group
	_make_label(panel, "ModeHint", Vector2(224, 488), Vector2(360, 32), 12, PARCHMENT)


func _loadout_block(panel: Control) -> void:
	_make_label(panel, "LoadoutTitle", Vector2(616, 308), Vector2(200, 20), 16, INK).text = "Loadout"
	_divider(panel, Vector2(616, 332), Vector2(328, 6))
	for slot_i: int in range(2):
		var y: int = 344 + slot_i * 52
		var n: int = slot_i + 1
		var slot_btn := Button.new()
		slot_btn.name = "LoadoutItem%d" % n
		slot_btn.position = Vector2(616, y)
		slot_btn.size = Vector2(44, 44)
		slot_btn.flat = true
		panel.add_child(slot_btn)
		_style_item_slot(slot_btn)
		_make_label(panel, "LoadoutName%d" % n, Vector2(668, y + 4), Vector2(120, 16), 12, INK)
		_add_loadout_stepper(panel, n, Vector2(788, y + 8))


func _add_footer(panel: Control) -> void:
	var sim_label: String = "Simulate"
	var strings: Node = get_node_or_null("/root/ContentStrings")
	if strings != null:
		sim_label = str(strings.call("get_text", "board_simulate"))
	var sim := _action_button(panel, "SimulateButton", Vector2(224, 544), sim_label)
	sim.size = Vector2(160, 44)
	var chip := _nine_patch("CostChip", BOARD_DIR + "cost_chip_9s_ok_24x32.png", 8, Vector2(596, 548), Vector2(84, 44))
	panel.add_child(chip)
	var ess_icon := _tex_rect(chip, ICON_ESSENCE_TEX, Vector2(8, 6), Vector2(32, 32))
	ess_icon.name = "EssenceCostIcon"
	ess_icon.modulate = ESSENCE_TINT
	essence_icons.append(ess_icon)
	_make_label(chip, "CostAmount", Vector2(40, 10), Vector2(40, 24), 16, INK).text = "20"
	_make_label(panel, "CostLabel", Vector2(224, 500), Vector2(832, 20), 13, Color(0.82, 0.88, 0.9, 1.0))
	var depart := _action_button(panel, "Depart", Vector2(688, 544), "Depart")
	depart.size = Vector2(160, 44)
	_make_label(panel, "DepartHint", Vector2(688, 592), Vector2(200, 16), 12, PARCHMENT)
	_make_label(panel, "DepartEssenceWarn", Vector2(688, 608), Vector2(200, 16), 12, Color(0.9, 0.45, 0.4, 1.0))


func _add_progress(panel: Control) -> void:
	_make_label(panel, "ProgressLabel", Vector2(224, 176), Vector2(832, 28), 15, Color(0.9, 0.88, 0.78, 1.0))
	_make_label(panel, "PackLabel", Vector2(224, 208), Vector2(832, 24), 14, Color(0.78, 0.84, 0.88, 1.0))
	_make_label(panel, "LoadoutLeftLabel", Vector2(224, 236), Vector2(832, 24), 14, Color(0.78, 0.84, 0.88, 1.0))
	var skip := Button.new()
	skip.name = "SkipRoom"
	skip.text = "Skip room"
	skip.position = Vector2(224, 528)
	skip.size = Vector2(160, 36)
	panel.add_child(skip)
	var rush := Button.new()
	rush.name = "Rush"
	rush.text = "Rush"
	rush.toggle_mode = true
	rush.position = Vector2(396, 528)
	rush.size = Vector2(120, 36)
	panel.add_child(rush)


func _build_picker() -> void:
	picker_popup = PanelContainer.new()
	picker_popup.name = "PickerPopup"
	picker_popup.visible = false
	picker_popup.mouse_filter = Control.MOUSE_FILTER_STOP
	var sb := StyleBoxTexture.new()
	sb.texture = _load_tex(BOARD_DIR + "popup_9s_32x32.png")
	sb.texture_margin_left = POPUP_9S
	sb.texture_margin_top = POPUP_9S
	sb.texture_margin_right = POPUP_9S
	sb.texture_margin_bottom = POPUP_9S
	picker_popup.add_theme_stylebox_override("panel", sb)
	add_child(picker_popup)
	_make_label(picker_popup, "PickerTitle", Vector2(12, 8), Vector2(200, 20), 14, INK)
	for i: int in range(4):
		var row := Button.new()
		row.name = "PickerRow%d" % i
		row.custom_minimum_size = Vector2(220, 54)
		row.position = Vector2(8, 28 + i * 56)
		row.size = Vector2(220, 54)
		row.flat = true
		picker_popup.add_child(row)
		picker_rows.append(row)
	var tail := _tex_rect(picker_popup, BOARD_DIR + "popup_tail_l_8x14.png", Vector2(-6, 0), Vector2(8, 14))
	tail.name = "PickerTail"
	tail.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _build_simulate_window() -> void:
	simulate_window = Control.new()
	simulate_window.name = "SimulateWindow"
	simulate_window.set_anchors_preset(Control.PRESET_FULL_RECT)
	simulate_window.visible = false
	simulate_window.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(simulate_window)
	var veil := ColorRect.new()
	veil.set_anchors_preset(Control.PRESET_FULL_RECT)
	veil.color = Color(0, 0, 0, 0.5)
	veil.mouse_filter = Control.MOUSE_FILTER_STOP
	simulate_window.add_child(veil)
	var frame := _nine_patch("ResultsFrame", KIT_DIR + "frame_9s_96.png", FRAME_9S, Vector2(330, 110), Vector2(620, 500))
	simulate_window.add_child(frame)
	_add_title_plank(simulate_window, Vector2(510, 92), "Simulation")
	simulate_close = _stop_button(simulate_window, "SimulateClose", Vector2(814, 140))
	_make_label(simulate_window, "SimulateHeader", Vector2(356, 144), Vector2(430, 20), 12, PARCHMENT)
	_make_label(simulate_window, "SimulateSummary", Vector2(356, 164), Vector2(430, 20), 16, INK)
	simulate_scroll = ScrollContainer.new()
	simulate_scroll.name = "SimulateScroll"
	simulate_scroll.position = Vector2(354, 192)
	simulate_scroll.size = Vector2(572, 270)
	simulate_window.add_child(simulate_scroll)
	var inner := VBoxContainer.new()
	inner.name = "SimulateList"
	inner.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	simulate_scroll.add_child(inner)
	simulate_result = Label.new()
	simulate_result.name = "SimulateResult"
	simulate_result.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	simulate_result.add_theme_font_size_override("font_size", 12)
	simulate_result.add_theme_color_override("font_color", INK)
	simulate_result.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inner.add_child(simulate_result)
	_make_label(simulate_window, "SimulateLosses", Vector2(356, 474), Vector2(570, 18), 12, INK)
	_make_label(simulate_window, "SimulateTotals", Vector2(356, 496), Vector2(570, 40), 12, INK)
	var totals_ess := _tex_rect(simulate_window, ICON_ESSENCE_TEX, Vector2(700, 494), Vector2(32, 32))
	totals_ess.name = "SimulateEssenceIcon"
	totals_ess.modulate = ESSENCE_TINT
	essence_icons.append(totals_ess)
	_make_label(simulate_window, "SimulateNote", Vector2(356, 554), Vector2(430, 16), 12, PARCHMENT)
	simulate_rerun = _wood_text_button(simulate_window, "SimulateRerun", Vector2(806, 544), Vector2(120, 32), "Run again")


func _add_title(panel: Control) -> void:
	var plate := _tex_rect(panel, KIT_DIR + "title_plate_312x46.png", Vector2(484, 37), Vector2(312, 46))
	plate.name = "TitlePlate"
	var title := _make_label(panel, "Title", Vector2(496, 40), Vector2(288, 40), 18, INK)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER


func _add_title_plank(parent: Control, pos: Vector2, _text: String) -> void:
	var plate := _tex_rect(parent, KIT_DIR + "title_plank_3s_48x40.png", pos, Vector2(260, 40))
	plate.name = "ResultsTitlePlate"


func _add_close(panel: Control) -> void:
	var btn := _stop_button(panel, "CloseButton", Vector2(956, 84))
	btn.text = "Close"
	var esc := _tex_rect(panel, KIT_DIR + "keycap_esc.png", Vector2(1068, 84), Vector2(28, 15))
	esc.name = "CloseEscKeycap"
	esc.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _add_vines(panel: Control) -> void:
	_tex_rect(panel, KIT_DIR + "deco_vine_tl.png", Vector2(-4, -4), Vector2(32, 32))
	_tex_rect(panel, KIT_DIR + "deco_vine_br.png", Vector2(852, 572), Vector2(32, 32))


func _add_loadout_stepper(panel: Control, slot_n: int, pos: Vector2) -> void:
	_add_stepper(panel, "Loadout", pos, false, slot_n)


func _add_stepper(panel: Control, prefix: String, pos: Vector2, _qty_only: bool = false, slot_n: int = 0) -> void:
	var minus_name: String = "%sMinus" % prefix
	var field_name: String = "%sField" % prefix
	var plus_name: String = "%sPlus" % prefix
	if slot_n > 0:
		minus_name = "LoadoutMinus%d" % slot_n
		field_name = "LoadoutQty%d" % slot_n
		plus_name = "LoadoutPlus%d" % slot_n
	var minus := _wood_glyph_button(panel, minus_name, pos, BOARD_DIR + "glyph_minus_10x10.png", BOARD_DIR + "glyph_minus_disabled_10x10.png")
	var field := LineEdit.new()
	field.name = field_name
	field.position = pos + Vector2(32, 0)
	field.size = Vector2(48 if slot_n > 0 else 72, 28)
	field.alignment = HORIZONTAL_ALIGNMENT_CENTER
	field.add_theme_font_size_override("font_size", 16)
	field.add_theme_color_override("font_color", INK)
	_style_field(field)
	panel.add_child(field)
	var plus := _wood_glyph_button(panel, plus_name, pos + Vector2(84 if slot_n > 0 else 108, 0), BOARD_DIR + "glyph_plus_10x10.png", BOARD_DIR + "glyph_plus_disabled_10x10.png")
	if slot_n > 0:
		_make_label(panel, "LoadoutQty%dCap" % slot_n, pos + Vector2(136, 6), Vector2(48, 20), 12, PARCHMENT).text = "/ 100"


func _party_slot_button(node_name: String, pos: Vector2) -> Button:
	var btn := Button.new()
	btn.name = node_name
	btn.position = pos
	btn.size = Vector2(60, 60)
	btn.toggle_mode = false
	btn.flat = true
	_style_party_slot(btn, BOARD_DIR + "party_slot_empty_60x60.png")
	return btn


func _mode_toggle(panel: Control, node_name: String, pos: Vector2, text: String) -> Button:
	var btn := _wood_text_button(panel, node_name, pos, Vector2(120, 32), text)
	btn.toggle_mode = true
	var selected := StyleBoxTexture.new()
	selected.texture = _load_tex(BOARD_DIR + "wood_button_9s_selected_32x28.png")
	selected.texture_margin_left = WOOD_9S
	selected.texture_margin_top = WOOD_9S
	selected.texture_margin_right = WOOD_9S
	selected.texture_margin_bottom = WOOD_9S
	btn.add_theme_stylebox_override("pressed", selected)
	return btn


func _action_button(parent: Control, node_name: String, pos: Vector2, text: String) -> Button:
	var btn := Button.new()
	btn.name = node_name
	btn.position = pos
	btn.text = text
	btn.add_theme_font_size_override("font_size", 14)
	btn.add_theme_color_override("font_color", INK)
	for state: String in ["normal", "hover", "pressed", "disabled"]:
		var suffix: String = state
		var box := StyleBoxTexture.new()
		box.texture = _load_tex("%saction_button_%s_160x44.png" % [BATTLE_UI, suffix])
		btn.add_theme_stylebox_override(state, box)
	parent.add_child(btn)
	return btn


func _stop_button(parent: Control, node_name: String, pos: Vector2) -> Button:
	var btn := Button.new()
	btn.name = node_name
	btn.position = pos
	btn.size = Vector2(104, 28)
	btn.add_theme_font_size_override("font_size", 13)
	btn.add_theme_color_override("font_color", INK)
	for state: String in ["normal", "hover", "pressed", "disabled"]:
		var box := StyleBoxTexture.new()
		box.texture = _load_tex("%sstop_button_%s_104x28.png" % [KIT_DIR, state])
		btn.add_theme_stylebox_override(state, box)
	parent.add_child(btn)
	return btn


func _wood_text_button(parent: Control, node_name: String, pos: Vector2, size: Vector2, text: String) -> Button:
	var btn := Button.new()
	btn.name = node_name
	btn.position = pos
	btn.size = size
	btn.text = text
	btn.add_theme_font_size_override("font_size", 13)
	btn.add_theme_color_override("font_color", INK)
	_style_wood(btn)
	parent.add_child(btn)
	return btn


func _wood_glyph_button(parent: Control, node_name: String, pos: Vector2, glyph: String, glyph_dis: String) -> Button:
	var btn := Button.new()
	btn.name = node_name
	btn.position = pos
	btn.size = Vector2(28, 28)
	_style_wood(btn)
	var icon := TextureRect.new()
	icon.texture = _load_tex(glyph)
	icon.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	icon.custom_minimum_size = Vector2(10, 10)
	icon.size = Vector2(10, 10)
	icon.position = Vector2(9, 9)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(icon)
	btn.set_meta("glyph_disabled", glyph_dis)
	parent.add_child(btn)
	return btn


func _style_wood(btn: Button) -> void:
	for state: String in ["normal", "hover", "pressed", "disabled"]:
		var box := StyleBoxTexture.new()
		box.texture = _load_tex("%swood_button_9s_%s_32x28.png" % [KIT_DIR, state])
		box.texture_margin_left = WOOD_9S
		box.texture_margin_top = WOOD_9S
		box.texture_margin_right = WOOD_9S
		box.texture_margin_bottom = WOOD_9S
		btn.add_theme_stylebox_override(state, box)


func _style_field(field: LineEdit) -> void:
	for state: String in ["normal", "focus", "read_only"]:
		var file: String = "field_9s_%s_24x24.png" % state
		if state == "read_only":
			file = "field_9s_disabled_24x24.png"
		var box := StyleBoxTexture.new()
		box.texture = _load_tex(BOARD_DIR + file)
		box.texture_margin_left = FIELD_9S
		box.texture_margin_top = FIELD_9S
		box.texture_margin_right = FIELD_9S
		box.texture_margin_bottom = FIELD_9S
		var key: String = state
		if state == "read_only":
			key = "disabled"
		field.add_theme_stylebox_override(key, box)
	field.add_theme_stylebox_override("normal", _field_style("field_9s_normal_24x24.png"))


func _field_style(file: String) -> StyleBoxTexture:
	var box := StyleBoxTexture.new()
	box.texture = _load_tex(BOARD_DIR + file)
	box.texture_margin_left = FIELD_9S
	box.texture_margin_top = FIELD_9S
	box.texture_margin_right = FIELD_9S
	box.texture_margin_bottom = FIELD_9S
	return box


func set_field_invalid(field: LineEdit, invalid: bool) -> void:
	if invalid:
		field.add_theme_stylebox_override("normal", _field_style("field_9s_invalid_24x24.png"))
	else:
		field.add_theme_stylebox_override("normal", _field_style("field_9s_normal_24x24.png"))


func _style_party_slot(btn: Button, tex_path: String) -> void:
	var box := StyleBoxTexture.new()
	box.texture = _load_tex(tex_path)
	btn.add_theme_stylebox_override("normal", box)
	btn.add_theme_stylebox_override("hover", box)
	btn.add_theme_stylebox_override("pressed", box)


func _style_item_slot(btn: Button) -> void:
	var normal := StyleBoxTexture.new()
	normal.texture = _load_tex(BOARD_DIR + "item_slot_empty_44x44.png")
	btn.add_theme_stylebox_override("normal", normal)
	var hover := StyleBoxTexture.new()
	hover.texture = _load_tex(BOARD_DIR + "item_slot_hover_44x44.png")
	btn.add_theme_stylebox_override("hover", hover)


func _nine_patch(node_name: String, path: String, margin: int, pos: Vector2, size: Vector2) -> NinePatchRect:
	var np := NinePatchRect.new()
	np.name = node_name
	np.position = pos
	np.size = size
	np.texture = _load_tex(path)
	np.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	np.patch_margin_left = margin
	np.patch_margin_top = margin
	np.patch_margin_right = margin
	np.patch_margin_bottom = margin
	return np


func _tex_rect(parent: Control, path: String, pos: Vector2, size: Vector2) -> TextureRect:
	var tr := TextureRect.new()
	tr.texture = _load_tex(path)
	tr.position = pos
	tr.size = size
	tr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(tr)
	return tr


func _divider(parent: Control, pos: Vector2, size: Vector2) -> void:
	var tr := TextureRect.new()
	tr.texture = _load_tex(BOARD_DIR + "divider_3s_48x6.png")
	tr.position = pos
	tr.size = size
	tr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(tr)


func _make_label(parent: Control, node_name: String, pos: Vector2, sz: Vector2, font_size: int, color: Color) -> Label:
	var lbl := Label.new()
	lbl.name = node_name
	lbl.position = pos
	lbl.size = sz
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.add_theme_font_size_override("font_size", font_size)
	lbl.add_theme_color_override("font_color", color)
	parent.add_child(lbl)
	return lbl


func _load_tex(path: String) -> Texture2D:
	if not ResourceLoader.exists(path):
		return null
	return load(path) as Texture2D


func place_picker(slot_btn: Button) -> void:
	if picker_popup == null or slot_btn == null:
		return
	var h: float = 28.0 + float(picker_rows.size()) * 56.0
	var y: float = clampf(slot_btn.global_position.y - 76.0, 140.0, 418.0 - h)
	picker_popup.position = Vector2(slot_btn.global_position.x + 70.0, y)
	picker_popup.size = Vector2(236, h)
	picker_popup.visible = true


func hide_picker() -> void:
	if picker_popup != null:
		picker_popup.visible = false
