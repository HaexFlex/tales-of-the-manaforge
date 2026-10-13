extends Control
class_name ExpeditionShellView
## Expedition board shell (Art mockup 2026-10-11). Built at runtime; expedition_board owns state.

const BOARD_DIR: String = "res://assets/art/ui/board/"
const KIT_DIR: String = "res://assets/ui/theme/"
const BATTLE_UI: String = "res://assets/art/battle/ui/"
const PANEL_SIZE: Vector2 = Vector2(912, 472)
const PAD: float = 24.0
const HEADER_Y: float = 26.0
const DIVIDER_Y: float = 84.0
const COL_TITLE_Y: float = 92.0
const COL_TITLE_H: float = 24.0
const BODY_Y: float = 118.0
const ROW_H: float = 44.0
const ROW_PITCH: float = 50.0
const PARTY_X: float = 24.0
const PARTY_W: float = 272.0
const BED_H: float = 242.0
const SLOT_PITCH_Y: float = 70.0
const SLOT_MID_STEP: float = 30.0
const BACK_COL_X: float = 48.0
const FRONT_COL_X: float = 188.0
const ROUTE_X: float = 312.0
const ROUTE_W: float = 288.0
const ROUTE_FIELD_X: float = 76.0
const LOAD_X: float = 616.0
const LOAD_W: float = 272.0
const LOAD_SLOT_PITCH: float = 100.0
const FOOT_BTN_Y_FROM_BOTTOM: float = 76.0
const DEPART_W: float = 232.0
const SIM_SIZE: Vector2 = Vector2(560, 340)
const SIM_TOP: float = 86.0
const INK: Color = Color(0.243137, 0.164706, 0.0941176, 1.0) # #3E2A18
const INK_SECONDARY: Color = Color8(90, 62, 40)
const WARN_RED: Color = Color(0.55, 0.22, 0.18, 1.0)
const BODY_SIZE: int = 19
const BIG_SIZE: int = 38
const PRIMARY_FONT_PATH: String = "res://assets/fonts/font_primary_silver38_bold.tres"
const FIELD_9S: int = 6
const PICK_ROW_9S: int = 6
const PICKER_POPUP_W: float = 272.0
const PICKER_POPUP_MAX_H: float = 300.0
const PICKER_ROW_H: float = 48.0
const PICKER_ROW_W: float = 224.0
const PICKER_ROW_GAP: float = 4.0
const PICKER_ROW_POOL: int = 16
const PICKER_PAD_TOP: float = 20.0
const PICKER_TITLE_H: float = 24.0
const PICKER_PAD_BOTTOM: float = 22.0
const PICKER_CHROME_H: float = PICKER_PAD_TOP + PICKER_TITLE_H + PICKER_ROW_GAP + PICKER_PAD_BOTTOM
const PICKER_SCROLL_MAX_H: float = 228.0
const ICON_ESSENCE_TEX: String = "res://assets_extra/shared/icon_essence.png"
const ESC_KEYCAP_SIZE: Vector2 = Vector2(56, 40)
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
var _panel: Panel
var _win_h: float = PANEL_SIZE.y
var _primary_font: Font


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_primary_font = load(PRIMARY_FONT_PATH) as Font
	_build()


func _build() -> void:
	var dim := ColorRect.new()
	dim.name = "Dim"
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0.5)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)
	_panel = Panel.new()
	_panel.name = "Panel"
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_panel.clip_contents = false
	add_child(_panel)
	_win_h = Ui540.fit_kit_window(_panel, PANEL_SIZE).y
	Ui540.apply_kit_panel(_panel, "adventure_board")
	_build_panel(_panel)
	call_deferred("_center_board_panel")


func _center_board_panel() -> void:
	if _panel == null:
		return
	Ui540.fit_kit_window(_panel, PANEL_SIZE)
	Ui540.place_title_plank(_panel.get_node("Title") as Label, PANEL_SIZE.x)
	_fit_enemy_marker()
	if simulate_window != null:
		simulate_window.position = Vector2(roundf((Ui540.viewport_size().x - SIM_SIZE.x) * 0.5), SIM_TOP)


