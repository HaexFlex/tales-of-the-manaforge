extends ColorRect
## "While you were away". Built from the catch-up report. Not a save field.

const ART: String = "res://assets/ui/offline/"
const THEME_UI: String = "res://assets/ui/theme/"
const ICONS: String = "res://assets_extra/shared/"
const WINDOW_Y: float = 92.0
const WINDOW_H: float = 424.0
const PC_W: float = 600.0
const PHONE_W: float = 912.0
const INSET: float = 44.0
const HEADER_H: float = 44.0
const ROW_H: float = 34.0
const SHARD_ROW_H: float = 52.0
const BODY_H: float = 236.0
const HINT_H: float = 16.0
const INK: Color = Color8(62, 42, 24)
const MUTED: Color = Color8(154, 126, 82)
const CREAM: Color = Color8(250, 238, 204)
const CREAM_MUTED: Color = Color8(214, 190, 138)
const CYAN: Color = Color8(143, 227, 230)
const OUTLINE: Color = Color8(26, 15, 8)

var _report: Dictionary = {}
var _open_sections: Dictionary = {}
var _card: Panel
var _headline: Label
var _body: ScrollContainer
var _sections: VBoxContainer
var _continue: Button
var _pause_was_visible: bool = true


func _ready() -> void:
	name = "OfflineSummary"
	visible = false
	color = Color(0, 0, 0, 0.45)
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_preset(Control.PRESET_FULL_RECT)
	offset_left = 0.0
	offset_top = 0.0
	offset_right = 0.0
	offset_bottom = 0.0
	z_index = 0
	_build_shell()
	if not get_viewport().size_changed.is_connected(_layout):
		get_viewport().size_changed.connect(_layout)


func tick_queue() -> void:
	if visible:
		return
	if not has_node("/root/SaveService"):
		return
	var report: Dictionary = SaveService.pending_offline_report
	if report.is_empty() or not bool(report.get("show", false)):
		return
	if _blocked_by_modal():
		return
	present(report)


func present(report: Dictionary) -> void:
	_report = report.duplicate(true)
	_open_sections.clear()
	visible = true
	_fill()
	_layout()
	_hide_phone_pause(true)
	if _continue:
		_continue.grab_focus()
	if has_node("/root/GameAudio"):
		GameAudio.play_ui_open()


func dismiss() -> void:
	visible = false
	_hide_phone_pause(false)
	if has_node("/root/SaveService"):
		SaveService.pending_offline_report = {}
	if has_node("/root/GameAudio"):
		GameAudio.play_ui_confirm()


func is_open() -> bool:
	return visible


func card_position() -> Vector2:
	return _card.position if _card else Vector2.ZERO


func card_size() -> Vector2:
	return _card.size if _card else Vector2.ZERO


func headline_text() -> String:
	return _headline.text if _headline else ""


func section_visible(section_id: String) -> bool:
	var node: Node = _sections.get_node_or_null(section_id) if _sections else null
	return node != null and node.visible


func ancient_note_text() -> String:
	if _sections == null:
		return ""
	var wrap: Node = _sections.get_node_or_null("AncientNote")
	if wrap == null or not (wrap is CanvasItem) or not (wrap as CanvasItem).visible:
		return ""
	var note: Label = wrap.get_node_or_null("AncientNote") as Label
	if note == null:
		return ""
	return note.text


func shard_tag_text() -> String:
	var tag: Label = find_child("ShardTag", true, false) as Label
	if tag == null or not tag.visible:
		return ""
	return tag.text


func _blocked_by_modal() -> bool:
	if BattleView.is_open():
		return true
	if has_node("/root/EchoChamber") and EchoChamber.in_battle:
		return true
	var hud: Node = get_parent()
	if hud == null:
		return false
	var shop: CanvasItem = hud.get("ascension_panel") as CanvasItem
	return shop != null and shop.visible


