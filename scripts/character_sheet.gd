extends Control
class_name CharacterSheet
## Paper-doll character sheet. Portrait left, battle gear middle, stats right.
## Equip by click or drag. Locked slots stay grey until a later forge unlock.

signal close_requested

const PORTRAIT_PATH: String = "res://assets/art/keeper/keeper_idle_south_0000.png"
const WISP_PORTRAIT_PATH: String = "res://assets/art/wisps/wisp_portrait.png"
## HUD party slots. 52×52, drawn 1:1. companions.json points at these.
const KEEPER_PARTY_PORTRAIT_PATH: String = "res://assets/art/portraits/keeper_portrait.png"
const ELAIA_PARTY_PORTRAIT_PATH: String = "res://assets/art/portraits/elaia_portrait.png"
## 160×160 busts. Header icon only. The sheet figure stays the idle-south frame.
const KEEPER_SHEET_PORTRAIT_PATH: String = "res://assets/art/portraits/keeper_portrait_sheet.png"
const ELAIA_SHEET_PORTRAIT_PATH: String = "res://assets/art/portraits/elaia_portrait_sheet.png"
const SHEET_SIZE: Vector2 = Vector2(1272, 716)
const HOST_POS: Vector2 = Vector2(12, 54)
## Paper-doll host. The sprite is inset; slots sit in the margins around the figure.
const PORTRAIT_SIZE: Vector2 = Vector2(496, 622)
## Prior fitted portrait was 160×160 (128² kept inside a 160×284 rect). This is 3×.
const SPRITE_SIZE: Vector2 = Vector2(480, 480)
const SPRITE_POS: Vector2 = Vector2(8, 70)
const PLACEHOLDER_SWATCH: Color = Color(0.42, 0.40, 0.36, 1.0)


## Autoload name is not in scope when this script reloads under a --script run.
static func _auto(node_name: String):
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	return tree.root.get_node_or_null(node_name)


static func gear_icon_path(item_id: String) -> String:
	var eq = CharacterSheet._auto("Equipment")
	if eq == null:
		return ""
	return str(eq.call("item_art_path", item_id))


static func make_item_icon(item_id: String) -> Control:
	var eq = CharacterSheet._auto("Equipment")
	var tip: String = str(eq.call("item_display_name", item_id)) if eq != null else item_id
	var sheet_index: int = HudIcons.index_for_item(item_id)
	if sheet_index >= 0:
		var sheet_icon: TextureRect = HudIcons.make_icon(sheet_index)
		sheet_icon.tooltip_text = tip
		return sheet_icon
	var path: String = gear_icon_path(item_id)
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
## Below the persist hint and the trait line, so Might does not sit on the hint.
const STAT_TOP: float = 76.0
const STAT_NAME_H: float = 22.0
const STAT_ROLE_H: float = 18.0
const STAT_GAP_SMALL: float = 4.0
const STAT_NUM_H: float = 24.0
const STAT_GAP_LARGE: float = 10.0
const STAT_STRIDE: float = STAT_NAME_H + STAT_ROLE_H + STAT_GAP_SMALL + STAT_NUM_H + STAT_GAP_LARGE
const ELAIA_SHEET_FIGURE: String = "res://assets/art/elaia/anim/idle/south.png"
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
var _actor_id: String = "keeper"


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
	if not CharacterSheet._auto("Equipment").equipment_changed.is_connected(_refresh):
		CharacterSheet._auto("Equipment").equipment_changed.connect(_refresh)
	if not CharacterSheet._auto("KeeperStats").ranks_changed.is_connected(_on_ranks):
		CharacterSheet._auto("KeeperStats").ranks_changed.connect(_on_ranks)
	_refresh()


func _on_ranks(_stat_id: StringName) -> void:
	if visible:
		_refresh_stats()


func is_open() -> bool:
	return visible


func open_sheet(actor_id: String = "keeper") -> void:
	visible = true
	_hover_item_id = ""
	show_actor(actor_id if actor_id != "" else "keeper")


func sheet_actor() -> String:
	return _actor_id


func show_actor(actor_id: String) -> void:
	## Clicking the other party portrait switches this sheet. Gear follows the open sheet.
	if actor_id == "elaia" and not CharacterSheet._auto("GameState").call("elaia_in_party"):
		actor_id = "keeper"
	_actor_id = actor_id if actor_id == "elaia" else "keeper"
	_apply_actor_chrome()
	_refresh()
	_fit_sheet()


