extends CanvasLayer
class_name GameHUD
## HUD + Manatree care + backpack + Keeper's Bench + Ascension shop.

@onready var panel: ColorRect = $Panel
@onready var resources_label: Label = $Panel/ResourcesLabel
@onready var num_wood: Label = $Panel/IconRow/WoodChip/NumWood
@onready var num_stone: Label = $Panel/IconRow/StoneChip/NumStone
@onready var num_food: Label = $Panel/IconRow/FoodChip/NumFood
@onready var num_shards: Label = $Panel/IconRow/ShardChip/NumShards
@onready var num_essence: Label = $Panel/IconRow/EssenceChip/NumEssence
@onready var stage_label: Label = $Panel/StageLabel
@onready var controls_hint: Label = $Panel/ControlsHint
@onready var status_label: Label = $Panel/StatusLabel
@onready var toast_shade: ColorRect = $Panel/ToastShade
@onready var selection_hint: Label = $Panel/SelectionHint
@onready var help_button: Button = $Panel/HelpButton
@onready var help_icon: TextureRect = $Panel/HelpButton/HelpIcon
@onready var pause_button: Button = $Panel/PauseButton
@onready var character_button: Button = $Panel/CharacterButton
@onready var character_icon: TextureRect = $Panel/CharacterButton/CharacterIcon
@onready var ascension_icon: TextureRect = $Panel/AscensionReopenButton/AscensionIcon
@onready var backpack_button: Button = $Panel/BackpackButton
@onready var backpack_icon: TextureRect = $Panel/BackpackButton/BackpackIcon
@onready var pause_icon: TextureRect = $Panel/PauseButton/Icon
@onready var backpack_dim: ColorRect = $BackpackDim
@onready var backpack_panel: Panel = $BackpackPanel
@onready var backpack_title: Label = $BackpackPanel/Header/BackpackTitle
@onready var backpack_close_button: Button = $BackpackPanel/Header/BackpackCloseButton
@onready var inventory_title: Label = $BackpackPanel/InventoryTitle
@onready var backpack_tab_all: Button = $BackpackPanel/TabRow/TabAll
@onready var backpack_tab_raw: Button = $BackpackPanel/TabRow/TabRaw
@onready var backpack_tab_refined: Button = $BackpackPanel/TabRow/TabRefined
@onready var backpack_tab_tools: Button = $BackpackPanel/TabRow/TabTools
@onready var backpack_tab_weapons: Button = $BackpackPanel/TabRow/TabWeapons
@onready var backpack_tab_relics: Button = $BackpackPanel/TabRow/TabRelics
@onready var inventory_list: VBoxContainer = $BackpackPanel/InventoryScroll/InventoryList
@onready var bench_panel: Panel = $BenchPanel
@onready var bench_title: Label = $BenchPanel/Header/BenchTitle
@onready var bench_close_button: Button = $BenchPanel/Header/BenchCloseButton
@onready var bench_prompt: Label = $BenchPanel/BenchPrompt
@onready var craft_list: VBoxContainer = $BenchPanel/CraftScroll/CraftList
@onready var care_grow_costs: HBoxContainer = $CarePanel/CareGrowCosts
@onready var grow_fert_icon: TextureRect = $CarePanel/CareGrowCosts/FertilizerIcon
@onready var grow_fert_need: Label = $CarePanel/CareGrowCosts/FertilizerNeed
@onready var grow_ess_icon: TextureRect = $CarePanel/CareGrowCosts/EssenceIcon
@onready var grow_ess_need: Label = $CarePanel/CareGrowCosts/EssenceNeed
@onready var ascension_reopen_button: Button = $Panel/AscensionReopenButton
@onready var care_panel: Panel = $CarePanel
@onready var care_header: Control = $CarePanel/Header
@onready var care_title: Label = $CarePanel/Header/CareTitle
@onready var care_stage_label: Label = $CarePanel/Header/CareStageLabel
@onready var care_needs_label: Label = $CarePanel/CareNeedsLabel
@onready var fruit_ready_card: ColorRect = $CarePanel/FruitReadyCard
@onready var water_button: Button = $CarePanel/ActionBand/WaterButton
@onready var pay_button: Button = $CarePanel/ActionBand/PayButton
@onready var harvest_fruit_button: Button = $CarePanel/ActionBand/HarvestFruitButton
@onready var precommit_hint: Label = $CarePanel/FruitReadyCard/PrecommitHint
@onready var care_close_button: Button = $CarePanel/Header/CareCloseButton
@onready var care_action_band: Control = $CarePanel/ActionBand
var forge_button: Button
var _forge_popup: Panel
var _forge_popup_body: Label
@onready var fruit_confirm_panel: Panel = $FruitConfirmPanel
@onready var fruit_confirm_title: Label = $FruitConfirmPanel/ConfirmTitle
@onready var fruit_confirm_body: Label = $FruitConfirmPanel/ConfirmBody
@onready var fruit_confirm_yes: Button = $FruitConfirmPanel/ConfirmYes
@onready var fruit_confirm_no: Button = $FruitConfirmPanel/ConfirmNo
@onready var shop_dim: ColorRect = $ShopDim
@onready var ascension_panel: Panel = $AscensionPanel
@onready var prestige_panel: Panel = $AscensionPanel
@onready var shop_header: Control = $AscensionPanel/Header
@onready var prestige_title: Label = $AscensionPanel/Header/Title
@onready var prestige_sub: Label = $AscensionPanel/Header/Subtitle
@onready var shard_chip: ColorRect = $AscensionPanel/Header/ShardChip
@onready var shard_count_label: Label = $AscensionPanel/Header/ShardChip/ShardCount
@onready var shop_scroll: ScrollContainer = $AscensionPanel/ShopScroll
@onready var upgrade_list: VBoxContainer = $AscensionPanel/ShopScroll/UpgradeList
@onready var shop_footer: Control = $AscensionPanel/Footer
@onready var close_button: Button = $AscensionPanel/Footer/CloseButton
@onready var ascend_button: Button = $AscensionPanel/Footer/AscendButton
@onready var welcome_panel: ColorRect = $WelcomePanel
@onready var welcome_boot_label: Label = $WelcomePanel/WelcomeBoot
@onready var welcome_title_label: Label = $WelcomePanel/WelcomeTitle
@onready var welcome_body_label: Label = $WelcomePanel/WelcomeBody
@onready var welcome_hint_label: Label = $WelcomePanel/WelcomeHint
@onready var welcome_dismiss_button: Button = $WelcomePanel/WelcomeDismiss

## Art lock MANATREE_CARE_PANEL_V01: 520×420, header 64 / body / action band 56. No shop rows.
const CARE_SIZE: Vector2 = Vector2(520, 420)
const CARE_HEADER_H: float = 64.0
const CARE_ACTION_BAND_H: float = 56.0
## Art lock ASCENSION_SHOP_LAYOUT_V01: 720×500, header 64 / list flex / footer 72, row 48.
const SHOP_SIZE: Vector2 = Vector2(720, 500)
const SHOP_MIN_SIZE: Vector2 = Vector2(640, 420)
const SHOP_HEADER_H: float = 64.0
const SHOP_FOOTER_H: float = 72.0
const SHOP_ROW_H: float = 48.0
const SHOP_PAD: float = 16.0
const WOOD: Color = Color(0.16, 0.11, 0.07, 0.98)
const GOLD: Color = Color(0.82, 0.64, 0.28, 1.0)
const LEAF: Color = Color(0.24, 0.48, 0.28, 1.0)
const BUY_CAN: Color = Color(0.28, 0.52, 0.30, 1.0)
const BUY_CANT: Color = Color(0.62, 0.22, 0.18, 1.0)
const CHIP_CYAN: Color = Color(0.14, 0.38, 0.68, 0.95)
const ICON_FERTILIZER: Color = Color(0.42, 0.35, 0.14, 1.0)
const ICON_ESSENCE: Color = Color(0.56, 0.35, 0.66, 1.0)
const ICON_BACKPACK: Color = Color(0.48, 0.31, 0.18, 1.0)
const ESSENCE_TINT: Color = Color(0.78, 0.62, 1.18, 1.0)
const PLACEHOLDER_SWATCH: Color = Color(0.42, 0.40, 0.36, 1.0)
const ICON_WOOD_TEX: String = "res://assets/art/ui/icon_wood.png"
const ICON_STONE_TEX: String = "res://assets/art/ui/icon_stone.png"
const ICON_FOOD_TEX: String = "res://assets/art/ui/icon_food.png"
const ICON_SHARD_TEX: String = "res://assets/art/ui/icon_manashards.png"
const ICON_ESSENCE_TEX: String = "res://assets/art/ui/icon_essence.png"
const ICON_FERTILIZER_TEX: String = "res://assets/art/ui/icon_fertilizer.png"
const BTN_PAUSE_NORMAL: String = "res://assets/art/ui/buttons/pause_normal.png"
const BTN_PAUSE_HOVER: String = "res://assets/art/ui/buttons/pause_hover.png"
const BTN_PAUSE_PRESSED: String = "res://assets/art/ui/buttons/pause_pressed.png"
const BTN_PACK_NORMAL: String = "res://assets/art/ui/buttons/backpack_normal.png"
const BTN_PACK_HOVER: String = "res://assets/art/ui/buttons/backpack_hover.png"
const BTN_PACK_PRESSED: String = "res://assets/art/ui/buttons/backpack_pressed.png"
const BACKPACK_ROW_H: float = 40.0

var _manatree: Manatree = null
var _confirm_pay: bool = false
var _confirm_ascend: bool = false
## 0 = closed, 1 = Begin Ascension?, 2 = Commit the harvest.
var _fruit_confirm_step: int = 0
var _ancient_confirm: Panel
var _ancient_countdown: Label
var _ancient_countdown_bg: ColorRect
var _frozen_button: Button
var _frozen_hint: Label
var _nav_button: Button
var _highlight_ascend: bool = false
var _backpack_tab: String = "all"
var _sheet: CharacterSheet = null
var _toast_tween: Tween
var _care_hidden_for_forge: bool = false
const TOAST_HOLD_SEC: float = 2.6
const TOAST_FADE_SEC: float = 0.8


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	panel.color = Color(0, 0, 0, 0)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ascension_panel.visible = false
	fruit_confirm_panel.visible = false
	care_panel.visible = false
	welcome_panel.visible = false
	shop_dim.visible = false
	welcome_panel.color = Color(0.07, 0.1, 0.09, 0.97)
	shop_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	shop_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_ALWAYS
	shop_scroll.clip_contents = true
	_apply_wood_chrome()
	add_to_group("game_hud")
	pause_button.text = ""
	pause_button.tooltip_text = ContentStrings.get_text("btn_pause")
	character_button.text = ""
	character_button.tooltip_text = ContentStrings.get_text("char_sheet_hotkey_hint")
	backpack_button.text = ""
	backpack_button.tooltip_text = ContentStrings.get_text("backpack_open")
	_wire_sprite_hud()
	backpack_title.text = ContentStrings.get_text("backpack_title")
	inventory_title.text = ContentStrings.get_text("backpack_hint")
	_apply_filter_labels()
	bench_title.text = ContentStrings.get_text("bench_title")
	bench_prompt.text = "%s  ·  %s" % [
		ContentStrings.get_text("handcraft_title"),
		ContentStrings.get_text("tool_never_gate"),
	]
	bench_panel.visible = false
	close_button.text = ContentStrings.get_text("btn_close")
	care_close_button.text = ContentStrings.get_text("btn_close")
	water_button.text = ContentStrings.get_text("tree_interact_water")
	pay_button.text = ContentStrings.get_text("tree_grow")
	harvest_fruit_button.text = ContentStrings.get_text("fruit_ready_prompt")
	ascension_reopen_button.text = ""
	ascension_reopen_button.tooltip_text = ContentStrings.get_text("ascension_paused_title")
	care_title.text = "%s %s" % [
		ContentStrings.get_text("tree_menu_title"),
		ContentStrings.get_text("tree_care_title"),
	]
	welcome_boot_label.text = ContentStrings.get_text("welcome_boot")
	welcome_title_label.text = ContentStrings.get_text("welcome_title")
	welcome_body_label.text = ContentStrings.get_text("welcome_body")
	welcome_hint_label.text = ContentStrings.get_text("welcome_hint")
	welcome_dismiss_button.text = ContentStrings.get_text("welcome_dismiss")
	pause_button.pressed.connect(_on_pause_pressed)
	character_button.pressed.connect(toggle_character_sheet)
	backpack_button.pressed.connect(toggle_backpack)
	_sheet = CharacterSheet.new()
	_sheet.name = "CharacterSheet"
	_sheet.visible = false
	_sheet.z_index = 10
	_sheet.close_requested.connect(close_character_sheet)
	add_child(_sheet)
	backpack_close_button.pressed.connect(close_backpack)
	bench_close_button.pressed.connect(close_bench)
	backpack_tab_all.pressed.connect(_on_backpack_tab.bind("all"))
	backpack_tab_raw.pressed.connect(_on_backpack_tab.bind("raw"))
	backpack_tab_refined.pressed.connect(_on_backpack_tab.bind("refined"))
	backpack_tab_tools.pressed.connect(_on_backpack_tab.bind("tools"))
	backpack_tab_weapons.pressed.connect(_on_backpack_tab.bind("weapons"))
	backpack_tab_relics.pressed.connect(_on_backpack_tab.bind("relics"))
	if backpack_dim:
		backpack_dim.gui_input.connect(_on_backpack_dim_input)
	ascension_reopen_button.pressed.connect(show_ascension_shop)
	harvest_fruit_button.pressed.connect(open_fruit_confirm)
	fruit_confirm_yes.pressed.connect(confirm_fruit_step)
	fruit_confirm_no.pressed.connect(cancel_fruit_confirm)
	ascend_button.pressed.connect(_on_ascend)
	close_button.pressed.connect(_on_shop_close)
	care_close_button.pressed.connect(hide_care_menu)
	water_button.pressed.connect(_on_water)
	pay_button.pressed.connect(_on_pay)
	_ensure_forge_controls()
	_ensure_wisp_counter()
	_ensure_ancient_hud()
	_ensure_frozen_banner()
	_ensure_nav_button()
	if not GameState.ancient_expired.is_connected(_on_ancient_expired):
		GameState.ancient_expired.connect(_on_ancient_expired)
	if not GameState.echo_flags_changed.is_connected(_refresh_forge_entry):
		GameState.echo_flags_changed.connect(_refresh_forge_entry)
	welcome_dismiss_button.pressed.connect(_on_welcome_dismiss)
	GameState.resources_changed.connect(_on_resources)
	GameState.stage_changed.connect(_on_stage)
	GameState.needs_changed.connect(_on_needs)
	GameState.upgrades_changed.connect(_refresh_all)
	GameState.status_message.connect(_on_status)
	GameState.fruit_ready_changed.connect(_on_fruit_ready_changed)
	GameState.selection_changed.connect(_refresh_selection_hint)
	GameState.wisps_changed.connect(_refresh_selection_hint)
	GameState.echo_flags_changed.connect(_refresh_selection_hint)
	GameState.load_completed.connect(_on_game_state_loaded)
	Backpack.inventory_changed.connect(_on_backpack_inventory)
	_refresh_all()
	stage_label.visible = false
	controls_hint.visible = false
	selection_hint.visible = false
	status_label.visible = false
	if toast_shade:
		toast_shade.visible = false
	_refresh_controls_hint()
	_build_party_bar()
	_refresh_selection_hint()
	_show_toast(ContentStrings.get_text("boot_line"))
	_sync_ascension_from_state()


