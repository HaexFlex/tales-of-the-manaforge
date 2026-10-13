extends Control
class_name CharacterSheet
## Paper-doll character sheet. Portrait left, battle gear middle, stats right.
## Equip by click or drag. Locked slots stay grey until a later forge unlock.

signal close_requested

const PORTRAIT_PATH: String = "res://assets/art/keeper/stills/keeper_still_south_frame0.png"
const WISP_PORTRAIT_PATH: String = "res://assets_extra/hud/wisp_portrait.png"
## HUD party slots. 52×52, drawn 1:1. companions.json points at these.
const KEEPER_PARTY_PORTRAIT_PATH: String = "res://assets_extra/shared/keeper_portrait.png"
const ELAIA_PARTY_PORTRAIT_PATH: String = "res://assets_extra/shared/elaia_portrait.png"
## 160×160 busts. Header icon only. The sheet figure is idle v4 south, frame 0.
const KEEPER_SHEET_PORTRAIT_PATH: String = "res://assets/art/portraits/keeper_portrait_sheet.png"
const ELAIA_SHEET_PORTRAIT_PATH: String = "res://assets/art/portraits/elaia_portrait_sheet.png"
## char540 r4 kit window (912×492, 24 px safe margins on 960×540).
const SHEET_SIZE: Vector2 = Vector2(912, 492)
const PAD: float = 24.0
const HEADER_H: float = 44.0
const BODY_TOP: float = 86.0
const BODY_H: float = 382.0
const HOST_POS: Vector2 = Vector2(24, 86)
const PORTRAIT_SIZE: Vector2 = Vector2(276, 382)
const SPRITE_SIZE: Vector2 = Vector2(144, 351)
const SPRITE_POS: Vector2 = Vector2(66, 15)
const FIGURE_SCALE: float = 3.0
const GEAR_X: float = 316.0
const GEAR_W: float = 270.0
const TABS_Y: float = 88.0
const GEAR_ROW_H: float = 46.0
const GEAR_ROW_PITCH: float = 50.0
const STATS_X: float = 604.0
const DOLL_BG: Color = Color8(26, 36, 28)
const STAT_RULE: Color = Color(0.243, 0.165, 0.094, 0.2)
const BEVEL_PATH: String = "res://assets/ui/theme/play_bevel_9s_6x6.png"
const DIVIDER_PATH: String = "res://assets_extra/shared/divider_3s_48x6.png"
const ROW_EVEN_PATH: String = "res://assets/ui/theme/list_row_9s_even_24x24.png"
const ROW_HOVER_PATH: String = "res://assets/ui/theme/pick_row_9s_hover_24x24.png"
const NOTE_SECONDS: float = 4.0
const PRIMARY_FONT_PATH: String = "res://assets/fonts/font_primary_silver38_bold.tres"
const TITLE_FONT_SIZE: int = 37
const SECTION_FONT_SIZE: int = 19
const BODY_FONT_SIZE: int = 19
const PLACEHOLDER_SWATCH: Color = Color(0.42, 0.40, 0.36, 1.0)


## Autoload name is not in scope when this script reloads under a --script run.
static func _auto(node_name: String):
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	return tree.root.get_node_or_null(node_name)


static func _theme() -> Node:
	return CharacterSheet._auto("GameTheme")


static func _style_plank_label(lbl: Label) -> void:
	var gt: Node = CharacterSheet._theme()
	if gt:
		gt.call("style_plank_label", lbl)


static func _style_ink(lbl: Label, muted: bool = false) -> void:
	var gt: Node = CharacterSheet._theme()
	if gt:
		gt.call("style_ink_label", lbl, muted)


static func _theme_call(method: String, ctrl: Control) -> void:
	var gt: Node = CharacterSheet._theme()
	if gt:
		gt.call(method, ctrl)


static func _theme_font(method: String) -> Font:
	var gt: Node = CharacterSheet._theme()
	return gt.call(method) as Font if gt else null


static func _style_body_label(lbl: Label) -> void:
	var gt: Node = CharacterSheet._theme()
	if gt:
		gt.call("style_body_label", lbl)


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


