extends CanvasLayer
class_name GameHUD
## HUD + Manatree care + backpack + Keeper's Bench + Ascension shop.

const BATCH_PANEL_SCENE: PackedScene = preload("res://scenes/ui/batch_panel.tscn")
const Binds := preload("res://scripts/ui/input_binds.gd")
const BatchPanel := preload("res://scripts/batch_panel.gd")

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
@onready var toast_shade: Control = $Panel/ToastShade
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
@onready var close_button: Button = $AscensionPanel/Header/CloseButton
@onready var ascend_button: Button = $AscensionPanel/Footer/AscendButton
@onready var welcome_panel: ColorRect = $WelcomePanel
@onready var welcome_boot_label: Label = $WelcomePanel/WelcomeBoot
@onready var welcome_title_label: Label = $WelcomePanel/WelcomeTitle
@onready var welcome_body_label: Label = $WelcomePanel/WelcomeBody
@onready var welcome_hint_label: Label = $WelcomePanel/WelcomeHint
@onready var welcome_dismiss_button: Button = $WelcomePanel/WelcomeDismiss

## Shop dim sits between kit windows (35) and the shop / confirms it dims behind.
const Z_MODAL_DIM: int = 39
const Z_MODAL: int = 40
## Art lock MANATREE_CARE_PANEL_V01 (540p r2): 600×440, header 64 / card / action band 56.
const CARE_SIZE: Vector2 = Vector2(600, 440)
## Card 84..244, then the 52 px action row 12 below it.
const CARE_ACTION_END_Y: float = 308.0
const CARE_COST_COL_W: float = 250.0
const ANCIENT_TIMER_W: float = 300.0
const CARE_TIMER_CYAN: Color = Color8(46, 150, 170)
const CARE_GREEN: Color = Color8(52, 120, 44)
const CARE_HEADER_H: float = 64.0
const CARE_ACTION_BAND_H: float = 56.0
## Mockup ascension540_pc_16x9_r3: 912×472, 48 px rows on a 52 pitch in a bevelled list,
## Ascend 240×52 bottom-right; × in the title row with the shard chip to its left.
const SHOP_SIZE: Vector2 = Vector2(912, 472)
const SHOP_MIN_SIZE: Vector2 = Vector2(640, 412)
const SHOP_HEADER_H: float = 48.0
const SHOP_FOOTER_BTN_H: float = 52.0
const SHOP_ROW_H: float = 48.0
const SHOP_PAD: float = 24.0
const SHOP_LIST_Y: float = 126.0
const SHOP_CHIP_W: float = 150.0
const SHOP_CHIP_BG: Color = Color8(40, 28, 20)
const SHOP_BUY_W: float = 136.0
const SHOP_SHARD_ICON: String = "res://assets_extra/shared/icon_manashards.png"
const SHOP_LOCK_ICON: String = "res://assets_extra/shared/hud_equip_locked.png"
const GOLD: Color = Color(0.82, 0.64, 0.28, 1.0)
const ICON_FERTILIZER: Color = Color(0.42, 0.35, 0.14, 1.0)
const ICON_ESSENCE: Color = Color(0.56, 0.35, 0.66, 1.0)
const ICON_BACKPACK: Color = Color(0.48, 0.31, 0.18, 1.0)
const ESSENCE_TINT: Color = Color(0.78, 0.62, 1.18, 1.0)
const PLACEHOLDER_SWATCH: Color = Color(0.42, 0.40, 0.36, 1.0)
const ICON_WOOD_TEX: String = "res://assets_extra/shared/icon_wood.png"
const ICON_STONE_TEX: String = "res://assets_extra/shared/icon_stone.png"
const ICON_FOOD_TEX: String = "res://assets_extra/shared/icon_food.png"
const ICON_SHARD_TEX: String = "res://assets_extra/shared/icon_manashards.png"
const ICON_ESSENCE_TEX: String = "res://assets_extra/shared/icon_essence.png"
const ICON_FERTILIZER_TEX: String = "res://assets_extra/shared/icon_fertilizer.png"
const BTN_PAUSE_NORMAL: String = "res://assets/art/ui/buttons/pause_normal.png"
const BTN_PAUSE_HOVER: String = "res://assets/art/ui/buttons/pause_hover.png"
const BTN_PAUSE_PRESSED: String = "res://assets/art/ui/buttons/pause_pressed.png"
const BTN_PACK_NORMAL: String = "res://assets_extra/shared/backpack_normal.png"
const BTN_PACK_HOVER: String = "res://assets/art/ui/buttons/backpack_hover.png"
const BTN_PACK_PRESSED: String = "res://assets/art/ui/buttons/backpack_pressed.png"
const BACKPACK_ROW_H: float = 48.0
const BAG_PANEL_W: float = 560.0
const BAG_PANEL_H: float = 452.0
const BAG_ROW_H: float = 44.0
const BENCH_SIZE: Vector2 = Vector2(912, 472)
const BENCH_LIST_W: float = 330.0
const BENCH_BATCH_Y: float = 300.0
const BENCH_FILTER_CYCLE: Array[String] = ["all", "parts", "tools", "weapons"]
const SHORT_RED: Color = Color8(170, 52, 40)

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
var _speed_button: TextureButton
var _speed_index: int = 0
var _play_speed_button: TextureButton
var _footsteps_popup: Panel
var _keeper_activity: Label
var _elaia_activity: Label
var _highlight_ascend: bool = false
var _confirm_batches: bool = false
var _ascend_batch_dialog: Panel
var _ascend_batch_body: Label
var _bench_batch: BatchPanel
var _bench_tabs: HBoxContainer
var _care_card: Panel
var _forge_locked: bool = false
var _care_needs_hdr: Label
var _care_status: Label
var _care_hint: Label
var _care_timer: Label
var _bench_tab_all: Button
var _bench_cat_btn: Button
var _bench_detail: Control
var _bench_filter_ix: int = 0
var _bench_selected: String = ""
var _backpack_tab: String = "all"
const BAG_FILTER_CYCLE: Array[String] = ["all", "raw", "refined", "potions", "tools", "weapons", "relics"]
var _backpack_cat_btn: Button
var _bag_detail_panel: Panel
var _bag_detail_item_id: String = ""
var _sheet: CharacterSheet = null
var _toast_tween: Tween
var _care_hidden_for_forge: bool = false
var _shop_preview_mode: bool = false
var _shop_toolbar: HBoxContainer
var _shop_list_bevel: Panel
var _shop_preview_tag: Label
var _shop_footer_hint: Label
var _hide_locked_toggle: CheckButton
var _hide_maxed_toggle: CheckButton
var _blessings_preview_button: Button
var _spoiler_dialog: Panel
var _spoiler_pending_unlock: bool = false
var _welcome_dismiss_ready: bool = false
var _welcome_delay_tween: Tween
const TOAST_HOLD_SEC: float = 2.6
const TOAST_FADE_SEC: float = 0.8
const HUD_KIT_LOG: String = "res://assets/ui/theme/log_panel_9s_12.png"
const HUD_KIT_TOAST: String = "res://assets/ui/theme/toast_9s_40x30.png"
const HUD_PAUSE_ICON: String = "res://assets/ui/theme/icon_pause_32.png"
const HUD_BOARD_ICON: String = "res://assets_extra/hud/board_icon_30.png"
const PARTY_PITCH_R4: float = 50.0

var _board_button: Button
var _board_icon: TextureRect
var _party_tag: PanelContainer
var _party_tag_label: Label
var _help_dim: ColorRect
var _help_panel: Panel
var _help_tab_pc: Button
var _help_tab_phone: Button
var _help_body: VBoxContainer
var _help_close: Button
var _help_tab: String = "pc"


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	panel.color = Color(0, 0, 0, 0)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ascension_panel.visible = false
	fruit_confirm_panel.visible = false
	care_panel.visible = false
	welcome_panel.visible = false
	call_deferred("_layout_welcome_panel")
	if not get_viewport().size_changed.is_connected(_layout_welcome_panel):
		get_viewport().size_changed.connect(_layout_welcome_panel)
	shop_dim.visible = false
	shop_dim.z_index = Z_MODAL_DIM
	ascension_panel.z_index = Z_MODAL
	fruit_confirm_panel.z_index = Z_MODAL
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
	_ensure_bench_batch()
	bench_title.text = ContentStrings.get_text("bench_title")
	bench_prompt.text = "%s  ·  %s" % [
		ContentStrings.get_text("handcraft_title"),
		ContentStrings.get_text("tool_never_gate"),
	]
	bench_panel.visible = false
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
	_sheet.z_index = 30
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
	_ensure_speed_button()
	_ensure_shop_toolbar()
	_ensure_spoiler_dialog()
	_ensure_care_blessings_button()
	_ensure_play_speed_button()
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
	if has_node("/root/Reach") and not Reach.party_changed.is_connected(_on_reach_party_changed):
		Reach.party_changed.connect(_on_reach_party_changed)
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
	_layout_ascension_shop()
	if has_node("/root/GameTheme"):
		GameTheme.sweep_theme(self)
	_apply_hud540_chrome()
	_ensure_board_button()
	_reorder_resource_row()
	_layout_hud540()
	if not get_viewport().size_changed.is_connected(_layout_hud540):
		get_viewport().size_changed.connect(_layout_hud540)
	_apply_bag540_chrome()
	_layout_bag540()
	if not get_viewport().size_changed.is_connected(_layout_bag540):
		get_viewport().size_changed.connect(_layout_bag540)
	_apply_care540_chrome()
	_layout_care540()
	if not get_viewport().size_changed.is_connected(_layout_care540):
		get_viewport().size_changed.connect(_layout_care540)
	_ensure_help_panel()
	_sink_hud_chrome()
	if help_button:
		help_button.visible = true
		Ui540.style_wood_icon_button(help_button)
		if not help_button.pressed.is_connected(_toggle_help_panel):
			help_button.pressed.connect(_toggle_help_panel)


## HUD chrome draws under every HUD window: z 0 and tree order right after the Panel,
## so the dims and kit windows (later siblings) cover the party column, wisp counter and toast.
func _sink_hud_chrome() -> void:
	var at: int = panel.get_index() + 1
	for node_name: String in ["PartyBar", "WispCounter"]:
		var chrome: CanvasItem = get_node_or_null(node_name) as CanvasItem
		if chrome:
			chrome.z_index = 0
			move_child(chrome, at)
			at += 1
	if status_label:
		status_label.z_index = 0
	if toast_shade:
		toast_shade.z_index = 0


func _reorder_resource_row() -> void:
	var row: HBoxContainer = $Panel/IconRow as HBoxContainer
	if row == null:
		return
	for chip_name: String in ["ShardChip", "WoodChip", "StoneChip", "FoodChip", "EssenceChip"]:
		var chip: Node = row.get_node_or_null(chip_name)
		if chip:
			row.move_child(chip, -1)
	row.add_theme_constant_override("separation", 8)


func _apply_hud540_chrome() -> void:
	var shade: Panel = $Panel.get_node_or_null("IconShade") as Panel
	if shade:
		shade.add_theme_stylebox_override(
			"panel",
			Ui540.kit_stylebox_9s(HUD_KIT_LOG, Vector4i(4, 4, 4, 4), Vector4(8, 4, 8, 4)),
		)
	if toast_shade is Panel:
		(toast_shade as Panel).add_theme_stylebox_override(
			"panel",
			Ui540.kit_stylebox_9s(HUD_KIT_TOAST, Vector4i(12, 8, 12, 8), Vector4(12, 6, 12, 6)),
		)
	for chip_path: String in [
		"Panel/IconRow/ShardChip/NumShards",
		"Panel/IconRow/WoodChip/NumWood",
		"Panel/IconRow/StoneChip/NumStone",
		"Panel/IconRow/FoodChip/NumFood",
		"Panel/IconRow/EssenceChip/NumEssence",
	]:
		var num: Label = get_node_or_null(chip_path) as Label
		if num:
			num.add_theme_font_size_override("font_size", GameTheme.silver_body_size())
			num.add_theme_font_override("font", GameTheme.body_font())
			num.add_theme_color_override("font_color", GameTheme.INK)
	if status_label:
		GameTheme.style_outlined_ink_label(status_label)
		status_label.z_index = 50
	if toast_shade:
		toast_shade.z_index = 49
		toast_shade.clip_contents = true
	Ui540.style_wood_icon_button(pause_button)
	Ui540.style_wood_icon_button(character_button)
	Ui540.style_wood_icon_button(backpack_button)
	var pause_tex: Texture2D = load(HUD_PAUSE_ICON) as Texture2D
	if pause_icon and pause_tex:
		pause_icon.texture = pause_tex
		pause_icon.custom_minimum_size = Vector2(32, 32)


func _layout_hud540() -> void:
	var vs: Vector2 = Ui540.viewport_size()
	var safe: float = Ui540.SAFE_MARGIN_PX
	## HUD chrome hugs the screen edges on every aspect (hud540 20:9 mockup).
	var shift: float = 0.0
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.offset_left = 0.0
	panel.offset_top = 0.0
	panel.offset_right = 0.0
	panel.offset_bottom = 0.0
	var bar_h: float = 40.0
	var bar_w: float = 16.0 + 5.0 * 72.0
	var shade: Control = panel.get_node_or_null("IconShade") as Control
	if shade:
		shade.position = Vector2(safe + shift, safe)
		shade.size = Vector2(bar_w, bar_h)
	var row: Control = $Panel/IconRow as Control
	if row:
		row.position = Vector2(safe + 8.0 + shift, safe + 4.0)
		row.size = Vector2(bar_w - 16.0, bar_h - 8.0)
	var tap: float = Ui540.TAP_MIN_PX
	var pause_sz: float = 40.0 if Ui540.is_phone_export() else tap
	var pause_x: float = vs.x - safe - pause_sz + shift
	pause_button.position = Vector2(pause_x, safe)
	pause_button.size = Vector2(pause_sz, pause_sz)
	if ascension_reopen_button.visible:
		ascension_reopen_button.position = Vector2(pause_x - tap - 8.0, safe)
		ascension_reopen_button.size = Vector2(tap, tap)
	var speed_x: float = pause_x - 8.0 - tap
	if _play_speed_button:
		_play_speed_button.position = Vector2(speed_x, safe)
		_play_speed_button.size = Vector2(tap, tap)
	var counter_right: float = speed_x - 12.0
	if _speed_button:
		_speed_button.position = Vector2(speed_x - tap - 4.0, safe)
		_speed_button.size = Vector2(tap, tap)
		if _speed_button.visible:
			counter_right = _speed_button.position.x - 12.0
	var counter: Label = get_node_or_null("WispCounter") as Label
	if counter:
		counter.size = Vector2(160, 28)
		counter.position = Vector2(counter_right - counter.size.x, safe + (tap - counter.size.y) * 0.5)
	var shortcut_y: float = vs.y - safe - tap
	var show_nav: bool = _nav_button != null and _nav_button.visible
	var shortcut_n: float = 4.0 if show_nav else 3.0
	var shortcut_x: float = vs.x - safe - shortcut_n * tap - (shortcut_n - 1.0) * 8.0 + shift
	var slot: float = 0.0
	if show_nav:
		_nav_button.set_anchors_preset(Control.PRESET_TOP_LEFT)
		_nav_button.position = Vector2(shortcut_x, shortcut_y)
		_nav_button.size = Vector2(tap, tap)
		slot = 1.0
	character_button.position = Vector2(shortcut_x + slot * (tap + 8.0), shortcut_y)
	character_button.size = Vector2(tap, tap)
	backpack_button.position = Vector2(shortcut_x + (slot + 1.0) * (tap + 8.0), shortcut_y)
	backpack_button.size = Vector2(tap, tap)
	if _board_button:
		_board_button.position = Vector2(shortcut_x + (slot + 2.0) * (tap + 8.0), shortcut_y)
		_board_button.size = Vector2(tap, tap)
	_layout_party_bar_r4(vs, safe, shift)
	_layout_toast_r4(vs, safe, shift)


func _layout_toast_r4(vs: Vector2, safe: float, shift: float) -> void:
	if status_label == null or toast_shade == null:
		return
	var tap: float = Ui540.TAP_MIN_PX
	var toast_y: float = vs.y - safe - tap - 8.0 - 32.0
	var line: String = status_label.text
	var text_w: float = GameTheme.body_font().get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, GameTheme.silver_body_size()).x
	var toast_w: float = clampf(text_w + 64.0, 180.0, vs.x - safe * 2.0)
	var toast_x: float = roundf((vs.x - toast_w) * 0.5 + shift)
	var toast_h: float = 30.0
	var clear: Vector2 = _toast_clear_of_station(Vector2(toast_x, toast_y), Vector2(toast_w, toast_h), vs)
	toast_x = clear.x
	toast_y = clear.y
	toast_shade.position = Vector2(toast_x, toast_y)
	toast_shade.size = Vector2(toast_w, toast_h)
	status_label.position = Vector2(toast_x + 40.0, toast_y + 2.0)
	status_label.size = Vector2(toast_w - 48.0, 26.0)