func _wood_style() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = WOOD
	sb.border_color = GOLD
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(2)
	sb.content_margin_left = 2.0
	sb.content_margin_right = 2.0
	sb.content_margin_top = 2.0
	sb.content_margin_bottom = 2.0
	return sb


func _btn_style(bg: Color, border: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(3)
	sb.content_margin_left = 10.0
	sb.content_margin_right = 10.0
	sb.content_margin_top = 6.0
	sb.content_margin_bottom = 6.0
	return sb


func _apply_button_chrome(btn: Button, bg: Color, border: Color) -> void:
	var normal: StyleBoxFlat = _btn_style(bg, border)
	var hover: StyleBoxFlat = _btn_style(bg.lightened(0.08), GOLD)
	var pressed: StyleBoxFlat = _btn_style(bg.darkened(0.12), border)
	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", pressed)
	btn.add_theme_stylebox_override("focus", hover)
	btn.add_theme_color_override("font_color", Color(0.95, 0.96, 0.88, 1.0))
	btn.add_theme_color_override("font_hover_color", Color(1, 1, 0.92, 1.0))
	btn.add_theme_color_override("font_pressed_color", Color(1, 1, 1, 1.0))


func _apply_icon_button(btn: Button) -> void:
	var empty := StyleBoxEmpty.new()
	btn.add_theme_stylebox_override("normal", empty)
	btn.add_theme_stylebox_override("hover", empty)
	btn.add_theme_stylebox_override("pressed", empty)
	btn.add_theme_stylebox_override("focus", empty)
	btn.add_theme_stylebox_override("disabled", empty)
	btn.flat = true


func _load_ui_tex(path: String) -> Texture2D:
	if path == "" or not ResourceLoader.exists(path):
		return null
	return load(path) as Texture2D


func _assign_tex(node: TextureRect, path: String, tip: String, tint: Color = Color.WHITE) -> void:
	if node == null:
		return
	node.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	node.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	node.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	node.texture = _load_ui_tex(path)
	node.modulate = tint
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if tip != "":
		node.tooltip_text = tip


func _bind_tex_states(btn: Button, icon: TextureRect, normal: String, hover: String, pressed: String) -> void:
	if icon == null:
		return
	var ntex: Texture2D = _load_ui_tex(normal)
	var htex: Texture2D = _load_ui_tex(hover)
	var ptex: Texture2D = _load_ui_tex(pressed)
	icon.texture = ntex
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if ntex == null:
		return
	btn.mouse_entered.connect(func() -> void:
		icon.texture = htex if htex else ntex
	)
	btn.mouse_exited.connect(func() -> void:
		icon.texture = ntex
	)
	btn.button_down.connect(func() -> void:
		icon.texture = ptex if ptex else ntex
	)
	btn.button_up.connect(func() -> void:
		icon.texture = htex if htex and btn.is_hovered() else ntex
	)


func _wire_sprite_hud() -> void:
	panel.color = Color(0, 0, 0, 0)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var icon_row: Control = $Panel/IconRow
	if icon_row:
		icon_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_assign_tex($Panel/IconRow/WoodChip/IconWood, ICON_WOOD_TEX, ContentStrings.get_text("hud_wood"))
	_assign_tex($Panel/IconRow/StoneChip/IconStone, ICON_STONE_TEX, ContentStrings.get_text("hud_stone"))
	_assign_tex($Panel/IconRow/FoodChip/IconFood, ICON_FOOD_TEX, ContentStrings.get_text("hud_food"))
	_assign_tex($Panel/IconRow/ShardChip/IconShards, ICON_SHARD_TEX, ContentStrings.get_text("hud_manashards"))
	_assign_tex($Panel/IconRow/EssenceChip/IconEssence, ICON_ESSENCE_TEX, ContentStrings.get_text("hud_essence"), ESSENCE_TINT)
	_assign_tex(grow_fert_icon, ICON_FERTILIZER_TEX, ContentStrings.get_text("fertilizer_name"))
	_assign_tex(grow_ess_icon, ICON_ESSENCE_TEX, ContentStrings.get_text("hud_essence"), ESSENCE_TINT)
	_bind_tex_states(backpack_button, backpack_icon, BTN_PACK_NORMAL, BTN_PACK_HOVER, BTN_PACK_PRESSED)
	_bind_tex_states(pause_button, pause_icon, BTN_PAUSE_NORMAL, BTN_PAUSE_HOVER, BTN_PAUSE_PRESSED)
	if character_icon:
		HudIcons.apply(character_icon, HudIcons.CHARACTER)
	if help_icon:
		HudIcons.apply(help_icon, HudIcons.HELP)
	if ascension_icon:
		HudIcons.apply(ascension_icon, HudIcons.ASCENSION)
	for chip_path: String in [
		"Panel/IconRow/WoodChip",
		"Panel/IconRow/StoneChip",
		"Panel/IconRow/FoodChip",
		"Panel/IconRow/ShardChip",
		"Panel/IconRow/EssenceChip",
	]:
		var chip: Control = get_node_or_null(chip_path) as Control
		if chip and chip.get_child_count() > 0:
			var icon: CanvasItem = chip.get_child(0) as CanvasItem
			if icon:
				chip.tooltip_text = icon.tooltip_text


func _item_icon_path(item_id: String) -> String:
	var from_art: String = Equipment.item_art_path(item_id)
	if from_art != "":
		return from_art
	match item_id:
		"wood":
			return ICON_WOOD_TEX
		"stone":
			return ICON_STONE_TEX
		"food":
			return ICON_FOOD_TEX
		"manashards":
			return ICON_SHARD_TEX
		"essence":
			return ICON_ESSENCE_TEX
		_:
			return ""


func _make_item_icon(item_id: String, tip: String) -> Control:
	var sheet_index: int = HudIcons.index_for_item(item_id)
	if sheet_index >= 0:
		var sheet_icon: TextureRect = HudIcons.make_icon(sheet_index)
		sheet_icon.tooltip_text = tip
		return sheet_icon
	var path: String = _item_icon_path(item_id)
	var tex: Texture2D = _load_ui_tex(path)
	if tex:
		var icon := TextureRect.new()
		icon.custom_minimum_size = Vector2(32, 32)
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture = tex
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon.tooltip_text = tip
		if item_id == "essence":
			icon.modulate = ESSENCE_TINT
		return icon
	var placeholder := _placeholder_icon(PLACEHOLDER_SWATCH)
	placeholder.tooltip_text = tip
	return placeholder


func _apply_wood_chrome() -> void:
	ascension_panel.add_theme_stylebox_override("panel", _wood_style())
	fruit_confirm_panel.add_theme_stylebox_override("panel", _wood_style())
	care_panel.add_theme_stylebox_override("panel", _wood_style())
	shard_chip.color = CHIP_CYAN
	_apply_button_chrome(close_button, Color(0.18, 0.14, 0.10, 1.0), GOLD)
	_apply_button_chrome(ascend_button, LEAF, GOLD)
	_apply_button_chrome(fruit_confirm_yes, LEAF, GOLD)
	_apply_button_chrome(fruit_confirm_no, Color(0.18, 0.14, 0.10, 1.0), GOLD)
	_apply_button_chrome(care_close_button, Color(0.18, 0.14, 0.10, 1.0), GOLD)
	_apply_button_chrome(water_button, Color(0.18, 0.14, 0.10, 1.0), GOLD)
	_apply_button_chrome(pay_button, LEAF, GOLD)
	_apply_button_chrome(harvest_fruit_button, LEAF, GOLD)
	_apply_icon_button(character_button)
	_apply_icon_button(backpack_button)
	_apply_icon_button(pause_button)
	_apply_icon_button(ascension_reopen_button)
	_apply_button_chrome(backpack_close_button, Color(0.18, 0.14, 0.10, 1.0), GOLD)
	_apply_button_chrome(bench_close_button, Color(0.18, 0.14, 0.10, 1.0), GOLD)
	for tab: Button in [backpack_tab_all, backpack_tab_raw, backpack_tab_refined, backpack_tab_tools, backpack_tab_weapons, backpack_tab_relics]:
		_apply_button_chrome(tab, Color(0.18, 0.14, 0.10, 1.0), GOLD)
	backpack_panel.add_theme_stylebox_override("panel", _wood_style())
	bench_panel.add_theme_stylebox_override("panel", _wood_style())


func _process(_delta: float) -> void:
	_refresh_ancient_countdown()
	_refresh_nav_button()
	_refresh_frozen_banner()
	if _party_info != null and _party_info.visible:
		_apply_selection_job()


func _refresh_dim() -> void:
	if shop_dim == null:
		return
	var ancient_open: bool = _ancient_confirm != null and _ancient_confirm.visible
	shop_dim.visible = fruit_confirm_panel.visible or ascension_panel.visible or ancient_open
	if backpack_dim:
		backpack_dim.visible = backpack_panel.visible or bench_panel.visible


func bind_manatree(tree: Manatree) -> void:
	_manatree = tree


func maybe_show_welcome() -> void:
	if GameState.welcome_shown:
		return
	show_welcome()


func show_welcome() -> void:
	close_backpack()
	close_character_sheet()
	hide_care_menu()
	hide_fruit_confirm()
	hide_ascension_shop()
	welcome_boot_label.text = ContentStrings.get_text("welcome_boot")
	welcome_title_label.text = ContentStrings.get_text("welcome_title")
	welcome_body_label.text = ContentStrings.get_text("welcome_body")
	welcome_hint_label.text = ContentStrings.get_text("welcome_hint")
	welcome_dismiss_button.text = ContentStrings.get_text("welcome_dismiss")
	welcome_panel.visible = true
	GameAudio.play_ui_open()


func hide_welcome() -> void:
	welcome_panel.visible = false


func _on_welcome_dismiss() -> void:
	GameState.welcome_shown = true
	hide_welcome()
	GameAudio.play_ui_confirm()
	_show_toast(ContentStrings.get_text("boot_line"))
	SaveService.save_game()
	maybe_show_elaia_join()


func _on_resources(_id: StringName, _amount: int) -> void:
	_refresh_resources()
	_refresh_ascension_copy()
	if care_panel.visible:
		_refresh_care_needs()


func _on_stage(_id: StringName) -> void:
	_refresh_stage()
	_confirm_pay = false
	if care_panel.visible:
		_refresh_care_needs()


func _on_needs() -> void:
	_refresh_stage()
	if care_panel.visible:
		_refresh_care_needs()


func _on_status(text: String) -> void:
	_show_toast(text)


func _controls_line() -> String:
	return "%s  ·  %s  ·  %s  ·  %s" % [
		ContentStrings.get_text("controls_lmb_select"),
		ContentStrings.get_text("controls_rmb_command"),
		ContentStrings.get_text("controls_lmb_deselect"),
		ContentStrings.get_text("controls_camera_pan"),
	]


func _show_toast(text: String) -> void:
	if status_label == null:
		return
	var line := text.strip_edges()
	var nl := line.find("\n")
	if nl >= 0:
		line = line.substr(0, nl).strip_edges()
	if line == "":
		return
	status_label.text = line
	status_label.visible = true
	status_label.modulate.a = 1.0
	if toast_shade:
		toast_shade.visible = true
		toast_shade.modulate.a = 0.92
	if _toast_tween != null and _toast_tween.is_valid():
		_toast_tween.kill()
	_toast_tween = create_tween()
	_toast_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_toast_tween.tween_interval(TOAST_HOLD_SEC)
	_toast_tween.tween_property(status_label, "modulate:a", 0.0, TOAST_FADE_SEC)
	if toast_shade:
		_toast_tween.parallel().tween_property(toast_shade, "modulate:a", 0.0, TOAST_FADE_SEC)
	_toast_tween.tween_callback(_hide_toast)


func _hide_toast() -> void:
	if status_label:
		status_label.visible = false
	if toast_shade:
		toast_shade.visible = false


func _refresh_controls_hint() -> void:
	if controls_hint == null:
		return
	var line := _controls_line()
	controls_hint.text = line
	controls_hint.visible = false
	if help_button:
		help_button.text = ""
		help_button.tooltip_text = line


const PARTY_SLOT: float = 56.0
const PARTY_OUTLINE: Color = Color(0.78, 0.92, 0.62, 1.0)

var _party_bar: Control
var _party_column: VBoxContainer
var _party_info: VBoxContainer
var _slot_wisp: Control
var _slot_elaia: Control
var _slot_keeper: Control
var _wisp_count_label: Label
var _sel_name: Label
var _sel_task: Label
var _sel_job: Label
var _sel_extra: Label
var _join_band: Panel
var _join_name: Label
var _join_line: Label
var _join_index: int = 0


func _build_party_bar() -> void:
	if _party_bar != null:
		return
	_party_bar = Control.new()
	_party_bar.name = "PartyBar"
	## Top-left anchors. The column stays in the gutter the character sheet leaves open.
	_party_bar.anchor_left = 0.0
	_party_bar.anchor_top = 0.0
	_party_bar.anchor_right = 0.0
	_party_bar.anchor_bottom = 0.0
	_party_bar.offset_left = 12.0
	_party_bar.offset_top = 86.0
	_party_bar.offset_right = 12.0 + PARTY_SLOT
	_party_bar.offset_bottom = 86.0 + PARTY_SLOT * 3.0 + 24.0
	_party_bar.z_index = 20
	_party_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_party_column = VBoxContainer.new()
	_party_column.name = "Column"
	_party_column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_party_column.add_theme_constant_override("separation", 6)
	_slot_wisp = _make_party_slot("Wisps", "wisp")
	_slot_elaia = _make_party_slot("Elaia", "elaia")
	_slot_keeper = _make_party_slot("Keeper", "keeper")
	_wisp_count_label = Label.new()
	_wisp_count_label.name = "Count"
	_wisp_count_label.position = Vector2(24, 34)
	_wisp_count_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_style_party_label(_wisp_count_label, 14, Color(0.95, 0.92, 0.78))
	_slot_wisp.add_child(_wisp_count_label)
	_party_column.add_child(_slot_wisp)
	_party_column.add_child(_slot_keeper)
	_party_column.add_child(_slot_elaia)
	_party_info = VBoxContainer.new()
	_party_info.name = "Info"
	_party_info.position = Vector2(PARTY_SLOT + 10.0, 0)
	_party_info.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_party_info.add_theme_constant_override("separation", 0)
	_sel_name = Label.new()
	_sel_name.name = "Name"
	_style_party_label(_sel_name, 15, Color(0.96, 0.94, 0.86))
	_sel_extra = Label.new()
	_sel_extra.name = "Extra"
	_style_party_label(_sel_extra, 13, Color(0.85, 0.9, 0.75))
	_sel_task = Label.new()
	_sel_task.name = "Task"
	_style_party_label(_sel_task, 13, Color(0.85, 0.9, 0.75))
	_sel_job = Label.new()
	_sel_job.name = "JobLine"
	_style_party_label(_sel_job, 13, Color(0.95, 0.86, 0.55))
	_sel_job.visible = false
	_party_info.add_child(_sel_name)
	_party_info.add_child(_sel_extra)
	_party_info.add_child(_sel_task)
	_party_info.add_child(_sel_job)
	_party_bar.add_child(_party_column)
	_party_bar.add_child(_party_info)
	add_child(_party_bar)
	var keeper_tex: Texture2D = load(CharacterSheet.PORTRAIT_PATH) as Texture2D
	var wisp_tex: Texture2D = load(CharacterSheet.WISP_PORTRAIT_PATH) as Texture2D
	(_slot_keeper.get_node("Portrait") as TextureRect).texture = keeper_tex
	(_slot_wisp.get_node("Portrait") as TextureRect).texture = wisp_tex
	(_slot_elaia.get_node("Portrait") as TextureRect).texture = _elaia_portrait_texture()
	_slot_elaia.tooltip_text = ContentStrings.get_text("hud_elaia_portrait_tooltip")
	_slot_elaia.visible = false
	_slot_elaia.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _elaia_portrait_texture() -> Texture2D:
	## Same face crop as the character sheet. The key stays outside the region.
	return CharacterSheet.elaia_portrait_texture()


func _make_party_slot(slot_name: String, unit: String) -> Control:
	var host := Control.new()
	host.name = slot_name
	host.custom_minimum_size = Vector2(PARTY_SLOT, PARTY_SLOT)
	host.size = Vector2(PARTY_SLOT, PARTY_SLOT)
	host.mouse_filter = Control.MOUSE_FILTER_STOP
	host.gui_input.connect(_on_party_slot_input.bind(unit))
	var frame := Panel.new()
	frame.name = "Frame"
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.position = Vector2.ZERO
	frame.size = Vector2(PARTY_SLOT, PARTY_SLOT)
	host.add_child(frame)
	var portrait := TextureRect.new()
	portrait.name = "Portrait"
	portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	portrait.position = Vector2(2, 2)
	portrait.size = Vector2(PARTY_SLOT - 4.0, PARTY_SLOT - 4.0)
	host.add_child(portrait)
	return host


func _style_party_label(label: Label, size: int, color: Color) -> void:
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0.05, 0.04, 0.03, 1.0))
	label.add_theme_constant_override("outline_size", 4)