func _build_panel(panel: Control) -> void:
	_add_title(panel)
	_add_close(panel)
	_line(panel, "Hint", Vector2(PAD, HEADER_Y), Vector2(640, 20), false)
	var lantern := _line(panel, "Lantern", Vector2(PAD, HEADER_Y + 20.0), Vector2(640, 38), true)
	lantern.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lantern.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	lantern.add_theme_constant_override("line_spacing", -2)
	_divider(panel, "DividerTop", Vector2(PAD, DIVIDER_Y), Vector2(PANEL_SIZE.x - PAD * 2.0, 6))
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
	_section(panel, "PartyTitle", Vector2(PARTY_X, COL_TITLE_Y), Vector2(120, COL_TITLE_H)).text = ""
	var sub := _line(panel, "PartyHint", Vector2(PARTY_X + 100.0, COL_TITLE_Y), Vector2(PARTY_W - 100.0, COL_TITLE_H), true)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	var bed := _nine_patch("FormationBed", KIT_DIR + "play_bevel_9s_6x6.png", 2, Vector2(PARTY_X, BODY_Y), Vector2(PARTY_W, BED_H))
	bed.clip_contents = true
	panel.add_child(bed)
	var label_y: float = BODY_Y + 12.0 + SLOT_PITCH_Y * 2.0 + 62.0
	for col: Array in [["LabelBack", BACK_COL_X, "Back"], ["LabelFront", FRONT_COL_X, "Front"]]:
		var col_lbl := _line(panel, str(col[0]), Vector2(float(col[1]), label_y), Vector2(60, 20), true)
		col_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		col_lbl.text = str(col[2])
	var marker_y: float = BODY_Y + BED_H + 6.0
	var arrow := _tex_rect(panel, BOARD_DIR + "arrow_enemy_side_12x9.png", Vector2(0, marker_y + 6.0), Vector2(12, 9))
	arrow.name = "EnemyArrow"
	var enemy_lbl := _line(panel, "EnemyLabel", Vector2(0, marker_y), Vector2(60, 20), true)
	enemy_lbl.text = "enemies"
	_fit_enemy_marker()
	var rows: Array[String] = ["Top", "Mid", "Bot"]
	for col: Array in [["back", "SlotBack", BACK_COL_X], ["front", "SlotFront", FRONT_COL_X]]:
		for cell: int in range(3):
			var x: float = float(col[2]) + (SLOT_MID_STEP if cell == 1 else 0.0)
			var pos := Vector2(x, BODY_Y + 12.0 + SLOT_PITCH_Y * float(cell))
			var btn := _party_slot_button("%s%s" % [str(col[1]), rows[cell]], pos)
			panel.add_child(btn)
			party_slots["%s:%d" % [str(col[0]), cell]] = btn


## The "enemies" marker hugs the bed's right edge: arrow, 4 px, then the word.
func _fit_enemy_marker() -> void:
	if _panel == null:
		return
	var lbl: Label = _panel.get_node_or_null("EnemyLabel") as Label
	var arrow: Control = _panel.get_node_or_null("EnemyArrow") as Control
	if lbl == null or arrow == null:
		return
	var font: Font = lbl.get_theme_font("font")
	var w: float = ceilf(font.get_string_size(lbl.text, HORIZONTAL_ALIGNMENT_LEFT, -1, BODY_SIZE).x) if font else 44.0
	lbl.size = Vector2(w, 20)
	lbl.position.x = PARTY_X + PARTY_W - 8.0 - w
	arrow.position.x = lbl.position.x - 4.0 - arrow.size.x