## The station window owns the centre. Slide the toast above it, or below if that fits.
func _toast_clear_of_station(origin: Vector2, toast_sz: Vector2, vs: Vector2) -> Vector2:
	var station: Control = _forge_station_panel()
	if station == null or not station.is_visible_in_tree():
		return origin
	var win: Rect2 = station.get_global_rect().grow(6.0)
	var rect := Rect2(origin, toast_sz)
	if not rect.intersects(win):
		return origin
	var above: float = win.position.y - 8.0 - toast_sz.y
	if above >= Ui540.SAFE_MARGIN_PX and not Rect2(origin.x, above, toast_sz.x, toast_sz.y).intersects(win):
		return Vector2(origin.x, above)
	var below: float = win.end.y + 8.0
	if below + toast_sz.y <= vs.y - 4.0 and not Rect2(origin.x, below, toast_sz.x, toast_sz.y).intersects(win):
		return Vector2(origin.x, below)
	return Vector2(origin.x, clampf(origin.y, Ui540.SAFE_MARGIN_PX, maxf(Ui540.SAFE_MARGIN_PX, vs.y - toast_sz.y - 4.0)))


func _forge_station_panel() -> Control:
	var scene: Node = get_tree().current_scene if get_tree() else null
	if scene == null:
		return null
	return scene.get_node_or_null("UI/RecipePanel") as Control


## The bar is exactly as tall as its portrait column and sits on the bottom safe margin,
## so the column starts at y 0 and the activity labels share the portrait row offsets.
func _layout_party_bar_r4(vs: Vector2, safe: float, _shift: float) -> void:
	if _party_bar == null:
		return
	var col_x: float = 30.0
	var bottom: float = vs.y - safe
	var col_h: float = PARTY_SLOT
	if _party_column:
		var rows: int = 0
		for slot: Node in _party_column.get_children():
			if slot is Control and (slot as Control).visible:
				rows += 1
		col_h = maxf(PARTY_SLOT, rows * PARTY_PITCH_R4 - (PARTY_PITCH_R4 - PARTY_SLOT))
		_party_column.position = Vector2.ZERO
		_party_column.size = Vector2(PARTY_SLOT, col_h)
	_party_bar.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_party_bar.position = Vector2(col_x, bottom - col_h)
	_party_bar.size = Vector2(PARTY_SLOT + 220.0, col_h)


func _ensure_board_button() -> void:
	if _board_button != null:
		return
	_board_button = Button.new()
	_board_button.name = "BoardButton"
	_board_button.text = ""
	_board_button.tooltip_text = ContentStrings.get_text("expedition_board_name")
	_board_button.pressed.connect(_on_board_pressed)
	_board_icon = TextureRect.new()
	_board_icon.name = "BoardIcon"
	_board_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_board_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_board_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_board_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_board_icon.custom_minimum_size = Vector2(30, 30)
	_board_icon.texture = load(HUD_BOARD_ICON) as Texture2D
	_board_button.add_child(_board_icon)
	panel.add_child(_board_button)
	Ui540.style_wood_icon_button(_board_button)


func _on_board_pressed() -> void:
	for node: Node in get_tree().get_nodes_in_group("expedition_board"):
		if node.has_method("open_shell"):
			node.call("open_shell")
			GameAudio.play_ui_open()
			return


func _apply_bag540_chrome() -> void:
	if backpack_panel == null:
		return
	Ui540.apply_kit_panel(backpack_panel, "bag", backpack_title, backpack_close_button)
	GameTheme.style_plank_label(backpack_title)
	GameTheme.style_ink_label(inventory_title, true)
	inventory_title.clip_text = true
	inventory_title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	backpack_panel.z_index = 35
	## Mockup bag540: "All" plus one cycling category button; the per-category tabs stay as
	## nodes (verify, keyboard paths) but are not shown.
	for tab: Button in [backpack_tab_raw, backpack_tab_refined, backpack_tab_tools, backpack_tab_weapons, backpack_tab_relics]:
		tab.visible = false
	backpack_tab_all.custom_minimum_size = Vector2(90, 44)
	GameTheme.style_big_tab_button(backpack_tab_all)
	if _backpack_cat_btn == null:
		_backpack_cat_btn = Button.new()
		_backpack_cat_btn.name = "TabCategoryCycle"
		backpack_tab_all.get_parent().add_child(_backpack_cat_btn)
		_backpack_cat_btn.pressed.connect(_cycle_backpack_filter)
	_backpack_cat_btn.custom_minimum_size = Vector2(160, 44)
	GameTheme.style_big_tab_button(_backpack_cat_btn)
	Ui540.add_cycle_cue(_backpack_cat_btn)
	_backpack_cat_btn.visible = true
	var tab_row: HBoxContainer = backpack_panel.get_node_or_null("TabRow") as HBoxContainer
	if tab_row:
		tab_row.add_theme_constant_override("separation", 8)
	var list: VBoxContainer = inventory_list as VBoxContainer
	if list:
		list.add_theme_constant_override("separation", int(BACKPACK_ROW_H - BAG_ROW_H))
	_ensure_bag_detail_panel()


func _layout_bag540() -> void:
	if backpack_panel == null:
		return
	var sz: Vector2 = Ui540.fit_kit_window(backpack_panel, Vector2(BAG_PANEL_W, BAG_PANEL_H))
	var w: float = sz.x
	var h: float = sz.y
	var inner_w: float = w - 72.0
	Ui540.place_close_button(backpack_close_button, w)
	Ui540.place_title_plank(backpack_title, w)
	inventory_title.position = Vector2(36, 30)
	inventory_title.size = Vector2(inner_w - Ui540.TAP_MIN_PX - 12.0, 24)
	var tab_row: Control = backpack_panel.get_node_or_null("TabRow") as Control
	var tab_y: float = 64.0
	if tab_row:
		tab_row.position = Vector2(36, tab_y)
		tab_row.size = Vector2(inner_w, 44)
	var list_top: float = tab_y + 44.0 + 14.0
	var scroll: ScrollContainer = backpack_panel.get_node_or_null("InventoryScroll") as ScrollContainer
	if scroll:
		scroll.position = Vector2(36, list_top)
		scroll.size = Vector2(inner_w, h - list_top - 28.0)


func _apply_care540_chrome() -> void:
	if care_panel:
		Ui540.apply_kit_panel(care_panel, "manatree_care", care_title, care_close_button)
		GameTheme.style_plank_label(care_title)
		GameTheme.style_ink_label(care_stage_label, true)
		GameTheme.style_ink_label(care_needs_label)
		care_needs_label.autowrap_mode = TextServer.AUTOWRAP_OFF
		GameTheme.style_primary_button(pay_button)
		GameTheme.style_primary_button(harvest_fruit_button)
		GameTheme.style_menu_button(water_button)
		_ensure_care_card()
	if bench_panel:
		Ui540.apply_kit_panel(bench_panel, "workbench", bench_title, bench_close_button)
		GameTheme.style_plank_label(bench_title)
		GameTheme.style_ink_label(bench_prompt, true)
		bench_prompt.autowrap_mode = TextServer.AUTOWRAP_OFF
		bench_prompt.clip_text = true
		bench_prompt.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		bench_panel.z_index = 35
		_ensure_bench_chrome()


func _ensure_care_card() -> void:
	if _care_card != null:
		return
	_care_card = Panel.new()
	_care_card.name = "CareCard"
	_care_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_care_card.add_theme_stylebox_override("panel", Ui540.kit_stylebox_9s("res://assets/ui/theme/play_bevel_9s_6x6.png", Vector4i(2, 2, 2, 2)))
	care_panel.add_child(_care_card)
	var vines: Node = care_panel.get_node_or_null("VineFrame")
	care_panel.move_child(_care_card, vines.get_index() + 1 if vines else 0)
	_care_needs_hdr = Label.new()
	_care_needs_hdr.name = "CareNeedsHeader"
	GameTheme.style_ink_label(_care_needs_hdr, true)
	care_panel.add_child(_care_needs_hdr)
	_care_status = Label.new()
	_care_status.name = "CareStatus"
	GameTheme.style_ink_label(_care_status)
	_care_status.add_theme_color_override("font_color", CARE_GREEN)
	care_panel.add_child(_care_status)
	_care_hint = Label.new()
	_care_hint.name = "CareHint"
	GameTheme.style_ink_label(_care_hint, true)
	_care_hint.clip_text = true
	_care_hint.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	care_panel.add_child(_care_hint)
	fruit_ready_card.color = Color(0, 0, 0, 0)
	_care_timer = Label.new()
	_care_timer.name = "CareFruitTimer"
	_care_timer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_care_timer.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_care_timer.add_theme_font_override("font", GameTheme.title_font())
	_care_timer.add_theme_font_size_override("font_size", GameTheme.TITLE_SIZE)
	_care_timer.add_theme_color_override("font_color", CARE_TIMER_CYAN)
	_care_timer.visible = false
	fruit_ready_card.add_child(_care_timer)
	GameTheme.style_ink_label(precommit_hint)
	precommit_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	for lbl: Label in [grow_fert_need, grow_ess_need]:
		GameTheme.style_ink_label(lbl)
		lbl.custom_minimum_size = Vector2(CARE_COST_COL_W - 40.0, 44)
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	for icon: TextureRect in [grow_fert_icon, grow_ess_icon]:
		icon.custom_minimum_size = Vector2(32, 32)
		icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	care_grow_costs.add_theme_constant_override("separation", 8)


## Mockup manatree540_pc_16x9_r3: 600 wide; header = stage line + Blessings + ×; a bevelled
## needs card; Grow/Harvest (primary, left) | Water (right); Enter Forge full width last.
## Height follows the content: 344 without Enter Forge, 400 with it (CARE_SIZE.y is the cap).
## The last row keeps 12 px clear of the 24 px frame.
func _care_window_h() -> float:
	var h: float = CARE_ACTION_END_Y + 24.0 + 12.0
	if forge_button != null and forge_button.visible:
		h += 12.0 + 44.0
	return minf(h, CARE_SIZE.y)


func _layout_care_window() -> void:
	var sz: Vector2 = Ui540.fit_kit_window(care_panel, Vector2(CARE_SIZE.x, _care_window_h()))
	var w: float = sz.x
	var h: float = sz.y
	var left: float = 28.0
	var inner: float = w - left * 2.0
	Ui540.place_close_button(care_close_button, w)
	Ui540.place_title_plank(care_title, w)
	if _blessings_preview_button:
		_blessings_preview_button.position = Vector2(CARE_SIZE.x - 124.0, 20.0)
		_blessings_preview_button.size = Vector2(44, 44)
	care_stage_label.position = Vector2(left, 30)
	care_stage_label.size = Vector2(w - 124.0 - 12.0 - left, 24)
	var card := Rect2(left, 84, inner, 160)
	if _care_card:
		_care_card.position = card.position
		_care_card.size = card.size
	care_needs_label.position = card.position + Vector2(14, 8)
	care_needs_label.size = Vector2(card.size.x - 28.0, 24)
	if _care_needs_hdr:
		_care_needs_hdr.position = card.position + Vector2(14, 32)
		_care_needs_hdr.size = Vector2(card.size.x - 28.0, 24)
	care_grow_costs.position = card.position + Vector2(14, 56)
	care_grow_costs.size = Vector2(card.size.x - 28.0, 44)
	if _care_status:
		_care_status.position = card.position + Vector2(14, 104)
		_care_status.size = Vector2(card.size.x - 28.0, 24)
	if _care_hint:
		_care_hint.position = card.position + Vector2(14, 128)
		_care_hint.size = Vector2(card.size.x - 28.0, 24)
	fruit_ready_card.position = card.position
	fruit_ready_card.size = card.size
	precommit_hint.position = Vector2(14, 10)
	precommit_hint.size = Vector2(card.size.x - 28.0, 70)
	if _care_timer:
		_care_timer.position = Vector2(14, 88)
		_care_timer.size = Vector2(card.size.x - 28.0, 48)
	care_action_band.set_anchors_preset(Control.PRESET_TOP_LEFT)
	care_action_band.position = Vector2(left, card.end.y + 12.0)
	care_action_band.size = Vector2(inner, 56)
	var half: float = floorf((inner - 12.0) * 0.5)
	pay_button.position = Vector2(0, 0)
	pay_button.size = Vector2(half, 52)
	harvest_fruit_button.position = pay_button.position
	harvest_fruit_button.size = pay_button.size
	water_button.position = Vector2(inner - half, 0)
	water_button.size = Vector2(half, 52)
	Ui540.fit_button_font(harvest_fruit_button, half)
	harvest_fruit_button.size = pay_button.size
	if forge_button:
		forge_button.position = Vector2(left, h - 36.0 - 44.0)
		forge_button.size = Vector2(inner, 44)


func _layout_care540() -> void:
	if care_panel:
		_layout_care_window()
	if bench_panel:
		_layout_bench540()


## Mockup workbench540_bench_pc_r2: 912×472, recipe list left (300 + scrollbar), detail and
## the batch controls right, × in the header.
func _layout_bench540() -> void:
	var sz: Vector2 = Ui540.fit_kit_window(bench_panel, BENCH_SIZE)
	var w: float = sz.x
	var h: float = sz.y
	Ui540.place_close_button(bench_close_button, w)
	Ui540.place_title_plank(bench_title, w)
	bench_prompt.position = Vector2(24, 30)
	bench_prompt.size = Vector2(w - 48.0 - Ui540.TAP_MIN_PX - 12.0, 24)
	if _bench_tabs:
		_bench_tabs.position = Vector2(24, 72)
		_bench_tabs.size = Vector2(BENCH_LIST_W, 44)
	var list_top: float = 130.0
	var scroll: ScrollContainer = bench_panel.get_node_or_null("CraftScroll") as ScrollContainer
	if scroll:
		scroll.position = Vector2(24, list_top)
		## Extra inset so the frame doesn't clip the last recipe, plus the list's own pad.
		scroll.size = Vector2(BENCH_LIST_W, h - 40.0 - list_top)
	var rx: float = 24.0 + BENCH_LIST_W + 20.0
	var rw: float = w - 24.0 - rx
	if _bench_detail:
		_bench_detail.position = Vector2(rx, 72)
		_bench_detail.size = Vector2(rw, BENCH_BATCH_Y - 72.0)
	if _bench_batch != null and is_instance_valid(_bench_batch):
		_bench_batch.custom_minimum_size = Vector2.ZERO
		_bench_batch.anchor_left = 0.0
		_bench_batch.anchor_top = 0.0
		_bench_batch.anchor_right = 1.0
		_bench_batch.anchor_bottom = 1.0
		_bench_batch.offset_left = rx
		_bench_batch.offset_top = BENCH_BATCH_Y
		_bench_batch.offset_right = -24.0
		_bench_batch.offset_bottom = -24.0


func _ensure_help_panel() -> void:
	if _help_panel != null:
		return
	_help_dim = ColorRect.new()
	_help_dim.name = "HelpDim"
	_help_dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_help_dim.color = Color(0, 0, 0, 0.5)
	_help_dim.visible = false
	_help_dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_help_dim.gui_input.connect(_on_help_dim_input)
	add_child(_help_dim)
	_help_panel = Panel.new()
	_help_panel.name = "HelpPanel"
	_help_panel.visible = false
	_help_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_help_panel)
	Ui540.apply_kit_panel(_help_panel, "help")
	var title := Label.new()
	title.name = "HelpTitle"
	title.text = "Help"
	title.position = Vector2((912.0 - 120.0) * 0.5, -20.0)
	title.size = Vector2(120, 40)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	GameTheme.style_plank_label(title)
	_help_panel.add_child(title)
	_help_close = Button.new()
	_help_close.name = "CloseButton"
	_help_close.position = Vector2(912.0 - 68.0, 18.0)
	_help_close.size = Vector2(44, 44)
	Ui540.configure_kit_close_button(_help_close)
	_help_close.pressed.connect(_close_help_panel)
	_help_panel.add_child(_help_close)
	var draft := Label.new()
	draft.name = "HelpDraftTag"
	draft.text = "DRAFT — for Lore"
	draft.position = Vector2(36, 28)
	draft.size = Vector2(200, 26)
	GameTheme.style_body_label(draft)
	draft.add_theme_color_override("font_color", Color(0.69, 0.44, 0.08))
	_help_panel.add_child(draft)
	_help_tab_pc = Button.new()
	_help_tab_pc.text = "PC"
	_help_tab_pc.position = Vector2(220, 28)
	_help_tab_pc.size = Vector2(120, 44)
	_help_tab_pc.pressed.connect(_set_help_tab.bind("pc"))
	Ui540.style_wood_icon_button(_help_tab_pc)
	_help_panel.add_child(_help_tab_pc)
	_help_tab_phone = Button.new()
	_help_tab_phone.text = "Phone"
	_help_tab_phone.position = Vector2(348, 28)
	_help_tab_phone.size = Vector2(120, 44)
	_help_tab_phone.pressed.connect(_set_help_tab.bind("phone"))
	Ui540.style_wood_icon_button(_help_tab_phone)
	_help_panel.add_child(_help_tab_phone)
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(36, 84)
	scroll.size = Vector2(840, 360)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_help_panel.add_child(scroll)
	_help_body = VBoxContainer.new()
	_help_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_help_body)
	_layout_help_panel()


