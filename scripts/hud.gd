extends CanvasLayer
class_name GameHUD
## HUD + Manatree care + welcome + Ascension Manashard shop. SYSTEMS/Content v0.2.4.

@onready var panel: ColorRect = $Panel
@onready var resources_label: Label = $Panel/ResourcesLabel
@onready var stage_label: Label = $Panel/StageLabel
@onready var status_label: Label = $Panel/StatusLabel
@onready var pause_button: Button = $Panel/PauseButton
@onready var care_panel: ColorRect = $CarePanel
@onready var care_title: Label = $CarePanel/CareTitle
@onready var care_needs_label: Label = $CarePanel/CareNeedsLabel
@onready var water_button: Button = $CarePanel/WaterButton
@onready var pay_button: Button = $CarePanel/PayButton
@onready var care_close_button: Button = $CarePanel/CareCloseButton
@onready var prestige_panel: ColorRect = $PrestigePanel
@onready var prestige_title: Label = $PrestigePanel/Title
@onready var prestige_sub: Label = $PrestigePanel/Subtitle
@onready var upgrade_list: VBoxContainer = $PrestigePanel/UpgradeList
@onready var harvest_button: Button = $PrestigePanel/HarvestButton
@onready var ascend_button: Button = $PrestigePanel/AscendButton
@onready var close_button: Button = $PrestigePanel/CloseButton
@onready var welcome_panel: ColorRect = $WelcomePanel
@onready var welcome_boot_label: Label = $WelcomePanel/WelcomeBoot
@onready var welcome_title_label: Label = $WelcomePanel/WelcomeTitle
@onready var welcome_body_label: Label = $WelcomePanel/WelcomeBody
@onready var welcome_hint_label: Label = $WelcomePanel/WelcomeHint
@onready var welcome_dismiss_button: Button = $WelcomePanel/WelcomeDismiss

var _manatree: Manatree = null
var _confirm_pay: bool = false
var _confirm_harvest: bool = false
var _confirm_ascend: bool = false
## Auto-open Fruit panel once when fruit becomes ready this cycle.
var _auto_opened_fruit_this_cycle: bool = false
var _highlight_ascend: bool = false


func _ready() -> void:
	panel.color = Color(0.08, 0.1, 0.14, 0.85)
	prestige_panel.color = Color(0.14, 0.1, 0.08, 0.96)
	prestige_panel.visible = false
	care_panel.visible = false
	welcome_panel.visible = false
	welcome_panel.color = Color(0.07, 0.1, 0.09, 0.97)
	pause_button.text = ContentStrings.get_text("btn_pause")
	close_button.text = ContentStrings.get_text("btn_close")
	care_close_button.text = ContentStrings.get_text("btn_close")
	water_button.text = ContentStrings.get_text("tree_interact_water")
	pay_button.text = ContentStrings.get_text("tree_pay")
	care_title.text = ContentStrings.get_text("tree_care_title")
	welcome_boot_label.text = ContentStrings.get_text("welcome_boot")
	welcome_title_label.text = ContentStrings.get_text("welcome_title")
	welcome_body_label.text = ContentStrings.get_text("welcome_body")
	welcome_hint_label.text = ContentStrings.get_text("welcome_hint")
	welcome_dismiss_button.text = ContentStrings.get_text("welcome_dismiss")
	pause_button.pressed.connect(_on_pause_pressed)
	harvest_button.pressed.connect(_on_harvest)
	ascend_button.pressed.connect(_on_ascend)
	close_button.pressed.connect(hide_prestige_menu)
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
	_refresh_all()
	status_label.text = ContentStrings.get_text("boot_line")


func _ensure_fruit_care_button() -> void:
	if care_panel.get_node_or_null("FruitOpenButton") != null:
		return
	var btn := Button.new()
	btn.name = "FruitOpenButton"
	btn.text = ContentStrings.get_text("tree_fruit_open")
	btn.position = Vector2(20, 236)
	btn.size = Vector2(200, 28)
	btn.visible = false
	btn.pressed.connect(open_fruit_from_care)
	care_panel.add_child(btn)


func bind_manatree(tree: Manatree) -> void:
	_manatree = tree
	_ensure_fruit_care_button()


func maybe_show_welcome() -> void:
	if GameState.welcome_shown:
		return
	show_welcome()


func show_welcome() -> void:
	hide_care_menu()
	hide_prestige_menu()
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
	status_label.text = ContentStrings.get_text("welcome_hint")
	SaveService.save_game()


func _on_resources(_id: StringName, _amount: int) -> void:
	_refresh_resources()
	_refresh_prestige_buttons()
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
	hide_prestige_menu()
	_auto_opened_fruit_this_cycle = false
	_highlight_ascend = false
	_refresh_all()
	show_welcome()