func _set_party_outline(slot: Control, selected: bool) -> void:
	var frame := slot.get_node("Frame") as Panel
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0)
	style.border_color = PARTY_OUTLINE
	style.set_border_width_all(2 if selected else 0)
	frame.add_theme_stylebox_override("panel", style)


func _on_party_slot_input(event: InputEvent, unit: String) -> void:
	if not (event is InputEventMouseButton):
		return
	var mb: InputEventMouseButton = event
	if not mb.pressed or mb.button_index != MOUSE_BUTTON_LEFT:
		return
	party_click(unit)
	if mb.double_click:
		party_focus()


func party_click(unit: String) -> void:
	if unit == "elaia" and not GameState.elaia_in_party():
		return
	if is_character_open() and (unit == "keeper" or unit == "elaia") and _sheet != null:
		_sheet.show_actor(unit)
	if unit == "keeper":
		GameState.select_keeper()
	elif unit == "elaia":
		GameState.select_companion("elaia")
	elif unit == "wisp":
		var ids: Array[int] = GameState.selected_wisp_list()
		if ids.is_empty():
			if GameState.wisp_count > 0:
				GameState.select_wisp(0)
		else:
			GameState.select_group(ids, false)


func party_focus() -> void:
	var scene: Node = get_tree().current_scene
	if scene and scene.has_method("focus_selection"):
		scene.call("focus_selection")


func _refresh_party_bar() -> void:
	if _party_bar == null:
		return
	var ids: Array[int] = GameState.selected_wisp_list()
	var show_keeper: bool = GameState.keeper_selected
	var companion_id: String = str(GameState.selected_companion_id)
	var elaia_joined: bool = GameState.elaia_in_party()
	_party_bar.visible = true
	_slot_keeper.visible = true
	_slot_elaia.visible = elaia_joined
	_slot_elaia.mouse_filter = Control.MOUSE_FILTER_STOP if elaia_joined else Control.MOUSE_FILTER_IGNORE
	_slot_wisp.visible = not ids.is_empty()
	_set_party_outline(_slot_keeper, show_keeper)
	_set_party_outline(_slot_elaia, companion_id == "elaia")
	_set_party_outline(_slot_wisp, not ids.is_empty())
	if ids.size() >= 2:
		_wisp_count_label.text = "x%d" % ids.size()
		_wisp_count_label.visible = true
	else:
		_wisp_count_label.text = ""
		_wisp_count_label.visible = false
	if not show_keeper and ids.is_empty() and companion_id == "":
		_party_info.visible = false
		_apply_selection_job()
		_hide_party_info_for_sheet()
		return
	_party_info.visible = true
	_sel_extra.visible = false
	if show_keeper and not ids.is_empty():
		_sel_name.text = ContentStrings.get_text("hud_sel_keeper")
		_sel_extra.text = ContentStrings.get_text("hud_sel_plus_wisps")
		_sel_extra.visible = true
		_sel_task.text = _keeper_task_text()
	elif show_keeper:
		_sel_name.text = ContentStrings.get_text("hud_sel_keeper")
		_sel_task.text = _keeper_task_text()
	elif companion_id == "elaia" and elaia_joined:
		_sel_name.text = ContentStrings.get_text("echo_elaia_name")
		_sel_task.text = _hero_task_text(ForgeJobs.elaia_task() if has_node("/root/ForgeJobs") else {})
	elif ids.size() >= 2:
		_sel_name.text = ContentStrings.get_text("hud_sel_wisp_group")
		_sel_task.text = _group_task_text(ids, false)
	elif not ids.is_empty():
		_sel_name.text = ContentStrings.get_text("hud_sel_wisp")
		_sel_task.text = _wisp_task_text(ids[0])
	else:
		_party_info.visible = false
	_apply_selection_job()
	_hide_party_info_for_sheet()


func _hide_party_info_for_sheet() -> void:
	## The name line sits beside the portraits and would cover the sheet.
	if is_character_open() and _party_info:
		_party_info.visible = false


func _apply_selection_job() -> void:
	if _sel_job == null:
		return
	if _party_info == null or not _party_info.visible:
		_sel_job.visible = false
		return
	var station: String = _selection_job_station()
	if station == "":
		_sel_job.visible = false
		_sel_job.text = ""
		return
	_sel_job.visible = true
	_sel_job.text = ForgeJobs.job_line(station)


func _selection_job_station() -> String:
	if not has_node("/root/ForgeJobs"):
		return ""
	if GameState.keeper_selected:
		var task: Dictionary = ForgeJobs.keeper_task()
		if bool(task.get("working", false)) and str(task.get("kind", "")) == "forge":
			var station: String = str(task.get("target", ""))
			var keeper_state: Dictionary = ForgeJobs.job_state(station)
			if not keeper_state.is_empty() and bool(keeper_state.get("working", false)):
				return station
	if str(GameState.selected_companion_id) == "elaia" and GameState.elaia_in_party():
		var elaia_task: Dictionary = ForgeJobs.elaia_task()
		if bool(elaia_task.get("working", false)) and str(elaia_task.get("kind", "")) == "forge":
			var elaia_station: String = str(elaia_task.get("target", ""))
			var elaia_state: Dictionary = ForgeJobs.job_state(elaia_station)
			if not elaia_state.is_empty() and bool(elaia_state.get("working", false)):
				return elaia_station
	var ids: Array[int] = GameState.selected_wisp_list()
	if ids.is_empty():
		return ""
	var shared: String = GameState.get_wisp_assignment(ids[0])
	if not ForgeJobs.is_forge_station(shared):
		return ""
	for id: int in ids:
		if GameState.get_wisp_assignment(id) != shared:
			return ""
	var state: Dictionary = ForgeJobs.job_state(shared)
	if state.is_empty() or not bool(state.get("working", false)):
		return ""
	return shared