func close_sheet() -> void:
	close_trait_popup()
	visible = false
	_hover_item_id = ""


func request_close() -> void:
	close_requested.emit()


func request_equip(item_id: String) -> String:
	var result: String = CharacterSheet._auto("Equipment").try_equip(item_id, _actor_id)
	_toast(result, item_id, CharacterSheet._auto("Equipment").item_slot(item_id))
	return result


func request_equip_slot(item_id: String, slot_id: String) -> String:
	var result: String = CharacterSheet._auto("Equipment").try_equip_to_slot(item_id, slot_id, _actor_id)
	_toast(result, item_id, slot_id)
	return result


func request_unequip(slot_id: String) -> String:
	var item_id: String = CharacterSheet._auto("Equipment").equipped_id_for(_actor_id, slot_id)
	var result: String = CharacterSheet._auto("Equipment").try_unequip(slot_id, _actor_id)
	_toast(result, item_id, slot_id)
	return result


func set_hover_item(item_id: String) -> void:
	if _hover_item_id == item_id:
		return
	_hover_item_id = item_id
	_refresh_stats()


func _toast(result: String, item_id: String, slot_id: String) -> void:
	var item_name: String = CharacterSheet._auto("Equipment").item_display_name(item_id) if item_id != "" else ""
	var text: String = ""
	match result:
		"ok":
			if CharacterSheet._auto("Equipment").equipped_id_for(_actor_id, slot_id) == item_id and item_id != "":
				text = CharacterSheet._auto("ContentStrings").get_text("equip_ok", {"item": item_name})
			else:
				text = CharacterSheet._auto("ContentStrings").get_text("equip_unequip_ok", {"item": item_name})
			CharacterSheet._auto("GameAudio").play_ui_confirm()
			CharacterSheet._auto("SaveService").save_game()
		"locked":
			text = CharacterSheet._auto("Equipment").slot_lock_hint(slot_id if slot_id != "" else CharacterSheet._auto("Equipment").item_slot(item_id))
			CharacterSheet._auto("GameAudio").play_tree_deny()
		"wrong_slot":
			text = ""
			CharacterSheet._auto("GameAudio").play_tree_deny()
		"missing":
			text = CharacterSheet._auto("ContentStrings").get_text("equip_no_item")
			CharacterSheet._auto("GameAudio").play_tree_deny()
		"empty":
			text = ""
		_:
			text = ""
	if text != "":
		if _footer:
			_footer.text = text
		CharacterSheet._auto("GameState").status_message.emit(text)


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

	## Gutter for the party column. Anchors track every window size; the paper doll scales inside.
	var fit := Control.new()
	fit.name = "SheetFit"
	fit.set_anchors_preset(Control.PRESET_FULL_RECT)
	fit.offset_left = 88.0
	fit.offset_top = 8.0
	fit.offset_right = -12.0
	fit.offset_bottom = -12.0
	fit.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fit)
	fit.resized.connect(_fit_sheet)

	var sheet := Panel.new()
	sheet.name = "Sheet"
	sheet.custom_minimum_size = SHEET_SIZE
	sheet.size = SHEET_SIZE
	sheet.mouse_filter = Control.MOUSE_FILTER_STOP
	sheet.add_theme_stylebox_override("panel", _wood_style())
	fit.add_child(sheet)

	var header_icon := TextureRect.new()
	header_icon.name = "HeaderPortrait"
	header_icon.position = Vector2(16, 4)
	header_icon.size = Vector2(32, 32)
	header_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	header_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	header_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	header_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header_icon.texture = load(KEEPER_SHEET_PORTRAIT_PATH) as Texture2D
	sheet.add_child(header_icon)

	var title := Label.new()
	title.name = "Title"
	title.position = Vector2(54, 8)
	title.size = Vector2(600, 26)
	title.text = CharacterSheet._auto("ContentStrings").get_text("char_sheet_title")
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", GOLD)
	sheet.add_child(title)

	var hint := Label.new()
	hint.name = "Hint"
	hint.position = Vector2(54, 32)
	hint.size = Vector2(660, 22)
	hint.text = CharacterSheet._auto("ContentStrings").get_text("char_sheet_hint")
	var hotkey := Label.new()
	hotkey.name = "HotkeyHint"
	hotkey.position = Vector2(SHEET_SIZE.x - 250, 34)
	hotkey.size = Vector2(120, 18)
	hotkey.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hotkey.text = CharacterSheet._auto("ContentStrings").get_text("char_sheet_hotkey_hint")
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
	close.text = CharacterSheet._auto("ContentStrings").get_text("char_sheet_close")
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

	for slot_name: StringName in CharacterSheet._auto("Equipment").SLOT_ORDER:
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
			var anchor: Vector2 = CharacterSheet._auto("Equipment").slot_anchor(sid)
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
	gear_title.text = CharacterSheet._auto("ContentStrings").get_text("gear_title")
	gear_title.add_theme_font_size_override("font_size", 15)
	gear_title.add_theme_color_override("font_color", GOLD)
	mid.add_child(gear_title)

	var gear_hint := Label.new()
	gear_hint.position = Vector2(0, 22)
	gear_hint.size = Vector2(360, 30)
	gear_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	gear_hint.text = CharacterSheet._auto("ContentStrings").get_text("gear_hint")
	var persist := Label.new()
	persist.name = "PersistHint"
	persist.position = Vector2(0, 54)
	persist.size = Vector2(360, 16)
	persist.text = CharacterSheet._auto("ContentStrings").get_text("weapon_persist_hint")
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
	tab_all.text = CharacterSheet._auto("ContentStrings").get_text("gear_tab_all")
	tab_all.custom_minimum_size = Vector2(72, 26)
	tab_all.pressed.connect(_set_gear_tab.bind("all"))
	_paint_button(tab_all, Color(0.18, 0.14, 0.10, 1.0))
	tabs.add_child(tab_all)
	var tab_weapons := Button.new()
	tab_weapons.name = "TabWeapons"
	tab_weapons.text = CharacterSheet._auto("ContentStrings").get_text("gear_tab_weapons")
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
	stats_title.text = CharacterSheet._auto("ContentStrings").get_text("char_sheet_stats_header")
	stats_title.add_theme_font_size_override("font_size", 15)
	stats_title.add_theme_color_override("font_color", GOLD)
	right.add_child(stats_title)

	var stats_hint := Label.new()
	stats_hint.name = "PersistHint"
	stats_hint.position = Vector2(0, 22)
	stats_hint.size = Vector2(360, 20)
	stats_hint.clip_text = false
	stats_hint.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	stats_hint.text = CharacterSheet._auto("ContentStrings").get_text("stat_persist_hint")
	stats_hint.add_theme_font_size_override("font_size", 11)
	stats_hint.add_theme_color_override("font_color", MUTED)
	right.add_child(stats_hint)

	var trait_row := Control.new()
	trait_row.name = "TraitRow"
	trait_row.position = Vector2(0, 44)
	trait_row.size = Vector2(360, 28)
	trait_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	right.add_child(trait_row)
	var trait_label := Label.new()
	trait_label.name = "TraitLabel"
	trait_label.position = Vector2(0, 4)
	trait_label.size = Vector2(52, 20)
	trait_label.clip_text = false
	trait_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	trait_label.text = CharacterSheet._auto("ContentStrings").get_text("char_sheet_trait_label")
	trait_label.add_theme_font_size_override("font_size", 12)
	trait_label.add_theme_color_override("font_color", MUTED)
	trait_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	trait_row.add_child(trait_label)
	var trait_btn := Button.new()
	trait_btn.name = "TraitButton"
	trait_btn.position = Vector2(52, 0)
	trait_btn.size = Vector2(304, 28)
	trait_btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	trait_btn.clip_text = false
	trait_btn.text = CharacterSheet._auto("ContentStrings").get_text("char_sheet_keeper_trait")
	trait_btn.add_theme_font_size_override("font_size", 13)
	_paint_trait_button(trait_btn)
	trait_btn.mouse_entered.connect(open_trait_popup)
	trait_btn.mouse_exited.connect(close_trait_popup)
	trait_row.add_child(trait_btn)

	## Name, role flush under it, a small gap, the numbers, then a larger gap.
	## The font line box is taller than the glyphs, so the role row overlaps the
	## name row's empty descent and each label is centered in its host.
	var y: float = STAT_TOP
	for stat_name: StringName in CharacterSheet._auto("KeeperStats").STAT_ORDER:
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
		_add_stat_row(block, "Name", CharacterSheet._auto("KeeperStats").stat_display_name(sid), 14, CharacterSheet._auto("KeeperStats").stat_color(sid), 0.0, STAT_NAME_H)
		_add_stat_row(block, "Role", CharacterSheet._auto("KeeperStats").stat_role(sid), 11, MUTED, role_y, STAT_ROLE_H)
		_add_stat_row(block, "Line", "", 15, INK, line_y, STAT_NUM_H)
		y += STAT_STRIDE
	var stats_bottom: float = y - STAT_GAP_LARGE + 4.0
	var sheet_h: float = SHEET_SIZE.y
	if stats_bottom > right.size.y:
		var extra: float = stats_bottom - right.size.y
		right.size.y = stats_bottom
		sheet_h = minf(688.0, SHEET_SIZE.y + extra)
		sheet.custom_minimum_size = Vector2(SHEET_SIZE.x, sheet_h)
		sheet.size = sheet.custom_minimum_size

	var fate_note := Label.new()
	fate_note.name = "FateNote"
	fate_note.visible = false
	fate_note.position = Vector2(0, y)
	fate_note.size = Vector2(360, 0)
	fate_note.text = ""
	fate_note.mouse_filter = Control.MOUSE_FILTER_IGNORE
	right.add_child(fate_note)

	_build_trait_popup()
	_footer = Label.new()
	_footer.name = "Footer"
	_footer.position = Vector2(524, sheet_h - 32.0)
	_footer.size = Vector2(740, 24)
	_footer.add_theme_font_size_override("font_size", 12)
	_footer.add_theme_color_override("font_color", INK)
	sheet.add_child(_footer)
	call_deferred("_fit_sheet")


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
	var root: Node = get_node_or_null("SheetFit/Sheet/Stats")
	if root == null:
		return
	for stat_name: StringName in CharacterSheet._auto("KeeperStats").STAT_ORDER:
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