func _on_loaded_from_pause() -> void:
	hide_care_menu()
	hide_prestige_menu()
	_auto_opened_fruit_this_cycle = GameState.fruit_ready or GameState.fruit_harvested_pending_ascend
	_highlight_ascend = false
	_refresh_all()
	maybe_show_welcome()


func _refresh_all() -> void:
	_refresh_resources()
	_refresh_stage()
	_rebuild_upgrades()
	_refresh_prestige_buttons()
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
	pay_button.visible = not bool(info.get("is_ancient", false))
	if _confirm_pay and can_pay:
		pay_button.text = ContentStrings.get_text("tree_pay_confirm_yes")
	else:
		pay_button.text = ContentStrings.get_text("tree_pay")
	pay_button.disabled = not can_pay
	_ensure_fruit_care_button()
	var fruit_btn: Button = care_panel.get_node_or_null("FruitOpenButton") as Button
	if fruit_btn:
		fruit_btn.visible = GameState.fruit_ready or GameState.fruit_harvested_pending_ascend


func show_care_menu() -> void:
	if welcome_panel.visible:
		return
	if _pause_menu and _pause_menu.is_open():
		return
	hide_prestige_menu()
	_confirm_pay = false
	care_panel.visible = true
	_ensure_fruit_care_button()
	water_button.text = ContentStrings.get_text("tree_interact_water")
	_refresh_care_needs()
	GameAudio.play_ui_open()


func open_fruit_from_care() -> void:
	hide_care_menu()
	show_prestige_menu()


func hide_care_menu() -> void:
	if care_panel.visible:
		GameAudio.play_ui_close()
	care_panel.visible = false
	_confirm_pay = false


func show_prestige_menu(focus_ascend: bool = false) -> void:
	if welcome_panel.visible:
		return
	if _pause_menu and _pause_menu.is_open():
		return
	hide_care_menu()
	_confirm_harvest = false
	_confirm_ascend = false
	if focus_ascend or GameState.fruit_harvested_pending_ascend:
		_highlight_ascend = true
	elif GameState.fruit_ready:
		_highlight_ascend = false
	prestige_panel.visible = true
	GameAudio.play_ui_open()
	prestige_title.text = ContentStrings.get_text("fruit_panel_title")
	_rebuild_upgrades()
	_refresh_prestige_buttons()


func hide_prestige_menu() -> void:
	if prestige_panel.visible:
		GameAudio.play_ui_close()
	prestige_panel.visible = false
	_confirm_harvest = false
	_confirm_ascend = false
	_highlight_ascend = false
	_clear_ascend_highlight()


func _on_fruit_ready_changed(ready: bool) -> void:
	## Auto-open Fruit panel once when fruit becomes ready (Ancient).
	if ready and not _auto_opened_fruit_this_cycle:
		_auto_opened_fruit_this_cycle = true
		call_deferred("_auto_open_prestige_for_fruit")
	_refresh_prestige_buttons()
	if care_panel.visible:
		_refresh_care_needs()


func _auto_open_prestige_for_fruit() -> void:
	if welcome_panel.visible:
		return
	if _pause_menu and _pause_menu.is_open():
		return
	if not GameState.fruit_ready and not GameState.fruit_harvested_pending_ascend:
		return
	show_prestige_menu(GameState.fruit_harvested_pending_ascend)


func _on_water() -> void:
	## Starts water channel on Keeper; hide menu so channel can tick.
	if _manatree:
		hide_care_menu()
		_manatree.do_water()
	_refresh_all()


func _on_pay() -> void:
	if not GameState.can_pay_stage():
		GameAudio.play_tree_deny()
		_refresh_care_needs()
		return
	# Two-step confirm: first click arms confirm label; second pays.
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


func _prestige_guided_steps() -> String:
	var s1: String = ContentStrings.get_text("fruit_step_1")
	var s2: String = ContentStrings.get_text("fruit_step_2")
	var s3: String = ContentStrings.get_text("fruit_step_3")
	if GameState.fruit_ready:
		return "%s  →  %s  →  %s" % [s1, s2, s3]
	if GameState.fruit_harvested_pending_ascend:
		return ContentStrings.get_text("fruit_panel_step")
	return "%s  ·  %s  ·  %s" % [s1, s2, s3]


func _prestige_status_hint() -> String:
	if GameState.fruit_ready:
		return ContentStrings.get_text("fruit_ready_prompt")
	if GameState.fruit_harvested_pending_ascend:
		return ContentStrings.get_text("fruit_flow_hint")
	return ContentStrings.get_text("fruit_panel_subtitle")