func _route_block(panel: Control) -> void:
	_section(panel, "RouteTitle", Vector2(ROUTE_X, COL_TITLE_Y), Vector2(120, COL_TITLE_H)).text = "Route"
	var note_x: float = ROUTE_X + ROUTE_FIELD_X + 172.0
	var note_w: float = ROUTE_X + ROUTE_W - note_x
	for row: Array in [["Depth", "DepthMaxLabel", ""], ["Rooms", "RoomsStepNote", "step 5"]]:
		var y: float = BODY_Y + ROW_PITCH * (0.0 if str(row[0]) == "Depth" else 1.0)
		_line(panel, "%sLabel" % str(row[0]), Vector2(ROUTE_X, y), Vector2(ROUTE_FIELD_X, ROW_H), false)
		_add_stepper(panel, str(row[0]), Vector2(ROUTE_X + ROUTE_FIELD_X, y))
		var note := _line(panel, str(row[1]), Vector2(note_x, y), Vector2(note_w, ROW_H), true)
		note.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		note.text = str(row[2])
	var hero_y: float = BODY_Y + ROW_PITCH * 3.0 + 2.0
	var duration := _line(panel, "DurationLabel", Vector2(ROUTE_X, hero_y), Vector2(ROUTE_W, 30), false)
	duration.add_theme_font_override("font", _primary_font)
	duration.add_theme_font_size_override("font_size", BIG_SIZE)
	_line(panel, "BossLabel", Vector2(ROUTE_X, hero_y + 30.0), Vector2(ROUTE_W, 20), true)


func _mode_block(panel: Control) -> void:
	var y: float = BODY_Y + ROW_PITCH * 2.0
	_line(panel, "ModeTitle", Vector2(ROUTE_X, y), Vector2(ROUTE_FIELD_X, ROW_H), false).text = "Mode"
	var toggle_w: float = (ROUTE_W - ROUTE_FIELD_X - 8.0) * 0.5
	var manual := _mode_toggle(panel, "ManualButton", Vector2(ROUTE_X + ROUTE_FIELD_X, y), toggle_w, "Manual")
	var idle := _mode_toggle(panel, "IdleButton", Vector2(ROUTE_X + ROUTE_FIELD_X + toggle_w + 8.0, y), toggle_w, "Idle")
	var join := _big_button(panel, "JoinFightButton", Vector2(ROUTE_X, BODY_Y + 64.0), Vector2(ROUTE_W, ROW_H), "Join the fight")
	join.visible = false
	var group := ButtonGroup.new()
	manual.button_group = group
	idle.button_group = group


func _add_bottom_copy(panel: Control) -> void:
	var box := VBoxContainer.new()
	box.name = "BottomLeftCopy"
	box.position = Vector2(ROUTE_X, BODY_Y + ROW_PITCH * 3.0 + 56.0)
	box.custom_minimum_size = Vector2(ROUTE_W, 0)
	box.add_theme_constant_override("separation", 2)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(box)
	for node_name: String in ["ModeHint", "WarningLabel"]:
		var copy := Label.new()
		copy.name = node_name
		GameTheme.style_ink_label(copy, true)
		copy.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		copy.add_theme_constant_override("line_spacing", -2)
		copy.custom_minimum_size = Vector2(ROUTE_W, 18)
		copy.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.add_child(copy)


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
	_section(panel, "LoadoutTitle", Vector2(LOAD_X, COL_TITLE_Y), Vector2(120, COL_TITLE_H)).text = "Loadout"
	var cap := _line(panel, "LoadoutCap", Vector2(LOAD_X + 120.0, COL_TITLE_Y), Vector2(LOAD_W - 120.0, COL_TITLE_H), true)
	cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	cap.text = "up to 100 each"
	for slot_i: int in range(2):
		var y: float = BODY_Y + LOAD_SLOT_PITCH * float(slot_i)
		var n: int = slot_i + 1
		var slot_btn := Button.new()
		slot_btn.name = "LoadoutItem%d" % n
		slot_btn.position = Vector2(LOAD_X, y)
		slot_btn.size = Vector2(ROW_H, ROW_H)
		slot_btn.flat = false
		slot_btn.text = ""
		panel.add_child(slot_btn)
		_style_item_slot(slot_btn)
		_add_loadout_stepper(panel, n, Vector2(LOAD_X + 52.0, y))
		var name_lbl := _line(panel, "LoadoutName%d" % n, Vector2(LOAD_X, y + 48.0), Vector2(LOAD_W, 40), false)
		name_lbl.autowrap_mode = TextServer.AUTOWRAP_OFF
		name_lbl.vertical_alignment = VERTICAL_ALIGNMENT_TOP
		name_lbl.add_theme_constant_override("line_spacing", -2)