func _fit_sheet() -> void:
	var fit: Control = get_node_or_null("SheetFit") as Control
	var sheet: Control = get_node_or_null("SheetFit/Sheet") as Control
	if fit == null or sheet == null:
		return
	var avail: Vector2 = fit.size
	if avail.x < 32.0 or avail.y < 32.0:
		return
	var design: Vector2 = sheet.custom_minimum_size
	if design.x < 1.0 or design.y < 1.0:
		design = SHEET_SIZE
	var sc: float = minf(1.0, minf(avail.x / design.x, avail.y / design.y))
	sheet.scale = Vector2(sc, sc)
	sheet.pivot_offset = Vector2.ZERO
	var drawn: Vector2 = design * sc
	sheet.position = (avail - drawn) * 0.5
	sheet.size = design


func _apply_actor_chrome() -> void:
	var sheet: Node = get_node_or_null("SheetFit/Sheet")
	if sheet == null:
		return
	var elaia: bool = _actor_id == "elaia"
	var strings = CharacterSheet._auto("ContentStrings")
	var title: Label = sheet.get_node_or_null("Title") as Label
	if title:
		title.text = strings.get_text("char_sheet_elaia_title") if elaia else strings.get_text("char_sheet_title")
	var hint: Label = sheet.get_node_or_null("Hint") as Label
	if hint:
		hint.text = strings.get_text("char_sheet_elaia_role") if elaia else strings.get_text("char_sheet_hint")
		hint.visible = true
	var host: Node = sheet.get_node_or_null("PortraitHost")
	if host:
		for child: Node in host.get_children():
			if str(child.name).begins_with("Slot_"):
				child.visible = true
	var gear: CanvasItem = sheet.get_node_or_null("GearColumn") as CanvasItem
	if gear:
		gear.visible = true
	var stats: CanvasItem = sheet.get_node_or_null("Stats") as CanvasItem
	if stats:
		stats.visible = true
	if _portrait:
		var figure_path: String = _sheet_figure_path()
		_portrait.texture = load(figure_path) as Texture2D
		_portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		_portrait.position = SPRITE_POS
		_portrait.size = SPRITE_SIZE
	var header_icon: TextureRect = sheet.get_node_or_null("HeaderPortrait") as TextureRect
	if header_icon:
		var bust_path: String = ELAIA_SHEET_PORTRAIT_PATH if elaia else KEEPER_SHEET_PORTRAIT_PATH
		header_icon.texture = load(bust_path) as Texture2D
		header_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var trait_btn: Button = sheet.get_node_or_null("Stats/TraitRow/TraitButton") as Button
	if trait_btn:
		var trait_key: String = "char_sheet_elaia_trait" if elaia else "char_sheet_keeper_trait"
		trait_btn.text = strings.get_text(trait_key)


