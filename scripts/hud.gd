extends CanvasLayer
class_name GameHUD
## HUD + Manatree care + welcome + Ascension shop. SYSTEMS v0.3.3 / Content v0.3.5.

@onready var panel: ColorRect = $Panel
@onready var resources_label: Label = $Panel/ResourcesLabel
@onready var stage_label: Label = $Panel/StageLabel
@onready var controls_hint: Label = $Panel/ControlsHint
@onready var status_label: Label = $Panel/StatusLabel
@onready var selection_hint: Label = $Panel/SelectionHint
@onready var pause_button: Button = $Panel/PauseButton
@onready var ascension_reopen_button: Button = $Panel/AscensionReopenButton
@onready var care_panel: ColorRect = $CarePanel
@onready var care_title: Label = $CarePanel/CareTitle
@onready var care_needs_label: Label = $CarePanel/CareNeedsLabel
@onready var water_button: Button = $CarePanel/WaterButton
@onready var pay_button: Button = $CarePanel/PayButton
@onready var harvest_fruit_button: Button = $CarePanel/HarvestFruitButton
@onready var precommit_hint: Label = $CarePanel/PrecommitHint
@onready var care_close_button: Button = $CarePanel/CareCloseButton
@onready var fruit_confirm_panel: ColorRect = $FruitConfirmPanel
@onready var fruit_confirm_title: Label = $FruitConfirmPanel/ConfirmTitle
@onready var fruit_confirm_body: Label = $FruitConfirmPanel/ConfirmBody
@onready var fruit_confirm_yes: Button = $FruitConfirmPanel/ConfirmYes
@onready var fruit_confirm_no: Button = $FruitConfirmPanel/ConfirmNo
@onready var ascension_panel: ColorRect = $AscensionPanel
@onready var prestige_panel: ColorRect = $AscensionPanel
@onready var prestige_title: Label = $AscensionPanel/Layout/Title
@onready var shop_banner: Label = $AscensionPanel/Layout/Banner
@onready var prestige_sub: Label = $AscensionPanel/Layout/Subtitle
@onready var shop_balances: Label = $AscensionPanel/Layout/Balances
@onready var shop_hint: Label = $AscensionPanel/Layout/Hint
@onready var shop_scroll: ScrollContainer = $AscensionPanel/Layout/ShopScroll
@onready var upgrade_list: VBoxContainer = $AscensionPanel/Layout/ShopScroll/UpgradeList
@onready var shop_footer: HBoxContainer = $AscensionPanel/Layout/Footer
@onready var ascend_button: Button = $AscensionPanel/Layout/Footer/AscendButton
@onready var close_button: Button = $AscensionPanel/Layout/Footer/CloseButton
@onready var welcome_panel: ColorRect = $WelcomePanel
@onready var welcome_boot_label: Label = $WelcomePanel/WelcomeBoot
@onready var welcome_title_label: Label = $WelcomePanel/WelcomeTitle
@onready var welcome_body_label: Label = $WelcomePanel/WelcomeBody
@onready var welcome_hint_label: Label = $WelcomePanel/WelcomeHint
@onready var welcome_dismiss_button: Button = $WelcomePanel/WelcomeDismiss

var _manatree: Manatree = null
var _confirm_pay: bool = false
var _confirm_ascend: bool = false
## 0 = closed, 1 = Begin Ascension?, 2 = Commit the harvest.
var _fruit_confirm_step: int = 0
var _highlight_ascend: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	panel.color = Color(0.08, 0.1, 0.14, 0.85)
	ascension_panel.color = Color(0.14, 0.1, 0.08, 0.96)
	fruit_confirm_panel.color = Color(0.12, 0.1, 0.08, 0.98)
	ascension_panel.visible = false
	fruit_confirm_panel.visible = false
	care_panel.visible = false
	welcome_panel.visible = false
	welcome_panel.color = Color(0.07, 0.1, 0.09, 0.97)
	shop_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	shop_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_ALWAYS
	pause_button.text = ContentStrings.get_text("btn_pause")
	close_button.text = ContentStrings.get_text("btn_close")
	care_close_button.text = ContentStrings.get_text("btn_close")
	water_button.text = ContentStrings.get_text("tree_interact_water")
	pay_button.text = ContentStrings.get_text("tree_pay")
	harvest_fruit_button.text = ContentStrings.get_text("fruit_precommit_cta")
	ascension_reopen_button.text = ContentStrings.get_text("ascension_paused_title")
	care_title.text = ContentStrings.get_text("tree_care_title")
	welcome_boot_label.text = ContentStrings.get_text("welcome_boot")
	welcome_title_label.text = ContentStrings.get_text("welcome_title")
	welcome_body_label.text = ContentStrings.get_text("welcome_body")
	welcome_hint_label.text = ContentStrings.get_text("welcome_hint")
	welcome_dismiss_button.text = ContentStrings.get_text("welcome_dismiss")
	pause_button.pressed.connect(_on_pause_pressed)
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
	_refresh_all()
	status_label.text = ContentStrings.get_text("boot_line")
	_refresh_controls_hint()
	_refresh_selection_hint()
	_sync_ascension_from_state()


