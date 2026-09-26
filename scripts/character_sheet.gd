extends Control
class_name CharacterSheet
## Paper-doll character sheet. Portrait left, battle gear middle, stats right.
## Equip by click or drag. Locked slots stay grey until a later forge unlock.

signal close_requested

const PORTRAIT_PATH: String = "res://assets/art/keeper/keeper_idle_south_0000.png"
const SHEET_SIZE: Vector2 = Vector2(1272, 716)
const HOST_POS: Vector2 = Vector2(12, 54)
## Paper-doll host. The sprite is inset; slots sit in the margins around the figure.
const PORTRAIT_SIZE: Vector2 = Vector2(496, 622)
## Prior fitted portrait was 160×160 (128² kept inside a 160×284 rect). This is 3×.
const SPRITE_SIZE: Vector2 = Vector2(480, 480)
const SPRITE_POS: Vector2 = Vector2(8, 70)
const PLACEHOLDER_SWATCH: Color = Color(0.42, 0.40, 0.36, 1.0)


static func make_item_icon(item_id: String) -> Control:
	var tip: String = Equipment.item_display_name(item_id)
	var sheet_index: int = HudIcons.index_for_item(item_id)
	if sheet_index >= 0:
		var sheet_icon: TextureRect = HudIcons.make_icon(sheet_index)
		sheet_icon.tooltip_text = tip
		return sheet_icon
	var path: String = ""
	match item_id:
		"forge_key_relic":
			path = "res://assets/art/ui/icons/icon_forge_key.png"
	if path != "" and ResourceLoader.exists(path):
		var icon := TextureRect.new()
		icon.custom_minimum_size = Vector2(32, 32)
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture = load(path) as Texture2D
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon.tooltip_text = tip
		return icon
	var swatch := ColorRect.new()
	swatch.custom_minimum_size = Vector2(32, 32)
	swatch.color = PLACEHOLDER_SWATCH
	swatch.mouse_filter = Control.MOUSE_FILTER_IGNORE
	swatch.tooltip_text = tip
	return swatch
## Slot plates in host space, flanking the enlarged Keeper so they do not cover the figure.
const SLOT_POS: Dictionary = {
	"head": Vector2(216, 2),
	"relic": Vector2(18, 80),
	"cape": Vector2(18, 208),
	"body": Vector2(18, 337),
	"ring1": Vector2(18, 465),
	"weapon": Vector2(400, 80),
	"hands": Vector2(400, 208),
	"pants": Vector2(400, 337),
	"ring2": Vector2(400, 465),
	"feet": Vector2(216, 554),
}
const SLOT_SIZE: Vector2 = Vector2(56, 66)
const SLOT_SQUARE: Vector2 = Vector2(44, 44)
## Empty and locked chrome come from the HUD icon sheet. No gold edge — the caption sits under the square.
const STAT_TOP: float = 30.0
const STAT_NAME_H: float = 22.0
const STAT_ROLE_H: float = 18.0
const STAT_GAP_SMALL: float = 4.0
const STAT_NUM_H: float = 24.0
const STAT_GAP_LARGE: float = 10.0
const STAT_STRIDE: float = STAT_NAME_H + STAT_ROLE_H + STAT_GAP_SMALL + STAT_NUM_H + STAT_GAP_LARGE
const WOOD: Color = Color(0.16, 0.11, 0.07, 0.98)
const GOLD: Color = Color(0.82, 0.64, 0.28, 1.0)
const INK: Color = Color(0.92, 0.86, 0.72, 1.0)
const MUTED: Color = Color(0.70, 0.64, 0.52, 1.0)

