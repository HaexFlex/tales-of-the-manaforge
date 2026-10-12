extends Control
class_name ExpeditionShellView
## Expedition board shell (Art mockup 2026-10-11). Built at runtime; expedition_board owns state.

const BOARD_DIR: String = "res://assets/art/ui/board/"
const KIT_DIR: String = "res://assets/art/ui/minigames/kit/"
const BATTLE_UI: String = "res://assets/art/battle/ui/"
const PANEL_ORIGIN: Vector2 = Vector2(200, 60)
const SIM_ORIGIN: Vector2 = Vector2(330, 110)
const SIM_SIZE: Vector2 = Vector2(548, 500)
const INK: Color = Color(0.243137, 0.164706, 0.0941176, 1.0) # #3E2A18
const INK_SECONDARY: Color = Color(0.368627, 0.321569, 0.266667, 1.0) # #5E5244
const WOOD_9S: int = 6
const FRAME_9S: int = 24
const FIELD_9S: int = 6
const POPUP_9S: int = 8
const PICK_ROW_9S: int = 6
const PICKER_POPUP_W: float = 236.0
const PICKER_POPUP_MAX_H: float = 262.0
const PICKER_ROW_H: float = 54.0
const PICKER_ROW_GAP: float = 2.0
const PICKER_ROW_POOL: int = 16
const PICKER_SCROLL_MAX_H: float = PICKER_POPUP_MAX_H - 34.0
const ICON_ESSENCE_TEX: String = "res://assets/art/ui/icon_essence.png"
const ESSENCE_TINT: Color = Color(0.78, 0.62, 1.18, 1.0)

var picker_popup: PanelContainer
var picker_title: Label
var picker_scroll: ScrollContainer
var picker_list: VBoxContainer
var picker_tail: TextureRect
var picker_rows: Array[Button] = []
var party_slots: Dictionary = {}
var simulate_modal: Control
var simulate_window: Control
var simulate_scroll: ScrollContainer
var simulate_room_list: VBoxContainer
var simulate_footer: VBoxContainer
var simulate_result: Label
var simulate_close: Button
var simulate_rerun: Button
var simulate_essence_icon: TextureRect
var essence_icons: Array[TextureRect] = []


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build()


func _scr(screen_pos: Vector2) -> Vector2:
	return screen_pos - PANEL_ORIGIN


func _sim_local(screen_pos: Vector2) -> Vector2:
	return screen_pos - SIM_ORIGIN


func _build() -> void:
	var dim := ColorRect.new()
	dim.name = "Dim"
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0.58)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)
	var panel: NinePatchRect = _nine_patch("Panel", KIT_DIR + "frame_9s_96.png", FRAME_9S, PANEL_ORIGIN, Vector2(880, 600))
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.clip_contents = false  # the title plate and vines sit above the panel edge
	add_child(panel)
	_build_panel(panel)


func _build_panel(panel: Control) -> void:
	_add_vines(panel)
	_add_title(panel)
	_add_close(panel)
	_make_label(panel, "Hint", _scr(Vector2(244, 92)), Vector2(680, 18), 14, INK).text = ""
	_make_label(panel, "Lantern", _scr(Vector2(244, 114)), Vector2(680, 16), 12, INK_SECONDARY).text = ""
	_divider(panel, "DividerTop", _scr(Vector2(244, 136)), Vector2(796, 6))
	_party_block(panel)
	_route_block(panel)
	_mode_block(panel)
	_loadout_block(panel)
	_add_bottom_copy(panel)
	_add_footer(panel)
	_build_picker()
	_build_simulate_window()
	_add_progress(panel)


