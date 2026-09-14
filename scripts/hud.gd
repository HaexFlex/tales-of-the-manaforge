extends CanvasLayer
class_name GameHUD
## Minimal HUD + Fruit blessings / Ascend panel (CONTENT_STRINGS_V01).

@onready var panel: ColorRect = $Panel
@onready var resources_label: Label = $Panel/ResourcesLabel
@onready var stage_label: Label = $Panel/StageLabel
@onready var status_label: Label = $Panel/StatusLabel
@onready var save_button: Button = $Panel/SaveButton
@onready var load_button: Button = $Panel/LoadButton
@onready var prestige_panel: ColorRect = $PrestigePanel
@onready var prestige_title: Label = $PrestigePanel/Title
@onready var prestige_sub: Label = $PrestigePanel/Subtitle
@onready var upgrade_list: VBoxContainer = $PrestigePanel/UpgradeList
@onready var harvest_button: Button = $PrestigePanel/HarvestButton
@onready var ascend_button: Button = $PrestigePanel/AscendButton
@onready var close_button: Button = $PrestigePanel/CloseButton


func _ready() -> void:
	panel.color = Color(0.08, 0.1, 0.14, 0.85)
	prestige_panel.color = Color(0.14, 0.1, 0.08, 0.96)
	prestige_panel.visible = false
	save_button.text = ContentStrings.get_text("btn_save")
	load_button.text = ContentStrings.get_text("btn_load")
	close_button.text = ContentStrings.get_text("btn_close")
	save_button.pressed.connect(_on_save)
	load_button.pressed.connect(_on_load)
	harvest_button.pressed.connect(_on_harvest)
	ascend_button.pressed.connect(_on_ascend)
	close_button.pressed.connect(hide_prestige_menu)
	GameState.resources_changed.connect(_on_resources)
	GameState.stage_changed.connect(_on_stage)
	GameState.growth_changed.connect(_on_growth)
	GameState.upgrades_changed.connect(_refresh_all)
	GameState.status_message.connect(_on_status)
	_refresh_all()
	status_label.text = ContentStrings.get_text("boot_line")


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
		ContentStrings.get_text("hud_wood") if false else "Wood", GameState.wood,
		"Stone", GameState.stone,
		"Food", GameState.food,
		"Manashards", GameState.manashards,
		"Essence", GameState.essence,
	]
	# Prefer Content keys where present:
	resources_label.text = "Wood %d  |  Stone %d  |  Food %d  |  Manashards %d  |  Essence %d" % [
		GameState.wood, GameState.stone, GameState.food, GameState.manashards, GameState.essence
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


func show_prestige_menu() -> void:
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