## 44 px slots in the doll gutters, beside the 3× figure (host 276×382, figure x 66–210).
## They ring the sprite; none of them sit on it.
const SLOT_POS: Dictionary = {
	"head": Vector2(8, 8),
	"cape": Vector2(8, 82),
	"weapon": Vector2(8, 156),
	"ring1": Vector2(8, 230),
	"feet": Vector2(8, 304),
	"relic": Vector2(224, 8),
	"body": Vector2(224, 82),
	"hands": Vector2(224, 156),
	"pants": Vector2(224, 230),
	"ring2": Vector2(224, 304),
}
const GEAR_TAB_W: float = 131.0
const SLOT_SIZE: Vector2 = Vector2(44, 44)
const SLOT_SQUARE: Vector2 = Vector2(44, 44)
## Stat blocks on a 40 px pitch below the Trait lines.
const STAT_TOP: float = 88.0
const STAT_STRIDE: float = 40.0
const STAT_NAME_Y: float = 2.0
const STAT_NAME_H: float = 20.0
const STAT_ROLE_Y: float = 19.0
const STAT_ROLE_H: float = 18.0
const ELAIA_SHEET_FIGURE: String = "res://assets/art/elaia/anim/idle/south.png"
const WOOD: Color = Color(0.16, 0.11, 0.07, 0.98)
const GOLD: Color = Color(0.82, 0.64, 0.28, 1.0)
const INK: Color = Color8(62, 42, 24)
const MUTED: Color = Color8(90, 62, 40)

var _portrait: TextureRect
var _inv_list: VBoxContainer
var _footer: Label
var _hover_item_id: String = ""
var _gear_filter_slot: String = ""
const GEAR_FILTER_CYCLE: Array[String] = [
	"", "weapon", "relic", "body", "pants", "hands", "cape", "head", "feet", "ring1",
]
var _built: bool = false
var _actor_id: String = "keeper"
var _prev_char_btn: Button
var _next_char_btn: Button
var _gear_tab_all_btn: Button
var _gear_cat_btn: Button
var _gear_tab_line: ColorRect
var _note_serial: int = 0


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
	var eq = CharacterSheet._auto("Equipment")
	if eq != null and not eq.equipment_changed.is_connected(_on_equipment_changed):
		eq.equipment_changed.connect(_on_equipment_changed)
	var stats = CharacterSheet._auto("KeeperStats")
	if stats != null and not stats.ranks_changed.is_connected(_on_ranks):
		stats.ranks_changed.connect(_on_ranks)
	_refresh()


func _on_ranks(_stat_id: StringName) -> void:
	if visible:
		_refresh_stats()


func _on_equipment_changed() -> void:
	## Bag clicks equip inside GearRow._gui_input; rebuilding the list in the
	## same frame tries to free the row that is still handling the click.
	call_deferred("_refresh")


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
	var gs = CharacterSheet._auto("GameState")
	if actor_id == "elaia" and (gs == null or not bool(gs.call("elaia_portrait_visible"))):
		actor_id = "keeper"
	_actor_id = actor_id if actor_id == "elaia" else "keeper"
	_apply_actor_chrome()
	_refresh_gear_tabs()
	_refresh_actor_nav()
	_refresh()
	_fit_sheet()


func close_sheet() -> void:
	close_trait_popup()
	visible = false
	_hover_item_id = ""


func request_close() -> void:
	close_requested.emit()


func request_equip(item_id: String) -> String:
	var actor: String = sheet_actor()
	var result: String = CharacterSheet._auto("Equipment").try_equip(item_id, actor)
	_toast(result, item_id, CharacterSheet._auto("Equipment").item_slot(item_id))
	return result


func request_equip_slot(item_id: String, slot_id: String) -> String:
	var actor: String = sheet_actor()
	var result: String = CharacterSheet._auto("Equipment").try_equip_to_slot(item_id, slot_id, actor)
	_toast(result, item_id, slot_id)
	return result


func request_unequip(slot_id: String) -> String:
	var actor: String = sheet_actor()
	var item_id: String = CharacterSheet._auto("Equipment").equipped_id_for(actor, slot_id)
	var result: String = CharacterSheet._auto("Equipment").try_unequip(slot_id, actor)
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
			if CharacterSheet._auto("Equipment").equipped_id_for(sheet_actor(), slot_id) == item_id and item_id != "":
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
		show_note(text)
		CharacterSheet._auto("GameState").status_message.emit(text)


