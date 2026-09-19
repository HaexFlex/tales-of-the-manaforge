extends CanvasLayer
class_name GameHUD
## HUD + Manatree care + backpack/handcraft + Ascension shop. SYSTEMS v0.4.1.

@onready var panel: ColorRect = $Panel
@onready var resources_label: Label = $Panel/ResourcesLabel
@onready var stage_label: Label = $Panel/StageLabel
@onready var controls_hint: Label = $Panel/ControlsHint
@onready var status_label: Label = $Panel/StatusLabel
@onready var selection_hint: Label = $Panel/SelectionHint
@onready var pause_button: Button = $Panel/PauseButton
@onready var backpack_button: Button = $Panel/BackpackButton
@onready var backpack_icon: ColorRect = $Panel/BackpackButton/BackpackIcon
@onready var backpack_dim: ColorRect = $BackpackDim
@onready var backpack_panel: Panel = $BackpackPanel
@onready var backpack_title: Label = $BackpackPanel/Header/BackpackTitle
@onready var backpack_close_button: Button = $BackpackPanel/Header/BackpackCloseButton
@onready var inventory_title: Label = $BackpackPanel/InventoryTitle
@onready var backpack_tab_all: Button = $BackpackPanel/TabRow/TabAll
@onready var backpack_tab_tools: Button = $BackpackPanel/TabRow/TabTools
@onready var backpack_tab_parts: Button = $BackpackPanel/TabRow/TabParts
@onready var inventory_list: VBoxContainer = $BackpackPanel/InventoryScroll/InventoryList
@onready var handcraft_title: Label = $BackpackPanel/HandcraftTitle
@onready var craft_list: VBoxContainer = $BackpackPanel/CraftScroll/CraftList
@onready var care_grow_costs: HBoxContainer = $CarePanel/CareGrowCosts
@onready var grow_fert_icon: ColorRect = $CarePanel/CareGrowCosts/FertilizerIcon
@onready var grow_fert_need: Label = $CarePanel/CareGrowCosts/FertilizerNeed
@onready var grow_ess_icon: ColorRect = $CarePanel/CareGrowCosts/EssenceIcon
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
const ICON_KEEP_TOOLS: Color = Color(0.72, 0.53, 0.04, 1.0)
const BACKPACK_ROW_H: float = 40.0