func _add_footer(panel: Control) -> void:
	var sim_label: String = "Simulate"
	var strings: Node = get_node_or_null("/root/ContentStrings")
	if strings != null:
		sim_label = str(strings.call("get_text", "board_simulate"))
	var foot_y: float = _win_h - FOOT_BTN_Y_FROM_BOTTOM
	_big_button(panel, "SimulateButton", Vector2(ROUTE_X, foot_y + 4.0), Vector2(160, ROW_H), sim_label)
	var chip := _nine_patch("CostChip", BOARD_DIR + "cost_chip_9s_ok_24x32.png", 8, Vector2(ROUTE_X + 172.0, foot_y + 4.0), Vector2(84, ROW_H))
	panel.add_child(chip)
	var ess_icon := _tex_rect(chip, ICON_ESSENCE_TEX, Vector2(8, 10), Vector2(24, 24))
	ess_icon.name = "EssenceCostIcon"
	ess_icon.modulate = ESSENCE_TINT
	essence_icons.append(ess_icon)
	var amount := _make_label(chip, "CostAmount", Vector2(36, 0), Vector2(42, ROW_H), BIG_SIZE, INK)
	amount.add_theme_font_override("font", _primary_font)
	amount.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	amount.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	amount.autowrap_mode = TextServer.AUTOWRAP_OFF
	amount.text = "20"
	var depart_x: float = PANEL_SIZE.x - PAD - DEPART_W
	_big_button(panel, "Depart", Vector2(depart_x, foot_y), Vector2(DEPART_W, 52), "Depart")
	var hint_x: float = ROUTE_X + 264.0
	_line(panel, "DepartHint", Vector2(hint_x, foot_y + 4.0), Vector2(depart_x - 8.0 - hint_x, ROW_H), true)
	var warn := _line(panel, "DepartEssenceWarn", Vector2(LOAD_X, foot_y - 26.0), Vector2(LOAD_W, 20), false)
	warn.add_theme_color_override("font_color", WARN_RED)
	warn.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT


func _add_progress(panel: Control) -> void:
	var prog := _line(panel, "ProgressLabel", Vector2(ROUTE_X, BODY_Y), Vector2(ROUTE_W, 30), false)
	prog.add_theme_font_override("font", _primary_font)
	prog.add_theme_font_size_override("font_size", BIG_SIZE)
	prog.visible = false
	var pack := _line(panel, "PackLabel", Vector2(ROUTE_X, BODY_Y + 32.0), Vector2(ROUTE_W, 20), true)
	pack.visible = false
	var left := _line(panel, "LoadoutLeftLabel", Vector2(LOAD_X, BODY_Y), Vector2(LOAD_W, 60), true)
	left.visible = false
	left.clip_text = false
	left.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	left.vertical_alignment = VERTICAL_ALIGNMENT_TOP