func _make_help_row(row: Dictionary) -> HBoxContainer:
	var line := HBoxContainer.new()
	line.add_theme_constant_override("separation", 12)
	line.custom_minimum_size = Vector2(0, 28)
	var key_lbl := Label.new()
	key_lbl.custom_minimum_size = Vector2(140, 24)
	key_lbl.text = "[%s]" % str(row.get("key", ""))
	GameTheme.style_body_label(key_lbl)
	var act_lbl := Label.new()
	act_lbl.text = str(row.get("action", ""))
	act_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	act_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	GameTheme.style_body_label(act_lbl)
	line.add_child(key_lbl)
	line.add_child(act_lbl)
	return line


func _help_rows() -> Array[Dictionary]:
	if _help_tab == "phone":
		return [
			{"key": "Tap", "action": "Select · press buttons"},
			{"key": "Long-press (½ s)", "action": "Show what it is; on open ground: command"},
			{"key": "Pause button", "action": "Pause menu (top right)"},
		]
	return [
		{"key": "Left-click", "action": ContentStrings.get_text("controls_lmb_select")},
		{"key": "Right-click / G", "action": ContentStrings.get_text("controls_rmb_command")},
		{"key": "H", "action": "Inspect what is under the pointer"},
		{"key": "Arrow keys", "action": ContentStrings.get_text("controls_camera_pan")},
		{"key": "I", "action": ContentStrings.get_text("backpack_open")},
		{"key": "C", "action": ContentStrings.get_text("char_sheet_hotkey_hint")},
		{"key": "Esc", "action": "Close a window · Pause"},
	]


func _layout_help_panel() -> void:
	if _help_panel == null:
		return
	_help_panel.custom_minimum_size = Vector2(912, 472)
	_help_panel.size = Vector2(912, 472)
	Ui540.center_kit_panel(_help_panel)
	for child: Node in _help_body.get_children():
		child.free()
	var rows: Array[Dictionary] = _help_rows()
	if _help_tab == "pc":
		var cols_box := HBoxContainer.new()
		cols_box.add_theme_constant_override("separation", 20)
		var left := VBoxContainer.new()
		var right := VBoxContainer.new()
		left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var per_col: int = int(ceil(float(rows.size()) / 2.0))
		for i: int in range(rows.size()):
			var line: Control = _make_help_row(rows[i])
			if i < per_col:
				left.add_child(line)
			else:
				right.add_child(line)
		cols_box.add_child(left)
		cols_box.add_child(right)
		_help_body.add_child(cols_box)
		var pad := Label.new()
		pad.text = "Gamepad: not supported yet (menus follow Godot ui_ arrows only)."
		GameTheme.style_body_label(pad)
		pad.add_theme_color_override("font_color", Color(0.7, 0.64, 0.52))
		pad.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_help_body.add_child(pad)
	else:
		for row: Dictionary in rows:
			_help_body.add_child(_make_help_row(row))


func _set_help_tab(tab_id: String) -> void:
	_help_tab = tab_id
	_layout_help_panel()


func _toggle_help_panel() -> void:
	if _help_panel != null and _help_panel.visible:
		_close_help_panel()
	else:
		_open_help_panel()


func _open_help_panel() -> void:
	if _help_panel == null:
		_ensure_help_panel()
	close_backpack()
	close_character_sheet()
	_layout_help_panel()
	_help_dim.visible = true
	_help_panel.visible = true
	GameAudio.play_ui_open()


func _close_help_panel() -> void:
	if _help_panel:
		_help_panel.visible = false
	if _help_dim:
		_help_dim.visible = false
	GameAudio.play_ui_close()


func _on_help_dim_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			_close_help_panel()


func _layout_ascension_shop() -> void:
	if ascension_panel == null:
		return
	_ensure_shop_chrome()
	var sz: Vector2 = Ui540.fit_kit_window(ascension_panel, SHOP_SIZE)
	var w: float = sz.x
	var h: float = sz.y
	var right: float = w - SHOP_PAD
	Ui540.anchor_rect_safe(shop_header, 0, 0, w, SHOP_HEADER_H)
	Ui540.place_title_plank(prestige_title, w)
	Ui540.place_close_button(close_button, w)
	var chip_x: float = w - 24.0 - Ui540.TAP_MIN_PX - 12.0 - SHOP_CHIP_W
	Ui540.anchor_rect_safe(shard_chip, chip_x, 20, SHOP_CHIP_W, 44)
	Ui540.anchor_rect_safe(prestige_sub, SHOP_PAD, 30, chip_x - SHOP_PAD - 12.0, 24)
	prestige_sub.autowrap_mode = TextServer.AUTOWRAP_OFF
	prestige_sub.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	prestige_sub.clip_text = true
	_place_shop_preview_tag()
	if _shop_toolbar:
		var tw: float = _shop_toolbar.get_combined_minimum_size().x
		Ui540.anchor_rect_safe(_shop_toolbar, right - tw, 72, tw, 44)
	var has_footer: bool = ascend_button.visible
	var foot_y: float = h - 24.0 - SHOP_FOOTER_BTN_H
	var list_bottom: float = (foot_y - 12.0) if has_footer else (h - 24.0)
	Ui540.anchor_rect_safe(_shop_list_bevel, SHOP_PAD, SHOP_LIST_Y, right - SHOP_PAD, list_bottom - SHOP_LIST_Y)
	shop_scroll.set_anchors_preset(Control.PRESET_TOP_LEFT)
	shop_scroll.position = Vector2(SHOP_PAD + 2.0, SHOP_LIST_Y + 2.0)
	shop_scroll.size = Vector2(right - SHOP_PAD - 4.0, list_bottom - SHOP_LIST_Y - 4.0)
	Ui540.anchor_rect_safe(shop_footer, 0, foot_y, w, SHOP_FOOTER_BTN_H)
	Ui540.anchor_rect_safe(ascend_button, right - 240.0, 0, 240, SHOP_FOOTER_BTN_H)
	Ui540.anchor_rect_safe(_shop_footer_hint, SHOP_PAD, 0, right - 240.0 - 12.0 - SHOP_PAD, SHOP_FOOTER_BTN_H)
	_shop_footer_hint.visible = has_footer
	if has_node("/root/GameInput"):
		GameInput.configure_scroll_container(shop_scroll)


func _ensure_shop_chrome() -> void:
	if _shop_list_bevel != null:
		return
	_shop_list_bevel = Panel.new()
	_shop_list_bevel.name = "ShopListBevel"
	_shop_list_bevel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_shop_list_bevel.add_theme_stylebox_override("panel", Ui540.kit_stylebox_9s("res://assets/ui/theme/play_bevel_9s_6x6.png", Vector4i(2, 2, 2, 2)))
	ascension_panel.add_child(_shop_list_bevel)
	ascension_panel.move_child(_shop_list_bevel, shop_scroll.get_index())
	upgrade_list.add_theme_constant_override("separation", 4)
	_shop_preview_tag = Label.new()
	_shop_preview_tag.name = "PreviewTag"
	_shop_preview_tag.text = ContentStrings.get_text("ascend_shop_preview_tag")
	GameTheme.style_ink_label(_shop_preview_tag)
	_shop_preview_tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_shop_preview_tag.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_shop_preview_tag.add_theme_stylebox_override("normal", Ui540.kit_stylebox_9s(
		"res://assets/ui/theme/action_button_hover_160x44.png", Vector4i(6, 6, 6, 6), Vector4(10, 0, 10, 0)))
	_shop_preview_tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_shop_preview_tag.z_index = 1
	shop_header.add_child(_shop_preview_tag)
	_shop_footer_hint = Label.new()
	_shop_footer_hint.name = "AscendHint"
	_shop_footer_hint.text = ContentStrings.get_text("ascension_paused_hint")
	GameTheme.style_ink_label(_shop_footer_hint, true)
	_shop_footer_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_shop_footer_hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_shop_footer_hint.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	shop_footer.add_child(_shop_footer_hint)
	shard_chip.color = SHOP_CHIP_BG
	var icon: TextureRect = shard_chip.get_node("ShardIcon") as TextureRect
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	Ui540.anchor_rect_safe(icon, 10, 6, 32, 32)
	Ui540.anchor_rect_safe(shard_count_label, 48, 0, SHOP_CHIP_W - 56.0, 44)
	shard_count_label.remove_theme_font_size_override("font_size")
	shard_count_label.add_theme_font_override("font", load(GameTheme.PRIMARY_FONT_PATH) as Font)
	shard_count_label.add_theme_font_size_override("font_size", GameTheme.TITLE_HERO_SIZE)
	shard_count_label.add_theme_color_override("font_color", GameTheme.CREAM_BTN)
	shard_count_label.add_theme_color_override("font_outline_color", GameTheme.OUTLINE)
	shard_count_label.add_theme_constant_override("outline_size", 2)
	shard_count_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER


func _place_shop_preview_tag() -> void:
	if _shop_preview_tag == null:
		return
	_shop_preview_tag.visible = _shop_preview_mode
	var font: Font = _shop_preview_tag.get_theme_font("font")
	var tw: float = ceilf(font.get_string_size(_shop_preview_tag.text, HORIZONTAL_ALIGNMENT_LEFT, -1, GameTheme.BODY_SIZE).x + 20.0)
	## Header row, left of the shard chip; the subline gives way to it.
	var tag_x: float = shard_chip.position.x - 12.0 - tw
	Ui540.anchor_rect_safe(_shop_preview_tag, tag_x, shard_chip.position.y + 9.0, tw, 26)
	if _shop_preview_mode:
		prestige_sub.size.x = minf(prestige_sub.size.x, tag_x - 12.0 - prestige_sub.position.x)


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
	var pause_tex: Texture2D = load(HUD_PAUSE_ICON) as Texture2D
	if pause_icon and pause_tex:
		pause_icon.texture = pause_tex
	else:
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
	var swatch: Color = PLACEHOLDER_SWATCH
	if has_node("/root/Backpack") and Backpack.is_known_item(item_id):
		var hex: String = str(Backpack.get_item_def(item_id).get("color", ""))
		if hex != "":
			swatch = Backpack.item_color(item_id)
	var placeholder := _placeholder_icon(swatch)
	placeholder.tooltip_text = tip
	return placeholder


func _apply_wood_chrome() -> void:
	Ui540.apply_kit_panel(ascension_panel, "ascension_shop", prestige_title, close_button)
	GameTheme.style_plank_label(prestige_title)
	GameTheme.style_ink_label(prestige_sub, true)
	GameTheme.style_primary_button(ascend_button)
	_apply_icon_button(character_button)
	_apply_icon_button(backpack_button)
	_apply_icon_button(pause_button)
	_apply_icon_button(ascension_reopen_button)


func _process(_delta: float) -> void:
	_refresh_ancient_countdown()
	_refresh_nav_button()
	_refresh_frozen_banner()
	_refresh_speed_button()
	_refresh_play_speed_button()
	if _keeper_activity != null:
		_refresh_actor_activities(GameState.elaia_portrait_visible(), GameState.keeper_selected, str(GameState.selected_companion_id))
	_settle_world_labels()
	_sync_toast_under_modals()


## The status toast is world feedback. Any modal (HUD windows, pause, board, runestone,
## debug, battle) covers it; self_modulate leaves the toast's own fade tween alone.
## The HUD chrome ($Panel: resource bar, speed, pause, help, bottom buttons) steps aside too:
## wide windows start at y 46, so the bar would otherwise peek out above their frame.
func _sync_toast_under_modals() -> void:
	var modal: bool = modal_window_open()
	var a: float = 0.0 if modal else 1.0
	if panel:
		panel.visible = not modal
	hold_pause_button_over_dim(_pause_menu_is_open())
	## The Keeper portrait and Idle label sit in the party column, outside $Panel.
	if _party_bar:
		_party_bar.visible = not modal
	var wisps: CanvasItem = get_node_or_null("WispCounter") as CanvasItem
	if wisps:
		wisps.self_modulate.a = a
	if status_label:
		status_label.self_modulate.a = a
	if toast_shade:
		toast_shade.self_modulate.a = a
	if _ancient_countdown:
		_ancient_countdown.self_modulate.a = a


var _pause_button_lifted: bool = false


func hold_pause_button_over_dim(hold: bool) -> void:
	## The phone pause control stays on the pause layer, above the dim, while pause is open.
	if pause_button == null or not is_instance_valid(pause_button):
		return
	if hold == _pause_button_lifted and ((not hold) or pause_button.get_parent() != panel):
		if hold:
			pause_button.visible = true
			pause_button.modulate = Color.WHITE
		return
	_pause_button_lifted = hold
	if hold:
		var menu: Node = _open_pause_layer()
		if menu == null:
			_pause_button_lifted = false
			return
		var at: Vector2 = pause_button.global_position
		pause_button.get_parent().remove_child(pause_button)
		menu.add_child(pause_button)
		pause_button.global_position = at
		pause_button.visible = true
		pause_button.modulate = Color.WHITE
		pause_button.z_index = 20
		return
	if panel != null and pause_button.get_parent() != panel:
		var back: Vector2 = pause_button.global_position
		pause_button.get_parent().remove_child(pause_button)
		panel.add_child(pause_button)
		pause_button.global_position = back
		pause_button.z_index = 0
		_layout_hud540()


func _pause_menu_is_open() -> bool:
	return _open_pause_layer() != null


func _open_pause_layer() -> Node:
	var tree: SceneTree = get_tree()
	if tree == null:
		return null
	for menu: Node in tree.get_nodes_in_group("pause_menu"):
		if menu.has_method("is_open") and bool(menu.call("is_open")):
			return menu
	return null


func modal_window_open() -> bool:
	if _kit_window_obscures_world():
		return true
	if (_ancient_confirm != null and _ancient_confirm.visible) or (_spoiler_dialog != null and _spoiler_dialog.visible):
		return true
	if (_footsteps_popup != null and _footsteps_popup.visible) or (_forge_popup != null and _forge_popup.visible):
		return true
	var tree: SceneTree = get_tree()
	for menu: Node in tree.get_nodes_in_group("pause_menu"):
		if menu is CanvasItem or menu is CanvasLayer:
			if bool(menu.get("visible")):
				return true
	for board: Node in tree.get_nodes_in_group("expedition_board"):
		if board.has_method("shell_open") and bool(board.call("shell_open")):
			return true
	for stone: Node in tree.get_nodes_in_group("runestone"):
		if stone.has_method("is_spend_confirm_open") and bool(stone.call("is_spend_confirm_open")):
			return true
	if has_node("/root/AnimPreviewHotkey") and AnimPreviewHotkey.debug_panel_open():
		return true
	return BattleView.is_open()


func _refresh_dim() -> void:
	if shop_dim == null:
		return
	var ancient_open: bool = _ancient_confirm != null and _ancient_confirm.visible
	shop_dim.visible = fruit_confirm_panel.visible or ascension_panel.visible or ancient_open
	## A confirm over the shop dims the shop too (kit_dialog's second dim).
	var over_shop: bool = (_spoiler_dialog != null and _spoiler_dialog.visible) \
		or (_ascend_batch_dialog != null and _ascend_batch_dialog.visible)
	shop_dim.z_index = Z_MODAL + 1 if over_shop else Z_MODAL_DIM
	if backpack_dim:
		backpack_dim.visible = backpack_panel.visible or bench_panel.visible


func bind_manatree(tree: Manatree) -> void:
	_manatree = tree


func maybe_show_welcome() -> void:
	if GameState.welcome_shown:
		return
	show_welcome()


func _layout_welcome_panel() -> void:
	if welcome_panel == null:
		return
	welcome_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	welcome_panel.offset_left = 0.0
	welcome_panel.offset_top = 0.0
	welcome_panel.offset_right = 0.0
	welcome_panel.offset_bottom = 0.0
	## intro540: the scene dims and the kit card (600×306, "Keeper" plank) holds the boot line,
	## the body, the muted hint and one primary button.
	welcome_panel.color = Color(0, 0, 0, 0.5)
	welcome_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var vs: Vector2 = Ui540.viewport_size()
	var card_w: float = 600.0
	var card_h: float = 306.0
	var card_x: float = roundf((vs.x - card_w) * 0.5)
	var card_y: float = roundf((vs.y - card_h) * 0.5 + 22.0)
	var card := welcome_panel.get_node_or_null("WelcomeCard") as Panel
	if card == null:
		card = Panel.new()
		card.name = "WelcomeCard"
		card.mouse_filter = Control.MOUSE_FILTER_IGNORE
		welcome_panel.add_child(card)
		welcome_panel.move_child(card, 0)
		Ui540.apply_kit_frame_panel(card, "intro")
	card.position = Vector2(card_x, card_y)
	card.size = Vector2(card_w, card_h)
	for lbl: Label in [welcome_boot_label, welcome_title_label, welcome_body_label, welcome_hint_label]:
		lbl.set_anchors_preset(Control.PRESET_TOP_LEFT)
	## Scene caption above the card, not a line inside it.
	welcome_boot_label.position = Vector2(24.0, 96.0)
	welcome_boot_label.size = Vector2(vs.x - 48.0, 28.0)
	welcome_boot_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	welcome_boot_label.remove_theme_color_override("font_outline_color")
	welcome_boot_label.remove_theme_constant_override("outline_size")
	GameTheme.style_ink_label(welcome_boot_label, true)
	if welcome_title_label.get_parent() != card:
		welcome_title_label.reparent(card, false)
	Ui540.place_title_plank(welcome_title_label, card_w)
	welcome_body_label.position = Vector2(card_x + 40.0, card_y + 58.0)
	welcome_body_label.size = Vector2(card_w - 80.0, 124.0)
	welcome_body_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	welcome_body_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	welcome_body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	GameTheme.style_ink_label(welcome_body_label)
	welcome_body_label.add_theme_constant_override("line_spacing", 4)
	welcome_hint_label.position = Vector2(card_x + 40.0, card_y + 186.0)
	welcome_hint_label.size = Vector2(card_w - 80.0, 24.0)
	welcome_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	GameTheme.style_ink_label(welcome_hint_label, true)
	welcome_dismiss_button.set_anchors_preset(Control.PRESET_TOP_LEFT)
	welcome_dismiss_button.position = Vector2(card_x + (card_w - 260.0) * 0.5, card_y + card_h - 28.0 - 52.0)
	welcome_dismiss_button.size = Vector2(260, 52)
	GameTheme.style_primary_button(welcome_dismiss_button)