func _sheet_figure_path() -> String:
	return ELAIA_SHEET_FIGURE if _actor_id == "elaia" else PORTRAIT_PATH


func open_trait_popup() -> void:
	var pop: Control = get_node_or_null("TraitPopup") as Control
	if pop == null:
		return
	_fill_trait_popup()
	_place_trait_popup()
	pop.visible = true


func close_trait_popup() -> void:
	var pop: CanvasItem = get_node_or_null("TraitPopup") as CanvasItem
	if pop:
		pop.visible = false


func _trait_sentence() -> String:
	var key: String = "char_sheet_elaia_trait" if _actor_id == "elaia" else "char_sheet_keeper_trait"
	return CharacterSheet._auto("ContentStrings").get_text(key)


func _build_trait_popup() -> void:
	var pop := ColorRect.new()
	pop.name = "TraitPopup"
	pop.visible = false
	pop.z_index = 40
	pop.set_anchors_preset(Control.PRESET_FULL_RECT)
	pop.color = Color(0, 0, 0, 0)
	pop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pop.gui_input.connect(_on_trait_dim_input)
	add_child(pop)
	var panel := Panel.new()
	panel.name = "Panel"
	panel.size = Vector2(520, 280)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", _wood_style())
	pop.add_child(panel)
	var title := Label.new()
	title.name = "Title"
	title.position = Vector2(20, 16)
	title.size = Vector2(400, 28)
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", GOLD)
	panel.add_child(title)
	var sub := Label.new()
	sub.name = "Subtitle"
	sub.position = Vector2(20, 48)
	sub.size = Vector2(480, 28)
	sub.clip_text = false
	sub.add_theme_font_size_override("font_size", 14)
	sub.add_theme_color_override("font_color", INK)
	panel.add_child(sub)
	var y: float = 92.0
	for row_name: String in ["Work", "Reliquary", "Water", "Pace"]:
		var row := Control.new()
		row.name = "Row%s" % row_name
		row.position = Vector2(20, y)
		row.size = Vector2(480, 32)
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.add_child(row)
		var name_lbl := Label.new()
		name_lbl.name = "Name"
		name_lbl.position = Vector2(0, 0)
		name_lbl.size = Vector2(280, 32)
		name_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		name_lbl.add_theme_font_size_override("font_size", 15)
		name_lbl.add_theme_color_override("font_color", INK)
		row.add_child(name_lbl)
		var value_lbl := Label.new()
		value_lbl.name = "Value"
		value_lbl.position = Vector2(280, 0)
		value_lbl.size = Vector2(180, 32)
		value_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		value_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		value_lbl.add_theme_font_size_override("font_size", 15)
		value_lbl.add_theme_color_override("font_color", GOLD)
		row.add_child(value_lbl)
		y += 36.0
	var close := Button.new()
	close.name = "CloseButton"
	close.position = Vector2(400, 232)
	close.size = Vector2(96, 32)
	close.text = CharacterSheet._auto("ContentStrings").get_text("char_sheet_close")
	close.visible = false
	close.pressed.connect(close_trait_popup)
	_paint_button(close, Color(0.18, 0.14, 0.10, 1.0))
	panel.add_child(close)