var _portrait: TextureRect
var _inv_list: VBoxContainer
var _footer: Label
var _hover_item_id: String = ""
var _gear_tab: String = "all"
var _built: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_preset(Control.PRESET_FULL_RECT)
	offset_left = 0.0
	offset_top = 0.0
	offset_right = 0.0
	offset_bottom = 0.0
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	_build()
	call_deferred("_center_stat_glyphs")
	if not Equipment.equipment_changed.is_connected(_refresh):
		Equipment.equipment_changed.connect(_refresh)
	if not KeeperStats.ranks_changed.is_connected(_on_ranks):
		KeeperStats.ranks_changed.connect(_on_ranks)
	_refresh()


func _on_ranks(_stat_id: StringName) -> void:
	if visible:
		_refresh_stats()


func is_open() -> bool:
	return visible


func open_sheet() -> void:
	visible = true
	_hover_item_id = ""
	_refresh()


func close_sheet() -> void:
	visible = false
	_hover_item_id = ""


func request_close() -> void:
	close_requested.emit()


func request_equip(item_id: String) -> String:
	var result: String = Equipment.try_equip(item_id)
	_toast(result, item_id, Equipment.item_slot(item_id))
	return result


func request_equip_slot(item_id: String, slot_id: String) -> String:
	var result: String = Equipment.try_equip_to_slot(item_id, slot_id)
	_toast(result, item_id, slot_id)
	return result


func request_unequip(slot_id: String) -> String:
	var item_id: String = Equipment.equipped_id(slot_id)
	var result: String = Equipment.try_unequip(slot_id)
	_toast(result, item_id, slot_id)
	return result


func set_hover_item(item_id: String) -> void:
	if _hover_item_id == item_id:
		return
	_hover_item_id = item_id
	_refresh_stats()


func _toast(result: String, item_id: String, slot_id: String) -> void:
	var item_name: String = Equipment.item_display_name(item_id) if item_id != "" else ""
	var text: String = ""
	match result:
		"ok":
			if Equipment.equipped_id(slot_id) == item_id and item_id != "":
				text = ContentStrings.get_text("equip_ok", {"item": item_name})
			else:
				text = ContentStrings.get_text("equip_unequip_ok", {"item": item_name})
			GameAudio.play_ui_confirm()
			SaveService.save_game()
		"locked":
			text = Equipment.slot_lock_hint(slot_id if slot_id != "" else Equipment.item_slot(item_id))
			GameAudio.play_tree_deny()
		"wrong_slot":
			text = ""
			GameAudio.play_tree_deny()
		"missing":
			text = ContentStrings.get_text("equip_no_item")
			GameAudio.play_tree_deny()
		"empty":
			text = ""
		_:
			text = ""
	if text != "":
		if _footer:
			_footer.text = text
		GameState.status_message.emit(text)