func show_welcome() -> void:
	close_backpack()
	close_character_sheet()
	hide_care_menu()
	hide_fruit_confirm()
	hide_ascension_shop()
	_layout_welcome_panel()
	welcome_boot_label.text = ContentStrings.get_text("welcome_boot")
	welcome_title_label.text = ContentStrings.get_text("welcome_title")
	welcome_body_label.text = ContentStrings.get_text("welcome_body")
	welcome_hint_label.text = ContentStrings.get_text("welcome_hint")
	welcome_dismiss_button.text = ContentStrings.get_text("welcome_dismiss")
	## Arming ignores presses for 1.5 s; the button shows its primary face from the first frame.
	_welcome_dismiss_ready = false
	welcome_dismiss_button.disabled = false
	if _welcome_delay_tween != null and is_instance_valid(_welcome_delay_tween):
		_welcome_delay_tween.kill()
	_welcome_delay_tween = create_tween()
	_welcome_delay_tween.tween_interval(1.5)
	_welcome_delay_tween.tween_callback(_enable_welcome_dismiss)
	welcome_panel.visible = true
	_play_welcome_beats()
	GameAudio.play_ui_open()


func _play_welcome_beats() -> void:
	## Boot line alone, then the card fades in.
	var card: CanvasItem = welcome_panel.get_node_or_null("WelcomeCard") as CanvasItem
	var hidden: Array[CanvasItem] = [welcome_body_label, welcome_hint_label, welcome_dismiss_button, welcome_title_label]
	if card:
		hidden.append(card)
	for item: CanvasItem in hidden:
		if item:
			item.modulate.a = 0.0
	welcome_boot_label.modulate.a = 1.0
	var tw: Tween = create_tween()
	tw.tween_interval(1.2)
	for item: CanvasItem in hidden:
		if item:
			tw.parallel().tween_property(item, "modulate:a", 1.0, 0.35)


func _enable_welcome_dismiss() -> void:
	_welcome_dismiss_ready = true


func hide_welcome() -> void:
	welcome_panel.visible = false


func _fade_hud_in() -> void:
	var pieces: Array[CanvasItem] = []
	if panel:
		pieces.append(panel)
	if _party_bar:
		pieces.append(_party_bar)
	if pause_button:
		pieces.append(pause_button)
	for item: CanvasItem in pieces:
		item.modulate.a = 0.0
	var tw: Tween = create_tween()
	for item: CanvasItem in pieces:
		tw.parallel().tween_property(item, "modulate:a", 1.0, 0.45)


func _on_welcome_dismiss() -> void:
	if not _welcome_dismiss_ready:
		return
	GameState.welcome_shown = true
	hide_welcome()
	_fade_hud_in()
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


const PARTY_SLOT: float = 44.0
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
	_party_bar.z_index = 20
	_party_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_party_bar.clip_contents = true
	_party_column = VBoxContainer.new()
	_party_column.name = "Column"
	_party_column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_party_column.add_theme_constant_override("separation", int(PARTY_PITCH_R4 - PARTY_SLOT))
	_slot_elaia = _make_party_slot("Elaia", "elaia")
	_slot_wisp = _make_party_slot("Wisps", "wisp")
	_slot_keeper = _make_party_slot("Keeper", "keeper")
	_wisp_count_label = Label.new()
	_wisp_count_label.name = "Count"
	_wisp_count_label.position = Vector2(22, 30)
	_wisp_count_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_style_world_label(_wisp_count_label)
	_slot_wisp.add_child(_wisp_count_label)
	_party_column.add_child(_slot_elaia)
	_party_column.add_child(_slot_wisp)
	_party_column.add_child(_slot_keeper)
	_party_bar.add_child(_party_column)
	_party_info = VBoxContainer.new()
	_party_info.name = "Info"
	_party_info.visible = false
	_party_info.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_sel_name = Label.new()
	_sel_name.name = "Name"
	_sel_extra = Label.new()
	_sel_extra.name = "Extra"
	_sel_task = Label.new()
	_sel_task.name = "Task"
	_sel_job = Label.new()
	_sel_job.name = "JobLine"
	_party_info.add_child(_sel_name)
	_party_info.add_child(_sel_extra)
	_party_info.add_child(_sel_task)
	_party_info.add_child(_sel_job)
	_party_bar.add_child(_party_info)
	_keeper_activity = _make_activity_label("KeeperActivity", 62.0)
	_elaia_activity = _make_activity_label("ElaiaActivity", 124.0)
	_keeper_activity.visible = false
	_elaia_activity.visible = false
	_party_bar.add_child(_keeper_activity)
	_party_bar.add_child(_elaia_activity)
	_party_tag = PanelContainer.new()
	_party_tag.name = "ActivityTag"
	_party_tag.visible = false
	_party_tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_party_tag.add_theme_stylebox_override(
		"panel",
		Ui540.kit_stylebox_9s(HUD_KIT_TOAST, Vector4i(12, 8, 12, 8), Vector4(10, 4, 10, 4)),
	)
	_party_tag_label = Label.new()
	_party_tag_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	GameTheme.style_body_label(_party_tag_label)
	_party_tag.add_child(_party_tag_label)
	_party_bar.add_child(_party_tag)
	add_child(_party_bar)
	var keeper_tex: Texture2D = _actor_portrait_texture("keeper")
	var wisp_tex: Texture2D = load(CharacterSheet.WISP_PORTRAIT_PATH) as Texture2D
	(_slot_keeper.get_node("Portrait") as TextureRect).texture = keeper_tex
	(_slot_wisp.get_node("Portrait") as TextureRect).texture = wisp_tex
	(_slot_elaia.get_node("Portrait") as TextureRect).texture = _actor_portrait_texture("elaia")
	_slot_elaia.visible = false
	_slot_elaia.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _actor_portrait_texture(actor: String) -> Texture2D:
	## Path and optional crop live in companions.json. The sheet uses the full idle figure.
	if has_node("/root/GameState") and GameState.has_method("actor_portrait_texture"):
		var tex: Texture2D = GameState.actor_portrait_texture(actor)
		if tex != null:
			return tex
	if actor == "elaia":
		return load(CharacterSheet.ELAIA_PARTY_PORTRAIT_PATH) as Texture2D
	return load(CharacterSheet.KEEPER_PARTY_PORTRAIT_PATH) as Texture2D


func _make_party_slot(slot_name: String, unit: String) -> Control:
	var host := Control.new()
	host.name = slot_name
	host.custom_minimum_size = Vector2(PARTY_SLOT, PARTY_SLOT)
	host.size = Vector2(PARTY_SLOT, PARTY_SLOT)
	host.mouse_filter = Control.MOUSE_FILTER_STOP
	host.gui_input.connect(_on_party_slot_input.bind(unit, host))
	if not Ui540.is_phone_export():
		host.tooltip_text = slot_name
	var face := Panel.new()
	face.name = "Face"
	face.mouse_filter = Control.MOUSE_FILTER_IGNORE
	face.position = Vector2.ZERO
	face.size = Vector2(PARTY_SLOT, PARTY_SLOT)
	face.add_theme_stylebox_override(
		"panel",
		Ui540.kit_stylebox_9s("res://assets/ui/theme/wood_button_9s_normal_32x28.png", Vector4i(6, 6, 6, 6)),
	)
	host.add_child(face)
	var frame := Panel.new()
	frame.name = "Frame"
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.position = Vector2.ZERO
	frame.size = Vector2(PARTY_SLOT, PARTY_SLOT)
	frame.z_index = 1
	host.add_child(frame)
	var portrait := TextureRect.new()
	portrait.name = "Portrait"
	portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	portrait.position = Vector2(4, 3)
	portrait.size = Vector2(PARTY_SLOT - 8.0, PARTY_SLOT - 9.0)
	host.add_child(portrait)
	return host


func _style_party_label(label: Label, size: int, color: Color) -> void:
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0.05, 0.04, 0.03, 1.0))
	label.add_theme_constant_override("outline_size", 4)


func _set_party_outline(slot: Control, selected: bool) -> void:
	var frame := slot.get_node("Frame") as Panel
	frame.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	var glow: Control = slot.get_node_or_null("SelectGlow") as Control
	if glow == null:
		glow = Control.new()
		glow.name = "SelectGlow"
		glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
		glow.position = Vector2(-6, -6)
		glow.size = Vector2(PARTY_SLOT + 12.0, PARTY_SLOT + 12.0)
		glow.z_index = 2
		glow.draw.connect(_draw_party_glow.bind(glow))
		slot.add_child(glow)
	glow.visible = selected
	glow.queue_redraw()


func _draw_party_glow(glow: Control) -> void:
	## Square ring plus an ordered dither that falls off by 6 px.
	var ink := Color8(143, 227, 230)
	var inner := Rect2(Vector2(6, 6), Vector2(PARTY_SLOT, PARTY_SLOT))
	glow.draw_rect(inner, ink, false, 2.0)
	for d: int in range(1, 7):
		var alpha: float = 0.55 * (1.0 - float(d) / 6.0)
		var x0: int = 6 - d
		var y0: int = 6 - d
		var x1: int = 6 + int(PARTY_SLOT) + d
		var y1: int = 6 + int(PARTY_SLOT) + d
		for x: int in range(x0, x1):
			for y: int in range(y0, y1):
				var edge: bool = x == x0 or x == x1 - 1 or y == y0 or y == y1 - 1
				if not edge:
					continue
				if ((x + y) & 1) != (d & 1):
					continue
				var px := ink
				px.a = alpha
				glow.draw_rect(Rect2(Vector2(x, y), Vector2.ONE), px, true)


func _set_party_away_visual(slot: Control, away: bool) -> void:
	if slot == null:
		return
	var portrait := slot.get_node_or_null("Portrait") as CanvasItem
	if portrait:
		portrait.modulate = Color(0.42, 0.44, 0.42, 1.0) if away else Color.WHITE
	slot.mouse_filter = Control.MOUSE_FILTER_IGNORE if away else Control.MOUSE_FILTER_STOP


func _on_party_slot_input(event: InputEvent, unit: String, slot: Control) -> void:
	if not (event is InputEventMouseButton):
		return
	var mb: InputEventMouseButton = event
	if not mb.pressed or mb.button_index != MOUSE_BUTTON_LEFT:
		return
	## Grab the viewport before a view swap. The swap is deferred, and this node
	## can already be leaving the tree by the time the handler finishes.
	var viewport: Viewport = get_viewport()
	party_click(unit)
	if mb.double_click:
		party_focus(unit)
	## The click is the portrait, not a ground order. Do not walk or clear the job.
	if is_instance_valid(slot):
		slot.accept_event()
	if viewport != null and is_instance_valid(viewport):
		viewport.set_input_as_handled()


func party_click(unit: String) -> void:
	if unit == "elaia" and not GameState.elaia_portrait_visible():
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


func party_focus(unit: String = "") -> void:
	## Double-click centres that character. Switch the view if they are in the other place. Do not move them.
	if unit == "keeper" or unit == "elaia":
		var area: String = GameState.keeper_area if unit == "keeper" else GameState.elaia_area
		var want_forge: bool = area == "forge"
		if has_node("/root/ForgeJobs") and ForgeJobs.in_forge_scene() != want_forge:
			GameState.pending_focus_actor = unit
			ForgeJobs.switch_view(want_forge)
			return
	var scene: Node = get_tree().current_scene
	if unit != "" and scene and scene.has_method("focus_actor"):
		scene.call("focus_actor", unit)
		return
	if scene and scene.has_method("focus_selection"):
		scene.call("focus_selection")


func _refresh_party_bar() -> void:
	if _party_bar == null:
		return
	var ids: Array[int] = GameState.selected_wisp_list()
	var show_keeper: bool = GameState.keeper_selected
	var companion_id: String = str(GameState.selected_companion_id)
	var elaia_joined: bool = GameState.elaia_portrait_visible()
	_party_bar.visible = not modal_window_open()
	_slot_keeper.visible = true
	_slot_elaia.visible = elaia_joined
	_slot_elaia.mouse_filter = Control.MOUSE_FILTER_STOP if elaia_joined else Control.MOUSE_FILTER_IGNORE
	_set_party_away_visual(_slot_keeper, GameState.member_away("keeper"))
	_set_party_away_visual(_slot_elaia, elaia_joined and GameState.member_away("elaia"))
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
	_layout_party_bar_r4(Ui540.viewport_size(), Ui540.SAFE_MARGIN_PX, 0.0)
	_refresh_actor_activities(elaia_joined, show_keeper, companion_id)
	_clear_shared_activity()
	_update_party_activity_tag(show_keeper, companion_id, ids)


func _update_party_activity_tag(_show_keeper: bool, _companion_id: String, _wisp_ids: Array[int]) -> void:
	## The parchment under a selected portrait is gone for every actor, Idle included.
	if _party_tag == null:
		return
	_party_tag.visible = false
	if _party_tag_label:
		_party_tag_label.text = ""


func _clear_shared_activity() -> void:
	## Activity lives on each portrait. The old shared box stays in the tree for lookups and stays blank.
	if _sel_name:
		_sel_name.text = ""
	if _sel_extra:
		_sel_extra.text = ""
		_sel_extra.visible = false
	if _sel_task:
		_sel_task.text = ""
		_sel_task.visible = false
	if _sel_job:
		_sel_job.text = ""
		_sel_job.visible = false
	if _party_info:
		_party_info.visible = false


func _hide_party_info_for_sheet() -> void:
	_clear_shared_activity()


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


func _on_reach_party_changed() -> void:
	_refresh_party_bar()


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
	var is_ancient: bool = bool(info.get("is_ancient", false))
	var can_pay_now: bool = bool(info.get("can_pay", false))
	## Mockup r3: "Toward …", "Needs", the icon checklist, "Ready to Grow" only when payable,
	## and the grow hint. The cost sentences that repeated the checklist are gone.
	if is_ancient:
		care_needs_label.text = "\n".join(lines)
		care_needs_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		care_needs_label.size.y = 140.0
	else:
		care_needs_label.text = str(info.get("title", ""))
		care_needs_label.autowrap_mode = TextServer.AUTOWRAP_OFF
		care_needs_label.size.y = 24.0
	care_needs_label.visible = not fruit_ready
	if _care_card:
		_care_card.visible = true
	if _care_needs_hdr:
		_care_needs_hdr.text = header
		_care_needs_hdr.visible = not fruit_ready and not is_ancient
	if _care_status:
		_care_status.text = ContentStrings.get_text("tree_grow_ready")
		_care_status.visible = not fruit_ready and not is_ancient and can_pay_now
	if _care_hint:
		_care_hint.text = ContentStrings.get_text("tree_grow_hint")
		_care_hint.visible = not fruit_ready and not is_ancient
	var can_pay: bool = bool(info.get("can_pay", false))
	pay_button.visible = not is_ancient
	pay_button.text = ContentStrings.get_text("tree_grow")
	## Stays tappable when short, so a press can flash the missing line.
	pay_button.disabled = false
	_refresh_grow_cost_icons(info, is_ancient)
	water_button.visible = not GameState.fruit_committed
	water_button.text = ContentStrings.get_text("tree_interact_water")
	harvest_fruit_button.visible = fruit_ready
	harvest_fruit_button.text = ContentStrings.get_text("fruit_ready_prompt")
	_refresh_forge_entry()
	_layout_care_window()
	_paint_grow_face(can_pay)
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
	counter.size = Vector2(160, 28)
	counter.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	counter.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	counter.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_style_world_label(counter)
	add_child(counter)
	counter.z_index = 25
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
	_forge_popup.z_index = 45
	_forge_popup.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_forge_popup)
	Ui540.apply_kit_panel(_forge_popup, "forge_popup")
	_forge_popup_body = Label.new()
	_forge_popup_body.name = "Body"
	_forge_popup_body.position = Vector2(28, 28)
	_forge_popup_body.size = Vector2(364, 50)
	_forge_popup_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_forge_popup_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_forge_popup_body.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	GameTheme.style_ink_label(_forge_popup_body)
	_forge_popup.add_child(_forge_popup_body)
	var close := Button.new()
	close.name = "Close"
	close.anchor_left = 0.5
	close.anchor_right = 0.5
	close.anchor_top = 1.0
	close.anchor_bottom = 1.0
	close.offset_left = -80.0
	close.offset_right = 80.0
	close.offset_top = -68.0
	close.offset_bottom = -24.0
	close.text = ContentStrings.get_text("btn_close")
	close.pressed.connect(hide_forge_popup)
	GameTheme.style_wood_button(close)
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
	forge_button.disabled = false
	var owns_key: bool = GameState.forge_key
	if has_node("/root/ForgeJobs"):
		owns_key = ForgeJobs.owns_forge_key()
	_forge_locked = not owns_key
	## Locked stays tappable (it explains the key), so it borrows the disabled face instead
	## of disabling the button.
	GameTheme.style_menu_button(forge_button)
	for state: StringName in [&"normal", &"hover", &"pressed", &"focus"]:
		forge_button.remove_theme_stylebox_override(state)
	if _forge_locked:
		forge_button.text = "%s  ·  %s" % [ContentStrings.get_text("forge_enter"), ContentStrings.get_text("forge_locked_hint")]
		var dis: StyleBox = forge_button.get_theme_stylebox("disabled")
		for state: StringName in [&"normal", &"hover", &"pressed"]:
			forge_button.add_theme_stylebox_override(state, dis)
		for state: StringName in [&"font_color", &"font_hover_color", &"font_pressed_color", &"font_focus_color"]:
			forge_button.add_theme_color_override(state, forge_button.get_theme_color("font_disabled_color"))
	else:
		forge_button.text = ContentStrings.get_text("forge_enter")
	## Same face size as Grow and Water. The long locked line is not shrunk.
	forge_button.remove_theme_font_override("font")
	forge_button.remove_theme_font_size_override("font_size")
	var lock_icon: Texture2D = load("res://assets/art/ui/board/lock_10x12.png") as Texture2D
	forge_button.icon = lock_icon if _forge_locked else null
	forge_button.expand_icon = false
	forge_button.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT


func is_forge_entry_visible() -> bool:
	return forge_button != null and forge_button.visible


func is_forge_entry_gray() -> bool:
	return forge_button != null and forge_button.visible and _forge_locked


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
	if has_node("/root/ForgeJobs") and (ForgeJobs.can_enter_forge() or GameState.forge_visited):
		return ForgeJobs.travel_to_forge()
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
	return ascension_panel.visible and not _shop_preview_mode


func is_shop_preview_open() -> bool:
	return ascension_panel.visible and _shop_preview_mode


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
		"preferred_h": _care_window_h(),
	}


func get_fruit_confirm_step() -> int:
	return _fruit_confirm_step


func show_ascension_shop_preview() -> void:
	_shop_preview_mode = true
	_open_ascension_shop_internal(false)


func show_ascension_shop() -> void:
	if welcome_panel.visible:
		return
	if _pause_menu and _pause_menu.is_open():
		return
	if not GameState.fruit_harvested_pending_ascend:
		return
	_shop_preview_mode = false
	_open_ascension_shop_internal(true)


func _open_ascension_shop_internal(ascend_pause: bool) -> void:
	if welcome_panel.visible:
		return
	if _pause_menu and _pause_menu.is_open():
		return
	backpack_panel.visible = false
	close_character_sheet()
	hide_care_menu()
	hide_fruit_confirm()
	if ascend_pause:
		_hold_world_for_ascension()
	else:
		_release_world_if_allowed()
	_confirm_ascend = false
	_highlight_ascend = ascend_pause
	ascension_panel.visible = true
	_confirm_batches = false
	_hide_ascend_batch_dialog()
	_sync_shop_toolbar()
	GameAudio.play_ui_open()
	_rebuild_upgrades()
	_refresh_ascension_copy()
	_refresh_reopen_button()
	_refresh_frozen_banner()
	_refresh_dim()
	if ascend_pause:
		_apply_ascend_highlight()
	else:
		_clear_ascend_highlight()


func hide_ascension_shop() -> void:
	if ascension_panel.visible:
		GameAudio.play_ui_close()
	ascension_panel.visible = false
	_shop_preview_mode = false
	_confirm_ascend = false
	_confirm_batches = false
	_hide_ascend_batch_dialog()
	_highlight_ascend = false
	_clear_ascend_highlight()
	_refresh_reopen_button()
	_refresh_frozen_banner()
	_refresh_dim()


func _on_shop_close() -> void:
	## Close cancels the harvest lock. Play resumes; Fruit can be harvested again.
	## The run locks only when Ascend actually commits.
	var preview: bool = _shop_preview_mode
	var cancelled_commit: bool = (
		not preview and GameState.fruit_committed and not GameState.ancient_frozen
	)
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
	## One box. Yes harvests. There is no second prompt.
	if _fruit_confirm_step != 1:
		return
	_commit_primordial_fruit()


func cancel_fruit_confirm() -> void:
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
	## One confirmation. Both the intent and the commit copy sit in the same box.
	fruit_confirm_panel.visible = true
	fruit_confirm_title.text = ContentStrings.get_text("fruit_confirm_step2_title")
	fruit_confirm_body.text = "%s\n\n%s" % [
		ContentStrings.get_text("fruit_confirm_step1"),
		ContentStrings.get_text("fruit_confirm_step2"),
	]
	fruit_confirm_yes.text = ContentStrings.get_text("fruit_confirm_step2_yes")
	fruit_confirm_no.text = ContentStrings.get_text("fruit_confirm_step1_no")
	Ui540.layout_confirm(fruit_confirm_panel, fruit_confirm_title, fruit_confirm_body, fruit_confirm_yes, fruit_confirm_no)
	fruit_confirm_no.grab_focus.call_deferred()
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
		grow_fert_need.text = ContentStrings.get_text("tree_grow_cost_fertilizer", {"have": fert_have, "need": fert_need})
		grow_fert_need.add_theme_color_override("font_color", CARE_GREEN if fert_have >= fert_need else GameTheme.INK)
		grow_fert_need.tooltip_text = ContentStrings.get_text(fert_key, {
			"item": ContentStrings.get_text("fertilizer_name"),
			"have": fert_have,
			"need": fert_need,
		})
	if grow_ess_need:
		var ess_key: String = "tree_grow_cost_essence" if ess_have < ess_need else "tree_grow_cost_essence_met"
		grow_ess_need.text = ContentStrings.get_text("tree_grow_cost_essence", {"have": ess_have, "need": ess_need})
		grow_ess_need.add_theme_color_override("font_color", CARE_GREEN if ess_have >= ess_need else GameTheme.INK)
		grow_ess_need.tooltip_text = ContentStrings.get_text(ess_key, {
			"item": ContentStrings.get_text("hud_essence"),
			"have": ess_have,
			"need": ess_need,
		})


func _paint_grow_face(can_pay: bool) -> void:
	if pay_button == null:
		return
	for state: StringName in [&"normal", &"hover", &"pressed", &"focus"]:
		pay_button.remove_theme_stylebox_override(state)
	if can_pay:
		GameTheme.style_primary_button(pay_button)
		return
	var dis: StyleBox = pay_button.get_theme_stylebox(&"disabled")
	if dis == null:
		return
	for state: StringName in [&"normal", &"hover", &"pressed"]:
		pay_button.add_theme_stylebox_override(state, dis)


func _flash_grow_needs() -> void:
	var missing: String = GameState.format_missing_needs()
	if _care_status and missing != "":
		_care_status.text = missing
		_care_status.visible = true
	if care_grow_costs == null:
		return
	var tw: Tween = create_tween()
	care_grow_costs.modulate = Color(1.0, 0.55, 0.25)
	tw.tween_property(care_grow_costs, "modulate", Color.WHITE, 0.45)


func _on_pay() -> void:
	## One-click Grow, except Ancient, which asks first. try_grow_stage itself stays direct.
	if not GameState.can_grow_stage():
		GameAudio.play_tree_deny()
		_flash_grow_needs()
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
	_ancient_countdown_bg.color = Color(0, 0, 0, 0)
	_ancient_countdown_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ancient_countdown_bg.visible = false
	add_child(_ancient_countdown_bg)
	_ancient_countdown = Label.new()
	_ancient_countdown.name = "AncientCountdown"
	_ancient_countdown.size = Vector2(ANCIENT_TIMER_W, 36)
	_ancient_countdown.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_ancient_countdown.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_ancient_countdown.mouse_filter = Control.MOUSE_FILTER_IGNORE
	GameTheme.style_ink_label(_ancient_countdown)
	_ancient_countdown.add_theme_stylebox_override("normal", Ui540.kit_stylebox_9s(
		"res://assets/ui/theme/toast_9s_40x30.png", Vector4i(12, 8, 12, 8), Vector4(20, 6, 20, 6)))
	_ancient_countdown.visible = false
	add_child(_ancient_countdown)
	_ancient_confirm = Panel.new()
	_ancient_confirm.name = "AncientGrowConfirm"
	_ancient_confirm.visible = false
	_ancient_confirm.z_index = Z_MODAL
	add_child(_ancient_confirm)
	var title := Label.new()
	title.name = "Title"
	_ancient_confirm.add_child(title)
	var body := Label.new()
	body.name = "Body"
	_ancient_confirm.add_child(body)
	var yes := Button.new()
	yes.name = "Yes"
	yes.pressed.connect(_on_ancient_grow_yes)
	_ancient_confirm.add_child(yes)
	var no := Button.new()
	no.name = "No"
	no.pressed.connect(hide_ancient_grow_confirm)
	_ancient_confirm.add_child(no)


func _ensure_frozen_banner() -> void:
	_frozen_button = Button.new()
	_frozen_button.name = "AscendFrozenButton"
	_frozen_button.size = Vector2(420, 52)
	GameTheme.style_primary_button(_frozen_button)
	_frozen_button.pressed.connect(show_ascension_shop)
	_frozen_button.visible = false
	add_child(_frozen_button)
	_frozen_hint = Label.new()
	_frozen_hint.name = "AscendFrozenHint"
	_frozen_hint.size = Vector2(560, 64)
	_frozen_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_frozen_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_style_world_label(_frozen_hint)
	_frozen_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_frozen_hint.visible = false
	add_child(_frozen_hint)


func _refresh_frozen_banner() -> void:
	if _frozen_button == null:
		return
	var show_banner: bool = GameState.ancient_frozen and not ascension_panel.visible
	_frozen_button.visible = show_banner
	if show_banner:
		var vs: Vector2 = Ui540.viewport_size()
		_frozen_button.position = ((vs - _frozen_button.size) * 0.5 - Vector2(0, 20)).round()
		if _frozen_hint:
			_frozen_hint.position = Vector2(roundf((vs.x - _frozen_hint.size.x) * 0.5), _frozen_button.position.y + 60.0)
	_frozen_button.text = ContentStrings.get_text("ascend_frozen_button")
	if _frozen_hint:
		_frozen_hint.visible = show_banner
		_frozen_hint.text = ContentStrings.get_text("ascend_frozen_hint")


func _ensure_nav_button() -> void:
	_nav_button = Button.new()
	_nav_button.name = "HubForgeNav"
	_nav_button.text = ""
	_nav_button.focus_mode = Control.FOCUS_NONE
	_nav_button.custom_minimum_size = Vector2(Ui540.TAP_MIN_PX, Ui540.TAP_MIN_PX)
	_nav_button.pressed.connect(_on_nav_pressed)
	_nav_button.visible = false
	var host: Node = get_node_or_null("Panel")
	if host:
		host.add_child(_nav_button)
	else:
		add_child(_nav_button)


func _nav_face(path: String, expand: float = 0.0) -> StyleBoxTexture:
	var box := StyleBoxTexture.new()
	box.texture = load(path) as Texture2D
	if expand > 0.0:
		box.expand_margin_left = expand
		box.expand_margin_top = expand
		box.expand_margin_right = expand
		box.expand_margin_bottom = expand
	return box


func _apply_nav_board_face(destination: String) -> void:
	if _nav_button == null:
		return
	var stem: String = "res://assets/ui/extras/hud_board_btn_%s_" % destination
	_nav_button.add_theme_stylebox_override("normal", _nav_face(stem + "normal_44x44.png"))
	_nav_button.add_theme_stylebox_override("hover", _nav_face(stem + "hover_44x44.png"))
	_nav_button.add_theme_stylebox_override("pressed", _nav_face(stem + "pressed_44x44.png"))
	_nav_button.add_theme_stylebox_override("hover_pressed", _nav_face(stem + "pressed_44x44.png"))
	_nav_button.add_theme_stylebox_override("disabled", _nav_face(stem + "disabled_44x44.png"))
	_nav_button.add_theme_stylebox_override("focus", _nav_face(stem + "focus_50x50.png", 3.0))


func _refresh_nav_button() -> void:
	if _nav_button == null or not has_node("/root/ForgeJobs"):
		return
	var in_battle: bool = has_node("/root/EchoChamber") and EchoChamber.in_battle
	var unlocked: bool = GameState.forge_visited or ForgeJobs.can_enter_forge()
	var show_nav: bool = unlocked and not in_battle and not GameState.is_world_frozen()
	var was: bool = _nav_button.visible
	_nav_button.visible = show_nav
	if show_nav:
		var in_forge: bool = ForgeJobs.in_forge_scene()
		var tip_key: String = "nav_to_clearing" if in_forge else "nav_to_forge"
		var tip: String = ContentStrings.get_text(tip_key)
		if Ui540.should_show_pc_tooltips():
			tip = "%s (Tab)" % tip
		_nav_button.tooltip_text = tip
		var destination: String = "clearing" if in_forge else "forge"
		if str(_nav_button.get_meta("nav_dest", "")) != destination:
			_nav_button.set_meta("nav_dest", destination)
			_apply_nav_board_face(destination)
	if was != show_nav:
		_layout_hud540()


func _on_nav_pressed() -> void:
	if not has_node("/root/ForgeJobs"):
		return
	## The icon only changes the view. Walking through a door moves a character.
	ForgeJobs.switch_view(not ForgeJobs.in_forge_scene())


func _ensure_speed_button() -> void:
	_speed_button = TextureButton.new()
	_speed_button.name = "SpeedButton"
	_speed_button.position = Vector2(1020, 6)
	_speed_button.size = Vector2(40, 40)
	_speed_button.custom_minimum_size = Vector2(40, 40)
	_speed_button.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_speed_button.ignore_texture_size = true
	_speed_button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	_speed_button.focus_mode = Control.FOCUS_NONE
	_speed_button.visible = false
	_speed_button.pressed.connect(_on_speed_pressed)
	var host: Node = get_node_or_null("Panel")
	if host:
		host.add_child(_speed_button)
	else:
		add_child(_speed_button)
	_apply_speed_textures()


func _refresh_speed_button() -> void:
	## 16× stays off the HUD. The player button is the only speed control here.
	if _speed_button == null:
		return
	_speed_button.visible = false
	if not is_equal_approx(Engine.time_scale, 1.0):
		Engine.time_scale = 1.0
	_speed_index = 0


func _on_speed_pressed() -> void:
	_speed_index = 0
	Engine.time_scale = 1.0


func _apply_speed_textures() -> void:
	if _speed_button == null:
		return
	var steps: Array[int] = [1, 2, 4, 8]
	var n: int = steps[_speed_index]
	var stem: String = "res://assets/art/ui/buttons/speed_%dx_" % n
	_speed_button.texture_normal = load(stem + "normal.png") as Texture2D
	_speed_button.texture_hover = load(stem + "hover.png") as Texture2D
	_speed_button.texture_pressed = load(stem + "pressed.png") as Texture2D
	_speed_button.tooltip_text = "%dx" % n


func _ensure_play_speed_button() -> void:
	## Player control. Shown only when Options turns the speed button on. Steps are 1× / 2× / 4× / 8×.
	_play_speed_button = TextureButton.new()
	_play_speed_button.name = "PlaySpeedButton"
	_play_speed_button.position = Vector2(924, 6)
	_play_speed_button.size = Vector2(40, 40)
	_play_speed_button.custom_minimum_size = Vector2(40, 40)
	_play_speed_button.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_play_speed_button.ignore_texture_size = true
	_play_speed_button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	_play_speed_button.focus_mode = Control.FOCUS_NONE
	_play_speed_button.visible = true
	_play_speed_button.pressed.connect(_on_play_speed_pressed)
	var host: Node = get_node_or_null("Panel")
	if host:
		host.add_child(_play_speed_button)
	else:
		add_child(_play_speed_button)
	_apply_play_speed_textures()


func _refresh_play_speed_button() -> void:
	if _play_speed_button == null:
		return
	var show: bool = has_node("/root/GameAudio") and GameAudio.use_speedup_button
	_play_speed_button.visible = show
	if not show and has_node("/root/GameState"):
		GameState.reset_play_speed()
	_apply_play_speed_textures()


func _on_play_speed_pressed() -> void:
	if has_node("/root/GameState"):
		GameState.cycle_play_speed()
	_apply_play_speed_textures()