func _build_picker() -> void:
	picker_popup = PanelContainer.new()
	picker_popup.name = "PickerPopup"
	picker_popup.visible = false
	picker_popup.mouse_filter = Control.MOUSE_FILTER_STOP
	picker_popup.add_theme_stylebox_override("panel", Ui540.kit_stylebox_9s(
		KIT_DIR + "frame_9s_96.png", Vector4i(24, 24, 24, 24),
		Vector4(PAD, PICKER_PAD_TOP, PAD, PICKER_PAD_BOTTOM), true))
	add_child(picker_popup)
	picker_popup.z_index = 20
	picker_tail = _tex_rect(self, BOARD_DIR + "popup_tail_l_8x14.png", Vector2.ZERO, Vector2(8, 14))
	picker_tail.name = "PickerTail"
	picker_tail.visible = false
	picker_tail.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	var vbox := VBoxContainer.new()
	vbox.name = "PickerVBox"
	vbox.add_theme_constant_override("separation", int(PICKER_ROW_GAP))
	picker_popup.add_child(vbox)
	picker_title = Label.new()
	picker_title.name = "PickerTitle"
	_style_section(picker_title)
	picker_title.custom_minimum_size = Vector2(PICKER_ROW_W, PICKER_TITLE_H)
	picker_title.text = "Who stands here?"
	vbox.add_child(picker_title)
	picker_scroll = ScrollContainer.new()
	picker_scroll.name = "PickerScroll"
	picker_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	picker_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	picker_scroll.custom_minimum_size = Vector2(PICKER_ROW_W, PICKER_SCROLL_MAX_H)
	picker_scroll.size = Vector2(PICKER_ROW_W, PICKER_SCROLL_MAX_H)
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
	row.custom_minimum_size = Vector2(PICKER_ROW_W, PICKER_ROW_H)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.flat = false
	row.text = ""
	row.alignment = HORIZONTAL_ALIGNMENT_LEFT
	_style_picker_row(row, "normal")
	var portrait := TextureRect.new()
	portrait.name = "Portrait"
	portrait.position = Vector2(4, 4)
	portrait.size = Vector2(40, 40)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(portrait)
	var name_lbl := _picker_line(row, "Name", Vector2(52, 4), false)
	name_lbl.add_theme_color_override("font_color", INK)
	_picker_line(row, "Sub", Vector2(52, 24), true)
	var lock := _tex_rect(row, BOARD_DIR + "lock_10x12.png", Vector2(34, 32), Vector2(10, 12))
	lock.name = "Lock"
	lock.visible = false
	return row


func _picker_line(row: Button, node_name: String, pos: Vector2, muted: bool) -> Label:
	var lbl := Label.new()
	lbl.name = node_name
	lbl.position = pos
	lbl.size = Vector2(PICKER_ROW_W - pos.x - 6.0, 20)
	GameTheme.style_ink_label(lbl, muted)
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.clip_text = true
	lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(lbl)
	return lbl


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
		portrait.size = Vector2(40, 40)
		portrait.position = Vector2(4, 4)
		portrait.modulate = Color(0.55, 0.55, 0.55, 1.0) if row_state == "disabled" else Color.WHITE
		if plus_lbl != null:
			plus_lbl.visible = false
		name_lbl.position = Vector2(52, 4)
		sub_lbl.position = Vector2(52, 24)
	else:
		portrait.texture = null
		portrait.visible = false
		if plus_lbl == null:
			plus_lbl = Label.new()
			plus_lbl.name = "PlusGlyph"
			plus_lbl.position = Vector2(4, 4)
			plus_lbl.size = Vector2(40, 40)
			plus_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			plus_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			plus_lbl.add_theme_font_override("font", _primary_font)
			plus_lbl.add_theme_font_size_override("font_size", BIG_SIZE)
			plus_lbl.add_theme_color_override("font_color", INK)
			plus_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
			row.add_child(plus_lbl)
		plus_lbl.text = "+"
		plus_lbl.visible = row_state != "disabled"
		name_lbl.position = Vector2(52, 4)
		sub_lbl.position = Vector2(52, 24)
	_style_picker_row(row, row_state)
	var blocked: bool = row_state == "disabled"
	row.set_meta("picker_locked", blocked)
	row.disabled = false
	row.focus_mode = Control.FOCUS_NONE