func _build() -> void:
	if _built:
		return
	_built = true
	var strings = CharacterSheet._auto("ContentStrings")
	var dim := ColorRect.new()
	dim.name = "Dim"
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.02, 0.03, 0.02, 0.55)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	dim.gui_input.connect(_on_dim_input)
	add_child(dim)

	var fit := Control.new()
	fit.name = "SheetFit"
	fit.set_anchors_preset(Control.PRESET_TOP_LEFT)
	fit.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fit)
	resized.connect(_fit_sheet)

	var sheet := Panel.new()
	sheet.name = "Sheet"
	sheet.custom_minimum_size = SHEET_SIZE
	sheet.size = SHEET_SIZE
	sheet.mouse_filter = Control.MOUSE_FILTER_STOP
	fit.add_child(sheet)
	Ui540.apply_kit_panel(sheet, "character_sheet")

	# Header row: ‹ portrait Name › · hint · hotkey · ×
	_prev_char_btn = _make_arrow_button("PrevCharButton", "<", Vector2(PAD, PAD))
	_prev_char_btn.pressed.connect(_cycle_actor.bind(-1))
	sheet.add_child(_prev_char_btn)

	var header_icon := TextureRect.new()
	header_icon.name = "HeaderPortrait"
	header_icon.position = Vector2(PAD + 52.0, PAD + 6.0)
	header_icon.size = Vector2(32, 32)
	header_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	header_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	header_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	header_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header_icon.texture = load(KEEPER_SHEET_PORTRAIT_PATH) as Texture2D
	sheet.add_child(header_icon)

	var title := Label.new()
	title.name = "Title"
	title.position = Vector2(PAD + 92.0, PAD)
	title.size = Vector2(112, HEADER_H)
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.clip_text = true
	title.text = strings.get_text("char_sheet_title")
	title.add_theme_font_override("font", CharacterSheet._theme_font("title_font"))
	title.add_theme_font_size_override("font_size", TITLE_FONT_SIZE)
	title.add_theme_color_override("font_color", INK)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sheet.add_child(title)

	_next_char_btn = _make_arrow_button("NextCharButton", ">", Vector2(PAD + 212.0, PAD))
	_next_char_btn.pressed.connect(_cycle_actor.bind(1))
	sheet.add_child(_next_char_btn)

	var close := Button.new()
	close.name = "CloseButton"
	close.pressed.connect(request_close)
	Ui540.configure_kit_close_button(close)
	sheet.add_child(close)
	Ui540.place_close_button(close, SHEET_SIZE.x)
	close.position.y = PAD

	var hotkey := Label.new()
	hotkey.name = "HotkeyHint"
	hotkey.text = strings.get_text("char_sheet_hotkey_hint")
	_style_line(hotkey, true)
	hotkey.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	var hotkey_font: Font = hotkey.get_theme_font("font")
	var hotkey_w: float = 120.0
	if hotkey_font:
		hotkey_w = ceilf(hotkey_font.get_string_size(hotkey.text, HORIZONTAL_ALIGNMENT_LEFT, -1, BODY_FONT_SIZE).x) + 4.0
	hotkey.size = Vector2(hotkey_w, HEADER_H)
	hotkey.position = Vector2(close.position.x - 12.0 - hotkey_w, PAD)
	sheet.add_child(hotkey)

	var hint_x: float = PAD + 268.0
	var hint := Label.new()
	hint.name = "Hint"
	hint.text = strings.get_text("char_sheet_hint")
	_style_line(hint, true)
	hint.position = Vector2(hint_x, PAD)
	hint.size = Vector2(hotkey.position.x - 12.0 - hint_x, HEADER_H)
	hint.tooltip_text = hint.text
	hint.mouse_filter = Control.MOUSE_FILTER_PASS
	sheet.add_child(hint)

	_footer = Label.new()
	_footer.name = "Footer"
	_style_line(_footer, false)
	_footer.position = hint.position
	_footer.size = hint.size
	_footer.visible = false
	sheet.add_child(_footer)

	var divider := NinePatchRect.new()
	divider.name = "HeaderDivider"
	divider.texture = load(DIVIDER_PATH) as Texture2D
	divider.patch_margin_left = 16
	divider.patch_margin_right = 16
	divider.position = Vector2(PAD, PAD + 50.0)
	divider.size = Vector2(SHEET_SIZE.x - PAD * 2.0, 8.0)
	divider.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sheet.add_child(divider)

	# Paper doll: dark bevel, the 3× still centred, 44 px slots in the gutters beside it.
	var host := Control.new()
	host.name = "PortraitHost"
	host.position = HOST_POS
	host.size = PORTRAIT_SIZE
	host.custom_minimum_size = PORTRAIT_SIZE
	host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	host.clip_contents = true
	sheet.add_child(host)

	var bevel := Panel.new()
	bevel.name = "DollBevel"
	bevel.set_anchors_preset(Control.PRESET_FULL_RECT)
	bevel.add_theme_stylebox_override("panel", Ui540.kit_stylebox_9s(BEVEL_PATH, Vector4i(2, 2, 2, 2)))
	bevel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	host.add_child(bevel)
	var backdrop := ColorRect.new()
	backdrop.name = "PortraitBackdrop"
	backdrop.position = Vector2(2, 2)
	backdrop.size = PORTRAIT_SIZE - Vector2(4, 4)
	backdrop.color = DOLL_BG
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
	_portrait.texture = load(PORTRAIT_PATH) as Texture2D
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

	# Gear column
	var mid := InvColumn.new()
	mid.name = "GearColumn"
	mid.host = self
	mid.mouse_filter = Control.MOUSE_FILTER_STOP
	mid.position = Vector2(GEAR_X, BODY_TOP)
	mid.size = Vector2(GEAR_W, BODY_H)
	sheet.add_child(mid)

	var gear_title := Label.new()
	gear_title.name = "GearTitle"
	gear_title.text = strings.get_text("gear_title")
	_style_section_title(gear_title)
	gear_title.position = Vector2.ZERO
	gear_title.size = Vector2(GEAR_W, 20)
	mid.add_child(gear_title)

	var gear_hint := Label.new()
	gear_hint.name = "GearHint"
	gear_hint.text = strings.get_text("gear_hint")
	CharacterSheet._style_ink(gear_hint, true)
	gear_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	gear_hint.position = Vector2(0, 22)
	gear_hint.size = Vector2(GEAR_W, 40)
	mid.add_child(gear_hint)
	var persist := Label.new()
	persist.name = "PersistHint"
	persist.text = strings.get_text("weapon_persist_hint")
	_style_line(persist, true)
	persist.position = Vector2(0, 62)
	persist.size = Vector2(GEAR_W, 20)
	mid.add_child(persist)

	var tabs := HBoxContainer.new()
	tabs.name = "GearTabs"
	tabs.position = Vector2(0, TABS_Y)
	tabs.size = Vector2(GEAR_W, 44)
	tabs.add_theme_constant_override("separation", 8)
	mid.add_child(tabs)
	_gear_tab_all_btn = Button.new()
	_gear_tab_all_btn.name = "TabAll"
	_gear_tab_all_btn.custom_minimum_size = Vector2(GEAR_TAB_W, 44)
	_gear_tab_all_btn.pressed.connect(_set_gear_filter_all)
	CharacterSheet._theme_call("style_tab_button", _gear_tab_all_btn)
	_big_tab_font(_gear_tab_all_btn)
	tabs.add_child(_gear_tab_all_btn)
	_gear_cat_btn = Button.new()
	_gear_cat_btn.name = "GearCategoryCycle"
	_gear_cat_btn.custom_minimum_size = Vector2(GEAR_TAB_W, 44)
	_gear_cat_btn.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_gear_cat_btn.pressed.connect(_cycle_gear_filter)
	CharacterSheet._theme_call("style_tab_button", _gear_cat_btn)
	_big_tab_font(_gear_cat_btn)
	Ui540.add_cycle_cue(_gear_cat_btn)
	tabs.add_child(_gear_cat_btn)
	_gear_tab_line = ColorRect.new()
	_gear_tab_line.name = "TabUnderline"
	_gear_tab_line.color = GOLD
	_gear_tab_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mid.add_child(_gear_tab_line)

	var list_y: float = TABS_Y + 56.0
	var scroll := ScrollContainer.new()
	scroll.name = "GearScroll"
	scroll.position = Vector2(0, list_y)
	scroll.size = Vector2(GEAR_W, BODY_H - list_y)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_ALWAYS
	scroll.add_theme_stylebox_override("panel", Ui540.kit_stylebox_9s(BEVEL_PATH, Vector4i(2, 2, 2, 2), Vector4(2, 2, 2, 2)))
	mid.add_child(scroll)

	_inv_list = VBoxContainer.new()
	_inv_list.name = "GearList"
	_inv_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_inv_list.add_theme_constant_override("separation", int(GEAR_ROW_PITCH - GEAR_ROW_H))
	scroll.add_child(_inv_list)
	_refresh_gear_tabs()

	# Stats column
	var right := Control.new()
	right.name = "Stats"
	right.position = Vector2(STATS_X, BODY_TOP)
	right.size = Vector2(SHEET_SIZE.x - PAD - 8.0 - STATS_X, BODY_H)
	right.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sheet.add_child(right)
	var sw: float = right.size.x

	var stats_title := Label.new()
	stats_title.name = "StatsTitle"
	stats_title.text = strings.get_text("char_sheet_stats_header")
	_style_section_title(stats_title)
	stats_title.position = Vector2.ZERO
	stats_title.size = Vector2(sw, 20)
	right.add_child(stats_title)

	var stats_hint := Label.new()
	stats_hint.name = "PersistHint"
	stats_hint.text = strings.get_text("stat_persist_hint")
	_style_line(stats_hint, true)
	stats_hint.position = Vector2(0, 22)
	stats_hint.size = Vector2(sw, 20)
	right.add_child(stats_hint)

	var trait_row := Control.new()
	trait_row.name = "TraitRow"
	trait_row.position = Vector2(0, 42)
	trait_row.size = Vector2(sw, 44)
	trait_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	right.add_child(trait_row)
	var trait_label := Label.new()
	trait_label.name = "TraitLabel"
	trait_label.text = strings.get_text("char_sheet_trait_label")
	_style_line(trait_label, true)
	trait_label.position = Vector2(0, 0)
	trait_label.size = Vector2(44, 44)
	trait_row.add_child(trait_label)
	var trait_btn := Button.new()
	trait_btn.name = "TraitButton"
	trait_btn.position = Vector2(44, 0)
	trait_btn.size = Vector2(sw - 44.0, 44)
	trait_btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	trait_btn.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	trait_btn.text = strings.get_text("char_sheet_keeper_trait")
	_paint_trait_button(trait_btn)
	trait_btn.mouse_entered.connect(open_trait_popup)
	trait_btn.mouse_exited.connect(close_trait_popup)
	trait_row.add_child(trait_btn)

	## Name left and base + gear = total right on one line, the role under the name,
	## a hairline between stats.
	var y: float = STAT_TOP
	var first: bool = true
	for stat_name: StringName in CharacterSheet._auto("KeeperStats").STAT_ORDER:
		var sid: String = String(stat_name)
		var block := Control.new()
		block.name = "Stat_%s" % sid
		block.position = Vector2(0, y)
		block.size = Vector2(sw, STAT_STRIDE)
		block.mouse_filter = Control.MOUSE_FILTER_IGNORE
		right.add_child(block)
		if not first:
			var rule := ColorRect.new()
			rule.name = "Rule"
			rule.position = Vector2(0, 0)
			rule.size = Vector2(sw, 1)
			rule.color = STAT_RULE
			rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
			block.add_child(rule)
		first = false
		var stats = CharacterSheet._auto("KeeperStats")
		_add_stat_row(block, "Name", stats.stat_display_name(sid), stats.stat_ink_color(sid), STAT_NAME_Y, STAT_NAME_H, sw, false)
		_add_stat_row(block, "Role", stats.stat_role(sid), MUTED, STAT_ROLE_Y, STAT_ROLE_H, sw, false)
		_add_stat_row(block, "Line", "", INK, STAT_NAME_Y, STAT_NAME_H, sw, true)
		y += STAT_STRIDE

	var fate_note := Label.new()
	fate_note.name = "FateNote"
	fate_note.visible = false
	fate_note.position = Vector2(0, y)
	fate_note.size = Vector2(sw, 0)
	fate_note.mouse_filter = Control.MOUSE_FILTER_IGNORE
	right.add_child(fate_note)

	_build_trait_popup()
	call_deferred("_fit_sheet")