func _group_task_text(ids: Array[int], with_keeper: bool) -> String:
	var first: String = _wisp_task_text(ids[0])
	var same: bool = true
	for id: int in ids:
		if _wisp_task_text(id) != first:
			same = false
			break
	if with_keeper:
		return "%s + %s" % [ContentStrings.get_text("hud_sel_keeper"), first if same else "Mixed"]
	return first if same else "Mixed"


func _keeper_task_text() -> String:
	if not has_node("/root/ForgeJobs"):
		return ContentStrings.get_text("hud_task_idle")
	return _hero_task_text(ForgeJobs.keeper_task())


func _hero_task_text(task: Dictionary) -> String:
	if not bool(task.get("working", false)):
		return ContentStrings.get_text("hud_task_idle")
	var kind: String = str(task.get("kind", ""))
	var target: String = str(task.get("target", ""))
	if kind == "forge":
		return "Tending %s" % ForgeJobs.station_display(target)
	if kind == "harvest":
		match target:
			"wood":
				return "Gathering Wood"
			"stone":
				return "Gathering Stone"
			"food":
				return "Gathering Food"
			_:
				return "Gathering"
	if kind == "water":
		return "Tending the Manatree"
	return ContentStrings.get_text("hud_task_idle")


func _wisp_task_text(wisp_id: int) -> String:
	var assigned: String = GameState.get_wisp_assignment(wisp_id)
	if assigned == "":
		return ContentStrings.get_text("hud_task_idle")
	match assigned:
		"harvest_tree":
			return "Gathering Wood"
		"harvest_stone":
			return "Gathering Stone"
		"harvest_berry":
			return "Gathering Food"
		"manatree":
			return "Tending the Manatree"
		_:
			if has_node("/root/ForgeJobs") and ForgeJobs.is_forge_station(assigned):
				return "Tending %s" % ForgeJobs.station_display(assigned)
			return GameState.assignment_target_display(assigned)


func _refresh_selection_hint() -> void:
	_refresh_party_bar()
	if selection_hint == null:
		return
	if GameState.selected_wisp_id >= 0:
		selection_hint.text = "%s  ·  %s" % [
			ContentStrings.get_text("wisp_orbit_hint"),
			ContentStrings.get_text("wisp_node_shared_hint"),
		]
	elif GameState.keeper_selected:
		selection_hint.text = ContentStrings.get_text("keeper_move_prompt")
	else:
		selection_hint.text = ContentStrings.get_text("keeper_select_hint")
	selection_hint.visible = false
	maybe_show_elaia_join()


var _pause_menu: PauseMenu = null


func bind_pause_menu(menu: PauseMenu) -> void:
	_pause_menu = menu
	if _pause_menu:
		_pause_menu.status_toast.connect(_on_status)
		_pause_menu.new_game_started.connect(_on_new_game_from_pause)
		_pause_menu.game_loaded.connect(_on_loaded_from_pause)


func _on_pause_pressed() -> void:
	if welcome_panel.visible:
		return
	if is_backpack_open():
		close_backpack()
	if is_character_open():
		close_character_sheet()
	if _pause_menu:
		_pause_menu.open_pause()


func _on_new_game_from_pause() -> void:
	hide_care_menu()
	hide_fruit_confirm()
	hide_ascension_shop()
	_highlight_ascend = false
	_refresh_all()
	show_welcome()


func _on_loaded_from_pause() -> void:
	hide_care_menu()
	hide_fruit_confirm()
	_highlight_ascend = false
	_refresh_all()
	_sync_ascension_from_state()
	maybe_show_welcome()


func _on_game_state_loaded() -> void:
	_refresh_all()
	_sync_ascension_from_state()


func _refresh_all() -> void:
	_refresh_resources()
	_refresh_stage()
	if GameState.fruit_harvested_pending_ascend:
		_rebuild_upgrades()
	_refresh_ascension_copy()
	_refresh_controls_hint()
	_refresh_selection_hint()
	_refresh_reopen_button()
	_refresh_frozen_banner()
	_refresh_nav_button()
	if care_panel.visible:
		_refresh_care_needs()


func _refresh_resources() -> void:
	if num_wood:
		num_wood.text = str(GameState.wood)
	if num_stone:
		num_stone.text = str(GameState.stone)
	if num_food:
		num_food.text = str(GameState.food)
	if num_shards:
		num_shards.text = str(GameState.manashards)
	if num_essence:
		num_essence.text = str(GameState.essence)
	if resources_label:
		resources_label.text = ""


func _refresh_stage() -> void:
	var def: Dictionary = GameState.get_stage_def()
	stage_label.text = "%s  |  %s" % [
		str(def.get("display_name", GameState.stage_id)),
		ContentStrings.get_text("ascend_count_hud", {"count": GameState.ascensions}),
	]
	stage_label.visible = false


func _refresh_care_needs() -> void:
	var info: Dictionary = GameState.get_care_next_stage_info()
	care_title.text = "%s %s" % [
		ContentStrings.get_text("tree_menu_title"),
		ContentStrings.get_text("tree_care_title"),
	]
	var stage_name: String = str(GameState.get_stage_def().get("display_name", GameState.stage_id))
	var fruit_ready: bool = GameState.fruit_ready and not GameState.fruit_committed
	if fruit_ready:
		care_stage_label.text = ContentStrings.get_text("hud_stage_label_fruit_ready", {"stage": stage_name})
	else:
		care_stage_label.text = ContentStrings.get_text("hud_stage_label", {"stage": stage_name})
	var lines: PackedStringArray = info.get("needs_lines", PackedStringArray()) as PackedStringArray
	var header: String = str(info.get("needs_header", ""))
	var status: String = str(info.get("needs_status", ""))
	var body_parts: PackedStringArray = PackedStringArray()
	var is_ancient: bool = bool(info.get("is_ancient", false))
	if not is_ancient:
		var toward: String = str(info.get("title", ""))
		if toward != "":
			body_parts.append(toward)
		var next_id: String = str(info.get("next_stage_id", ""))
		if next_id != "":
			var grow_key: String = "tree_grow_cost_%s" % next_id
			var grow_line: String = _content_line(grow_key)
			if grow_line != "":
				body_parts.append(grow_line)
	if header != "":
		body_parts.append(header)
	for line: String in lines:
		body_parts.append(line)
	if status != "" and not is_ancient:
		body_parts.append(status)
	if not is_ancient:
		var grow_needs: Dictionary = info.get("needs", {}) as Dictionary
		if grow_needs.is_empty():
			grow_needs = GameState.get_next_stage_needs()
		body_parts.append(_format_grow_needs_sentence(
			int(grow_needs.get("fertilizer", 0)),
			int(grow_needs.get("essence", 0))
		))
		body_parts.append(ContentStrings.get_text("tree_grow_hint"))
	care_needs_label.text = "\n".join(body_parts)
	care_needs_label.visible = not fruit_ready
	var can_pay: bool = bool(info.get("can_pay", false))
	pay_button.visible = not is_ancient
	pay_button.text = ContentStrings.get_text("tree_grow")
	pay_button.disabled = not can_pay
	_refresh_grow_cost_icons(info, is_ancient)
	water_button.visible = not GameState.fruit_committed
	water_button.text = ContentStrings.get_text("tree_interact_water")
	harvest_fruit_button.visible = fruit_ready
	harvest_fruit_button.text = ContentStrings.get_text("fruit_ready_prompt")
	_refresh_forge_entry()
	fruit_ready_card.visible = fruit_ready
	precommit_hint.visible = fruit_ready
	if fruit_ready:
		## Early harvest stays. tree_water_ancient_note stays in the table and is not shown:
		## "The Fruit waits when you are ready" fights the timed fall.
		precommit_hint.text = ContentStrings.get_text("tree_ancient_care_hint")


func show_care_menu() -> void:
	if welcome_panel.visible:
		return
	if _pause_menu and _pause_menu.is_open():
		return
	if GameState.fruit_committed:
		show_ascension_shop()
		return
	close_backpack()
	close_character_sheet()
	hide_ascension_shop()
	hide_fruit_confirm()
	hide_ancient_grow_confirm()
	_confirm_pay = false
	care_panel.visible = true
	water_button.text = ContentStrings.get_text("tree_interact_water")
	_refresh_care_needs()
	GameAudio.play_ui_open()


func open_fruit_from_care() -> void:
	open_fruit_confirm()


func hide_care_menu() -> void:
	_care_hidden_for_forge = false
	if care_panel.visible:
		GameAudio.play_ui_close()
	care_panel.visible = false
	_confirm_pay = false
	hide_forge_popup()


## Legacy entry: pre-commit never opens the shop; pending reopen the paused shop.
func show_prestige_menu(_focus_ascend: bool = false) -> void:
	if GameState.fruit_harvested_pending_ascend:
		show_ascension_shop()
		return
	show_care_menu()


func hide_prestige_menu() -> void:
	hide_ascension_shop()


func _ensure_wisp_counter() -> void:
	var counter := Label.new()
	counter.name = "WispCounter"
	counter.position = Vector2(780, 14)
	counter.size = Vector2(180, 28)
	counter.add_theme_font_size_override("font_size", 15)
	counter.add_theme_color_override("font_color", Color(0.86, 0.95, 0.9, 1))
	add_child(counter)
	if not GameState.wisps_changed.is_connected(_refresh_wisp_counter):
		GameState.wisps_changed.connect(_refresh_wisp_counter)
	_refresh_wisp_counter()


func _set_wisp_counter_visible(show_counter: bool) -> void:
	var counter: CanvasItem = get_node_or_null("WispCounter") as CanvasItem
	if counter:
		counter.visible = show_counter


func _refresh_wisp_counter() -> void:
	var counter: Label = get_node_or_null("WispCounter") as Label
	if counter == null:
		return
	if is_character_open():
		counter.visible = false
	var text: String = "Wisps: %d" % GameState.wisp_count
	if has_node("/root/ForgeJobs"):
		text = ForgeJobs.copy_text("wisp_counter", {"count": GameState.wisp_count})
	counter.text = text


func _ensure_forge_controls() -> void:
	if care_panel == null:
		return
	forge_button = Button.new()
	forge_button.name = "ForgeButton"
	forge_button.position = Vector2(16, 304)
	forge_button.size = Vector2(488, 36)
	care_panel.add_child(forge_button)
	forge_button.pressed.connect(_on_enter_forge)
	_forge_popup = Panel.new()
	_forge_popup.name = "ForgePopup"
	_forge_popup.visible = false
	_forge_popup.anchor_left = 0.5
	_forge_popup.anchor_top = 0.5
	_forge_popup.anchor_right = 0.5
	_forge_popup.anchor_bottom = 0.5
	_forge_popup.offset_left = -210.0
	_forge_popup.offset_top = -78.0
	_forge_popup.offset_right = 210.0
	_forge_popup.offset_bottom = 72.0
	_forge_popup.mouse_filter = Control.MOUSE_FILTER_STOP
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.13, 0.11, 1)
	sb.border_color = Color(0.45, 0.58, 0.48, 1)
	sb.set_border_width_all(2)
	sb.set_content_margin_all(12)
	_forge_popup.add_theme_stylebox_override("panel", sb)
	add_child(_forge_popup)
	_forge_popup_body = Label.new()
	_forge_popup_body.name = "Body"
	_forge_popup_body.position = Vector2(16, 12)
	_forge_popup_body.size = Vector2(388, 78)
	_forge_popup_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_forge_popup_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_forge_popup_body.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_forge_popup_body.add_theme_font_size_override("font_size", 16)
	_forge_popup_body.add_theme_color_override("font_color", Color(0.88, 0.92, 0.84, 1))
	_forge_popup.add_child(_forge_popup_body)
	var close := Button.new()
	close.name = "Close"
	close.anchor_left = 0.5
	close.anchor_right = 0.5
	close.anchor_top = 1.0
	close.anchor_bottom = 1.0
	close.offset_left = -70.0
	close.offset_right = 70.0
	close.offset_top = -44.0
	close.offset_bottom = -10.0
	close.text = ContentStrings.get_text("btn_close")
	close.pressed.connect(hide_forge_popup)
	_forge_popup.add_child(close)
	_refresh_forge_entry()


