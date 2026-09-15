extends CanvasLayer
class_name GameHUD
## HUD + Manatree care (Water channel / Offer) + Fruit blessings panel.

@onready var panel: ColorRect = $Panel
@onready var resources_label: Label = $Panel/ResourcesLabel
@onready var stage_label: Label = $Panel/StageLabel
@onready var status_label: Label = $Panel/StatusLabel
@onready var save_button: Button = $Panel/SaveButton
@onready var load_button: Button = $Panel/LoadButton
@onready var care_panel: ColorRect = $CarePanel
@onready var care_title: Label = $CarePanel/CareTitle
@onready var water_button: Button = $CarePanel/WaterButton
@onready var offer_wood_button: Button = $CarePanel/OfferWoodButton
@onready var offer_stone_button: Button = $CarePanel/OfferStoneButton
@onready var offer_food_button: Button = $CarePanel/OfferFoodButton
@onready var offer_shards_button: Button = $CarePanel/OfferShardsButton
@onready var care_close_button: Button = $CarePanel/CareCloseButton
@onready var prestige_panel: ColorRect = $PrestigePanel
@onready var prestige_title: Label = $PrestigePanel/Title
@onready var prestige_sub: Label = $PrestigePanel/Subtitle
@onready var upgrade_list: VBoxContainer = $PrestigePanel/UpgradeList
@onready var harvest_button: Button = $PrestigePanel/HarvestButton
@onready var ascend_button: Button = $PrestigePanel/AscendButton
@onready var close_button: Button = $PrestigePanel/CloseButton

var _manatree: Manatree = null


func _ready() -> void:
	panel.color = Color(0.08, 0.1, 0.14, 0.85)
	prestige_panel.color = Color(0.14, 0.1, 0.08, 0.96)
	prestige_panel.visible = false
	care_panel.visible = false
	save_button.text = ContentStrings.get_text("btn_save")
	load_button.text = ContentStrings.get_text("btn_load")
	close_button.text = ContentStrings.get_text("btn_close")
	care_close_button.text = ContentStrings.get_text("btn_close")
	water_button.text = ContentStrings.get_text("tree_interact_water")
	offer_wood_button.text = ContentStrings.get_text("tree_offer_wood")
	offer_stone_button.text = ContentStrings.get_text("tree_offer_stone")
	offer_food_button.text = ContentStrings.get_text("tree_offer_food")
	offer_shards_button.text = ContentStrings.get_text("tree_offer_manashards")
	care_title.text = ContentStrings.get_text("tree_menu_title")
	save_button.pressed.connect(_on_save)
	load_button.pressed.connect(_on_load)
	harvest_button.pressed.connect(_on_harvest)
	ascend_button.pressed.connect(_on_ascend)
	close_button.pressed.connect(hide_prestige_menu)
	care_close_button.pressed.connect(hide_care_menu)
	water_button.pressed.connect(_on_water)
	offer_wood_button.pressed.connect(_on_offer.bind(&"wood"))
	offer_stone_button.pressed.connect(_on_offer.bind(&"stone"))
	offer_food_button.pressed.connect(_on_offer.bind(&"food"))
	offer_shards_button.pressed.connect(_on_offer.bind(&"manashards"))
	GameState.resources_changed.connect(_on_resources)
	GameState.stage_changed.connect(_on_stage)
	GameState.growth_changed.connect(_on_growth)
	GameState.upgrades_changed.connect(_refresh_all)
	GameState.status_message.connect(_on_status)
	_refresh_all()
	status_label.text = ContentStrings.get_text("boot_line")



func _ensure_fruit_care_button() -> void:
	if care_panel.get_node_or_null("FruitOpenButton") != null:
		return
	var btn := Button.new()
	btn.name = "FruitOpenButton"
	btn.text = ContentStrings.get_text("tree_fruit_open")
	btn.position = Vector2(20, 210)
	btn.size = Vector2(200, 28)
	btn.visible = false
	btn.pressed.connect(open_fruit_from_care)
	care_panel.add_child(btn)


func bind_manatree(tree: Manatree) -> void:
	_manatree = tree
	_ensure_fruit_care_button()


func _on_resources(_id: StringName, _amount: int) -> void:
	_refresh_resources()
	_refresh_prestige_buttons()


func _on_stage(_id: StringName) -> void:
	_refresh_stage()


func _on_growth(_g: int, _r: int) -> void:
	_refresh_stage()