func _make_arrow_button(node_name: String, glyph: String, at: Vector2) -> Button:
	var btn := Button.new()
	btn.name = node_name
	btn.text = glyph
	CharacterSheet._theme_call("style_menu_button", btn)
	btn.custom_minimum_size = Vector2(44, 44)
	btn.position = at
	btn.size = Vector2(44, 44)
	return btn


## char540 gear tabs use the Silver 38 caps of the menu buttons.
func _big_tab_font(btn: Button) -> void:
	btn.add_theme_font_override("font", load(PRIMARY_FONT_PATH) as Font)
	btn.add_theme_font_size_override("font_size", 38)


func _style_line(lbl: Label, muted: bool) -> void:
	CharacterSheet._style_ink(lbl, muted)
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.autowrap_mode = TextServer.AUTOWRAP_OFF
	lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	lbl.clip_text = true
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _style_section_title(lbl: Label) -> void:
	lbl.add_theme_font_override("font", CharacterSheet._theme_font("title_font"))
	lbl.add_theme_font_size_override("font_size", SECTION_FONT_SIZE)
	lbl.add_theme_color_override("font_color", INK)
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE


## Equip and lock notes replace the header hint for a few seconds.
func show_note(text: String) -> void:
	if _footer == null:
		return
	_footer.text = text
	_footer.tooltip_text = text
	_footer.visible = text != ""
	var hint: CanvasItem = get_node_or_null("SheetFit/Sheet/Hint") as CanvasItem
	if hint:
		hint.visible = text == ""
	_note_serial += 1
	if text == "" or not is_inside_tree():
		return
	var serial: int = _note_serial
	await get_tree().create_timer(NOTE_SECONDS, true, false, true).timeout
	if serial == _note_serial:
		show_note("")