var _manatree: Manatree = null
var _confirm_pay: bool = false
var _confirm_ascend: bool = false
## 0 = closed, 1 = Begin Ascension?, 2 = Commit the harvest.
var _fruit_confirm_step: int = 0
var _highlight_ascend: bool = false
var _backpack_tab: String = "all"


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	panel.color = Color(0.08, 0.1, 0.14, 0.85)
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
	pause_button.text = ContentStrings.get_text("btn_pause")
	backpack_button.text = ContentStrings.get_text("backpack_open")
	backpack_title.text = ContentStrings.get_text("backpack_title")
	handcraft_title.text = "%s  ·  %s" % [
		ContentStrings.get_text("handcraft_title"),
		ContentStrings.get_text("tool_never_gate"),
	]
	inventory_title.text = ContentStrings.get_text("backpack_hint")
	backpack_tab_all.text = ContentStrings.get_text("backpack_tab_all")
	backpack_tab_tools.text = ContentStrings.get_text("backpack_tab_tools")
	backpack_tab_parts.text = ContentStrings.get_text("backpack_tab_materials")
	if backpack_icon:
		backpack_icon.color = ICON_BACKPACK
	if grow_fert_icon:
		grow_fert_icon.color = ICON_FERTILIZER
	if grow_ess_icon:
		grow_ess_icon.color = ICON_ESSENCE
	close_button.text = ContentStrings.get_text("btn_close")
	care_close_button.text = ContentStrings.get_text("btn_close")
	water_button.text = ContentStrings.get_text("tree_interact_water")
	pay_button.text = ContentStrings.get_text("tree_grow")
	harvest_fruit_button.text = ContentStrings.get_text("fruit_ready_prompt")
	ascension_reopen_button.text = ContentStrings.get_text("ascension_paused_title")
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
	backpack_button.pressed.connect(toggle_backpack)
	backpack_close_button.pressed.connect(close_backpack)
	backpack_tab_all.pressed.connect(_on_backpack_tab.bind("all"))
	backpack_tab_tools.pressed.connect(_on_backpack_tab.bind("tools"))
	backpack_tab_parts.pressed.connect(_on_backpack_tab.bind("parts"))
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
	welcome_dismiss_button.pressed.connect(_on_welcome_dismiss)
	GameState.resources_changed.connect(_on_resources)
	GameState.stage_changed.connect(_on_stage)
	GameState.needs_changed.connect(_on_needs)
	GameState.upgrades_changed.connect(_refresh_all)
	GameState.status_message.connect(_on_status)
	GameState.fruit_ready_changed.connect(_on_fruit_ready_changed)
	GameState.selection_changed.connect(_refresh_selection_hint)
	GameState.load_completed.connect(_on_game_state_loaded)
	Backpack.inventory_changed.connect(_on_backpack_inventory)
	_refresh_all()
	status_label.text = ContentStrings.get_text("boot_line")
	_refresh_controls_hint()
	_refresh_selection_hint()
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
	_apply_button_chrome(backpack_button, Color(0.18, 0.14, 0.10, 1.0), GOLD)
	_apply_button_chrome(backpack_close_button, Color(0.18, 0.14, 0.10, 1.0), GOLD)
	_apply_button_chrome(backpack_tab_all, Color(0.18, 0.14, 0.10, 1.0), GOLD)
	_apply_button_chrome(backpack_tab_tools, Color(0.18, 0.14, 0.10, 1.0), GOLD)
	_apply_button_chrome(backpack_tab_parts, Color(0.18, 0.14, 0.10, 1.0), GOLD)
	backpack_panel.add_theme_stylebox_override("panel", _wood_style())


func _refresh_dim() -> void:
	if shop_dim == null:
		return
	shop_dim.visible = fruit_confirm_panel.visible or ascension_panel.visible
	if backpack_dim:
		backpack_dim.visible = backpack_panel.visible


func bind_manatree(tree: Manatree) -> void:
	_manatree = tree


func maybe_show_welcome() -> void:
	if GameState.welcome_shown:
		return
	show_welcome()


func show_welcome() -> void:
	close_backpack()
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
	status_label.text = ContentStrings.get_text("controls_hint")
	SaveService.save_game()


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
	status_label.text = text


func _refresh_controls_hint() -> void:
	if controls_hint == null:
		return
	controls_hint.text = "%s  ·  %s  ·  %s  ·  %s" % [
		ContentStrings.get_text("controls_lmb_select"),
		ContentStrings.get_text("controls_rmb_command"),
		ContentStrings.get_text("controls_lmb_deselect"),
		ContentStrings.get_text("controls_camera_pan"),
	]


func _refresh_selection_hint() -> void:
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
	if care_panel.visible:
		_refresh_care_needs()


func _refresh_resources() -> void:
	resources_label.text = "%s %d  |  %s %d  |  %s %d  |  %s %d  |  %s %d" % [
		ContentStrings.get_text("hud_wood"), GameState.wood,
		ContentStrings.get_text("hud_stone"), GameState.stone,
		ContentStrings.get_text("hud_food"), GameState.food,
		ContentStrings.get_text("hud_manashards"), GameState.manashards,
		ContentStrings.get_text("hud_essence"), GameState.essence,
	]


func _refresh_stage() -> void:
	var def: Dictionary = GameState.get_stage_def()
	stage_label.text = "%s  |  %s" % [
		str(def.get("display_name", GameState.stage_id)),
		ContentStrings.get_text("ascend_count_hud", {"count": GameState.ascensions}),
	]