func _build() -> void:
	if _built:
		return
	_built = true
	var dim := ColorRect.new()
	dim.name = "Dim"
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.02, 0.03, 0.02, 0.55)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	dim.gui_input.connect(_on_dim_input)
	add_child(dim)

	var sheet := Panel.new()
	sheet.name = "Sheet"
	sheet.custom_minimum_size = SHEET_SIZE
	sheet.anchor_left = 0.5
	sheet.anchor_top = 0.5
	sheet.anchor_right = 0.5
	sheet.anchor_bottom = 0.5
	sheet.offset_left = -SHEET_SIZE.x * 0.5
	sheet.offset_top = -SHEET_SIZE.y * 0.5
	sheet.offset_right = SHEET_SIZE.x * 0.5
	sheet.offset_bottom = SHEET_SIZE.y * 0.5
	sheet.mouse_filter = Control.MOUSE_FILTER_STOP
	sheet.add_theme_stylebox_override("panel", _wood_style())
	add_child(sheet)

	var title := Label.new()
	title.name = "Title"
	title.position = Vector2(20, 8)
	title.size = Vector2(640, 26)
	title.text = ContentStrings.get_text("char_sheet_title")
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", GOLD)
	sheet.add_child(title)

	var hint := Label.new()
	hint.name = "Hint"
	hint.position = Vector2(20, 32)
	hint.size = Vector2(960, 18)
	hint.text = ContentStrings.get_text("char_sheet_hint")
	var hotkey := Label.new()
	hotkey.name = "HotkeyHint"
	hotkey.position = Vector2(SHEET_SIZE.x - 250, 34)
	hotkey.size = Vector2(120, 18)
	hotkey.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hotkey.text = ContentStrings.get_text("char_sheet_hotkey_hint")
	hotkey.add_theme_font_size_override("font_size", 11)
	hotkey.add_theme_color_override("font_color", MUTED)
	sheet.add_child(hotkey)
	hint.add_theme_font_size_override("font_size", 12)
	hint.add_theme_color_override("font_color", MUTED)
	sheet.add_child(hint)

	var close := Button.new()
	close.name = "CloseButton"
	close.position = Vector2(SHEET_SIZE.x - 116, 8)
	close.size = Vector2(96, 36)
	close.text = ContentStrings.get_text("char_sheet_close")
	close.pressed.connect(request_close)
	_paint_button(close, Color(0.18, 0.14, 0.10, 1.0))
	sheet.add_child(close)

	var host := Control.new()
	host.name = "PortraitHost"
	host.position = HOST_POS
	host.size = PORTRAIT_SIZE
	host.custom_minimum_size = PORTRAIT_SIZE
	host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sheet.add_child(host)

	var backdrop := ColorRect.new()
	backdrop.name = "PortraitBackdrop"
	backdrop.position = SPRITE_POS
	backdrop.size = SPRITE_SIZE
	backdrop.color = Color(0.10, 0.14, 0.11, 1.0)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	host.add_child(backdrop)

	_portrait = TextureRect.new()
	_portrait.name = "Portrait"
	_portrait.position = SPRITE_POS
	_portrait.size = SPRITE_SIZE
	_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tex: Texture2D = load(PORTRAIT_PATH) as Texture2D
	_portrait.texture = tex
	host.add_child(_portrait)

	for slot_name: StringName in Equipment.SLOT_ORDER:
		var sid: String = String(slot_name)
		var plate := SlotPlate.new()
		plate.name = "Slot_%s" % sid
		plate.slot_id = sid
		plate.host = self
		plate.custom_minimum_size = SLOT_SIZE
		plate.size = SLOT_SIZE
		var placed: Variant = SLOT_POS.get(sid, null)
		if placed is Vector2:
			plate.position = placed as Vector2
		else:
			var anchor: Vector2 = Equipment.slot_anchor(sid)
			plate.position = Vector2(
				anchor.x * PORTRAIT_SIZE.x - SLOT_SIZE.x * 0.5,
				anchor.y * PORTRAIT_SIZE.y - SLOT_SIZE.y * 0.5
			)
		plate.mouse_filter = Control.MOUSE_FILTER_STOP
		host.add_child(plate)
		plate.setup()

	var mid := InvColumn.new()
	mid.name = "GearColumn"
	mid.host = self
	mid.mouse_filter = Control.MOUSE_FILTER_STOP
	mid.position = Vector2(524, 64)
	mid.size = Vector2(360, 600)
	sheet.add_child(mid)

	var gear_title := Label.new()
	gear_title.name = "GearTitle"
	gear_title.position = Vector2(0, 0)
	gear_title.size = Vector2(360, 22)
	gear_title.text = ContentStrings.get_text("gear_title")
	gear_title.add_theme_font_size_override("font_size", 15)
	gear_title.add_theme_color_override("font_color", GOLD)
	mid.add_child(gear_title)

	var gear_hint := Label.new()
	gear_hint.position = Vector2(0, 22)
	gear_hint.size = Vector2(360, 30)
	gear_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	gear_hint.text = ContentStrings.get_text("gear_hint")
	var persist := Label.new()
	persist.name = "PersistHint"
	persist.position = Vector2(0, 54)
	persist.size = Vector2(360, 16)
	persist.text = ContentStrings.get_text("weapon_persist_hint")
	persist.add_theme_font_size_override("font_size", 11)
	persist.add_theme_color_override("font_color", MUTED)
	mid.add_child(persist)
	var tabs := HBoxContainer.new()
	tabs.name = "GearTabs"
	tabs.position = Vector2(0, 72)
	tabs.size = Vector2(360, 28)
	tabs.add_theme_constant_override("separation", 6)
	mid.add_child(tabs)
	var tab_all := Button.new()
	tab_all.name = "TabAll"
	tab_all.text = ContentStrings.get_text("gear_tab_all")
	tab_all.custom_minimum_size = Vector2(72, 26)
	tab_all.pressed.connect(_set_gear_tab.bind("all"))
	_paint_button(tab_all, Color(0.18, 0.14, 0.10, 1.0))
	tabs.add_child(tab_all)
	var tab_weapons := Button.new()
	tab_weapons.name = "TabWeapons"
	tab_weapons.text = ContentStrings.get_text("gear_tab_weapons")
	tab_weapons.custom_minimum_size = Vector2(96, 26)
	tab_weapons.pressed.connect(_set_gear_tab.bind("weapons"))
	_paint_button(tab_weapons, Color(0.18, 0.14, 0.10, 1.0))
	tabs.add_child(tab_weapons)
	gear_hint.add_theme_font_size_override("font_size", 11)
	gear_hint.add_theme_color_override("font_color", MUTED)
	mid.add_child(gear_hint)

	var scroll := ScrollContainer.new()
	scroll.name = "GearScroll"
	scroll.position = Vector2(0, 106)
	scroll.size = Vector2(360, 480)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_ALWAYS
	mid.add_child(scroll)

	_inv_list = VBoxContainer.new()
	_inv_list.name = "GearList"
	_inv_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_inv_list.add_theme_constant_override("separation", 6)
	scroll.add_child(_inv_list)

	var right := Control.new()
	right.name = "Stats"
	right.position = Vector2(896, 64)
	right.size = Vector2(360, 620)
	sheet.add_child(right)

	var stats_title := Label.new()
	stats_title.name = "StatsTitle"
	stats_title.position = Vector2(0, 0)
	stats_title.size = Vector2(360, 22)
	stats_title.text = ContentStrings.get_text("char_sheet_stats_header")
	stats_title.add_theme_font_size_override("font_size", 15)
	stats_title.add_theme_color_override("font_color", GOLD)
	right.add_child(stats_title)

	var stats_hint := Label.new()
	stats_hint.position = Vector2(0, 22)
	stats_hint.size = Vector2(360, 20)
	stats_hint.text = ContentStrings.get_text("stat_persist_hint")
	stats_hint.add_theme_font_size_override("font_size", 11)
	stats_hint.add_theme_color_override("font_color", MUTED)
	right.add_child(stats_hint)

	## Name, role flush under it, a small gap, the numbers, then a larger gap.
	## The font line box is taller than the glyphs, so the role row overlaps the
	## name row's empty descent and each label is centered in its host.
	var y: float = STAT_TOP
	for stat_name: StringName in KeeperStats.STAT_ORDER:
		var sid: String = String(stat_name)
		var block := Control.new()
		block.name = "Stat_%s" % sid
		block.position = Vector2(0, y)
		block.size = Vector2(360, STAT_STRIDE)
		block.mouse_filter = Control.MOUSE_FILTER_IGNORE
		right.add_child(block)
		# Role overlaps the name row's empty descent so the words sit flush under the name.
		var role_y: float = STAT_NAME_H - 8.0
		var line_y: float = role_y + STAT_ROLE_H + STAT_GAP_SMALL
		_add_stat_row(block, "Name", KeeperStats.stat_display_name(sid), 14, KeeperStats.stat_color(sid), 0.0, STAT_NAME_H)
		_add_stat_row(block, "Role", KeeperStats.stat_role(sid), 11, MUTED, role_y, STAT_ROLE_H)
		_add_stat_row(block, "Line", "", 15, INK, line_y, STAT_NUM_H)
		y += STAT_STRIDE
	var stats_bottom: float = y - STAT_GAP_LARGE + 4.0
	var sheet_h: float = SHEET_SIZE.y
	if stats_bottom > right.size.y:
		var extra: float = stats_bottom - right.size.y
		right.size.y = stats_bottom
		sheet_h = minf(688.0, SHEET_SIZE.y + extra)
		sheet.custom_minimum_size = Vector2(SHEET_SIZE.x, sheet_h)
		sheet.offset_top = -sheet_h * 0.5
		sheet.offset_bottom = sheet_h * 0.5

	var fate_note := Label.new()
	fate_note.name = "FateNote"
	fate_note.visible = false
	fate_note.position = Vector2(0, y)
	fate_note.size = Vector2(360, 0)
	fate_note.text = ""
	fate_note.mouse_filter = Control.MOUSE_FILTER_IGNORE
	right.add_child(fate_note)

	_footer = Label.new()
	_footer.name = "Footer"
	_footer.position = Vector2(524, sheet_h - 32.0)
	_footer.size = Vector2(740, 24)
	_footer.add_theme_font_size_override("font_size", 12)
	_footer.add_theme_color_override("font_color", INK)
	sheet.add_child(_footer)