func _pick_row_stylebox(kind: String) -> StyleBox:
	var file: String = "pick_row_9s_hover_24x24.png"
	match kind:
		"normal":
			file = "list_row_9s_even_24x24.png"
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
	var normal_box: StyleBox = _pick_row_stylebox("normal")
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
	simulate_window.position = Vector2(roundf((Ui540.viewport_size().x - SIM_SIZE.x) * 0.5), SIM_TOP)
	simulate_window.size = SIM_SIZE
	simulate_window.mouse_filter = Control.MOUSE_FILTER_STOP
	simulate_modal.add_child(simulate_window)
	var frame := _nine_patch("ResultsFrame", KIT_DIR + "frame_9s_96.png", 24, Vector2.ZERO, SIM_SIZE)
	frame.axis_stretch_horizontal = NinePatchRect.AXIS_STRETCH_MODE_TILE_FIT
	frame.axis_stretch_vertical = NinePatchRect.AXIS_STRETCH_MODE_TILE_FIT
	simulate_window.add_child(frame)
	var sim_title := Label.new()
	sim_title.name = "ResultsTitle"
	sim_title.text = "Simulation"
	simulate_window.add_child(sim_title)
	Ui540.place_title_plank(sim_title, SIM_SIZE.x)
	var inner_w: float = SIM_SIZE.x - PAD * 2.0
	simulate_close = _big_button(simulate_window, "SimulateClose", Vector2(SIM_SIZE.x - PAD - 120.0, 20), Vector2(120, ROW_H), "Close")
	var esc := _esc_keycap(simulate_window, simulate_close)
	esc.name = "SimulateCloseEsc"
	Ui540.hide_on_phone(esc)
	var header := _line(simulate_window, "SimulateHeader", Vector2(PAD, 22), Vector2(inner_w - 192.0, 20), true)
	header.clip_text = true
	var summary := _line(simulate_window, "SimulateSummary", Vector2(PAD, 68), Vector2(inner_w, 24), false)
	summary.z_index = 2
	simulate_scroll = ScrollContainer.new()
	simulate_scroll.name = "SimulateScroll"
	simulate_scroll.position = Vector2(PAD, 98)
	simulate_scroll.size = Vector2(inner_w, 130)
	simulate_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	simulate_scroll.clip_contents = true
	_apply_simulate_scroll_theme(simulate_scroll)
	simulate_window.add_child(simulate_scroll)
	simulate_room_list = VBoxContainer.new()
	simulate_room_list.name = "SimulateRoomList"
	simulate_room_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	simulate_room_list.add_theme_constant_override("separation", 2)
	simulate_scroll.add_child(simulate_room_list)
	simulate_result = Label.new()
	simulate_result.name = "SimulateResult"
	simulate_result.visible = false
	var rerun_w: float = 140.0
	var footer_w: float = inner_w - rerun_w - 16.0
	simulate_footer = VBoxContainer.new()
	simulate_footer.name = "SimulateFooter"
	simulate_footer.position = Vector2(PAD, 236)
	simulate_footer.size = Vector2(footer_w, 84)
	simulate_footer.add_theme_constant_override("separation", 1)
	simulate_footer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	simulate_window.add_child(simulate_footer)
	for line_def: Array in [["SimulateLosses", false], ["SimulateBanked", false], ["SimulateUsed", false], ["SimulateNote", true]]:
		var line := Label.new()
		line.name = str(line_def[0])
		GameTheme.style_ink_label(line, bool(line_def[1]))
		line.autowrap_mode = TextServer.AUTOWRAP_OFF
		line.clip_text = true
		line.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		line.custom_minimum_size = Vector2(footer_w, 20)
		line.mouse_filter = Control.MOUSE_FILTER_IGNORE
		simulate_footer.add_child(line)
	var banked: Label = simulate_footer.get_node("SimulateBanked") as Label
	banked.custom_minimum_size.x = footer_w - 26.0
	banked.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	simulate_essence_icon = _tex_rect(simulate_window, ICON_ESSENCE_TEX, Vector2(PAD + footer_w - 20.0, 236.0 + 21.0), Vector2(20, 20))
	simulate_essence_icon.name = "SimulateEssenceIcon"
	simulate_essence_icon.modulate = ESSENCE_TINT
	simulate_essence_icon.visible = false
	essence_icons.append(simulate_essence_icon)
	simulate_rerun = _big_button(simulate_window, "SimulateRerun", Vector2(SIM_SIZE.x - PAD - rerun_w, SIM_SIZE.y - PAD - ROW_H), Vector2(rerun_w, ROW_H), "Run again")


func _add_title(panel: Control) -> void:
	var title := Label.new()
	title.name = "Title"
	panel.add_child(title)
	Ui540.place_title_plank(title, PANEL_SIZE.x)