func _fill_trait_popup() -> void:
	var panel: Node = get_node_or_null("TraitPopup/Panel")
	if panel == null:
		return
	var strings = CharacterSheet._auto("ContentStrings")
	var gs = CharacterSheet._auto("GameState")
	var title: Label = panel.get_node_or_null("Title") as Label
	var sub: Label = panel.get_node_or_null("Subtitle") as Label
	if title:
		title.text = strings.get_text("char_sheet_trait_popup_title")
	if sub:
		sub.text = _trait_sentence()
	var work: float = float(gs.call("actor_work_rate", _actor_id, ""))
	var relic: float = float(gs.call("actor_work_rate", _actor_id, "reliquary"))
	var water: float = float(gs.call("actor_water_mult", _actor_id))
	var pace: float = float(gs.call("actor_move_mult", _actor_id))
	_set_trait_row(panel, "Work", "char_sheet_trait_work", work)
	_set_trait_row(panel, "Reliquary", "char_sheet_trait_reliquary", relic)
	_set_trait_row(panel, "Water", "char_sheet_trait_water", water)
	_set_trait_row(panel, "Pace", "char_sheet_trait_move", pace)


func _set_trait_row(panel: Node, row_name: String, key: String, value: float) -> void:
	var name_lbl: Label = panel.get_node_or_null("Row%s/Name" % row_name) as Label
	var value_lbl: Label = panel.get_node_or_null("Row%s/Value" % row_name) as Label
	if name_lbl:
		name_lbl.text = CharacterSheet._auto("ContentStrings").get_text(key)
	if value_lbl:
		value_lbl.text = String.num(value, 1) + "×"