func _party_block(panel: Control) -> void:
	_make_label(panel, "PartyTitle", _scr(Vector2(244, 148)), Vector2(200, 20), 16, INK).text = ""
	var sub := _make_label(panel, "PartyHint", _scr(Vector2(340, 150)), Vector2(200, 16), 12, INK_SECONDARY)
	sub.text = ""
	var bed := _nine_patch("FormationBed", KIT_DIR + "play_bevel_9s_6x6.png", 2, _scr(Vector2(244, 172)), Vector2(340, 246))
	bed.clip_contents = true
	panel.add_child(bed)
	_make_label(panel, "LabelBack", _scr(Vector2(264, 398)), Vector2(60, 14), 12, INK_SECONDARY).text = "Back"
	_make_label(panel, "LabelFront", _scr(Vector2(414, 398)), Vector2(60, 14), 12, INK_SECONDARY).text = "Front"
	var arrow := _tex_rect(panel, BOARD_DIR + "arrow_enemy_side_12x9.png", _scr(Vector2(504, 184)), Vector2(12, 9))
	arrow.name = "EnemyArrow"
	var enemy_lbl := _make_label(panel, "EnemyLabel", _scr(Vector2(520, 182)), Vector2(64, 16), 12, INK_SECONDARY)
	enemy_lbl.text = "enemies"
	enemy_lbl.autowrap_mode = TextServer.AUTOWRAP_OFF
	enemy_lbl.clip_text = true
	enemy_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	var defs: Array[Dictionary] = [
		{"name": "SlotBackTop", "row": "back", "cell": 0, "pos": _scr(Vector2(264, 196))},
		{"name": "SlotBackMid", "row": "back", "cell": 1, "pos": _scr(Vector2(294, 266))},
		{"name": "SlotBackBot", "row": "back", "cell": 2, "pos": _scr(Vector2(264, 336))},
		{"name": "SlotFrontTop", "row": "front", "cell": 0, "pos": _scr(Vector2(414, 196))},
		{"name": "SlotFrontMid", "row": "front", "cell": 1, "pos": _scr(Vector2(444, 266))},
		{"name": "SlotFrontBot", "row": "front", "cell": 2, "pos": _scr(Vector2(414, 336))},
	]
	for def: Dictionary in defs:
		var btn := _party_slot_button(str(def["name"]), def["pos"] as Vector2)
		panel.add_child(btn)
		party_slots["%s:%d" % [str(def["row"]), int(def["cell"])]] = btn


func _route_block(panel: Control) -> void:
	_make_label(panel, "RouteTitle", _scr(Vector2(616, 148)), Vector2(120, 20), 16, INK).text = "Route"
	_make_label(panel, "DepthLabel", _scr(Vector2(616, 178)), Vector2(100, 16), 14, INK)
	_add_stepper(panel, "Depth", _scr(Vector2(728, 172)))
	_make_label(panel, "DepthMaxLabel", _scr(Vector2(874, 178)), Vector2(70, 16), 12, INK_SECONDARY)
	_make_label(panel, "RoomsLabel", _scr(Vector2(616, 218)), Vector2(100, 16), 14, INK)
	_add_stepper(panel, "Rooms", _scr(Vector2(728, 212)))
	_make_label(panel, "RoomsStepNote", _scr(Vector2(874, 218)), Vector2(70, 16), 12, INK_SECONDARY).text = "step 5"
	_make_label(panel, "DurationLabel", _scr(Vector2(616, 254)), Vector2(200, 16), 12, INK_SECONDARY)
	_make_label(panel, "BossLabel", _scr(Vector2(826, 254)), Vector2(200, 16), 12, INK_SECONDARY)


func _mode_block(panel: Control) -> void:
	_make_label(panel, "ModeTitle", _scr(Vector2(244, 430)), Vector2(80, 20), 16, INK).text = "Mode"
	var manual := _mode_toggle(panel, "ManualButton", _scr(Vector2(244, 452)), "Manual")
	var idle := _mode_toggle(panel, "IdleButton", _scr(Vector2(368, 452)), "Idle")
	var join := _action_button(panel, "JoinFightButton", _scr(Vector2(492, 452)), "Join the fight")
	join.size = Vector2(160, 36)
	join.visible = false
	manual.toggle_mode = true
	idle.toggle_mode = true
	var group := ButtonGroup.new()
	manual.button_group = group
	idle.button_group = group

func _add_bottom_copy(panel: Control) -> void:
	var box := VBoxContainer.new()
	box.name = "BottomLeftCopy"
	box.position = _scr(Vector2(244, 486))
	box.custom_minimum_size = Vector2(356, 0)
	box.add_theme_constant_override("separation", 6)
	panel.add_child(box)
	var mode_hint := Label.new()
	mode_hint.name = "ModeHint"
	mode_hint.add_theme_font_size_override("font_size", 12)
	mode_hint.add_theme_color_override("font_color", INK_SECONDARY)
	mode_hint.autowrap_mode = TextServer.AUTOWRAP_OFF
	mode_hint.custom_minimum_size = Vector2(356, 20)
	box.add_child(mode_hint)
	var warn := Label.new()
	warn.name = "WarningLabel"
	warn.add_theme_font_size_override("font_size", 11)
	warn.add_theme_color_override("font_color", INK_SECONDARY)
	warn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	warn.custom_minimum_size = Vector2(356, 64)
	box.add_child(warn)


func reflow_footer_copy() -> void:
	var box: VBoxContainer = find_child("BottomLeftCopy", true, false) as VBoxContainer
	if box == null:
		return
	box.queue_sort()
	var sep: int = box.get_theme_constant("separation")
	var y: float = 0.0
	for child: Node in box.get_children():
		if not child is Control:
			continue
		var ctrl: Control = child as Control
		ctrl.position = Vector2(0, y)
		var h: float = maxf(ctrl.custom_minimum_size.y, ctrl.get_combined_minimum_size().y)
		if child is Label:
			h = maxf(h, (child as Label).get_minimum_size().y)
		ctrl.size = Vector2(box.custom_minimum_size.x, h)
		y += h + float(sep)
	box.size = Vector2(box.custom_minimum_size.x, maxf(y - float(sep), 0.0))