func _add_close(panel: Control) -> void:
	var btn := _big_button(panel, "CloseButton", Vector2(PANEL_SIZE.x - PAD - 120.0, HEADER_Y), Vector2(120, ROW_H), "Close")
	btn.tooltip_text = "Close"
	if not Ui540.is_phone_export():
		var esc := _esc_keycap(panel, btn)
		esc.name = "CloseEscKeycap"


func _esc_keycap(parent: Control, close_btn: Control) -> TextureRect:
	## 2× the 28×20 cap, nearest-neighbour, centred on the Close button.
	var pos := Vector2(close_btn.position.x - 8.0 - ESC_KEYCAP_SIZE.x, close_btn.position.y + (ROW_H - ESC_KEYCAP_SIZE.y) * 0.5)
	return _tex_rect(parent, KIT_DIR + "keycap_esc.png", pos, ESC_KEYCAP_SIZE)


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
	_wood_glyph_button(panel, minus_name, pos, BOARD_DIR + "glyph_minus_10x10.png", BOARD_DIR + "glyph_minus_disabled_10x10.png")
	var field_w: float = 56.0 if slot_n > 0 else 64.0
	var field := LineEdit.new()
	field.name = field_name
	field.position = pos + Vector2(ROW_H + 8.0, 0)
	field.size = Vector2(field_w, ROW_H)
	field.clip_contents = true
	field.alignment = HORIZONTAL_ALIGNMENT_CENTER
	field.add_theme_font_override("font", _primary_font)
	field.add_theme_font_size_override("font_size", BIG_SIZE)
	field.add_theme_color_override("font_color", INK)
	_style_field(field, slot_n > 0)
	panel.add_child(field)
	var plus_x: float = ROW_H + 8.0 + field_w + 8.0
	_wood_glyph_button(panel, plus_name, pos + Vector2(plus_x, 0), BOARD_DIR + "glyph_plus_10x10.png", BOARD_DIR + "glyph_plus_disabled_10x10.png")
	if slot_n > 0:
		var cap_x: float = plus_x + ROW_H + 6.0
		var cap := _line(panel, "LoadoutQty%dCap" % slot_n, pos + Vector2(cap_x, 0), Vector2(LOAD_X + LOAD_W - pos.x - cap_x, ROW_H), true)
		cap.text = "/ 100"


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


func _mode_toggle(panel: Control, node_name: String, pos: Vector2, w: float, text: String) -> Button:
	var btn := Button.new()
	btn.name = node_name
	btn.position = pos
	btn.size = Vector2(w, ROW_H)
	btn.text = text
	GameTheme.style_tab_button(btn)
	btn.add_theme_font_override("font", _primary_font)
	btn.add_theme_font_size_override("font_size", BIG_SIZE)
	panel.add_child(btn)
	return btn


## Wood face with the Silver 38 caps in cream (Close, Simulate, Depart, Run again).
func _big_button(parent: Control, node_name: String, pos: Vector2, sz: Vector2, text: String) -> Button:
	var btn := Button.new()
	btn.name = node_name
	btn.position = pos
	btn.size = sz
	btn.text = text
	GameTheme.style_menu_button(btn)
	btn.clip_text = true
	parent.add_child(btn)
	return btn


func _wood_glyph_button(parent: Control, node_name: String, pos: Vector2, glyph: String, glyph_dis: String) -> Button:
	var btn := Button.new()
	btn.name = node_name
	btn.position = pos
	btn.size = Vector2(ROW_H, ROW_H)
	btn.text = ""
	GameTheme.style_wood_button(btn)
	var icon := TextureRect.new()
	icon.name = "Glyph"
	icon.texture = _load_tex(glyph)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.size = Vector2(20, 20)
	icon.position = Vector2(12, 11)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(icon)
	btn.set_meta("glyph_disabled", glyph_dis)
	var on_tex: Texture2D = icon.texture
	var off_tex: Texture2D = _load_tex(glyph_dis)
	btn.draw.connect(func() -> void:
		icon.texture = off_tex if btn.disabled and off_tex != null else on_tex
	)
	parent.add_child(btn)
	return btn


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
	row.custom_minimum_size = Vector2(SIM_SIZE.x - PAD * 2.0 - 14.0, 26)
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
	GameTheme.style_ink_label(left)
	left.clip_text = true
	left.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	h.add_child(left)
	var right := Label.new()
	right.text = right_text
	right.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	right.custom_minimum_size.x = 150
	GameTheme.style_ink_label(right, true)
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
	scroll.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
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
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
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