func _place_trait_popup() -> void:
	var panel: Control = get_node_or_null("TraitPopup/Panel") as Control
	if panel == null:
		return
	var panel_size := Vector2(360, 220)
	panel.size = panel_size
	var btn: Control = find_child("TraitButton", true, false) as Control
	var origin := Vector2(16, 16)
	if btn:
		origin = btn.global_position - global_position + Vector2(0, btn.size.y + 6)
	panel.position = Vector2(clampf(origin.x, 8.0, maxf(8.0, size.x - panel_size.x - 8.0)), clampf(origin.y, 8.0, maxf(8.0, size.y - panel_size.y - 8.0)))


func _on_trait_dim_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			var panel: Control = get_node_or_null("TraitPopup/Panel") as Control
			if panel and panel.get_global_rect().has_point(mb.global_position):
				return
			close_trait_popup()


func _paint_trait_button(btn: Button) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0, 0, 0, 0)
	normal.set_content_margin_all(2.0)
	var hover := StyleBoxFlat.new()
	hover.bg_color = Color(0.82, 0.64, 0.28, 0.18)
	hover.set_content_margin_all(2.0)
	hover.set_corner_radius_all(3)
	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", hover)
	btn.add_theme_stylebox_override("focus", hover)
	btn.add_theme_color_override("font_color", INK)
	btn.add_theme_color_override("font_hover_color", GOLD)


func _on_dim_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			request_close()


func _refresh() -> void:
	if not _built:
		return
	_apply_actor_chrome()
	_refresh_slots()
	_refresh_inventory()
	_refresh_stats()
	var pop: CanvasItem = get_node_or_null("TraitPopup") as CanvasItem
	if pop and pop.visible:
		_fill_trait_popup()


func _refresh_slots() -> void:
	var host: Control = get_node_or_null("SheetFit/Sheet/PortraitHost") as Control
	if host == null:
		return
	for slot_name: StringName in CharacterSheet._auto("Equipment").SLOT_ORDER:
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
	for inst: Dictionary in CharacterSheet._auto("Equipment").list_for_sheet(_actor_id):
		var iid: String = str(inst.get("id", ""))
		if _gear_tab == "weapons" and CharacterSheet._auto("Equipment").item_slot(iid) != "weapon":
			continue
		rows.append(inst)
	if rows.is_empty():
		var empty := Label.new()
		empty.name = "Empty"
		empty.text = CharacterSheet._auto("ContentStrings").get_text("gear_empty")
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
		row.shown_count = int(inst.get("count", 1))
		row.custom_minimum_size = Vector2(320, 48)
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.mouse_filter = Control.MOUSE_FILTER_STOP
		_inv_list.add_child(row)
		row.setup()