func _add_stat_row(block: Control, node_name: String, text: String, color: Color, y: float, row_h: float, width: float, right_align: bool) -> void:
	var host := Control.new()
	host.name = node_name
	host.position = Vector2(0, y)
	host.size = Vector2(width, row_h)
	host.clip_contents = false
	host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	block.add_child(host)
	var lbl := Label.new()
	lbl.name = "Text"
	lbl.text = text
	CharacterSheet._style_body_label(lbl)
	lbl.add_theme_color_override("font_color", color)
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT if right_align else HORIZONTAL_ALIGNMENT_LEFT
	lbl.mouse_filter = Control.MOUSE_FILTER_PASS if right_align else Control.MOUSE_FILTER_IGNORE
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
	need = maxf(host.size.y, need)
	lbl.size = Vector2(host.size.x, need)
	lbl.position = Vector2(0, (host.size.y - need) * 0.5)


func _fit_sheet() -> void:
	var fit: Control = get_node_or_null("SheetFit") as Control
	var sheet: Control = get_node_or_null("SheetFit/Sheet") as Control
	if fit == null or sheet == null:
		return
	sheet.scale = Vector2.ONE
	sheet.custom_minimum_size = SHEET_SIZE
	sheet.size = SHEET_SIZE
	sheet.position = Vector2.ZERO
	fit.custom_minimum_size = SHEET_SIZE
	fit.size = SHEET_SIZE
	Ui540.center_kit_panel(fit, false)