func _loadout_block(panel: Control) -> void:
	_make_label(panel, "LoadoutTitle", _scr(Vector2(616, 292)), Vector2(120, 20), 16, INK).text = "Loadout"
	_divider(panel, "DividerLoadout", _scr(Vector2(616, 318)), Vector2(424, 6))
	_make_label(panel, "LoadoutCap", _scr(Vector2(736, 296)), Vector2(160, 16), 12, INK_SECONDARY).text = "up to 100 each"
	for slot_i: int in range(2):
		var y_scr: int = 320 + slot_i * 56
		var n: int = slot_i + 1
		var slot_btn := Button.new()
		slot_btn.name = "LoadoutItem%d" % n
		slot_btn.position = _scr(Vector2(616, y_scr))
		slot_btn.size = Vector2(44, 44)
		slot_btn.flat = false
		slot_btn.text = ""
		panel.add_child(slot_btn)
		_style_item_slot(slot_btn)
		_make_label(panel, "LoadoutName%d" % n, _scr(Vector2(670, y_scr + 4)), Vector2(200, 36), 12, INK)
		_add_loadout_stepper(panel, n, _scr(Vector2(872, y_scr + 8)))


func _add_footer(panel: Control) -> void:
	var sim_label: String = "Simulate"
	var strings: Node = get_node_or_null("/root/ContentStrings")
	if strings != null:
		sim_label = str(strings.call("get_text", "board_simulate"))
	var sim := _action_button(panel, "SimulateButton", _scr(Vector2(616, 564)), sim_label)
	sim.size = Vector2(160, 44)
	var chip := _nine_patch("CostChip", BOARD_DIR + "cost_chip_9s_ok_24x32.png", 8, _scr(Vector2(786, 564)), Vector2(84, 44))
	panel.add_child(chip)
	var ess_icon := _tex_rect(chip, ICON_ESSENCE_TEX, Vector2(4, 6), Vector2(32, 32))
	ess_icon.name = "EssenceCostIcon"
	ess_icon.modulate = ESSENCE_TINT
	essence_icons.append(ess_icon)
	_make_label(chip, "CostAmount", Vector2(40, 10), Vector2(40, 24), 18, INK).text = "20"
	var depart := _action_button(panel, "Depart", _scr(Vector2(880, 564)), "Depart")
	depart.size = Vector2(160, 44)
	var depart_hint := _make_label(panel, "DepartHint", _scr(Vector2(760, 614)), Vector2(280, 16), 12, INK_SECONDARY)
	depart_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	depart_hint.clip_text = true
	depart_hint.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_make_label(panel, "DepartEssenceWarn", _scr(Vector2(760, 630)), Vector2(280, 16), 12, Color(0.55, 0.22, 0.18, 1.0))


func _add_progress(panel: Control) -> void:
	var prog := _make_label(panel, "ProgressLabel", _scr(Vector2(616, 148)), Vector2(400, 20), 15, INK)
	prog.visible = false
	prog.clip_text = true
	prog.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	var pack := _make_label(panel, "PackLabel", _scr(Vector2(616, 172)), Vector2(400, 18), 14, INK_SECONDARY)
	pack.visible = false
	pack.clip_text = true
	var left := _make_label(panel, "LoadoutLeftLabel", _scr(Vector2(616, 432)), Vector2(424, 36), 14, INK_SECONDARY)
	left.visible = false
	left.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

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
	picker_popup.z_index = 20
	picker_tail = _tex_rect(self, BOARD_DIR + "popup_tail_l_8x14.png", Vector2.ZERO, Vector2(8, 14))
	picker_tail.name = "PickerTail"
	picker_tail.visible = false
	picker_tail.z_index = 19
	picker_tail.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	picker_tail.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var margin := MarginContainer.new()
	margin.name = "PickerMargin"
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	picker_popup.add_child(margin)
	var vbox := VBoxContainer.new()
	vbox.name = "PickerVBox"
	vbox.add_theme_constant_override("separation", 2)
	margin.add_child(vbox)
	picker_title = Label.new()
	picker_title.name = "PickerTitle"
	picker_title.add_theme_font_size_override("font_size", 14)
	picker_title.add_theme_color_override("font_color", INK)
	picker_title.custom_minimum_size = Vector2(220, 18)
	vbox.add_child(picker_title)
	picker_scroll = ScrollContainer.new()
	picker_scroll.name = "PickerScroll"
	picker_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	picker_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	picker_scroll.custom_minimum_size = Vector2(220, PICKER_SCROLL_MAX_H)
	picker_scroll.size = Vector2(220, PICKER_SCROLL_MAX_H)
	_apply_picker_scroll_theme(picker_scroll)
	vbox.add_child(picker_scroll)
	picker_list = VBoxContainer.new()
	picker_list.name = "PickerList"
	picker_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	picker_list.add_theme_constant_override("separation", int(PICKER_ROW_GAP))
	picker_scroll.add_child(picker_list)
	for i: int in range(PICKER_ROW_POOL):
		var row := _make_picker_row(i)
		picker_list.add_child(row)
		picker_rows.append(row)