func _refresh_forge_entry() -> void:
	if forge_button == null:
		return
	var stage: String = String(GameState.stage_id)
	var forge_stage: bool = stage == "elder" or stage == "ancient"
	forge_button.visible = forge_stage
	if not forge_stage:
		return
	forge_button.text = ContentStrings.get_text("forge_enter")
	forge_button.disabled = false
	var owns_key: bool = GameState.forge_key
	if has_node("/root/ForgeJobs"):
		owns_key = ForgeJobs.owns_forge_key()
	if owns_key:
		forge_button.modulate = Color.WHITE
	else:
		forge_button.modulate = Color(0.45, 0.47, 0.44, 1)


func is_forge_entry_visible() -> bool:
	return forge_button != null and forge_button.visible


func is_forge_entry_gray() -> bool:
	return forge_button != null and forge_button.visible and forge_button.modulate.r < 0.6


func is_forge_popup_open() -> bool:
	return _forge_popup != null and _forge_popup.visible


func forge_popup_text() -> String:
	if _forge_popup_body == null:
		return ""
	return _forge_popup_body.text


func open_forge_entry() -> String:
	var owns_key: bool = GameState.forge_key
	if has_node("/root/ForgeJobs"):
		owns_key = ForgeJobs.owns_forge_key()
	if not owns_key:
		var msg: String = ContentStrings.get_text("forge_no_key")
		if _forge_popup_body:
			_forge_popup_body.text = msg
		if care_panel and care_panel.visible:
			_care_hidden_for_forge = true
			care_panel.visible = false
		if _forge_popup:
			_forge_popup.visible = true
		GameAudio.play_ui_confirm()
		return msg
	if has_node("/root/ForgeJobs") and ForgeJobs.can_enter_forge():
		return ForgeJobs.try_enter_forge()
	return "denied"


func hide_forge_popup() -> void:
	var was_open := _forge_popup != null and _forge_popup.visible
	if _forge_popup:
		_forge_popup.visible = false
	if was_open:
		GameAudio.play_ui_close()
	if _care_hidden_for_forge:
		_care_hidden_for_forge = false
		if care_panel:
			care_panel.visible = true


func _on_enter_forge() -> void:
	open_forge_entry()


func is_shop_list_visible() -> bool:
	return ascension_panel.visible and upgrade_list.get_child_count() > 0


func is_ascension_shop_open() -> bool:
	return ascension_panel.visible


func shop_list_clears_footer() -> bool:
	if not is_inside_tree() or not ascension_panel.visible:
		return false
	var scroll_rect: Rect2 = shop_scroll.get_global_rect()
	var footer_rect: Rect2 = shop_footer.get_global_rect()
	return scroll_rect.end.y <= footer_rect.position.y + 2.0


func get_shop_layout_metrics() -> Dictionary:
	return {
		"size": ascension_panel.size,
		"header_h": shop_header.size.y,
		"footer_h": shop_footer.size.y,
		"row_h": SHOP_ROW_H,
		"pad": SHOP_PAD,
		"min_w": SHOP_MIN_SIZE.x,
		"min_h": SHOP_MIN_SIZE.y,
		"preferred_w": SHOP_SIZE.x,
		"preferred_h": SHOP_SIZE.y,
	}


func shop_has_harvest_button() -> bool:
	return shop_footer.get_node_or_null("HarvestButton") != null or ascension_panel.get_node_or_null("HarvestButton") != null


func is_care_open() -> bool:
	return care_panel.visible


func care_embeds_shop_rows() -> bool:
	## Art v0.1.12: care must never host Buy list / shop scroll / Ascend.
	if care_panel.find_child("UpgradeList", true, false) != null:
		return true
	if care_panel.find_child("ShopScroll", true, false) != null:
		return true
	if care_panel.find_child("AscendButton", true, false) != null:
		return true
	if care_panel.find_child("Footer", true, false) != null:
		return true
	return false


func get_care_layout_metrics() -> Dictionary:
	return {
		"size": care_panel.size,
		"header_h": care_header.size.y,
		"action_band_h": care_action_band.size.y,
		"preferred_w": CARE_SIZE.x,
		"preferred_h": CARE_SIZE.y,
	}


func get_fruit_confirm_step() -> int:
	return _fruit_confirm_step


func show_ascension_shop() -> void:
	if welcome_panel.visible:
		return
	if _pause_menu and _pause_menu.is_open():
		return
	if not GameState.fruit_harvested_pending_ascend:
		return
	backpack_panel.visible = false
	close_character_sheet()
	hide_care_menu()
	hide_fruit_confirm()
	_hold_world_for_ascension()
	_confirm_ascend = false
	_highlight_ascend = true
	ascension_panel.visible = true
	GameAudio.play_ui_open()
	_rebuild_upgrades()
	_refresh_ascension_copy()
	_refresh_reopen_button()
	_refresh_frozen_banner()
	_refresh_dim()
	_apply_ascend_highlight()


func hide_ascension_shop() -> void:
	if ascension_panel.visible:
		GameAudio.play_ui_close()
	ascension_panel.visible = false
	_confirm_ascend = false
	_highlight_ascend = false
	_clear_ascend_highlight()
	_refresh_reopen_button()
	_refresh_frozen_banner()
	_refresh_dim()


func _on_shop_close() -> void:
	## Close cancels the harvest lock. Play resumes; Fruit can be harvested again.
	## The run locks only when Ascend actually commits.
	var cancelled_commit: bool = GameState.fruit_committed and not GameState.ancient_frozen
	if cancelled_commit:
		GameState.cancel_fruit_commit()
	hide_ascension_shop()
	_release_world_if_allowed()
	_refresh_all()
	if cancelled_commit:
		SaveService.save_game()


func _refresh_reopen_button() -> void:
	if ascension_reopen_button == null:
		return
	ascension_reopen_button.visible = (
		GameState.fruit_harvested_pending_ascend
		and not GameState.ancient_frozen
		and not ascension_panel.visible
	)
	ascension_reopen_button.text = ""
	ascension_reopen_button.tooltip_text = ContentStrings.get_text("ascension_paused_title")


func _sync_ascension_from_state() -> void:
	hide_fruit_confirm()
	if GameState.ancient_frozen:
		if ascension_panel.visible:
			_hold_world_for_ascension()
		else:
			hide_ascension_shop()
			_release_world_if_allowed()
		_refresh_frozen_banner()
		_refresh_nav_button()
		return
	if GameState.fruit_harvested_pending_ascend:
		_hold_world_for_ascension()
		if not welcome_panel.visible:
			show_ascension_shop()
		else:
			_refresh_reopen_button()
	else:
		hide_ascension_shop()
		_release_world_if_allowed()


func _hold_world_for_ascension() -> void:
	var tree: SceneTree = get_tree()
	if tree:
		tree.paused = true
	## Hub bed keeps looping while the shop is paused — never stop mus_hub_forest.
	GameAudio.ensure_hub_playing()


func _release_world_if_allowed() -> void:
	if GameState.fruit_harvested_pending_ascend and not GameState.ancient_frozen:
		return
	if is_backpack_open():
		return
	if is_bench_open():
		return
	if is_character_open():
		return
	if _pause_menu and _pause_menu.is_open():
		return
	var tree: SceneTree = get_tree()
	if tree:
		tree.paused = false


func _cancel_world_channels() -> void:
	var tree: SceneTree = get_tree()
	if tree == null:
		return
	var keepers: Array[Node] = tree.get_nodes_in_group("keeper")
	if keepers.is_empty():
		return
	var k: Node = keepers[0]
	if k.has_method("cancel_channel"):
		k.call("cancel_channel", false)


func _on_fruit_ready_changed(_ready: bool) -> void:
	## Do not auto-open shop. Pre-commit care still offers Water + Fruit CTA.
	_refresh_ascension_copy()
	_refresh_reopen_button()
	if care_panel.visible:
		_refresh_care_needs()


func open_fruit_confirm() -> void:
	if welcome_panel.visible:
		return
	if _pause_menu and _pause_menu.is_open():
		return
	if GameState.fruit_harvested_pending_ascend:
		show_ascension_shop()
		return
	if not GameState.fruit_ready:
		return
	care_panel.visible = false
	_confirm_pay = false
	_fruit_confirm_step = 1
	_show_fruit_confirm_step()
	GameAudio.play_ui_confirm()


func confirm_fruit_step() -> void:
	if _fruit_confirm_step == 1:
		_fruit_confirm_step = 2
		_show_fruit_confirm_step()
		GameAudio.play_ui_confirm()
		return
	if _fruit_confirm_step != 2:
		return
	_commit_primordial_fruit()


func cancel_fruit_confirm() -> void:
	## Step 2 "Go back" returns to intent. Step 1 "Keep watering" closes without commit.
	if _fruit_confirm_step == 2:
		_fruit_confirm_step = 1
		_show_fruit_confirm_step()
		GameAudio.play_ui_close()
		return
	hide_fruit_confirm()
	GameAudio.play_ui_close()
	if GameState.fruit_ready and not GameState.fruit_harvested_pending_ascend:
		if not care_panel.visible:
			show_care_menu()


func hide_fruit_confirm() -> void:
	fruit_confirm_panel.visible = false
	_fruit_confirm_step = 0
	_refresh_dim()


func _show_fruit_confirm_step() -> void:
	## Two-step Content keys. Modal never includes Buy list or Ascend.
	fruit_confirm_panel.visible = true
	if _fruit_confirm_step == 1:
		fruit_confirm_title.text = ContentStrings.get_text("fruit_confirm_step1_title")
		fruit_confirm_body.text = ContentStrings.get_text("fruit_confirm_step1")
		fruit_confirm_yes.text = ContentStrings.get_text("fruit_confirm_step1_yes")
		fruit_confirm_no.text = ContentStrings.get_text("fruit_confirm_step1_no")
		_show_toast(ContentStrings.get_text("fruit_confirm_step1"))
	else:
		fruit_confirm_title.text = ContentStrings.get_text("fruit_confirm_step2_title")
		fruit_confirm_body.text = ContentStrings.get_text("fruit_confirm_step2")
		fruit_confirm_yes.text = ContentStrings.get_text("fruit_confirm_step2_yes")
		fruit_confirm_no.text = ContentStrings.get_text("fruit_confirm_step2_no")
		_show_toast(ContentStrings.get_text("fruit_confirm_step2"))
	_refresh_dim()


func _commit_primordial_fruit() -> void:
	if not GameState.fruit_ready:
		hide_fruit_confirm()
		return
	## SYSTEMS v0.3.4: no Essence bank on commit — open shop only.
	var committed: int = GameState.harvest_fruit()
	if committed <= 0:
		hide_fruit_confirm()
		return
	_cancel_world_channels()
	hide_fruit_confirm()
	hide_care_menu()
	GameAudio.play_fruit_harvest()
	_show_toast("%s\n%s" % [
		ContentStrings.get_text("fruit_harvest_toast"),
		ContentStrings.get_text("fruit_flow_hint"),
	])
	_hold_world_for_ascension()
	show_ascension_shop()
	SaveService.save_game()


func _on_water() -> void:
	## Starts water channel on Keeper; hide menu so channel can tick.
	if GameState.fruit_harvested_pending_ascend:
		show_ascension_shop()
		return
	if _manatree:
		hide_care_menu()
		_manatree.do_water()
	_refresh_all()


func _format_grow_needs_sentence(fert_need: int, ess_need: int) -> String:
	## Content uses {count} twice; fill Fertilizer then Essence.
	var raw: String = ContentStrings.get_text("tree_grow_needs_fertilizer")
	var first: int = raw.find("{count}")
	if first >= 0:
		raw = raw.substr(0, first) + str(fert_need) + raw.substr(first + 7)
	var second: int = raw.find("{count}")
	if second >= 0:
		raw = raw.substr(0, second) + str(ess_need) + raw.substr(second + 7)
	return raw