func _refresh_actor_nav() -> void:
	var actors: Array[String] = _available_actors()
	var dual: bool = actors.size() > 1
	if _prev_char_btn:
		_prev_char_btn.visible = dual
	if _next_char_btn:
		_next_char_btn.visible = dual


func _apply_actor_chrome() -> void:
	var sheet: Node = get_node_or_null("SheetFit/Sheet")
	if sheet == null:
		return
	_refresh_actor_nav()
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
		_place_figure()
	var header_icon: TextureRect = sheet.get_node_or_null("HeaderPortrait") as TextureRect
	if header_icon:
		var bust_path: String = ELAIA_SHEET_PORTRAIT_PATH if elaia else KEEPER_SHEET_PORTRAIT_PATH
		header_icon.texture = load(bust_path) as Texture2D
		header_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var trait_btn: Button = sheet.get_node_or_null("Stats/TraitRow/TraitButton") as Button
	if trait_btn:
		var trait_key: String = "char_sheet_elaia_trait" if elaia else "char_sheet_keeper_trait"
		trait_btn.text = strings.get_text(trait_key)


## The stills sit on a 128 px canvas; draw them at 3× so the figure itself fills SPRITE_SIZE.
func _place_figure() -> void:
	var tex: Texture2D = _portrait.texture
	_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_portrait.stretch_mode = TextureRect.STRETCH_SCALE
	if tex == null:
		_portrait.position = SPRITE_POS
		_portrait.size = SPRITE_SIZE
		return
	var used := Rect2i(Vector2i.ZERO, Vector2i(tex.get_size()))
	var img: Image = tex.get_image()
	if img != null:
		used = img.get_used_rect()
	var drawn: Vector2 = Vector2(used.size) * FIGURE_SCALE
	var origin: Vector2 = SPRITE_POS + Vector2(roundf((SPRITE_SIZE.x - drawn.x) * 0.5), SPRITE_SIZE.y - drawn.y)
	_portrait.size = tex.get_size() * FIGURE_SCALE
	_portrait.position = origin - Vector2(used.position) * FIGURE_SCALE


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
	panel.size = Vector2(380, 268)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pop.add_child(panel)
	Ui540.apply_kit_panel(panel, "trait_popup")
	var title := Label.new()
	title.name = "Title"
	title.position = Vector2(12, -20)
	title.size = Vector2(356, 40)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_style_plank_label(title)
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
	if strings == null or gs == null:
		return
	var actor: String = sheet_actor()
	var title: Label = panel.get_node_or_null("Title") as Label
	var sub: Label = panel.get_node_or_null("Subtitle") as Label
	if title:
		title.text = strings.get_text("char_sheet_trait_popup_title")
	if sub:
		sub.text = _trait_sentence()
	var work: float = float(gs.call("actor_work_rate", actor, ""))
	var relic: float = float(gs.call("actor_work_rate", actor, "reliquary"))
	var water: float = float(gs.call("actor_water_mult", actor))
	var pace: float = float(gs.call("actor_move_mult", actor))
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
	var panel_size := Vector2(380, 268)
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
	btn.add_theme_font_override("font", CharacterSheet._theme_font("body_font"))
	btn.add_theme_font_size_override("font_size", BODY_FONT_SIZE)
	for state: StringName in [&"font_color", &"font_hover_color", &"font_pressed_color", &"font_focus_color", &"font_hover_pressed_color"]:
		btn.add_theme_color_override(state, INK)


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