func _build_shell() -> void:
	_card = Panel.new()
	_card.name = "OfflineCard"
	_card.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_card)
	Ui540.apply_kit_frame_panel(_card, "offline_summary")
	var title := Label.new()
	title.name = "Title"
	title.text = "While you were away"
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_card.add_child(title)
	var close := Button.new()
	close.name = "CloseButton"
	_card.add_child(close)
	Ui540.configure_kit_close_button(close)
	close.pressed.connect(dismiss)
	_headline = Label.new()
	_headline.name = "Headline"
	_headline.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_headline.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_card.add_child(_headline)
	_style_ink(_headline, false)
	_body = ScrollContainer.new()
	_body.name = "Body"
	_body.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_body.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_card.add_child(_body)
	_sections = VBoxContainer.new()
	_sections.name = "Sections"
	_sections.add_theme_constant_override("separation", 0)
	_body.add_child(_sections)
	_continue = Button.new()
	_continue.name = "ContinueButton"
	_continue.text = "Continue"
	_card.add_child(_continue)
	if has_node("/root/GameTheme"):
		GameTheme.force_primary_button(_continue)
	_continue.pressed.connect(dismiss)


func _layout() -> void:
	if _card == null:
		return
	set_anchors_preset(Control.PRESET_FULL_RECT)
	offset_left = 0.0
	offset_top = 0.0
	offset_right = 0.0
	offset_bottom = 0.0
	var vs: Vector2 = Ui540.viewport_size()
	var phone: bool = Ui540.is_phone_export()
	var w: float = PHONE_W if phone else PC_W
	var x: float = (24.0 if phone else (vs.x - w) * 0.5) + (Ui540.center_shift_x() if phone else 0.0)
	if not phone:
		x = roundf((vs.x - w) * 0.5)
	x = clampf(x, 24.0, maxf(24.0, vs.x - w - 24.0))
	_card.position = Vector2(roundf(x), WINDOW_Y)
	_card.size = Vector2(w, WINDOW_H)
	var title: Label = _card.get_node_or_null("Title") as Label
	if title:
		if has_node("/root/ContentStrings"):
			title.text = ContentStrings.get_text("offline_title")
		if has_node("/root/GameTheme"):
			GameTheme.style_plank_label(title)
		Ui540.place_title_plank(title, w)
	var close: Control = _card.get_node_or_null("CloseButton")
	var content_w: float = w - INSET * 2.0
	if close:
		close.position = Vector2(w - INSET - 44.0, INSET)
		close.size = Vector2(44, 44)
	if _headline:
		_headline.position = Vector2(INSET, INSET + 4.0)
		_headline.size = Vector2(content_w - 56.0, 36.0)
	if _body:
		_body.position = Vector2(INSET, INSET + 48.0)
		_body.size = Vector2(content_w, BODY_H)
		_sections.custom_minimum_size = Vector2(content_w - 8.0, 0)
	if _continue:
		_continue.position = Vector2(roundf((w - 300.0) * 0.5), WINDOW_H - INSET - 44.0)
		_continue.size = Vector2(300, 44)


func _fill() -> void:
	if _sections == null:
		return
	for child: Node in _sections.get_children():
		child.free()
	if _headline and has_node("/root/ContentStrings"):
		var away: String = ContentStrings.get_text("offline_headline", {"away": _format_span(float(_report.get("raw_sec", 0.0)))})
		var worth: String = ContentStrings.get_text("offline_worth", {"worth": _format_worth(float(_report.get("effective_sec", 0.0)))})
		_headline.text = "%s %s" % [away, worth]
	if _continue and has_node("/root/ContentStrings"):
		_continue.text = ContentStrings.get_text("offline_continue")
	var blocked: bool = bool(_report.get("blocked", false))
	if blocked:
		_add_ancient_note()
	if not blocked:
		_add_section("gathered", "offline_sec_gathered", "icon_section_gathered_24.png", _gathered_summary(), _gathered_rows())
		_add_section("workers", "offline_sec_workers", "icon_section_workers_24.png", _workers_summary(), _workers_rows())
		_add_section("forge", "offline_sec_forge", "icon_section_forge_24.png", _forge_summary(), _forge_rows())
	_add_section("expedition", "offline_sec_expedition", "icon_section_expedition_24.png", _expedition_summary(), _expedition_rows())
	_add_section("left", "offline_sec_left", "icon_section_leftover_24.png", _left_summary(), _left_rows())
	_layout()