func _on_status(text: String) -> void:
	status_label.text = text


func _on_save() -> void:
	var ok: bool = SaveService.save_game()
	if ok:
		GameAudio.play_ui_confirm()
	status_label.text = ContentStrings.get_text("save_toast") if ok else "Save failed."


func _on_load() -> void:
	var ok: bool = SaveService.load_game()
	status_label.text = ContentStrings.get_text("load_toast") if ok else "No save found."
	_refresh_all()


func _refresh_all() -> void:
	_refresh_resources()
	_refresh_stage()
	_rebuild_upgrades()
	_refresh_prestige_buttons()


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
	var req: int = GameState.get_growth_required_for_next()
	var growth_bit: String = ""
	if GameState.stage_id != &"ancient":
		growth_bit = "  |  Growth %d/%d" % [GameState.growth, req]
	stage_label.text = "%s%s  |  %s" % [
		str(def.get("display_name", GameState.stage_id)),
		growth_bit,
		ContentStrings.get_text("ascend_count_hud", {"count": GameState.ascensions}),
	]


func show_care_menu() -> void:
	hide_prestige_menu()
	care_panel.visible = true
	# Ancient: Water still available; Fruit prompt via prestige if ready.
	_ensure_fruit_care_button()
	var fruit_btn: Button = care_panel.get_node_or_null("FruitOpenButton") as Button
	if fruit_btn:
		fruit_btn.visible = GameState.fruit_ready
	water_button.text = ContentStrings.get_text("tree_interact_water")
	care_title.text = ContentStrings.get_text("tree_menu_title")
	GameAudio.play_ui_open()


func open_fruit_from_care() -> void:
	hide_care_menu()
	show_prestige_menu()


func hide_care_menu() -> void:
	if care_panel.visible:
		GameAudio.play_ui_close()
	care_panel.visible = false


func show_prestige_menu() -> void:
	hide_care_menu()
	prestige_panel.visible = true
	GameAudio.play_ui_open()
	prestige_title.text = ContentStrings.get_text("fruit_panel_title")
	prestige_sub.text = ContentStrings.get_text("fruit_panel_subtitle")
	_rebuild_upgrades()
	_refresh_prestige_buttons()


func hide_prestige_menu() -> void:
	if prestige_panel.visible:
		GameAudio.play_ui_close()
	prestige_panel.visible = false


func _on_water() -> void:
	## Starts water channel on Keeper; hide menu so channel can tick.
	if _manatree:
		hide_care_menu()
		_manatree.do_water()
	_refresh_all()


func _on_offer(resource_id: StringName) -> void:
	if _manatree:
		_manatree.do_offer(resource_id)
	_refresh_all()


func _refresh_prestige_buttons() -> void:
	harvest_button.visible = GameState.fruit_ready
	harvest_button.text = ContentStrings.get_text("fruit_confirm_yes")
	ascend_button.visible = GameState.can_ascend()
	ascend_button.text = ContentStrings.get_text("ascend_confirm_yes")
	prestige_sub.text = "%s\n%s" % [
		ContentStrings.get_text("fruit_panel_subtitle"),
		ContentStrings.get_text("fruit_essence_hud", {"count": GameState.essence}),
	]


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
		elif not GameState.can_buy_upgrade(uid):
			btn.text = ContentStrings.get_text("upgrade_cant_afford")
			btn.disabled = true
		else:
			btn.text = ContentStrings.get_text("upgrade_buy")
			btn.pressed.connect(_on_buy.bind(uid))
		row.add_child(info)
		row.add_child(btn)
		upgrade_list.add_child(row)


func _on_buy(upgrade_id: String) -> void:
	if GameState.buy_upgrade(upgrade_id):
		GameAudio.play_upgrade_buy()
		_refresh_all()
		SaveService.save_game()


func _on_harvest() -> void:
	var gained: int = GameState.harvest_fruit()
	if gained > 0:
		GameAudio.play_fruit_harvest()
		status_label.text = ContentStrings.get_text("fruit_harvest_toast", {"amount": gained})
		_refresh_all()
		SaveService.save_game()


func _on_ascend() -> void:
	if not GameState.can_ascend():
		return
	GameAudio.play_ascend()
	GameAudio.reset_cycle_flags()
	GameState.ascend()
	hide_prestige_menu()
	_refresh_all()
	SaveService.save_game()