func _available_actors() -> Array[String]:
	var actors: Array[String] = ["keeper"]
	var gs = CharacterSheet._auto("GameState")
	if gs != null and bool(gs.call("elaia_portrait_visible")):
		actors.append("elaia")
	return actors


func _cycle_actor(delta: int) -> void:
	var actors: Array[String] = _available_actors()
	if actors.size() < 2:
		return
	var idx: int = actors.find(_actor_id)
	if idx < 0:
		idx = 0
	idx = (idx + delta) % actors.size()
	show_actor(actors[idx])


func _set_gear_filter_all() -> void:
	_gear_filter_slot = ""
	_refresh_gear_tabs()
	_refresh_inventory()


func _cycle_gear_filter() -> void:
	var idx: int = GEAR_FILTER_CYCLE.find(_gear_filter_slot)
	if idx < 0:
		idx = 0
	idx = (idx + 1) % GEAR_FILTER_CYCLE.size()
	_gear_filter_slot = GEAR_FILTER_CYCLE[idx]
	_refresh_gear_tabs()
	_refresh_inventory()


## On All the cycle tab names the category it will switch to; otherwise the one in use.
func _gear_filter_label() -> String:
	var slot_id: String = _gear_filter_slot if _gear_filter_slot != "" else GEAR_FILTER_CYCLE[1]
	var eq = CharacterSheet._auto("Equipment")
	if eq != null and eq.has_method("slot_display_name"):
		return str(eq.call("slot_display_name", slot_id))
	return slot_id.capitalize()


func _refresh_gear_tabs() -> void:
	var on_all: bool = _gear_filter_slot == ""
	if _gear_tab_all_btn:
		_gear_tab_all_btn.text = CharacterSheet._auto("ContentStrings").get_text("gear_tab_all")
		_gear_tab_all_btn.set_pressed_no_signal(on_all)
	if _gear_cat_btn:
		_gear_cat_btn.text = _gear_filter_label()
		_gear_cat_btn.set_pressed_no_signal(not on_all)
	if _gear_tab_line:
		var tab_x: float = 0.0 if on_all else 98.0
		var tab_w: float = 90.0 if on_all else GEAR_W - 98.0
		_gear_tab_line.position = Vector2(tab_x + 12.0, TABS_Y + 46.0)
		_gear_tab_line.size = Vector2(tab_w - 24.0, 3.0)


func _refresh_inventory() -> void:
	if _inv_list == null:
		return
	for child: Node in _inv_list.get_children():
		_inv_list.remove_child(child)
		child.free()
	var rows: Array[Dictionary] = []
	var eq = CharacterSheet._auto("Equipment")
	var actor: String = sheet_actor()
	for inst: Dictionary in eq.list_for_sheet(actor):
		var iid: String = str(inst.get("id", ""))
		if not eq.call("is_equippable", iid):
			continue
		if _gear_filter_slot != "" and str(eq.call("item_slot", iid)) != _gear_filter_slot:
			continue
		rows.append(inst)
	if rows.is_empty():
		var empty := Label.new()
		empty.name = "Empty"
		empty.text = CharacterSheet._auto("ContentStrings").get_text("gear_empty")
		empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		empty.mouse_filter = Control.MOUSE_FILTER_IGNORE
		empty.custom_minimum_size = Vector2(0, GEAR_ROW_H)
		empty.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		CharacterSheet._style_ink(empty, true)
		_inv_list.add_child(empty)
		return
	for inst: Dictionary in rows:
		var row := GearRow.new()
		row.host = self
		row.item_id = str(inst.get("id", ""))
		row.shown_count = int(inst.get("count", 1))
		row.custom_minimum_size = Vector2(0, GEAR_ROW_H)
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.mouse_filter = Control.MOUSE_FILTER_STOP
		_inv_list.add_child(row)
		row.setup()