func _make_picker_row(index: int) -> Button:
	var row := Button.new()
	row.name = "PickerRow%d" % index
	row.custom_minimum_size = Vector2(220, 54)
	row.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	row.flat = false
	row.text = ""
	row.alignment = HORIZONTAL_ALIGNMENT_LEFT
	_style_picker_row(row, "normal")
	var portrait := TextureRect.new()
	portrait.name = "Portrait"
	portrait.position = Vector2(3, 1)
	portrait.size = Vector2(52, 52)
	portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(portrait)
	var name_lbl := Label.new()
	name_lbl.name = "Name"
	name_lbl.position = Vector2(62, 12)
	name_lbl.size = Vector2(150, 16)
	name_lbl.add_theme_font_size_override("font_size", 14)
	name_lbl.add_theme_color_override("font_color", INK)
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(name_lbl)
	var sub_lbl := Label.new()
	sub_lbl.name = "Sub"
	sub_lbl.position = Vector2(62, 32)
	sub_lbl.size = Vector2(150, 16)
	sub_lbl.add_theme_font_size_override("font_size", 12)
	sub_lbl.add_theme_color_override("font_color", INK_SECONDARY)
	sub_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(sub_lbl)
	var lock := _tex_rect(row, BOARD_DIR + "lock_10x12.png", Vector2(43, 38), Vector2(10, 12))
	lock.name = "Lock"
	lock.visible = false
	return row


func configure_picker_row(index: int, display_name: String, sub: String, portrait_path: String, row_state: String, locked: bool) -> void:
	if index < 0 or index >= picker_rows.size():
		return
	var row: Button = picker_rows[index]
	var portrait: TextureRect = row.get_node("Portrait") as TextureRect
	var name_lbl: Label = row.get_node("Name") as Label
	var sub_lbl: Label = row.get_node("Sub") as Label
	var lock: TextureRect = row.get_node("Lock") as TextureRect
	name_lbl.text = display_name
	sub_lbl.text = sub
	lock.visible = locked
	var plus_lbl: Label = row.get_node_or_null("PlusGlyph") as Label
	if portrait_path != "" and ResourceLoader.exists(portrait_path):
		portrait.texture = load(portrait_path) as Texture2D
		portrait.visible = true
		portrait.size = Vector2(52, 52)
		portrait.position = Vector2(3, 1)
		portrait.modulate = Color(0.55, 0.55, 0.55, 1.0) if row_state == "disabled" else Color.WHITE
		if plus_lbl != null:
			plus_lbl.visible = false
		name_lbl.position = Vector2(62, 12)
		sub_lbl.position = Vector2(62, 32)
	else:
		portrait.texture = null
		portrait.visible = false
		if plus_lbl == null:
			plus_lbl = Label.new()
			plus_lbl.name = "PlusGlyph"
			plus_lbl.position = Vector2(10, 14)
			plus_lbl.size = Vector2(24, 24)
			plus_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			plus_lbl.add_theme_font_size_override("font_size", 20)
			plus_lbl.add_theme_color_override("font_color", INK_SECONDARY)
			plus_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
			row.add_child(plus_lbl)
		plus_lbl.text = "+"
		plus_lbl.visible = row_state != "disabled"
		name_lbl.position = Vector2(40, 12)
		sub_lbl.position = Vector2(40, 32)
	_style_picker_row(row, row_state)
	var blocked: bool = row_state == "disabled"
	row.set_meta("picker_locked", blocked)
	row.disabled = false
	row.focus_mode = Control.FOCUS_NONE


func _pick_row_stylebox(kind: String) -> StyleBox:
	if kind == "empty":
		return StyleBoxEmpty.new()
	var file: String = "pick_row_9s_hover_24x24.png"
	match kind:
		"current":
			file = "pick_row_9s_current_24x24.png"
		"disabled":
			file = "pick_row_9s_disabled_24x24.png"
	var box := StyleBoxTexture.new()
	box.texture = _load_tex(BOARD_DIR + file)
	box.texture_margin_left = PICK_ROW_9S
	box.texture_margin_top = PICK_ROW_9S
	box.texture_margin_right = PICK_ROW_9S
	box.texture_margin_bottom = PICK_ROW_9S
	return box