func _refresh_grow_cost_icons(info: Dictionary, is_ancient: bool) -> void:
	if care_grow_costs == null:
		return
	care_grow_costs.visible = not is_ancient and not bool(info.get("ready_for_fruit", false))
	if not care_grow_costs.visible:
		return
	var needs: Dictionary = info.get("needs", {}) as Dictionary
	if needs.is_empty():
		needs = GameState.get_next_stage_needs()
	var fert_need: int = int(needs.get("fertilizer", 0))
	var ess_need: int = int(needs.get("essence", 0))
	var fert_have: int = GameState.get_need_have(&"fertilizer")
	var ess_have: int = GameState.get_need_have(&"essence")
	if grow_fert_need:
		var fert_key: String = "tree_grow_cost_fertilizer" if fert_have < fert_need else "tree_grow_cost_fertilizer_met"
		grow_fert_need.text = "%d/%d" % [fert_have, fert_need]
		grow_fert_need.tooltip_text = ContentStrings.get_text(fert_key, {
			"item": ContentStrings.get_text("fertilizer_name"),
			"have": fert_have,
			"need": fert_need,
		})
	if grow_ess_need:
		var ess_key: String = "tree_grow_cost_essence" if ess_have < ess_need else "tree_grow_cost_essence_met"
		grow_ess_need.text = "%d/%d" % [ess_have, ess_need]
		grow_ess_need.tooltip_text = ContentStrings.get_text(ess_key, {
			"item": ContentStrings.get_text("hud_essence"),
			"have": ess_have,
			"need": ess_need,
		})


func _on_pay() -> void:
	## One-click Grow, except Ancient, which asks first. try_grow_stage itself stays direct.
	if not GameState.can_grow_stage():
		GameAudio.play_tree_deny()
		_refresh_care_needs()
		return
	if String(GameState.get_next_stage_id()) == "ancient":
		open_ancient_grow_confirm()
		return
	_commit_grow()


func _commit_grow() -> void:
	_confirm_pay = false
	var result: String = "cant_afford"
	if _manatree:
		result = _manatree.do_pay_stage()
	else:
		result = GameState.try_grow_stage()
	if result == "ok":
		SaveService.save_game()
	_refresh_all()


func _ensure_ancient_hud() -> void:
	_ancient_countdown_bg = ColorRect.new()
	_ancient_countdown_bg.name = "AncientCountdownBg"
	_ancient_countdown_bg.position = Vector2(390, 64)
	_ancient_countdown_bg.size = Vector2(500, 40)
	_ancient_countdown_bg.color = Color(0.05, 0.08, 0.06, 0.88)
	_ancient_countdown_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ancient_countdown_bg.visible = false
	add_child(_ancient_countdown_bg)
	_ancient_countdown = Label.new()
	_ancient_countdown.name = "AncientCountdown"
	_ancient_countdown.position = Vector2(390, 64)
	_ancient_countdown.size = Vector2(500, 40)
	_ancient_countdown.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_ancient_countdown.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_ancient_countdown.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ancient_countdown.add_theme_font_size_override("font_size", 22)
	_ancient_countdown.add_theme_color_override("font_color", GOLD)
	_ancient_countdown.visible = false
	add_child(_ancient_countdown)
	_ancient_confirm = Panel.new()
	_ancient_confirm.name = "AncientGrowConfirm"
	_ancient_confirm.position = Vector2(280, 150)
	_ancient_confirm.size = Vector2(720, 300)
	_ancient_confirm.visible = false
	_ancient_confirm.z_index = 40
	_ancient_confirm.add_theme_stylebox_override("panel", _wood_style())
	add_child(_ancient_confirm)
	var title := Label.new()
	title.name = "Title"
	title.position = Vector2(24, 16)
	title.size = Vector2(672, 36)
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", GOLD)
	_ancient_confirm.add_child(title)
	var body := Label.new()
	body.name = "Body"
	body.position = Vector2(24, 64)
	body.size = Vector2(672, 140)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_theme_font_size_override("font_size", 18)
	body.add_theme_color_override("font_color", Color(0.93, 0.94, 0.86, 1))
	_ancient_confirm.add_child(body)
	var yes := Button.new()
	yes.name = "Yes"
	yes.position = Vector2(24, 220)
	yes.size = Vector2(320, 52)
	_apply_button_chrome(yes, LEAF, GOLD)
	yes.pressed.connect(_on_ancient_grow_yes)
	_ancient_confirm.add_child(yes)
	var no := Button.new()
	no.name = "No"
	no.position = Vector2(376, 220)
	no.size = Vector2(320, 52)
	_apply_button_chrome(no, Color(0.18, 0.14, 0.10, 1.0), GOLD)
	no.pressed.connect(hide_ancient_grow_confirm)
	_ancient_confirm.add_child(no)


func _ensure_frozen_banner() -> void:
	_frozen_button = Button.new()
	_frozen_button.name = "AscendFrozenButton"
	_frozen_button.position = Vector2(430, 250)
	_frozen_button.size = Vector2(420, 64)
	_frozen_button.add_theme_font_size_override("font_size", 28)
	_apply_button_chrome(_frozen_button, LEAF, GOLD)
	_frozen_button.pressed.connect(show_ascension_shop)
	_frozen_button.visible = false
	add_child(_frozen_button)
	_frozen_hint = Label.new()
	_frozen_hint.name = "AscendFrozenHint"
	_frozen_hint.position = Vector2(360, 322)
	_frozen_hint.size = Vector2(560, 64)
	_frozen_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_frozen_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_frozen_hint.add_theme_font_size_override("font_size", 16)
	_frozen_hint.add_theme_color_override("font_color", GOLD)
	_frozen_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_frozen_hint.visible = false
	add_child(_frozen_hint)


func _refresh_frozen_banner() -> void:
	if _frozen_button == null:
		return
	var show_banner: bool = GameState.ancient_frozen and not ascension_panel.visible
	_frozen_button.visible = show_banner
	_frozen_button.text = ContentStrings.get_text("ascend_frozen_button")
	if _frozen_hint:
		_frozen_hint.visible = show_banner
		_frozen_hint.text = ContentStrings.get_text("ascend_frozen_hint")


func _ensure_nav_button() -> void:
	_nav_button = Button.new()
	_nav_button.name = "HubForgeNav"
	_nav_button.position = Vector2(16, 64)
	_nav_button.size = Vector2(180, 36)
	_apply_button_chrome(_nav_button, Color(0.16, 0.18, 0.14, 1.0), GOLD)
	_nav_button.pressed.connect(_on_nav_pressed)
	_nav_button.visible = false
	add_child(_nav_button)


func _refresh_nav_button() -> void:
	if _nav_button == null or not has_node("/root/ForgeJobs"):
		return
	var in_battle: bool = has_node("/root/EchoChamber") and EchoChamber.in_battle
	var show_nav: bool = GameState.forge_visited and not in_battle and not GameState.is_world_frozen()
	_nav_button.visible = show_nav
	if not show_nav:
		return
	var in_forge: bool = ForgeJobs.in_forge_scene()
	_nav_button.text = ContentStrings.get_text("nav_to_clearing" if in_forge else "nav_to_forge")


func _on_nav_pressed() -> void:
	if not has_node("/root/ForgeJobs"):
		return
	if ForgeJobs.in_forge_scene():
		ForgeJobs.exit_forge()
		return
	ForgeJobs.travel_to_forge()


func _refresh_ancient_countdown() -> void:
	if _ancient_countdown == null:
		return
	var show_timer: bool = (
		GameState.stage_id == &"ancient"
		and not GameState.fruit_committed
		and GameState.ancient_remaining_sec > 0.0
	)
	_ancient_countdown.visible = show_timer
	if _ancient_countdown_bg:
		_ancient_countdown_bg.visible = show_timer
	if not show_timer:
		return
	var total: int = int(ceil(GameState.ancient_remaining_sec))
	var label: String = "%d:%02d" % [int(total / 60), total % 60]
	_ancient_countdown.text = ContentStrings.get_text("tree_ancient_timer_label", {"time": label})


func open_ancient_grow_confirm() -> void:
	if _ancient_confirm == null:
		return
	var title: Label = _ancient_confirm.get_node("Title") as Label
	var body: Label = _ancient_confirm.get_node("Body") as Label
	var yes: Button = _ancient_confirm.get_node("Yes") as Button
	var no: Button = _ancient_confirm.get_node("No") as Button
	var minutes: int = GameState.ancient_duration_minutes()
	title.text = ContentStrings.get_text("tree_grow_ancient_confirm_title")
	body.text = ContentStrings.get_text("tree_grow_ancient_confirm_body", {"minutes": minutes})
	yes.text = ContentStrings.get_text("tree_grow_ancient_confirm_yes")
	no.text = ContentStrings.get_text("tree_grow_ancient_confirm_no")
	_ancient_confirm.visible = true
	_refresh_dim()
	GameAudio.play_ui_confirm()


func hide_ancient_grow_confirm() -> void:
	if _ancient_confirm == null or not _ancient_confirm.visible:
		return
	_ancient_confirm.visible = false
	_refresh_dim()
	GameAudio.play_ui_close()


func _on_ancient_grow_yes() -> void:
	if _ancient_confirm:
		_ancient_confirm.visible = false
	_refresh_dim()
	_commit_grow()


func _on_ancient_expired() -> void:
	## Timer hit 0. Fruit is already committed. Open the shop with no harvest confirm.
	_cancel_world_channels()
	hide_fruit_confirm()
	hide_ancient_grow_confirm()
	hide_care_menu()
	GameAudio.play_fruit_harvest()
	_show_toast("%s\n%s" % [
		ContentStrings.get_text("fruit_harvest_toast"),
		ContentStrings.get_text("fruit_flow_hint"),
	])
	_hold_world_for_ascension()
	show_ascension_shop()
	SaveService.save_game()


func is_backpack_open() -> bool:
	return backpack_panel != null and backpack_panel.visible


func is_character_open() -> bool:
	return _sheet != null and _sheet.visible


func toggle_character_sheet() -> void:
	if is_character_open():
		close_character_sheet()
	else:
		open_character_sheet()


func open_character_sheet() -> void:
	if EchoChamber.in_battle:
		return
	if welcome_panel.visible:
		return
	if _pause_menu and _pause_menu.is_open():
		return
	if is_character_open():
		return
	if is_backpack_open():
		close_backpack()
	if is_bench_open():
		close_bench()
	hide_care_menu()
	hide_fruit_confirm()
	if _sheet == null:
		return
	var actor: String = "elaia" if GameState.selected_hero_id() == "elaia" else "keeper"
	_sheet.open_sheet(actor)
	if _party_info:
		_party_info.visible = false
	_set_wisp_counter_visible(false)
	if not GameState.fruit_committed:
		_hold_world_for_backpack()
	GameAudio.play_ui_open()


func close_character_sheet() -> void:
	if _sheet == null or not _sheet.visible:
		return
	_sheet.close_sheet()
	_set_wisp_counter_visible(true)
	_refresh_party_bar()
	GameAudio.play_ui_close()
	_release_world_if_allowed()


func is_elaia_join_open() -> bool:
	return _join_band != null and _join_band.visible


func maybe_show_elaia_join() -> void:
	## Once, in the Clearing, after she has joined. Migrated saves set the flag and skip this.
	if not GameState.elaia_join_pending():
		return
	if welcome_panel != null and welcome_panel.visible:
		return
	if is_elaia_join_open():
		return
	var scene: Node = get_tree().current_scene if get_tree() else null
	if scene == null or not scene.is_in_group("main_root"):
		return
	_ensure_join_band()
	_join_index = 0
	_show_join_line()
	_join_band.visible = true


func _ensure_join_band() -> void:
	if _join_band != null:
		return
	_join_band = Panel.new()
	_join_band.name = "ElaiaJoinBand"
	_join_band.anchor_left = 0.5
	_join_band.anchor_right = 0.5
	_join_band.anchor_top = 1.0
	_join_band.anchor_bottom = 1.0
	_join_band.offset_left = -260.0
	_join_band.offset_right = 260.0
	_join_band.offset_top = -196.0
	_join_band.offset_bottom = -16.0
	_join_band.mouse_filter = Control.MOUSE_FILTER_STOP
	_join_band.z_index = 30
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.09, 0.15, 0.13, 0.94)
	style.set_corner_radius_all(2)
	_join_band.add_theme_stylebox_override("panel", style)
	_join_band.gui_input.connect(_on_join_band_input)
	_join_name = Label.new()
	_join_name.name = "Speaker"
	_join_name.position = Vector2(16, 10)
	_join_name.size = Vector2(488, 22)
	_join_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_join_name.add_theme_font_size_override("font_size", 15)
	_join_name.add_theme_color_override("font_color", Color(0.88, 0.92, 0.86))
	_join_band.add_child(_join_name)
	_join_line = Label.new()
	_join_line.name = "Line"
	_join_line.position = Vector2(16, 36)
	_join_line.size = Vector2(488, 120)
	_join_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_join_line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_join_line.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_join_line.add_theme_font_size_override("font_size", 12)
	_join_line.add_theme_color_override("font_color", Color(0.86, 0.91, 0.84))
	_join_band.add_child(_join_line)
	add_child(_join_band)
	_join_band.visible = false