func _refresh_care_needs() -> void:
	var info: Dictionary = GameState.get_care_next_stage_info()
	care_title.text = "%s %s" % [
		ContentStrings.get_text("tree_menu_title"),
		ContentStrings.get_text("tree_care_title"),
	]
	var stage_name: String = str(GameState.get_stage_def().get("display_name", GameState.stage_id))
	var fruit_ready: bool = GameState.fruit_ready and not GameState.fruit_committed
	if fruit_ready:
		care_stage_label.text = "Stage: %s · Fruit ready" % stage_name
	else:
		care_stage_label.text = "Stage: %s" % stage_name
	var lines: PackedStringArray = info.get("needs_lines", PackedStringArray()) as PackedStringArray
	var header: String = str(info.get("needs_header", ""))
	var status: String = str(info.get("needs_status", ""))
	var body_parts: PackedStringArray = PackedStringArray()
	var is_ancient: bool = bool(info.get("is_ancient", false))
	if not is_ancient:
		var toward: String = str(info.get("title", ""))
		if toward != "":
			body_parts.append(toward)
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
	fruit_ready_card.visible = fruit_ready
	precommit_hint.visible = fruit_ready
	if fruit_ready:
		precommit_hint.text = "%s\n%s" % [
			ContentStrings.get_text("tree_ancient_care_hint"),
			ContentStrings.get_text("tree_water_ancient_note"),
		]


func show_care_menu() -> void:
	if welcome_panel.visible:
		return
	if _pause_menu and _pause_menu.is_open():
		return
	if GameState.fruit_committed:
		show_ascension_shop()
		return
	close_backpack()
	hide_ascension_shop()
	hide_fruit_confirm()
	_confirm_pay = false
	care_panel.visible = true
	water_button.text = ContentStrings.get_text("tree_interact_water")
	_refresh_care_needs()
	GameAudio.play_ui_open()


func open_fruit_from_care() -> void:
	open_fruit_confirm()


func hide_care_menu() -> void:
	if care_panel.visible:
		GameAudio.play_ui_close()
	care_panel.visible = false
	_confirm_pay = false


## Legacy entry: pre-commit never opens the shop; pending reopen the paused shop.
func show_prestige_menu(_focus_ascend: bool = false) -> void:
	if GameState.fruit_harvested_pending_ascend:
		show_ascension_shop()
		return
	show_care_menu()


func hide_prestige_menu() -> void:
	hide_ascension_shop()


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
	_refresh_dim()


func _on_shop_close() -> void:
	## Hide shop UI only. World stays paused until Ascend.
	hide_ascension_shop()


func _refresh_reopen_button() -> void:
	if ascension_reopen_button == null:
		return
	ascension_reopen_button.visible = (
		GameState.fruit_harvested_pending_ascend and not ascension_panel.visible
	)
	ascension_reopen_button.text = ContentStrings.get_text("ascension_paused_title")


func _sync_ascension_from_state() -> void:
	hide_fruit_confirm()
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
	if GameState.fruit_harvested_pending_ascend:
		return
	if is_backpack_open():
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
		status_label.text = ContentStrings.get_text("fruit_confirm_step1")
	else:
		fruit_confirm_title.text = ContentStrings.get_text("fruit_confirm_step2_title")
		fruit_confirm_body.text = ContentStrings.get_text("fruit_confirm_step2")
		fruit_confirm_yes.text = ContentStrings.get_text("fruit_confirm_step2_yes")
		fruit_confirm_no.text = ContentStrings.get_text("fruit_confirm_step2_no")
		status_label.text = ContentStrings.get_text("fruit_confirm_step2")
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
	status_label.text = "%s\n%s" % [
		ContentStrings.get_text("fruit_harvest_toast"),
		ContentStrings.get_text("fruit_flow_hint"),
	]
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
	if grow_fert_icon:
		grow_fert_icon.color = ICON_FERTILIZER
	if grow_ess_icon:
		grow_ess_icon.color = ICON_ESSENCE
	if grow_fert_need:
		var fert_key: String = "tree_grow_cost_fertilizer" if fert_have < fert_need else "tree_grow_cost_fertilizer_met"
		grow_fert_need.text = ContentStrings.get_text(fert_key, {
			"item": ContentStrings.get_text("fertilizer_name"),
			"have": fert_have,
			"need": fert_need,
		})
	if grow_ess_need:
		var ess_key: String = "tree_grow_cost_essence" if ess_have < ess_need else "tree_grow_cost_essence_met"
		grow_ess_need.text = ContentStrings.get_text(ess_key, {
			"item": ContentStrings.get_text("hud_essence"),
			"have": ess_have,
			"need": ess_need,
		})