func _style_picker_row(btn: Button, row_state: String) -> void:
	var normal_box: StyleBox = _pick_row_stylebox("empty")
	if row_state == "current":
		normal_box = _pick_row_stylebox("current")
	elif row_state == "disabled":
		normal_box = _pick_row_stylebox("disabled")
	var hover_box: StyleBox = _pick_row_stylebox("hover")
	var dis_box: StyleBox = _pick_row_stylebox("disabled")
	for state: String in ["normal", "hover", "pressed", "focus", "disabled"]:
		var box: StyleBox = normal_box
		if state == "hover":
			box = hover_box
		elif state == "disabled":
			box = dis_box
		btn.add_theme_stylebox_override(state, box)


func _build_simulate_window() -> void:
	simulate_modal = Control.new()
	simulate_modal.name = "SimulateModal"
	simulate_modal.set_anchors_preset(Control.PRESET_FULL_RECT)
	simulate_modal.visible = false
	simulate_modal.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(simulate_modal)
	var veil := ColorRect.new()
	veil.name = "SimulateDim"
	veil.set_anchors_preset(Control.PRESET_FULL_RECT)
	veil.color = Color(0, 0, 0, 0.5)
	veil.mouse_filter = Control.MOUSE_FILTER_STOP
	simulate_modal.add_child(veil)
	simulate_window = Control.new()
	simulate_window.name = "SimulateWindow"
	simulate_window.position = SIM_ORIGIN
	simulate_window.size = SIM_SIZE
	simulate_window.mouse_filter = Control.MOUSE_FILTER_STOP
	simulate_modal.add_child(simulate_window)
	var frame := _nine_patch("ResultsFrame", KIT_DIR + "frame_9s_96.png", FRAME_9S, Vector2.ZERO, SIM_SIZE)
	simulate_window.add_child(frame)
	var plate := _tex_rect(simulate_window, KIT_DIR + "title_plank_3s_48x40.png", Vector2(144, 0), Vector2(260, 40))
	plate.name = "ResultsTitlePlate"
	var sim_title := _make_label(simulate_window, "ResultsTitle", Vector2(152, 6), Vector2(244, 28), 16, INK)
	sim_title.text = "Simulation"
	sim_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	simulate_close = _stop_button(simulate_window, "SimulateClose", Vector2(392, 20))
	simulate_close.text = "Close"
	_tex_rect(simulate_window, KIT_DIR + "keycap_esc.png", Vector2(468, 24), Vector2(28, 15)).name = "SimulateCloseEsc"
	_make_label(simulate_window, "SimulateHeader", Vector2(24, 52), Vector2(400, 20), 12, INK_SECONDARY)
	var summary := _make_label(simulate_window, "SimulateSummary", Vector2(24, 72), Vector2(460, 24), 16, INK)
	summary.z_index = 2
	simulate_scroll = ScrollContainer.new()
	simulate_scroll.name = "SimulateScroll"
	simulate_scroll.position = Vector2(24, 102)
	simulate_scroll.size = Vector2(500, 228)
	simulate_scroll.clip_contents = true
	_apply_simulate_scroll_theme(simulate_scroll)
	simulate_window.add_child(simulate_scroll)
	simulate_room_list = VBoxContainer.new()
	simulate_room_list.name = "SimulateRoomList"
	simulate_room_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	simulate_scroll.add_child(simulate_room_list)
	simulate_result = Label.new()
	simulate_result.name = "SimulateResult"
	simulate_result.visible = false
	simulate_footer = VBoxContainer.new()
	simulate_footer.name = "SimulateFooter"
	simulate_footer.position = Vector2(24, 338)
	simulate_footer.size = Vector2(500, 88)
	simulate_footer.add_theme_constant_override("separation", 2)
	simulate_window.add_child(simulate_footer)
	var losses := Label.new()
	losses.name = "SimulateLosses"
	losses.autowrap_mode = TextServer.AUTOWRAP_OFF
	losses.clip_text = true
	losses.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	losses.custom_minimum_size = Vector2(500, 16)
	losses.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	losses.add_theme_font_size_override("font_size", 12)
	losses.add_theme_color_override("font_color", INK)
	simulate_footer.add_child(losses)
	var banked := Label.new()
	banked.name = "SimulateBanked"
	banked.autowrap_mode = TextServer.AUTOWRAP_OFF
	banked.clip_text = true
	banked.custom_minimum_size = Vector2(500, 16)
	banked.add_theme_font_size_override("font_size", 12)
	banked.add_theme_color_override("font_color", INK)
	simulate_footer.add_child(banked)
	var used := Label.new()
	used.name = "SimulateUsed"
	used.autowrap_mode = TextServer.AUTOWRAP_OFF
	used.clip_text = true
	used.custom_minimum_size = Vector2(500, 16)
	used.add_theme_font_size_override("font_size", 12)
	used.add_theme_color_override("font_color", INK)
	simulate_footer.add_child(used)
	var note := Label.new()
	note.name = "SimulateNote"
	note.autowrap_mode = TextServer.AUTOWRAP_OFF
	note.clip_text = true
	note.custom_minimum_size = Vector2(500, 14)
	note.add_theme_font_size_override("font_size", 12)
	note.add_theme_color_override("font_color", INK_SECONDARY)
	simulate_footer.add_child(note)
	simulate_essence_icon = _tex_rect(simulate_window, ICON_ESSENCE_TEX, Vector2(-64, -64), Vector2(32, 32))
	simulate_essence_icon.name = "SimulateEssenceIcon"
	simulate_essence_icon.modulate = ESSENCE_TINT
	simulate_essence_icon.visible = false
	essence_icons.append(simulate_essence_icon)
	simulate_rerun = _wood_text_button(simulate_window, "SimulateRerun", Vector2(380, 432), Vector2(120, 32), "Run again")