func _add_stat_row(block: Control, node_name: String, text: String, font_size: int, color: Color, y: float, row_h: float) -> void:
	var host := Control.new()
	host.name = node_name
	host.position = Vector2(0, y)
	host.size = Vector2(360, row_h)
	host.clip_contents = false
	host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	block.add_child(host)
	var lbl := Label.new()
	lbl.name = "Text"
	lbl.text = text
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl.add_theme_font_size_override("font_size", font_size)
	lbl.add_theme_color_override("font_color", color)
	host.add_child(lbl)
	_center_glyph_label(host, lbl)


func _center_stat_glyphs() -> void:
	var root: Node = get_node_or_null("Sheet/Stats")
	if root == null:
		return
	for stat_name: StringName in KeeperStats.STAT_ORDER:
		var block: Node = root.get_node_or_null("Stat_%s" % String(stat_name))
		if block == null:
			continue
		for row_name: String in ["Name", "Role", "Line"]:
			var host: Control = block.get_node_or_null(row_name) as Control
			if host == null:
				continue
			var lbl: Label = host.get_node_or_null("Text") as Label
			if lbl == null:
				continue
			_center_glyph_label(host, lbl)


func _center_glyph_label(host: Control, lbl: Label) -> void:
	var font: Font = lbl.get_theme_font("font")
	var font_size: int = lbl.get_theme_font_size("font_size")
	var need: float = host.size.y
	if font != null:
		need = float(font.get_height(font_size))
	need = minf(host.size.y, maxf(need, lbl.get_minimum_size().y))
	lbl.size = Vector2(host.size.x, need)
	lbl.position = Vector2(0, (host.size.y - need) * 0.5)