## Silver 19 parchment line, centred in its row, trimmed instead of wrapping into a neighbour.
func _line(parent: Control, node_name: String, pos: Vector2, sz: Vector2, muted: bool) -> Label:
	var lbl := Label.new()
	lbl.name = node_name
	lbl.position = pos
	lbl.size = sz
	GameTheme.style_ink_label(lbl, muted)
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.autowrap_mode = TextServer.AUTOWRAP_OFF
	lbl.clip_text = true
	lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(lbl)
	return lbl


func _section(parent: Control, node_name: String, pos: Vector2, sz: Vector2) -> Label:
	var lbl := Label.new()
	lbl.name = node_name
	lbl.position = pos
	lbl.size = sz
	_style_section(lbl)
	parent.add_child(lbl)
	return lbl


## Column headings: Jersey 19 ink, as on the character sheet.
func _style_section(lbl: Label) -> void:
	lbl.add_theme_font_override("font", GameTheme.title_font())
	lbl.add_theme_font_size_override("font_size", GameTheme.PLANK_SIZE)
	lbl.add_theme_color_override("font_color", INK)
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.autowrap_mode = TextServer.AUTOWRAP_OFF
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _load_tex(path: String) -> Texture2D:
	if path.begins_with(BOARD_DIR):
		var file_name: String = path.substr(BOARD_DIR.length())
		var from_extra: Texture2D = AssetsExtra.board_tex(file_name)
		if from_extra != null:
			return from_extra
	if path.begins_with("res://assets/art/ui/board/"):
		var file_name: String = path.get_file()
		var from_extra: Texture2D = AssetsExtra.board_tex(file_name)
		if from_extra != null:
			return from_extra
	if path.begins_with(AssetsExtra.SHARED):
		return AssetsExtra.tex(path)
	var shared_name: String = path.get_file()
	if shared_name == "divider_3s_48x6.png":
		var div: Texture2D = AssetsExtra.tex("shared/divider_3s_48x6.png")
		if div != null:
			return div
	if not ResourceLoader.exists(path):
		return null
	return load(path) as Texture2D


## The picker is a framed window over the party bed, so it never covers the Route column.
func place_picker(slot_btn: Button) -> void:
	if picker_popup == null or slot_btn == null or _panel == null:
		return
	var list_h: float = -PICKER_ROW_GAP
	for row: Button in picker_rows:
		if row.visible:
			list_h += maxf(PICKER_ROW_H, row.get_combined_minimum_size().y) + PICKER_ROW_GAP
	list_h = maxf(list_h, 0.0)
	var scroll_h: float = minf(list_h, PICKER_SCROLL_MAX_H)
	var h: float = minf(PICKER_CHROME_H + scroll_h, PICKER_POPUP_MAX_H)
	if picker_scroll != null:
		picker_scroll.custom_minimum_size = Vector2(PICKER_ROW_W, scroll_h)
		picker_scroll.size = Vector2(PICKER_ROW_W, scroll_h)
	var origin: Vector2 = _panel.global_position - global_position
	picker_popup.custom_minimum_size = Vector2(PICKER_POPUP_W, h)
	picker_popup.size = Vector2(PICKER_POPUP_W, h)
	picker_popup.position = origin + Vector2(PARTY_X, BODY_Y + 6.0)
	picker_tail.visible = false
	picker_popup.visible = true


func hide_picker() -> void:
	if picker_popup != null:
		picker_popup.visible = false
	if picker_tail != null:
		picker_tail.visible = false