func _add_title(panel: Control) -> void:
	var plate := _tex_rect(panel, KIT_DIR + "title_plate_312x46.png", _scr(Vector2(484, 37)), Vector2(312, 46))
	plate.name = "TitlePlate"
	var title := _make_label(panel, "Title", _scr(Vector2(496, 40)), Vector2(288, 40), 18, INK)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER


func _add_close(panel: Control) -> void:
	var btn := _stop_button(panel, "CloseButton", _scr(Vector2(944, 92)))
	btn.text = "Close"
	var esc := _tex_rect(panel, KIT_DIR + "keycap_esc.png", _scr(Vector2(1020, 96)), Vector2(28, 15))
	esc.name = "CloseEscKeycap"
	esc.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _add_vines(panel: Control) -> void:
	var vine_tl := _tex_rect(panel, KIT_DIR + "deco_vine_tl.png", Vector2(-4, -4), Vector2(32, 32))
	vine_tl.name = "DecoVineTL"
	var vine_br := _tex_rect(panel, KIT_DIR + "deco_vine_br.png", Vector2(852, 572), Vector2(32, 32))
	vine_br.name = "DecoVineBR"


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
	field.clip_contents = true
	field.alignment = HORIZONTAL_ALIGNMENT_CENTER
	field.add_theme_font_size_override("font_size", 16)
	field.add_theme_color_override("font_color", INK)
	_style_field(field, slot_n > 0)
	panel.add_child(field)
	var plus := _wood_glyph_button(panel, plus_name, pos + Vector2(84 if slot_n > 0 else 108, 0), BOARD_DIR + "glyph_plus_10x10.png", BOARD_DIR + "glyph_plus_disabled_10x10.png")
	if slot_n > 0:
		_make_label(panel, "LoadoutQty%dCap" % slot_n, pos + Vector2(136, 4), Vector2(48, 20), 12, INK_SECONDARY).text = "/ 100"


func _party_slot_button(node_name: String, pos: Vector2) -> Button:
	var btn := Button.new()
	btn.name = node_name
	btn.position = pos
	btn.size = Vector2(60, 60)
	btn.toggle_mode = false
	btn.flat = false
	btn.text = ""
	set_party_slot_style(btn, "empty")
	return btn


func set_party_slot_style(btn: Button, state: String) -> void:
	var file: String = "party_slot_empty_60x60.png"
	match state:
		"empty_hover":
			file = "party_slot_empty_hover_60x60.png"
		"filled":
			file = "party_slot_filled_60x60.png"
		"hover":
			file = "party_slot_hover_60x60.png"
		"selected":
			file = "party_slot_selected_60x60.png"
		"locked":
			file = "party_slot_locked_60x60.png"
	_style_party_slot(btn, BOARD_DIR + file)


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


func _style_field(field: LineEdit, compact: bool = false) -> void:
	var margin: int = 3 if compact else FIELD_9S
	for state: String in ["normal", "focus", "read_only"]:
		var file: String = "field_9s_%s_24x24.png" % state
		if state == "read_only":
			file = "field_9s_disabled_24x24.png"
		var box := StyleBoxTexture.new()
		box.texture = _load_tex(BOARD_DIR + file)
		box.texture_margin_left = margin
		box.texture_margin_top = margin
		box.texture_margin_right = margin
		box.texture_margin_bottom = margin
		box.set_expand_margin_all(0)
		var key: String = state
		if state == "read_only":
			key = "disabled"
		field.add_theme_stylebox_override(key, box)
	field.add_theme_stylebox_override("normal", _field_style("field_9s_normal_24x24.png", compact))


func _field_style(file: String, compact: bool = false) -> StyleBoxTexture:
	var margin: int = 3 if compact else FIELD_9S
	var box := StyleBoxTexture.new()
	box.texture = _load_tex(BOARD_DIR + file)
	box.texture_margin_left = margin
	box.texture_margin_top = margin
	box.texture_margin_right = margin
	box.texture_margin_bottom = margin
	box.set_expand_margin_all(0)
	return box