func _on_dim_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			request_close()


func _refresh() -> void:
	if not _built:
		return
	_refresh_slots()
	_refresh_inventory()
	_refresh_stats()


func _refresh_slots() -> void:
	var host: Control = get_node_or_null("Sheet/PortraitHost") as Control
	if host == null:
		return
	for slot_name: StringName in Equipment.SLOT_ORDER:
		var sid: String = String(slot_name)
		var plate: SlotPlate = host.get_node_or_null("Slot_%s" % sid) as SlotPlate
		if plate:
			plate.refresh()


func _set_gear_tab(tab_id: String) -> void:
	_gear_tab = tab_id
	_refresh_inventory()


func _refresh_inventory() -> void:
	if _inv_list == null:
		return
	for child: Node in _inv_list.get_children():
		_inv_list.remove_child(child)
		child.free()
	var rows: Array[Dictionary] = []
	for inst: Dictionary in Equipment.list_unequipped():
		var iid: String = str(inst.get("id", ""))
		if _gear_tab == "weapons" and Equipment.item_slot(iid) != "weapon":
			continue
		rows.append(inst)
	if rows.is_empty():
		var empty := Label.new()
		empty.name = "Empty"
		empty.text = ContentStrings.get_text("gear_empty")
		empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		empty.mouse_filter = Control.MOUSE_FILTER_IGNORE
		empty.custom_minimum_size = Vector2(320, 48)
		empty.add_theme_font_size_override("font_size", 12)
		empty.add_theme_color_override("font_color", MUTED)
		_inv_list.add_child(empty)
		return
	for inst: Dictionary in rows:
		var row := GearRow.new()
		row.host = self
		row.item_id = str(inst.get("id", ""))
		row.custom_minimum_size = Vector2(320, 48)
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.mouse_filter = Control.MOUSE_FILTER_STOP
		_inv_list.add_child(row)
		row.setup()