func _apply_play_speed_textures() -> void:
	if _play_speed_button == null:
		return
	var n: int = 1
	if has_node("/root/GameState"):
		n = int(GameState.play_speed)
	var stem: String = "res://assets/art/ui/buttons/speed_%dx_" % n
	_play_speed_button.texture_normal = load(stem + "normal.png") as Texture2D
	_play_speed_button.texture_hover = load(stem + "hover.png") as Texture2D
	_play_speed_button.texture_pressed = load(stem + "pressed.png") as Texture2D
	_play_speed_button.tooltip_text = "%dx" % n
	Ui540.paint_speed_pips(_play_speed_button, [1, 2, 4, 8].find(n))


func _make_activity_label(node_name: String, y: float) -> Label:
	var lbl := Label.new()
	lbl.name = node_name
	lbl.position = Vector2(PARTY_SLOT + 8.0, y)
	lbl.size = Vector2(210, PARTY_SLOT)
	lbl.autowrap_mode = TextServer.AUTOWRAP_OFF
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_style_world_label(lbl)
	return lbl


var _world_bold_font: FontVariation


## Wisps and Idle sit on the grass. Silver 19 faux-bold, cream, with a dark rim.
func _style_world_label(label: Label) -> void:
	if _world_bold_font == null:
		_world_bold_font = FontVariation.new()
		_world_bold_font.base_font = GameTheme.body_font()
		_world_bold_font.variation_embolden = 1.0
	label.add_theme_font_override("font", _world_bold_font)
	label.add_theme_font_size_override("font_size", GameTheme.silver_body_size())
	label.add_theme_color_override("font_color", GameTheme.CREAM_BTN)
	label.add_theme_color_override("font_outline_color", GameTheme.OUTLINE)
	label.add_theme_constant_override("outline_size", 6)
	label.add_theme_constant_override("line_spacing", -2)
	label.remove_theme_color_override("font_shadow_color")


func _portrait_row_y(which: String) -> float:
	## Walks Column in order: 44 px slots on a 50 px pitch, hidden rows take no space.
	var target: Control = _slot_keeper
	if which == "wisp":
		target = _slot_wisp
	elif which == "elaia":
		target = _slot_elaia
	var y: float = 0.0
	if _party_column == null:
		return y
	for slot: Node in _party_column.get_children():
		if slot == target:
			return y
		if slot is Control and (slot as Control).visible:
			y += PARTY_PITCH_R4
	return y


func _place_activity_label(label: Label, which: String) -> void:
	label.position = Vector2(PARTY_SLOT + 8.0, _portrait_row_y(which))
	label.size = Vector2(210, PARTY_SLOT)


func _refresh_actor_activities(elaia_visible: bool, keeper_selected: bool, companion_id: String) -> void:
	if _keeper_activity:
		_keeper_activity.visible = true
		_place_activity_label(_keeper_activity, "keeper")
		_keeper_activity.text = _actor_status_text("keeper", keeper_selected)
	if _elaia_activity:
		_elaia_activity.visible = elaia_visible
		_place_activity_label(_elaia_activity, "elaia")
		if elaia_visible:
			_elaia_activity.text = _actor_status_text("elaia", companion_id == "elaia")
		else:
			_elaia_activity.text = ""


func _actor_status_text(actor: String, selected: bool) -> String:
	## Line 1 is always reserved, so the activity line does not jump when selection changes.
	var head: String = ContentStrings.get_text("hud_activity_selected") if selected else " "
	return "%s\n%s" % [head, _activity_line(actor)]


func _kit_window_obscures_world() -> bool:
	return (
		welcome_panel.visible
		or backpack_panel.visible
		or bench_panel.visible
		or care_panel.visible
		or ascension_panel.visible
		or fruit_confirm_panel.visible
		or (_help_panel != null and _help_panel.visible)
		or is_character_open()
		or (_sheet != null and _sheet.visible)
	)


func _settle_world_labels() -> void:
	## Hide world Labels under the HUD band and whenever a kit window is open.
	var scene: Node = get_tree().current_scene
	if scene == null:
		return
	var band := Rect2(0, 0, get_viewport().get_visible_rect().size.x, Ui540.kit_top_inset())
	var force_hide: bool = _kit_window_obscures_world()
	_fade_world_labels(scene, band, false, force_hide)


func _fade_world_labels(node: Node, band: Rect2, in_layer: bool, force_hide: bool) -> void:
	var layer: bool = in_layer or node is CanvasLayer
	if not layer and node is Label:
		var lbl: Label = node as Label
		if lbl.visible:
			var mod: Color = lbl.modulate
			if force_hide:
				mod.a = 0.0
			else:
				var screen: Transform2D = lbl.get_global_transform_with_canvas()
				var rect := Rect2(screen.origin, lbl.size * screen.get_scale())
				mod.a = 0.0 if rect.intersects(band) else 1.0
			lbl.modulate = mod
	for child: Node in node.get_children():
		_fade_world_labels(child, band, layer, force_hide)


func _activity_line(actor: String) -> String:
	if has_node("/root/Reach") and GameState.member_away(actor):
		return ContentStrings.get_text("hud_activity_adventure", {"depth": Reach.depth})
	if not has_node("/root/ForgeJobs"):
		return ContentStrings.get_text("hud_activity_idle")
	var task: Dictionary = ForgeJobs.keeper_task() if actor == "keeper" else ForgeJobs.elaia_task()
	if not bool(task.get("working", false)):
		return ContentStrings.get_text("hud_activity_idle")
	var kind: String = str(task.get("kind", ""))
	var target: String = str(task.get("target", ""))
	if kind == "harvest":
		match target:
			"wood":
				return ContentStrings.get_text("hud_activity_harvest_wood")
			"stone":
				return ContentStrings.get_text("hud_activity_harvest_stone")
			"food":
				return ContentStrings.get_text("hud_activity_harvest_food")
	if kind == "water":
		return ContentStrings.get_text("hud_activity_water")
	if kind == "runestone":
		return ContentStrings.get_text("hud_activity_runestone")
	if kind == "forge":
		return ContentStrings.get_text("hud_activity_station", {"station": ForgeJobs.station_display(target)})
	return ContentStrings.get_text("hud_activity_idle")


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
		_ancient_countdown_bg.visible = false
	if _care_timer:
		_care_timer.visible = show_timer and fruit_ready_card.visible
	if not show_timer:
		return
	var total: int = int(ceil(GameState.ancient_remaining_sec))
	var label: String = "%d:%02d" % [int(total / 60), total % 60]
	_ancient_countdown.text = ContentStrings.get_text("tree_ancient_timer_label", {"time": label})
	_ancient_countdown.position = Vector2(roundf((Ui540.viewport_size().x - ANCIENT_TIMER_W) * 0.5), 72.0)
	if _care_timer:
		_care_timer.text = _ancient_countdown.text


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
	Ui540.layout_confirm(_ancient_confirm, title, body, yes, no)
	_ancient_confirm.visible = true
	no.grab_focus.call_deferred()
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


func maybe_show_elaia_footsteps() -> void:
	if not GameState.elaia_footsteps_pending():
		return
	if not has_node("/root/ForgeJobs") or not ForgeJobs.in_forge_scene():
		return
	if _pause_menu and _pause_menu.is_open():
		return
	if _forge_station_panel_open():
		return
	_ensure_footsteps_popup()
	_footsteps_popup.visible = true


func _forge_station_panel_open() -> bool:
	var scene: Node = get_tree().current_scene if get_tree() else null
	if scene == null:
		return false
	var panel: CanvasItem = scene.get_node_or_null("UI/RecipePanel") as CanvasItem
	return panel != null and panel.visible


func _ensure_footsteps_popup() -> void:
	if _footsteps_popup != null and is_instance_valid(_footsteps_popup):
		return
	_footsteps_popup = Panel.new()
	_footsteps_popup.name = "ElaiaFootsteps"
	_footsteps_popup.anchor_left = 0.5
	_footsteps_popup.anchor_right = 0.5
	_footsteps_popup.anchor_top = 0.5
	_footsteps_popup.anchor_bottom = 0.5
	_footsteps_popup.offset_left = -240.0
	_footsteps_popup.offset_top = -90.0
	_footsteps_popup.offset_right = 240.0
	_footsteps_popup.offset_bottom = 90.0
	_footsteps_popup.mouse_filter = Control.MOUSE_FILTER_STOP
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.13, 0.11, 0.96)
	sb.border_color = Color(0.45, 0.58, 0.48, 1)
	sb.set_border_width_all(2)
	_footsteps_popup.add_theme_stylebox_override("panel", sb)
	var body := Label.new()
	body.name = "Body"
	body.position = Vector2(16, 16)
	body.size = Vector2(448, 80)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.text = ContentStrings.get_text("forge_elaia_footsteps")
	body.add_theme_font_size_override("font_size", 16)
	body.add_theme_color_override("font_color", Color(0.88, 0.92, 0.84, 1))
	_footsteps_popup.add_child(body)
	var go := Button.new()
	go.name = "Go"
	go.position = Vector2(150, 110)
	go.size = Vector2(180, 40)
	go.text = ContentStrings.get_text("forge_elaia_footsteps_ok")
	go.pressed.connect(_on_footsteps_go)
	_footsteps_popup.add_child(go)
	_footsteps_popup.visible = false
	add_child(_footsteps_popup)


func _on_footsteps_go() -> void:
	GameState.elaia_footsteps_seen = true
	if _footsteps_popup:
		_footsteps_popup.visible = false
	GameState.begin_elaia_join_clearing()
	if has_node("/root/SaveService"):
		SaveService.save_game()
	if has_node("/root/ForgeJobs"):
		ForgeJobs.switch_view(false)


func is_footsteps_open() -> bool:
	return _footsteps_popup != null and _footsteps_popup.visible


func maybe_show_elaia_join() -> void:
	## Once, in the Clearing, after the Forge footsteps have been acknowledged.
	if GameState.elaia_footsteps_pending():
		return
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
	_refresh_party_bar()
	_show_toast(ContentStrings.get_text("elaia_join_toast"))
	if has_node("/root/SaveService"):
		SaveService.save_game()


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey):
		return
	var key: InputEventKey = event
	if not key.pressed or key.echo:
		return
	if welcome_panel.visible:
		get_viewport().set_input_as_handled()
		return
	if BattleView.is_open():
		return
	if Binds.event_matches(key, "inventory"):
		if welcome_panel.visible:
			return
		if _pause_menu and _pause_menu.is_open():
			return
		toggle_backpack()
		get_viewport().set_input_as_handled()
		return
	var sheet_key: bool = Binds.event_matches(key, "character") or key.is_action_pressed("character_sheet")
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
	_hide_bag_detail()
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
	_bag_filter_ix = maxi(0, BAG_FILTER_CYCLE.find(tab_id))
	_refresh_backpack_tab_labels()
	_rebuild_backpack()


var _bag_filter_ix: int = 0


func _cycle_backpack_filter() -> void:
	_bag_filter_ix = (_bag_filter_ix + 1) % BAG_FILTER_CYCLE.size()
	_backpack_tab = BAG_FILTER_CYCLE[_bag_filter_ix]
	_refresh_backpack_tab_labels()
	_rebuild_backpack()


func _refresh_backpack_tab_labels() -> void:
	backpack_tab_all.text = _filter_label("all")
	backpack_tab_all.set_pressed_no_signal(_backpack_tab == "all")
	if _backpack_cat_btn:
		_backpack_cat_btn.set_pressed_no_signal(_backpack_tab != "all")
		if _backpack_tab == "all":
			_backpack_cat_btn.text = _filter_label(BAG_FILTER_CYCLE[(_bag_filter_ix + 1) % BAG_FILTER_CYCLE.size()])
		else:
			_backpack_cat_btn.text = _filter_label(_backpack_tab)
		## Same 18 px mark and 12 px inset as the bench Parts and char Weapon tabs.
		Ui540.add_cycle_cue(_backpack_cat_btn)


func _apply_filter_labels() -> void:
	_refresh_backpack_tab_labels()


func _filter_label(filter_id: String) -> String:
	match filter_id:
		"all":
			return ContentStrings.get_text("backpack_tab_all")
		"raw":
			return ContentStrings.get_text("backpack_tab_raw")
		"refined":
			return ContentStrings.get_text("backpack_tab_refined")
		"potions":
			return ContentStrings.get_text("backpack_tab_potions")
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
		var item_row: Control = _make_item_row(row, false)
		inventory_list.add_child(item_row)
		_wire_backpack_row(item_row, row)
	if rows.is_empty():
		var empty := Label.new()
		empty.text = ContentStrings.get_text("backpack_empty")
		GameTheme.style_ink_label(empty, true)
		empty.custom_minimum_size = Vector2(0, BAG_ROW_H)
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		inventory_list.add_child(empty)


func filter_owned_counts() -> Dictionary:
	var counts: Dictionary = {}
	var filters: PackedStringArray = PackedStringArray(["all", "raw", "refined", "potions", "tools", "weapons", "relics"])
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
	_rebuild_bench()
	_refresh_dim()


func close_bench() -> void:
	if bench_panel == null or not bench_panel.visible:
		return
	bench_panel.visible = false
	GameAudio.play_ui_close()
	_release_world_if_allowed()
	_refresh_dim()


func _ensure_bench_batch() -> BatchPanel:
	if _bench_batch != null and is_instance_valid(_bench_batch):
		return _bench_batch
	if bench_panel == null:
		return null
	var existing: BatchPanel = bench_panel.get_node_or_null("BatchPanel") as BatchPanel
	if existing == null:
		existing = BATCH_PANEL_SCENE.instantiate() as BatchPanel
		if existing == null:
			return null
		existing.name = "BatchPanel"
		bench_panel.add_child(existing)
	existing.compact = true
	existing.setup(ForgeJobs.WORKBENCH_ID if has_node("/root/ForgeJobs") else "workbench")
	_bench_batch = existing
	if _bench_detail != null:
		_layout_bench540()
	return existing


func _ensure_bench_chrome() -> void:
	if _bench_tabs != null or bench_panel == null:
		return
	_bench_tabs = HBoxContainer.new()
	_bench_tabs.name = "BenchTabs"
	_bench_tabs.add_theme_constant_override("separation", 8)
	bench_panel.add_child(_bench_tabs)
	_bench_tab_all = Button.new()
	_bench_tab_all.name = "TabAll"
	_bench_tab_all.custom_minimum_size = Vector2(90, 44)
	_bench_tab_all.pressed.connect(_set_bench_filter.bind(0))
	GameTheme.style_big_tab_button(_bench_tab_all)
	_bench_tabs.add_child(_bench_tab_all)
	_bench_cat_btn = Button.new()
	_bench_cat_btn.name = "BenchCategoryCycle"
	_bench_cat_btn.custom_minimum_size = Vector2(160, 44)
	_bench_cat_btn.pressed.connect(_cycle_bench_filter)
	GameTheme.style_big_tab_button(_bench_cat_btn)
	Ui540.add_cycle_cue(_bench_cat_btn)
	_bench_tabs.add_child(_bench_cat_btn)
	craft_list.add_theme_constant_override("separation", int(BACKPACK_ROW_H - BAG_ROW_H))
	_bench_detail = Control.new()
	_bench_detail.name = "BenchDetail"
	_bench_detail.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bench_panel.add_child(_bench_detail)


func _bench_filter_label(filter_id: String) -> String:
	match filter_id:
		"all":
			return ContentStrings.get_text("backpack_tab_all")
		"parts":
			return "Parts"
		"tools":
			return ContentStrings.get_text("backpack_tab_tools")
		"weapons":
			return ContentStrings.get_text("backpack_tab_weapons")
		_:
			return filter_id


func _set_bench_filter(ix: int) -> void:
	_bench_filter_ix = ix
	_rebuild_bench()


func _cycle_bench_filter() -> void:
	_bench_filter_ix = _bench_filter_ix % (BENCH_FILTER_CYCLE.size() - 1) + 1
	_rebuild_bench()


func _bench_recipe_category(recipe_id: String, equipment_out: bool) -> String:
	if equipment_out:
		return "weapons"
	var out_id: String = str(Backpack.get_recipe_def(recipe_id).get("output_id", recipe_id))
	if Backpack.is_tool(out_id) or Backpack.matches_filter(out_id, "tools") or out_id == "fertilizer":
		return "tools"
	return "parts"


func _bench_recipes() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for entry: Variant in Backpack.recipes_data:
		if typeof(entry) == TYPE_DICTIONARY:
			out.append({"id": str((entry as Dictionary).get("id", "")), "gear": false})
	for gear_entry: Variant in Equipment.recipes_data:
		if typeof(gear_entry) != TYPE_DICTIONARY:
			continue
		var gear_id: String = str((gear_entry as Dictionary).get("id", ""))
		if Equipment.recipe_station(gear_id) != "anvil":
			out.append({"id": gear_id, "gear": true})
	return out