func set_field_invalid(field: LineEdit, invalid: bool) -> void:
	var compact: bool = field.name.begins_with("LoadoutQty")
	if invalid:
		field.add_theme_stylebox_override("normal", _field_style("field_9s_invalid_24x24.png", compact))
	else:
		field.add_theme_stylebox_override("normal", _field_style("field_9s_normal_24x24.png", compact))


func _style_party_slot(btn: Button, tex_path: String) -> void:
	var tex: Texture2D = _load_tex(tex_path)
	if tex == null:
		return
	var box := StyleBoxTexture.new()
	box.texture = tex
	btn.add_theme_stylebox_override("normal", box)
	var hover_path: String = tex_path.replace("_empty_60", "_empty_hover_60")
	if tex_path.find("_filled_") >= 0:
		hover_path = tex_path.replace("_filled_60", "_hover_60")
	var hover_tex: Texture2D = _load_tex(hover_path)
	if hover_tex != null:
		var hover_box := StyleBoxTexture.new()
		hover_box.texture = hover_tex
		btn.add_theme_stylebox_override("hover", hover_box)
	btn.add_theme_stylebox_override("pressed", box)
	btn.add_theme_stylebox_override("disabled", box)
	btn.add_theme_stylebox_override("focus", box)


func _style_item_slot(btn: Button) -> void:
	for state: String in ["normal", "hover", "pressed", "disabled"]:
		var file: String = "item_slot_empty_44x44.png"
		if state == "hover" or state == "pressed":
			file = "item_slot_hover_44x44.png"
		var box := StyleBoxTexture.new()
		box.texture = _load_tex(BOARD_DIR + file)
		btn.add_theme_stylebox_override(state, box)


func clear_simulate_rows() -> void:
	if simulate_room_list == null:
		return
	for child: Node in simulate_room_list.get_children():
		child.queue_free()


func add_simulate_row(left_text: String, right_text: String, row_kind: String, icon_kind: String = "good") -> void:
	if simulate_room_list == null:
		return
	var row := PanelContainer.new()
	row.custom_minimum_size = Vector2(480, 26)
	var bg: StyleBox = _list_row_stylebox("list_row_9s_even_24x24.png")
	if row_kind == "loss":
		bg = _list_row_stylebox("list_row_9s_loss_24x24.png")
	row.add_theme_stylebox_override("panel", bg)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 4)
	margin.add_theme_constant_override("margin_right", 4)
	row.add_child(margin)
	var h := HBoxContainer.new()
	h.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_child(h)
	var icon_slot := Control.new()
	icon_slot.custom_minimum_size = Vector2(18, 16)
	icon_slot.size = Vector2(18, 16)
	icon_slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(icon_slot)
	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(12, 12)
	icon.size = Vector2(12, 12)
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	var icon_path: String = KIT_DIR + "pip_good_12.png"
	var icon_sz: Vector2 = Vector2(12, 12)
	if icon_kind == "boss":
		icon_path = BATTLE_UI + "boss_crown_16.png"
		icon_sz = Vector2(16, 16)
	elif row_kind == "loss" or icon_kind == "miss":
		icon_path = KIT_DIR + "pip_miss_12.png"
	icon.texture = _load_tex(icon_path)
	icon.custom_minimum_size = icon_sz
	icon.size = icon_sz
	icon.position = Vector2((18.0 - icon_sz.x) * 0.5, (16.0 - icon_sz.y) * 0.5)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon_slot.add_child(icon)
	var left := Label.new()
	left.text = left_text
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.add_theme_font_size_override("font_size", 14)
	left.add_theme_color_override("font_color", INK)
	h.add_child(left)
	var right := Label.new()
	right.text = right_text
	right.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	right.custom_minimum_size.x = 132
	right.add_theme_font_size_override("font_size", 12)
	right.add_theme_color_override("font_color", INK_SECONDARY)
	h.add_child(right)
	simulate_room_list.add_child(row)


func _list_row_stylebox(file: String) -> StyleBoxTexture:
	var box := StyleBoxTexture.new()
	box.texture = _load_tex(BOARD_DIR + file)
	box.texture_margin_left = 4
	box.texture_margin_top = 4
	box.texture_margin_right = 4
	box.texture_margin_bottom = 4
	return box


func ensure_picker_rows(visible_count: int) -> void:
	var need: int = clampi(visible_count, 0, picker_rows.size())
	for i: int in range(picker_rows.size()):
		picker_rows[i].visible = i < need


