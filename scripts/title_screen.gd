extends Control
## Title screen (540p kit). Hub BGM is already playing from GameAudio and is not restarted.

const MAIN_SCENE: String = "res://scenes/main.tscn"
const KIT_DIALOG: PackedScene = preload("res://scenes/ui/kit_dialog.tscn")

@onready var fade: ColorRect = $Fade
@onready var menu: VBoxContainer = $Menu
@onready var logo: Label = $Logo
@onready var btn_continue: Button = $Menu/BtnContinue
@onready var save_info: Label = $Menu/SaveInfo
@onready var btn_new: Button = $Menu/BtnNewGame
@onready var btn_load: Button = $Menu/BtnLoad
@onready var btn_options: Button = $Menu/BtnOptions
@onready var btn_quit: Button = $Menu/BtnQuit
@onready var pause_menu: PauseMenu = $PauseMenu

var _items: Array[Button] = []
var _index: int = 0
var _fade: float = 1.0
var _confirm_action: String = ""
var _active_dialog: KitDialog


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = false
	Engine.time_scale = 1.0
	GameState.reset_play_speed()
	GameTheme.apply_app_theme()
	GameAudio.play_hub_music()
	if logo:
		logo.add_theme_font_override("font", GameTheme.title_font())
		logo.add_theme_font_size_override("font_size", GameTheme.jersey_title_size())
	for btn: Button in [btn_continue, btn_new, btn_load, btn_options, btn_quit]:
		btn.add_to_group("title_hero_button")
		GameTheme.style_title_hero_button(btn)
		btn.alignment = HORIZONTAL_ALIGNMENT_CENTER
	btn_continue.text = ContentStrings.get_text("title_continue")
	btn_new.text = ContentStrings.get_text("title_new_game")
	btn_load.text = ContentStrings.get_text("title_load")
	btn_options.text = ContentStrings.get_text("title_options")
	btn_quit.text = ContentStrings.get_text("title_quit")
	btn_continue.visible = SaveService.has_save()
	Ui540.hide_on_phone(btn_quit)
	_refresh_save_info()
	btn_continue.pressed.connect(_on_continue)
	btn_new.pressed.connect(_on_new_game)
	btn_load.pressed.connect(_on_load)
	btn_options.pressed.connect(_on_options)
	btn_quit.pressed.connect(_on_quit)
	for child: Node in menu.get_children():
		if child is Button:
			(child as Button).focus_entered.connect(_on_menu_focus.bind(child))
	pause_menu.suppress_pause_hotkey = true
	pause_menu.standalone_load_requested.connect(_on_slot_chosen)
	pause_menu.close_standalone()
	_rebuild_items()
	_set_menu_enabled(false)
	call_deferred("_arm_menu_when_idle")


func _process(delta: float) -> void:
	if _fade > 0.0:
		_fade = maxf(0.0, _fade - delta * 1.4)
		fade.color = Color(0, 0, 0, _fade)
		fade.mouse_filter = Control.MOUSE_FILTER_STOP if _fade > 0.05 else Control.MOUSE_FILTER_IGNORE


func _refresh_save_info() -> void:
	if save_info == null:
		return
	if not SaveService.has_save():
		save_info.visible = false
		save_info.text = ""
		return
	save_info.visible = true
	var rec: Dictionary = SaveService.get_most_recent_record()
	if rec.is_empty():
		save_info.text = ContentStrings.get_text("title_continue_hint")
		return
	var kind: String = str(rec.get("kind", "manual"))
	var slot: int = int(rec.get("slot", 0))
	var slot_label: String = "Slot %d" % slot if kind == "manual" else ContentStrings.get_text("load_autosave_slot", {"n": slot})
	var ts: float = float(rec.get("timestamp", 0.0))
	var ago: String = _format_time_ago(ts)
	save_info.text = "Last save: %s · %s" % [slot_label, ago]


func _format_time_ago(ts: float) -> String:
	if ts <= 0.0:
		return "—"
	var sec: float = maxf(0.0, Time.get_unix_time_from_system() - ts)
	if sec < 90.0:
		return "just now"
	var mins: int = int(sec / 60.0)
	if mins < 90:
		return "%d min ago" % mins
	var hours: int = int(mins / 60.0)
	if hours < 48:
		return "%d hr ago" % hours
	return "%d days ago" % int(hours / 24.0)