func bind_manatree(tree: Manatree) -> void:
	_manatree = tree


func maybe_show_welcome() -> void:
	if GameState.welcome_shown:
		return
	show_welcome()


func show_welcome() -> void:
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
	controls_hint.text = "%s  ·  %s  ·  %s" % [
		ContentStrings.get_text("controls_lmb_select"),
		ContentStrings.get_text("controls_rmb_command"),
		ContentStrings.get_text("controls_lmb_deselect"),
	]


func _refresh_selection_hint() -> void:
	if selection_hint == null:
		return
	if GameState.selected_wisp_id >= 0:
		selection_hint.text = ContentStrings.get_text("wisp_orbit_hint")
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
	care_title.text = str(info.get("title", ContentStrings.get_text("tree_care_title")))
	var lines: PackedStringArray = info.get("needs_lines", PackedStringArray()) as PackedStringArray
	var header: String = str(info.get("needs_header", ""))
	var status: String = str(info.get("needs_status", ""))
	var body_parts: PackedStringArray = PackedStringArray()
	if header != "":
		body_parts.append(header)
	for line: String in lines:
		body_parts.append(line)
	if status != "" and not bool(info.get("is_ancient", false)):
		body_parts.append(status)
	care_needs_label.text = "\n".join(body_parts)
	var can_pay: bool = bool(info.get("can_pay", false))
	var is_ancient: bool = bool(info.get("is_ancient", false))
	var fruit_ready: bool = GameState.fruit_ready and not GameState.fruit_harvested_pending_ascend
	pay_button.visible = not is_ancient
	if _confirm_pay and can_pay:
		pay_button.text = ContentStrings.get_text("tree_pay_confirm_yes")
	else:
		pay_button.text = ContentStrings.get_text("tree_pay")
	pay_button.disabled = not can_pay
	water_button.visible = not GameState.fruit_harvested_pending_ascend
	water_button.text = ContentStrings.get_text("tree_interact_water")
	harvest_fruit_button.visible = fruit_ready
	harvest_fruit_button.text = ContentStrings.get_text("fruit_precommit_cta")
	precommit_hint.visible = fruit_ready
	if fruit_ready:
		precommit_hint.text = "%s\n%s" % [
			ContentStrings.get_text("fruit_precommit_hint"),
			ContentStrings.get_text("fruit_precommit_no_shop"),
		]


func show_care_menu() -> void:
	if welcome_panel.visible:
		return
	if _pause_menu and _pause_menu.is_open():
		return
	if GameState.fruit_harvested_pending_ascend:
		show_ascension_shop()
		return
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


func get_fruit_confirm_step() -> int:
	return _fruit_confirm_step


func show_ascension_shop() -> void:
	if welcome_panel.visible:
		return
	if _pause_menu and _pause_menu.is_open():
		return
	if not GameState.fruit_harvested_pending_ascend:
		return
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
	_apply_ascend_highlight()


func hide_ascension_shop() -> void:
	if ascension_panel.visible:
		GameAudio.play_ui_close()
	ascension_panel.visible = false
	_confirm_ascend = false
	_highlight_ascend = false
	_clear_ascend_highlight()
	_refresh_reopen_button()


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


func _release_world_if_allowed() -> void:
	if GameState.fruit_harvested_pending_ascend:
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
	_fruit_confirm_step = 1
	_show_fruit_confirm_step()
	GameAudio.play_ui_open()


func confirm_fruit_step() -> void:
	if _fruit_confirm_step == 1:
		_fruit_confirm_step = 2
		_show_fruit_confirm_step()
		return
	if _fruit_confirm_step == 2:
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