func _refresh_stats() -> void:
	var root: Node = get_node_or_null("Sheet/Stats")
	if root == null:
		return
	for stat_name: StringName in KeeperStats.STAT_ORDER:
		var sid: String = String(stat_name)
		var line: Label = root.get_node_or_null("Stat_%s/Line/Text" % sid) as Label
		if line == null:
			continue
		var base: int = KeeperStats.get_base(sid)
		var gear: int = Equipment.gear_bonus(sid)
		var shown_gear: int = gear
		if _hover_item_id != "":
			shown_gear = Equipment.preview_gear_bonus(sid, _hover_item_id)
		var total: int = base + shown_gear
		## base = STAT_BASE_START + ranks. Line is base + gear = total.
		var text: String = "%d + %d = %d" % [base, shown_gear, total]
		line.tooltip_text = ContentStrings.get_text("stat_base_note")
		if _hover_item_id != "" and shown_gear != gear:
			var delta: int = shown_gear - gear
			var sign: String = "+" if delta > 0 else ""
			text = "%s  (%s%d)" % [text, sign, delta]
		line.text = text


func _wood_style() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = WOOD
	sb.border_color = GOLD
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(2)
	return sb


func _paint_button(btn: Button, bg: Color) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = bg
	normal.border_color = GOLD
	normal.set_border_width_all(1)
	normal.set_corner_radius_all(3)
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = bg.lightened(0.08)
	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", normal)
	btn.add_theme_stylebox_override("focus", hover)
	btn.add_theme_color_override("font_color", INK)


class InvColumn extends Control:
	var host: Control = null

	func _can_drop_data(_at: Vector2, data: Variant) -> bool:
		if typeof(data) != TYPE_DICTIONARY:
			return false
		return str((data as Dictionary).get("from_slot", "")) != ""

	func _drop_data(_at: Vector2, data: Variant) -> void:
		if host == null or typeof(data) != TYPE_DICTIONARY:
			return
		host.call("request_unequip", str((data as Dictionary).get("from_slot", "")))