func _show_join_line() -> void:
	if _join_name == null or _join_line == null:
		return
	_join_name.text = ContentStrings.get_text("echo_elaia_name")
	var key: String = "elaia_join_%d" % (_join_index + 1)
	_join_line.text = ContentStrings.get_text(key)


func _on_join_band_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton):
		return
	var mb: InputEventMouseButton = event
	if not mb.pressed or mb.button_index != MOUSE_BUTTON_LEFT:
		return
	_advance_join_line()


func _advance_join_line() -> void:
	if _join_band == null or not _join_band.visible:
		return
	_join_index += 1
	if _join_index < 5:
		_show_join_line()
		return
	_join_band.visible = false
	GameState.elaia_join_seen = true
	_show_toast(ContentStrings.get_text("elaia_join_toast"))
	if has_node("/root/SaveService"):
		SaveService.save_game()


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey):
		return
	var key: InputEventKey = event
	if not key.pressed or key.echo:
		return
	var sheet_key: bool = key.keycode == KEY_C or key.is_action_pressed("character_sheet")
	if not sheet_key or key.ctrl_pressed or key.alt_pressed or key.meta_pressed:
		return
	if welcome_panel.visible:
		return
	if _pause_menu and _pause_menu.is_open():
		return
	toggle_character_sheet()
	get_viewport().set_input_as_handled()


func toggle_backpack() -> void:
	if is_backpack_open():
		close_backpack()
	else:
		open_backpack()


func open_backpack() -> void:
	if EchoChamber.in_battle:
		return
	if welcome_panel.visible:
		return
	if GameState.fruit_committed:
		show_ascension_shop()
		return
	if _pause_menu and _pause_menu.is_open():
		return
	close_character_sheet()
	close_bench()
	hide_care_menu()
	hide_fruit_confirm()
	hide_ascension_shop()
	backpack_panel.visible = true
	_hold_world_for_backpack()
	_rebuild_backpack()
	_refresh_dim()
	GameAudio.play_ui_open()


func close_backpack() -> void:
	if backpack_panel.visible:
		GameAudio.play_ui_close()
	backpack_panel.visible = false
	_release_world_if_allowed()
	_refresh_dim()


func _hold_world_for_backpack() -> void:
	var tree: SceneTree = get_tree()
	if tree:
		tree.paused = true
	GameAudio.ensure_hub_playing()


func _on_backpack_dim_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			if is_bench_open():
				close_bench()
			else:
				close_backpack()


func _on_backpack_inventory(_item_id: StringName, _amount: int) -> void:
	if is_backpack_open():
		_rebuild_backpack()
	if is_bench_open():
		_rebuild_bench()
	if care_panel.visible:
		_refresh_care_needs()


func _on_backpack_tab(tab_id: String) -> void:
	_backpack_tab = tab_id
	_rebuild_backpack()


func _apply_filter_labels() -> void:
	backpack_tab_all.text = _filter_label("all")
	backpack_tab_raw.text = _filter_label("raw")
	backpack_tab_refined.text = _filter_label("refined")
	backpack_tab_tools.text = _filter_label("tools")
	backpack_tab_weapons.text = _filter_label("weapons")
	backpack_tab_relics.text = _filter_label("relics")


func _filter_label(filter_id: String) -> String:
	match filter_id:
		"all":
			return ContentStrings.get_text("backpack_tab_all")
		"raw":
			return ContentStrings.get_text("backpack_tab_raw")
		"refined":
			return ContentStrings.get_text("backpack_tab_refined")
		"tools":
			return ContentStrings.get_text("backpack_tab_tools")
		"weapons":
			return ContentStrings.get_text("backpack_tab_weapons")
		"relics":
			return ContentStrings.get_text("backpack_tab_relics")
		_:
			return filter_id


func _rebuild_backpack() -> void:
	backpack_title.text = ContentStrings.get_text("backpack_title")
	inventory_title.text = ContentStrings.get_text("backpack_hint")
	_apply_filter_labels()
	for child: Node in inventory_list.get_children():
		child.queue_free()
	var rows: Array[Dictionary] = _filtered_rows(_backpack_tab)
	for row: Dictionary in rows:
		inventory_list.add_child(_make_item_row(row, false))
	if rows.is_empty():
		var empty := Label.new()
		empty.text = ContentStrings.get_text("backpack_empty")
		empty.add_theme_font_size_override("font_size", 12)
		empty.add_theme_color_override("font_color", Color(0.70, 0.64, 0.52, 1.0))
		empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		inventory_list.add_child(empty)


func filter_owned_counts() -> Dictionary:
	var counts: Dictionary = {}
	var filters: PackedStringArray = PackedStringArray(["all", "raw", "refined", "tools", "weapons", "relics"])
	if has_node("/root/ForgeJobs"):
		filters = ForgeJobs.backpack_filters()
	for filter_id: String in filters:
		counts[filter_id] = _filtered_rows(filter_id).size()
	return counts


func _filtered_rows(filter_id: String) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	var resources: Array[String] = ["wood", "stone", "food", "manashards", "essence"]
	for resource_id: String in resources:
		var count: int = int(GameState.get(resource_id))
		if count <= 0 or not Backpack.matches_filter(resource_id, filter_id):
			continue
		rows.append({
			"id": resource_id,
			"count": count,
			"display_name": ContentStrings.get_text("hud_%s" % resource_id),
			"unique": false,
		})
	for stack: Dictionary in Backpack.stacked_items():
		var stack_id: String = str(stack.get("id", ""))
		if Backpack.matches_filter(stack_id, filter_id):
			rows.append(stack)
	var gear_counts: Dictionary = {}
	for entry: Dictionary in Equipment.list_unequipped():
		var gear_id: String = str(entry.get("id", ""))
		gear_counts[gear_id] = int(entry.get("count", 0))
	for slot_id: String in ["weapon", "relic"]:
		var equipped_id: String = Equipment.equipped_id(slot_id)
		if equipped_id != "":
			gear_counts[equipped_id] = int(gear_counts.get(equipped_id, 0)) + 1
	for gear_key: Variant in gear_counts.keys():
		var iid: String = str(gear_key)
		if not Backpack.matches_filter(iid, filter_id):
			continue
		rows.append({
			"id": iid,
			"count": int(gear_counts[gear_key]),
			"display_name": Equipment.item_display_name(iid),
			"unique": Equipment.is_unique_item(iid),
		})
	return rows


func is_bench_open() -> bool:
	return bench_panel != null and bench_panel.visible


func open_bench_panel() -> void:
	if EchoChamber.in_battle or welcome_panel.visible:
		return
	if _pause_menu and _pause_menu.is_open():
		return
	close_backpack()
	close_character_sheet()
	hide_care_menu()
	hide_fruit_confirm()
	hide_ascension_shop()
	bench_panel.visible = true
	_hold_world_for_backpack()
	_rebuild_bench()
	_refresh_dim()


func close_bench() -> void:
	if bench_panel == null or not bench_panel.visible:
		return
	bench_panel.visible = false
	GameAudio.play_ui_close()
	_release_world_if_allowed()
	_refresh_dim()


func _rebuild_bench() -> void:
	bench_title.text = ContentStrings.get_text("bench_title")
	bench_prompt.text = "%s  ·  %s" % [
		ContentStrings.get_text("handcraft_title"),
		ContentStrings.get_text("tool_never_gate"),
	]
	for child: Node in craft_list.get_children():
		child.queue_free()
	for entry: Variant in Backpack.recipes_data:
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var rec: Dictionary = entry
		craft_list.add_child(_make_craft_row(str(rec.get("id", "")), false))
	for gear_entry: Variant in Equipment.recipes_data:
		if typeof(gear_entry) != TYPE_DICTIONARY:
			continue
		var gear_rec: Dictionary = gear_entry
		var gear_id: String = str(gear_rec.get("id", ""))
		if Equipment.recipe_station(gear_id) == "anvil":
			continue
		craft_list.add_child(_make_craft_row(gear_id, true))


func _placeholder_icon(color: Color) -> ColorRect:
	var icon := ColorRect.new()
	icon.custom_minimum_size = Vector2(32, 32)
	icon.color = color
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return icon


func _make_item_row(stack: Dictionary, _craft: bool) -> Control:
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(0, BACKPACK_ROW_H)
	row.add_theme_constant_override("separation", 8)
	var stack_id: String = str(stack.get("id", ""))
	var stack_name: String = str(stack.get("display_name", stack_id))
	row.add_child(_make_item_icon(stack_id, stack_name))
	var lbl := Label.new()
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var count: int = int(stack.get("count", 0))
	var name: String = str(stack.get("display_name", ""))
	if str(stack.get("id", "")) == "stone_watering_can":
		lbl.text = "%s  ·  %s" % [name, ContentStrings.get_text("tool_water_hint")]
	elif bool(stack.get("unique", false)):
		lbl.text = "%s  ·  %s" % [name, ContentStrings.get_text("tool_owned_hint")]
	else:
		lbl.text = "%s  ×%d" % [name, count]
	lbl.add_theme_font_size_override("font_size", 12)
	lbl.add_theme_color_override("font_color", Color(0.92, 0.86, 0.72, 1.0))
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var examine: String = _item_examine_text(str(stack.get("id", "")))
	if examine != "":
		row.tooltip_text = examine
		lbl.tooltip_text = examine
	row.add_child(lbl)
	return row


func _make_craft_row(recipe_id: String, equipment_out: bool = false) -> Control:
	var def: Dictionary = Equipment.get_recipe_def(recipe_id) if equipment_out else Backpack.get_recipe_def(recipe_id)
	var out_id: String = str(def.get("output_id", recipe_id))
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(0, BACKPACK_ROW_H + 8.0)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 8)
	row.clip_contents = true
	var craft_name: String = Equipment.item_display_name(out_id) if equipment_out else Backpack.item_display_name(out_id)
	row.add_child(_make_item_icon(out_id, craft_name))
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.size_flags_stretch_ratio = 1.0
	var name_lbl := Label.new()
	name_lbl.text = Equipment.item_display_name(out_id) if equipment_out else Backpack.item_display_name(out_id)
	name_lbl.add_theme_font_size_override("font_size", 13)
	name_lbl.add_theme_color_override("font_color", Color(0.92, 0.86, 0.72, 1.0))
	name_lbl.clip_text = true
	name_lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	var cost_lbl := Label.new()
	## Costs only — long tool/fertilizer fluff overflowed the panel.
	cost_lbl.text = _craft_row_cost_text(recipe_id)
	cost_lbl.add_theme_font_size_override("font_size", 11)
	cost_lbl.add_theme_color_override("font_color", Color(0.70, 0.64, 0.52, 1.0))
	cost_lbl.clip_text = true
	cost_lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	cost_lbl.autowrap_mode = TextServer.AUTOWRAP_OFF
	info.add_child(name_lbl)
	info.add_child(cost_lbl)
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(72, 28)
	btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	btn.size_flags_horizontal = Control.SIZE_SHRINK_END
	var reason: String = Equipment.craft_block_reason(recipe_id) if equipment_out else Backpack.craft_block_reason(recipe_id)
	if reason == "unique":
		btn.text = ContentStrings.get_text("backpack_owned")
		btn.disabled = true
		_apply_button_chrome(btn, Color(0.22, 0.18, 0.12, 1.0), GOLD)
	elif reason != "":
		btn.text = ContentStrings.get_text("handcraft_prompt")
		btn.disabled = true
		_apply_button_chrome(btn, Color(0.22, 0.12, 0.10, 1.0), BUY_CANT)
	else:
		btn.text = ContentStrings.get_text("handcraft_prompt")
		_apply_button_chrome(btn, BUY_CAN, GOLD)
		btn.pressed.connect(_on_craft.bind(recipe_id))
	row.add_child(info)
	row.add_child(btn)
	row.set_meta("recipe_id", recipe_id)
	return row


func _item_examine_text(item_id: String) -> String:
	match item_id:
		"axe_head":
			return _content_line("part_stone_axe_head_examine")
		"pickaxe_head":
			return _content_line("part_stone_pickaxe_head_examine")
		_:
			pass
	if has_node("/root/Equipment") and Equipment.is_known_item(item_id):
		return Equipment.item_tooltip(item_id)
	if has_node("/root/Backpack"):
		return Backpack.item_tooltip(item_id)
	return ""


func _content_line(key: String, tokens: Dictionary = {}) -> String:
	var labeled: String = ContentStrings.get_text(key, tokens)
	if labeled != key and labeled != "":
		return labeled
	return ""