func _add_ancient_note() -> void:
	var wrap := PanelContainer.new()
	wrap.name = "AncientNote"
	var box := Ui540.kit_stylebox_9s(ART + "note_amber_9s_24x24.png", Vector4i(8, 8, 8, 8), Vector4(12, 8, 12, 8))
	wrap.add_theme_stylebox_override("panel", box)
	var label := Label.new()
	label.name = "AncientNote"
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_style_ink(label, false)
	var minutes: int = 0
	if has_node("/root/GameState"):
		minutes = maxi(0, int(round(GameState.ancient_remaining_sec / 60.0)))
	var term: String = "bloom"
	if has_node("/root/ContentStrings"):
		var keyed: String = ContentStrings.get_text("offline_ancient_term")
		if keyed != "offline_ancient_term":
			term = keyed
		label.text = ContentStrings.get_text("offline_ancient_blocked", {"term": term, "minutes": minutes})
	else:
		label.text = term
	wrap.add_child(label)
	_sections.add_child(wrap)


func _add_section(section_id: String, title_key: String, icon_file: String, summary: String, rows: Array) -> void:
	if rows.is_empty() and section_id != "left":
		return
	if section_id == "left" and rows.is_empty():
		return
	var host := VBoxContainer.new()
	host.name = section_id
	host.add_theme_constant_override("separation", 0)
	var open: bool = bool(_open_sections.get(section_id, false))
	var header := Button.new()
	header.name = "Header"
	header.focus_mode = Control.FOCUS_ALL
	header.custom_minimum_size = Vector2(0, HEADER_H)
	header.alignment = HORIZONTAL_ALIGNMENT_LEFT
	header.pressed.connect(_toggle_section.bind(section_id))
	_style_header(header, open)
	host.add_child(header)
	var chevron := TextureRect.new()
	chevron.name = "Chevron"
	chevron.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chevron.texture = load(ART + ("chevron_down_14.png" if open else "chevron_right_14.png"))
	chevron.position = Vector2(10, 15)
	chevron.size = Vector2(14, 14)
	header.add_child(chevron)
	var icon := TextureRect.new()
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.texture = load(ART + icon_file)
	icon.position = Vector2(30, 10)
	icon.size = Vector2(24, 24)
	header.add_child(icon)
	var title := Label.new()
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title.text = ContentStrings.get_text(title_key) if has_node("/root/ContentStrings") else title_key
	title.position = Vector2(62, 10)
	title.size = Vector2(120, 24)
	_style_cream(title, false)
	header.add_child(title)
	var sum := Label.new()
	sum.name = "Summary"
	sum.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sum.text = summary
	sum.clip_text = true
	sum.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	sum.visible = not open
	header.add_child(sum)
	var show_tag: bool = section_id == "gathered" and _shard_tag() != "" and not open
	if show_tag:
		_place_tag(header, _shard_tag())
	var hint_line: Label = null
	if show_tag:
		hint_line = Label.new()
		hint_line.name = "ShardHint"
		hint_line.text = ContentStrings.get_text("offline_shard_hint") if has_node("/root/ContentStrings") else ""
		hint_line.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		_style_ink(hint_line, true)
		hint_line.custom_minimum_size = Vector2(0, HINT_H)
		host.add_child(hint_line)
	var details := VBoxContainer.new()
	details.name = "Details"
	details.visible = open
	details.add_theme_constant_override("separation", 0)
	var row_i: int = 0
	for row_v: Variant in rows:
		if typeof(row_v) != TYPE_DICTIONARY:
			continue
		details.add_child(_detail_row(row_v as Dictionary, row_i, section_id == "gathered" and open))
		row_i += 1
	host.add_child(details)
	_sections.add_child(host)
	var content_w: float = _card.size.x - INSET * 2.0 - 8.0
	sum.position = Vector2(144, 10)
	var tag_room: float = 150.0 if show_tag else 12.0
	sum.size = Vector2(maxf(40.0, content_w - 144.0 - tag_room), 24)
	_style_cream(sum, true)