func _refresh_stats() -> void:
	var root: Node = get_node_or_null("SheetFit/Sheet/Stats")
	if root == null:
		return
	for stat_name: StringName in CharacterSheet._auto("KeeperStats").STAT_ORDER:
		var sid: String = String(stat_name)
		var line: Label = root.get_node_or_null("Stat_%s/Line/Text" % sid) as Label
		if line == null:
			continue
		var base: int = CharacterSheet._auto("KeeperStats").get_base_for(_actor_id, sid)
		var gear: int = CharacterSheet._auto("Equipment").gear_bonus_for(_actor_id, sid)
		var shown_gear: int = gear
		if _hover_item_id != "":
			shown_gear = CharacterSheet._auto("Equipment").preview_gear_bonus_for(_actor_id, sid, _hover_item_id)
		var total: int = base + shown_gear
		## base = STAT_BASE_START + ranks. Line is base + gear = total.
		var text: String = "%d + %d = %d" % [base, shown_gear, total]
		if _actor_id == "elaia":
			line.tooltip_text = ""
		else:
			line.tooltip_text = CharacterSheet._auto("ContentStrings").get_text("stat_base_note")
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


const EMPTY_RELIC_FRAME_PATH: String = "res://assets/art/ui/relic_slot_empty.png"
const RELIC_ICON_SIZE: Vector2 = Vector2(32, 32)
const RELIC_ICON_INSET: Vector2 = Vector2(6, 6)

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
		if slot_id == "relic":
			var glyph := TextureRect.new()
			glyph.name = "RelicGlyph"
			glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
			glyph.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			glyph.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			glyph.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			glyph.position = CharacterSheet.RELIC_ICON_INSET
			glyph.size = CharacterSheet.RELIC_ICON_SIZE
			glyph.visible = false
			_square.add_child(glyph)
		refresh()

	func _apply_empty_relic_frame() -> bool:
		var tex: Texture2D = null
		if ResourceLoader.exists(CharacterSheet.EMPTY_RELIC_FRAME_PATH):
			tex = load(CharacterSheet.EMPTY_RELIC_FRAME_PATH) as Texture2D
		if tex == null:
			return false
		_square.texture = tex
		_square.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		_square.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		_square.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		_square.modulate = Color.WHITE
		_square.position = Vector2((SLOT_SIZE.x - SLOT_SQUARE.x) * 0.5, 0)
		_square.size = SLOT_SQUARE
		return true


	func _show_slot_icon(index: int) -> void:
		HudIcons.apply(_square, index)
		_square.modulate = Color.WHITE
		_square.position = Vector2((SLOT_SIZE.x - SLOT_SQUARE.x) * 0.5, 0)
		_square.size = SLOT_SQUARE

	func _relic_glyph() -> TextureRect:
		if _square == null:
			return null
		return _square.get_node_or_null("RelicGlyph") as TextureRect


	func _hide_relic_glyph() -> void:
		var glyph: TextureRect = _relic_glyph()
		if glyph:
			glyph.visible = false
			glyph.texture = null


	func _show_relic_in_frame(item_id: String) -> bool:
		if not _apply_empty_relic_frame():
			return false
		var glyph: TextureRect = _relic_glyph()
		if glyph == null:
			return false
		var path: String = CharacterSheet.gear_icon_path(item_id)
		var tex: Texture2D = null
		if path != "" and ResourceLoader.exists(path):
			tex = load(path) as Texture2D
		if tex == null:
			_hide_relic_glyph()
			return false
		glyph.texture = tex
		glyph.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		glyph.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		glyph.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		glyph.position = CharacterSheet.RELIC_ICON_INSET
		glyph.size = CharacterSheet.RELIC_ICON_SIZE
		glyph.visible = true
		return true


	func _show_equipped_icon(item_id: String) -> void:
		var gear_index: int = HudIcons.index_for_item(item_id)
		if gear_index >= 0:
			_show_slot_icon(gear_index)
			return
		var path: String = CharacterSheet.gear_icon_path(item_id)
		if path != "" and ResourceLoader.exists(path):
			_square.texture = load(path) as Texture2D
			_square.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			_square.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			_square.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			_square.modulate = Color.WHITE
			_square.position = Vector2((SLOT_SIZE.x - SLOT_SQUARE.x) * 0.5, 0)
			_square.size = SLOT_SQUARE
			return
		_show_slot_icon(HudIcons.EQUIP_EMPTY)
		_square.modulate = CharacterSheet._auto("Equipment").item_color(item_id)

	func refresh() -> void:
		if _square == null:
			return
		var unlocked: bool = CharacterSheet._auto("Equipment").is_slot_unlocked(slot_id)
		var iid: String = CharacterSheet._auto("Equipment").equipped_id_for(_actor(), slot_id)
		if not unlocked:
			_hide_relic_glyph()
			_show_slot_icon(HudIcons.EQUIP_LOCKED)
			_caption.text = CharacterSheet._auto("Equipment").slot_lock_short(slot_id)
			tooltip_text = CharacterSheet._auto("Equipment").slot_lock_hint(slot_id)
			if slot_id == "relic":
				tooltip_text = "%s %s" % [tooltip_text, CharacterSheet._auto("ContentStrings").get_text("relic_locked_tooltip")]
			return
		if iid == "":
			_hide_relic_glyph()
			if slot_id == "relic" and _apply_empty_relic_frame():
				_caption.text = CharacterSheet._auto("ContentStrings").get_text("equip_empty")
				tooltip_text = CharacterSheet._auto("ContentStrings").get_text("equip_empty")
				return
			_show_slot_icon(HudIcons.EQUIP_EMPTY)
			if slot_id == "weapon":
				_caption.text = CharacterSheet._auto("Equipment").slot_display_name(slot_id)
				tooltip_text = CharacterSheet._auto("ContentStrings").get_text("equip_bare_stone_tooltip")
			else:
				_caption.text = CharacterSheet._auto("ContentStrings").get_text("equip_empty")
				tooltip_text = CharacterSheet._auto("ContentStrings").get_text("equip_empty")
		else:
			if slot_id == "relic" and _show_relic_in_frame(iid):
				_caption.text = CharacterSheet._auto("Equipment").item_display_name(iid)
				tooltip_text = CharacterSheet._auto("Equipment").item_tooltip(iid)
				return
			_hide_relic_glyph()
			_show_equipped_icon(iid)
			_caption.text = CharacterSheet._auto("Equipment").item_display_name(iid)
			tooltip_text = CharacterSheet._auto("Equipment").item_tooltip(iid)

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
		if not CharacterSheet._auto("Equipment").is_slot_unlocked(slot_id):
			var hint: String = CharacterSheet._auto("Equipment").slot_lock_hint(slot_id)
			CharacterSheet._auto("GameAudio").play_tree_deny()
			CharacterSheet._auto("GameState").status_message.emit(hint)
			var footer: Label = host.get_node_or_null("SheetFit/Sheet/Footer") as Label
			if footer:
				footer.text = hint
			return
		var iid: String = CharacterSheet._auto("Equipment").equipped_id_for(_actor(), slot_id)
		if iid != "":
			host.call("request_unequip", slot_id)

	func _actor() -> String:
		if host != null and host.has_method("sheet_actor"):
			return str(host.call("sheet_actor"))
		return "keeper"

	func _get_drag_data(_at: Vector2) -> Variant:
		var iid: String = CharacterSheet._auto("Equipment").equipped_id_for(_actor(), slot_id)
		if iid == "" or not CharacterSheet._auto("Equipment").is_slot_unlocked(slot_id):
			return null
		_dragged = true
		set_drag_preview(CharacterSheet.make_item_icon(iid))
		return {"kind": "gear", "item_id": iid, "from_slot": slot_id}

	func _can_drop_data(_at: Vector2, data: Variant) -> bool:
		if typeof(data) != TYPE_DICTIONARY:
			return false
		if not CharacterSheet._auto("Equipment").is_slot_unlocked(slot_id):
			return false
		var d: Dictionary = data
		if str(d.get("kind", "")) != "gear":
			return false
		var iid: String = str(d.get("item_id", ""))
		if str(d.get("from_slot", "")) == slot_id:
			return false
		return CharacterSheet._auto("Equipment").item_fits_slot(iid, slot_id)

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
	var shown_count: int = -1
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
		var count: int = shown_count if shown_count >= 0 else CharacterSheet._auto("Equipment").unequipped_count(item_id)
		var name: String = CharacterSheet._auto("Equipment").item_display_name(item_id)
		lbl.text = name if count <= 1 else "%s  ×%d" % [name, count]
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl.add_theme_font_size_override("font_size", 13)
		lbl.add_theme_color_override("font_color", Color(0.92, 0.86, 0.72, 1.0))
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(lbl)
		tooltip_text = "%s\n%s" % [CharacterSheet._auto("Equipment").item_tooltip(item_id), CharacterSheet._auto("ContentStrings").get_text("equip_equip")]

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