func _craft_row_cost_text(recipe_id: String) -> String:
	## Prefer Content v0.4.1 shorts, then craft-cost keys, then live ingredient lines.
	if Equipment.has_recipe(recipe_id):
		var gear_costs: String = ""
		if recipe_id == "stone_sword":
			gear_costs = _content_line("stone_sword_craft_cost")
		elif recipe_id == "weapon_rod":
			gear_costs = _content_line("handcraft_row_weapon_rod_short")
		elif recipe_id == "sapstaff":
			gear_costs = _content_line("sapstaff_craft_cost")
		elif recipe_id == "thornbow":
			gear_costs = _content_line("thornbow_craft_cost")
		if gear_costs == "":
			gear_costs = "  ".join(Equipment.recipe_ingredient_lines(recipe_id))
		var gear_wrapped: String = _content_line("handcraft_row_costs_only", {"costs": gear_costs})
		if gear_wrapped != "":
			return gear_wrapped
		return gear_costs
	var costs: String = ""
	match recipe_id:
		"stone_watering_can":
			costs = _content_line("handcraft_row_watering_can_short")
			if costs == "":
				costs = _content_line("tool_stone_watering_can_craft_cost")
		"wooden_basket":
			costs = _content_line("handcraft_row_wooden_basket_short")
			if costs == "":
				costs = _content_line("tool_wooden_basket_craft_cost")
		"fertilizer":
			var ings: Dictionary = Backpack.get_recipe_ingredients(recipe_id)
			var toks: Dictionary = {
				"wood": int(ings.get("wood", 10)),
				"stone": int(ings.get("stone", 10)),
				"food": int(ings.get("food", 10)),
			}
			costs = _content_line("handcraft_row_fertilizer_short", toks)
			if costs == "":
				costs = _content_line("fertilizer_craft_cost", toks)
			if costs == "":
				costs = _content_line("fertilizer_craft_cost_default")
	if costs == "":
		costs = "  ".join(Backpack.recipe_ingredient_lines(recipe_id))
	var wrapped: String = _content_line("handcraft_row_costs_only", {"costs": costs})
	if wrapped != "":
		return wrapped
	return costs


func get_backpack_layout_metrics() -> Dictionary:
	var panel_w: float = backpack_panel.size.x if backpack_panel else 0.0
	return {
		"panel_w": panel_w,
		"fits": panel_w >= 630.0,
	}


func get_bench_layout_metrics() -> Dictionary:
	var panel_w: float = bench_panel.size.x if bench_panel else 0.0
	var craft_scroll: ScrollContainer = get_node_or_null("BenchPanel/CraftScroll") as ScrollContainer
	var craft_w: float = craft_scroll.size.x if craft_scroll else 0.0
	return {
		"panel_w": panel_w,
		"craft_scroll_w": craft_w,
		"fits": craft_w <= panel_w + 1.0 and craft_w > 0.0,
	}


func _on_craft(recipe_id: String) -> void:
	if Equipment.has_recipe(recipe_id):
		_on_craft_gear(recipe_id)
		return
	var result: String = Backpack.try_craft(recipe_id)
	var out_id: String = str(Backpack.get_recipe_def(recipe_id).get("output_id", recipe_id))
	var item_name: String = Backpack.item_display_name(out_id)
	if result == "ok":
		GameAudio.play_ui_confirm()
		if out_id == "fertilizer":
			_show_toast(ContentStrings.get_text("fertilizer_craft_ok"))
		else:
			_show_toast(ContentStrings.get_text("handcraft_ok", {"item": item_name}))
		_rebuild_backpack()
		_rebuild_bench()
		_refresh_resources()
		SaveService.save_game()
		return
	GameAudio.play_tree_deny()
	if result == "unique":
		_show_toast(ContentStrings.get_text("handcraft_owned_unique"))
	else:
		_show_toast(ContentStrings.get_text("handcraft_cant_afford", {
			"costs": "  ".join(Backpack.recipe_ingredient_lines(recipe_id)),
		}))
	_rebuild_backpack()
	_rebuild_bench()


func _on_craft_gear(recipe_id: String) -> void:
	var result: String = Equipment.try_craft(recipe_id)
	var out_id: String = str(Equipment.get_recipe_def(recipe_id).get("output_id", recipe_id))
	var item_name: String = Equipment.item_display_name(out_id)
	if result == "ok":
		GameAudio.play_ui_confirm()
		_show_toast(ContentStrings.get_text("weapon_craft_ok", {"item": item_name}))
		_rebuild_backpack()
		_rebuild_bench()
		_refresh_resources()
		SaveService.save_game()
		return
	GameAudio.play_tree_deny()
	if result == "unique":
		_show_toast(ContentStrings.get_text("handcraft_owned_unique"))
	else:
		_show_toast(ContentStrings.get_text("handcraft_cant_afford", {
			"costs": "  ".join(Equipment.recipe_ingredient_lines(recipe_id)),
		}))
	_rebuild_backpack()
	_rebuild_bench()


func _refresh_ascension_copy() -> void:
	if prestige_title == null:
		return
	prestige_title.text = ContentStrings.get_text("fruit_panel_title")
	prestige_sub.text = ContentStrings.get_text("fruit_shop_only_banner")
	if shard_count_label:
		shard_count_label.text = str(GameState.manashards)
	ascend_button.visible = GameState.fruit_harvested_pending_ascend
	ascend_button.disabled = not GameState.can_ascend()
	ascend_button.text = ContentStrings.get_text("ascend_confirm_yes")
	if _highlight_ascend and GameState.can_ascend():
		_apply_ascend_highlight()
	else:
		_clear_ascend_highlight()


func _apply_ascend_highlight() -> void:
	ascend_button.modulate = Color(1.15, 1.05, 0.75, 1.0)
	if ascend_button.visible and not ascend_button.disabled and ascension_panel.visible:
		ascend_button.grab_focus()


func _clear_ascend_highlight() -> void:
	ascend_button.modulate = Color.WHITE


func _rebuild_upgrades() -> void:
	for child: Node in upgrade_list.get_children():
		child.queue_free()
	if not GameState.fruit_harvested_pending_ascend:
		return
	var stripe: bool = false
	for entry: Variant in GameState.upgrades_data:
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var d: Dictionary = entry
		var uid: String = str(d.get("id", ""))
		var rank: int = GameState.get_upgrade_rank(uid)
		var max_rank: int = int(d.get("max_rank", 1))
		var cost: int = GameState.get_upgrade_cost(uid)
		var row := PanelContainer.new()
		row.custom_minimum_size = Vector2(0, SHOP_ROW_H)
		var row_sb := StyleBoxFlat.new()
		if stripe:
			row_sb.bg_color = Color(0.20, 0.14, 0.09, 1.0)
		else:
			row_sb.bg_color = Color(0.15, 0.10, 0.07, 1.0)
		row_sb.set_border_width_all(0)
		row_sb.border_color = Color(0.35, 0.26, 0.14, 0.5)
		row_sb.border_width_bottom = 1
		row.add_theme_stylebox_override("panel", row_sb)
		var inner := HBoxContainer.new()
		inner.custom_minimum_size = Vector2(0, SHOP_ROW_H)
		inner.add_theme_constant_override("separation", 8)
		inner.add_child(_upgrade_icon(uid, d))
		var info := VBoxContainer.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info.alignment = BoxContainer.ALIGNMENT_CENTER
		var name_lbl := Label.new()
		if uid == "keep_tools":
			name_lbl.text = ContentStrings.get_text("upgrade_keep_tools_name")
		else:
			name_lbl.text = str(d.get("display_name", uid))
		name_lbl.add_theme_font_size_override("font_size", 13)
		name_lbl.add_theme_color_override("font_color", Color(0.92, 0.86, 0.72, 1.0))
		var desc: String = _upgrade_description(uid, d)
		var rank_lbl := Label.new()
		if desc != "":
			rank_lbl.text = "%s  ·  %s" % [
				desc,
				ContentStrings.get_text("upgrade_rank", {"rank": rank, "max": max_rank}),
			]
		else:
			rank_lbl.text = ContentStrings.get_text("upgrade_rank", {"rank": rank, "max": max_rank})
		rank_lbl.add_theme_font_size_override("font_size", 11)
		rank_lbl.add_theme_color_override("font_color", Color(0.70, 0.64, 0.52, 1.0))
		rank_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		info.add_child(name_lbl)
		info.add_child(rank_lbl)
		if desc != "":
			row.tooltip_text = desc
			inner.tooltip_text = desc
			name_lbl.tooltip_text = desc
			rank_lbl.tooltip_text = desc
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(108, 32)
		btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		if rank >= max_rank:
			btn.text = ContentStrings.get_text("upgrade_maxed")
			btn.disabled = true
			_apply_button_chrome(btn, Color(0.22, 0.18, 0.12, 1.0), GOLD)
		elif GameState.manashards < cost:
			btn.text = "%s %d" % [ContentStrings.get_text("upgrade_buy"), cost]
			btn.disabled = true
			_apply_button_chrome(btn, Color(0.22, 0.12, 0.10, 1.0), BUY_CANT)
		else:
			btn.text = "%s %d" % [ContentStrings.get_text("upgrade_buy"), cost]
			_apply_button_chrome(btn, BUY_CAN, GOLD)
			btn.pressed.connect(_on_buy.bind(uid))
		var keep_cost_tip: String = _upgrade_keep_tools_cost_text(uid, cost)
		if keep_cost_tip != "":
			btn.tooltip_text = keep_cost_tip
		inner.add_child(info)
		inner.add_child(btn)
		row.add_child(inner)
		upgrade_list.add_child(row)
		stripe = not stripe


func _upgrade_icon(upgrade_id: String, def: Dictionary) -> TextureRect:
	var icon := TextureRect.new()
	icon.name = "AscIcon"
	icon.custom_minimum_size = Vector2(32, 32)
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var path: String = GameState.upgrade_art_path(upgrade_id)
	if path != "":
		icon.texture = load(path) as Texture2D
	var tip: String = str(def.get("display_name", upgrade_id))
	if upgrade_id == "keep_tools":
		tip = ContentStrings.get_text("upgrade_keep_tools_name")
	icon.tooltip_text = tip
	return icon


func _upgrade_keep_tools_cost_text(upgrade_id: String, cost: int) -> String:
	if upgrade_id != "keep_tools":
		return ""
	var keep_cost: String = _content_line("upgrade_keep_tools_cost", {"cost": cost})
	if keep_cost != "":
		return keep_cost
	return _content_line("upgrade_keep_tools_cost_default")


func _upgrade_description(upgrade_id: String, def: Dictionary) -> String:
	var tip_key: String = "upgrade_%s_tooltip" % upgrade_id
	var tip: String = ContentStrings.get_text(tip_key)
	if tip != tip_key and tip != "":
		return tip
	var key: String = "upgrade_%s_desc" % upgrade_id
	var labeled: String = ContentStrings.get_text(key)
	if labeled != key and labeled != "":
		return labeled
	return str(def.get("description", ""))


func _on_buy(upgrade_id: String) -> void:
	## Manashard blessing shop (Ascension-only): multi-buy OK; Ascend never requires a purchase.
	if GameState.buy_upgrade(upgrade_id):
		GameAudio.play_upgrade_buy()
		var disp: String = str(GameState.get_upgrade_def(upgrade_id).get("display_name", upgrade_id))
		if upgrade_id == "keep_tools":
			_show_toast(ContentStrings.get_text("upgrade_keep_tools_toast"))
		else:
			_show_toast(ContentStrings.get_text("upgrade_buy_ok", {"blessing_name": disp}))
		_confirm_ascend = false
		_rebuild_upgrades()
		_refresh_all()
		SaveService.save_game()


func _on_ascend() -> void:
	if not GameState.can_ascend():
		return
	if not _confirm_ascend:
		_confirm_ascend = true
		var confirm_line: String = ContentStrings.get_text("ascend_confirm")
		if has_node("/root/ForgeJobs"):
			var warn: String = ForgeJobs.ascend_warning()
			if warn != "":
				confirm_line = warn
				ascend_button.tooltip_text = warn
		_show_toast("%s\n%s" % [
			confirm_line,
			ContentStrings.get_text("ascend_hint"),
		])
		ascend_button.text = ContentStrings.get_text("ascend_confirm_yes")
		_refresh_ascension_copy()
		return
	_confirm_ascend = false
	GameAudio.play_ascend()
	GameAudio.reset_cycle_flags()
	GameState.ascend()
	_highlight_ascend = false
	hide_ascension_shop()
	_release_world_if_allowed()
	_refresh_all()
	SaveService.save_game()