class SlotPlate extends Panel:
	var slot_id: String = ""
	var host: Control = null
	var _square: TextureRect
	var _caption: Label
	var _pressed: bool = false
	var _dragged: bool = false

	func setup() -> void:
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0, 0, 0, 0)
		sb.border_color = Color(0, 0, 0, 0)
		sb.set_border_width_all(0)
		sb.set_corner_radius_all(0)
		sb.shadow_size = 0
		add_theme_stylebox_override("panel", sb)
		_square = TextureRect.new()
		_square.name = "Square"
		_square.position = Vector2((SLOT_SIZE.x - SLOT_SQUARE.x) * 0.5, 0)
		_square.size = SLOT_SQUARE
		_square.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_square.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		_square.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		_square.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		add_child(_square)
		var caption_host := Control.new()
		caption_host.name = "CaptionHost"
		caption_host.position = Vector2(-14, SLOT_SQUARE.y + 2)
		caption_host.size = Vector2(SLOT_SIZE.x + 28, 16)
		caption_host.clip_contents = true
		caption_host.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(caption_host)
		_caption = Label.new()
		_caption.name = "Hint"
		_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_caption.add_theme_font_size_override("font_size", 10)
		_caption.add_theme_color_override("font_color", Color(0.86, 0.82, 0.70, 1.0))
		_caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
		caption_host.add_child(_caption)
		var cap_h: float = maxf(16.0, _caption.get_minimum_size().y)
		_caption.size = Vector2(caption_host.size.x, cap_h)
		_caption.position = Vector2(0, (caption_host.size.y - cap_h) * 0.5)
		refresh()

	func _show_slot_icon(index: int) -> void:
		HudIcons.apply(_square, index)
		_square.modulate = Color.WHITE
		_square.position = Vector2((SLOT_SIZE.x - SLOT_SQUARE.x) * 0.5, 0)
		_square.size = SLOT_SQUARE

	func _show_equipped_icon(item_id: String) -> void:
		var gear_index: int = HudIcons.index_for_item(item_id)
		if gear_index >= 0:
			_show_slot_icon(gear_index)
			return
		if item_id == "forge_key_relic" and ResourceLoader.exists("res://assets/art/ui/icons/icon_forge_key.png"):
			_square.texture = load("res://assets/art/ui/icons/icon_forge_key.png") as Texture2D
			_square.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			_square.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			_square.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			_square.modulate = Color.WHITE
			_square.position = Vector2((SLOT_SIZE.x - SLOT_SQUARE.x) * 0.5, 0)
			_square.size = SLOT_SQUARE
			return
		_show_slot_icon(HudIcons.EQUIP_EMPTY)
		_square.modulate = Equipment.item_color(item_id)

	func refresh() -> void:
		if _square == null:
			return
		var unlocked: bool = Equipment.is_slot_unlocked(slot_id)
		var iid: String = Equipment.equipped_id(slot_id)
		if not unlocked:
			_show_slot_icon(HudIcons.EQUIP_LOCKED)
			_caption.text = Equipment.slot_lock_short(slot_id)
			tooltip_text = Equipment.slot_lock_hint(slot_id)
			if slot_id == "relic":
				tooltip_text = "%s %s" % [tooltip_text, ContentStrings.get_text("relic_locked_tooltip")]
			return
		if iid == "":
			_show_slot_icon(HudIcons.EQUIP_EMPTY)
			if slot_id == "weapon":
				_caption.text = Equipment.slot_display_name(slot_id)
				tooltip_text = ContentStrings.get_text("equip_bare_stone_tooltip")
			else:
				_caption.text = ContentStrings.get_text("equip_empty")
				tooltip_text = ContentStrings.get_text("equip_empty")
		else:
			_show_equipped_icon(iid)
			_caption.text = Equipment.item_display_name(iid)
			tooltip_text = Equipment.item_tooltip(iid)

	func _gui_input(event: InputEvent) -> void:
		if not (event is InputEventMouseButton):
			return
		var mb: InputEventMouseButton = event
		if mb.button_index != MOUSE_BUTTON_LEFT:
			return
		if mb.pressed:
			_pressed = true
			return
		if not _pressed:
			return
		_pressed = false
		if _dragged:
			_dragged = false
			return
		if host == null:
			return
		if not Equipment.is_slot_unlocked(slot_id):
			var hint: String = Equipment.slot_lock_hint(slot_id)
			GameAudio.play_tree_deny()
			GameState.status_message.emit(hint)
			var footer: Label = host.get_node_or_null("Sheet/Footer") as Label
			if footer:
				footer.text = hint
			return
		var iid: String = Equipment.equipped_id(slot_id)
		if iid != "":
			host.call("request_unequip", slot_id)

	func _get_drag_data(_at: Vector2) -> Variant:
		var iid: String = Equipment.equipped_id(slot_id)
		if iid == "" or not Equipment.is_slot_unlocked(slot_id):
			return null
		_dragged = true
		set_drag_preview(CharacterSheet.make_item_icon(iid))
		return {"kind": "gear", "item_id": iid, "from_slot": slot_id}

	func _can_drop_data(_at: Vector2, data: Variant) -> bool:
		if typeof(data) != TYPE_DICTIONARY:
			return false
		if not Equipment.is_slot_unlocked(slot_id):
			return false
		var d: Dictionary = data
		if str(d.get("kind", "")) != "gear":
			return false
		var iid: String = str(d.get("item_id", ""))
		if str(d.get("from_slot", "")) == slot_id:
			return false
		return Equipment.item_fits_slot(iid, slot_id)

	func _drop_data(_at: Vector2, data: Variant) -> void:
		if typeof(data) != TYPE_DICTIONARY or host == null:
			return
		var d: Dictionary = data
		var iid: String = str(d.get("item_id", ""))
		var from_slot: String = str(d.get("from_slot", ""))
		if from_slot != "":
			host.call("request_unequip", from_slot)
		host.call("request_equip_slot", iid, slot_id)