func _set_menu_enabled(enabled: bool) -> void:
	btn_continue.disabled = not enabled
	btn_new.disabled = not enabled
	btn_load.disabled = not enabled
	btn_options.disabled = not enabled
	btn_quit.disabled = not enabled


func _input_held() -> bool:
	return (
		Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
		or Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)
		or Input.is_action_pressed("ui_accept")
		or Input.is_key_pressed(KEY_ENTER)
		or Input.is_key_pressed(KEY_KP_ENTER)
		or Input.is_key_pressed(KEY_SPACE)
	)


func _arm_menu_when_idle() -> void:
	while is_inside_tree() and (_fade > 0.05 or _input_held()):
		await get_tree().process_frame
	if not is_inside_tree():
		return
	await get_tree().process_frame
	if not is_inside_tree():
		return
	_set_menu_enabled(true)
	_rebuild_items()
	_focus_index(0)


func _rebuild_items() -> void:
	_items.clear()
	for child: Node in menu.get_children():
		if child is Button and (child as Button).visible:
			_items.append(child as Button)


func _focus_index(index: int) -> void:
	if _items.is_empty():
		return
	_index = posmod(index, _items.size())
	_items[_index].grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if pause_menu.visible and pause_menu.standalone:
		return
	if _active_dialog != null and is_instance_valid(_active_dialog):
		return
	if event.is_action_pressed("ui_down"):
		_focus_index(_index + 1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_up"):
		_focus_index(_index - 1)
		get_viewport().set_input_as_handled()


func _on_menu_focus(btn: Button) -> void:
	var found: int = _items.find(btn)
	if found >= 0:
		_index = found


func _on_continue() -> void:
	if not SaveService.has_save():
		return
	SaveService.boot_intent = "continue"
	SaveService.boot_slot = 0
	GameAudio.play_ui_confirm()
	get_tree().change_scene_to_file(MAIN_SCENE)


func _on_new_game() -> void:
	if SaveService.has_save():
		_show_confirm(
			"new",
			ContentStrings.get_text("title_new_game_confirm"),
			ContentStrings.get_text("title_new_game_confirm_yes"),
			ContentStrings.get_text("title_new_game_confirm_no"),
		)
		return
	_start_new_game()


func _start_new_game() -> void:
	SaveService.boot_intent = "new"
	SaveService.boot_slot = 0
	GameAudio.play_ui_confirm()
	get_tree().change_scene_to_file(MAIN_SCENE)


func _on_load() -> void:
	pause_menu.open_load_standalone()


func _on_options() -> void:
	pause_menu.open_options_standalone()


func _on_quit() -> void:
	_show_confirm(
		"quit",
		ContentStrings.get_text("title_quit_confirm"),
		ContentStrings.get_text("title_quit_confirm_yes"),
		ContentStrings.get_text("title_quit_confirm_no"),
	)


func _on_slot_chosen(slot: int, kind: String) -> void:
	SaveService.boot_intent = "load"
	SaveService.boot_slot = slot
	SaveService.boot_slot_kind = kind
	GameAudio.play_ui_confirm()
	get_tree().change_scene_to_file(MAIN_SCENE)


func _show_confirm(action: String, body: String, yes: String, no: String) -> void:
	_confirm_action = action
	var dialog: KitDialog = KIT_DIALOG.instantiate() as KitDialog
	_active_dialog = dialog
	add_child(dialog)
	dialog.setup("", body, "", no, yes, "title_%s" % action)
	dialog.confirmed.connect(_on_confirm_yes)
	dialog.cancelled.connect(_on_confirm_no)
	GameAudio.play_ui_open()


func _on_confirm_no() -> void:
	_confirm_action = ""
	_active_dialog = null
	GameAudio.play_ui_cancel()


func _on_confirm_yes() -> void:
	var action: String = _confirm_action
	_confirm_action = ""
	_active_dialog = null
	match action:
		"new":
			_start_new_game()
		"quit":
			SaveService.save_on_quit()
			get_tree().quit()