func _detail_row(row: Dictionary, index: int, gathered_open: bool) -> Control:
	var kind: String = str(row.get("kind", "text"))
	var tall: bool = kind == "manashards" and gathered_open
	var h: float = SHARD_ROW_H if tall else ROW_H
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, h)
	var tex: String = ART + "list_row_9s_odd_24x24.png" if index % 2 == 1 else THEME_UI + "list_row_9s_even_24x24.png"
	panel.add_theme_stylebox_override("panel", Ui540.kit_stylebox_9s(tex, Vector4i(2, 2, 2, 2)))
	var label := Label.new()
	label.text = str(row.get("text", ""))
	label.position = Vector2(14, 6)
	_style_ink(label, false)
	panel.add_child(label)
	var value: String = str(row.get("value", ""))
	if value != "":
		var val := Label.new()
		val.text = value
		val.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		_style_ink(val, false)
		val.set_anchors_preset(Control.PRESET_TOP_RIGHT)
		val.position = Vector2(-120, 6)
		val.size = Vector2(108, 22)
		panel.add_child(val)
	if kind == "manashards" and gathered_open and _shard_tag() != "":
		var tag := _place_tag(panel, _shard_tag())
		tag.position = Vector2(220, 6)
		var hint := Label.new()
		hint.name = "ShardHint"
		hint.text = ContentStrings.get_text("offline_shard_hint") if has_node("/root/ContentStrings") else ""
		_style_ink(hint, true)
		hint.position = Vector2(14, 28)
		hint.size = Vector2(400, 18)
		hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		panel.add_child(hint)
	return panel


func _place_tag(parent: Control, text: String) -> Label:
	var chip := NinePatchRect.new()
	chip.name = "ShardChip"
	chip.texture = load(ART + "tag_chip_9s_24x22.png")
	chip.patch_margin_left = 4
	chip.patch_margin_top = 4
	chip.patch_margin_right = 4
	chip.patch_margin_bottom = 4
	chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var label := Label.new()
	label.name = "ShardTag"
	label.text = text
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_color_override("font_color", CYAN)
	if has_node("/root/GameTheme"):
		GameTheme.style_body_label(label)
	label.add_theme_color_override("font_color", CYAN)
	var font: Font = label.get_theme_font("font")
	var width: float = 80.0
	if font:
		width = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 19).x + 20.0
	chip.custom_minimum_size = Vector2(width, 22)
	chip.size = Vector2(width, 22)
	label.size = Vector2(width, 22)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	chip.add_child(label)
	parent.add_child(chip)
	chip.position = Vector2(maxf(0.0, parent.size.x - width - 8.0), 11)
	if parent.size.x < 8.0:
		chip.set_anchors_preset(Control.PRESET_TOP_RIGHT)
		chip.offset_left = -width - 8.0
		chip.offset_right = -8.0
		chip.offset_top = 11.0
		chip.offset_bottom = 33.0
	return label


func _toggle_section(section_id: String) -> void:
	_open_sections[section_id] = not bool(_open_sections.get(section_id, false))
	_fill()


func _style_header(btn: Button, open: bool) -> void:
	var face: String = "wood_button_9s_selected_32x28.png" if open else "wood_button_9s_normal_32x28.png"
	var hover: String = "wood_button_9s_selected_32x28.png" if open else "wood_button_9s_hover_32x28.png"
	var box := func(path: String) -> StyleBoxTexture:
		return Ui540.kit_stylebox_9s(THEME_UI + path, Vector4i(8, 8, 8, 8))
	btn.add_theme_stylebox_override("normal", box.call(face))
	btn.add_theme_stylebox_override("hover", box.call(hover))
	btn.add_theme_stylebox_override("pressed", box.call("wood_button_9s_pressed_32x28.png"))
	btn.add_theme_stylebox_override("focus", box.call(hover))
	btn.text = ""


func _style_ink(lbl: Label, muted: bool) -> void:
	if has_node("/root/GameTheme"):
		GameTheme.style_ink_label(lbl, muted)
		return
	lbl.add_theme_color_override("font_color", MUTED if muted else INK)


func _style_cream(lbl: Label, muted: bool) -> void:
	if has_node("/root/GameTheme"):
		GameTheme.style_body_label(lbl)
	lbl.add_theme_color_override("font_color", CREAM_MUTED if muted else CREAM)
	lbl.add_theme_color_override("font_outline_color", OUTLINE)
	lbl.add_theme_constant_override("outline_size", 1)