class GearRow extends Panel:
	var item_id: String = ""
	var host: Control = null
	var _pressed: bool = false
	var _dragged: bool = false

	func setup() -> void:
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.20, 0.14, 0.09, 1.0)
		sb.border_color = Color(0.45, 0.34, 0.18, 1.0)
		sb.set_border_width_all(1)
		sb.set_corner_radius_all(2)
		sb.content_margin_left = 4.0
		sb.content_margin_right = 4.0
		sb.content_margin_top = 4.0
		sb.content_margin_bottom = 4.0
		add_theme_stylebox_override("panel", sb)
		var row := HBoxContainer.new()
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_theme_constant_override("separation", 8)
		add_child(row)
		var icon: Control = CharacterSheet.make_item_icon(item_id)
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(icon)
		var lbl := Label.new()
		var count: int = Equipment.unequipped_count(item_id)
		var name: String = Equipment.item_display_name(item_id)
		lbl.text = name if count <= 1 else "%s  ×%d" % [name, count]
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl.add_theme_font_size_override("font_size", 13)
		lbl.add_theme_color_override("font_color", Color(0.92, 0.86, 0.72, 1.0))
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(lbl)
		tooltip_text = "%s\n%s" % [Equipment.item_tooltip(item_id), ContentStrings.get_text("equip_equip")]

	func _gui_input(event: InputEvent) -> void:
		if event is InputEventMouseMotion and host != null:
			host.call("set_hover_item", item_id)
		if not (event is InputEventMouseButton):
			return
		var mb: InputEventMouseButton = event
		if mb.button_index != MOUSE_BUTTON_LEFT:
			return
		if mb.pressed:
			_pressed = true
			return
		if not _pressed:
			return
		_pressed = false
		if _dragged:
			_dragged = false
			return
		if host:
			host.call("request_equip", item_id)

	func _notification(what: int) -> void:
		if what == NOTIFICATION_MOUSE_EXIT and host != null:
			host.call("set_hover_item", "")

	func _get_drag_data(_at: Vector2) -> Variant:
		if item_id == "":
			return null
		_dragged = true
		set_drag_preview(CharacterSheet.make_item_icon(item_id))
		return {"kind": "gear", "item_id": item_id, "from_slot": ""}

	func _can_drop_data(_at: Vector2, data: Variant) -> bool:
		if typeof(data) != TYPE_DICTIONARY:
			return false
		return str((data as Dictionary).get("from_slot", "")) != ""

	func _drop_data(_at: Vector2, data: Variant) -> void:
		if host == null or typeof(data) != TYPE_DICTIONARY:
			return
		host.call("request_unequip", str((data as Dictionary).get("from_slot", "")))