func _on_pay() -> void:
	## One-click Grow — no confirm. Spend Fertilizer + Essence when affordable.
	if not GameState.can_grow_stage():
		GameAudio.play_tree_deny()
		_refresh_care_needs()
		return
	_confirm_pay = false
	var result: String = "cant_afford"
	if _manatree:
		result = _manatree.do_pay_stage()
	else:
		result = GameState.try_grow_stage()
	if result == "ok":
		SaveService.save_game()
	_refresh_all()


func is_backpack_open() -> bool:
	return backpack_panel != null and backpack_panel.visible


func toggle_backpack() -> void:
	if is_backpack_open():
		close_backpack()
	else:
		open_backpack()


func open_backpack() -> void:
	if welcome_panel.visible:
		return
	if GameState.fruit_committed:
		show_ascension_shop()
		return
	if _pause_menu and _pause_menu.is_open():
		return
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
			close_backpack()


func _on_backpack_inventory(_item_id: StringName, _amount: int) -> void:
	if is_backpack_open():
		_rebuild_backpack()
	if care_panel.visible:
		_refresh_care_needs()


func _on_backpack_tab(tab_id: String) -> void:
	_backpack_tab = tab_id
	_rebuild_backpack()


func _stack_matches_tab(stack: Dictionary) -> bool:
	if _backpack_tab == "tools":
		return str(stack.get("kind", "")) == "tool"
	if _backpack_tab == "parts":
		var kind: String = str(stack.get("kind", ""))
		return kind == "intermediate" or kind == "consumable"
	return true


func _rebuild_backpack() -> void:
	backpack_title.text = ContentStrings.get_text("backpack_title")
	handcraft_title.text = "%s  ·  %s" % [
		ContentStrings.get_text("handcraft_title"),
		ContentStrings.get_text("tool_never_gate"),
	]
	inventory_title.text = ContentStrings.get_text("backpack_hint")
	backpack_tab_all.text = ContentStrings.get_text("backpack_tab_all")
	backpack_tab_tools.text = ContentStrings.get_text("backpack_tab_tools")
	backpack_tab_parts.text = ContentStrings.get_text("backpack_tab_materials")
	for child: Node in inventory_list.get_children():
		child.queue_free()
	var stacks: Array[Dictionary] = Backpack.stacked_items()
	var shown: int = 0
	for stack: Dictionary in stacks:
		if not _stack_matches_tab(stack):
			continue
		inventory_list.add_child(_make_item_row(stack, false))
		shown += 1
	if shown == 0:
		var empty := Label.new()
		empty.text = ContentStrings.get_text("backpack_empty")
		if _backpack_tab != "all" and not stacks.is_empty():
			empty.text = ContentStrings.get_text("backpack_hint")
		empty.add_theme_font_size_override("font_size", 12)
		empty.add_theme_color_override("font_color", Color(0.70, 0.64, 0.52, 1.0))
		empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		inventory_list.add_child(empty)
	for child2: Node in craft_list.get_children():
		child2.queue_free()
	for entry: Variant in Backpack.recipes_data:
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var rec: Dictionary = entry
		craft_list.add_child(_make_craft_row(str(rec.get("id", ""))))


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
	row.add_child(_placeholder_icon(stack.get("color", Color.GRAY) as Color))
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
	row.add_child(lbl)
	return row