func _apply_picker_scroll_theme(scroll: ScrollContainer) -> void:
	var track := StyleBoxTexture.new()
	track.texture = _load_tex(BOARD_DIR + "scroll_track_9s_12x24.png")
	track.texture_margin_left = 4
	track.texture_margin_top = 4
	track.texture_margin_right = 4
	track.texture_margin_bottom = 4
	var grab := StyleBoxTexture.new()
	grab.texture = _load_tex(BOARD_DIR + "scroll_thumb_9s_normal_12x16.png")
	grab.texture_margin_left = 5
	grab.texture_margin_top = 5
	grab.texture_margin_right = 5
	grab.texture_margin_bottom = 5
	var grab_hi := StyleBoxTexture.new()
	grab_hi.texture = _load_tex(BOARD_DIR + "scroll_thumb_9s_hover_12x16.png")
	grab_hi.texture_margin_left = 5
	grab_hi.texture_margin_top = 5
	grab_hi.texture_margin_right = 5
	grab_hi.texture_margin_bottom = 5
	scroll.add_theme_stylebox_override("panel", track)
	scroll.add_theme_stylebox_override("bg", track)
	var vbar := scroll.get_v_scroll_bar()
	if vbar != null:
		vbar.add_theme_stylebox_override("scroll", track)
		vbar.add_theme_stylebox_override("grabber", grab)
		vbar.add_theme_stylebox_override("grabber_highlight", grab_hi)
		vbar.add_theme_stylebox_override("grabber_pressed", grab_hi)


func _apply_simulate_scroll_theme(scroll: ScrollContainer) -> void:
	var track := StyleBoxTexture.new()
	track.texture = _load_tex(BOARD_DIR + "scroll_track_9s_12x24.png")
	track.texture_margin_left = 4
	track.texture_margin_top = 4
	track.texture_margin_right = 4
	track.texture_margin_bottom = 4
	var grab := StyleBoxTexture.new()
	grab.texture = _load_tex(BOARD_DIR + "scroll_thumb_9s_normal_12x16.png")
	grab.texture_margin_left = 5
	grab.texture_margin_top = 5
	grab.texture_margin_right = 5
	grab.texture_margin_bottom = 5
	var grab_hi := StyleBoxTexture.new()
	grab_hi.texture = _load_tex(BOARD_DIR + "scroll_thumb_9s_hover_12x16.png")
	grab_hi.texture_margin_left = 5
	grab_hi.texture_margin_top = 5
	grab_hi.texture_margin_right = 5
	grab_hi.texture_margin_bottom = 5
	var grab_press := StyleBoxTexture.new()
	grab_press.texture = _load_tex(BOARD_DIR + "scroll_thumb_9s_drag_12x16.png")
	grab_press.texture_margin_left = 5
	grab_press.texture_margin_top = 5
	grab_press.texture_margin_right = 5
	grab_press.texture_margin_bottom = 5
	scroll.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	var vbar := scroll.get_v_scroll_bar()
	vbar.add_theme_stylebox_override("scroll", track)
	vbar.add_theme_stylebox_override("grabber", grab)
	vbar.add_theme_stylebox_override("grabber_highlight", grab_hi)
	vbar.add_theme_stylebox_override("grabber_pressed", grab_press)


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


func _divider(parent: Control, node_name: String, pos: Vector2, size: Vector2) -> void:
	var np := NinePatchRect.new()
	np.name = node_name
	np.texture = _load_tex(BOARD_DIR + "divider_3s_48x6.png")
	np.position = pos
	np.size = size
	np.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	np.patch_margin_left = 8
	np.patch_margin_right = 8
	np.patch_margin_top = 0
	np.patch_margin_bottom = 0
	np.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(np)


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
	var visible_rows: int = 0
	for row: Button in picker_rows:
		if row.visible:
			visible_rows += 1
	var list_h: float = maxf(0.0, float(visible_rows) * (PICKER_ROW_H + PICKER_ROW_GAP) - PICKER_ROW_GAP)
	var scroll_h: float = minf(list_h, PICKER_SCROLL_MAX_H)
	var h: float = 34.0 + scroll_h
	if picker_scroll != null:
		picker_scroll.custom_minimum_size = Vector2(220, scroll_h)
		picker_scroll.size = Vector2(220, scroll_h)
	var slot_centre_y: float = slot_btn.global_position.y + slot_btn.size.y * 0.5
	var y: float = clampf(slot_btn.global_position.y - 76.0, 140.0, 418.0 - h)
	picker_popup.position = Vector2(slot_btn.global_position.x + 68.0, y)
	picker_popup.custom_minimum_size = Vector2(PICKER_POPUP_W, h)
	picker_popup.size = Vector2(PICKER_POPUP_W, h)
	picker_tail.position = Vector2(picker_popup.position.x - 6.0, slot_centre_y - 7.0)
	picker_tail.size = Vector2(8, 14)
	picker_tail.visible = true
	picker_popup.visible = true


func hide_picker() -> void:
	if picker_popup != null:
		picker_popup.visible = false
	if picker_tail != null:
		picker_tail.visible = false