func _rebuild_bench() -> void:
	_ensure_bench_chrome()
	_ensure_bench_batch()
	bench_title.text = ContentStrings.get_text("bench_title")
	bench_prompt.text = "%s  ·  %s" % [
		ContentStrings.get_text("handcraft_title"),
		ContentStrings.get_text("tool_never_gate"),
	]
	var filter_id: String = BENCH_FILTER_CYCLE[_bench_filter_ix]
	_bench_tab_all.text = _bench_filter_label("all")
	_bench_tab_all.set_pressed_no_signal(filter_id == "all")
	_bench_cat_btn.text = _bench_filter_label(BENCH_FILTER_CYCLE[maxi(1, _bench_filter_ix)])
	_bench_cat_btn.set_pressed_no_signal(filter_id != "all")
	for child: Node in craft_list.get_children():
		child.queue_free()
	var first: String = ""
	var keep: bool = false
	for rec: Dictionary in _bench_recipes():
		var rid: String = str(rec["id"])
		var gear: bool = bool(rec["gear"])
		if filter_id != "all" and _bench_recipe_category(rid, gear) != filter_id:
			continue
		craft_list.add_child(_make_craft_row(rid, gear))
		if first == "":
			first = rid
		if rid == _bench_selected:
			keep = true
	var pad := Control.new()
	pad.name = "ScrollPad"
	pad.custom_minimum_size = Vector2(0, 16)
	pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	craft_list.add_child(pad)
	if not keep:
		_bench_selected = first
	if _bench_selected != "":
		_on_bench_recipe_selected(_bench_selected)
	else:
		_refresh_bench_detail()


func _placeholder_icon(color: Color) -> ColorRect:
	var icon := ColorRect.new()
	icon.custom_minimum_size = Vector2(32, 32)
	icon.color = color
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return icon


func _ensure_bag_detail_panel() -> void:
	if _bag_detail_panel != null or backpack_panel == null:
		return
	_bag_detail_panel = Panel.new()
	_bag_detail_panel.name = "BagDetailPopup"
	_bag_detail_panel.visible = false
	_bag_detail_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	backpack_panel.add_child(_bag_detail_panel)
	Ui540.apply_kit_panel(_bag_detail_panel, "bag_detail")


func _wire_backpack_row(row: Control, stack: Dictionary) -> void:
	row.mouse_filter = Control.MOUSE_FILTER_STOP
	row.gui_input.connect(func(ev: InputEvent) -> void:
		if ev is InputEventMouseButton:
			var mb: InputEventMouseButton = ev as InputEventMouseButton
			if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
				if _bag_detail_panel != null and _bag_detail_panel.visible and _bag_detail_item_id == str(stack.get("id", "")):
					_hide_bag_detail()
				else:
					_show_bag_detail(stack, row)
	)


## Mockup bag540_pc_detail: 320 wide, under the tapped row, right edge on the list's right
## edge, flipped above the row when it would leave the window.
func _show_bag_detail(stack: Dictionary, row: Control = null) -> void:
	_ensure_bag_detail_panel()
	if _bag_detail_panel == null:
		return
	_bag_detail_item_id = str(stack.get("id", ""))
	for child: Node in _bag_detail_panel.get_children():
		if child.name != "VineFrame":
			child.free()
	if not _bag_detail_panel.gui_input.is_connected(_on_bag_detail_input):
		_bag_detail_panel.gui_input.connect(_on_bag_detail_input)
	var item_id: String = _bag_detail_item_id
	var w: float = 320.0
	var equippable: bool = Equipment.is_equippable(item_id)
	var action_w: float = 100.0 if equippable else 0.0
	var icon: Control = _make_item_icon(item_id, "")
	icon.position = Vector2(22, 18)
	icon.size = Vector2(32, 32)
	_bag_detail_panel.add_child(icon)
	var title := Label.new()
	title.text = str(stack.get("display_name", item_id))
	GameTheme.style_heading_label(title)
	title.position = Vector2(62, 12)
	title.size = Vector2(w - 62 - 24, 40)
	title.clip_text = true
	title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_bag_detail_panel.add_child(title)
	var body := Label.new()
	body.text = _item_examine_text(item_id)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	GameTheme.style_ink_label(body)
	var body_w: float = w - 48.0 - (action_w + 8.0 if equippable else 0.0)
	body.position = Vector2(24, 58)
	body.size = Vector2(body_w, 20)
	_bag_detail_panel.add_child(body)
	var lines: int = maxi(1, body.get_line_count())
	var body_h: float = maxf(20.0 * lines, 44.0 if equippable else 0.0)
	body.size = Vector2(body_w, 20.0 * lines)
	var h: float = 58.0 + body_h + 20.0
	if equippable:
		var action := Button.new()
		action.text = "Equip"
		GameTheme.style_wood_button(action)
		action.position = Vector2(w - 24.0 - action_w, h - 20.0 - 44.0)
		action.size = Vector2(action_w, 44)
		action.pressed.connect(_on_bag_detail_action.bind(true))
		_bag_detail_panel.add_child(action)
	_bag_detail_panel.custom_minimum_size = Vector2(w, h)
	_bag_detail_panel.size = Vector2(w, h)
	var scroll: Control = backpack_panel.get_node_or_null("InventoryScroll") as Control
	var right: float = (scroll.position.x + scroll.size.x - 30.0) if scroll else backpack_panel.size.x - 36.0
	var top: float = scroll.position.y if scroll else 24.0
	var bottom: float = (scroll.position.y + scroll.size.y) if scroll else backpack_panel.size.y - 24.0
	var y: float = top
	if row != null and scroll != null:
		var row_top: float = row.global_position.y - backpack_panel.global_position.y
		y = row_top + row.size.y + 2.0
		if y + h > bottom:
			y = row_top - h - 2.0
	_bag_detail_panel.position = Vector2(right - w, clampf(y, top, maxf(top, bottom - h)))
	_bag_detail_panel.z_index = 2
	_bag_detail_panel.visible = true


func _on_bag_detail_input(ev: InputEvent) -> void:
	if ev is InputEventMouseButton:
		var mb: InputEventMouseButton = ev as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			_hide_bag_detail()


func _on_bag_detail_action(equip: bool) -> void:
	if equip and _bag_detail_item_id != "":
		Equipment.try_equip(_bag_detail_item_id)
		_rebuild_backpack()
	_hide_bag_detail()


func _hide_bag_detail() -> void:
	if _bag_detail_panel:
		_bag_detail_panel.visible = false
	_bag_detail_item_id = ""


func _make_item_row(stack: Dictionary, _craft: bool) -> Control:
	var row := PanelContainer.new()
	row.custom_minimum_size = Vector2(0, BAG_ROW_H)
	row.add_theme_stylebox_override("panel", Ui540.list_row_style())
	var line := HBoxContainer.new()
	line.add_theme_constant_override("separation", 8)
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(line)
	var stack_id: String = str(stack.get("id", ""))
	var stack_name: String = str(stack.get("display_name", stack_id))
	var icon: Control = _make_item_icon(stack_id, stack_name)
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	line.add_child(icon)
	var lbl := Label.new()
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var count: int = int(stack.get("count", 0))
	var name: String = str(stack.get("display_name", ""))
	var count_text: String = "×%d" % count
	if stack_id == "stone_watering_can":
		lbl.text = "%s  ·  %s" % [name, ContentStrings.get_text("tool_water_hint")]
		count_text = ""
	elif bool(stack.get("unique", false)):
		lbl.text = "%s  ·  %s" % [name, ContentStrings.get_text("tool_owned_hint")]
		count_text = ""
	else:
		lbl.text = name
	GameTheme.style_ink_label(lbl)
	lbl.clip_text = true
	lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.mouse_filter = Control.MOUSE_FILTER_PASS
	var examine: String = _item_examine_text(stack_id)
	if examine != "":
		row.tooltip_text = examine
		lbl.tooltip_text = examine
	line.add_child(lbl)
	if count_text != "":
		var cnt := Label.new()
		cnt.text = count_text
		GameTheme.style_ink_label(cnt)
		cnt.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		cnt.mouse_filter = Control.MOUSE_FILTER_PASS
		line.add_child(cnt)
	return row


## One 44 px list row; the whole row is the (toggle) Button that selects the recipe, the
## label line sits on top and ignores the mouse.
func _make_craft_row(recipe_id: String, equipment_out: bool = false) -> Control:
	var def: Dictionary = Equipment.get_recipe_def(recipe_id) if equipment_out else Backpack.get_recipe_def(recipe_id)
	var out_id: String = str(def.get("output_id", recipe_id))
	var row := Control.new()
	row.custom_minimum_size = Vector2(0, BAG_ROW_H)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var btn := Button.new()
	btn.name = "Pick"
	btn.toggle_mode = true
	btn.set_anchors_preset(Control.PRESET_FULL_RECT)
	btn.focus_mode = Control.FOCUS_NONE
	btn.add_theme_stylebox_override("normal", Ui540.list_row_style())
	btn.add_theme_stylebox_override("hover", Ui540.kit_stylebox_9s("res://assets/ui/theme/pick_row_9s_hover_24x24.png", Vector4i(6, 6, 6, 6)))
	btn.add_theme_stylebox_override("pressed", Ui540.list_row_style(true))
	btn.add_theme_stylebox_override("hover_pressed", Ui540.list_row_style(true))
	btn.pressed.connect(_on_bench_recipe_selected.bind(recipe_id))
	row.add_child(btn)
	var line := HBoxContainer.new()
	line.set_anchors_preset(Control.PRESET_FULL_RECT)
	line.offset_left = 6.0
	## Gutter before the scrollbar. The name keeps its full width; the tag gives way.
	line.offset_right = -16.0
	line.add_theme_constant_override("separation", 8)
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(line)
	var craft_name: String = Equipment.item_display_name(out_id) if equipment_out else Backpack.item_display_name(out_id)
	var reason: String = Equipment.craft_block_reason(recipe_id) if equipment_out else Backpack.craft_block_reason(recipe_id)
	var icon: Control = _make_item_icon(out_id, craft_name)
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if reason != "":
		icon.modulate = Color(0.75, 0.72, 0.68, 0.7)
	line.add_child(icon)
	var name_lbl := Label.new()
	name_lbl.name = "RecipeName"
	name_lbl.text = craft_name
	GameTheme.style_ink_label(name_lbl, false)
	## The name keeps its full width and never takes the leftover, so a shortage
	## hint cannot be squeezed to nothing and the name itself is never ellipsized.
	name_lbl.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	name_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_lbl.clip_text = false
	name_lbl.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	line.add_child(name_lbl)
	var state_lbl := Label.new()
	state_lbl.name = "RecipeState"
	var missing_tip: String = ""
	if reason == "unique":
		state_lbl.text = ContentStrings.get_text("backpack_owned")
	elif reason == "":
		state_lbl.text = "ready"
	elif reason == "cant_afford" or reason == "no_shards":
		var missing: PackedStringArray = _bench_missing_parts(recipe_id, equipment_out)
		missing_tip = ", ".join(missing)
		state_lbl.text = _bench_short_text(missing)
	else:
		state_lbl.text = ""
	GameTheme.style_ink_label(state_lbl, true)
	## Muted ink, parked on the right before the scrollbar gutter, so the hint
	## reads apart from the recipe name. Silver only renders crisp at 19/38: at
	## 15-17 every glyph pixel is a blend and the hint read as faint 7 px text,
	## so it keeps the body 19 and stands apart by colour and alignment.
	## Ellipsis only when the leftover is short.
	state_lbl.add_theme_font_size_override("font_size", GameTheme.BODY_SIZE)
	state_lbl.add_theme_color_override("font_color", Color8(90, 62, 40))
	state_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	state_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	state_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	state_lbl.clip_text = true
	state_lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	state_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if missing_tip != "":
		state_lbl.tooltip_text = missing_tip
	line.add_child(state_lbl)
	var cost_tip: String = _craft_row_cost_text(recipe_id)
	if missing_tip != "" and cost_tip.find(missing_tip) < 0:
		cost_tip = missing_tip if cost_tip == "" else "%s\n%s" % [cost_tip, missing_tip]
	row.tooltip_text = cost_tip
	btn.tooltip_text = cost_tip
	row.set_meta("recipe_id", recipe_id)
	row.set_meta("gear", equipment_out)
	return row


## One missing ingredient stays "Need 3 Wood". Several name the first and a count
## ("Need 1 Wood Rod +1") so the recipe name is never squeezed; the full list
## stays on the tooltip.
func _bench_short_text(parts: PackedStringArray) -> String:
	if parts.size() > 1:
		return "%s +%d" % [parts[0], parts.size() - 1]
	return ", ".join(parts)


func _bench_missing_parts(recipe_id: String, equipment_out: bool) -> PackedStringArray:
	var ings: Dictionary = Equipment.get_recipe_ingredients(recipe_id) if equipment_out else Backpack.get_recipe_ingredients(recipe_id)
	var parts: PackedStringArray = PackedStringArray()
	for key: Variant in ings.keys():
		var iid: String = str(key)
		var missing: int = int(ings[key]) - _bench_have(iid)
		if missing > 0:
			parts.append("Need %d %s" % [missing, _bench_item_name(iid)])
	return parts


func _bench_have(iid: String) -> int:
	if StringName(iid) in Backpack.RESOURCE_IDS:
		return GameState.get_resource(StringName(iid))
	if Backpack.is_known_item(iid):
		return Backpack.get_count(iid)
	return Equipment.gear_count_anywhere(iid)


func _bench_item_name(iid: String) -> String:
	if StringName(iid) in Backpack.RESOURCE_IDS:
		return ContentStrings.get_text("hud_%s" % iid)
	if Backpack.is_known_item(iid):
		return Backpack.item_display_name(iid)
	return Equipment.item_display_name(iid)


func _bench_detail_label(text: String, pos: Vector2, w: float, muted: bool = false) -> Label:
	var lbl := Label.new()
	lbl.text = text
	GameTheme.style_ink_label(lbl, muted)
	lbl.position = pos
	lbl.size = Vector2(w, 22)
	lbl.clip_text = true
	lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_bench_detail.add_child(lbl)
	return lbl


func _refresh_bench_detail() -> void:
	if _bench_detail == null:
		return
	for child: Node in _bench_detail.get_children():
		child.queue_free()
	var rid: String = _bench_selected
	if rid == "":
		return
	var gear: bool = Equipment.has_recipe(rid)
	var def: Dictionary = Equipment.get_recipe_def(rid) if gear else Backpack.get_recipe_def(rid)
	var out_id: String = str(def.get("output_id", rid))
	var rw: float = _bench_detail.size.x
	var frame := Panel.new()
	frame.position = Vector2.ZERO
	frame.size = Vector2(108, 108)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_theme_stylebox_override("panel", Ui540.kit_stylebox_9s("res://assets/ui/theme/play_bevel_9s_6x6.png", Vector4i(2, 2, 2, 2)))
	_bench_detail.add_child(frame)
	var big: Control = _make_item_icon(out_id, "")
	big.position = Vector2(6, 6)
	big.size = Vector2(96, 96)
	big.custom_minimum_size = Vector2(96, 96)
	if big is TextureRect:
		(big as TextureRect).expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	frame.add_child(big)
	var tx: float = 124.0
	var name_lbl := Label.new()
	name_lbl.text = _bench_item_name(out_id)
	GameTheme.style_heading_label(name_lbl)
	name_lbl.position = Vector2(tx, -2)
	name_lbl.size = Vector2(rw - tx, 40)
	name_lbl.clip_text = true
	name_lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_bench_detail.add_child(name_lbl)
	var cat: String = _bench_recipe_category(rid, gear)
	var sub: String = {"weapons": "Weapon", "tools": "Tool", "parts": "Part"}.get(cat, "")
	var stats: String = ""
	if gear:
		var item: Dictionary = Equipment.get_item_def(out_id)
		var kind: String = str(item.get("damage_kind", ""))
		if kind != "":
			sub += " · " + kind.capitalize()
		var bon: Variant = item.get("bonuses", {})
		if typeof(bon) == TYPE_DICTIONARY:
			var bits: PackedStringArray = PackedStringArray()
			for stat: Variant in (bon as Dictionary).keys():
				bits.append("%s +%d" % [str(stat).capitalize(), int((bon as Dictionary)[stat])])
			stats = "  ".join(bits)
	if stats == "":
		stats = _item_examine_text(out_id).get_slice("\n", 0)
	if stats == "" or stats == name_lbl.text:
		stats = "—"
	_bench_detail_label(sub, Vector2(tx, 34), rw - tx, true)
	_bench_detail_label(stats, Vector2(tx, 56), rw - tx)
	_bench_detail_label("Handcraft at the Bench", Vector2(tx, 78), rw - tx, true)
	var mat_title := _bench_detail_label("Materials", Vector2(0, 118), rw)
	mat_title.add_theme_font_override("font", GameTheme.title_font())
	var ings: Dictionary = Equipment.get_recipe_ingredients(rid) if gear else Backpack.get_recipe_ingredients(rid)
	var col_w: float = floorf(rw * 0.5)
	var j: int = 0
	for key: Variant in ings.keys():
		var iid: String = str(key)
		var need: int = int(ings[key])
		var have: int = _bench_have(iid)
		var mx: float = float(j % 2) * col_w
		var my: float = 142.0 + float(j / 2) * 40.0
		var ic: Control = _make_item_icon(iid, _bench_item_name(iid))
		ic.position = Vector2(mx, my + 2)
		ic.size = Vector2(32, 32)
		_bench_detail.add_child(ic)
		_bench_detail_label(_bench_item_name(iid), Vector2(mx + 38, my + 7), col_w - 38 - 80)
		var cnt := _bench_detail_label("%d/%d" % [have, need], Vector2(mx + col_w - 12 - 76, my + 7), 76)
		cnt.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		if have < need:
			cnt.add_theme_color_override("font_color", SHORT_RED)
		j += 1


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
	## Every recipe row is have/need from the recipe data. Static × strings stay for tooltips.
	var lines: PackedStringArray = PackedStringArray()
	if has_node("/root/Equipment") and Equipment.has_recipe(recipe_id):
		lines = Equipment.recipe_ingredient_lines(recipe_id)
	elif has_node("/root/Backpack"):
		lines = Backpack.recipe_ingredient_lines(recipe_id)
	return ", ".join(lines)


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