func _refresh_prestige_buttons() -> void:
	var in_fruit_flow: bool = GameState.fruit_ready or GameState.fruit_harvested_pending_ascend
	# Harvest: visible in fruit flow; disabled after pending.
	harvest_button.visible = in_fruit_flow
	harvest_button.disabled = not GameState.fruit_ready
	harvest_button.text = ContentStrings.get_text("fruit_confirm_yes")
	# Ascend: visible in fruit flow; enabled only after harvest (no purchase required).
	ascend_button.visible = in_fruit_flow
	ascend_button.disabled = not GameState.can_ascend()
	ascend_button.text = ContentStrings.get_text("ascend_confirm_yes")
	var shards_line: String = ContentStrings.get_text("fruit_shards_hud", {"count": GameState.manashards})
	var essence_line: String = ContentStrings.get_text("fruit_essence_hud", {"count": GameState.essence})
	var hint: String = _prestige_status_hint()
	if GameState.fruit_harvested_pending_ascend:
		hint = "%s\n%s" % [hint, ContentStrings.get_text("ascend_before_bless_hint")]
	prestige_sub.text = "%s\n%s\n%s  |  %s\n%s" % [
		ContentStrings.get_text("fruit_panel_subtitle"),
		_prestige_guided_steps(),
		shards_line,
		essence_line,
		hint,
	]
	if _highlight_ascend and GameState.can_ascend():
		_apply_ascend_highlight()
	else:
		_clear_ascend_highlight()


func _apply_ascend_highlight() -> void:
	ascend_button.modulate = Color(1.15, 1.05, 0.75, 1.0)
	if ascend_button.visible and not ascend_button.disabled:
		ascend_button.grab_focus()


func _clear_ascend_highlight() -> void:
	ascend_button.modulate = Color.WHITE


func _rebuild_upgrades() -> void:
	for child: Node in upgrade_list.get_children():
		child.queue_free()
	for entry: Variant in GameState.upgrades_data:
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var d: Dictionary = entry
		var uid: String = str(d.get("id", ""))
		var rank: int = GameState.get_upgrade_rank(uid)
		var max_rank: int = int(d.get("max_rank", 1))
		var cost: int = GameState.get_upgrade_cost(uid)
		var row := HBoxContainer.new()
		var info := Label.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info.text = "%s — %s\n%s  |  %s" % [
			str(d.get("display_name", uid)),
			str(d.get("description", "")),
			ContentStrings.get_text("upgrade_rank", {"rank": rank, "max": max_rank}),
			ContentStrings.get_text("upgrade_cost", {"cost": cost}),
		]
		var btn := Button.new()
		if rank >= max_rank:
			btn.text = ContentStrings.get_text("upgrade_maxed")
			btn.disabled = true
		elif not GameState.fruit_harvested_pending_ascend:
			# Ascension-only shop: preview costs before Harvest; Buy after.
			btn.text = ContentStrings.get_text("upgrade_buy")
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


func _on_harvest() -> void:
	if not GameState.fruit_ready:
		return
	# Two-step confirm (like Pay).
	if not _confirm_harvest:
		_confirm_harvest = true
		_confirm_ascend = false
		status_label.text = ContentStrings.get_text("fruit_confirm")
		_refresh_prestige_buttons()
		return
	_confirm_harvest = false
	var gained: int = GameState.harvest_fruit()
	if gained > 0:
		GameAudio.play_fruit_harvest()
		status_label.text = "%s\n%s" % [
			ContentStrings.get_text("fruit_harvest_toast", {"amount": gained}),
			ContentStrings.get_text("fruit_flow_hint"),
		]
		_highlight_ascend = true
		# Reopen/refresh Manashard shop; Ascend available (purchase optional).
		if not prestige_panel.visible:
			show_prestige_menu(true)
		else:
			_rebuild_upgrades()
			_refresh_all()
			_apply_ascend_highlight()
		SaveService.save_game()


func _on_ascend() -> void:
	if not GameState.can_ascend():
		return
	# Two-step confirm (like Pay). Ascend always available after harvest (no buy required).
	if not _confirm_ascend:
		_confirm_ascend = true
		_confirm_harvest = false
		status_label.text = "%s\n%s" % [
			ContentStrings.get_text("ascend_confirm"),
			ContentStrings.get_text("ascend_hint"),
		]
		_refresh_prestige_buttons()
		return
	_confirm_ascend = false
	GameAudio.play_ascend()
	GameAudio.reset_cycle_flags()
	GameState.ascend()
	_auto_opened_fruit_this_cycle = false
	_highlight_ascend = false
	hide_prestige_menu()
	_refresh_all()
	SaveService.save_game()