func _show_fruit_confirm_step() -> void:
	fruit_confirm_panel.visible = true
	if _fruit_confirm_step <= 1:
		_fruit_confirm_step = 1
		fruit_confirm_title.text = ContentStrings.get_text("fruit_confirm_step1_title")
		fruit_confirm_body.text = ContentStrings.get_text("fruit_confirm_step1")
		fruit_confirm_yes.text = ContentStrings.get_text("fruit_confirm_step1_yes")
		fruit_confirm_no.text = ContentStrings.get_text("fruit_confirm_step1_no")
		status_label.text = ContentStrings.get_text("fruit_confirm_step1")
	else:
		_fruit_confirm_step = 2
		fruit_confirm_title.text = ContentStrings.get_text("fruit_confirm_step2_title")
		fruit_confirm_body.text = ContentStrings.get_text("fruit_confirm_step2")
		fruit_confirm_yes.text = ContentStrings.get_text("fruit_confirm_step2_yes")
		fruit_confirm_no.text = ContentStrings.get_text("fruit_confirm_step2_no")
		status_label.text = ContentStrings.get_text("fruit_confirm_step2")


func _commit_primordial_fruit() -> void:
	if not GameState.fruit_ready:
		hide_fruit_confirm()
		return
	var gained: int = GameState.harvest_fruit()
	if gained <= 0:
		hide_fruit_confirm()
		return
	_cancel_world_channels()
	hide_fruit_confirm()
	hide_care_menu()
	GameAudio.play_fruit_harvest()
	status_label.text = "%s\n%s" % [
		ContentStrings.get_text("fruit_harvest_toast", {"amount": gained}),
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


func _on_pay() -> void:
	if not GameState.can_pay_stage():
		GameAudio.play_tree_deny()
		_refresh_care_needs()
		return
	if not _confirm_pay:
		_confirm_pay = true
		var info: Dictionary = GameState.get_care_next_stage_info()
		var next_display: String = str(info.get("next_stage_display", ""))
		status_label.text = ContentStrings.get_text("tree_pay_confirm", {"next_stage": next_display})
		_refresh_care_needs()
		return
	_confirm_pay = false
	var result: String = "cant_afford"
	if _manatree:
		result = _manatree.do_pay_stage()
	else:
		result = GameState.try_pay_stage()
	if result == "ok":
		SaveService.save_game()
	_refresh_all()


func _refresh_ascension_copy() -> void:
	if prestige_title == null:
		return
	prestige_title.text = ContentStrings.get_text("fruit_panel_title")
	shop_banner.text = ContentStrings.get_text("fruit_shop_only_banner")
	prestige_sub.text = ContentStrings.get_text("fruit_panel_subtitle")
	shop_balances.text = "%s  |  %s" % [
		ContentStrings.get_text("fruit_shards_hud", {"count": GameState.manashards}),
		ContentStrings.get_text("fruit_essence_hud", {"count": GameState.essence}),
	]
	shop_hint.text = "%s\n%s" % [
		ContentStrings.get_text("ascension_paused_body"),
		ContentStrings.get_text("ascend_before_bless_hint"),
	]
	ascend_button.visible = GameState.fruit_harvested_pending_ascend
	ascend_button.disabled = not GameState.can_ascend()
	if _confirm_ascend and GameState.can_ascend():
		ascend_button.text = ContentStrings.get_text("ascend_confirm_yes")
	else:
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
	for entry: Variant in GameState.upgrades_data:
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var d: Dictionary = entry
		var uid: String = str(d.get("id", ""))
		var rank: int = GameState.get_upgrade_rank(uid)
		var max_rank: int = int(d.get("max_rank", 1))
		var cost: int = GameState.get_upgrade_cost(uid)
		var row := HBoxContainer.new()
		row.custom_minimum_size = Vector2(0, 56)
		var info := Label.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		info.text = "%s — %s\n%s  |  %s" % [
			str(d.get("display_name", uid)),
			str(d.get("description", "")),
			ContentStrings.get_text("upgrade_rank", {"rank": rank, "max": max_rank}),
			ContentStrings.get_text("upgrade_cost", {"cost": cost}),
		]
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(120, 36)
		if rank >= max_rank:
			btn.text = ContentStrings.get_text("upgrade_maxed")
			btn.disabled = true
		elif GameState.manashards < cost:
			btn.text = ContentStrings.get_text("upgrade_cant_afford")
			btn.disabled = true
		else:
			btn.text = ContentStrings.get_text("upgrade_buy")
			btn.pressed.connect(_on_buy.bind(uid))
		row.add_child(info)
		row.add_child(btn)
		upgrade_list.add_child(row)


func _on_buy(upgrade_id: String) -> void:
	## Manashard blessing shop (Ascension-only): multi-buy OK; Ascend never requires a purchase.
	if GameState.buy_upgrade(upgrade_id):
		GameAudio.play_upgrade_buy()
		var disp: String = str(GameState.get_upgrade_def(upgrade_id).get("display_name", upgrade_id))
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