func _txt(key: String, tokens: Dictionary = {}) -> String:
	if has_node("/root/ContentStrings"):
		return ContentStrings.get_text(key, tokens)
	return key


func _shard_tag() -> String:
	if bool(_report.get("blocked", false)):
		return ""
	if int(_report.get("manashards", 0)) <= 0:
		return ""
	return _txt("offline_shard_tag", {"mult": "%.2f" % float(_report.get("shard_mult", 0.25))})


func _gathered_rows() -> Array:
	var rows: Array = []
	for pair: Array in [["essence", "offline_line_essence"], ["manashards", "offline_line_manashards"], ["wood", "offline_line_wood"], ["stone", "offline_line_stone"], ["food", "offline_line_food"]]:
		var n: int = int(_report.get(str(pair[0]), 0))
		if n <= 0:
			continue
		var label: String = _txt(str(pair[1]), {"n": _comma(n)})
		rows.append({"kind": str(pair[0]), "text": label, "value": "+%s" % _comma(n)})
	return rows


func _gathered_summary() -> String:
	var bits: PackedStringArray = PackedStringArray()
	for pair: Array in [["essence", "Ess"], ["manashards", "Sh"], ["wood", "Wood"], ["stone", "Stone"], ["food", "Food"]]:
		var n: int = int(_report.get(str(pair[0]), 0))
		if n > 0:
			bits.append("+%s %s" % [_comma(n), str(pair[1])])
	return "  ".join(bits)


func _workers_rows() -> Array:
	var rows: Array = []
	var keeper_kind: String = str(_report.get("keeper_kind", ""))
	if keeper_kind != "":
		rows.append({"text": _txt("offline_worker_keeper", {"task": _task_phrase(keeper_kind, str(_report.get("keeper_task", "")))})})
	var elaia_kind: String = str(_report.get("elaia_kind", ""))
	if elaia_kind != "":
		rows.append({"text": _txt("offline_worker_elaia", {"task": _task_phrase(elaia_kind, str(_report.get("elaia_task", "")))})})
	var wisps: int = int(_report.get("wisp_count", 0))
	if wisps > 0:
		rows.append({"text": _txt("offline_worker_wisps", {"count": wisps})})
	return rows


func _workers_summary() -> String:
	var rows: Array = _workers_rows()
	if rows.is_empty():
		return ""
	return str((rows[0] as Dictionary).get("text", ""))


func _forge_rows() -> Array:
	var rows: Array = []
	var stations_v: Variant = _report.get("forge_stations", {})
	if typeof(stations_v) != TYPE_DICTIONARY:
		return rows
	for row_v: Variant in (stations_v as Dictionary).values():
		if typeof(row_v) != TYPE_DICTIONARY:
			continue
		var row: Dictionary = row_v
		var finished: int = int(row.get("finished", 0))
		var item: String = str(row.get("name", ""))
		if finished > 0:
			rows.append({"text": _txt("offline_forge_done", {"count": finished}), "value": item})
		if bool(row.get("working", false)):
			rows.append({"text": _txt("offline_forge_working", {"item": item})})
	return rows


func _forge_summary() -> String:
	var finished: int = int(_report.get("forge_completed", 0))
	if finished > 0:
		return _txt("offline_forge_done", {"count": finished})
	var rows: Array = _forge_rows()
	if rows.is_empty():
		return ""
	return str((rows[0] as Dictionary).get("text", ""))


func _expedition_rows() -> Array:
	var trip_v: Variant = _report.get("expedition", {})
	if typeof(trip_v) != TYPE_DICTIONARY:
		return []
	var trip: Dictionary = trip_v
	var reason: String = str(trip.get("reason", ""))
	var rows: Array = []
	if reason == "overwhelmed":
		rows.append({"text": _txt("offline_exp_failed", {"room": int(trip.get("room", 0))})})
	elif reason == "flee":
		rows.append({"text": _txt("offline_exp_flee")})
	elif reason == "finished" or reason == "head_home":
		rows.append({"text": _txt("offline_exp_done", {"loot": _loot_phrase(trip.get("loot", {}))})})
	elif bool(trip.get("waiting", false)):
		rows.append({"text": _txt("offline_exp_waiting")})
	var rooms: int = int(trip.get("rooms", 0))
	if rooms > 0 and reason != "overwhelmed":
		rows.append({"text": _txt("offline_exp_rooms", {"rooms": rooms})})
	return rows