func _make_craft_row(recipe_id: String) -> Control:
	var def: Dictionary = Backpack.get_recipe_def(recipe_id)
	var out_id: String = str(def.get("output_id", recipe_id))
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(0, BACKPACK_ROW_H + 8.0)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 8)
	row.clip_contents = true
	row.add_child(_placeholder_icon(Backpack.item_color(out_id)))
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.size_flags_stretch_ratio = 1.0
	var name_lbl := Label.new()
	name_lbl.text = Backpack.item_display_name(out_id)
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
	var reason: String = Backpack.craft_block_reason(recipe_id)
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
	return row


func _craft_row_cost_text(recipe_id: String) -> String:
	match recipe_id:
		"stone_watering_can":
			var short_can: String = ContentStrings.get_text("handcraft_row_watering_can_short")
			if short_can != "handcraft_row_watering_can_short":
				return short_can
		"wooden_basket":
			var short_basket: String = ContentStrings.get_text("handcraft_row_wooden_basket_short")
			if short_basket != "handcraft_row_wooden_basket_short":
				return short_basket
		"fertilizer":
			var ings: Dictionary = Backpack.get_recipe_ingredients(recipe_id)
			var short_fert: String = ContentStrings.get_text("handcraft_row_fertilizer_short", {
				"wood": int(ings.get("wood", 10)),
				"stone": int(ings.get("stone", 10)),
				"food": int(ings.get("food", 10)),
			})
			if short_fert != "handcraft_row_fertilizer_short":
				return short_fert
	return "  ".join(Backpack.recipe_ingredient_lines(recipe_id))


func get_backpack_layout_metrics() -> Dictionary:
	var panel_w: float = backpack_panel.size.x if backpack_panel else 0.0
	var craft_scroll: ScrollContainer = get_node_or_null("BackpackPanel/CraftScroll") as ScrollContainer
	var craft_w: float = craft_scroll.size.x if craft_scroll else 0.0
	return {
		"panel_w": panel_w,
		"craft_scroll_w": craft_w,
		"fits": craft_w <= panel_w + 1.0,
	}


func _on_craft(recipe_id: String) -> void:
	var result: String = Backpack.try_craft(recipe_id)
	var out_id: String = str(Backpack.get_recipe_def(recipe_id).get("output_id", recipe_id))
	var item_name: String = Backpack.item_display_name(out_id)
	if result == "ok":
		GameAudio.play_ui_confirm()
		if out_id == "fertilizer":
			status_label.text = ContentStrings.get_text("fertilizer_craft_ok")
		else:
			status_label.text = ContentStrings.get_text("handcraft_ok", {"item": item_name})
		_rebuild_backpack()
		_refresh_resources()
		SaveService.save_game()
		return
	GameAudio.play_tree_deny()
	if result == "unique":
		status_label.text = ContentStrings.get_text("handcraft_owned_unique")
	else:
		status_label.text = ContentStrings.get_text("handcraft_cant_afford", {
			"costs": "  ".join(Backpack.recipe_ingredient_lines(recipe_id)),
		})
	_rebuild_backpack()


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
		if uid == "keep_tools":
			var keep_icon := ColorRect.new()
			keep_icon.custom_minimum_size = Vector2(32, 32)
			keep_icon.color = ICON_KEEP_TOOLS
			keep_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
			keep_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			inner.add_child(keep_icon)
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
		inner.add_child(info)
		inner.add_child(btn)
		row.add_child(inner)
		upgrade_list.add_child(row)
		stripe = not stripe


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
			status_label.text = ContentStrings.get_text("upgrade_keep_tools_toast")
		else:
			status_label.text = ContentStrings.get_text("upgrade_buy_ok", {"blessing_name": disp})
		_confirm_ascend = false
		_rebuild_upgrades()
		_refresh_all()
		SaveService.save_game()


func _on_ascend() -> void:
	if not GameState.can_ascend():
		return
	if not _confirm_ascend:
		_confirm_ascend = true
		status_label.text = "%s\n%s" % [
			ContentStrings.get_text("ascend_confirm"),
			ContentStrings.get_text("ascend_hint"),
		]
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