func _on_bench_recipe_selected(recipe_id: String) -> void:
	var panel: BatchPanel = _ensure_bench_batch()
	if panel == null:
		return
	_bench_selected = recipe_id
	panel.bind_recipe(recipe_id)
	for row: Node in craft_list.get_children():
		var pick: Button = row.get_node_or_null("Pick") as Button
		if pick:
			pick.set_pressed_no_signal(str(row.get_meta("recipe_id", "")) == recipe_id)
	_refresh_bench_detail()


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
	if _shop_preview_mode:
		prestige_sub.text = ContentStrings.get_text("ascend_shop_preview_line")
	elif prestige_sub:
		prestige_sub.text = ContentStrings.get_text("fruit_shop_only_banner")
	if shard_count_label:
		shard_count_label.text = str(GameState.manashards)
	ascend_button.visible = GameState.fruit_harvested_pending_ascend and not _shop_preview_mode
	ascend_button.disabled = not GameState.can_ascend()
	ascend_button.text = ContentStrings.get_text("ascend_confirm_yes")
	_layout_ascension_shop()
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


func _ensure_shop_toolbar() -> void:
	if ascension_panel == null or _shop_toolbar != null:
		return
	_shop_toolbar = HBoxContainer.new()
	_shop_toolbar.name = "ShopToolbar"
	_shop_toolbar.add_theme_constant_override("separation", 12)
	ascension_panel.add_child(_shop_toolbar)
	_hide_locked_toggle = CheckButton.new()
	_hide_locked_toggle.text = ContentStrings.get_text("ascend_shop_hide_locked")
	_hide_locked_toggle.custom_minimum_size = Vector2(0, 44)
	_hide_locked_toggle.toggled.connect(_on_hide_locked_toggled)
	_shop_toolbar.add_child(_hide_locked_toggle)
	_hide_maxed_toggle = CheckButton.new()
	_hide_maxed_toggle.text = ContentStrings.get_text("ascend_shop_hide_maxed")
	_hide_maxed_toggle.custom_minimum_size = Vector2(0, 44)
	_hide_maxed_toggle.toggled.connect(_on_hide_maxed_toggled)
	_shop_toolbar.add_child(_hide_maxed_toggle)
	_sync_shop_toolbar()


func _sync_shop_toolbar() -> void:
	if _hide_locked_toggle == null or _hide_maxed_toggle == null:
		return
	_hide_locked_toggle.set_block_signals(true)
	_hide_maxed_toggle.set_block_signals(true)
	_hide_locked_toggle.button_pressed = GameState.shop_hide_locked
	_hide_maxed_toggle.button_pressed = GameState.shop_hide_maxed
	_hide_locked_toggle.set_block_signals(false)
	_hide_maxed_toggle.set_block_signals(false)


func _on_hide_maxed_toggled(pressed: bool) -> void:
	GameState.shop_hide_maxed = pressed
	_rebuild_upgrades()
	SaveService.save_game()


func _on_hide_locked_toggled(pressed: bool) -> void:
	if pressed:
		GameState.shop_hide_locked = true
		_rebuild_upgrades()
		SaveService.save_game()
		return
	if not GameState.shop_hide_locked:
		return
	if GameState.shop_spoiler_shown_count >= 3:
		GameState.shop_hide_locked = false
		_rebuild_upgrades()
		SaveService.save_game()
		return
	_spoiler_pending_unlock = true
	_show_spoiler_dialog()


func _ensure_spoiler_dialog() -> void:
	if _spoiler_dialog != null:
		return
	_spoiler_dialog = _make_kit_confirm("AscendSpoilerDialog", _on_spoiler_peek, _on_spoiler_stay)
	_spoiler_dialog.z_index = Z_MODAL + 2


## Bare confirm (Title, Body, Yes = action, No = safe); Ui540.layout_confirm styles and sizes it.
func _make_kit_confirm(node_name: String, on_yes: Callable, on_no: Callable) -> Panel:
	var dialog := Panel.new()
	dialog.name = node_name
	dialog.visible = false
	dialog.z_index = Z_MODAL
	dialog.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dialog)
	for label_name: String in ["Title", "Body"]:
		var lbl := Label.new()
		lbl.name = label_name
		dialog.add_child(lbl)
	var yes := Button.new()
	yes.name = "Yes"
	yes.pressed.connect(on_yes)
	dialog.add_child(yes)
	var no := Button.new()
	no.name = "No"
	no.pressed.connect(on_no)
	dialog.add_child(no)
	return dialog


func _show_kit_confirm(dialog: Panel, title: String, body: String, yes_text: String, no_text: String) -> void:
	var title_lbl: Label = dialog.get_node("Title") as Label
	var body_lbl: Label = dialog.get_node("Body") as Label
	var yes: Button = dialog.get_node("Yes") as Button
	var no: Button = dialog.get_node("No") as Button
	title_lbl.text = title
	body_lbl.text = body.trim_prefix(title + " ")
	yes.text = yes_text
	no.text = no_text
	Ui540.layout_confirm(dialog, title_lbl, body_lbl, yes, no)
	dialog.visible = true
	no.grab_focus.call_deferred()
	_refresh_dim()


func _show_spoiler_dialog() -> void:
	_ensure_spoiler_dialog()
	_show_kit_confirm(_spoiler_dialog,
		ContentStrings.get_text("ascend_spoiler_title"),
		ContentStrings.get_text("ascend_spoiler_body"),
		ContentStrings.get_text("ascend_spoiler_confirm"),
		ContentStrings.get_text("ascend_spoiler_stay"))
	_sync_shop_toolbar()


func _hide_spoiler_dialog() -> void:
	if _spoiler_dialog:
		_spoiler_dialog.visible = false
	_spoiler_pending_unlock = false
	_refresh_dim()


func _on_spoiler_peek() -> void:
	GameState.shop_spoiler_shown_count += 1
	GameState.shop_hide_locked = false
	_hide_spoiler_dialog()
	_sync_shop_toolbar()
	_rebuild_upgrades()
	SaveService.save_game()


func _on_spoiler_stay() -> void:
	_hide_spoiler_dialog()
	_sync_shop_toolbar()


func _ensure_care_blessings_button() -> void:
	if care_panel == null or _blessings_preview_button != null:
		return
	_blessings_preview_button = Button.new()
	_blessings_preview_button.name = "BlessingsPreviewButton"
	_blessings_preview_button.position = Vector2(CARE_SIZE.x - 124.0, 18.0)
	_blessings_preview_button.size = Vector2(44, 44)
	_blessings_preview_button.text = ""
	_blessings_preview_button.tooltip_text = ContentStrings.get_text("ascend_shop_preview_line")
	_blessings_preview_button.icon = HudIcons.cell(HudIcons.ASCENSION)
	_blessings_preview_button.expand_icon = true
	Ui540.style_wood_icon_button(_blessings_preview_button)
	care_header.add_child(_blessings_preview_button)
	_blessings_preview_button.pressed.connect(_on_care_blessings_preview)


func _on_care_blessings_preview() -> void:
	hide_care_menu()
	show_ascension_shop_preview()


func _upgrade_rank_label(rank: int, upgrade_id: String) -> String:
	var cap: int = GameState.upgrade_max_rank(upgrade_id)
	if cap >= 1_000_000:
		return ContentStrings.get_text("upgrade_rank_endless", {"rank": rank})
	return ContentStrings.get_text("upgrade_rank", {"rank": rank, "max": cap})


func _rebuild_upgrades() -> void:
	for child: Node in upgrade_list.get_children():
		child.queue_free()
	if not _shop_preview_mode and not GameState.fruit_harvested_pending_ascend:
		return
	var locked_hidden: int = 0
	var maxed_hidden: int = 0
	for entry: Variant in GameState.upgrades_data:
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var d: Dictionary = entry
		var uid: String = str(d.get("id", ""))
		if uid == "":
			continue
		var rank: int = GameState.get_upgrade_rank(uid)
		var unlocked: bool = GameState.is_upgrade_unlocked(uid)
		var maxed: bool = rank >= GameState.upgrade_max_rank(uid)
		var always_show: bool = uid == "party_banner"
		if GameState.shop_hide_maxed and maxed:
			maxed_hidden += 1
			continue
		if GameState.shop_hide_locked and not unlocked and not always_show:
			locked_hidden += 1
			continue
		upgrade_list.add_child(_make_upgrade_row(uid, d, rank, unlocked, maxed))
	if maxed_hidden > 0:
		upgrade_list.add_child(_shop_summary_row(
			ContentStrings.get_text("ascend_shop_complete_collapsed", {"count": maxed_hidden}), false
		))
	if locked_hidden > 0:
		upgrade_list.add_child(_shop_summary_row(
			ContentStrings.get_text("ascend_shop_locked_collapsed", {"count": locked_hidden}), true
		))


func _make_upgrade_row(uid: String, d: Dictionary, rank: int, unlocked: bool, maxed: bool) -> PanelContainer:
	var cost: int = GameState.get_upgrade_cost(uid)
	var row := PanelContainer.new()
	row.custom_minimum_size = Vector2(0, SHOP_ROW_H)
	row.add_theme_stylebox_override("panel", _shop_row_style())
	var desc: String = _upgrade_description(uid, d)
	row.tooltip_text = desc if desc != "" else _upgrade_display_name(uid, d)
	var inner := HBoxContainer.new()
	inner.add_theme_constant_override("separation", 10)
	inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(inner)
	var can_buy: bool = unlocked and not maxed and GameState.manashards >= cost
	var icon: TextureRect = _upgrade_icon(uid, d)
	if not unlocked:
		icon.self_modulate = Color(0.35, 0.32, 0.30, 1.0)
		var lock := TextureRect.new()
		lock.name = "Lock"
		lock.texture = _load_ui_tex(SHOP_LOCK_ICON)
		lock.set_anchors_preset(Control.PRESET_FULL_RECT)
		lock.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon.add_child(lock)
	elif not can_buy and not maxed and not _shop_preview_mode:
		icon.modulate = Color(0.6, 0.6, 0.6, 1.0)
	inner.add_child(icon)
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.alignment = BoxContainer.ALIGNMENT_CENTER
	info.add_theme_constant_override("separation", -2)
	info.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner.add_child(info)
	var name_lbl := Label.new()
	name_lbl.text = _upgrade_display_name(uid, d)
	GameTheme.style_ink_label(name_lbl, not unlocked)
	name_lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	info.add_child(name_lbl)
	var rank_lbl := Label.new()
	rank_lbl.text = "%s  ·  %s" % [desc, _upgrade_rank_label(rank, uid)] if desc != "" else _upgrade_rank_label(rank, uid)
	GameTheme.style_ink_label(rank_lbl, true)
	rank_lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	rank_lbl.custom_minimum_size.x = 120.0
	info.add_child(rank_lbl)
	if maxed or not unlocked:
		inner.add_child(_shop_state_label(
			ContentStrings.get_text("upgrade_maxed") if maxed else ContentStrings.get_text("equip_locked")))
	elif _shop_preview_mode:
		inner.add_child(_shop_price(cost))
	else:
		if not can_buy:
			var need := Label.new()
			need.text = ContentStrings.get_text("upgrade_need_more", {"count": cost - GameState.manashards})
			GameTheme.style_ink_label(need)
			need.add_theme_color_override("font_color", SHORT_RED)
			need.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			inner.add_child(need)
		var btn := Button.new()
		btn.name = "Buy"
		btn.text = str(cost)
		btn.icon = _load_ui_tex(SHOP_SHARD_ICON)
		btn.expand_icon = false
		btn.custom_minimum_size = Vector2(SHOP_BUY_W, 44)
		btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		btn.disabled = not can_buy
		if can_buy:
			GameTheme.style_primary_button(btn)
			btn.pressed.connect(_on_buy.bind(uid))
		else:
			GameTheme.style_menu_button(btn)
		var keep_cost_tip: String = _upgrade_keep_tools_cost_text(uid, cost)
		btn.tooltip_text = keep_cost_tip if keep_cost_tip != "" else row.tooltip_text
		inner.add_child(btn)
	return row


## 44 px Buy buttons sit 2 px inside the 48 px row.
func _shop_row_style() -> StyleBoxTexture:
	var sb: StyleBoxTexture = Ui540.list_row_style()
	sb.content_margin_top = 2.0
	sb.content_margin_bottom = 2.0
	sb.content_margin_right = 4.0
	return sb


## Fixed-width right column so state labels and prices line up with the Buy buttons.
func _shop_state_label(text: String) -> Label:
	var lbl := Label.new()
	lbl.text = text
	GameTheme.style_ink_label(lbl, true)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.custom_minimum_size = Vector2(SHOP_BUY_W, 40)
	return lbl


func _shop_price(cost: int) -> HBoxContainer:
	var box := HBoxContainer.new()
	box.custom_minimum_size = Vector2(SHOP_BUY_W, 40)
	box.add_theme_constant_override("separation", 8)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var icon := TextureRect.new()
	icon.texture = _load_ui_tex(SHOP_SHARD_ICON)
	icon.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(icon)
	var lbl := Label.new()
	lbl.text = str(cost)
	GameTheme.style_ink_label(lbl)
	lbl.custom_minimum_size.x = 64.0
	box.add_child(lbl)
	return box


func _shop_summary_row(text: String, locked: bool) -> PanelContainer:
	var row := PanelContainer.new()
	row.name = "SummaryLocked" if locked else "SummaryComplete"
	row.custom_minimum_size = Vector2(0, SHOP_ROW_H)
	row.add_theme_stylebox_override("panel", _shop_row_style())
	row.tooltip_text = text
	var inner := HBoxContainer.new()
	inner.add_theme_constant_override("separation", 10)
	inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(inner)
	if locked:
		var icon := TextureRect.new()
		icon.texture = _load_ui_tex(SHOP_LOCK_ICON)
		icon.custom_minimum_size = Vector2(32, 32)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		inner.add_child(icon)
	var lbl := Label.new()
	lbl.text = text
	GameTheme.style_ink_label(lbl, not locked)
	lbl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	inner.add_child(lbl)
	return row


func _upgrade_display_name(upgrade_id: String, def: Dictionary) -> String:
	var key: String = "upgrade_%s_name" % upgrade_id
	var named: String = ContentStrings.get_text(key)
	if named != key and named != "":
		return named
	if upgrade_id == "keep_tools":
		return ContentStrings.get_text("upgrade_keep_tools_name")
	return str(def.get("display_name", upgrade_id))


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
	var batch_note: String = ""
	if has_node("/root/ForgeJobs"):
		batch_note = ForgeJobs.ascend_confirm_text()
	if batch_note != "" and not _confirm_batches:
		_show_ascend_batch_dialog(batch_note)
		return
	## Ask only when leftover Manashards can still buy a blessing.
	if GameState.can_afford_any_ascension() and not _confirm_ascend:
		_confirm_ascend = true
		var confirm_line: String = ContentStrings.get_text("ascend_confirm")
		if has_node("/root/ForgeJobs"):
			var warn: String = ForgeJobs.ascend_warning()
			if warn != "":
				confirm_line = warn
				ascend_button.tooltip_text = warn
		_show_ascend_batch_dialog(confirm_line)
		return
	_confirm_ascend = false
	_confirm_batches = false
	_hide_ascend_batch_dialog()
	GameAudio.play_ascend()
	GameAudio.reset_cycle_flags()
	GameState.ascend()
	_highlight_ascend = false
	hide_ascension_shop()
	_release_world_if_allowed()
	_refresh_all()
	SaveService.save_game()


func _show_ascend_batch_dialog(body: String) -> void:
	_ensure_ascend_batch_dialog()
	_show_kit_confirm(_ascend_batch_dialog,
		ContentStrings.get_text("ascend_confirm_title"),
		body,
		ContentStrings.get_text("ascend_confirm_yes"),
		ContentStrings.get_text("ascend_confirm_no"))


func _hide_ascend_batch_dialog() -> void:
	if _ascend_batch_dialog:
		_ascend_batch_dialog.visible = false
		_refresh_dim()


func _ensure_ascend_batch_dialog() -> void:
	if _ascend_batch_dialog != null and is_instance_valid(_ascend_batch_dialog):
		return
	_ascend_batch_dialog = _make_kit_confirm("AscendBatchDialog", _on_ascend_batch_yes, _on_ascend_batch_no)
	_ascend_batch_dialog.z_index = Z_MODAL + 2
	_ascend_batch_body = _ascend_batch_dialog.get_node("Body") as Label


func _on_ascend_batch_yes() -> void:
	_confirm_batches = true
	_confirm_ascend = true
	_hide_ascend_batch_dialog()
	_on_ascend()


func _on_ascend_batch_no() -> void:
	_confirm_batches = false
	_confirm_ascend = false
	_hide_ascend_batch_dialog()