func _expedition_summary() -> String:
	var rows: Array = _expedition_rows()
	if rows.is_empty():
		return ""
	return str((rows[0] as Dictionary).get("text", ""))


func _left_rows() -> Array:
	var rows: Array = []
	if not bool(_report.get("blocked", false)) and str(_report.get("keeper_kind", "")) == "":
		rows.append({"text": _txt("offline_left_idle")})
	var finished: int = int(_report.get("forge_completed", 0))
	var still: bool = false
	var stations_v: Variant = _report.get("forge_stations", {})
	if typeof(stations_v) == TYPE_DICTIONARY:
		for row_v: Variant in (stations_v as Dictionary).values():
			if typeof(row_v) == TYPE_DICTIONARY and bool((row_v as Dictionary).get("working", false)):
				still = true
	if finished > 0 and not still:
		rows.append({"text": _txt("offline_left_forge_empty")})
	rows.append({"text": _txt("offline_explain")})
	return rows


func _left_summary() -> String:
	return _txt("offline_explain")


func _loot_phrase(loot_v: Variant) -> String:
	if typeof(loot_v) != TYPE_DICTIONARY or (loot_v as Dictionary).is_empty():
		return _txt("offline_sec_expedition")
	var bits: PackedStringArray = PackedStringArray()
	for key_v: Variant in (loot_v as Dictionary).keys():
		var n: int = int((loot_v as Dictionary)[key_v])
		if n > 0:
			bits.append("%s × %d" % [str(key_v), n])
	if bits.is_empty():
		return _txt("offline_sec_expedition")
	return ", ".join(bits)


func _task_phrase(kind: String, target: String) -> String:
	if kind == "water":
		return "the Manatree"
	if kind == "harvest":
		match target:
			"wood":
				return "the trees"
			"stone":
				return "the stone"
			"food":
				return "the berries"
			_:
				return target
	if target != "":
		return target
	return "your work"


func _format_span(sec: float) -> String:
	var total: int = maxi(0, int(round(sec)))
	var days: int = int(total / 86400.0)
	var hours: int = int((total % 86400) / 3600.0)
	var mins: int = int((total % 3600) / 60.0)
	if days > 0:
		return "%dd %dh" % [days, hours] if hours > 0 else "%dd" % days
	if hours > 0:
		return "%dh %dm" % [hours, mins] if mins > 0 else "%dh" % hours
	if mins > 0:
		return "%dm" % mins
	return "%ds" % total


func _format_worth(sec: float) -> String:
	var mins: int = maxi(0, int(round(sec / 60.0)))
	if mins < 60:
		return "%d min" % mins
	var hours: int = int(mins / 60.0)
	var rest: int = mins % 60
	if rest == 0:
		return "1 hour" if hours == 1 else "%d hours" % hours
	return "%dh %d min" % [hours, rest]


func _comma(n: int) -> String:
	var sign: String = ""
	var v: int = n
	if v < 0:
		sign = "-"
		v = -v
	var text: String = str(v)
	var out: String = ""
	while text.length() > 3:
		out = "," + text.substr(text.length() - 3, 3) + out
		text = text.substr(0, text.length() - 3)
	return sign + text + out


func _hide_phone_pause(hide: bool) -> void:
	if not Ui540.is_phone_export():
		return
	var hud: Node = get_parent()
	if hud == null:
		return
	var btn: CanvasItem = hud.get("pause_button") as CanvasItem
	if btn == null:
		return
	if hide:
		_pause_was_visible = btn.visible
		btn.visible = false
	else:
		btn.visible = _pause_was_visible


func _gui_input(event: InputEvent) -> void:
	if not visible or _card == null:
		return
	if event is InputEventMouseButton:
		var mouse: InputEventMouseButton = event
		if mouse.pressed and mouse.button_index == MOUSE_BUTTON_LEFT:
			if not _card.get_global_rect().has_point(mouse.global_position):
				dismiss()
				accept_event()