func _refresh_stats() -> void:
	var root: Node = get_node_or_null("SheetFit/Sheet/Stats")
	if root == null:
		return
	var actor: String = sheet_actor()
	for stat_name: StringName in CharacterSheet._auto("KeeperStats").STAT_ORDER:
		var sid: String = String(stat_name)
		var line: Label = root.get_node_or_null("Stat_%s/Line/Text" % sid) as Label
		if line == null:
			continue
		var base: int = CharacterSheet._auto("KeeperStats").get_base_for(actor, sid)
		var gear: int = CharacterSheet._auto("Equipment").gear_bonus_for(actor, sid)
		var shown_gear: int = gear
		if _hover_item_id != "":
			shown_gear = CharacterSheet._auto("Equipment").preview_gear_bonus_for(actor, sid, _hover_item_id)
		var total: int = base + shown_gear
		## base = STAT_BASE_START + ranks. Line is base + gear = total.
		var text: String = "%d + %d = %d" % [base, shown_gear, total]
		if actor == "elaia":
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


const EMPTY_RELIC_FRAME_PATH: String = "res://assets_extra/char/relic_slot_empty.png"
const EMPTY_SLOT_FRAME_PATH: String = "res://assets/art/ui/board/item_slot_empty_44x44.png"
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
		caption_host.position = Vector2(-8, SLOT_SQUARE.y + 4)
		caption_host.size = Vector2(SLOT_SIZE.x + 16, 14)
		caption_host.clip_contents = true
		caption_host.mouse_filter = Control.MOUSE_FILTER_IGNORE
		## char540 r4 slots carry no caption; the tooltip names the slot or item.
		caption_host.visible = false
		add_child(caption_host)
		_caption = Label.new()
		_caption.name = "Hint"
		_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_caption.add_theme_font_size_override("font_size", 9)
		_caption.add_theme_color_override("font_color", CharacterSheet.MUTED)
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
		return _apply_frame(CharacterSheet.EMPTY_RELIC_FRAME_PATH)


	func _apply_frame(path: String) -> bool:
		var tex: Texture2D = null
		if ResourceLoader.exists(path):
			tex = load(path) as Texture2D
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
			if not _apply_frame(CharacterSheet.EMPTY_SLOT_FRAME_PATH):
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
			host.call("show_note", hint)
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
		_paint(false)
		var row := HBoxContainer.new()
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_theme_constant_override("separation", 7)
		row.set_anchors_preset(Control.PRESET_FULL_RECT)
		row.offset_left = 7.0
		row.offset_right = -6.0
		add_child(row)
		var icon: Control = CharacterSheet.make_item_icon(item_id)
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(icon)
		var text_col := VBoxContainer.new()
		text_col.mouse_filter = Control.MOUSE_FILTER_IGNORE
		text_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		text_col.alignment = BoxContainer.ALIGNMENT_CENTER
		text_col.add_theme_constant_override("separation", 0)
		row.add_child(text_col)
		var eq = CharacterSheet._auto("Equipment")
		var count: int = shown_count if shown_count >= 0 else eq.unequipped_count(item_id)
		var name: String = eq.item_display_name(item_id)
		var lbl := Label.new()
		lbl.name = "Name"
		lbl.text = name if count <= 1 else "%s  ×%d" % [name, count]
		CharacterSheet._style_ink(lbl)
		lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		text_col.add_child(lbl)
		var sub := Label.new()
		sub.name = "Detail"
		sub.text = _detail_line(eq)
		CharacterSheet._style_ink(sub, true)
		sub.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		sub.mouse_filter = Control.MOUSE_FILTER_IGNORE
		text_col.add_child(sub)
		tooltip_text = "%s\n%s" % [eq.item_tooltip(item_id), CharacterSheet._auto("ContentStrings").get_text("equip_equip")]

	## "Weapon · Might +2": the slot, then the first stat the item raises.
	func _detail_line(eq: Node) -> String:
		var parts: PackedStringArray = [str(eq.slot_display_name(eq.item_slot(item_id)))]
		var bonuses_v: Variant = eq.get_item_def(item_id).get("bonuses", {})
		if typeof(bonuses_v) == TYPE_DICTIONARY:
			var stats = CharacterSheet._auto("KeeperStats")
			for stat_name: StringName in stats.STAT_ORDER:
				var amount: int = int((bonuses_v as Dictionary).get(String(stat_name), 0))
				if amount != 0:
					parts.append("%s %s%d" % [stats.stat_display_name(String(stat_name)), "+" if amount > 0 else "", amount])
					break
		return " · ".join(parts)

	func _paint(hot: bool) -> void:
		var path: String = CharacterSheet.ROW_HOVER_PATH if hot else CharacterSheet.ROW_EVEN_PATH
		add_theme_stylebox_override("panel", Ui540.kit_stylebox_9s(path, Vector4i(6, 6, 6, 6)))

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
		if what == NOTIFICATION_MOUSE_ENTER:
			_paint(true)
		elif what == NOTIFICATION_MOUSE_EXIT:
			_paint(false)
			if host != null:
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
